#!/bin/bash
# 查看后端和前端服务状态

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_DIR="$SCRIPTS_DIR/.pids"

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}● 运行中${NC}  $1"; }
down() { echo -e "  ${RED}○ 已停止${NC}  $1"; }

check_service() {
  local name=$1
  local port=$2
  local label=$3

  local pids
  pids=$(lsof -ti tcp:"$port" 2>/dev/null)

  echo "[$name]"
  if [ -n "$pids" ]; then
    ok "端口=$port  PID=$(echo $pids | tr '\n' ' ')"
    echo "  地址：$label"
  else
    down "端口=$port 未监听"
  fi
  echo ""
}

echo ""
check_service "backend"  5679 "http://localhost:5679/api/v1"
check_service "frontend" 3013 "http://localhost:3013"
