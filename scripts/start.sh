#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_DIR="$ROOT_DIR/run"
PID_FILE="$PID_DIR/xiaoqimanager.pid"
LOG_FILE="$PID_DIR/xiaoqimanager.log"

WEB_HOST="${WEB_HOST:-0.0.0.0}"
WEB_PORT="${WEB_PORT:-8080}"
MODE="daemon"

log() { echo "[xiaoqimanager:start] $*"; }

usage() {
  cat <<USAGE
Usage: bash scripts/start.sh [options]

Options:
  --foreground      run in foreground mode (default: daemon)
  --daemon          run in daemon mode
  --stop            stop service and exit
  --restart         restart service
  --status          show running status
  --host <host>     override WEB_HOST (default: 0.0.0.0)
  --port <port>     override WEB_PORT (default: 8080)
  -h, --help        show this help

Examples:
  bash scripts/start.sh
  bash scripts/start.sh --foreground
  bash scripts/start.sh --host 127.0.0.1 --port 9090
  bash scripts/start.sh --restart
USAGE
}

is_running() {
  if [[ ! -f "$PID_FILE" ]]; then
    return 1
  fi
  local pid
  pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

stop_service() {
  if ! is_running; then
    log "service is not running"
    rm -f "$PID_FILE"
    return 0
  fi

  local pid
  pid="$(cat "$PID_FILE")"
  log "stopping service pid=$pid"
  kill "$pid" || true

  for _ in {1..20}; do
    if kill -0 "$pid" 2>/dev/null; then
      sleep 0.2
    else
      break
    fi
  done

  if kill -0 "$pid" 2>/dev/null; then
    log "force killing service pid=$pid"
    kill -9 "$pid" || true
  fi

  rm -f "$PID_FILE"
  log "service stopped"
}

status_service() {
  if is_running; then
    local pid
    pid="$(cat "$PID_FILE")"
    log "service is running, pid=$pid"
    log "url: http://$WEB_HOST:$WEB_PORT"
  else
    log "service is not running"
    return 1
  fi
}

verify_layout() {
  [[ -f "$ROOT_DIR/app.py" ]] || { log "app.py not found in $ROOT_DIR"; exit 1; }
  [[ -f "$ROOT_DIR/scripts/install.sh" ]] || { log "scripts/install.sh not found in $ROOT_DIR"; exit 1; }
}

start_foreground() {
  log "starting in foreground at http://$WEB_HOST:$WEB_PORT"
  cd "$ROOT_DIR"
  WEB_HOST="$WEB_HOST" WEB_PORT="$WEB_PORT" python3 app.py
}

start_daemon() {
  mkdir -p "$PID_DIR"

  if is_running; then
    local pid
    pid="$(cat "$PID_FILE")"
    log "service already running, pid=$pid"
    log "log file: $LOG_FILE"
    return 0
  fi

  log "starting in daemon mode at http://$WEB_HOST:$WEB_PORT"
  cd "$ROOT_DIR"
  nohup env WEB_HOST="$WEB_HOST" WEB_PORT="$WEB_PORT" python3 app.py >>"$LOG_FILE" 2>&1 &
  local pid=$!
  echo "$pid" >"$PID_FILE"
  sleep 0.5

  if kill -0 "$pid" 2>/dev/null; then
    log "started successfully, pid=$pid"
    log "url: http://$WEB_HOST:$WEB_PORT"
    log "tail logs: tail -f $LOG_FILE"
  else
    log "startup failed, check logs: $LOG_FILE"
    exit 1
  fi
}

ACTION="start"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --foreground)
      MODE="foreground"
      shift
      ;;
    --daemon)
      MODE="daemon"
      shift
      ;;
    --stop)
      ACTION="stop"
      shift
      ;;
    --restart)
      ACTION="restart"
      shift
      ;;
    --status)
      ACTION="status"
      shift
      ;;
    --host)
      WEB_HOST="${2:-}"
      [[ -n "$WEB_HOST" ]] || { log "--host requires value"; exit 1; }
      shift 2
      ;;
    --port)
      WEB_PORT="${2:-}"
      [[ "$WEB_PORT" =~ ^[0-9]+$ ]] || { log "--port must be a number"; exit 1; }
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log "unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

verify_layout

case "$ACTION" in
  stop)
    stop_service
    exit 0
    ;;
  status)
    status_service
    exit 0
    ;;
  restart)
    stop_service
    ;;
esac

bash "$ROOT_DIR/scripts/install.sh"

if [[ "$MODE" == "foreground" ]]; then
  start_foreground
else
  start_daemon
fi
