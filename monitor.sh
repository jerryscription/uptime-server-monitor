#!/bin/bash

# --- 配置 ---
# 从环境变量中获取 Push URL
if [ -z "$UPTIME_KUMA_PUSH_URL" ]; then
    echo "Error: UPTIME_KUMA_PUSH_URL environment variable is not set."
    exit 1
fi

# 从环境变量获取网卡名称，如果未设置，则默认为 eth0
INTERFACE=${MONITOR_INTERFACE:-eth0}
# 存储上一次网络统计数据的临时文件
STATS_FILE="/tmp/net_stats.last"

# --- 1. 获取 CPU 使用率 (需要 --pid="host") ---
CPU_IDLE=$(top -b -n 1 | grep "%Cpu(s)" | awk '{print $8}' || echo "0")
if [ -z "$CPU_IDLE" ] || ! [[ "$CPU_IDLE" =~ ^[0-9.]+$ ]]; then
    CPU_IDLE="0"
fi
CPU_USAGE=$(echo "100 - $CPU_IDLE" | bc -l || echo "0")

# --- 2. 获取内存使用率 (需要 --pid="host") ---
MEM_INFO=$(free -m | grep Mem || echo "")
if [ -n "$MEM_INFO" ]; then
    MEM_TOTAL=$(echo "$MEM_INFO" | awk '{print $2}')
    MEM_USED=$(echo "$MEM_INFO" | awk '{print $3}')
    if [ "$MEM_TOTAL" -gt 0 ] 2>/dev/null; then
        MEM_USAGE=$(echo "scale=2; $MEM_USED / $MEM_TOTAL * 100" | bc -l)
    else
        MEM_USAGE="0"
    fi
else
    MEM_USAGE="0"
fi

# --- 3. 获取磁盘使用率 (需要 -v /:/host_root:ro) ---
DISK_USAGE=$(df -h /host_root 2>/dev/null | awk 'NR==2 {print $5}' || echo "0%")
if [ -z "$DISK_USAGE" ]; then
    DISK_USAGE="0%"
fi

# --- 4. 计算网络平均速率 (需要 -v /proc:/host_proc:ro) ---
NET_RX_RATE=0
NET_TX_RATE=0

# 从宿主机的 /proc 文件系统读取当前的网络字节数
CURRENT_STATS=$(grep "${INTERFACE}:" /host_proc/net/dev 2>/dev/null | awk '{print $2, $10}' || echo "")
if [ -n "$CURRENT_STATS" ]; then
    CURRENT_TIME=$(date +%s)
    CURRENT_RX_BYTES=$(echo "$CURRENT_STATS" | awk '{print $1}')
    CURRENT_TX_BYTES=$(echo "$CURRENT_STATS" | awk '{print $2}')

    # 如果存在上一次的记录文件，则进行计算
    if [ -f "$STATS_FILE" ]; then
        # 读取上一次的记录
        LAST_STATS=$(cat "$STATS_FILE" 2>/dev/null || echo "")
        if [ -n "$LAST_STATS" ]; then
            LAST_TIME=$(echo "$LAST_STATS" | awk '{print $1}')
            LAST_RX_BYTES=$(echo "$LAST_STATS" | awk '{print $2}')
            LAST_TX_BYTES=$(echo "$LAST_STATS" | awk '{print $3}')

            # 计算时间差和字节差
            TIME_DIFF=$((CURRENT_TIME - LAST_TIME))
            RX_BYTES_DIFF=$((CURRENT_RX_BYTES - LAST_RX_BYTES))
            TX_BYTES_DIFF=$((CURRENT_TX_BYTES - LAST_TX_BYTES))

            # 避免除以零的错误
            if [ "$TIME_DIFF" -gt 0 ] && [ "$RX_BYTES_DIFF" -ge 0 ] && [ "$TX_BYTES_DIFF" -ge 0 ]; then
                # 计算速率 (Bytes/s)，然后转换为 KB/s
                NET_RX_RATE=$(echo "scale=2; $RX_BYTES_DIFF / $TIME_DIFF / 1024" | bc -l 2>/dev/null || echo "0")
                NET_TX_RATE=$(echo "scale=2; $TX_BYTES_DIFF / $TIME_DIFF / 1024" | bc -l 2>/dev/null || echo "0")
            fi
        fi
    fi

    # 将当前数据写入文件，供下一次使用
    echo "$CURRENT_TIME $CURRENT_RX_BYTES $CURRENT_TX_BYTES" > "$STATS_FILE" 2>/dev/null || true
else
    echo "Warning: Network interface '${INTERFACE}' not found in /host_proc/net/dev."
fi

# --- 5. 格式化消息 ---
MSG=$(printf "CPU: %.1f%% | RAM: %.1f%% | Disk: %s | Net RX: %.1f KB/s | Net TX: %.1f KB/s" \
"$CPU_USAGE" "$MEM_USAGE" "$DISK_USAGE" "$NET_RX_RATE" "$NET_TX_RATE" 2>/dev/null || echo "CPU: 0% | RAM: 0% | Disk: 0% | Net RX: 0 KB/s | Net TX: 0 KB/s")

# --- 6. URL编码消息并发送 ---
ENCODED_MSG=$(printf %s "$MSG" | jq -s -R -r @uri 2>/dev/null || echo "monitoring_data")

# --- 7. 发送数据到 Uptime Kuma ---
FINAL_URL="${UPTIME_KUMA_PUSH_URL}&msg=${ENCODED_MSG}"

# 执行推送
if curl -s --fail --max-time 30 "$FINAL_URL" > /dev/null 2>&1; then
    # 打印日志（方便调试）
    echo "$(date): Pushed data: $MSG"
else
    echo "$(date): Failed to push data: $MSG"
fi