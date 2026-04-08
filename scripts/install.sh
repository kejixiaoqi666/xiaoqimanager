#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ensure_file() {
  local src="$1"
  local dst="$2"
  if [[ ! -f "$dst" ]]; then
    cp "$src" "$dst"
    echo "[init] created $dst"
  else
    echo "[skip] exists $dst"
  fi
}

mkdir -p "$ROOT_DIR/backend/core-a" "$ROOT_DIR/backend/core-b" "$ROOT_DIR/config" "$ROOT_DIR/web"

ensure_file "$ROOT_DIR/backend/core-a/.env.example" "$ROOT_DIR/backend/core-a/.env"
ensure_file "$ROOT_DIR/backend/core-b/.env.example" "$ROOT_DIR/backend/core-b/.env"

if [[ ! -f "$ROOT_DIR/config/services.json" ]]; then
  echo "[error] missing config/services.json"
  exit 1
fi

echo "[done] project directories and backend config files are ready."
echo "[tip] run: python3 app.py"
