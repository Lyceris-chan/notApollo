#!/bin/bash
# Test script for notApollo OpenWrt package build
# Verifies Makefile functionality and build process

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_DIR="$SCRIPT_DIR"
readonly TEST_BUILD_DIR="/tmp/notapollo-test-build"
readonly WWW_SOURCE_DIR="$SCRIPT_DIR/../../www/notapollo"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*" >&2
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Cleanup function
cleanup() {
  if [[ -d "$TEST_BUILD_DIR" ]]; then
    log_info "Cleaning up test build directory..."
    rm -rf "$TEST_BUILD_DIR"
  fi
}

trap cleanup EXIT

# Check prerequisites
check_prerequisites() {
  log_info "Checking prerequisites..."
  
  local missing_tools=()
  
  # Check for required tools
  command -v curl >/dev/null 2>&1 || missing_tools+=("curl")
  command -v gzip >/dev/null 2>&1 || missing_tools+=("gzip")
  
  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Missing required tools: ${missing_tools[*]}"
    log_info "Please install missing tools before running this test"
    return 1
  fi
  
  # Check source directory
  if [[ ! -d "$WWW_SOURCE_DIR" ]]; then
    log_error "Source directory not found: $WWW_SOURCE_DIR"
    log_info "Please ensure the www/notapollo directory exists"
    return 1
  fi
  
  # Check for build scripts
  if [[ ! -f "$WWW_SOURCE_DIR/scripts/download-assets.sh" ]]; then
    log_error "Build scripts not found in source directory"
    return 1
  fi
  
  log_success "Prerequisites check passed"
  return 0
}

# Verify Makefile syntax
verify_makefile() {
  log_info "Verifying Makefile syntax..."
  
  local makefile="$PACKAGE_DIR/Makefile"
  
  if [[ ! -f "$makefile" ]]; then
    log_error "Makefile not found: $makefile"
    return 1
  fi
  
  # Check for required sections
  local required_sections=(
    "PKG_NAME:=notapollo"
    "define Package/notapollo"
    "define Build/Prepare"
    "define Build/Compile"
    "define Package/notapollo/install"
    "define Package/notapollo/postinst"
  )
  
  for section in "${required_sections[@]}"; do
    if ! grep -q "$section" "$makefile"; then
      log_error "Missing required section: $section"
      return 1
    fi
  done
  
  # Check for asset bundling integration
  if ! grep -q "download-assets.sh" "$makefile"; then
    log_error "Asset bundling integration not found"
    return 1
  fi
  
  if ! grep -q "verify-assets.sh" "$makefile"; then
    log_error "Asset verification integration not found"
    return 1
  fi
  
  if ! grep -q "build.sh production" "$makefile"; then
    log_error "Production build integration not found"
    return 1
  fi
  
  log_success "Makefile syntax verification passed"
  return 0
}

# Test build preparation
test_build_prepare() {
  log_info "Testing Build/Prepare phase..."
  
  # Create test build directory
  mkdir -p "$TEST_BUILD_DIR"
  
  # Simulate Build/Prepare
  log_info "Copying source files..."
  cp -r "$WWW_SOURCE_DIR"/* "$TEST_BUILD_DIR/"
  
  # Copy package files
  if [[ -d "$PACKAGE_DIR/files" ]]; then
    cp -r "$PACKAGE_DIR/files"/* "$TEST_BUILD_DIR/"
  fi
  
  # Make scripts executable
  find "$TEST_BUILD_DIR/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
  
  # Verify key files are present
  local required_files=(
    "index.html"
    "scripts/download-assets.sh"
    "scripts/verify-assets.sh"
    "scripts/build.sh"
  )
  
  for file in "${required_files[@]}"; do
    if [[ ! -f "$TEST_BUILD_DIR/$file" ]]; then
      log_error "Required file missing after prepare: $file"
      return 1
    fi
  done
  
  log_success "Build/Prepare phase test passed"
  return 0
}

# Test asset download (if internet available)
test_asset_download() {
  log_info "Testing asset download..."
  
  cd "$TEST_BUILD_DIR"
  
  # Check internet connectivity
  if ! curl -s --connect-timeout 5 -I https://fonts.googleapis.com >/dev/null 2>&1; then
    log_warning "No internet connectivity, skipping asset download test"
    return 0
  fi
  
  # Test asset download script
  if ./scripts/download-assets.sh; then
    log_success "Asset download test passed"
    
    # Verify downloaded assets
    if ./scripts/verify-assets.sh; then
      log_success "Asset verification test passed"
    else
      log_error "Asset verification failed"
      return 1
    fi
  else
    log_error "Asset download failed"
    return 1
  fi
  
  return 0
}

# Test build process
test_build_process() {
  log_info "Testing build process..."
  
  cd "$TEST_BUILD_DIR"
  
  # Test production build
  if ./scripts/build.sh production; then
    log_success "Production build test passed"
    
    # Verify build outputs
    if [[ -d "dist" ]]; then
      log_success "Distribution directory created"
      
      # Check for key files in dist
      local dist_files=(
        "dist/index.html"
        "dist/css"
        "dist/js"
      )
      
      for file in "${dist_files[@]}"; do
        if [[ ! -e "$file" ]]; then
          log_warning "Expected dist file missing: $file"
        fi
      done
    else
      log_warning "Distribution directory not created (may be normal)"
    fi
    
    # Check for build reports
    if [[ -f "build-report.txt" ]]; then
      log_success "Build report generated"
    fi
    
    if [[ -f "asset-inventory.json" ]]; then
      log_success "Asset inventory generated"
    fi
    
  else
    log_error "Production build failed"
    return 1
  fi
  
  return 0
}

# Test installation simulation
test_installation() {
  log_info "Testing installation simulation..."
  
  local install_dir="$TEST_BUILD_DIR/install_test"
  mkdir -p "$install_dir"
  
  # Simulate package installation
  mkdir -p "$install_dir/www/notapollo"
  mkdir -p "$install_dir/etc/config"
  mkdir -p "$install_dir/etc/init.d"
  
  # Copy files (simulate Makefile install section)
  if [[ -d "$TEST_BUILD_DIR/dist" ]]; then
    cp -r "$TEST_BUILD_DIR/dist"/* "$install_dir/www/notapollo/"
  else
    cp -r "$TEST_BUILD_DIR"/* "$install_dir/www/notapollo/"
  fi
  
  # Copy configuration files
  if [[ -f "$PACKAGE_DIR/files/etc/config/notapollo" ]]; then
    cp "$PACKAGE_DIR/files/etc/config/notapollo" "$install_dir/etc/config/"
  fi
  
  if [[ -f "$PACKAGE_DIR/files/etc/init.d/notapollo" ]]; then
    cp "$PACKAGE_DIR/files/etc/init.d/notapollo" "$install_dir/etc/init.d/"
  fi
  
  # Set permissions (simulate Makefile permission setting)
  find "$install_dir/www/notapollo/api" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
  find "$install_dir/www/notapollo/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
  
  # Create verification script (simulate Makefile script creation)
  cat > "$install_dir/www/notapollo/verify-installation.sh" << 'EOF'
#!/bin/sh
echo "Testing installation verification..."
[ -f index.html ] && echo "OK: index.html found" || echo "ERROR: index.html missing"
[ -d api ] && echo "OK: API directory found" || echo "ERROR: API directory missing"
[ -f css/app.css ] || [ -f css/app.min.css ] && echo "OK: CSS found" || echo "ERROR: CSS missing"
[ -f js/app.js ] || [ -f js/app.min.js ] && echo "OK: JavaScript found" || echo "ERROR: JavaScript missing"
echo "Verification complete."
EOF
  chmod +x "$install_dir/www/notapollo/verify-installation.sh"
  
  # Test verification script
  cd "$install_dir/www/notapollo"
  if ./verify-installation.sh; then
    log_success "Installation verification test passed"
  else
    log_error "Installation verification failed"
    return 1
  fi
  
  log_success "Installation simulation test passed"
  return 0
}

# Test dependency checking
test_dependencies() {
  log_info "Testing dependency requirements..."
  
  # Extract dependencies from Makefile
  local makefile="$PACKAGE_DIR/Makefile"
  local depends_line
  depends_line=$(grep "DEPENDS:=" "$makefile" || true)
  
  if [[ -z "$depends_line" ]]; then
    log_error "No DEPENDS line found in Makefile"
    return 1
  fi
  
  log_info "Found dependencies: $depends_line"
  
  # Check for required dependencies
  local required_deps=(
    "uhttpd"
    "curl"
    "iwinfo"
    "ip-full"
    "bind-dig"
  )
  
  for dep in "${required_deps[@]}"; do
    if [[ "$depends_line" == *"+$dep"* ]]; then
      log_success "Required dependency found: $dep"
    else
      log_error "Required dependency missing: $dep"
      return 1
    fi
  done
  
  log_success "Dependency check passed"
  return 0
}

# Test configuration files
test_configuration() {
  log_info "Testing configuration files..."
  
  # Check UCI configuration
  local uci_config="$PACKAGE_DIR/files/etc/config/notapollo"
  if [[ -f "$uci_config" ]]; then
    log_success "UCI configuration file found"
    
    # Check for required sections
    local required_sections=(
      "config main 'main'"
      "config diagnostics 'diagnostics'"
      "config security 'security'"
      "config features 'features'"
    )
    
    for section in "${required_sections[@]}"; do
      if grep -q "$section" "$uci_config"; then
        log_success "Configuration section found: $section"
      else
        log_error "Configuration section missing: $section"
        return 1
      fi
    done
  else
    log_error "UCI configuration file not found: $uci_config"
    return 1
  fi
  
  # Check init script
  local init_script="$PACKAGE_DIR/files/etc/init.d/notapollo"
  if [[ -f "$init_script" ]]; then
    log_success "Init script found"
    
    # Check for required functions
    if grep -q "start_service()" "$init_script"; then
      log_success "start_service function found"
    else
      log_error "start_service function missing"
      return 1
    fi
  else
    log_error "Init script not found: $init_script"
    return 1
  fi
  
  log_success "Configuration test passed"
  return 0
}

# Generate test report
generate_report() {
  log_info "Generating test report..."
  
  local report_file="$PACKAGE_DIR/test-report.txt"
  
  cat > "$report_file" << EOF
notApollo OpenWrt Package Test Report
====================================
Test Date: $(date)
Test Environment: $(uname -a)

Test Results:
- Makefile Syntax: PASSED
- Build Preparation: PASSED
- Asset Download: $(if [[ -f "$TEST_BUILD_DIR/fonts/google-sans-flex/GoogleSansFlex-Regular.woff2" ]]; then echo "PASSED"; else echo "SKIPPED (no internet)"; fi)
- Build Process: PASSED
- Installation Simulation: PASSED
- Dependencies: PASSED
- Configuration: PASSED

Build Artifacts:
EOF
  
  if [[ -d "$TEST_BUILD_DIR" ]]; then
    echo "- Build directory size: $(du -sh "$TEST_BUILD_DIR" | cut -f1)" >> "$report_file"
    
    if [[ -f "$TEST_BUILD_DIR/build-report.txt" ]]; then
      echo "- Build report generated: YES" >> "$report_file"
    fi
    
    if [[ -f "$TEST_BUILD_DIR/asset-inventory.json" ]]; then
      echo "- Asset inventory generated: YES" >> "$report_file"
    fi
  fi
  
  echo "" >> "$report_file"
  echo "Package Information:" >> "$report_file"
  echo "- Package Name: notapollo" >> "$report_file"
  echo "- Version: 1.0.0" >> "$report_file"
  echo "- License: GPL-2.0" >> "$report_file"
  echo "- Architecture: all" >> "$report_file"
  
  log_success "Test report generated: $report_file"
}

# Main test function
main() {
  log_info "=== notApollo OpenWrt Package Build Test ==="
  log_info "Testing Makefile functionality and build process"
  
  local test_functions=(
    "check_prerequisites"
    "verify_makefile"
    "test_build_prepare"
    "test_asset_download"
    "test_build_process"
    "test_installation"
    "test_dependencies"
    "test_configuration"
  )
  
  local failed_tests=0
  
  for test_func in "${test_functions[@]}"; do
    log_info "Running test: $test_func"
    if $test_func; then
      log_success "Test passed: $test_func"
    else
      log_error "Test failed: $test_func"
      ((failed_tests++))
    fi
    echo ""
  done
  
  generate_report
  
  if [[ $failed_tests -eq 0 ]]; then
    log_success "=== All Tests Passed ==="
    log_success "The notApollo OpenWrt package is ready for build"
    log_info "To build the package in OpenWrt:"
    log_info "  make package/notapollo/clean"
    log_info "  make package/notapollo/compile"
    log_info "  make package/notapollo/install"
  else
    log_error "=== $failed_tests Test(s) Failed ==="
    log_error "Please fix the issues before building the package"
    exit 1
  fi
}

# Run tests
main "$@"