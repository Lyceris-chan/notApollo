# notApollo Build System

This document describes the comprehensive build configuration for local asset bundling in the notApollo network diagnostic webpage.

## Overview

The build system ensures all external dependencies are downloaded and bundled locally to avoid internet connectivity requirements during operation. This includes Google Sans Flex fonts, Chart.js library, and Material Symbols icon fonts.

## Build Scripts

### 1. Asset Download (`scripts/download-assets.sh`)

Downloads and bundles all external assets locally:

- **Google Sans Flex fonts**: Downloads variable and individual weight fonts
- **Chart.js library**: Downloads the latest Chart.js minified library
- **Material Symbols icons**: Downloads Material Symbols Outlined icon fonts
- **CSS generation**: Creates local CSS files for fonts and icons

**Usage:**
```bash
./scripts/download-assets.sh
```

**Features:**
- Integrity verification with file size checks
- Automatic CSS generation for local font references
- Error handling and logging
- Follows Google code style guidelines

### 2. Build System (`scripts/build.sh`)

Handles CSS/JS minification and optimization:

- **CSS minification**: Combines and minifies all CSS files
- **JavaScript minification**: Combines and minifies application JS
- **Asset optimization**: Creates gzipped versions for better performance
- **HTML updates**: Updates references to use minified assets

**Usage:**
```bash
# Production build (default)
./scripts/build.sh production

# Development build (no minification)
./scripts/build.sh development

# Clean build directories
./scripts/build.sh clean
```

**Output:**
- `build/` - Intermediate build files
- `dist/` - Final distribution files
- `build-report.txt` - Detailed build report
- `version.json` - Build metadata

### 3. Asset Verification (`scripts/verify-assets.sh`)

Comprehensive asset verification and integrity checking:

- **File existence**: Verifies all required assets are present
- **Size validation**: Checks minimum file sizes to detect corruption
- **Format validation**: Validates WOFF2 headers and file formats
- **Reference checking**: Verifies CSS font references are correct
- **Inventory generation**: Creates JSON inventory of all assets

**Usage:**
```bash
# Full verification (default)
./scripts/verify-assets.sh

# Verify specific asset types
./scripts/verify-assets.sh fonts
./scripts/verify-assets.sh icons
./scripts/verify-assets.sh js
./scripts/verify-assets.sh css

# Generate asset inventory
./scripts/verify-assets.sh inventory
```

### 4. Local Development Server (`scripts/serve-local.sh`)

Local serving configuration for development and testing:

- **Multi-server support**: Automatically detects available HTTP servers
- **Asset verification**: Verifies assets before serving
- **Network information**: Shows available network interfaces
- **Configurable options**: Port, host, and server type selection

**Usage:**
```bash
# Start server on default port (8080)
./scripts/serve-local.sh

# Custom port and host
./scripts/serve-local.sh -p 3000 -h 192.168.1.100

# Force specific server type
./scripts/serve-local.sh -s python3

# Skip asset verification
./scripts/serve-local.sh --no-verify
```

**Supported servers:**
- Python 3 HTTP server
- Python 2 SimpleHTTPServer
- Node.js HTTP server
- PHP built-in server
- BusyBox httpd
- Netcat fallback (basic)

### 5. Master Setup Script (`scripts/setup-build.sh`)

Orchestrates the complete build process:

- **Automated workflow**: Downloads, builds, and verifies in sequence
- **Flexible options**: Configurable build type and options
- **Error handling**: Comprehensive error checking and reporting
- **Development server**: Optional server startup after build

**Usage:**
```bash
# Full production build
./scripts/setup-build.sh

# Development build with server
./scripts/setup-build.sh --build-type development --serve

# Clean build with fresh assets
./scripts/setup-build.sh --clean --download-assets

# Skip download, verify only
./scripts/setup-build.sh --no-download --verify
```

## Asset Structure

### Fonts (`fonts/google-sans-flex/`)
```
fonts/google-sans-flex/
├── GoogleSansFlex-Variable.woff2    # Variable font (300-700 weights)
├── GoogleSansFlex-Light.woff2       # 300 weight
├── GoogleSansFlex-Regular.woff2     # 400 weight
├── GoogleSansFlex-Medium.woff2      # 500 weight
├── GoogleSansFlex-SemiBold.woff2    # 600 weight
├── GoogleSansFlex-Bold.woff2        # 700 weight
└── fonts.css                        # Local font definitions
```

### Icons (`icons/material-symbols/`)
```
icons/material-symbols/
├── material-symbols-outlined.woff2  # Primary icon font
├── material-symbols-outlined-0.woff2 # Additional variants
└── icons.css                        # Local icon definitions
```

### JavaScript (`js/lib/`)
```
js/lib/
└── chart.min.js                     # Chart.js library (local)
```

## Build Configuration

### Production Build
- CSS and JavaScript minification enabled
- Gzip compression for smaller file sizes
- Asset optimization and bundling
- HTML references updated to minified assets

### Development Build
- No minification for easier debugging
- Source maps preserved where available
- Faster build times
- Original file structure maintained

## Integration with OpenWrt

### Makefile Integration
The build system is integrated into the OpenWrt Makefile:

```makefile
define Build/Compile
	# Download and bundle local assets
	cd $(PKG_BUILD_DIR) && ./scripts/download-assets.sh
	
	# Verify assets
	cd $(PKG_BUILD_DIR) && ./scripts/verify-assets.sh
	
	# Build production version
	cd $(PKG_BUILD_DIR) && ./scripts/build.sh production
endef
```

### Package Dependencies
Required OpenWrt packages:
- `+uhttpd` - Web server
- `+curl` - Asset downloading
- `+iwinfo` - WiFi information
- `+coreutils-stat` - File size checking

### Installation Verification
Post-installation verification script:
```bash
/www/notapollo/verify-installation.sh
```

## Asset Inventory

The build system generates a comprehensive asset inventory (`asset-inventory.json`):

```json
{
  "generated": "2024-01-15T10:30:00Z",
  "fonts": {
    "GoogleSansFlex-Variable.woff2": {
      "size": 87432,
      "path": "fonts/google-sans-flex/GoogleSansFlex-Variable.woff2"
    }
  },
  "icons": {
    "material-symbols-outlined.woff2": {
      "size": 234567,
      "path": "icons/material-symbols/material-symbols-outlined.woff2"
    }
  },
  "javascript": {
    "chart.min.js": {
      "size": 345678,
      "path": "js/lib/chart.min.js"
    }
  }
}
```

## Build Reports

Detailed build reports are generated (`build-report.txt`):

```
notApollo Build Report
=====================
Build Date: Mon Jan 15 10:30:00 UTC 2024
Build Type: Production (Minified)

Asset Sizes:
- CSS (minified): 12345 bytes
- CSS (gzipped): 3456 bytes
- JS (minified): 23456 bytes
- JS (gzipped): 7890 bytes
- Chart.js: 345678 bytes

Font Assets:
- GoogleSansFlex-Variable.woff2: 87432 bytes
- GoogleSansFlex-Regular.woff2: 45678 bytes

Icon Assets:
- material-symbols-outlined.woff2: 234567 bytes

Total Distribution Size: 756789 bytes
```

## Offline Operation

The build system ensures complete offline operation:

1. **No CDN dependencies**: All fonts and libraries are local
2. **Local CSS references**: Font and icon CSS uses local paths
3. **Bundled libraries**: Chart.js is included in the package
4. **Asset verification**: Ensures all required files are present
5. **Integrity checking**: Validates file formats and sizes

## Development Workflow

### Initial Setup
```bash
# Clone/download the project
cd www/notapollo

# Run complete setup
./scripts/setup-build.sh --clean --download-assets --verify --serve
```

### Development Cycle
```bash
# Make changes to source files
# ...

# Rebuild for testing
./scripts/build.sh development

# Start development server
./scripts/serve-local.sh -p 8080
```

### Production Deployment
```bash
# Build production version
./scripts/setup-build.sh --build-type production

# Deploy dist/ directory to target
# or use OpenWrt package build system
```

## Troubleshooting

### Asset Download Issues
```bash
# Check network connectivity
curl -I https://fonts.googleapis.com

# Verify download script
./scripts/download-assets.sh

# Check downloaded files
./scripts/verify-assets.sh
```

### Build Issues
```bash
# Clean and rebuild
./scripts/build.sh clean
./scripts/setup-build.sh --clean --download-assets

# Check build dependencies
./scripts/setup-build.sh --help
```

### Server Issues
```bash
# Check available servers
./scripts/serve-local.sh --help

# Try different server type
./scripts/serve-local.sh -s python3

# Check port availability
netstat -tuln | grep :8080
```

## Security Considerations

- **Local assets only**: No external requests during operation
- **Integrity verification**: File size and format validation
- **Secure downloads**: HTTPS for all asset downloads
- **Input validation**: Proper handling of downloaded content
- **Error handling**: Graceful failure without information disclosure

## Performance Optimization

- **Minification**: CSS and JS size reduction
- **Compression**: Gzip encoding for smaller transfers
- **Caching**: Proper cache headers for static assets
- **Bundling**: Reduced number of HTTP requests
- **Optimization**: Efficient asset loading and rendering

This build system provides a comprehensive solution for local asset bundling while maintaining security, performance, and reliability requirements for the notApollo diagnostic webpage.