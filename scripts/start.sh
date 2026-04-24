#!/bin/bash
# 启动后端和前端服务

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
PID_DIR="$SCRIPTS_DIR/.pids"
LOG_DIR="$SCRIPTS_DIR/logs"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; }

mkdir -p "$PID_DIR" "$LOG_DIR"

start_service() {
  local name=$1
  local port=$2
  local dir=$3
  local pid_file="$PID_DIR/$name.pid"
  local log_file="$LOG_DIR/$name.log"

  if lsof -ti tcp:"$port" > /dev/null 2>&1; then
    warn "$name 已在端口 $port 运行，跳过启动"
    return 0
  fi

  log "启动 $name..."
  cd "$PROJECT_ROOT/$dir"
  nohup npm run dev >> "$log_file" 2>&1 &
  local pid=$!
  disown $pid
  echo $pid > "$pid_file"

  # 等待端口就绪，最多 15 秒
  local i=0
  while ! lsof -ti tcp:"$port" > /dev/null 2>&1; do
    sleep 1
    i=$((i+1))
    if [ $i -ge 15 ]; then
      err "$name 启动超时，请查看日志：$log_file"
      return 1
    fi
  done

  log "$name 已启动  PID=$pid  端口=$port"
  log "日志文件：$log_file"
}

start_service "backend"  5679 "backend-node"
start_service "frontend" 3013 "frontweb"
