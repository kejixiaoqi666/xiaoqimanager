#!/usr/bin/env python3
from __future__ import annotations

import json
import os
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parent
WEB_DIR = ROOT / "web"
SERVICE_CONFIG_FILE = ROOT / "config" / "services.json"


def load_services() -> list[dict]:
    if not SERVICE_CONFIG_FILE.exists():
        return []
    with SERVICE_CONFIG_FILE.open("r", encoding="utf-8") as f:
        payload = json.load(f)
    return payload.get("services", [])


def read_env_preview(env_file: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    if not env_file.exists():
        return result
    for line in env_file.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        result[key] = value
    return result


def probe_health(url: str) -> str:
    try:
        with urlopen(url, timeout=1.2) as resp:
            return "online" if 200 <= resp.status < 300 else "degraded"
    except URLError:
        return "offline"


class Handler(BaseHTTPRequestHandler):
    def _json(self, payload: dict, code: int = 200) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _serve_file(self, relpath: str) -> None:
        safe_path = (WEB_DIR / relpath.lstrip("/")).resolve()
        if WEB_DIR not in safe_path.parents and safe_path != WEB_DIR:
            self.send_error(HTTPStatus.FORBIDDEN)
            return
        if safe_path.is_dir():
            safe_path = safe_path / "index.html"
        if not safe_path.exists():
            self.send_error(HTTPStatus.NOT_FOUND)
            return

        content_type = "text/plain; charset=utf-8"
        if safe_path.suffix == ".html":
            content_type = "text/html; charset=utf-8"
        elif safe_path.suffix == ".css":
            content_type = "text/css; charset=utf-8"
        elif safe_path.suffix == ".js":
            content_type = "application/javascript; charset=utf-8"

        content = safe_path.read_bytes()
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(content)))
        self.end_headers()
        self.wfile.write(content)

    def do_GET(self) -> None:  # noqa: N802
        if self.path == "/api/services":
            services = load_services()
            enriched = []
            for service in services:
                env_preview = read_env_preview(ROOT / service["config"])
                enriched.append(
                    {
                        **service,
                        "status": probe_health(service["healthEndpoint"]),
                        "envPreview": env_preview,
                    }
                )
            self._json({"services": enriched})
            return

        if self.path == "/api/summary":
            services = load_services()
            online = 0
            for service in services:
                if probe_health(service["healthEndpoint"]) == "online":
                    online += 1
            self._json({"total": len(services), "online": online, "offline": len(services) - online})
            return

        if self.path == "/":
            self._serve_file("index.html")
            return

        self._serve_file(self.path)


if __name__ == "__main__":
    host = os.getenv("WEB_HOST", "127.0.0.1")
    port = int(os.getenv("WEB_PORT", "8080"))
    server = HTTPServer((host, port), Handler)
    print(f"xiaoqimanager web panel running at http://{host}:{port}")
    server.serve_forever()
