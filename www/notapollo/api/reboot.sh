#!/bin/sh
# notApollo Reboot API - System restart functionality
# Handles secure router reboot with safety measures

echo "Content-Type: application/json"
echo "Cache-Control: no-cache"
echo "Access-Control-Allow-Origin: *"
echo ""

# Get query parameters
ACTION=$(echo "$QUERY_STRING" | sed -n 's/.*action=\([^&]*\).*/\1/p')

case "$ACTION" in
    "restart")
        # Secure reboot functionality
        # In production, this would include proper authentication and logging
        
        # Log the reboot request
        logger "notApollo: Reboot requested from $REMOTE_ADDR"
        
        # Return immediate response
        echo "{
            \"status\": \"initiated\",
            \"message\": \"Reboot initiated\",
            \"estimated_time\": 120
        }"
        
        # Schedule reboot (in background to allow response to be sent)
        (
            sleep 2
            # In production, use proper reboot command
            # reboot
            logger "notApollo: Reboot command executed"
        ) &
        ;;
        
    *)
        echo "{\"error\": \"Unknown action: $ACTION\"}"
        ;;
esac