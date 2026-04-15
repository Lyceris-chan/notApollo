#!/bin/bash
# Smart retry wrapper for asset downloads
# Only retries the necessary steps based on what failed

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ASSETS_DIR="$(dirname "$SCRIPT_DIR")"
readonly FONTS_DIR="$ASSETS_DIR/fonts/google-sans-flex"
readonly ICONS_DIR="$ASSETS_DIR/icons/material-symbols"
readonly JS_DIR="$ASSETS_DIR/js/lib"
readonly DOWNLOAD_SCRIPT="$SCRIPT_DIR/download-assets.sh"

# Logging functions
log_info() {
  echo "[INFO] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}

log_success() {
  echo "[SUCCESS] $*" >&2
}

log_warning() {
  echo "[WARNING] $*" >&2
}

# Check what assets are missing or need retry
check_asset_status() {
  local fonts_ok=false
  local icons_ok=false
  local chartjs_ok=false
  
  # Check fonts
  if [[ -f "$FONTS_DIR/GoogleSansFlex-Variable.woff2" ]] || [[ -f "$FONTS_DIR/GoogleSansFlex-Regular.woff2" ]]; then
    fonts_ok=true
    log_success "Google Sans Flex fonts are available (named files)"
  else
    # Check if we have any Google Sans Flex fonts (numbered files)
    local font_count
    font_count=$(find "$FONTS_DIR" -name "GoogleSansFlex-*.woff2" -type f 2>/dev/null | wc -l)
    if [[ $font_count -gt 0 ]]; then
      fonts_ok=true
      log_success "Google Sans Flex fonts are available ($font_count files)"
    fi
  fi
  
  # Check icons
  if [[ -f "$ICONS_DIR/material-symbols-outlined.woff2" ]]; then
    local file_size
    file_size=$(stat -c%s "$ICONS_DIR/material-symbols-outlined.woff2" 2>/dev/null || stat -f%z "$ICONS_DIR/material-symbols-outlined.woff2" 2>/dev/null || echo "0")
    if [[ $file_size -gt 1000 ]]; then
      icons_ok=true
      log_success "Material Symbols icons are available ($file_size bytes)"
    fi
  fi
  
  # Check Chart.js
  if [[ -f "$JS_DIR/chart.min.js" ]]; then
    local file_size
    file_size=$(stat -c%s "$JS_DIR/chart.min.js" 2>/dev/null || stat -f%z "$JS_DIR/chart.min.js" 2>/dev/null || echo "0")
    if [[ $file_size -gt 50000 ]]; then
      chartjs_ok=true
      log_success "Chart.js library is available ($file_size bytes)"
    fi
  fi
  
  echo "$fonts_ok:$icons_ok:$chartjs_ok"
}

# Retry only specific assets
retry_specific_assets() {
  local status="$1"
  IFS=':' read -r fonts_ok icons_ok chartjs_ok <<< "$status"
  
  local retry_needed=false
  local retry_fonts=false
  local retry_icons=false
  local retry_chartjs=false
  
  if [[ "$fonts_ok" == "false" ]]; then
    log_info "Google Sans Flex fonts need retry"
    retry_fonts=true
    retry_needed=true
  fi
  
  if [[ "$icons_ok" == "false" ]]; then
    log_info "Material Symbols icons need retry"
    retry_icons=true
    retry_needed=true
  fi
  
  if [[ "$chartjs_ok" == "false" ]]; then
    log_info "Chart.js library needs retry"
    retry_chartjs=true
    retry_needed=true
  fi
  
  if [[ "$retry_needed" == "false" ]]; then
    log_success "All assets are available, no retry needed"
    return 0
  fi
  
  # Create temporary script with only needed functions
  local temp_script="/tmp/notapollo-selective-retry.sh"
  
  cat > "$temp_script" << 'SCRIPT_START'
#!/bin/bash
set -euo pipefail

# Source the main download script functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$(dirname "$SCRIPT_DIR")"
FONTS_DIR="$ASSETS_DIR/fonts/google-sans-flex"
ICONS_DIR="$ASSETS_DIR/icons/material-symbols"
JS_DIR="$ASSETS_DIR/js/lib"

# Configuration from main script
GOOGLE_FONTS_API="https://fonts.googleapis.com/css2?family=Google+Sans+Flex:wght@300;400;500;600;700&display=swap"
CHART_JS_URL="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.min.js"
MATERIAL_SYMBOLS_URL="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=swap"

# Logging functions
log_info() { echo "[INFO] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }
log_success() { echo "[SUCCESS] $*" >&2; }
log_warning() { echo "[WARNING] $*" >&2; }

# Create directories
mkdir -p "$FONTS_DIR" "$ICONS_DIR" "$JS_DIR"

SCRIPT_START

  # Add only the functions we need
  if [[ "$retry_fonts" == "true" ]]; then
    log_info "Adding Google Fonts retry to selective script"
    # Extract the download_google_fonts function from the main script
    sed -n '/^# Download Google Sans Flex fonts/,/^}/p' "$DOWNLOAD_SCRIPT" >> "$temp_script"
    echo "" >> "$temp_script"
    echo "download_google_fonts" >> "$temp_script"
    echo "" >> "$temp_script"
  fi
  
  if [[ "$retry_icons" == "true" ]]; then
    log_info "Adding Material Symbols retry to selective script"
    # Extract the download_material_symbols function from the main script
    sed -n '/^# Download Material Symbols icons/,/^}/p' "$DOWNLOAD_SCRIPT" >> "$temp_script"
    echo "" >> "$temp_script"
    echo "download_material_symbols" >> "$temp_script"
    echo "" >> "$temp_script"
  fi
  
  if [[ "$retry_chartjs" == "true" ]]; then
    log_info "Adding Chart.js retry to selective script"
    # Extract the download_chartjs function from the main script
    sed -n '/^# Download Chart.js library/,/^}/p' "$DOWNLOAD_SCRIPT" >> "$temp_script"
    echo "" >> "$temp_script"
    echo "download_chartjs" >> "$temp_script"
    echo "" >> "$temp_script"
  fi
  
  # Always regenerate CSS files
  log_info "Adding CSS generation to selective script"
  sed -n '/^# Generate local CSS for fonts/,/^}/p' "$DOWNLOAD_SCRIPT" >> "$temp_script"
  echo "" >> "$temp_script"
  sed -n '/^# Generate local CSS for icons/,/^}/p' "$DOWNLOAD_SCRIPT" >> "$temp_script"
  echo "" >> "$temp_script"
  echo "generate_font_css" >> "$temp_script"
  echo "generate_icon_css" >> "$temp_script"
  
  # Make the script executable and run it
  chmod +x "$temp_script"
  
  log_info "Running selective asset retry..."
  if bash "$temp_script"; then
    log_success "Selective retry completed successfully"
    rm -f "$temp_script"
    return 0
  else
    log_error "Selective retry failed"
    rm -f "$temp_script"
    return 1
  fi
}

# Main execution
main() {
  local max_attempts=3
  local attempt=1
  
  log_info "=== Smart Asset Download Retry ==="
  
  while [[ $attempt -le $max_attempts ]]; do
    log_info "Asset download attempt $attempt/$max_attempts..."
    
    # Check current status
    local status
    status=$(check_asset_status)
    
    # If everything is OK, we're done
    if [[ "$status" == "true:true:true" ]]; then
      log_success "All assets are available!"
      exit 0
    fi
    
    # Try selective retry first if this isn't the first attempt
    if [[ $attempt -gt 1 ]]; then
      log_info "Attempting selective retry for missing assets..."
      if retry_specific_assets "$status"; then
        # Check again after selective retry
        status=$(check_asset_status)
        if [[ "$status" == "true:true:true" ]]; then
          log_success "Selective retry successful - all assets now available!"
          exit 0
        fi
      fi
    fi
    
    # Run full download script
    log_info "Running full asset download script..."
    if bash "$DOWNLOAD_SCRIPT"; then
      log_success "Full download completed successfully"
      exit 0
    else
      log_warning "Asset download failed on attempt $attempt"
      
      if [[ $attempt -lt $max_attempts ]]; then
        log_info "Retrying in 10 seconds..."
        sleep 10
      fi
    fi
    
    ((attempt++))
  done
  
  # Final check and fallback
  local final_status
  final_status=$(check_asset_status)
  IFS=':' read -r fonts_ok icons_ok chartjs_ok <<< "$final_status"
  
  log_error "All download attempts failed"
  
  # Check what we have and provide specific guidance
  if [[ "$chartjs_ok" == "false" ]]; then
    log_error "Chart.js is required for functionality - cannot proceed without it"
    exit 1
  else
    log_warning "Chart.js is available, but some assets may use fallbacks"
    if [[ "$fonts_ok" == "false" ]]; then
      log_warning "Google Fonts will use system font fallbacks"
    fi
    if [[ "$icons_ok" == "false" ]]; then
      log_warning "Material Symbols will use Unicode fallbacks"
    fi
    log_success "Core functionality preserved with available assets"
    exit 0
  fi
}

# Run main function
main "$@"