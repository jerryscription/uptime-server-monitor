#!/bin/bash

# 监控守护进程 - 支持秒级间隔

# 从环境变量获取监控间隔（秒），默认为 60 秒
MONITOR_INTERVAL=${MONITOR_INTERVAL:-60}

# 验证间隔是否为有效数字
if ! [[ "$MONITOR_INTERVAL" =~ ^[0-9]+$ ]] || [ "$MONITOR_INTERVAL" -lt 1 ]; then
    echo "Error: MONITOR_INTERVAL must be a positive number (seconds)"
    exit 1
fi

echo "Starting monitoring daemon with interval: ${MONITOR_INTERVAL} seconds"
echo "Press Ctrl+C to stop..."

# 信号处理 - 优雅退出
cleanup() {
    echo ""
    echo "Monitoring daemon stopped"
    exit 0
}
trap cleanup SIGINT SIGTERM

# 主循环
while true; do
    # 执行监控脚本
    /app/monitor.sh
    
    # 等待指定的间隔时间
    sleep "$MONITOR_INTERVAL"
done