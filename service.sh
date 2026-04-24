#!/bin/bash
# 统一服务管理入口
# 用法：./service.sh {start|stop|restart|status}

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"

case "$1" in
  start)   bash "$SCRIPTS_DIR/start.sh" ;;
  stop)    bash "$SCRIPTS_DIR/stop.sh" ;;
  restart) bash "$SCRIPTS_DIR/restart.sh" ;;
  status)  bash "$SCRIPTS_DIR/status.sh" ;;
  *)
    echo "用法：$0 {start|stop|restart|status}"
    echo ""
    echo "  start    启动后端（:5679）和前端（:3013）"
    echo "  stop     停止所有服务"
    echo "  restart  重启所有服务"
    echo "  status   查看服务运行状态"
    exit 1
    ;;
esac
