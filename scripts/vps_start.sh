#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { echo "[xiaoqimanager:vps] $*"; }

ensure_exec_perm() {
  local file="$1"
  if [[ -x "$file" ]]; then
    return
  fi

  if chmod +x "$file" 2>/dev/null; then
    log "granted execute permission: $file"
    return
  fi

  if command -v sudo >/dev/null 2>&1; then
    sudo chmod +x "$file"
    log "granted execute permission via sudo: $file"
    return
  fi

  log "failed to grant execute permission: $file"
  log "please run with root or install sudo"
  exit 1
}

if [[ ! -f "$ROOT_DIR/scripts/start.sh" ]]; then
  log "missing script: $ROOT_DIR/scripts/start.sh"
  exit 1
fi

ensure_exec_perm "$ROOT_DIR/scripts/install.sh"
ensure_exec_perm "$ROOT_DIR/scripts/start.sh"

log "starting xiaoqimanager with internal authorization flow"
exec bash "$ROOT_DIR/scripts/start.sh" "$@"
