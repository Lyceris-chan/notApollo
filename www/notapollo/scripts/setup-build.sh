#!/bin/bash
# Master build setup script for notApollo
# Downloads assets, builds, and verifies the complete application

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Build options
DOWNLOAD_ASSETS=true
BUILD_TYPE="production"
VERIFY_ASSETS=true
RUN_SERVER=false
CLEAN_FIRST=false

# Logging functions
log_info() {
  echo "[SETUP] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}

log_success() {
  echo "[SUCCESS] $*" >&2
}

# Show usage information
show_usage() {
  cat << EOF
notApollo Build Setup Script

Usage: $0 [OPTIONS]

Options:
  --download-assets     Download external assets (default: true)
  --no-download         Skip asset download
  --build-type TYPE     Build type: production|development (default: production)
  --verify              Verify assets after download (default: true)
  --no-verify           Skip asset verification
  --serve               Start local development server after build
  --clean               Clean build directories before starting
  --help                Show this help message

Build Types:
  production            Minified CSS/JS with compression
  development           Unminified assets for debugging

Examples:
  $0                                    # Full production build
  $0 --build-type development --serve   # Development build with server
  $0 --no-download --verify             # Skip download, verify only
  $0 --clean --download-assets          # Clean build with fresh assets

EOF
}

# Parse command line arguments
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --download-assets)
        DOWNLOAD_ASSETS=true
        shift
        ;;
      --no-download)
        DOWNLOAD_ASSETS=false
        shift
        ;;
      --build-type)
        BUILD_TYPE="$2"
        shift 2
        ;;
      --verify)
        VERIFY_ASSETS=true
        shift
        ;;
      --no-verify)
        VERIFY_ASSETS=false
        shift
        ;;
      --serve)
        RUN_SERVER=true
        shift
        ;;
      --clean)
        CLEAN_FIRST=true
        shift
        ;;
      --help)
        show_usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done
  
  # Validate build type
  if [[ "$BUILD_TYPE" != "production" && "$BUILD_TYPE" != "development" ]]; then
    log_error "Invalid build type: $BUILD_TYPE"
    log_error "Valid types: production, development"
    exit 1
  fi
}

# Clean build directories
clean_build_dirs() {
  log_info "Cleaning build directories..."
  
  if [[ -f "$SCRIPT_DIR/build.sh" ]]; then
    "$SCRIPT_DIR/build.sh" clean
  else
    # Manual cleanup
    rm -rf "$PROJECT_DIR/build" "$PROJECT_DIR/dist"
    log_success "Build directories cleaned"
  fi
}

# Download external assets
download_assets() {
  log_info "Downloading external assets..."
  
  # Check if smart retry script exists, use it if available
  if [[ -f "$SCRIPT_DIR/smart-retry-assets.sh" ]]; then
    log_info "Using smart retry asset download..."
    chmod +x "$SCRIPT_DIR/smart-retry-assets.sh"
    
    if "$SCRIPT_DIR/smart-retry-assets.sh"; then
      log_success "Smart asset download completed"
    else
      log_error "Smart asset download failed"
      return 1
    fi
  elif [[ -f "$SCRIPT_DIR/download-assets.sh" ]]; then
    log_info "Using standard asset download..."
    chmod +x "$SCRIPT_DIR/download-assets.sh"
    
    if "$SCRIPT_DIR/download-assets.sh"; then
      log_success "Asset download completed"
    else
      log_error "Asset download failed"
      return 1
    fi
  else
    log_error "No asset download script found"
    return 1
  fi
}

# Verify downloaded assets
verify_assets() {
  log_info "Verifying assets..."
  
  if [[ ! -f "$SCRIPT_DIR/verify-assets.sh" ]]; then
    log_error "Asset verification script not found: $SCRIPT_DIR/verify-assets.sh"
    return 1
  fi
  
  # Make script executable
  chmod +x "$SCRIPT_DIR/verify-assets.sh"
  
  # Run asset verification
  if "$SCRIPT_DIR/verify-assets.sh"; then
    log_success "Asset verification passed"
  else
    log_error "Asset verification failed"
    return 1
  fi
}

# Build the application
build_application() {
  log_info "Building application (type: $BUILD_TYPE)..."
  
  if [[ ! -f "$SCRIPT_DIR/build.sh" ]]; then
    log_error "Build script not found: $SCRIPT_DIR/build.sh"
    return 1
  fi
  
  # Make script executable
  chmod +x "$SCRIPT_DIR/build.sh"
  
  # Run build
  if "$SCRIPT_DIR/build.sh" "$BUILD_TYPE"; then
    log_success "Application build completed"
  else
    log_error "Application build failed"
    return 1
  fi
}

# Start development server
start_server() {
  log_info "Starting local development server..."
  
  if [[ ! -f "$SCRIPT_DIR/serve-local.sh" ]]; then
    log_error "Server script not found: $SCRIPT_DIR/serve-local.sh"
    return 1
  fi
  
  # Make script executable
  chmod +x "$SCRIPT_DIR/serve-local.sh"
  
  # Start server (this will block)
  "$SCRIPT_DIR/serve-local.sh"
}

# Check system requirements
check_requirements() {
  log_info "Checking system requirements..."
  
  local missing_tools=()
  
  # Check for basic tools
  command -v curl >/dev/null 2>&1 || missing_tools+=("curl")
  command -v grep >/dev/null 2>&1 || missing_tools+=("grep")
  command -v sed >/dev/null 2>&1 || missing_tools+=("sed")
  command -v find >/dev/null 2>&1 || missing_tools+=("find")
  
  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Missing required tools: ${missing_tools[*]}"
    log_error "Please install the missing tools and try again"
    return 1
  fi
  
  # Check for optional tools
  local optional_tools=()
  command -v node >/dev/null 2>&1 || optional_tools+=("node")
  command -v python3 >/dev/null 2>&1 || optional_tools+=("python3")
  command -v gzip >/dev/null 2>&1 || optional_tools+=("gzip")
  
  if [[ ${#optional_tools[@]} -gt 0 ]]; then
    log_info "Optional tools not found: ${optional_tools[*]}"
    log_info "Build will use fallback methods"
  fi
  
  log_success "System requirements check passed"
}

# Show build summary
show_summary() {
  log_info "=== Build Summary ==="
  log_info "Build Type: $BUILD_TYPE"
  log_info "Assets Downloaded: $DOWNLOAD_ASSETS"
  log_info "Assets Verified: $VERIFY_ASSETS"
  log_info "Server Started: $RUN_SERVER"
  
  # Show file sizes if dist directory exists
  if [[ -d "$PROJECT_DIR/dist" ]]; then
    log_info ""
    log_info "Distribution files:"
    
    # CSS files
    if [[ -f "$PROJECT_DIR/dist/css/app.min.css" ]]; then
      local css_size
      css_size=$(stat -c%s "$PROJECT_DIR/dist/css/app.min.css" 2>/dev/null || stat -f%z "$PROJECT_DIR/dist/css/app.min.css" 2>/dev/null || echo "0")
      log_info "  CSS (minified): $css_size bytes"
    fi
    
    # JS files
    if [[ -f "$PROJECT_DIR/dist/js/app.min.js" ]]; then
      local js_size
      js_size=$(stat -c%s "$PROJECT_DIR/dist/js/app.min.js" 2>/dev/null || stat -f%z "$PROJECT_DIR/dist/js/app.min.js" 2>/dev/null || echo "0")
      log_info "  JS (minified): $js_size bytes"
    fi
    
    # Chart.js
    if [[ -f "$PROJECT_DIR/dist/js/chart.min.js" ]]; then
      local chart_size
      chart_size=$(stat -c%s "$PROJECT_DIR/dist/js/chart.min.js" 2>/dev/null || stat -f%z "$PROJECT_DIR/dist/js/chart.min.js" 2>/dev/null || echo "0")
      log_info "  Chart.js: $chart_size bytes"
    fi
    
    # Total size
    local total_size
    total_size=$(du -sb "$PROJECT_DIR/dist" 2>/dev/null | cut -f1 || echo "0")
    log_info "  Total: $total_size bytes"
  fi
  
  log_info ""
  log_success "Build setup completed successfully!"
  
  if [[ "$RUN_SERVER" == false ]]; then
    log_info "To start the development server, run:"
    log_info "  $SCRIPT_DIR/serve-local.sh"
  fi
}

# Main execution function
main() {
  parse_arguments "$@"
  
  log_info "=== notApollo Build Setup ==="
  log_info "Starting build process..."
  
  # Check system requirements
  check_requirements || exit 1
  
  # Clean if requested
  if [[ "$CLEAN_FIRST" == true ]]; then
    clean_build_dirs || exit 1
  fi
  
  # Download assets if requested
  if [[ "$DOWNLOAD_ASSETS" == true ]]; then
    download_assets || exit 1
  fi
  
  # Verify assets if requested
  if [[ "$VERIFY_ASSETS" == true ]]; then
    verify_assets || exit 1
  fi
  
  # Build application
  build_application || exit 1
  
  # Show summary
  show_summary
  
  # Start server if requested (this will block)
  if [[ "$RUN_SERVER" == true ]]; then
    start_server
  fi
}

# Make all scripts executable
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true

# Run main function
main "$@"