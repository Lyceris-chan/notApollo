# notApollo OpenWrt Package Integration Guide

This document explains how the OpenWrt package Makefile integrates with the existing build system in `www/notapollo/` to create a comprehensive package with local asset bundling.

## Integration Architecture

```
OpenWrt Build System
├── package/notapollo/Makefile          # OpenWrt package configuration
├── package/notapollo/files/            # Package-specific files
│   ├── etc/config/notapollo            # UCI configuration
│   └── etc/init.d/notapollo            # Service management
└── www/notapollo/                      # Source application
    ├── scripts/download-assets.sh      # Asset bundling system
    ├── scripts/verify-assets.sh        # Asset verification
    ├── scripts/build.sh                # Production build
    ├── api/                            # Backend API scripts
    ├── css/                            # Stylesheets
    ├── js/                             # JavaScript modules
    ├── fonts/                          # Local font storage
    ├── icons/                          # Local icon storage
    └── config/                         # Server configuration
```

## Build Process Integration

### Phase 1: Source Preparation

The Makefile's `Build/Prepare` section integrates the source files:

```makefile
define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	
	# Copy source files from www/notapollo directory
	$(CP) $(PKG_SOURCE_DIR)/* $(PKG_BUILD_DIR)/
	
	# Copy package-specific files
	$(CP) $(CURDIR)/files/* $(PKG_BUILD_DIR)/
	
	# Make build scripts executable
	find $(PKG_BUILD_DIR)/scripts -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
endef
```

**Key Integration Points:**
- `PKG_SOURCE_DIR:=$(CURDIR)/../../www/notapollo` - Points to the source application
- Copies all source files to the build directory
- Overlays package-specific configuration files
- Ensures build scripts are executable

### Phase 2: Asset Bundling and Build

The `Build/Compile` section orchestrates the complete build process:

```makefile
define Build/Compile
	# === Local Asset Bundling Phase ===
	cd $(PKG_BUILD_DIR) && ./scripts/download-assets.sh || { ... }
	
	# === Asset Verification Phase ===
	cd $(PKG_BUILD_DIR) && ./scripts/verify-assets.sh || { ... }
	
	# === Production Build Phase ===
	cd $(PKG_BUILD_DIR) && ./scripts/build.sh production || { ... }
	
	# === Distribution Optimization ===
	if [ -d $(PKG_BUILD_DIR)/dist ]; then ... fi
endef
```

**Integration Features:**
1. **Asset Download**: Calls `download-assets.sh` to bundle Google Fonts, Material Symbols, and Chart.js
2. **Verification**: Uses `verify-assets.sh` to ensure asset integrity
3. **Production Build**: Executes `build.sh production` for minification and optimization
4. **Distribution Handling**: Uses optimized `dist/` output if available
5. **Error Handling**: Comprehensive error checking with fallback to cached assets

### Phase 3: Package Installation

The `Package/notapollo/install` section handles file installation:

```makefile
define Package/notapollo/install
	# === Web Application Installation ===
	$(INSTALL_DIR) $(1)/www/notapollo
	$(CP) $(PKG_BUILD_DIR)/* $(1)/www/notapollo/
	
	# === Configuration Files ===
	$(INSTALL_CONF) $(CURDIR)/files/etc/config/notapollo $(1)/etc/config/notapollo
	
	# === Service Management ===
	$(INSTALL_BIN) $(CURDIR)/files/etc/init.d/notapollo $(1)/etc/init.d/notapollo
	
	# === Permission Management ===
	find $(1)/www/notapollo/api -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
endef
```

## Build System Integration Details

### Asset Download Integration

The Makefile integrates with `scripts/download-assets.sh`:

**What it downloads:**
- Google Sans Flex fonts (Variable and individual weights)
- Material Symbols Outlined icon fonts
- Chart.js library from CDN

**Integration features:**
- **Fallback handling**: Uses cached assets if download fails
- **Integrity verification**: Checks file sizes and formats
- **Local CSS generation**: Creates font and icon CSS files
- **Error recovery**: Graceful handling of network issues

**Build-time requirements:**
- Internet connectivity (for initial download)
- `curl` command available
- Sufficient disk space for assets (~2-3MB)

### Asset Verification Integration

The Makefile integrates with `scripts/verify-assets.sh`:

**Verification checks:**
- File existence and minimum sizes
- WOFF2 font header validation
- JavaScript library signature checking
- CSS syntax validation
- Font reference verification

**Integration benefits:**
- **Build validation**: Ensures assets are complete before packaging
- **Inventory generation**: Creates `asset-inventory.json`
- **Error detection**: Catches corrupted or incomplete downloads
- **Quality assurance**: Validates file formats and integrity

### Production Build Integration

The Makefile integrates with `scripts/build.sh production`:

**Build optimizations:**
- CSS minification and combination
- JavaScript minification and bundling
- Gzip compression for smaller transfers
- HTML reference updates to minified assets

**Integration features:**
- **Distribution output**: Uses `dist/` directory if created
- **Build reports**: Generates detailed build information
- **Version metadata**: Creates version and build info files
- **Asset preservation**: Maintains API scripts and configuration

## Configuration Integration

### UCI Configuration

The package includes comprehensive UCI configuration in `/etc/config/notapollo`:

```
config main 'main'
    option enabled '1'
    option port '8080'
    option primary_interface '192.168.69.1'
    option dad_interface '192.168.70.1'

config diagnostics 'diagnostics'
    option dns_test_interval '600'
    option cache_optimization '1'
    option nextdns_primary_profile '8753a1'
    option nextdns_dad_profile '5414da'

config security 'security'
    option rate_limit_api '10'
    option input_validation '1'
    option audit_logging '1'

config features 'features'
    option reboot_safety_countdown '5'
    option ont_guidance '1'
    option user_friendly_language '1'
    option dark_theme_default '1'
```

### Service Integration

The init script `/etc/init.d/notapollo` integrates with OpenWrt's procd:

```bash
start_service() {
    config_load notapollo
    
    local enabled
    config_get_bool enabled main enabled 1
    [ "$enabled" -eq 0 ] && return 1
    
    procd_open_instance notapollo
    procd_set_param command $PROG -f -h /www/notapollo -r notApollo \
        -p 192.168.69.1:8080 -p 192.168.70.1:8080
    procd_close_instance
}
```

## Dependency Integration

### Build Dependencies

```makefile
PKG_BUILD_DEPENDS:=curl/host
```

**Purpose**: Ensures `curl` is available during build for asset downloading

### Runtime Dependencies

```makefile
DEPENDS:=+uhttpd +curl +iwinfo +ip-full +bind-dig +coreutils-stat +coreutils-timeout +procps-ng-ps +logread
```

**Integration mapping:**
- `+uhttpd` - Web server for dual interface serving
- `+curl` - API connectivity testing and asset management
- `+iwinfo` - WiFi diagnostics and monitoring
- `+ip-full` - Network interface management
- `+bind-dig` - DNS resolution testing
- `+coreutils-stat` - File size checking for asset verification
- `+coreutils-timeout` - Command timeout management
- `+procps-ng-ps` - Process monitoring for diagnostics
- `+logread` - System log access for troubleshooting

## Post-Installation Integration

### Verification Integration

The Makefile creates installation verification scripts:

```bash
# Created during package installation
/www/notapollo/verify-installation.sh
/www/notapollo/show-build-info.sh
```

**Integration features:**
- Calls existing `verify-assets.sh` if available
- Provides fallback verification for basic files
- Displays build information and asset inventory
- Shows package metadata and version information

### Service Integration

The `postinst` script integrates with OpenWrt services:

```bash
# Enable and start service
/etc/init.d/notapollo enable
/etc/init.d/notapollo start

# Restart uhttpd to apply configuration
/etc/init.d/uhttpd restart
```

## Development Workflow Integration

### Source Modification Workflow

1. **Modify Source Files**
   ```bash
   # Edit files in www/notapollo/
   vim www/notapollo/css/app.css
   vim www/notapollo/js/app.js
   ```

2. **Test Build System**
   ```bash
   cd www/notapollo
   ./scripts/build.sh development
   ./scripts/serve-local.sh
   ```

3. **Build Package**
   ```bash
   make package/notapollo/clean
   make package/notapollo/compile
   ```

4. **Test Package**
   ```bash
   # Run package test suite
   ./package/notapollo/test-build.sh
   ```

### Asset Management Workflow

1. **Update Assets**
   ```bash
   cd www/notapollo
   ./scripts/download-assets.sh
   ./scripts/verify-assets.sh
   ```

2. **Test Asset Integration**
   ```bash
   ./scripts/build.sh production
   ```

3. **Verify Package Build**
   ```bash
   make package/notapollo/compile
   ```

## Troubleshooting Integration Issues

### Build Failures

**Asset Download Issues:**
```bash
# Check internet connectivity
curl -I https://fonts.googleapis.com

# Use cached assets
ls -la www/notapollo/fonts/google-sans-flex/
ls -la www/notapollo/icons/material-symbols/
ls -la www/notapollo/js/lib/
```

**Build Script Issues:**
```bash
# Test scripts individually
cd www/notapollo
./scripts/download-assets.sh
./scripts/verify-assets.sh
./scripts/build.sh production
```

**Permission Issues:**
```bash
# Fix script permissions
find www/notapollo/scripts -name "*.sh" -exec chmod +x {} \;
find www/notapollo/api -name "*.sh" -exec chmod +x {} \;
```

### Runtime Integration Issues

**Service Start Issues:**
```bash
# Check configuration
uci show notapollo

# Check service status
/etc/init.d/notapollo status

# Check logs
logread | grep notapollo
```

**Asset Loading Issues:**
```bash
# Verify installation
/www/notapollo/verify-installation.sh

# Check asset integrity
cd /www/notapollo && ./scripts/verify-assets.sh
```

**Network Access Issues:**
```bash
# Test dual interface binding
netstat -tuln | grep :8080
curl -I http://192.168.69.1:8080
curl -I http://192.168.70.1:8080
```

## Performance Integration

### Build Performance

The integration optimizes build performance through:

1. **Parallel Processing**: Asset download and verification run concurrently where possible
2. **Caching**: Reuses downloaded assets if available
3. **Incremental Builds**: Only rebuilds changed components
4. **Compression**: Gzip compression reduces package size

### Runtime Performance

The integration optimizes runtime performance through:

1. **Local Assets**: No external requests during operation
2. **Minification**: Reduced CSS/JS file sizes
3. **Efficient Serving**: uhttpd optimized for static file serving
4. **Smart Caching**: DNS query optimization and cache integration

## Security Integration

### Build Security

1. **Asset Verification**: Integrity checking prevents corrupted assets
2. **Secure Downloads**: HTTPS for all external asset downloads
3. **Input Validation**: Build scripts validate downloaded content
4. **Error Handling**: Secure error messages without information disclosure

### Runtime Security

1. **No WAN Exposure**: Only binds to internal network interfaces
2. **Input Validation**: All API endpoints validate user input
3. **Rate Limiting**: Prevents abuse of diagnostic endpoints
4. **Audit Logging**: Administrative actions are logged
5. **Secure Permissions**: Proper file and directory permissions

## Future Integration Enhancements

### Planned Improvements

1. **Incremental Asset Updates**: Only download changed assets
2. **Build Caching**: Cache build artifacts for faster rebuilds
3. **Multi-Architecture Support**: Optimize for different OpenWrt targets
4. **Automated Testing**: Continuous integration with build system
5. **Asset Optimization**: Further compression and optimization techniques

### Extension Points

1. **Custom Asset Sources**: Support for additional font/icon sources
2. **Plugin Architecture**: Modular diagnostic components
3. **Theme Customization**: Build-time theme configuration
4. **Localization**: Multi-language asset bundling
5. **Advanced Minification**: Tree-shaking and dead code elimination

This integration provides a comprehensive, production-ready solution that seamlessly combines OpenWrt package management with modern web application build processes, ensuring reliable offline operation while maintaining development flexibility.