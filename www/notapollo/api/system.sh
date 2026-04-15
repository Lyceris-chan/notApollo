#!/bin/sh
# notApollo System API - System health and control
# Handles system status, reboot, and configuration

echo "Content-Type: application/json"
echo "Cache-Control: no-cache"
echo "Access-Control-Allow-Origin: *"
echo ""

# Get query parameters
ACTION=$(echo "$QUERY_STRING" | sed -n 's/.*action=\([^&]*\).*/\1/p')

case "$ACTION" in
    "health")
        # System health information
        UPTIME=$(cat /proc/uptime | cut -d' ' -f1)
        CPU_USAGE=$(top -bn1 | grep "CPU:" | awk '{print $2}' | sed 's/%//' || echo "0")
        MEMORY_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        MEMORY_FREE=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        MEMORY_USAGE=$(awk "BEGIN {printf \"%.1f\", (($MEMORY_TOTAL - $MEMORY_FREE) / $MEMORY_TOTAL) * 100}")
        LOAD_AVG=$(cat /proc/loadavg | cut -d' ' -f1-3)
        TEMPERATURE="N/A"
        
        # Try to get temperature if available
        if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
            TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp)
            TEMPERATURE=$(awk "BEGIN {printf \"%.1f\", $TEMP_RAW / 1000}")
        fi
        
        # Count reboots in last 24 hours (simplified)
        REBOOTS_24H=0
        if [ -f /var/log/messages ]; then
            REBOOTS_24H=$(grep -c "kernel.*Linux version" /var/log/messages | tail -1 || echo "0")
        fi
        
        echo "{
            \"uptime\": $UPTIME,
            \"cpu_usage\": $CPU_USAGE,
            \"memory_usage\": $MEMORY_USAGE,
            \"temperature\": \"$TEMPERATURE\",
            \"load_average\": [$LOAD_AVG],
            \"reboots_24h\": $REBOOTS_24H,
            \"processes\": $(ps | wc -l)
        }"
        ;;
        
    "resources")
        # Detailed resource information
        CPU_USAGE=$(top -bn1 | grep "CPU:" | awk '{print $2}' | sed 's/%//' || echo "0")
        MEMORY_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        MEMORY_FREE=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        MEMORY_USAGE=$(awk "BEGIN {printf \"%.1f\", (($MEMORY_TOTAL - $MEMORY_FREE) / $MEMORY_TOTAL) * 100}")
        DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
        
        echo "{
            \"cpu_usage\": $CPU_USAGE,
            \"memory_usage\": $MEMORY_USAGE,
            \"disk_usage\": $DISK_USAGE,
            \"temperature\": \"N/A\",
            \"processes\": $(ps | wc -l)
        }"
        ;;
        
    "network_info")
        # Network interface information
        echo "{
            \"interfaces\": [
                {
                    \"name\": \"br-lan\",
                    \"subnet\": \"192.168.1.0/24\",
                    \"type\": \"bridge\"
                }
            ],
            \"dns_servers\": [\"8.8.8.8\", \"1.1.1.1\"],
            \"gateway\": \"192.168.1.1\"
        }"
        ;;
        
    "client_ip")
        # Get client IP address
        CLIENT_IP="${HTTP_X_FORWARDED_FOR:-$REMOTE_ADDR}"
        echo "{\"client_ip\": \"$CLIENT_IP\"}"
        ;;
        
    "ping")
        # Simple ping response for restart monitoring
        echo "{\"status\": \"ok\", \"timestamp\": $(date +%s)}"
        ;;
        
    *)
        echo "{\"error\": \"Unknown action: $ACTION\"}"
        ;;
esac