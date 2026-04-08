#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/kejixiaoqi666/xiaoqimanager.git}"
APP_DIR="${APP_DIR:-$HOME/xiaoqimanager}"
BRANCH="${BRANCH:-main}"
RUN_MODE="${RUN_MODE:-daemon}" # daemon | foreground

log() { echo "[xiaoqimanager:quickstart] $*"; }

# Force all git operations to run in non-interactive mode so quickstart never
# blocks waiting for username/password input.
git_no_prompt() {
  GIT_TERMINAL_PROMPT=0 \
    GIT_ASKPASS=/bin/echo \
    GCM_INTERACTIVE=Never \
    git -c credential.helper= "$@"
}

require_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi

  if command -v apt-get >/dev/null 2>&1; then
    log "installing missing dependency: $cmd"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y "$cmd"
  else
    log "missing required command '$cmd', and apt-get is unavailable"
    exit 1
  fi
}

clone_or_update_repo() {
  if [[ -d "$APP_DIR/.git" ]]; then
    log "detected existing repo, updating: $APP_DIR"
    git_no_prompt -C "$APP_DIR" fetch --all --prune
    if git_no_prompt -C "$APP_DIR" show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
      git_no_prompt -C "$APP_DIR" checkout "$BRANCH"
      git_no_prompt -C "$APP_DIR" reset --hard "origin/$BRANCH"
    else
      log "warning: branch '$BRANCH' not found on origin, keeping current branch"
      git_no_prompt -C "$APP_DIR" pull --ff-only || true
    fi
    return 0
  fi

  if [[ -e "$APP_DIR" ]]; then
    log "path exists but is not a git repo: $APP_DIR"
    log "set APP_DIR to another path or remove this path before retrying"
    exit 1
  fi

  log "cloning repository into: $APP_DIR"
  if ! git_no_prompt clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$APP_DIR"; then
    log "clone failed (non-interactive mode)."
    log "if the repo is private, please use a tokenized REPO_URL or SSH key-based URL."
    exit 1
  fi
}

start_service() {
  local start_script="$APP_DIR/scripts/start.sh"
  [[ -x "$start_script" ]] || chmod +x "$start_script"

  if [[ "$RUN_MODE" == "foreground" ]]; then
    log "starting in foreground mode"
    bash "$start_script" --foreground
  else
    log "starting in daemon mode"
    bash "$start_script" --daemon
    log "done. check status with: bash $APP_DIR/scripts/start.sh --status"
  fi
}

main() {
  require_cmd git
  require_cmd curl
  require_cmd python3

  clone_or_update_repo
  start_service
}

main "$@"
