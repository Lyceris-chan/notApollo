# Development Guide

This guide provides comprehensive information for developers working on the notApollo network diagnostic tool.

## Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd notapollo
./scripts/setup-dev.sh
```

### 2. Start Development

```bash
# Start development server
./scripts/dev-server.sh

# In another terminal, run quality checks
./scripts/check-quality.sh
```

### 3. Make Changes

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make changes following coding standards
# Test your changes
./scripts/test.sh

# Commit with descriptive message
git commit -m "feat: add DNS cache performance monitoring"
```

## Development Environment

### Prerequisites

- **Git**: Version control
- **Bash**: Shell scripting (4.0+)
- **curl**: HTTP client for testing
- **jq**: JSON processor for API testing
- **Node.js**: Optional, for advanced tooling
- **OpenWrt SDK**: For package building (optional)

### Directory Structure

```
notapollo/
├── docs/                       # Documentation
├── package/notapollo/          # OpenWrt package configuration
├── www/notapollo/              # Web interface source
│   ├── api/                    # Backend API scripts
│   ├── css/                    # Stylesheets
│   ├── js/                     # JavaScript code
│   ├── docs/                   # Web-specific documentation
│   └── scripts/                # Build and utility scripts
├── scripts/                    # Development utilities
├── .vscode/                    # VS Code configuration
├── .git/                       # Git repository
├── README.md                   # Project overview
├── CONTRIBUTING.md             # Contribution guidelines
├── CHANGELOG.md                # Version history
└── LICENSE                     # License information
```

### Development Tools

#### VS Code Configuration

The project includes VS Code settings for:
- Consistent formatting (2-space indentation)
- Shell script validation with ShellCheck
- JavaScript linting with ESLint
- Material 3 CSS snippets
- Debugging configuration

#### Git Hooks

Pre-configured hooks for:
- **Pre-commit**: Code quality checks, syntax validation
- **Commit message**: Template for consistent commit messages
- **Pre-push**: Run tests before pushing (optional)

#### Development Scripts

- `scripts/setup-dev.sh` - Initial development environment setup
- `scripts/dev-server.sh` - Start local development server
- `scripts/check-quality.sh` - Run code quality checks
- `scripts/build.sh` - Build project for deployment
- `scripts/test.sh` - Run test suite
- `scripts/generate-docs.sh` - Generate documentation

## Coding Standards

### JavaScript (Google Style Guide)

#### Basic Formatting
```javascript
// Use 2-space indentation
function calculateCacheHitRate(queries, hits) {
  if (queries === 0) {
    return 0;
  }
  return hits / queries;
}

// Use single quotes for strings
const statusMessage = 'Internet connection is working';

// Use camelCase for variables and functions
const dnsResponseTime = 15;
const getUserFriendlyStatus = () => 'Everything looks good';

// Use PascalCase for constructors
class DiagnosticCard {
  constructor(title, status) {
    this.title = title;
    this.status = status;
  }
}
```

#### Documentation
```javascript
/**
 * Monitors DNS performance across both networks.
 * @param {Object} config - Configuration object
 * @param {string} config.primaryProfile - NextDNS profile for primary network
 * @param {string} config.dadProfile - NextDNS profile for Dad's network
 * @param {number} config.queryLimit - Daily query limit
 * @return {Promise<Object>} DNS monitoring results
 */
async function monitorDnsPerformance(config) {
  // Implementation
}
```

#### User-Friendly Language
```javascript
// Good: Plain language for users
const statusMessages = {
  healthy: 'Everything is working great!',
  degraded: 'Some issues detected, but still working',
  broken: 'Something needs attention'
};

// Bad: Technical jargon
const statusMessages = {
  healthy: 'All subsystems operational',
  degraded: 'Degraded performance detected',
  broken: 'Critical system failure'
};
```

### CSS (Material 3 Compliance)

#### Color System
```css
:root {
  /* Use Material 3 design tokens */
  --md-sys-color-primary: #a8c7fa;
  --md-sys-color-on-primary: #002e69;
  --md-sys-color-surface: #101418;
  --md-sys-color-on-surface: #e2e2e9;
  
  /* Status colors for dark theme */
  --status-healthy: #4caf50;
  --status-degraded: #ff9800;
  --status-broken: #f44336;
}
```

#### Component Styling
```css
/* Use consistent spacing and elevation */
.diagnostic-card {
  background: var(--md-sys-color-surface);
  color: var(--md-sys-color-on-surface);
  border-radius: 12px;
  padding: 16px;
  margin: 8px;
  
  /* Material 3 elevation */
  box-shadow: 
    0 1px 3px rgba(0, 0, 0, 0.12),
    0 1px 2px rgba(0, 0, 0, 0.24);
  
  transition: box-shadow 0.2s ease;
}

/* Responsive design with mobile-first approach */
@media (min-width: 768px) {
  .diagnostic-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1024px) {
  .diagnostic-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}
```

### Shell Scripts (POSIX Compliance)

#### Basic Structure
```bash
#!/bin/sh
# DNS monitoring script with cache integration

set -e  # Exit on error

# Use lowercase with underscores for variables
dns_cache_file="/tmp/dns_cache.json"
query_limit_daily=1000
cache_hit_threshold=0.8

# Quote all variable expansions
get_dns_performance() {
  local network_profile="$1"
  local cache_performance
  
  if [ -f "$dns_cache_file" ]; then
    cache_performance=$(jq -r ".${network_profile}.hit_rate" "$dns_cache_file")
  else
    cache_performance="0"
  fi
  
  echo "$cache_performance"
}

# Use proper error handling
main() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed" >&2
    exit 1
  fi
  
  # Implementation
}

main "$@"
```

#### User-Friendly Output
```bash
# Convert technical data to plain language
format_dns_status() {
  local response_time="$1"
  
  if [ "$response_time" -lt 20 ]; then
    echo "Website lookups are very fast"
  elif [ "$response_time" -lt 50 ]; then
    echo "Website lookups are working well"
  elif [ "$response_time" -lt 100 ]; then
    echo "Website lookups are a bit slow"
  else
    echo "Website lookups are very slow"
  fi
}
```

### HTML (Semantic and Accessible)

#### Structure
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>notApollo Network Diagnostics</title>
  
  <!-- Material 3 theme -->
  <meta name="theme-color" content="#101418">
  <meta name="color-scheme" content="dark light">
</head>
<body>
  <header role="banner">
    <h1>notApollo</h1>
    <nav role="navigation" aria-label="Main navigation">
      <!-- Navigation items -->
    </nav>
  </header>
  
  <main role="main">
    <section role="region" aria-labelledby="system-health">
      <h2 id="system-health">System Health</h2>
      <!-- Content -->
    </section>
  </main>
</body>
</html>
```

#### Accessibility
```html
<!-- Use proper ARIA labels -->
<div class="status-indicator" 
     role="img" 
     aria-label="System status: healthy">
  🟢
</div>

<!-- Ensure minimum touch targets (44px) -->
<button class="restart-button" 
        aria-describedby="restart-warning">
  Restart Router
</button>
<div id="restart-warning" class="sr-only">
  This will restart your router and temporarily interrupt internet access
</div>

<!-- Use semantic form elements -->
<fieldset>
  <legend>DNS Settings</legend>
  <label for="query-limit">Daily Query Limit</label>
  <input type="number" id="query-limit" min="100" max="10000">
</fieldset>
```

## Architecture Patterns

### Frontend Architecture

#### Component Structure
```javascript
// Use modular component pattern
class DiagnosticCard {
  constructor(container, config) {
    this.container = container;
    this.config = config;
    this.data = null;
    
    this.init();
  }
  
  init() {
    this.render();
    this.bindEvents();
    this.startUpdates();
  }
  
  render() {
    this.container.innerHTML = this.getTemplate();
  }
  
  getTemplate() {
    return `
      <div class="diagnostic-card">
        <h3>${this.config.title}</h3>
        <div class="status-indicator" data-status="${this.getStatus()}">
          ${this.getStatusIcon()}
        </div>
        <p class="status-message">${this.getStatusMessage()}</p>
      </div>
    `;
  }
  
  update(data) {
    this.data = data;
    this.render();
  }
  
  getStatus() {
    // Convert technical status to user-friendly status
    return this.data?.status || 'unknown';
  }
  
  getStatusMessage() {
    // Return plain language status message
    return this.data?.user_friendly_status || 'Checking status...';
  }
}
```

#### Real-Time Updates
```javascript
// Use Server-Sent Events for real-time updates
class RealTimeUpdater {
  constructor(apiUrl) {
    this.apiUrl = apiUrl;
    this.eventSource = null;
    this.components = new Map();
  }
  
  start() {
    if (typeof EventSource !== 'undefined') {
      this.eventSource = new EventSource(`${this.apiUrl}/stream`);
      this.eventSource.onmessage = (event) => {
        const data = JSON.parse(event.data);
        this.updateComponents(data);
      };
    } else {
      // Fallback to polling for older browsers
      this.startPolling();
    }
  }
  
  updateComponents(data) {
    this.components.forEach((component, id) => {
      if (data[id]) {
        component.update(data[id]);
      }
    });
  }
  
  registerComponent(id, component) {
    this.components.set(id, component);
  }
}
```

### Backend Architecture

#### API Response Pattern
```bash
#!/bin/sh
# Standard API response format

generate_api_response() {
  local status="$1"
  local user_friendly_status="$2"
  local data="$3"
  local error="$4"
  
  cat << EOF
{
  "timestamp": "$(date -Iseconds)",
  "status": "$status",
  "user_friendly_status": "$user_friendly_status",
  "data": $data,
  "error": $error
}
EOF
}

# Usage example
get_system_health() {
  local uptime_seconds
  local load_avg
  local memory_usage
  
  uptime_seconds=$(cat /proc/uptime | cut -d' ' -f1)
  load_avg=$(cat /proc/loadavg | cut -d' ' -f1)
  memory_usage=$(free | awk '/^Mem:/ {printf "%.1f", $3/$2 * 100.0}')
  
  local data
  data=$(cat << EOF
{
  "uptime": $uptime_seconds,
  "uptime_friendly": "$(format_uptime "$uptime_seconds")",
  "load_average": $load_avg,
  "load_friendly": "$(format_load "$load_avg")",
  "memory_usage": $memory_usage,
  "memory_friendly": "$(format_memory "$memory_usage")"
}
EOF
)
  
  if [ "$(echo "$load_avg < 1.0" | bc)" -eq 1 ]; then
    generate_api_response "healthy" "System is running smoothly" "$data" "null"
  else
    generate_api_response "degraded" "System is working but busy" "$data" "null"
  fi
}
```

#### Error Handling Pattern
```bash
# Consistent error handling
handle_error() {
  local error_code="$1"
  local error_message="$2"
  local user_friendly_message="$3"
  
  local error_data
  error_data=$(cat << EOF
{
  "code": "$error_code",
  "message": "$error_message",
  "user_friendly": "$user_friendly_message"
}
EOF
)
  
  generate_api_response "error" "$user_friendly_message" "null" "$error_data"
}

# Usage in diagnostic functions
get_wan_status() {
  if ! command -v ip >/dev/null 2>&1; then
    handle_error "MISSING_TOOL" "ip command not found" "Cannot check internet connection"
    return 1
  fi
  
  local wan_interface
  wan_interface=$(ip route | awk '/default/ {print $5}' | head -1)
  
  if [ -z "$wan_interface" ]; then
    handle_error "NO_WAN_INTERFACE" "No default route found" "Internet connection not configured"
    return 1
  fi
  
  # Continue with WAN diagnostics...
}
```

## Testing Strategy

### Unit Testing

#### JavaScript Tests
```javascript
// Use Jest or similar testing framework
describe('DNS Cache Performance', () => {
  beforeEach(() => {
    // Setup test data
    global.fetch = jest.fn();
  });
  
  afterEach(() => {
    jest.resetAllMocks();
  });
  
  test('should calculate cache hit rate correctly', () => {
    const queries = 100;
    const hits = 85;
    const hitRate = calculateCacheHitRate(queries, hits);
    
    expect(hitRate).toBe(0.85);
  });
  
  test('should handle zero queries gracefully', () => {
    const hitRate = calculateCacheHitRate(0, 0);
    expect(hitRate).toBe(0);
  });
  
  test('should format user-friendly status', () => {
    const status = formatDnsStatus(15); // 15ms response time
    expect(status).toBe('Website lookups are very fast');
  });
});
```

#### Shell Script Tests
```bash
#!/bin/sh
# Shell script testing with simple assertions

test_dns_performance_calculation() {
  # Setup test data
  echo '{"queries": 100, "hits": 85}' > /tmp/test_dns_data.json
  
  # Run function
  result=$(calculate_cache_hit_rate /tmp/test_dns_data.json)
  
  # Assert result
  if [ "$result" = "0.85" ]; then
    echo "✓ DNS performance calculation test passed"
  else
    echo "✗ DNS performance calculation test failed: expected 0.85, got $result"
    return 1
  fi
  
  # Cleanup
  rm -f /tmp/test_dns_data.json
}

test_user_friendly_formatting() {
  result=$(format_dns_status 15)
  expected="Website lookups are very fast"
  
  if [ "$result" = "$expected" ]; then
    echo "✓ User-friendly formatting test passed"
  else
    echo "✗ User-friendly formatting test failed"
    return 1
  fi
}

# Run tests
run_tests() {
  echo "Running shell script tests..."
  
  test_dns_performance_calculation || exit 1
  test_user_friendly_formatting || exit 1
  
  echo "All tests passed!"
}

run_tests
```

### Integration Testing

#### API Testing
```bash
#!/bin/sh
# Integration tests for API endpoints

API_BASE="http://localhost:8080/api"

test_api_endpoint() {
  local endpoint="$1"
  local expected_status="$2"
  
  echo "Testing $endpoint..."
  
  response=$(curl -s "$API_BASE$endpoint")
  status=$(echo "$response" | jq -r '.status')
  
  if [ "$status" = "$expected_status" ]; then
    echo "✓ $endpoint test passed"
  else
    echo "✗ $endpoint test failed: expected $expected_status, got $status"
    return 1
  fi
}

run_api_tests() {
  echo "Running API integration tests..."
  
  # Test system health endpoint
  test_api_endpoint "/diagnostics/system" "healthy" || exit 1
  
  # Test DNS endpoint
  test_api_endpoint "/diagnostics/dns" "healthy" || exit 1
  
  # Test complete diagnostics
  test_api_endpoint "/diagnostics/all" "healthy" || exit 1
  
  echo "All API tests passed!"
}

# Only run if development server is available
if curl -s http://localhost:8080 >/dev/null 2>&1; then
  run_api_tests
else
  echo "Development server not running, skipping API tests"
fi
```

### Performance Testing

#### Load Testing
```bash
#!/bin/sh
# Simple load testing script

CONCURRENT_USERS=5
REQUESTS_PER_USER=10
API_BASE="http://localhost:8080/api"

load_test_endpoint() {
  local endpoint="$1"
  local user_id="$2"
  
  for i in $(seq 1 $REQUESTS_PER_USER); do
    start_time=$(date +%s%N)
    curl -s "$API_BASE$endpoint" >/dev/null
    end_time=$(date +%s%N)
    
    response_time=$((($end_time - $start_time) / 1000000))
    echo "User $user_id, Request $i: ${response_time}ms"
  done
}

run_load_test() {
  echo "Running load test with $CONCURRENT_USERS concurrent users..."
  
  for user in $(seq 1 $CONCURRENT_USERS); do
    load_test_endpoint "/diagnostics/system" "$user" &
  done
  
  wait
  echo "Load test completed"
}

run_load_test
```

## Debugging

### Frontend Debugging

#### Browser Developer Tools
```javascript
// Use console methods for debugging
console.group('DNS Monitoring');
console.log('Cache hit rate:', cacheHitRate);
console.warn('Query limit approaching:', queryUsage);
console.error('DNS resolution failed:', error);
console.groupEnd();

// Use performance monitoring
performance.mark('dns-check-start');
// ... DNS checking code ...
performance.mark('dns-check-end');
performance.measure('dns-check', 'dns-check-start', 'dns-check-end');

// Debug real-time updates
window.debugRealTime = true;
if (window.debugRealTime) {
  console.log('Received update:', data);
}
```

#### Error Handling
```javascript
// Comprehensive error handling
class DiagnosticError extends Error {
  constructor(message, code, userFriendlyMessage) {
    super(message);
    this.name = 'DiagnosticError';
    this.code = code;
    this.userFriendlyMessage = userFriendlyMessage;
  }
}

async function fetchDiagnostics() {
  try {
    const response = await fetch('/api/diagnostics/all');
    
    if (!response.ok) {
      throw new DiagnosticError(
        `HTTP ${response.status}`,
        'HTTP_ERROR',
        'Unable to get diagnostic information'
      );
    }
    
    const data = await response.json();
    return data;
    
  } catch (error) {
    if (error instanceof DiagnosticError) {
      showUserError(error.userFriendlyMessage);
    } else {
      showUserError('Something went wrong while checking system status');
    }
    
    console.error('Diagnostic fetch failed:', error);
    throw error;
  }
}
```

### Backend Debugging

#### Shell Script Debugging
```bash
#!/bin/sh
# Enable debugging with set -x
set -x  # Print commands as they execute

# Use debug logging function
debug_log() {
  if [ "$DEBUG" = "true" ]; then
    echo "[DEBUG] $(date): $*" >&2
  fi
}

# Example usage
get_dns_performance() {
  debug_log "Starting DNS performance check"
  
  local cache_file="/tmp/dns_cache.json"
  debug_log "Using cache file: $cache_file"
  
  if [ ! -f "$cache_file" ]; then
    debug_log "Cache file not found, creating new one"
    echo '{}' > "$cache_file"
  fi
  
  debug_log "DNS performance check completed"
}

# Enable debugging in development
if [ "$NODE_ENV" = "development" ]; then
  DEBUG=true
fi
```

#### API Debugging
```bash
# Debug API responses
debug_api_response() {
  local endpoint="$1"
  local response="$2"
  
  if [ "$DEBUG" = "true" ]; then
    echo "[API DEBUG] Endpoint: $endpoint" >&2
    echo "[API DEBUG] Response: $response" >&2
    echo "[API DEBUG] Response size: $(echo "$response" | wc -c) bytes" >&2
  fi
}

# Usage in API handlers
handle_system_diagnostics() {
  local response
  response=$(get_system_health)
  
  debug_api_response "/diagnostics/system" "$response"
  
  echo "Content-Type: application/json"
  echo ""
  echo "$response"
}
```

## Deployment

### Development Deployment

#### Local Testing
```bash
# Start local development environment
./scripts/dev-server.sh

# Test on different devices
# Use ngrok or similar for external testing
npx ngrok http 8080
```

#### OpenWrt Testing
```bash
# Build and deploy to test router
./scripts/build.sh

# Copy to router
scp package/notapollo/*.ipk root@192.168.69.1:/tmp/

# Install on router
ssh root@192.168.69.1 "opkg install /tmp/notapollo_*.ipk"
```

### Production Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for comprehensive production deployment guide.

## Contributing Workflow

### 1. Issue Creation
- Use issue templates for bugs and features
- Provide detailed reproduction steps
- Include environment information
- Label appropriately

### 2. Development Process
```bash
# Create feature branch
git checkout -b feature/dns-cache-optimization

# Make changes following coding standards
# Write tests for new functionality
# Update documentation

# Run quality checks
./scripts/check-quality.sh

# Run tests
./scripts/test.sh

# Commit with descriptive message
git commit -m "feat: optimize DNS cache performance monitoring

- Add cache hit rate calculation with rolling averages
- Implement smart query frequency adjustment
- Update API response format with cache metrics
- Add user-friendly cache performance messages

Closes #123"
```

### 3. Pull Request Process
- Use pull request template
- Include screenshots for UI changes
- Ensure all tests pass
- Request appropriate reviewers
- Address review feedback

### 4. Code Review Guidelines

#### What to Look For
- **Functionality**: Does the code work as intended?
- **Style**: Follows Google code style guidelines?
- **User Experience**: Uses plain language for user-facing text?
- **Performance**: Efficient for OpenWrt hardware constraints?
- **Security**: Proper input validation and error handling?
- **Testing**: Adequate test coverage?
- **Documentation**: Clear comments and updated docs?

#### Review Checklist
- [ ] Code follows established patterns
- [ ] User-friendly language used throughout
- [ ] Material 3 design compliance maintained
- [ ] Mobile responsiveness preserved
- [ ] API responses include user-friendly messages
- [ ] Error handling is comprehensive
- [ ] Performance impact is acceptable
- [ ] Security best practices followed
- [ ] Tests cover new functionality
- [ ] Documentation is updated

## Resources

### External Documentation
- [OpenWrt Developer Guide](https://openwrt.org/docs/guide-developer/start)
- [Material 3 Design System](https://m3.material.io/)
- [Google JavaScript Style Guide](https://google.github.io/styleguide/jsguide.html)
- [Google HTML/CSS Style Guide](https://google.github.io/styleguide/htmlcssguide.html)

### Tools and Libraries
- [Chart.js Documentation](https://www.chartjs.org/docs/)
- [ESLint Configuration](https://eslint.org/docs/user-guide/configuring)
- [Jest Testing Framework](https://jestjs.io/docs/getting-started)
- [ShellCheck for Shell Scripts](https://www.shellcheck.net/)

### Community
- GitHub Issues for bug reports and feature requests
- GitHub Discussions for questions and community support
- OpenWrt Forums for OpenWrt-specific questions

Happy developing! 🚀