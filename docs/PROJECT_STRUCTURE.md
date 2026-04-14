# Project Structure Overview

This document provides an overview of the notApollo project structure and organization.

## Repository Structure

```
notapollo/
├── .git/                           # Git version control
├── .gitignore                      # Git ignore patterns for OpenWrt projects
├── .vscode/                        # VS Code configuration (created by setup script)
├── README.md                       # Project overview and quick start guide
├── CONTRIBUTING.md                 # Contribution guidelines and coding standards
├── CHANGELOG.md                    # Version history and release notes
├── LICENSE                         # MIT license with third-party attributions
│
├── docs/                           # Comprehensive documentation
│   ├── INSTALLATION.md             # Installation guide for multiple deployment methods
│   ├── API.md                      # Complete API reference with examples
│   ├── DEPLOYMENT.md               # Production deployment and monitoring guide
│   ├── DEVELOPMENT.md              # Development guide with coding standards
│   ├── TROUBLESHOOTING.md          # Common issues and solutions
│   └── PROJECT_STRUCTURE.md        # This file - project organization overview
│
├── scripts/                        # Development and build utilities
│   └── setup-dev.sh                # Automated development environment setup
│
├── package/notapollo/              # OpenWrt package configuration (existing)
│   ├── Makefile                    # OpenWrt package build configuration
│   ├── README.md                   # Package-specific documentation
│   ├── INTEGRATION.md              # Integration details
│   ├── SUMMARY.md                  # Package summary
│   ├── files/                      # Package installation files
│   └── test-build.sh               # Package build testing script
│
└── www/notapollo/                  # Web interface source code (existing)
    ├── index.html                  # Main application entry point
    ├── manifest.json               # PWA manifest
    ├── sw.js                       # Service worker for offline functionality
    ├── .gitignore                  # Web-specific ignore patterns
    │
    ├── css/                        # Stylesheets
    │   ├── app.css                 # Application-specific styles
    │   └── material3.css           # Material 3 design system styles
    │
    ├── js/                         # JavaScript source code
    │   ├── app.js                  # Main application logic
    │   ├── charts.js               # Chart.js integration and visualization
    │   ├── diagnostics.js          # Diagnostic data handling
    │   └── lib/                    # Third-party libraries
    │       └── chart.min.js        # Chart.js library (bundled locally)
    │
    ├── api/                        # Backend API scripts
    │   ├── diagnostics.sh          # Main diagnostic data collection
    │   ├── dns.sh                  # DNS monitoring with cache integration
    │   ├── ont.sh                  # ONT/fiber diagnostics
    │   ├── reboot.sh               # Router reboot functionality
    │   └── system.sh               # System health monitoring
    │
    ├── config/                     # Server configuration
    │   ├── nginx.conf              # Nginx configuration
    │   └── uhttpd.conf             # uhttpd configuration
    │
    ├── fonts/                      # Typography assets
    │   └── google-sans-flex/       # Google Sans Flex font family
    │       └── README.md           # Font usage documentation
    │
    ├── icons/                      # Icon assets
    │   └── material-symbols/       # Material Symbols icon set
    │       └── README.md           # Icon usage documentation
    │
    ├── images/                     # Image assets
    │   ├── favicon.ico             # Browser favicon
    │   ├── icon-192.png            # PWA icon (192x192)
    │   └── icon-512.png            # PWA icon (512x512)
    │
    ├── docs/                       # Web-specific documentation
    │   ├── API.md                  # API endpoint documentation
    │   ├── DEPLOYMENT.md           # Web deployment guide
    │   └── README.md               # Web interface overview
    │
    └── scripts/                    # Build and utility scripts
        ├── README.md               # Script documentation
        ├── build.sh                # Production build script
        ├── download-assets.sh      # Asset download automation
        ├── install.sh              # Installation script
        ├── serve-local.sh          # Local development server
        ├── setup-build.sh          # Build environment setup
        └── verify-assets.sh        # Asset integrity verification
```

## Documentation Organization

### User Documentation
- **README.md**: Project overview, quick start, and navigation
- **docs/INSTALLATION.md**: Complete installation guide with multiple methods
- **docs/TROUBLESHOOTING.md**: Common issues and step-by-step solutions
- **package/notapollo/README.md**: OpenWrt package specific information

### Developer Documentation
- **CONTRIBUTING.md**: Contribution guidelines and coding standards
- **docs/DEVELOPMENT.md**: Comprehensive development guide
- **docs/API.md**: Complete API reference with examples
- **docs/DEPLOYMENT.md**: Production deployment procedures

### Technical Documentation
- **CHANGELOG.md**: Version history and release notes
- **LICENSE**: Legal information and third-party attributions
- **docs/PROJECT_STRUCTURE.md**: This file - project organization

## Key Features Documented

### Version Control Best Practices
- Comprehensive .gitignore for OpenWrt projects
- Git hooks for code quality and commit message standards
- Branch strategy and workflow documentation
- Automated development environment setup

### Google Code Style Compliance
- JavaScript style guide implementation
- CSS/HTML formatting standards
- Shell script POSIX compliance
- Material 3 design system integration

### OpenWrt Integration
- Package build system configuration
- Dual network interface support (192.168.69.x, 192.168.70.x)
- uhttpd web server configuration
- Asset bundling for offline operation

### User Experience Focus
- User-friendly language requirements throughout
- Material 3 dark theme as default
- Mobile-first responsive design
- Accessibility compliance guidelines

### Production Readiness
- Comprehensive error handling patterns
- Security best practices and input validation
- Performance optimization for OpenWrt hardware
- Monitoring and logging capabilities
- Backup and recovery procedures

## Development Workflow

### Setup Process
1. Clone repository
2. Run `./scripts/setup-dev.sh` for automated environment setup
3. Start development with `./scripts/dev-server.sh`
4. Follow coding standards in CONTRIBUTING.md

### Quality Assurance
- Pre-commit hooks for code quality
- Automated testing framework structure
- Code style validation
- User-friendly language verification

### Deployment Pipeline
- Local development and testing
- OpenWrt package building
- Production deployment with monitoring
- Backup and recovery procedures

## Architecture Highlights

### Dual Network Support
- Primary network: 192.168.69.x/24
- Guest network: 192.168.70.x/24
- Simultaneous access from both networks

### DNS Monitoring with Cache Integration
- NextDNS integration with profiles (8753a1, 5414da)
- Smart query limiting to stay under 300,000 monthly queries
- Cache performance monitoring and optimization
- dnsproxy cache efficiency tracking

### Material 3 Design System
- Dark theme as default with light theme support
- Responsive design for mobile devices
- Accessibility compliance with ARIA labels
- Touch-friendly interface with 44px minimum targets

### Local-Only Operation
- All assets bundled locally for offline operation
- No external dependencies during runtime
- Chart.js and Material Symbols included locally
- Google Sans Flex font family bundled

## Future Development

### Planned Enhancements
- Real-time data visualization with Chart.js
- Cross-layer network intelligence and correlation
- Router reboot functionality with safety countdown
- ONT guidance system for fiber troubleshooting
- Production monitoring and alerting

### Extensibility
- Modular component architecture
- Plugin system for additional diagnostics
- Configurable monitoring intervals
- Custom theme support

This project structure provides a solid foundation for developing, deploying, and maintaining the notApollo network diagnostic tool while following industry best practices for OpenWrt development and Material 3 design compliance.