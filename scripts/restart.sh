#!/bin/bash
# 重启后端和前端服务

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPTS_DIR/stop.sh"
echo ""
bash "$SCRIPTS_DIR/start.sh"
