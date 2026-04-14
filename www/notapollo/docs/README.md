# notApollo Network Diagnostics

A comprehensive network diagnostic webpage for OpenWrt routers with Material 3 design.

## Features

- **Multi-Network Access**: Accessible from both 192.168.69.x and 192.168.70.x networks
- **Material 3 Design**: Modern dark theme interface with Google Sans Flex fonts
- **Local Assets**: All dependencies bundled locally (no internet required)
- **Real-time Monitoring**: Live updates of network status and performance
- **Smart DNS Monitoring**: Optimized DNS testing with cache integration
- **User-Friendly Language**: Plain language explanations for all technical terms
- **ONT Guidance**: Step-by-step fiber troubleshooting instructions
- **Safe Router Control**: 5-second safety countdown for reboot operations

## Installation

1. Copy the entire `/www/notapollo/` directory to your OpenWrt router
2. Configure uhttpd or nginx using the provided configuration files
3. Ensure proper permissions on API scripts (`chmod +x api/*.sh`)
4. Access via http://192.168.69.1:8080 or http://192.168.70.1:8080

## Directory Structure

```
/www/notapollo/
├── index.html              # Main application page
├── manifest.json           # PWA manifest
├── sw.js                   # Service worker
├── css/                    # Stylesheets
├── js/                     # JavaScript modules
├── fonts/                  # Local font files
├── icons/                  # Material symbols
├── images/                 # App icons and images
├── api/                    # Backend API scripts
├── config/                 # Server configurations
└── docs/                   # Documentation
```

## Development

- Follow Google JavaScript and CSS style guides
- All assets must be served locally
- Implement comprehensive error handling
- Use Material 3 design principles
- Optimize for mobile devices

## License

This project follows OpenWrt licensing conventions.