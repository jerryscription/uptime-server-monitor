# Uptime Push Server Status Monitor

Docker container for monitoring server status and pushing metrics to Uptime Kuma.

## Environment Variables

### Required
- `UPTIME_KUMA_PUSH_URL` - The push URL from your Uptime Kuma monitor

### Optional
- `MONITOR_INTERVAL` - Monitoring interval in seconds (default: 60)
- `MONITOR_INTERFACE` - Network interface to monitor (default: eth0)

## Usage

### Basic usage (every 60 seconds)
```bash
docker run -d \
  --name uptime-monitor \
  --pid=host \
  -v /:/host_root:ro \
  -v /proc:/host_proc:ro \
  -e UPTIME_KUMA_PUSH_URL="https://your-uptime-kuma.com/api/push/xxxxx" \
  jerryscript/uptime-server-monitor:latest
```

### Custom interval (every 30 seconds)
```bash
docker run -d \
  --name uptime-monitor \
  --pid=host \
  -v /:/host_root:ro \
  -v /proc:/host_proc:ro \
  -e UPTIME_KUMA_PUSH_URL="https://your-uptime-kuma.com/api/push/xxxxx" \
  -e MONITOR_INTERVAL=30 \
  jerryscript/uptime-server-monitor:latest
```

### High frequency monitoring (every 5 seconds)
```bash
docker run -d \
  --name uptime-monitor \
  --pid=host \
  -v /:/host_root:ro \
  -v /proc:/host_proc:ro \
  -e UPTIME_KUMA_PUSH_URL="https://your-uptime-kuma.com/api/push/xxxxx" \
  -e MONITOR_INTERVAL=5 \
  jerryscript/uptime-server-monitor:latest
```

### Custom network interface
```bash
docker run -d \
  --name uptime-monitor \
  --pid=host \
  -v /:/host_root:ro \
  -v /proc:/host_proc:ro \
  -e UPTIME_KUMA_PUSH_URL="https://your-uptime-kuma.com/api/push/xxxxx" \
  -e MONITOR_INTERFACE=ens33 \
  jerryscript/uptime-server-monitor:latest
```

## Monitored Metrics

- **CPU Usage** - Current CPU utilization percentage
- **Memory Usage** - RAM utilization percentage  
- **Disk Usage** - Root filesystem usage percentage
- **Network RX Rate** - Network receive rate in KB/s
- **Network TX Rate** - Network transmit rate in KB/s

## Docker Images

- `jerryscript/uptime-server-monitor:latest` (Alpine)
- `jerryscript/uptime-server-monitor:latest-alpine`
- `jerryscript/uptime-server-monitor:latest-debian`