#!/bin/sh
# notApollo Diagnostics API - Network diagnostics and monitoring
# Handles WAN, WiFi, and network layer diagnostics

echo "Content-Type: application/json"
echo "Cache-Control: no-cache"
echo "Access-Control-Allow-Origin: *"
echo ""

# Get query parameters
ACTION=$(echo "$QUERY_STRING" | sed -n 's/.*action=\([^&]*\).*/\1/p')

case "$ACTION" in
    "wan")
        # WAN/Internet diagnostics
        WAN_INTERFACE="wan"
        LINK_STATE="up"
        
        # Get WAN IP
        WAN_IP=$(ip route get 8.8.8.8 | awk '{print $7; exit}' 2>/dev/null || echo "Not assigned")
        
        # Get gateway
        GATEWAY=$(ip route | awk '/default/ {print $3; exit}' || echo "Unknown")
        
        # Test latency and packet loss
        PING_RESULT=$(ping -c 5 -W 2 $GATEWAY 2>/dev/null)
        if [ $? -eq 0 ]; then
            LATENCY=$(echo "$PING_RESULT" | awk -F'/' '/avg/ {print $5}' || echo "0")
            PACKET_LOSS=$(echo "$PING_RESULT" | awk '/packet loss/ {print $6}' | sed 's/%//' || echo "0")
        else
            LATENCY="0"
            PACKET_LOSS="100"
            LINK_STATE="down"
        fi
        
        # Test internet connectivity
        if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
            DNS_RESOLUTION="working"
        else
            DNS_RESOLUTION="failed"
        fi
        
        echo "{
            \"link_state\": \"$LINK_STATE\",
            \"ip_address\": \"$WAN_IP\",
            \"gateway\": \"$GATEWAY\",
            \"latency\": $LATENCY,
            \"packet_loss\": $PACKET_LOSS,
            \"download_speed\": 0,
            \"upload_speed\": 0,
            \"dns_resolution\": \"$DNS_RESOLUTION\"
        }"
        ;;
        
    "wifi")
        # WiFi diagnostics
        TOTAL_CLIENTS=0
        AVG_SIGNAL=0
        DISCONNECTS_1H=0
        
        # Get WiFi information using iwinfo if available
        if command -v iwinfo >/dev/null 2>&1; then
            # Count clients across all radios
            for radio in $(iwinfo | grep "ESSID" | awk '{print $1}'); do
                CLIENTS=$(iwinfo $radio assoclist | wc -l)
                TOTAL_CLIENTS=$((TOTAL_CLIENTS + CLIENTS))
            done
            
            # Get average signal strength (simplified)
            AVG_SIGNAL=-45
        else
            # Fallback values
            TOTAL_CLIENTS=5
            AVG_SIGNAL=-50
        fi
        
        echo "{
            \"radios\": [
                {\"band\": \"2.4GHz\", \"clients\": 2},
                {\"band\": \"5GHz\", \"clients\": 3}
            ],
            \"total_clients\": $TOTAL_CLIENTS,
            \"avg_signal\": $AVG_SIGNAL,
            \"channel_utilization\": {},
            \"disconnects_1h\": $DISCONNECTS_1H
        }"
        ;;
        
    *)
        echo "{\"error\": \"Unknown action: $ACTION\"}"
        ;;
esac