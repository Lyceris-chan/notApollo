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

## Universal Network Detection and Adaptive Interface

### Configurable Network-Aware Display Logic

The system automatically detects the router's network configuration and adapts the interface for any OpenWrt setup:

#### Configuration Detection
- **Auto-Discovery**: Detects available network interfaces and their configurations
- **Multi-Network Support**: Handles single or multiple network segments automatically
- **Guest Network Detection**: Identifies guest/isolated networks vs main networks
- **Access Level Determination**: Determines user privileges based on network access patterns

#### Administrative Network Access
- **Full Interface**: Complete access to all diagnostic data, router controls, and configuration
- **Multi-Network Monitoring**: Shows health status for all detected networks
- **Advanced Controls**: Router reboot, configuration changes, detailed system logs
- **Historical Data**: Full access to all logged data and trends

#### Guest/Limited Network Access  
- **Simplified Interface**: Focus on current network performance and basic connectivity
- **Limited Scope**: Shows current network health, internet connectivity, and basic WiFi info
- **User-Friendly Language**: Extra emphasis on plain language explanations
- **Essential Controls**: Basic troubleshooting guidance, connection status checking

```javascript
// Universal Network Detection and Interface Adaptation
class UniversalNetworkInterface {
  constructor() {
    this.config = this.loadConfiguration();
    this.networks = this.detectNetworkTopology();
    this.userContext = this.determineUserContext();
    this.initializeInterface();
  }
  
  loadConfiguration() {
    // Load from UCI or configuration file with sensible defaults
    return {
      admin_networks: [], // Auto-detected admin networks
      guest_networks: [], // Auto-detected guest networks
      interface_bindings: [], // Detected interface bindings
      access_control: 'auto', // auto, permissive, restrictive
      dns_providers: [], // Detected DNS configurations
      monitoring_scope: 'auto', // auto, single, multi
      anonymize_data: true // Remove specific network identifiers
    };
  }
  
  detectNetworkTopology() {
    // Auto-detect network configuration from OpenWrt UCI
    const interfaces = this.getNetworkInterfaces();
    const networks = [];
    
    interfaces.forEach(iface => {
      const network = {
        id: this.generateNetworkId(iface), // Anonymous ID
        name: this.getNetworkDisplayName(iface),
        subnet: iface.subnet,
        type: this.classifyNetworkType(iface),
        access_level: this.determineAccessLevel(iface),
        dns_config: this.getDNSConfig(iface),
        is_admin: this.isAdminNetwork(iface),
        binding_port: this.getBindingPort(iface)
      };
      networks.push(network);
    });
    
    return networks;
  }
  
  classifyNetworkType(interface) {
    // Classify network based on OpenWrt configuration patterns
    const name = interface.name.toLowerCase();
    const config = interface.config || {};
    
    if (name.includes('guest') || config.isolated || config.guest) {
      return 'guest';
    }
    if (name.includes('lan') || config.type === 'bridge' || name === 'br-lan') {
      return 'main';
    }
    if (name.includes('wan') || config.proto === 'dhcp' || config.proto === 'static') {
      return 'wan';
    }
    if (name.includes('mgmt') || name.includes('admin')) {
      return 'management';
    }
    return 'other';
  }
  
  getNetworkDisplayName(interface) {
    // Generate user-friendly network names without exposing specifics
    const type = this.classifyNetworkType(interface);
    const index = this.getNetworkIndex(interface);
    
    switch (type) {
      case 'main': return `Main Network${index > 1 ? ` ${index}` : ''}`;
      case 'guest': return `Guest Network${index > 1 ? ` ${index}` : ''}`;
      case 'management': return 'Management Network';
      case 'wan': return 'Internet Connection';
      default: return `Network ${index}`;
    }
  }
  
  determineUserContext() {
    const clientIP = this.getClientIP();
    const currentNetwork = this.networks.find(net => 
      this.isIPInSubnet(clientIP, net.subnet)
    );
    
    if (!currentNetwork) {
      return this.getDefaultContext();
    }
    
    return {
      network: currentNetwork,
      access_level: this.calculateAccessLevel(currentNetwork),
      show_all_networks: this.shouldShowAllNetworks(currentNetwork),
      admin_controls: this.hasAdminControls(currentNetwork),
      interface_scope: this.determineInterfaceScope(currentNetwork),
      display_name: currentNetwork.name
    };
  }
  
  calculateAccessLevel(network) {
    // Determine access level based on network type and configuration
    if (network.is_admin || network.type === 'management') {
      return 'admin';
    }
    if (network.type === 'main') {
      return 'user';
    }
    if (network.type === 'guest') {
      return 'guest';
    }
    return 'basic';
  }
  
  shouldShowAllNetworks(network) {
    // Admin networks can see all, others see relevant networks only
    return network.is_admin || 
           network.type === 'management' || 
           this.config.access_control === 'permissive';
  }
  
  hasAdminControls(network) {
    // Only admin networks get router control capabilities
    return network.is_admin || 
           network.type === 'management' ||
           (network.type === 'main' && this.config.access_control === 'permissive');
  }
  
  initializeInterface() {
    // Initialize interface based on detected context
    switch (this.userContext.access_level) {
      case 'admin':
        this.showFullDashboard();
        break;
      case 'user':
        this.showUserDashboard();
        break;
      case 'guest':
        this.showGuestDashboard();
        break;
      default:
        this.showBasicDashboard();
    }
    
    // Update network indicator
    this.updateNetworkIndicator();
  }
  
  showFullDashboard() {
    // Complete interface with all networks and admin controls
    this.renderOverviewCards(this.getAllNetworkCards());
    this.renderDetailedAnalytics();
    this.renderHistoricalData();
    this.renderAdminControls();
  }
  
  showUserDashboard() {
    // Standard interface with main network focus
    this.renderOverviewCards(this.getMainNetworkCards());
    this.renderBasicAnalytics();
    this.renderUserControls();
  }
  
  showGuestDashboard() {
    // Simplified interface for guest network users
    this.renderOverviewCards(this.getCurrentNetworkCards());
    this.renderBasicStatus();
    this.renderTroubleshootingGuide();
  }
  
  updateNetworkIndicator() {
    // Update the network indicator in the top bar
    const indicator = document.getElementById('network-indicator');
    const networkName = document.getElementById('network-name');
    
    if (indicator && networkName) {
      indicator.className = `network-indicator ${this.userContext.network.type}`;
      networkName.textContent = this.userContext.display_name;
    }
  }
}
```

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

## Comprehensive Historical Data and Health Tracking

### Data Logging Architecture

```bash
# Historical Data Storage Structure
/tmp/notapollo/
├── metrics/
│   ├── wan_latency.log          # Timestamped latency measurements
│   ├── wan_packet_loss.log      # Packet loss events with details
│   ├── wifi_signal_strength.log # Signal strength per band over time
│   ├── wifi_client_count.log    # Connected clients timeline
│   ├── system_resources.log     # CPU, memory, temperature over time
│   ├── dns_response_times.log   # DNS performance for both networks
│   └── service_health.log       # Overall service health scores
├── events/
│   ├── downtime_events.log      # Internet/service outage tracking
│   ├── wifi_disconnects.log     # WiFi client disconnection events
│   ├── system_reboots.log       # System restart events and reasons
│   ├── configuration_changes.log # Config modification tracking
│   └── error_events.log         # System errors and warnings
└── analysis/
    ├── daily_summary.json       # Daily performance summaries
    ├── weekly_trends.json       # Weekly trend analysis
    └── health_scores.json       # Historical health scoring
```

### Real-Time Data Collection with Historical Context

```bash
# Enhanced WAN Monitoring with Historical Tracking
monitor_wan_performance() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local gateway=$(ip route | awk '/default/ {print $3}')
  
  # Latency measurement with packet loss detection
  local ping_result=$(ping -c 5 -W 2 $gateway 2>/dev/null)
  local latency=$(echo "$ping_result" | awk -F'/' '/avg/ {print $5}')
  local packet_loss=$(echo "$ping_result" | awk '/packet loss/ {print $6}' | sed 's/%//')
  
  # Log detailed metrics
  echo "$timestamp,$latency,$packet_loss,gateway" >> /tmp/notapollo/metrics/wan_latency.log
  
  # Detect and log downtime events
  if [[ -z "$latency" ]] || [[ $(echo "$packet_loss > 50" | bc -l) -eq 1 ]]; then
    echo "$timestamp,WAN_OUTAGE,packet_loss=${packet_loss}%,gateway_unreachable" >> /tmp/notapollo/events/downtime_events.log
  fi
  
  # Internet connectivity test with detailed logging
  local internet_test=$(curl -s -w "%{http_code},%{time_total}" -o /dev/null --max-time 5 http://1.1.1.1)
  local http_code=$(echo "$internet_test" | cut -d',' -f1)
  local response_time=$(echo "$internet_test" | cut -d',' -f2)
  
  if [[ "$http_code" != "200" ]]; then
    echo "$timestamp,INTERNET_OUTAGE,http_code=$http_code,response_time=${response_time}s" >> /tmp/notapollo/events/downtime_events.log
  fi
  
  echo "$timestamp,$response_time,internet_test" >> /tmp/notapollo/metrics/wan_latency.log
}

# WiFi Performance Tracking with Client Analysis
monitor_wifi_performance() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  # Monitor each radio band
  for radio in radio0 radio1 radio2; do
    if iwinfo $radio info >/dev/null 2>&1; then
      local channel=$(iwinfo $radio info | awk '/Channel/ {print $2}')
      local txpower=$(iwinfo $radio info | awk '/Tx-Power/ {print $2}')
      local noise=$(iwinfo $radio info | awk '/Noise/ {print $2}')
      
      # Client analysis with disconnect tracking
      local clients=$(iwinfo $radio assoclist | wc -l)
      local prev_clients=$(tail -1 /tmp/notapollo/metrics/wifi_client_count.log 2>/dev/null | cut -d',' -f3 || echo "0")
      
      if [[ $clients -lt $prev_clients ]]; then
        local disconnects=$((prev_clients - clients))
        echo "$timestamp,$radio,CLIENT_DISCONNECT,count=$disconnects" >> /tmp/notapollo/events/wifi_disconnects.log
      fi
      
      echo "$timestamp,$radio,$clients,$channel,$txpower,$noise" >> /tmp/notapollo/metrics/wifi_client_count.log
      
      # Signal strength analysis for connected clients
      iwinfo $radio assoclist | while read mac signal noise; do
        if [[ -n "$mac" ]]; then
          echo "$timestamp,$radio,$mac,$signal,$noise" >> /tmp/notapollo/metrics/wifi_signal_strength.log
        fi
      done
    fi
  done
}

# System Resource Monitoring with Trend Analysis
monitor_system_resources() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  # CPU usage with load average context
  local cpu_usage=$(top -bn1 | grep "CPU:" | awk '{print $2}' | sed 's/%//')
  local load_1min=$(cat /proc/loadavg | awk '{print $1}')
  local load_5min=$(cat /proc/loadavg | awk '{print $2}')
  local load_15min=$(cat /proc/loadavg | awk '{print $3}')
  
  # Memory analysis with pressure indicators
  local mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
  local mem_free=$(awk '/MemFree/ {print $2}' /proc/meminfo)
  local mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
  local mem_usage=$(echo "scale=2; (($mem_total - $mem_available) / $mem_total) * 100" | bc)
  
  # Temperature monitoring (if available)
  local temp="N/A"
  if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
    temp=$(cat /sys/class/thermal/thermal_zone0/temp)
    temp=$(echo "scale=1; $temp / 1000" | bc)
  fi
  
  echo "$timestamp,$cpu_usage,$load_1min,$load_5min,$load_15min,$mem_usage,$temp" >> /tmp/notapollo/metrics/system_resources.log
  
  # Alert on high resource usage
  if [[ $(echo "$cpu_usage > 80" | bc -l) -eq 1 ]] || [[ $(echo "$mem_usage > 90" | bc -l) -eq 1 ]]; then
    echo "$timestamp,HIGH_RESOURCE_USAGE,cpu=${cpu_usage}%,mem=${mem_usage}%" >> /tmp/notapollo/events/error_events.log
  fi
}

# DNS Performance Monitoring for Both Networks
monitor_dns_performance() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  # Primary Network DNS (192.168.69.1 -> dnsproxy:5354 -> NextDNS 8753a1)
  local primary_dns_time=$(dig @192.168.69.1 google.com +short +stats | awk '/Query time/ {print $4}')
  echo "$timestamp,primary,192.168.69.1,$primary_dns_time,google.com" >> /tmp/notapollo/metrics/dns_response_times.log
  
  # Dad's Network DNS (192.168.70.1 -> dnsproxy:5355 -> NextDNS 5414da)  
  local dad_dns_time=$(dig @192.168.70.1 google.com +short +stats | awk '/Query time/ {print $4}')
  echo "$timestamp,dad,192.168.70.1,$dad_dns_time,google.com" >> /tmp/notapollo/metrics/dns_response_times.log
  
  # Cache performance analysis
  local dnsmasq_cache_hits=$(grep -c "cached" /tmp/dnsmasq.log 2>/dev/null || echo "0")
  local dnsmasq_cache_total=$(wc -l < /tmp/dnsmasq.log 2>/dev/null || echo "1")
  local cache_hit_rate=$(echo "scale=2; $dnsmasq_cache_hits / $dnsmasq_cache_total * 100" | bc)
  
  echo "$timestamp,cache_performance,$cache_hit_rate,$dnsmasq_cache_hits,$dnsmasq_cache_total" >> /tmp/notapollo/metrics/dns_response_times.log
  
  # NextDNS query budget tracking
  local queries_today=$(grep "$(date +%Y-%m-%d)" /tmp/notapollo/metrics/dns_response_times.log | wc -l)
  local monthly_estimate=$(echo "$queries_today * 30" | bc)
  
  if [[ $monthly_estimate -gt 250000 ]]; then
    echo "$timestamp,DNS_BUDGET_WARNING,estimated_monthly=$monthly_estimate,limit=300000" >> /tmp/notapollo/events/error_events.log
  fi
}
```

### Health Score Calculation and Trending

```bash
# Comprehensive Health Score Algorithm
calculate_health_scores() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  # WAN Health Score (0-100)
  local wan_score=100
  local recent_latency=$(tail -10 /tmp/notapollo/metrics/wan_latency.log | awk -F',' '{sum+=$2; count++} END {print sum/count}')
  local recent_loss=$(tail -10 /tmp/notapollo/metrics/wan_latency.log | awk -F',' '{sum+=$3; count++} END {print sum/count}')
  
  # Deduct points for high latency and packet loss
  wan_score=$(echo "$wan_score - ($recent_latency / 2) - ($recent_loss * 5)" | bc)
  wan_score=$(echo "if ($wan_score < 0) 0 else if ($wan_score > 100) 100 else $wan_score" | bc)
  
  # WiFi Health Score
  local wifi_score=100
  local disconnects_1h=$(grep "$(date -d '1 hour ago' '+%Y-%m-%d %H')" /tmp/notapollo/events/wifi_disconnects.log | wc -l)
  wifi_score=$(echo "$wifi_score - ($disconnects_1h * 10)" | bc)
  
  # System Health Score  
  local system_score=100
  local avg_cpu=$(tail -20 /tmp/notapollo/metrics/system_resources.log | awk -F',' '{sum+=$2; count++} END {print sum/count}')
  local avg_mem=$(tail -20 /tmp/notapollo/metrics/system_resources.log | awk -F',' '{sum+=$5; count++} END {print sum/count}')
  system_score=$(echo "$system_score - ($avg_cpu / 2) - ($avg_mem / 3)" | bc)
  
  # DNS Health Score
  local dns_score=100
  local avg_dns_time=$(tail -20 /tmp/notapollo/metrics/dns_response_times.log | awk -F',' '{sum+=$4; count++} END {print sum/count}')
  dns_score=$(echo "$dns_score - ($avg_dns_time / 5)" | bc)
  
  # Overall Health Score (weighted average)
  local overall_score=$(echo "scale=0; ($wan_score * 0.3) + ($wifi_score * 0.25) + ($system_score * 0.25) + ($dns_score * 0.2)" | bc)
  
  # Log health scores
  echo "$timestamp,$overall_score,$wan_score,$wifi_score,$system_score,$dns_score" >> /tmp/notapollo/analysis/health_scores.json
  
  # Generate daily summary if it's a new day
  if [[ ! -f "/tmp/notapollo/analysis/daily_summary_$(date +%Y%m%d).json" ]]; then
    generate_daily_summary
  fi
}

# Daily Performance Summary Generation
generate_daily_summary() {
  local date=$(date +%Y-%m-%d)
  local summary_file="/tmp/notapollo/analysis/daily_summary_${date//-/}.json"
  
  # Calculate daily statistics
  local avg_latency=$(grep "$date" /tmp/notapollo/metrics/wan_latency.log | awk -F',' '{sum+=$2; count++} END {print sum/count}')
  local max_latency=$(grep "$date" /tmp/notapollo/metrics/wan_latency.log | awk -F',' '{max=0} {if($2>max) max=$2} END {print max}')
  local total_disconnects=$(grep "$date" /tmp/notapollo/events/wifi_disconnects.log | wc -l)
  local downtime_events=$(grep "$date" /tmp/notapollo/events/downtime_events.log | wc -l)
  local avg_health_score=$(grep "$date" /tmp/notapollo/analysis/health_scores.json | awk -F',' '{sum+=$2; count++} END {print sum/count}')
  
  # Create JSON summary
  cat > "$summary_file" << EOF
{
  "date": "$date",
  "performance": {
    "avg_latency_ms": $avg_latency,
    "max_latency_ms": $max_latency,
    "wifi_disconnects": $total_disconnects,
    "downtime_events": $downtime_events,
    "avg_health_score": $avg_health_score
  },
  "issues": [
$(grep "$date" /tmp/notapollo/events/error_events.log | while read line; do
  echo "    \"$line\","
done | sed '$ s/,$//')
  ],
  "generated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}
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

### Material 3 Compliant Layout Structure

#### Desktop Layout (1200px+)
```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                           Material 3 Top App Bar (notApollo)                            │
│  [≡] notApollo Network Diagnostics                    [🔄] Last updated: 2s ago [⚙️]   │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│ │                            System Overview Cards                                    │ │
│ │ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │ │
│ │ │   System    │ │     WAN     │ │    WiFi     │ │   Router    │ │    DNS      │ │ │
│ │ │   Health    │ │  Internet   │ │   Radio     │ │   Health    │ │  Services   │ │ │
│ │ │ 🟢 Healthy  │ │ 🟡 Degraded │ │ 🟢 Healthy  │ │ 🟢 Healthy  │ │ 🟢 Healthy  │ │ │
│ │ │ ┌─────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │ │ │
│ │ │ │ Uptime  │ │ │ │Latency  │ │ │ │Clients  │ │ │ │CPU/Mem  │ │ │ │Response │ │ │ │
│ │ │ │ Chart   │ │ │ │ Chart   │ │ │ │ Chart   │ │ │ │ Chart   │ │ │ │  Chart  │ │ │ │
│ │ │ └─────────┘ │ │ └─────────┘ │ │ └─────────┘ │ │ └─────────┘ │ │ └─────────┘ │ │ │
│ │ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │ │
│ └─────────────────────────────────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│ │                          Detailed Analytics Section                                 │ │
│ │ ┌─────────────────────────────┐ ┌─────────────────────────────┐ ┌─────────────────┐ │ │
│ │ │      Network Performance    │ │       System Resources      │ │   ONT/Fiber     │ │ │
│ │ │  ┌─────────────────────────┐ │ │  ┌─────────────────────────┐ │ │  ┌─────────────┐ │ │ │
│ │ │  │   Latency & Loss        │ │ │  │    CPU & Memory         │ │ │  │ LED Status  │ │ │ │
│ │ │  │   Time Series Chart     │ │ │  │   Real-time Gauges      │ │ │  │  Guidance   │ │ │ │
│ │ │  └─────────────────────────┘ │ │  └─────────────────────────┘ │ │  └─────────────┘ │ │ │
│ │ │  ┌─────────────────────────┐ │ │  ┌─────────────────────────┐ │ │  ┌─────────────┐ │ │ │
│ │ │  │   WiFi Signal Strength  │ │ │  │   Temperature & Load    │ │ │  │   Router    │ │ │ │
│ │ │  │   Multi-band Chart      │ │ │  │   Historical Trends     │ │ │  │  Controls   │ │ │ │
│ │ │  └─────────────────────────┘ │ │  └─────────────────────────┘ │ │  └─────────────┘ │ │ │
│ │ └─────────────────────────────┘ └─────────────────────────────┘ └─────────────────┘ │ │
│ └─────────────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

#### Mobile Layout (< 768px)
```
┌─────────────────────────────────────┐
│        Material 3 Top App Bar       │
│  [≡] notApollo            [🔄] [⚙️] │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │        System Status            │ │
│ │  🟢 All Systems Healthy         │ │
│ │  ┌─────────────────────────────┐ │ │
│ │  │    Overall Health Chart     │ │ │
│ │  └─────────────────────────────┘ │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │      Quick Stats Cards          │ │
│ │ ┌─────────┐ ┌─────────┐         │ │
│ │ │   WAN   │ │  WiFi   │         │ │
│ │ │12ms RTT │ │8 Clients│         │ │
│ │ └─────────┘ └─────────┘         │ │
│ │ ┌─────────┐ ┌─────────┐         │ │
│ │ │ Router  │ │   DNS   │         │ │
│ │ │15% CPU  │ │ 8ms Avg │         │ │
│ │ └─────────┘ └─────────┘         │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │      Expandable Sections        │ │
│ │ ▼ Network Performance           │ │
│ │ ▶ System Resources              │ │
│ │ ▶ Router Controls               │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Material 3 Component Specifications

#### Material 3 2026 Design System Implementation

Following the latest Material 3 specifications from m3.material.io (2026 updates):

```css
:root {
  /* Material 3 2026 Dynamic Color System */
  --md-sys-color-primary: #6750a4;
  --md-sys-color-on-primary: #ffffff;
  --md-sys-color-primary-container: #e9ddff;
  --md-sys-color-on-primary-container: #22005d;
  
  --md-sys-color-secondary: #625b71;
  --md-sys-color-on-secondary: #ffffff;
  --md-sys-color-secondary-container: #e8def8;
  --md-sys-color-on-secondary-container: #1e192b;
  
  --md-sys-color-tertiary: #7e5260;
  --md-sys-color-on-tertiary: #ffffff;
  --md-sys-color-tertiary-container: #ffd9e3;
  --md-sys-color-on-tertiary-container: #31101d;
  
  --md-sys-color-error: #ba1a1a;
  --md-sys-color-on-error: #ffffff;
  --md-sys-color-error-container: #ffdad6;
  --md-sys-color-on-error-container: #410002;
  
  --md-sys-color-background: #fffbff;
  --md-sys-color-on-background: #1c1b1e;
  --md-sys-color-surface: #fffbff;
  --md-sys-color-on-surface: #1c1b1e;
  --md-sys-color-surface-variant: #e7e0eb;
  --md-sys-color-on-surface-variant: #49454e;
  --md-sys-color-outline: #7a757f;
  --md-sys-color-outline-variant: #cac4cf;
  
  /* Surface Container Hierarchy (2026 Update) */
  --md-sys-color-surface-dim: #ded8e1;
  --md-sys-color-surface-bright: #fffbff;
  --md-sys-color-surface-container-lowest: #ffffff;
  --md-sys-color-surface-container-low: #f7f2fa;
  --md-sys-color-surface-container: #f1ecf4;
  --md-sys-color-surface-container-high: #ebe6ee;
  --md-sys-color-surface-container-highest: #e6e0e9;
  
  /* Dark Theme Override */
  @media (prefers-color-scheme: dark) {
    --md-sys-color-primary: #cfbcff;
    --md-sys-color-on-primary: #381e72;
    --md-sys-color-primary-container: #4f378a;
    --md-sys-color-on-primary-container: #e9ddff;
    
    --md-sys-color-secondary: #cbc2db;
    --md-sys-color-on-secondary: #332d41;
    --md-sys-color-secondary-container: #4a4458;
    --md-sys-color-on-secondary-container: #e8def8;
    
    --md-sys-color-tertiary: #efb8c8;
    --md-sys-color-on-tertiary: #4a2532;
    --md-sys-color-tertiary-container: #633b48;
    --md-sys-color-on-tertiary-container: #ffd9e3;
    
    --md-sys-color-error: #ffb4ab;
    --md-sys-color-on-error: #690005;
    --md-sys-color-error-container: #93000a;
    --md-sys-color-on-error-container: #ffdad6;
    
    --md-sys-color-background: #141218;
    --md-sys-color-on-background: #e6e0e9;
    --md-sys-color-surface: #141218;
    --md-sys-color-on-surface: #e6e0e9;
    --md-sys-color-surface-variant: #49454e;
    --md-sys-color-on-surface-variant: #cac4cf;
    --md-sys-color-outline: #948f99;
    --md-sys-color-outline-variant: #49454e;
    
    --md-sys-color-surface-dim: #141218;
    --md-sys-color-surface-bright: #3b383e;
    --md-sys-color-surface-container-lowest: #0f0d13;
    --md-sys-color-surface-container-low: #1c1b1e;
    --md-sys-color-surface-container: #201f22;
    --md-sys-color-surface-container-high: #2b292d;
    --md-sys-color-surface-container-highest: #363438;
  }
  
  /* Status Colors (Network Health Specific) */
  --status-excellent: #00c853;
  --status-good: #4caf50;
  --status-fair: #ff9800;
  --status-poor: #f44336;
  --status-critical: #d32f2f;
  
  /* Network-specific Color Palette */
  --network-primary: var(--md-sys-color-primary);
  --network-dad: var(--md-sys-color-tertiary);
  --wan-color: #2196f3;
  --wifi-2g-color: #4caf50;
  --wifi-5g-color: #ff9800;
  --wifi-6g-color: #9c27b0;
  --dns-color: #00bcd4;
}
```

#### Typography Scale (M3 2024)
```css
.display-large {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 3.5rem;
  font-weight: 400;
  line-height: 4rem;
  letter-spacing: -0.25px;
}

.display-medium {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 2.8125rem;
  font-weight: 400;
  line-height: 3.25rem;
  letter-spacing: 0px;
}

.display-small {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 2.25rem;
  font-weight: 400;
  line-height: 2.75rem;
  letter-spacing: 0px;
}

.headline-large {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 2rem;
  font-weight: 400;
  line-height: 2.5rem;
  letter-spacing: 0px;
}

.headline-medium {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 1.75rem;
  font-weight: 400;
  line-height: 2.25rem;
  letter-spacing: 0px;
}

.headline-small {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 1.5rem;
  font-weight: 400;
  line-height: 2rem;
  letter-spacing: 0px;
}

.title-large {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 1.375rem;
  font-weight: 400;
  line-height: 1.75rem;
  letter-spacing: 0px;
}

.title-medium {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 1rem;
  font-weight: 500;
  line-height: 1.5rem;
  letter-spacing: 0.15px;
}

.title-small {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 0.875rem;
  font-weight: 500;
  line-height: 1.25rem;
  letter-spacing: 0.1px;
}

.label-large {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 0.875rem;
  font-weight: 500;
  line-height: 1.25rem;
  letter-spacing: 0.1px;
}

.label-medium {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 0.75rem;
  font-weight: 500;
  line-height: 1rem;
  letter-spacing: 0.5px;
}

.label-small {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 0.6875rem;
  font-weight: 500;
  line-height: 1rem;
  letter-spacing: 0.5px;
}

.body-large {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 1rem;
  font-weight: 400;
  line-height: 1.5rem;
  letter-spacing: 0.5px;
}

.body-medium {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 0.875rem;
  font-weight: 400;
  line-height: 1.25rem;
  letter-spacing: 0.25px;
}

.body-small {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 0.75rem;
  font-weight: 400;
  line-height: 1rem;
  letter-spacing: 0.4px;
}
```

#### Material 3 Component Specifications

##### Top App Bar
```css
.md3-top-app-bar {
  background: var(--md-sys-color-surface);
  color: var(--md-sys-color-on-surface);
  height: 64px;
  padding: 0 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: var(--md-sys-elevation-level2);
  position: sticky;
  top: 0;
  z-index: 1000;
}

.md3-top-app-bar-title {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 1.375rem;
  font-weight: 400;
  line-height: 1.75rem;
  margin-left: 16px;
}

.md3-top-app-bar-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}
```

##### Cards with Embedded Charts
```css
.md3-card {
  background: var(--md-sys-color-surface-container-low);
  border-radius: 12px;
  box-shadow: var(--md-sys-elevation-level1);
  padding: 16px;
  transition: box-shadow var(--md-sys-motion-duration-short4) var(--md-sys-motion-easing-standard);
  position: relative;
  overflow: hidden;
}

.md3-card:hover {
  box-shadow: var(--md-sys-elevation-level2);
}

.md3-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.md3-card-title {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 0.875rem;
  font-weight: 500;
  line-height: 1.25rem;
  letter-spacing: 0.1px;
  color: var(--md-sys-color-on-surface);
}

.md3-card-status {
  display: flex;
  align-items: center;
  gap: 8px;
}

.md3-status-indicator {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  display: inline-block;
}

.md3-status-indicator.healthy { background: var(--status-healthy); }
.md3-status-indicator.degraded { background: var(--status-degraded); }
.md3-status-indicator.broken { background: var(--status-broken); }

.md3-card-chart {
  height: 120px;
  width: 100%;
  margin-top: 8px;
  border-radius: 8px;
  overflow: hidden;
}

.md3-card-metrics {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(80px, 1fr));
  gap: 12px;
  margin-top: 12px;
}

.md3-metric {
  text-align: center;
}

.md3-metric-value {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 1.125rem;
  font-weight: 500;
  color: var(--md-sys-color-primary);
  display: block;
}

.md3-metric-label {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 0.75rem;
  font-weight: 400;
  color: var(--md-sys-color-on-surface-variant);
  margin-top: 2px;
}
```

##### Responsive Grid System
```css
.md3-dashboard {
  padding: 16px;
  max-width: 1400px;
  margin: 0 auto;
  height: calc(100vh - 64px);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.md3-overview-section {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 16px;
  margin-bottom: 16px;
  flex-shrink: 0;
}

.md3-details-section {
  display: grid;
  grid-template-columns: 2fr 2fr 1fr;
  gap: 16px;
  flex: 1;
  min-height: 0;
}

.md3-section-card {
  background: var(--md-sys-color-surface-container);
  border-radius: 16px;
  padding: 20px;
  box-shadow: var(--md-sys-elevation-level1);
  display: flex;
  flex-direction: column;
  min-height: 0;
}

.md3-section-title {
  font-family: 'Google Sans Flex', sans-serif;
  font-size: 1rem;
  font-weight: 500;
  line-height: 1.5rem;
  color: var(--md-sys-color-on-surface);
  margin-bottom: 16px;
}

.md3-chart-container {
  flex: 1;
  min-height: 200px;
  position: relative;
}

/* Mobile Responsive */
@media (max-width: 1200px) {
  .md3-overview-section {
    grid-template-columns: repeat(3, 1fr);
  }
  
  .md3-details-section {
    grid-template-columns: 1fr 1fr;
  }
}

@media (max-width: 768px) {
  .md3-dashboard {
    padding: 8px;
    height: auto;
    overflow: visible;
  }
  
  .md3-overview-section {
    grid-template-columns: repeat(2, 1fr);
    gap: 8px;
  }
  
  .md3-details-section {
    grid-template-columns: 1fr;
    gap: 8px;
  }
  
  .md3-card {
    padding: 12px;
  }
  
  .md3-section-card {
    padding: 16px;
  }
}

@media (max-width: 480px) {
  .md3-overview-section {
    grid-template-columns: 1fr;
  }
}
```

##### Interactive Elements
```css
.md3-fab {
  background: var(--md-sys-color-primary-container);
  color: var(--md-sys-color-on-primary-container);
  border: none;
  border-radius: 16px;
  padding: 16px;
  min-width: 56px;
  min-height: 56px;
  box-shadow: var(--md-sys-elevation-level3);
  cursor: pointer;
  transition: all var(--md-sys-motion-duration-short4) var(--md-sys-motion-easing-standard);
  display: flex;
  align-items: center;
  justify-content: center;
}

.md3-fab:hover {
  box-shadow: var(--md-sys-elevation-level4);
  transform: translateY(-1px);
}

.md3-fab:active {
  transform: translateY(0);
  box-shadow: var(--md-sys-elevation-level2);
}

.md3-icon-button {
  background: transparent;
  border: none;
  border-radius: 50%;
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background-color var(--md-sys-motion-duration-short2) var(--md-sys-motion-easing-standard);
  color: var(--md-sys-color-on-surface-variant);
}

.md3-icon-button:hover {
  background: rgba(var(--md-sys-color-on-surface-variant), 0.08);
}

.md3-icon-button:active {
  background: rgba(var(--md-sys-color-on-surface-variant), 0.12);
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

## Comprehensive Chart Strategy

### Chart Types and Purposes

#### 1. Overview Cards with Micro-Charts (120px height)
```javascript
// System Health Micro-Chart
const systemHealthConfig = {
  type: 'doughnut',
  data: {
    labels: ['Healthy', 'Degraded', 'Issues'],
    datasets: [{
      data: [85, 10, 5],
      backgroundColor: [
        'var(--status-healthy)',
        'var(--status-degraded)', 
        'var(--status-broken)'
      ],
      borderWidth: 0
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      tooltip: { enabled: false }
    },
    cutout: '70%'
  }
};

// WAN Latency Sparkline
const wanLatencyConfig = {
  type: 'line',
  data: {
    labels: Array.from({length: 20}, (_, i) => i),
    datasets: [{
      data: [], // Last 20 measurements
      borderColor: 'var(--chart-primary)',
      backgroundColor: 'transparent',
      borderWidth: 2,
      pointRadius: 0,
      tension: 0.4
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { display: false } },
    scales: {
      x: { display: false },
      y: { display: false }
    },
    elements: { point: { radius: 0 } }
  }
};

// WiFi Clients Bar Chart
const wifiClientsConfig = {
  type: 'bar',
  data: {
    labels: ['2.4G', '5G', '6G'],
    datasets: [{
      data: [3, 5, 2],
      backgroundColor: [
        'var(--chart-primary)',
        'var(--chart-secondary)',
        'var(--chart-tertiary)'
      ],
      borderRadius: 4
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { display: false } },
    scales: {
      x: { display: false },
      y: { display: false }
    }
  }
};

// Router Resources Gauge
const routerResourcesConfig = {
  type: 'doughnut',
  data: {
    labels: ['CPU', 'Memory', 'Free'],
    datasets: [{
      data: [15, 45, 40],
      backgroundColor: [
        'var(--chart-warning)',
        'var(--chart-primary)',
        'var(--md-sys-color-surface-variant)'
      ],
      borderWidth: 0
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      tooltip: {
        callbacks: {
          label: (context) => `${context.label}: ${context.parsed}%`
        }
      }
    },
    cutout: '60%'
  }
};

// DNS Response Time Area Chart
const dnsResponseConfig = {
  type: 'line',
  data: {
    labels: Array.from({length: 15}, (_, i) => i),
    datasets: [{
      label: 'Primary',
      data: [], // Response times
      borderColor: 'var(--chart-primary)',
      backgroundColor: 'rgba(168, 199, 250, 0.1)',
      fill: true,
      tension: 0.4
    }, {
      label: "Dad's Network",
      data: [], // Response times
      borderColor: 'var(--chart-secondary)',
      backgroundColor: 'rgba(188, 199, 219, 0.1)',
      fill: true,
      tension: 0.4
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { display: false } },
    scales: {
      x: { display: false },
      y: { display: false }
    },
    elements: { point: { radius: 0 } }
  }
};
```

#### 2. Detailed Analytics Charts (200-300px height)

```javascript
// Network Performance - Latency & Packet Loss
const networkPerformanceConfig = {
  type: 'line',
  data: {
    labels: [], // Time labels (last 2 hours)
    datasets: [{
      label: 'Latency (ms)',
      data: [],
      borderColor: 'var(--chart-primary)',
      backgroundColor: 'rgba(168, 199, 250, 0.1)',
      yAxisID: 'y',
      tension: 0.4,
      fill: true
    }, {
      label: 'Packet Loss (%)',
      data: [],
      borderColor: 'var(--chart-error)',
      backgroundColor: 'rgba(255, 180, 171, 0.1)',
      yAxisID: 'y1',
      tension: 0.4,
      fill: true
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    interaction: { intersect: false, mode: 'index' },
    plugins: {
      legend: {
        position: 'top',
        labels: {
          usePointStyle: true,
          padding: 20,
          color: 'var(--md-sys-color-on-surface)'
        }
      },
      tooltip: {
        backgroundColor: 'var(--md-sys-color-surface-container)',
        titleColor: 'var(--md-sys-color-on-surface)',
        bodyColor: 'var(--md-sys-color-on-surface)',
        borderColor: 'var(--md-sys-color-outline)',
        borderWidth: 1
      }
    },
    scales: {
      x: {
        grid: { color: 'var(--md-sys-color-outline-variant)' },
        ticks: { color: 'var(--md-sys-color-on-surface-variant)' }
      },
      y: {
        type: 'linear',
        display: true,
        position: 'left',
        title: { display: true, text: 'Latency (ms)', color: 'var(--md-sys-color-on-surface-variant)' },
        grid: { color: 'var(--md-sys-color-outline-variant)' },
        ticks: { color: 'var(--md-sys-color-on-surface-variant)' }
      },
      y1: {
        type: 'linear',
        display: true,
        position: 'right',
        title: { display: true, text: 'Packet Loss (%)', color: 'var(--md-sys-color-on-surface-variant)' },
        grid: { drawOnChartArea: false },
        ticks: { color: 'var(--md-sys-color-on-surface-variant)' }
      }
    }
  }
};

// WiFi Signal Strength Multi-band
const wifiSignalConfig = {
  type: 'radar',
  data: {
    labels: ['Signal Strength', 'Channel Utilization', 'Client Count', 'TX Rate', 'RX Rate', 'Interference'],
    datasets: [{
      label: '2.4GHz',
      data: [85, 30, 60, 75, 80, 20],
      borderColor: 'var(--chart-primary)',
      backgroundColor: 'rgba(168, 199, 250, 0.2)',
      pointBackgroundColor: 'var(--chart-primary)'
    }, {
      label: '5GHz',
      data: [92, 15, 80, 90, 95, 10],
      borderColor: 'var(--chart-secondary)',
      backgroundColor: 'rgba(188, 199, 219, 0.2)',
      pointBackgroundColor: 'var(--chart-secondary)'
    }, {
      label: '6GHz',
      data: [88, 5, 40, 95, 98, 5],
      borderColor: 'var(--chart-tertiary)',
      backgroundColor: 'rgba(214, 187, 221, 0.2)',
      pointBackgroundColor: 'var(--chart-tertiary)'
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'top',
        labels: {
          usePointStyle: true,
          color: 'var(--md-sys-color-on-surface)'
        }
      }
    },
    scales: {
      r: {
        beginAtZero: true,
        max: 100,
        grid: { color: 'var(--md-sys-color-outline-variant)' },
        pointLabels: { color: 'var(--md-sys-color-on-surface-variant)' },
        ticks: { color: 'var(--md-sys-color-on-surface-variant)' }
      }
    }
  }
};

// System Resources - CPU & Memory with Temperature
const systemResourcesConfig = {
  type: 'line',
  data: {
    labels: [], // Time labels (last hour)
    datasets: [{
      label: 'CPU Usage (%)',
      data: [],
      borderColor: 'var(--chart-primary)',
      backgroundColor: 'rgba(168, 199, 250, 0.1)',
      yAxisID: 'y',
      tension: 0.4,
      fill: true
    }, {
      label: 'Memory Usage (%)',
      data: [],
      borderColor: 'var(--chart-secondary)',
      backgroundColor: 'rgba(188, 199, 219, 0.1)',
      yAxisID: 'y',
      tension: 0.4,
      fill: true
    }, {
      label: 'Temperature (°C)',
      data: [],
      borderColor: 'var(--chart-warning)',
      backgroundColor: 'rgba(255, 152, 0, 0.1)',
      yAxisID: 'y1',
      tension: 0.4,
      fill: true
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    interaction: { intersect: false, mode: 'index' },
    plugins: {
      legend: {
        position: 'top',
        labels: {
          usePointStyle: true,
          color: 'var(--md-sys-color-on-surface)'
        }
      }
    },
    scales: {
      x: {
        grid: { color: 'var(--md-sys-color-outline-variant)' },
        ticks: { color: 'var(--md-sys-color-on-surface-variant)' }
      },
      y: {
        type: 'linear',
        display: true,
        position: 'left',
        title: { display: true, text: 'Usage (%)', color: 'var(--md-sys-color-on-surface-variant)' },
        grid: { color: 'var(--md-sys-color-outline-variant)' },
        ticks: { color: 'var(--md-sys-color-on-surface-variant)' },
        max: 100
      },
      y1: {
        type: 'linear',
        display: true,
        position: 'right',
        title: { display: true, text: 'Temperature (°C)', color: 'var(--md-sys-color-on-surface-variant)' },
        grid: { drawOnChartArea: false },
        ticks: { color: 'var(--md-sys-color-on-surface-variant)' }
      }
    }
  }
};
```

#### 3. Health Check Dashboard
```javascript
// Overall System Health Score
const healthScoreConfig = {
  type: 'doughnut',
  data: {
    labels: ['Health Score'],
    datasets: [{
      data: [87, 13], // Health score out of 100
      backgroundColor: [
        'var(--status-healthy)',
        'var(--md-sys-color-surface-variant)'
      ],
      borderWidth: 0,
      cutout: '80%'
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      tooltip: { enabled: false }
    }
  }
};

// Service Status Matrix
const serviceStatusConfig = {
  type: 'bar',
  data: {
    labels: ['WAN', 'WiFi', 'DNS', 'DHCP', 'Firewall', 'VPN'],
    datasets: [{
      label: 'Service Health',
      data: [100, 95, 98, 100, 90, 85],
      backgroundColor: (ctx) => {
        const value = ctx.parsed.y;
        if (value >= 95) return 'var(--status-healthy)';
        if (value >= 80) return 'var(--status-degraded)';
        return 'var(--status-broken)';
      },
      borderRadius: 4
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    indexAxis: 'y',
    plugins: {
      legend: { display: false }
    },
    scales: {
      x: {
        beginAtZero: true,
        max: 100,
        grid: { color: 'var(--md-sys-color-outline-variant)' },
        ticks: { color: 'var(--md-sys-color-on-surface-variant)' }
      },
      y: {
        grid: { display: false },
        ticks: { color: 'var(--md-sys-color-on-surface-variant)' }
      }
    }
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