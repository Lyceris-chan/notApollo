# notApollo Build Scripts

This directory contains the complete build configuration for local asset bundling in the notApollo network diagnostic webpage.

## Quick Start

### Complete Setup (Recommended)
```bash
# Download assets, build, and verify everything
./setup-build.sh

# Development build with local server
./setup-build.sh --build-type development --serve
```

### Individual Scripts

#### 1. Download Assets
```bash
./download-assets.sh
```
Downloads Google Sans Flex fonts, Chart.js library, and Material Symbols icons locally.

#### 2. Verify Assets
```bash
./verify-assets.sh
```
Verifies all assets are present and valid with integrity checking.

#### 3. Build Application
```bash
./build.sh production    # Minified production build
./build.sh development   # Development build
./build.sh clean         # Clean build directories
```

#### 4. Serve Locally
```bash
./serve-local.sh         # Start development server
./serve-local.sh -p 3000 # Custom port
```

## Script Features

### Asset Download (`download-assets.sh`)
- ✅ Downloads Google Sans Flex font family (variable + individual weights)
- ✅ Downloads Chart.js library for data visualization
- ✅ Downloads Material Symbols icon fonts
- ✅ Generates local CSS files for font/icon references
- ✅ Integrity verification with file size checks
- ✅ Error handling and detailed logging
- ✅ Follows Google code style guidelines

### Build System (`build.sh`)
- ✅ CSS minification and optimization
- ✅ JavaScript minification and bundling
- ✅ Gzip compression for better performance
- ✅ HTML reference updates for minified assets
- ✅ Build reports with asset sizes
- ✅ Version metadata generation
- ✅ Development and production build modes

### Asset Verification (`verify-assets.sh`)
- ✅ File existence and size validation
- ✅ WOFF2 format verification
- ✅ CSS reference checking
- ✅ Asset inventory generation (JSON)
- ✅ Comprehensive error reporting
- ✅ Individual asset type verification

### Local Server (`serve-local.sh`)
- ✅ Multi-server support (Python, Node.js, PHP, BusyBox)
- ✅ Configurable host and port
- ✅ Asset verification before serving
- ✅ Network interface information
- ✅ Automatic server detection

### Master Setup (`setup-build.sh`)
- ✅ Complete workflow orchestration
- ✅ Flexible build configuration
- ✅ System requirements checking
- ✅ Build summary and reporting
- ✅ Optional development server startup

## Key Requirements Met

### Local Asset Bundling ✅
- Google Sans Flex fonts downloaded and bundled locally
- Chart.js library bundled locally for data visualization
- Material Symbols icon fonts downloaded locally
- No CDN dependencies during operation

### Build System ✅
- CSS/JS minification and optimization
- Asset verification and integrity checking
- Local serving configuration
- Production and development build modes

### Google Code Style Guidelines ✅
- Consistent bash scripting style
- Proper error handling and logging
- Comprehensive documentation
- Modular script organization

### Offline Operation ✅
- All assets work without internet connectivity
- Local font and icon CSS generation
- Bundled JavaScript libraries
- Complete asset verification

## Integration

### OpenWrt Makefile
The build system is integrated into the OpenWrt package build process:

```makefile
define Build/Compile
	cd $(PKG_BUILD_DIR) && ./scripts/download-assets.sh
	cd $(PKG_BUILD_DIR) && ./scripts/verify-assets.sh
	cd $(PKG_BUILD_DIR) && ./scripts/build.sh production
endef
```

### Package Dependencies
- `+curl` - For asset downloading
- `+coreutils-stat` - For file size verification
- Standard shell utilities (grep, sed, find)

## Output Files

### Generated Assets
- `fonts/google-sans-flex/` - Local font files and CSS
- `icons/material-symbols/` - Local icon files and CSS
- `js/lib/chart.min.js` - Local Chart.js library

### Build Artifacts
- `build/` - Intermediate build files
- `dist/` - Final distribution files
- `asset-inventory.json` - Asset inventory
- `build-report.txt` - Build report
- `version.json` - Build metadata

## Usage Examples

### Development Workflow
```bash
# Initial setup
./setup-build.sh --clean --download-assets --verify

# Make changes to source files
# ...

# Rebuild and test
./build.sh development
./serve-local.sh -p 8080
```

### Production Deployment
```bash
# Build production version
./setup-build.sh --build-type production

# Deploy dist/ directory or use OpenWrt package system
```

### Asset Management
```bash
# Download fresh assets
./download-assets.sh

# Verify current assets
./verify-assets.sh

# Generate asset inventory
./verify-assets.sh inventory
```

## Troubleshooting

### Common Issues

**Asset download fails:**
```bash
# Check network connectivity
curl -I https://fonts.googleapis.com

# Retry download
./download-assets.sh
```

**Build fails:**
```bash
# Clean and rebuild
./build.sh clean
./setup-build.sh --clean --download-assets
```

**Server won't start:**
```bash
# Check available servers
./serve-local.sh --help

# Try different server
./serve-local.sh -s python3
```

### Verification

**Check asset integrity:**
```bash
./verify-assets.sh full
```

**Check build output:**
```bash
cat build-report.txt
cat asset-inventory.json
```

This build configuration provides a complete solution for local asset bundling that meets all requirements for offline operation, following Google code style guidelines, and ensuring reliable deployment on OpenWrt systems.