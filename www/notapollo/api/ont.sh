#!/bin/sh
# notApollo ONT API - ONT/Fiber diagnostics and monitoring
# Handles ONT LED status and fiber connectivity

echo "Content-Type: application/json"
echo "Cache-Control: no-cache"
echo "Access-Control-Allow-Origin: *"
echo ""

# Get query parameters
ACTION=$(echo "$QUERY_STRING" | sed -n 's/.*action=\([^&]*\).*/\1/p')

case "$ACTION" in
    "status")
        # ONT LED status (simulated - actual implementation would check hardware)
        POWER_LED="green"
        FIBER_LED="green"
        ETHERNET_LED="green"
        INTERNET_LED="green"
        LINK_QUALITY=95
        
        # Check if WAN interface is up as indicator
        if ip link show wan 2>/dev/null | grep -q "state UP"; then
            ETHERNET_LED="green"
            INTERNET_LED="green"
        else
            ETHERNET_LED="red"
            INTERNET_LED="red"
            LINK_QUALITY=0
        fi
        
        # Check internet connectivity
        if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
            INTERNET_LED="red"
            LINK_QUALITY=$((LINK_QUALITY - 20))
        fi
        
        echo "{
            \"power_led\": \"$POWER_LED\",
            \"fiber_led\": \"$FIBER_LED\",
            \"ethernet_led\": \"$ETHERNET_LED\",
            \"internet_led\": \"$INTERNET_LED\",
            \"link_quality\": $LINK_QUALITY
        }"
        ;;
        
    *)
        echo "{\"error\": \"Unknown action: $ACTION\"}"
        ;;
esac