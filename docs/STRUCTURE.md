# notApollo Project Directory Structure

## Complete Directory Layout

```
/www/notapollo/                          # Main application directory
├── index.html                           # Main application page
├── manifest.json                        # PWA manifest for mobile app behavior
├── sw.js                               # Service worker for offline functionality
├── .gitignore                          # Git ignore file for development
├── Makefile                            # Build configuration for OpenWrt
├── STRUCTURE.md                        # This documentation file
│
├── css/                                # Stylesheets directory
│   ├── material3.css                   # Material 3 design system styles
│   └── app.css                         # Application-specific styles
│
├── js/                                 # JavaScript modules directory
│   ├── app.js                          # Main application logic
│   ├── diagnostics.js                  # Diagnostic data handling
│   ├── charts.js                       # Chart.js integration
│   └── lib/                            # Third-party libraries
│       └── chart.min.js                # Chart.js library (local copy)
│
├── fonts/                              # Local font files directory
│   └── google-sans-flex/               # Google Sans Flex font family
│       └── README.md                   # Font installation instructions
│
├── icons/                              # Icon assets directory
│   └── material-symbols/               # Material Symbols icon fonts
│       └── README.md                   # Icon installation instructions
│
├── images/                             # Image assets directory
│   ├── favicon.ico                     # Browser favicon
│   ├── icon-192.png                    # PWA icon 192x192
│   └── icon-512.png                    # PWA icon 512x512
│
├── api/                                # Backend API scripts directory
│   ├── diagnostics.sh                  # Main diagnostics endpoint
│   ├── system.sh                       # System health and control
│   ├── reboot.sh                       # Safe router reboot with countdown
│   ├── dns.sh                          # DNS health with cache optimization
│   └── ont.sh                          # ONT/Fiber guidance system
│
├── config/                             # Server configuration files
│   ├── uhttpd.conf                     # uhttpd configuration for dual interfaces
│   └── nginx.conf                      # nginx configuration (alternative)
│
├── scripts/                            # Installation and maintenance scripts
│   ├── install.sh                      # Automated installation script
│   └── download-assets.sh              # Download local assets script
│
└── docs/                               # Documentation directory
    ├── README.md                       # Project overview and features
    ├── API.md                          # API endpoint documentation
    └── DEPLOYMENT.md                   # Deployment and installation guide
```

## OpenWrt Package Structure

```
/package/notapollo/                      # OpenWrt package directory
├── Makefile                            # OpenWrt package build configuration
└── files/                              # Package installation files
    └── etc/                            # System configuration files
        ├── config/                     # UCI configuration
        │   └── notapollo               # notApollo configuration file
        └── init.d/                     # Init scripts
            └── notapollo               # Service management script
```

## Key Features by Directory

### `/css/` - Material 3 Design System
- **Dark theme default** with Material 3 color tokens
- **Responsive design** with mobile-first approach
- **Google Sans Flex typography** for optimal readability
- **Touch-friendly interactions** with proper sizing

### `/js/` - Application Logic
- **Vanilla JavaScript** with ES6+ features
- **Real-time updates** via Server-Sent Events
- **Chart.js integration** for data visualization
- **Modular architecture** for maintainability

### `/fonts/` & `/icons/` - Local Assets
- **Google Sans Flex** font family (downloaded locally)
- **Material Symbols** icon fonts (downloaded locally)
- **No external dependencies** - fully offline capable

### `/api/` - Diagnostic Backend
- **Shell script APIs** optimized for OpenWrt
- **JSON responses** with user-friendly messages
- **Smart DNS monitoring** with cache optimization
- **Safety features** for router control operations

### `/config/` - Server Configuration
- **Dual interface binding** (192.168.69.1:8080, 192.168.70.1:8080)
- **Security headers** and rate limiting
- **CGI script handling** for API endpoints
- **Performance optimization** settings

### `/scripts/` - Automation
- **Automated installation** with verification
- **Asset downloading** for local serving
- **Permission management** and configuration

## Local Asset Strategy

The project follows a **local-first approach** to ensure reliability:

1. **Fonts**: Google Sans Flex downloaded and served locally
2. **Icons**: Material Symbols fonts bundled locally  
3. **JavaScript**: Chart.js library included in package
4. **No CDN dependencies** - works without internet access
5. **Offline PWA capability** via service worker

## Network Architecture

- **Primary Network**: 192.168.69.x → 192.168.69.1:8080
- **Dad's Network**: 192.168.70.x → 192.168.70.1:8080
- **Dual interface serving** with identical functionality
- **No WAN exposure** - internal networks only

## Security Features

- **Input validation** on all API endpoints
- **Rate limiting** to prevent abuse
- **Command injection protection** in shell scripts
- **Secure error handling** without information disclosure
- **Audit logging** for administrative actions

## Installation Methods

1. **Manual Installation**: Copy files and configure manually
2. **Script Installation**: Use `scripts/install.sh` for automation
3. **OpenWrt Package**: Build and install as native package
4. **Asset Download**: Use `scripts/download-assets.sh` for dependencies

This structure provides a complete, production-ready network diagnostic webpage that meets all OpenWrt conventions while ensuring local asset serving and comprehensive functionality.