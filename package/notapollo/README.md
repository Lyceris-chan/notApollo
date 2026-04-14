# notApollo OpenWrt Package

This directory contains the OpenWrt package configuration for notApollo, a comprehensive network diagnostic webpage with Material 3 design and local asset bundling.

## Package Overview

The notApollo package provides a complete network diagnostic solution for OpenWrt routers with the following key features:

### Core Features
- **Material 3 Design**: Dark theme with Google Sans Flex typography
- **Dual Network Support**: Serves on both 192.168.69.1:8080 and 192.168.70.1:8080
- **Real-time Monitoring**: WAN, WiFi, DNS, and system health diagnostics
- **Smart DNS Optimization**: Cache integration with NextDNS query management
- **User-friendly Language**: Non-technical explanations for all status messages
- **ONT/Fiber Guidance**: LED status interpretation and troubleshooting
- **Safe Router Reboot**: 5-second countdown confirmation system
- **Local Asset Serving**: Complete offline operation capability
- **Mobile Optimization**: Touch-friendly responsive design
- **Production Security**: Comprehensive error handling and security features

### Local Asset Bundling

The package integrates with the build system in `www/notapollo/` to download and bundle all external dependencies locally:

- **Google Sans Flex fonts**: Variable and individual weight fonts
- **Material Symbols icons**: Complete icon font set
- **Chart.js library**: Data visualization library
- **CSS/JS minification**: Production optimization

## Build Process

### Prerequisites

The build system requires internet connectivity during the build phase to download external assets. The following tools are used:

- `curl` - For downloading assets from Google Fonts and CDNs
- `node` (optional) - For advanced minification (falls back to shell-based minification)
- `gzip` - For compression optimization

### Build Phases

1. **Asset Download Phase**
   ```bash
   ./scripts/download-assets.sh
   ```
   - Downloads Google Sans Flex fonts from Google Fonts API
   - Downloads Material Symbols icon fonts
   - Downloads Chart.js library from CDN
   - Generates local CSS files for font references

2. **Asset Verification Phase**
   ```bash
   ./scripts/verify-assets.sh
   ```
   - Verifies file integrity and minimum sizes
   - Validates WOFF2 font headers
   - Checks JavaScript library signatures
   - Generates asset inventory JSON

3. **Production Build Phase**
   ```bash
   ./scripts/build.sh production
   ```
   - Minifies CSS and JavaScript files
   - Creates gzipped versions for better performance
   - Updates HTML references to minified assets
   - Generates build reports and metadata

4. **Package Assembly Phase**
   - Copies optimized distribution files
   - Sets proper file permissions
   - Creates installation verification scripts
   - Generates build information files

### Build Configuration

The Makefile includes several key configurations:

```makefile
# Source directory (relative to package directory)
PKG_SOURCE_DIR:=$(CURDIR)/../../www/notapollo

# Build dependencies
PKG_BUILD_DEPENDS:=curl/host

# Runtime dependencies
DEPENDS:=+uhttpd +curl +iwinfo +ip-full +bind-dig +coreutils-stat +coreutils-timeout +procps-ng-ps +logread
```

## Installation Process

### File Installation

The package installs files to the following locations:

```
/www/notapollo/                    # Web application files
├── index.html                     # Main application page
├── css/app.min.css               # Minified stylesheets
├── js/app.min.js                 # Minified JavaScript
├── fonts/google-sans-flex/       # Local font files
├── icons/material-symbols/       # Local icon fonts
├── api/                          # Backend API scripts
├── config/                       # Server configuration
├── scripts/                      # Maintenance scripts
├── docs/                         # Documentation
├── asset-inventory.json          # Asset inventory
├── build-report.txt              # Build report
├── version.json                  # Version metadata
├── BUILD_INFO.txt                # Package build info
├── verify-installation.sh        # Installation verification
└── show-build-info.sh           # Build information display

/etc/config/notapollo             # UCI configuration file
/etc/init.d/notapollo            # Service management script
/etc/uhttpd/notapollo            # uhttpd configuration
```

### Permission Management

The Makefile sets appropriate permissions for different file types:

- **Executable scripts**: API scripts (`api/*.sh`), build scripts (`scripts/*.sh`)
- **Web assets**: HTML, CSS, JS, fonts, images (644 permissions)
- **Configuration files**: UCI config, uhttpd config (644 permissions)
- **Service scripts**: Init script (755 permissions)

### Post-Installation Configuration

The `postinst` script performs comprehensive setup:

1. **Installation Verification**
   - Runs asset verification script
   - Checks core file presence
   - Displays build information

2. **Service Configuration**
   - Enables notApollo service
   - Restarts uhttpd to apply configuration
   - Starts notApollo service
   - Verifies service status

3. **User Information**
   - Displays access URLs for both networks
   - Lists enabled features
   - Provides troubleshooting commands

## Dependencies

### Build Dependencies

- `curl/host` - Required for downloading assets during build

### Runtime Dependencies

- `+uhttpd` - Web server for serving the application
- `+curl` - For API calls and connectivity testing
- `+iwinfo` - WiFi information and diagnostics
- `+ip-full` - Network interface management
- `+bind-dig` - DNS resolution testing
- `+coreutils-stat` - File size checking
- `+coreutils-timeout` - Command timeout management
- `+procps-ng-ps` - Process monitoring
- `+logread` - System log access

## Configuration

### UCI Configuration (`/etc/config/notapollo`)

```
config main 'main'
    option enabled '1'
    option port '8080'
    option primary_interface '192.168.69.1'
    option dad_interface '192.168.70.1'
    option max_connections '100'
    option script_timeout '60'
    option network_timeout '30'

config diagnostics 'diagnostics'
    option update_interval '30'
    option dns_test_interval '600'
    option cache_optimization '1'
    option nextdns_primary_profile '8753a1'
    option nextdns_dad_profile '5414da'
    option monthly_query_limit '300000'

config security 'security'
    option rate_limit_api '10'
    option rate_limit_burst '5'
    option input_validation '1'
    option audit_logging '1'

config features 'features'
    option reboot_safety_countdown '5'
    option ont_guidance '1'
    option user_friendly_language '1'
    option dark_theme_default '1'
    option mobile_optimization '1'
```

### Service Management

```bash
# Service control
/etc/init.d/notapollo start|stop|restart|status

# Configuration reload
/etc/init.d/notapollo reload

# Enable/disable service
/etc/init.d/notapollo enable|disable
```

## Verification and Troubleshooting

### Installation Verification

```bash
# Run comprehensive verification
/www/notapollo/verify-installation.sh

# Display build information
/www/notapollo/show-build-info.sh

# Check service status
/etc/init.d/notapollo status
```

### Asset Verification

```bash
# Verify all assets
cd /www/notapollo && ./scripts/verify-assets.sh

# Verify specific asset types
cd /www/notapollo && ./scripts/verify-assets.sh fonts
cd /www/notapollo && ./scripts/verify-assets.sh icons
cd /www/notapollo && ./scripts/verify-assets.sh js
```

### Log Monitoring

```bash
# Monitor notApollo logs
logread | grep notapollo

# Monitor uhttpd logs
logread | grep uhttpd

# Monitor both services
logread | grep -E '(notapollo|uhttpd)'
```

### Network Access Testing

```bash
# Test primary network access
curl -I http://192.168.69.1:8080

# Test Dad's network access
curl -I http://192.168.70.1:8080

# Check listening ports
netstat -tuln | grep :8080
```

## Build Troubleshooting

### Asset Download Issues

If asset download fails during build:

1. **Check Internet Connectivity**
   ```bash
   curl -I https://fonts.googleapis.com
   curl -I https://cdn.jsdelivr.net
   ```

2. **Use Cached Assets**
   - Place pre-downloaded assets in the source directory
   - The build system will use existing assets if download fails

3. **Manual Asset Download**
   ```bash
   cd www/notapollo
   ./scripts/download-assets.sh
   ```

### Build Failures

Common build issues and solutions:

1. **Missing Build Dependencies**
   ```bash
   # Install curl for asset downloading
   opkg update && opkg install curl
   ```

2. **Permission Issues**
   ```bash
   # Make scripts executable
   find www/notapollo/scripts -name "*.sh" -exec chmod +x {} \;
   ```

3. **Disk Space Issues**
   ```bash
   # Check available space
   df -h
   
   # Clean build directories
   cd www/notapollo && ./scripts/build.sh clean
   ```

### Runtime Issues

1. **Service Won't Start**
   ```bash
   # Check configuration
   uci show notapollo
   
   # Check uhttpd status
   /etc/init.d/uhttpd status
   
   # Restart uhttpd
   /etc/init.d/uhttpd restart
   ```

2. **Port Conflicts**
   ```bash
   # Check what's using port 8080
   netstat -tuln | grep :8080
   
   # Change port in configuration
   uci set notapollo.main.port='8081'
   uci commit notapollo
   /etc/init.d/notapollo restart
   ```

3. **Asset Loading Issues**
   ```bash
   # Verify assets are present
   /www/notapollo/verify-installation.sh
   
   # Check file permissions
   ls -la /www/notapollo/
   ```

## Development and Customization

### Modifying the Package

1. **Update Source Files**
   - Modify files in `www/notapollo/`
   - The Makefile will copy and build from this directory

2. **Rebuild Package**
   ```bash
   make package/notapollo/clean
   make package/notapollo/compile
   ```

3. **Test Installation**
   ```bash
   opkg install bin/packages/*/notapollo_*.ipk
   ```

### Adding New Dependencies

Update the `DEPENDS` line in the Makefile:

```makefile
DEPENDS:=+uhttpd +curl +iwinfo +ip-full +bind-dig +your-new-package
```

### Customizing Build Process

Modify the `Build/Compile` section to add custom build steps:

```makefile
define Build/Compile
    # Existing build steps...
    
    # Add custom build step
    cd $(PKG_BUILD_DIR) && ./scripts/your-custom-script.sh
endef
```

## Security Considerations

The package implements several security measures:

1. **No WAN Exposure**: Only binds to internal network interfaces
2. **Input Validation**: All API endpoints validate user input
3. **Rate Limiting**: Prevents abuse of API endpoints
4. **Secure Permissions**: Proper file and directory permissions
5. **Audit Logging**: Administrative actions are logged
6. **Error Handling**: Secure error messages without information disclosure

## Performance Optimization

The build system includes several performance optimizations:

1. **Asset Minification**: CSS and JavaScript are minified
2. **Gzip Compression**: Compressed versions for smaller transfers
3. **Local Serving**: No external requests during operation
4. **Efficient Caching**: Smart DNS query management
5. **Mobile Optimization**: Touch-friendly responsive design

## License and Maintenance

- **License**: GPL-2.0
- **Maintainer**: notApollo Team
- **Package Architecture**: `all` (architecture independent)
- **Configuration Backup**: UCI configuration is preserved during upgrades

This package provides a complete, production-ready network diagnostic solution for OpenWrt routers with comprehensive local asset bundling and offline operation capabilities.