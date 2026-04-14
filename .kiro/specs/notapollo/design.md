# Design Document

## Architecture Overview

The notApollo diagnostic webpage follows a client-server architecture optimized for OpenWrt routers. The system consists of a lightweight HTTP server serving static assets and a real-time diagnostic API that collects system metrics through OpenWrt's native interfaces.

### System Components

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Web Browser   │◄──►│  HTTP Server     │◄──►│ Diagnostic API  │
│  (Material 3)   │    │  (uhttpd/nginx)  │    │   (Shell/UCI)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  Static Assets   │    │ System Metrics  │
                       │ (HTML/CSS/JS)    │    │ (proc/sys/uci)  │
                       └──────────────────┘    └─────────────────┘
```

## Technical Stack

### Frontend
- **Framework**: Vanilla JavaScript (ES6+) with Web Components
- **Styling**: Material 3 CSS with custom properties
- **Typography**: Google Sans Flex font family
- **Charts**: Chart.js (bundled locally)
- **Icons**: Material Symbols (bundled locally)

### Backend
- **Server**: OpenWrt uhttpd or lightweight HTTP daemon
- **API**: Shell scripts with JSON output
- **Data Sources**: /proc, /sys, UCI, iwinfo, ip commands
- **Real-time**: Server-Sent Events (SSE) for live updates

### Network Architecture
- **Dual Interface Binding**: Listen on both 192.168.69.1 and 192.168.70.1
- **Port**: HTTP on port 8080 (non-conflicting with LuCI on 80/443)
- **Protocol**: HTTP/1.1 with keep-alive for efficiency

## Data Collection Strategy

### System Health Metrics
```bash
# Uptime and boot information
/proc/uptime                    # System uptime in seconds
/proc/stat                      # Boot time and CPU stats
/tmp/sysinfo/model             # Device model information
uci show system.@system[0]     # System configuration

# Reboot tracking
/tmp/reboot_counter            # Custom counter file
journalctl --since="24 hours ago" | grep reboot  # Recent reboots
```

### WAN/Internet Diagnostics
```bash
# Interface status
ip link show wan               # Physical link state
uci show network.wan           # Interface configuration
ifstatus wan                   # Logical interface status

# Connectivity testing
ping -c 3 -W 2 $(ip route | awk '/default/ {print $3}')  # Gateway
ping -c 3 -W 2 8.8.8.8        # Internet connectivity
nslookup google.com            # DNS resolution

# Traffic statistics
cat /sys/class/net/wan/statistics/{rx_bytes,tx_bytes,rx_errors,tx_errors}
```

### WiFi/Radio Diagnostics
```bash
# Radio status
iwinfo                         # Wireless interface information
iw dev                         # Device information
iw phy                         # Physical radio information

# Client information
iwinfo wlan0 assoclist         # Associated clients
iwinfo wlan0 txpower           # Transmission power
iwinfo wlan0 frequency         # Operating frequency

# Signal quality
iwinfo wlan0 info              # Signal strength and quality
```

### Router Health Monitoring
```bash
# CPU and memory
cat /proc/loadavg              # CPU load averages
cat /proc/meminfo              # Memory usage statistics
top -bn1                       # Process information

# Temperature (if available)
cat /sys/class/thermal/thermal_zone*/temp  # Thermal sensors

# System logs
logread | tail -100            # Recent system messages
dmesg | grep -i error          # Kernel error messages
```

### DNS Health Monitoring with Cache Integration
```bash
# Smart DNS testing with cache performance monitoring
# Monitor dnsmasq cache performance
cat /tmp/dnsmasq.log | grep -c "cached"   # Cache hit rate
grep "cache size" /tmp/dnsmasq.log        # Cache utilization

# Monitor dnsproxy cache efficiency (8MB cache, 300s min TTL, 3600s max TTL)
# Primary dnsproxy (127.0.0.1:5354) for main network
# Dad's dnsproxy (192.168.70.1:5355) for Dad's network
netstat -tulpn | grep ":535[45]"          # Verify dnsproxy listeners

# Cache-aware DNS testing with dynamic frequency adjustment
# High cache hit rate (>80%) -> Reduce testing frequency to 15-minute intervals
# Low cache hit rate (<60%) -> Increase testing frequency to 5-minute intervals
# Normal cache hit rate (60-80%) -> Standard 10-minute intervals

# Primary Network DNS Testing (NextDNS profile 8753a1)
nslookup google.com 192.168.69.1     # Test primary DNS resolution
dig @192.168.69.1 cloudflare.com +short  # Quick resolution test

# Dad's Network DNS Testing (NextDNS profile 5414da)  
nslookup google.com 192.168.70.1     # Test Dad's DNS resolution
dig @192.168.70.1 cloudflare.com +short  # Quick resolution test

# Query budget tracking with cache efficiency factoring
echo $(($(date +%s) - $(date -d "$(date +%Y-%m-01)" +%s))) # Days in month
# Smart scheduling: 300000 queries / days_in_month = daily_budget
# Adjust budget based on cache performance: high hit rate = lower query needs

# DNS Architecture Monitoring (from monolith.sh):
# devices -> dnsmasq:53 -> dnsproxy 127.0.0.1:5354 -> NextDNS (primary)
# Dad's devices -> DNAT :53->:5355 -> dnsproxy 192.168.70.1:5355 -> NextDNS (Dad's)
# dnsmasq: cache disabled (cachesize=0), noresolv mode
# dnsproxy: 8MB cache, 300s min TTL, 3600s max TTL for both instances
```

### ONT Guidance System
```bash
# ONT LED status interpretation guide
# Power LED: Solid Green = Normal, Red/Off = Power issue
# Fiber LED: Solid Green = Good signal, Red/Blinking = Fiber issue  
# Ethernet LED: Solid Green = Link up, Off = No connection
# Internet LED: Solid Green = Online, Red/Blinking = Auth/Service issue

# Automated ONT connectivity testing
ping -c 1 -W 2 192.168.1.1           # Test ONT web interface (common IP)
ethtool eth0 | grep "Link detected"   # Check physical Ethernet link
cat /sys/class/net/eth0/carrier       # Carrier detect status
```

### User-Friendly Language Translation
```bash
# Status message translation system
# Technical -> Plain Language mappings:
# "Interface down" -> "Internet connection is not working"
# "High packet loss" -> "Some data is getting lost on the way"
# "DNS timeout" -> "Having trouble finding websites"
# "Signal strength -70dBm" -> "WiFi signal is good"
# "CPU load 0.8" -> "Router is running normally"
```

## User Interface Design

### Layout Structure
```
┌─────────────────────────────────────────────────────────────┐
│                     App Bar (notApollo)                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   System    │  │     WAN     │  │    WiFi     │        │
│  │   Health    │  │  Internet   │  │   Radio     │        │
│  │  🟢 Healthy │  │ 🟡 Degraded │  │ 🟢 Healthy  │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Router    │  │ ONT/Fiber   │  │    DNS      │        │
│  │   Health    │  │   Layer     │  │  Services   │        │
│  │ 🟢 Healthy  │  │ 🟢 Healthy  │  │ 🟢 Healthy  │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │              Router Control Section                   │ │
│  │  ┌─────────────────┐  ┌─────────────────┐            │ │
│  │  │  Restart Router │  │  ONT Guidance   │            │ │
│  │  │     Button      │  │     Panel       │            │ │
│  │  └─────────────────┘  └─────────────────┘            │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │              Real-time Graphs Section                 │ │
│  │  ┌─────────────────┐  ┌─────────────────┐            │ │
│  │  │  Latency Trend  │  │  DNS Response   │            │ │
│  │  │      Chart      │  │     Times       │            │ │
│  │  └─────────────────┘  └─────────────────┘            │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Material 3 Component Specifications

#### Color Scheme
```css
:root {
  /* Material 3 Dark Theme Dynamic Color Tokens */
  --md-sys-color-primary: #a8c7fa;
  --md-sys-color-on-primary: #002e69;
  --md-sys-color-primary-container: #004494;
  --md-sys-color-on-primary-container: #d3e3fd;
  
  --md-sys-color-surface: #101418;
  --md-sys-color-on-surface: #e2e2e9;
  --md-sys-color-surface-variant: #44474f;
  --md-sys-color-on-surface-variant: #c4c6d0;
  
  --md-sys-color-background: #0f1419;
  --md-sys-color-on-background: #e2e2e9;
  
  /* Status Colors (Dark Theme Optimized) */
  --status-healthy: #4caf50;
  --status-degraded: #ff9800;
  --status-broken: #f44336;
  
  /* ONT Guidance Colors */
  --ont-led-power: #4caf50;
  --ont-led-fiber: #2196f3;
  --ont-led-ethernet: #ff9800;
  --ont-led-internet: #9c27b0;
}
```

#### Typography Scale
```css
.headline-large {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 2rem;
  font-weight: 400;
  line-height: 2.5rem;
}

.title-medium {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 1rem;
  font-weight: 500;
  line-height: 1.5rem;
}

.body-medium {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 0.875rem;
  font-weight: 400;
  line-height: 1.25rem;
}
```

#### Card Components
```css
.diagnostic-card {
  background: var(--md-sys-color-surface);
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
  padding: 16px;
  margin: 8px;
  transition: box-shadow 0.2s ease;
}

.diagnostic-card:hover {
  box-shadow: 0 4px 8px rgba(0,0,0,0.12), 0 2px 4px rgba(0,0,0,0.08);
}

/* Router Control Components with Safety Features */
.restart-button {
  background: var(--md-sys-color-primary);
  color: var(--md-sys-color-on-primary);
  border: none;
  border-radius: 20px;
  padding: 12px 24px;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  min-height: 44px;
  min-width: 120px;
}

.restart-button:disabled {
  background: var(--md-sys-color-surface-variant);
  color: var(--md-sys-color-on-surface-variant);
  cursor: not-allowed;
  opacity: 0.6;
}

.restart-button:hover:not(:disabled) {
  background: var(--md-sys-color-primary-container);
  transform: translateY(-1px);
}

.restart-countdown {
  background: var(--md-sys-color-error-container);
  color: var(--md-sys-color-on-error-container);
  border-radius: 8px;
  padding: 16px;
  margin-top: 12px;
  text-align: center;
  font-weight: 500;
}

.restart-progress {
  background: var(--md-sys-color-surface-variant);
  border-radius: 8px;
  padding: 16px;
  margin-top: 12px;
}

.safety-message {
  background: var(--md-sys-color-tertiary-container);
  color: var(--md-sys-color-on-tertiary-container);
  border-radius: 8px;
  padding: 12px;
  margin-bottom: 16px;
  font-size: 0.875rem;
  text-align: center;
}

/* ONT Guidance Panel */
.ont-guidance {
  background: var(--md-sys-color-surface-variant);
  border-radius: 12px;
  padding: 16px;
}

.ont-led-indicator {
  display: inline-block;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  margin-right: 8px;
}

.ont-led-power { background: var(--ont-led-power); }
.ont-led-fiber { background: var(--ont-led-fiber); }
.ont-led-ethernet { background: var(--ont-led-ethernet); }
.ont-led-internet { background: var(--ont-led-internet); }

/* User-Friendly Message Styling */
.plain-language {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 0.875rem;
  line-height: 1.4;
  color: var(--md-sys-color-on-surface);
}

.status-explanation {
  background: var(--md-sys-color-surface-variant);
  border-radius: 8px;
  padding: 12px;
  margin-top: 8px;
  font-size: 0.8rem;
  opacity: 0.8;
}
```

### Mobile Responsive Design

#### Breakpoints
```css
/* Mobile First Approach */
.container {
  padding: 8px;
  display: grid;
  grid-template-columns: 1fr;
  gap: 8px;
}

/* Tablet */
@media (min-width: 768px) {
  .container {
    padding: 16px;
    grid-template-columns: repeat(2, 1fr);
    gap: 16px;
  }
}

/* Desktop */
@media (min-width: 1024px) {
  .container {
    padding: 24px;
    grid-template-columns: repeat(3, 1fr);
    gap: 24px;
  }
}
```

#### Touch-Friendly Interactions
- Minimum touch target size: 44px × 44px
- Swipe gestures for card navigation
- Pull-to-refresh for data updates
- Haptic feedback for button interactions (where supported)

## Data Visualization Strategy

### Chart Configuration
```javascript
// Latency Trend Chart
const latencyConfig = {
  type: 'line',
  data: {
    labels: [], // Time labels
    datasets: [{
      label: 'Latency (ms)',
      data: [],
      borderColor: 'var(--md-sys-color-primary)',
      backgroundColor: 'var(--md-sys-color-primary-container)',
      tension: 0.4
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    scales: {
      y: {
        beginAtZero: true,
        title: {
          display: true,
          text: 'Latency (ms)'
        }
      }
    }
  }
};

// Signal Strength Chart
const signalConfig = {
  type: 'bar',
  data: {
    labels: ['2.4GHz', '5GHz'],
    datasets: [{
      label: 'Signal Strength (dBm)',
      data: [],
      backgroundColor: [
        'var(--status-healthy)',
        'var(--status-healthy)'
      ]
    }]
  }
};
```

### Real-time Updates
```javascript
// Server-Sent Events for live data
const eventSource = new EventSource('/api/diagnostics/stream');

eventSource.onmessage = function(event) {
  const data = JSON.parse(event.data);
  updateDashboard(data);
  updateCharts(data);
};

// Fallback polling for older browsers
if (!window.EventSource) {
  setInterval(fetchDiagnostics, 5000);
}
```

## API Design

### Endpoint Structure
```
GET /api/diagnostics/system     # System health data
GET /api/diagnostics/wan        # WAN/Internet status
GET /api/diagnostics/wifi       # WiFi/Radio information
GET /api/diagnostics/router     # Router health metrics
GET /api/diagnostics/ont        # ONT/Fiber diagnostics
GET /api/diagnostics/dns        # DNS health for both networks with cache data
GET /api/diagnostics/all        # Complete diagnostic data
GET /api/diagnostics/stream     # Server-Sent Events stream

POST /api/system/reboot         # Trigger system reboot with safety countdown
GET /api/system/reboot-status   # Get reboot progress status
GET /api/ont/guidance           # Get ONT troubleshooting guidance
GET /api/dns/query-usage        # Get NextDNS query usage statistics
GET /api/dns/cache-stats        # Get DNS cache performance metrics
GET /api/system/health-check    # Comprehensive system health validation
```

### Response Format
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "healthy|degraded|broken",
  "user_friendly_status": "Everything is working great!",
  "system": {
    "uptime": 86400,
    "last_reboot": "2024-01-14T10:30:00Z",
    "reboot_count_24h": 0,
    "reboot_count_7d": 1,
    "config_changed": "2024-01-10T15:45:00Z",
    "management_mode": "local",
    "reboot_in_progress": false,
    "reboot_progress": {
      "stage": "idle|countdown|preparing|rebooting|starting|complete",
      "message": "Router is ready",
      "estimated_seconds_remaining": 0,
      "countdown_seconds": 0,
      "safety_delay_active": false
    }
  },
  "wan": {
    "interface_state": "up",
    "ip_assigned": true,
    "gateway_reachable": true,
    "internet_reachable": true,
    "dhcp_lease_stable": true,
    "packet_loss_1m": 0.0,
    "packet_loss_5m": 0.1,
    "latency_current": 12,
    "latency_baseline": 10,
    "link_flaps_24h": 0,
    "user_friendly_message": "Internet connection is working perfectly"
  },
  "wifi": {
    "radios": {
      "2.4ghz": {
        "state": "up",
        "channel": 13,
        "clients": 3,
        "signal_avg": -45,
        "tx_retries": 0.02,
        "rx_errors": 0,
        "user_friendly_signal": "WiFi signal is strong"
      },
      "5ghz": {
        "state": "up", 
        "channel": 100,
        "clients": 5,
        "signal_avg": -38,
        "tx_retries": 0.01,
        "rx_errors": 0,
        "user_friendly_signal": "WiFi signal is excellent"
      }
    }
  },
  "dns": {
    "primary_network": {
      "profile_id": "8753a1",
      "resolution_working": true,
      "response_time_ms": 15,
      "cache_hit_rate": 0.85,
      "cache_performance": "excellent",
      "dnsproxy_cache_size": 8388608,
      "dnsproxy_cache_utilization": 0.45,
      "dnsmasq_cache_disabled": true,
      "user_friendly_status": "Website lookups are working fast"
    },
    "dad_network": {
      "profile_id": "5414da", 
      "resolution_working": true,
      "response_time_ms": 18,
      "cache_hit_rate": 0.82,
      "cache_performance": "good",
      "dnsproxy_cache_size": 8388608,
      "dnsproxy_cache_utilization": 0.38,
      "user_friendly_status": "Website lookups are working well"
    },
    "query_usage": {
      "monthly_limit": 300000,
      "queries_used_today": 1250,
      "estimated_monthly_usage": 38750,
      "budget_status": "well_under_limit",
      "cache_efficiency_factor": 0.85
    },
    "architecture": {
      "primary_path": "devices -> dnsmasq:53 -> dnsproxy:5354 -> NextDNS",
      "dad_path": "Dad's devices -> DNAT:53->5355 -> dnsproxy:5355 -> NextDNS",
      "dnsmasq_cache": "disabled (cachesize=0)",
      "dnsproxy_cache": "8MB, 300s min TTL, 3600s max TTL"
    }
  },
  "ont": {
    "guidance_needed": false,
    "led_status": {
      "power": "solid_green",
      "fiber": "solid_green", 
      "ethernet": "solid_green",
      "internet": "solid_green"
    },
    "troubleshooting_steps": [],
    "user_friendly_status": "Fiber connection looks good"
  }
}
```

## Implementation Strategy

### Phase 1: Core Infrastructure
1. Set up HTTP server with dual interface binding
2. Create basic HTML structure with Material 3 components
3. Implement diagnostic data collection scripts
4. Build REST API endpoints

### Phase 2: User Interface
1. Implement Material 3 design system
2. Create responsive card-based layout
3. Add Google Sans Flex typography
4. Design application icon and branding

### Phase 3: Data Visualization
1. Integrate Chart.js for graphing capabilities
2. Implement real-time data updates via SSE
3. Create interactive chart components
4. Add mobile-optimized chart rendering

### Phase 4: Advanced Features
1. Implement cross-layer correlation logic
2. Add intelligent health status determination
3. Create reboot functionality with progress indication
4. Optimize performance for mobile devices

### Phase 5: Testing and Optimization
1. Test across both network segments
2. Validate mobile responsiveness
3. Performance testing on OpenWrt hardware
4. Security review and hardening

## Security Considerations

### Access Control
- Bind only to internal network interfaces (no WAN exposure)
- Implement basic authentication if required
- Rate limiting for API endpoints to prevent abuse
- Input validation and sanitization for all user inputs
- Protection against command injection attacks
- Secure session management with proper timeouts

### Data Protection
- No sensitive data logging or storage
- Secure handling of system commands with minimal privileges
- Protection against path traversal attacks
- Secure error handling without information disclosure

### Production Security Features
- Comprehensive security headers (CSP, HSTS, X-Frame-Options)
- Request size limits and timeout controls
- Audit logging for administrative actions
- Graceful degradation under attack conditions

## Performance Optimization

### Frontend Optimization
- Minified CSS and JavaScript bundles with compression
- Efficient DOM manipulation with virtual DOM concepts
- Lazy loading for non-critical components
- Service worker for offline functionality and caching
- Progressive loading with skeleton screens
- Optimized image assets and icon fonts

### Backend Optimization
- Cached system metrics with intelligent TTL management
- Efficient shell command execution with connection pooling
- Minimal memory footprint with garbage collection
- Optimized for OpenWrt resource constraints
- Asynchronous processing for long-running operations
- Connection keep-alive and request batching

### Production Performance Features
- CDN-ready static asset organization
- Database connection pooling (if applicable)
- Memory leak prevention and monitoring
- CPU usage optimization with process prioritization
- Network bandwidth optimization with compression

## Deployment Architecture

### File Structure
```
/www/notapollo/
├── index.html
├── css/
│   ├── material3.css
│   └── app.css
├── js/
│   ├── chart.min.js
│   ├── app.js
│   └── diagnostics.js
├── fonts/
│   └── google-sans-flex/
├── icons/
│   └── material-symbols/
└── api/
    ├── diagnostics.sh
    ├── system.sh
    └── reboot.sh
```

### Server Configuration
```nginx
# uhttpd configuration for dual interface
config uhttpd 'notapollo'
    option home '/www/notapollo'
    option rfc1918_filter '0'
    option max_requests '10'
    option max_connections '100'
    option cert '/etc/uhttpd.crt'
    option key '/etc/uhttpd.key'
    list listen_http '192.168.69.1:8080'
    list listen_http '192.168.70.1:8080'
```

This design provides a comprehensive, Material 3-compliant diagnostic webpage that meets all requirements while being optimized for OpenWrt routers and mobile devices.