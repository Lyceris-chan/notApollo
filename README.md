# notApollo Network Diagnostic Tool

A comprehensive network diagnostic web interface for OpenWrt routers featuring Material 3 2026 design, real-time monitoring, and universal network compatibility. Provides user-friendly diagnostics across all network layers with responsive design optimized for any device.

## Overview

notApollo is a production-ready network diagnostic tool that automatically adapts to any OpenWrt router configuration. It provides real-time network diagnostics with an intuitive Material 3 2026 compliant interface, comprehensive monitoring capabilities, and offline operation through local asset bundling.

### Key Features

- **🌐 Universal Network Compatibility**: Auto-detects and works with any OpenWrt router setup
- **🎨 Material 3 2026 Design**: Latest Material Design system with responsive breakpoints
- **📱 Mobile-First Responsive**: Optimized for all screen sizes (xs: 0-599px to xl: 1536px+)
- **🔒 Local-Only Operation**: No external dependencies, works completely offline
- **⚡ Real-Time Monitoring**: Live updates with intelligent caching and performance optimization
- **🗣️ User-Friendly Language**: Technical information presented in plain English
- **📊 Comprehensive Diagnostics**: Covers all network layers from physical to application
- **🔍 Smart DNS Monitoring**: Advanced DNS analysis with cache optimization
- **🛡️ Safe Router Control**: Secure reboot functionality with safety confirmations
- **♿ Accessibility Compliant**: WCAG guidelines with 48px touch targets and proper contrast
- **🎯 No-Scroll Dashboard**: Everything visible without scrolling on any device
- **📈 Historical Analytics**: Time-series data with Chart.js visualization
- **🔧 Production Ready**: Clean, optimized code with comprehensive error handling

## Quick Start

### Automatic Installation (Recommended)

The easiest way to install notApollo is using our automatic installation script:

```bash
# Download and run the installation script
wget -O - https://raw.githubusercontent.com/Lyceris-chan/notApollo/main/install-notapollo.sh | sh
```

This script will:
- Automatically detect your OpenWrt version and architecture
- Download the appropriate package from GitHub releases
- Install and configure notApollo
- Verify the installation

### Manual Installation

#### Option 1: Pre-built Packages

1. **Download the package:**
   - Go to [Releases](https://github.com/Lyceris-chan/notApollo/releases)
   - Download the `.ipk` file matching your OpenWrt version and architecture

2. **Install the package:**
   ```bash
   # Upload to your router
   scp notapollo_*.ipk root@192.168.69.1:/tmp/
   
   # Install on the router
   ssh root@192.168.69.1
   opkg install /tmp/notapollo_*.ipk
   ```

#### Option 2: Build from Source

1. **Build the OpenWrt package:**
   ```bash
   cd package/notapollo
   make
   ```

2. **Install the web interface:**
   ```bash
   cd www/notapollo
   make install
   ```

### Access the Interface

After installation, access notApollo at:
- **Primary network:** http://192.168.69.1:8080
- **Guest network:** http://192.168.70.1:8080

### Uninstallation

To completely remove notApollo from your system:

```bash
# Download and run the uninstallation script
wget -O - https://raw.githubusercontent.com/Lyceris-chan/notApollo/main/uninstall-notapollo.sh | sh
```

Or manually:
```bash
# Stop and remove the service
/etc/init.d/notapollo stop
/etc/init.d/notapollo disable

# Remove the package
opkg remove notapollo

# Clean up remaining files (if any)
rm -rf /www/notapollo
rm -f /etc/config/notapollo
rm -f /etc/uhttpd/notapollo

# Restart web server
/etc/init.d/uhttpd restart
```

### Development Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Lyceris-chan/notApollo.git
   cd notApollo
   ```

2. **Set up local development:**
   ```bash
   cd www/notapollo
   ./scripts/setup-build.sh
   ./scripts/serve-local.sh
   ```

3. **Download required assets:**
   ```bash
   ./scripts/download-assets.sh
   ```

### Automated Builds

This project uses GitHub Actions to automatically build packages for multiple OpenWrt versions and architectures:

- **Supported OpenWrt versions:** 23.05.6, 24.10.6, 25.12.2 (latest)
- **Supported architectures:** ramips/mt76x8, x86/64
- **Automatic releases:** Tagged commits create GitHub releases with pre-built packages
- **Installation scripts:** Automatic and manual installation scripts are generated

The build process:
1. Downloads and caches OpenWrt SDKs
2. Downloads and bundles all external assets (Google Fonts, Chart.js, Material Symbols)
3. Builds packages for all supported platforms
4. Creates installation and uninstallation scripts
5. Publishes releases with all artifacts

## Architecture

### System Components

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Web Browser   │◄──►│  HTTP Server     │◄──►│ Diagnostic API  │
│  (Material 3)   │    │  (uhttpd/nginx)  │    │   (Shell/UCI)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Network Architecture

- **Dual Interface Binding**: Serves both 192.168.69.1:8080 and 192.168.70.1:8080
- **DNS Architecture**: dnsmasq → dnsproxy → NextDNS with intelligent caching
- **Local Asset Serving**: All resources bundled locally for offline operation

## Documentation

### User Guides
- [Installation Guide](docs/INSTALLATION.md) - Complete setup instructions
- [User Manual](docs/USER_GUIDE.md) - How to use the diagnostic interface
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Mobile Usage](docs/MOBILE.md) - Optimized mobile experience guide

### Technical Documentation
- [API Reference](docs/API.md) - Complete API endpoint documentation
- [Architecture Guide](docs/ARCHITECTURE.md) - System design and components
- [Development Guide](docs/DEVELOPMENT.md) - Contributing and development setup
- [Deployment Guide](docs/DEPLOYMENT.md) - Production deployment instructions

### OpenWrt Integration
- [Package Integration](package/notapollo/README.md) - OpenWrt package details
- [Build System](docs/BUILD.md) - Build configuration and process
- [Configuration](docs/CONFIGURATION.md) - System configuration options

## Features

### Network Diagnostics

- **🏠 System Health**: Uptime tracking, reboot monitoring, configuration validation
- **🌐 WAN/Internet**: Link state analysis, connectivity testing, latency monitoring, packet loss detection
- **📡 WiFi/Radio**: Multi-band monitoring, client tracking, signal strength analysis, interference detection
- **🖥️ Router Health**: CPU usage, memory utilization, temperature monitoring, process tracking
- **🔌 ONT/Fiber**: Guided LED status checking, connectivity testing, fiber diagnostics
- **🔍 DNS Services**: Universal DNS monitoring with cache optimization and performance analysis
- **📊 Network Performance**: Bandwidth monitoring, throughput analysis, connection quality metrics
- **🔒 Security Monitoring**: Connection tracking, firewall status, intrusion detection alerts

### User Experience

- **🎨 Material 3 2026 Interface**: Latest design system with dynamic color theming
- **📱 Responsive Design**: Optimized breakpoints (xs: 0-599px to xl: 1536px+)
- **⚡ Real-Time Updates**: Live data with Server-Sent Events and intelligent caching
- **📈 Interactive Charts**: Time-series visualization with Chart.js and historical trends
- **🎯 No-Scroll Dashboard**: Everything visible without scrolling on any device size
- **♿ Accessibility Compliant**: WCAG guidelines with proper contrast and 48px touch targets
- **🗣️ Plain Language**: Technical information presented in user-friendly terms
- **🌙 Dark Theme**: Material 3 dark theme optimized for low-light usage

### Advanced Features

- **🧠 Cross-Layer Intelligence**: Correlates issues across network layers for root cause analysis
- **⚡ Smart Caching**: DNS query optimization with intelligent cache integration
- **🛡️ Safety Controls**: Router reboot with 5-second confirmation countdown and safety checks
- **🔌 ONT Guidance**: Step-by-step fiber troubleshooting with visual LED status guide
- **📊 Performance Analytics**: Historical trends, baseline comparison, and anomaly detection
- **🔄 Auto-Discovery**: Universal network detection that works with any OpenWrt setup
- **💾 Local Asset Serving**: Complete offline operation with bundled fonts, icons, and libraries
- **🔧 Production Ready**: Comprehensive error handling, input validation, and security measures

## Development

### Prerequisites

- OpenWrt build environment
- Basic shell scripting knowledge
- Web development tools (optional for UI changes)

### Project Structure

```
notapollo/
├── package/notapollo/          # OpenWrt package configuration
├── www/notapollo/              # Web interface files
├── docs/                       # Documentation
├── scripts/                    # Build and deployment scripts
└── tests/                      # Test suites
```

### Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Follow the [Development Guide](docs/DEVELOPMENT.md)
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: Check the [docs/](docs/) directory
- **Issues**: Report bugs via GitHub issues
- **Discussions**: Use GitHub discussions for questions

## Acknowledgments

- OpenWrt project for the excellent router firmware
- Material Design team for the design system
- Chart.js for visualization capabilities
- NextDNS for DNS filtering services

---

**Note**: This tool is designed specifically for ASUS RT-AX53U routers running OpenWrt with the dual-network configuration described in the requirements. Adaptation for other hardware may require modifications.