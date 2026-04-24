#!/bin/bash
# 停止后端和前端服务

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_DIR="$SCRIPTS_DIR/.pids"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; }

stop_service() {
  local name=$1
  local port=$2
  local pid_file="$PID_DIR/$name.pid"

  local pids
  pids=$(lsof -ti tcp:"$port" 2>/dev/null)

  if [ -z "$pids" ]; then
    warn "$name 未在运行（端口 $port 空闲）"
  else
    echo "$pids" | xargs kill -9 2>/dev/null
    log "$name 已停止（端口 $port）"
  fi

  # 同时清理 PID 文件中记录的 npm 进程（父进程可能已不在端口监听）
  if [ -f "$pid_file" ]; then
    local saved_pid
    saved_pid=$(cat "$pid_file")
    kill -9 "$saved_pid" 2>/dev/null
    rm -f "$pid_file"
  fi
}

stop_service "backend"  5679
stop_service "frontend" 3013
