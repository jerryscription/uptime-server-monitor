#!/bin/bash

# 监控守护进程 - 支持秒级间隔

# 错误处理
set -e

# 从环境变量获取监控间隔（秒），默认为 60 秒
MONITOR_INTERVAL=${MONITOR_INTERVAL:-60}

# 验证间隔是否为有效数字
if ! [[ "$MONITOR_INTERVAL" =~ ^[0-9]+$ ]] || [ "$MONITOR_INTERVAL" -lt 1 ]; then
    echo "Error: MONITOR_INTERVAL must be a positive number (seconds)"
    exit 1
fi

# 验证必需的环境变量
if [ -z "$UPTIME_KUMA_PUSH_URL" ]; then
    echo "Error: UPTIME_KUMA_PUSH_URL environment variable is not set."
    echo "Please set it like: -e UPTIME_KUMA_PUSH_URL='https://your-uptime-kuma.com/api/push/xxxxx'"
    exit 1
fi

echo "Starting monitoring daemon with interval: ${MONITOR_INTERVAL} seconds"
echo "Push URL configured: ${UPTIME_KUMA_PUSH_URL%/*}/..."
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
    # 执行监控脚本，捕获错误但不退出
    if ! /app/monitor.sh; then
        echo "Warning: Monitor script failed, retrying in ${MONITOR_INTERVAL} seconds..."
    fi
    
    # 等待指定的间隔时间
    sleep "$MONITOR_INTERVAL"
done