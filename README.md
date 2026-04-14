# notApollo Network Diagnostic Tool

A comprehensive network diagnostic webpage for OpenWrt routers, specifically designed for ASUS RT-AX53U with dual-network configuration. Features Material 3 design, real-time monitoring, and user-friendly diagnostics across all network layers.

## Overview

notApollo provides real-time network diagnostics accessible from both primary (192.168.69.x) and isolated guest (192.168.70.x) networks. The system monitors everything from physical ONT/fiber connectivity to application-layer services, presenting information in plain language that anyone can understand.

### Key Features

- **Dual Network Access**: Works from both network segments simultaneously
- **Material 3 Design**: Modern, responsive interface optimized for mobile devices
- **Local-Only Operation**: No external dependencies, works offline
- **Real-Time Monitoring**: Live updates with intelligent caching
- **User-Friendly Language**: Technical information presented in plain English
- **Comprehensive Diagnostics**: Covers all network layers from fiber to applications
- **Smart DNS Monitoring**: Optimized for NextDNS with cache integration
- **Safe Router Control**: Reboot functionality with safety countdown

## Quick Start

### Automatic Installation (Recommended)

The easiest way to install notApollo is using our automatic installation script:

```bash
# Download and run the installation script
wget -O - https://raw.githubusercontent.com/YOUR_USERNAME/notapollo/main/install-notapollo.sh | sh
```

This script will:
- Automatically detect your OpenWrt version and architecture
- Download the appropriate package from GitHub releases
- Install and configure notApollo
- Verify the installation

### Manual Installation

#### Option 1: Pre-built Packages

1. **Download the package:**
   - Go to [Releases](https://github.com/YOUR_USERNAME/notapollo/releases)
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
wget -O - https://raw.githubusercontent.com/YOUR_USERNAME/notapollo/main/uninstall-notapollo.sh | sh
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
   git clone https://github.com/yourusername/notapollo.git
   cd notapollo
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

- **Supported OpenWrt versions:** 23.05.4, 24.10.0
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

- **System Health**: Uptime, reboot tracking, configuration monitoring
- **WAN/Internet**: Link state, connectivity, latency, packet loss monitoring
- **WiFi/Radio**: Multi-band monitoring, client tracking, signal analysis
- **Router Health**: CPU, memory, temperature, process monitoring
- **ONT/Fiber**: Guided LED status checking, connectivity testing
- **DNS Services**: Dual-network monitoring with cache optimization

### User Experience

- **Material 3 Interface**: Dark theme default with responsive design
- **Real-Time Updates**: Live data with Server-Sent Events
- **Interactive Charts**: Time-series visualization with Chart.js
- **Mobile Optimized**: Touch-friendly interface for all devices
- **Plain Language**: Technical information in user-friendly terms

### Advanced Features

- **Cross-Layer Intelligence**: Correlates issues across network layers
- **Smart Caching**: DNS query optimization with cache integration
- **Safety Controls**: Router reboot with 5-second confirmation countdown
- **ONT Guidance**: Step-by-step fiber troubleshooting instructions
- **Performance Monitoring**: Historical trends and baseline comparison

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