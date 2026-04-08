#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/doubleDimple/oci-start.git}"
APP_DIR="${APP_DIR:-$HOME/oci-start}"
BRANCH="${BRANCH:-main}"

log() { echo "[xiaoqimanager:bootstrap] $*"; }

if command -v git >/dev/null 2>&1; then
  :
else
  echo "git is required but not installed" >&2
  exit 1
fi

if [[ -d "$APP_DIR/.git" ]]; then
  log "repo exists, updating: $APP_DIR"
  if git -C "$APP_DIR" remote get-url origin >/dev/null 2>&1; then
    git -C "$APP_DIR" fetch --all --prune
    git -C "$APP_DIR" checkout "$BRANCH"
    git -C "$APP_DIR" pull --ff-only origin "$BRANCH"
  else
    log "warning: no git origin found, skip pull"
  fi
else
  log "cloning repo into: $APP_DIR"
  git clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR"

if [[ ! -f "scripts/vps_start.sh" ]]; then
  log "missing scripts/vps_start.sh, fallback to scripts/start.sh"
  exec bash scripts/start.sh "$@"
fi

exec bash scripts/vps_start.sh "$@"
