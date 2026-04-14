# API Reference

The notApollo diagnostic API provides comprehensive network monitoring data through RESTful endpoints. All responses are in JSON format with consistent structure and user-friendly messaging.

## Base URL

- Primary Network: `http://192.168.69.1:8080/api`
- Guest Network: `http://192.168.70.1:8080/api`

## Authentication

Currently, no authentication is required as the service is only accessible from internal networks. Future versions may include optional authentication.

## Response Format

All API responses follow this standard format:

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "healthy|degraded|broken",
  "user_friendly_status": "Everything is working great!",
  "data": {
    // Endpoint-specific data
  },
  "error": null
}
```

### Status Levels

- **healthy** (🟢): All systems operating normally
- **degraded** (🟡): Some issues detected but service functional
- **broken** (🔴): Critical issues requiring attention

## Endpoints

### System Health

#### GET /api/diagnostics/system

Returns comprehensive system health information.

**Response:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "healthy",
  "user_friendly_status": "Router is running smoothly",
  "data": {
    "uptime": 86400,
    "uptime_friendly": "1 day, 0 hours",
    "last_reboot": "2024-01-14T10:30:00Z",
    "last_reboot_friendly": "Yesterday at 10:30 AM",
    "reboot_count_24h": 0,
    "reboot_count_7d": 1,
    "config_changed": "2024-01-10T15:45:00Z",
    "config_changed_friendly": "5 days ago",
    "management_mode": "local",
    "management_mode_friendly": "Managed locally",
    "load_average": [0.15, 0.18, 0.12],
    "load_friendly": "Very light usage",
    "memory_usage": {
      "total": 134217728,
      "used": 67108864,
      "free": 67108864,
      "percentage": 50,
      "friendly": "Memory usage is normal"
    },
    "temperature": {
      "cpu": 45,
      "friendly": "Temperature is good"
    }
  }
}
```

### WAN/Internet Diagnostics

#### GET /api/diagnostics/wan

Monitors WAN interface and internet connectivity.

**Response:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "healthy",
  "user_friendly_status": "Internet connection is working perfectly",
  "data": {
    "interface_state": "up",
    "interface_friendly": "Connection is active",
    "ip_assigned": true,
    "ip_address": "203.0.113.45",
    "ip_friendly": "Got internet address successfully",
    "gateway_reachable": true,
    "gateway_ip": "203.0.113.1",
    "gateway_friendly": "Can reach internet gateway",
    "internet_reachable": true,
    "internet_friendly": "Can reach websites on the internet",
    "dhcp_lease_stable": true,
    "dhcp_friendly": "Internet address lease is stable",
    "packet_loss": {
      "1m": 0.0,
      "5m": 0.1,
      "15m": 0.05,
      "friendly": "No data is being lost"
    },
    "latency": {
      "current": 12,
      "baseline": 10,
      "spike_detected": false,
      "friendly": "Response time is excellent"
    },
    "link_flaps_24h": 0,
    "link_friendly": "Connection has been stable",
    "bandwidth": {
      "rx_bytes": 1073741824,
      "tx_bytes": 268435456,
      "rx_friendly": "Downloaded 1.0 GB today",
      "tx_friendly": "Uploaded 256 MB today"
    }
  }
}
```

### WiFi/Radio Diagnostics

#### GET /api/diagnostics/wifi

Provides detailed WiFi radio and client information.

**Response:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "healthy",
  "user_friendly_status": "WiFi is working great on all bands",
  "data": {
    "radios": {
      "2.4ghz": {
        "state": "up",
        "state_friendly": "2.4GHz WiFi is on",
        "channel": 13,
        "channel_friendly": "Using channel 13 (good choice)",
        "clients": 3,
        "clients_friendly": "3 devices connected",
        "signal_avg": -45,
        "signal_friendly": "Signal strength is strong",
        "tx_power": 20,
        "tx_power_friendly": "Transmit power is optimal",
        "tx_retries": 0.02,
        "tx_retries_friendly": "Very few transmission retries",
        "rx_errors": 0,
        "rx_errors_friendly": "No reception errors",
        "channel_utilization": 15,
        "utilization_friendly": "Channel is not crowded"
      },
      "5ghz": {
        "state": "up",
        "state_friendly": "5GHz WiFi is on",
        "channel": 100,
        "channel_friendly": "Using DFS channel 100",
        "clients": 5,
        "clients_friendly": "5 devices connected",
        "signal_avg": -38,
        "signal_friendly": "Signal strength is excellent",
        "tx_power": 23,
        "tx_power_friendly": "Transmit power is optimal",
        "tx_retries": 0.01,
        "tx_retries_friendly": "Almost no transmission retries",
        "rx_errors": 0,
        "rx_errors_friendly": "No reception errors",
        "channel_utilization": 8,
        "utilization_friendly": "Channel is very clear"
      }
    },
    "total_clients": 8,
    "total_clients_friendly": "8 devices connected to WiFi",
    "dfs_events_24h": 0,
    "dfs_friendly": "No radar interference detected"
  }
}
```

### Router Health

#### GET /api/diagnostics/router

Monitors router hardware health and performance.

**Response:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "healthy",
  "user_friendly_status": "Router hardware is performing well",
  "data": {
    "cpu": {
      "usage_percent": 15,
      "load_1m": 0.15,
      "load_5m": 0.18,
      "load_15m": 0.12,
      "friendly": "CPU usage is very low"
    },
    "memory": {
      "total_mb": 128,
      "used_mb": 64,
      "free_mb": 64,
      "usage_percent": 50,
      "friendly": "Memory usage is normal"
    },
    "temperature": {
      "cpu_celsius": 45,
      "status": "normal",
      "friendly": "Temperature is comfortable"
    },
    "processes": {
      "total": 45,
      "crashed_24h": 0,
      "friendly": "All processes running normally"
    },
    "watchdog": {
      "resets_24h": 0,
      "friendly": "No watchdog resets detected"
    },
    "storage": {
      "root_usage_percent": 65,
      "tmp_usage_percent": 25,
      "friendly": "Storage usage is reasonable"
    }
  }
}
```

### ONT/Fiber Diagnostics

#### GET /api/diagnostics/ont

Provides ONT status and fiber connectivity information.

**Response:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "healthy",
  "user_friendly_status": "Fiber connection looks good",
  "data": {
    "ethernet_link": {
      "state": "up",
      "speed": "1000",
      "duplex": "full",
      "friendly": "Ethernet connection to fiber box is working"
    },
    "ont_reachable": true,
    "ont_friendly": "Can communicate with fiber box",
    "power_events_24h": 0,
    "power_friendly": "No power interruptions detected",
    "led_guidance": {
      "power": {
        "expected": "solid_green",
        "meaning": "Power is good",
        "troubleshoot": "If not green, check power cable"
      },
      "fiber": {
        "expected": "solid_green", 
        "meaning": "Fiber signal is strong",
        "troubleshoot": "If not green, check fiber cable connections"
      },
      "ethernet": {
        "expected": "solid_green",
        "meaning": "Ethernet connection is active",
        "troubleshoot": "If not green, check ethernet cable"
      },
      "internet": {
        "expected": "solid_green",
        "meaning": "Internet service is active",
        "troubleshoot": "If not green, contact your internet provider"
      }
    }
  }
}
```

### DNS Services

#### GET /api/diagnostics/dns

Monitors DNS health across both networks with cache integration.

**Response:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "healthy",
  "user_friendly_status": "Website lookups are working fast on both networks",
  "data": {
    "primary_network": {
      "profile_id": "8753a1",
      "resolution_working": true,
      "response_time_ms": 15,
      "response_friendly": "Very fast website lookups",
      "cache_hit_rate": 0.85,
      "cache_performance": "excellent",
      "cache_friendly": "Cache is working very well",
      "dnsproxy_status": "running",
      "dnsproxy_port": 5354,
      "dnsproxy_cache_size_mb": 8,
      "dnsproxy_cache_utilization": 0.45
    },
    "dad_network": {
      "profile_id": "5414da",
      "resolution_working": true,
      "response_time_ms": 18,
      "response_friendly": "Fast website lookups",
      "cache_hit_rate": 0.82,
      "cache_performance": "good",
      "cache_friendly": "Cache is working well",
      "dnsproxy_status": "running",
      "dnsproxy_port": 5355,
      "dnsproxy_cache_size_mb": 8,
      "dnsproxy_cache_utilization": 0.38
    },
    "query_usage": {
      "monthly_limit": 300000,
      "queries_used_today": 1250,
      "estimated_monthly_usage": 38750,
      "budget_status": "well_under_limit",
      "budget_friendly": "Query usage is very reasonable",
      "cache_efficiency_factor": 0.85,
      "optimization_active": true
    },
    "architecture": {
      "dnsmasq_cache": "disabled",
      "dnsproxy_instances": 2,
      "cache_strategy": "dnsproxy_only",
      "friendly": "DNS caching is optimized for performance"
    }
  }
}
```

### Complete Diagnostics

#### GET /api/diagnostics/all

Returns all diagnostic data in a single response.

**Response:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "healthy",
  "user_friendly_status": "All systems are working great!",
  "data": {
    "system": { /* System health data */ },
    "wan": { /* WAN diagnostics data */ },
    "wifi": { /* WiFi diagnostics data */ },
    "router": { /* Router health data */ },
    "ont": { /* ONT diagnostics data */ },
    "dns": { /* DNS services data */ }
  }
}
```

### Real-Time Updates

#### GET /api/diagnostics/stream

Server-Sent Events endpoint for real-time updates.

**Headers:**
```
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive
```

**Event Format:**
```
data: {"timestamp": "2024-01-15T10:30:00Z", "type": "system", "data": {...}}

data: {"timestamp": "2024-01-15T10:30:01Z", "type": "wan", "data": {...}}
```

## System Control

### Router Reboot

#### POST /api/system/reboot

Initiates router reboot with safety countdown.

**Request:**
```json
{
  "confirm": true,
  "safety_acknowledged": true
}
```

**Response:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "accepted",
  "message": "Reboot initiated with safety countdown",
  "data": {
    "countdown_seconds": 5,
    "estimated_reboot_time": 90,
    "safety_message": "Think carefully... rebooting in 5 seconds"
  }
}
```

#### GET /api/system/reboot-status

Gets current reboot progress.

**Response:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "in_progress",
  "data": {
    "stage": "countdown|preparing|rebooting|starting|complete",
    "message": "Router is restarting...",
    "estimated_seconds_remaining": 45,
    "progress_percent": 50
  }
}
```

### ONT Guidance

#### GET /api/ont/guidance

Provides contextual ONT troubleshooting guidance.

**Response:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "guidance_available",
  "data": {
    "current_issue": "wan_connectivity",
    "steps": [
      {
        "step": 1,
        "title": "Check ONT Power LED",
        "description": "Look at the fiber box power light",
        "expected": "Solid green light",
        "if_different": "Check power cable connection"
      },
      {
        "step": 2,
        "title": "Check Fiber LED",
        "description": "Look at the fiber signal light",
        "expected": "Solid green light",
        "if_different": "Check fiber cable is securely connected"
      }
    ],
    "emergency_contact": "Call your internet provider if all lights are correct"
  }
}
```

## Error Handling

### Error Response Format

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "error",
  "error": {
    "code": "DIAGNOSTIC_FAILED",
    "message": "Unable to collect system information",
    "user_friendly": "Having trouble checking system status",
    "details": "Command timeout after 5 seconds"
  },
  "data": null
}
```

### Common Error Codes

- **DIAGNOSTIC_FAILED**: Unable to collect diagnostic data
- **NETWORK_UNREACHABLE**: Network connectivity issues
- **PERMISSION_DENIED**: Insufficient permissions for system access
- **TIMEOUT**: Operation timed out
- **INVALID_REQUEST**: Malformed request data
- **SERVICE_UNAVAILABLE**: Required service is not running

## Rate Limiting

API endpoints are rate-limited to prevent abuse:

- **Diagnostic endpoints**: 60 requests per minute
- **System control**: 5 requests per minute
- **Real-time stream**: 1 connection per IP

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1642248600
```

## Caching

Diagnostic data is cached to improve performance:

- **System metrics**: 30 second cache
- **Network status**: 10 second cache
- **DNS queries**: Smart caching based on performance
- **Static data**: 5 minute cache

Cache headers indicate freshness:
```
Cache-Control: max-age=30
Last-Modified: Mon, 15 Jan 2024 10:30:00 GMT
ETag: "abc123"
```

## Security

### Input Validation

All inputs are validated and sanitized:
- Command injection prevention
- Path traversal protection
- Input length limits
- Character set restrictions

### Access Control

- Internal network access only
- No WAN interface exposure
- Optional IP-based restrictions
- Session timeout controls

### Audit Logging

Administrative actions are logged:
- Reboot requests and execution
- Configuration changes
- Failed authentication attempts
- Suspicious activity patterns