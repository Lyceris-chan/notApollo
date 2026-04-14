# Requirements Document

## Introduction

The notApollo network diagnostic webpage is a comprehensive diagnostic tool for an ASUS RT-AX53U router running OpenWrt. The system provides real-time monitoring and diagnostics across all network layers, from physical ONT/fiber connectivity to application-layer services. The webpage must be accessible from both primary (192.168.69.x) and Dad's isolated (192.168.70.x) networks while following Material 3 design principles and Google developer code style guidelines.

## Glossary

- **System**: The notApollo diagnostic webpage application
- **Router**: The ASUS RT-AX53U running OpenWrt with dual-network configuration
- **Primary_Network**: The main LAN network (192.168.69.x) with full access
- **Dad_Network**: The isolated guest network (192.168.70.x) with restricted access
- **ONT**: Optical Network Terminal - the fiber modem device
- **WAN_Interface**: The router's internet connection interface (VLAN 300 for PROD, bare device for DEV)
- **Diagnostic_Engine**: The backend component that collects system metrics and status
- **UI_Component**: The frontend Material 3 interface that displays diagnostic information
- **Health_Status**: A tri-state indicator (🟢 Healthy / 🟡 Degraded / 🔴 Broken)

## Requirements

### Requirement 1: Multi-Network Accessibility

**User Story:** As a network administrator, I want to access the diagnostic webpage from both network segments, so that I can troubleshoot issues regardless of which network I'm connected to.

#### Acceptance Criteria

1. WHEN accessing from Primary_Network (192.168.69.x), THE System SHALL serve the diagnostic webpage
2. WHEN accessing from Dad_Network (192.168.70.x), THE System SHALL serve the diagnostic webpage
3. THE System SHALL bind to both network interfaces simultaneously
4. THE System SHALL maintain identical functionality across both network access points

### Requirement 2: Material 3 Design Compliance

**User Story:** As a user, I want a modern and intuitive interface, so that I can quickly understand network status and navigate diagnostic information.

#### Acceptance Criteria

1. THE UI_Component SHALL implement Material 3 expressive design principles
2. THE UI_Component SHALL use Material 3 color tokens and typography scales
3. THE UI_Component SHALL implement Material 3 component specifications for cards, buttons, and navigation
4. THE UI_Component SHALL provide responsive layout optimized for mobile devices
5. THE UI_Component SHALL use Material 3 motion and interaction patterns
6. THE UI_Component SHALL use Google Sans Flex font family for optimal readability
7. THE System SHALL include a distinctive application icon following Material 3 icon design principles
8. THE UI_Component SHALL use Material 3 dark theme as the default interface theme

### Requirement 3: Local-Only Implementation

**User Story:** As a security-conscious administrator, I want the diagnostic tool to work without external dependencies, so that it functions reliably in isolated network environments.

#### Acceptance Criteria

1. THE System SHALL operate without requiring external package downloads
2. THE System SHALL include all CSS, JavaScript, and font assets locally
3. THE System SHALL function when internet connectivity is unavailable
4. THE System SHALL not make any external HTTP requests during operation

### Requirement 4: System Health Monitoring

**User Story:** As a network administrator, I want to monitor core system health, so that I can identify when the router itself is experiencing issues.

#### Acceptance Criteria

1. THE Diagnostic_Engine SHALL report system uptime and last reboot timestamp
2. THE Diagnostic_Engine SHALL track reboot counter for last 24 hours and 7 days
3. THE Diagnostic_Engine SHALL display configuration last changed timestamp
4. THE Diagnostic_Engine SHALL identify management mode (local/cloud/ISP)
5. WHEN reboot is requested, THE System SHALL display reboot progress and reset uptime counter
6. THE System SHALL provide a functional reboot button with confirmation

### Requirement 5: WAN/Internet Layer Diagnostics

**User Story:** As a network administrator, I want comprehensive WAN diagnostics, so that I can quickly identify internet connectivity issues.

#### Acceptance Criteria

1. THE Diagnostic_Engine SHALL monitor WAN_Interface link state (up/down)
2. THE Diagnostic_Engine SHALL report IP address assignment status
3. THE Diagnostic_Engine SHALL test default gateway reachability via ping
4. THE Diagnostic_Engine SHALL verify public internet connectivity
5. THE Diagnostic_Engine SHALL monitor DHCP lease stability and renewal status
6. THE Diagnostic_Engine SHALL track packet loss in rolling time windows
7. THE Diagnostic_Engine SHALL monitor latency with baseline comparison and spike detection
8. THE Diagnostic_Engine SHALL detect link flap events and interface resets

### Requirement 6: WiFi/Radio Layer Diagnostics

**User Story:** As a network administrator, I want detailed WiFi diagnostics, so that I can troubleshoot wireless connectivity and performance issues.

#### Acceptance Criteria

1. THE Diagnostic_Engine SHALL monitor radio state for all bands (2.4GHz, 5GHz, 6GHz)
2. THE Diagnostic_Engine SHALL report SSID broadcasting status for each network
3. THE Diagnostic_Engine SHALL count connected clients per radio and SSID
4. THE Diagnostic_Engine SHALL monitor client stability (disconnects, authentication failures)
5. THE Diagnostic_Engine SHALL classify signal quality using RSSI and SNR metrics
6. THE Diagnostic_Engine SHALL track packet statistics (TX retries, drops, RX errors)
7. THE Diagnostic_Engine SHALL report channel utilization and congestion indicators
8. THE Diagnostic_Engine SHALL detect DFS events and radio restart occurrences

### Requirement 7: Router Health Monitoring

**User Story:** As a network administrator, I want to monitor router hardware health, so that I can identify performance bottlenecks and hardware issues.

#### Acceptance Criteria

1. THE Diagnostic_Engine SHALL monitor CPU usage and detect usage spikes
2. THE Diagnostic_Engine SHALL track memory utilization and pressure indicators
3. WHERE temperature sensors are available, THE Diagnostic_Engine SHALL report thermal status
4. THE Diagnostic_Engine SHALL detect process crashes and watchdog reset events
5. THE Diagnostic_Engine SHALL scan system logs for recurring error patterns

### Requirement 8: ONT/Fiber Layer Diagnostics

**User Story:** As a network administrator, I want ONT and fiber connectivity diagnostics, so that I can identify physical layer issues with the internet connection.

#### Acceptance Criteria

1. THE System SHALL provide guided ONT LED status checking interface
2. THE Diagnostic_Engine SHALL test Ethernet link between ONT and Router
3. WHERE available, THE Diagnostic_Engine SHALL attempt ONT web interface access
4. THE Diagnostic_Engine SHALL detect power event patterns
5. THE Diagnostic_Engine SHALL monitor power stability indicators

### Requirement 9: LAN Services Diagnostics

**User Story:** As a network administrator, I want to monitor essential LAN services, so that I can ensure local network functionality.

#### Acceptance Criteria

1. THE Diagnostic_Engine SHALL monitor DHCP server health and lease allocation
2. THE Diagnostic_Engine SHALL test DNS resolver reachability and response times
3. WHERE IPv6 is enabled, THE Diagnostic_Engine SHALL report IPv6 connectivity status
4. THE Diagnostic_Engine SHALL verify local service availability

### Requirement 10: Cross-Layer Intelligence

**User Story:** As a network administrator, I want intelligent correlation of diagnostic data, so that I can quickly identify root causes of network issues.

#### Acceptance Criteria

1. THE Diagnostic_Engine SHALL correlate WiFi disconnections with WAN stability events
2. THE Diagnostic_Engine SHALL identify patterns between different network layers
3. THE System SHALL convert all diagnostic data into Health_Status indicators
4. THE UI_Component SHALL present correlated findings in a unified dashboard
5. THE System SHALL prioritize critical issues over informational status

### Requirement 11: Real-Time Data Updates

**User Story:** As a network administrator, I want current diagnostic information, so that I can monitor network status in real-time.

#### Acceptance Criteria

1. THE System SHALL refresh diagnostic data automatically at regular intervals
2. THE UI_Component SHALL update displays without requiring page refresh
3. THE System SHALL indicate when data was last updated
4. WHEN network conditions change, THE System SHALL reflect changes within 30 seconds
5. THE System SHALL handle temporary data collection failures gracefully

### Requirement 13: Data Visualization and Graphing

**User Story:** As a network administrator, I want visual representations of time-series data, so that I can quickly identify trends and patterns in network performance.

#### Acceptance Criteria

1. THE UI_Component SHALL display line graphs for latency trends over time
2. THE UI_Component SHALL display bar charts for packet loss statistics in rolling windows
3. THE UI_Component SHALL display signal strength graphs for WiFi RSSI/SNR over time
4. THE UI_Component SHALL display CPU and memory usage graphs with historical data
5. THE UI_Component SHALL display bandwidth utilization charts for WAN interface
6. THE UI_Component SHALL render all graphs responsively for mobile and desktop viewing
7. THE UI_Component SHALL implement graphs using local-only charting libraries
8. THE UI_Component SHALL provide interactive tooltips and zoom capabilities for graph data

### Requirement 15: Google Code Style Compliance

**User Story:** As a developer, I want maintainable and consistent code, so that the diagnostic tool can be easily extended and modified.

#### Acceptance Criteria

1. THE System SHALL follow Google JavaScript Style Guide for all client-side code
2. THE System SHALL follow Google HTML/CSS Style Guide for all markup and styling
3. THE System SHALL use consistent naming conventions throughout the codebase
4. THE System SHALL include appropriate code documentation and comments
5. THE System SHALL structure code in logical, modular components

### Requirement 16: User-Friendly Language

**User Story:** As a non-technical user, I want diagnostic messages in plain language, so that I can understand network issues without technical expertise.

#### Acceptance Criteria

1. THE System SHALL display all diagnostic messages using plain, non-technical language
2. THE System SHALL avoid technical jargon in status indicators and error messages
3. THE System SHALL provide clear, simple explanations for network conditions
4. THE System SHALL use terminology that "Dad" can easily understand
5. THE System SHALL include helpful context for any technical terms that must be used

### Requirement 17: ONT Guidance System

**User Story:** As a user experiencing network issues, I want clear guidance on checking the ONT, so that I can troubleshoot fiber connectivity problems.

#### Acceptance Criteria

1. WHEN network issues are detected, THE System SHALL provide clear instructions to check ONT LED status
2. THE System SHALL display visual guides for interpreting ONT LED indicators
3. THE System SHALL suggest power cycling the ONT when appropriate network conditions are detected
4. THE System SHALL provide step-by-step ONT troubleshooting instructions
5. THE System SHALL explain what each ONT LED color and pattern means in simple terms

### Requirement 20: Router Reboot with Safety Confirmation

**User Story:** As a user, I want a safe way to restart the router with proper confirmation, so that I can resolve network issues without accidentally triggering reboots.

#### Acceptance Criteria

1. THE System SHALL provide a prominent "Restart Router" button in the interface
2. WHEN the reboot button is clicked, THE System SHALL display a 5-second countdown before allowing execution
3. THE System SHALL require the user to wait through the full 5-second delay before the reboot becomes active
4. THE System SHALL show countdown timer with clear messaging like "Think carefully... rebooting in 3 seconds"
5. THE System SHALL explain what is happening during each phase of the reboot process
6. THE System SHALL provide estimated time remaining during the reboot process
7. THE System SHALL display clear status messages throughout the restart sequence
8. THE System SHALL implement the safety delay during confirmation phase, not after command execution

### Requirement 21: Production Readiness and Error Handling

**User Story:** As a system administrator, I want comprehensive error handling and production-ready features, so that the diagnostic tool operates reliably in all conditions.

#### Acceptance Criteria

1. THE System SHALL implement comprehensive error handling for all edge cases
2. THE System SHALL provide proper logging and monitoring capabilities
3. THE System SHALL gracefully degrade when services are unavailable
4. THE System SHALL include proper security headers and input validation
5. THE System SHALL implement rate limiting to prevent abuse
6. THE System SHALL provide proper session management
7. THE System SHALL include backup and fallback mechanisms for critical functions
8. THE System SHALL implement proper startup and shutdown procedures
9. THE System SHALL provide health checks for all system components
10. THE System SHALL handle network interruptions and service failures gracefully

### Requirement 19: DNS Health Monitoring with Cache Integration

**User Story:** As a network administrator, I want to monitor DNS health across both networks while leveraging cache performance data, so that I can ensure reliable DNS resolution and optimize testing frequency based on cache efficiency.

#### Acceptance Criteria

1. THE Diagnostic_Engine SHALL monitor DNS resolution health for Primary_Network (192.168.69.x)
2. THE Diagnostic_Engine SHALL monitor DNS resolution health for Dad_Network (192.168.70.x)
3. THE System SHALL implement smart query limiting to stay well under 300,000 NextDNS monthly queries
4. THE System SHALL use cached DNS results with appropriate TTL to reduce query frequency
5. THE System SHALL reduce DNS test frequency during normal operation periods
6. THE System SHALL implement batch DNS testing during scheduled intervals
7. THE System SHALL monitor dnsmasq cache performance and hit rates from /tmp/dnsmasq.log
8. THE System SHALL monitor dnsproxy cache efficiency (8MB cache with 300s min TTL)
9. THE System SHALL use cache hit rates to optimize DNS testing frequency dynamically
10. THE System SHALL factor local cache performance into DNS health status determination
11. THE System SHALL track NextDNS query usage across both network profiles (primary 8753a1, Dad's 5414da)
12. THE System SHALL provide DNS health status without exceeding reasonable query budgets