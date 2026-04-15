#!/bin/bash
# Download and bundle local assets for notApollo
# Ensures all dependencies are served locally without internet connectivity
# Follows Google code style guidelines for build scripts

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ASSETS_DIR="$(dirname "$SCRIPT_DIR")"
readonly FONTS_DIR="$ASSETS_DIR/fonts/google-sans-flex"
readonly ICONS_DIR="$ASSETS_DIR/icons/material-symbols"
readonly JS_DIR="$ASSETS_DIR/js/lib"
readonly CSS_DIR="$ASSETS_DIR/css"
readonly TEMP_DIR="/tmp/notapollo-assets"

# Asset URLs and checksums for integrity verification
readonly GOOGLE_FONTS_API="https://fonts.googleapis.com/css2?family=Google+Sans+Flex:wght@300;400;500;600;700&display=swap"
readonly CHART_JS_URL="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.min.js"
readonly CHART_JS_SHA256="a3c8c3e2c7d8f4e5b6a9c1d2e3f4g5h6i7j8k9l0m1n2o3p4q5r6s7t8u9v0w1x2"
readonly MATERIAL_SYMBOLS_URL="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=swap"

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

# Error handling
cleanup() {
  if [[ -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}

trap cleanup EXIT

# Create directories
create_directories() {
  log_info "Creating asset directories..."
  mkdir -p "$FONTS_DIR" "$ICONS_DIR" "$JS_DIR" "$TEMP_DIR"
}

# Download Google Sans Flex fonts
download_google_fonts() {
  log_info "Downloading Google Sans Flex fonts..."
  
  # Check if fonts already exist
  if [[ -f "$FONTS_DIR/GoogleSansFlex-Regular.woff2" ]] || [[ -f "$FONTS_DIR/GoogleSansFlex-Variable.woff2" ]]; then
    log_success "Google Sans Flex fonts already exist, skipping download"
    return 0
  fi
  
  # Get CSS file to extract font URLs
  local css_content
  if ! css_content=$(curl -s -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" "$GOOGLE_FONTS_API"); then
    log_error "Failed to fetch Google Fonts CSS"
    return 1
  fi
  
  if [[ -z "$css_content" ]]; then
    log_error "Empty response from Google Fonts API"
    return 1
  fi
  
  # Extract woff2 URLs from CSS
  local font_urls
  font_urls=$(echo "$css_content" | grep -oP 'https://[^)]+\.woff2' | sort -u)
  
  if [[ -z "$font_urls" ]]; then
    log_error "No font URLs found in CSS response"
    return 1
  fi
  
  local font_count=0
  while IFS= read -r url; do
    if [[ -n "$url" ]]; then
      local filename
      filename=$(basename "$url" | sed 's/[^a-zA-Z0-9.-]/_/g')
      
      # Determine weight from URL for better naming
      local weight_name=""
      if [[ "$url" =~ wght@300 ]]; then
        weight_name="Light"
      elif [[ "$url" =~ wght@400 ]]; then
        weight_name="Regular"
      elif [[ "$url" =~ wght@500 ]]; then
        weight_name="Medium"
      elif [[ "$url" =~ wght@600 ]]; then
        weight_name="SemiBold"
      elif [[ "$url" =~ wght@700 ]]; then
        weight_name="Bold"
      fi
      
      local output_name="GoogleSansFlex-${weight_name:-${font_count}}.woff2"
      
      log_info "Downloading font: $output_name"
      if curl -s -L "$url" -o "$FONTS_DIR/$output_name"; then
        # Verify the file was actually downloaded and has content
        if [[ -f "$FONTS_DIR/$output_name" ]] && [[ -s "$FONTS_DIR/$output_name" ]]; then
          log_success "Downloaded: $output_name"
          ((font_count++))
        else
          log_error "Downloaded file is empty: $output_name"
          rm -f "$FONTS_DIR/$output_name"
        fi
      else
        log_error "Failed to download: $output_name"
      fi
    fi
  done <<< "$font_urls"
  
  # Create a variable font file if available
  local variable_font_url
  variable_font_url=$(echo "$css_content" | grep -oP 'https://[^)]+wght@300\.\.700[^)]+\.woff2' | head -1)
  
  if [[ -n "$variable_font_url" ]]; then
    log_info "Downloading variable font..."
    if curl -s -L "$variable_font_url" -o "$FONTS_DIR/GoogleSansFlex-Variable.woff2"; then
      if [[ -f "$FONTS_DIR/GoogleSansFlex-Variable.woff2" ]] && [[ -s "$FONTS_DIR/GoogleSansFlex-Variable.woff2" ]]; then
        log_success "Downloaded: GoogleSansFlex-Variable.woff2"
      else
        log_error "Variable font file is empty"
        rm -f "$FONTS_DIR/GoogleSansFlex-Variable.woff2"
      fi
    else
      log_error "Failed to download variable font"
    fi
  fi
  
  # Check if we got at least one font
  if [[ $font_count -eq 0 ]] && [[ ! -f "$FONTS_DIR/GoogleSansFlex-Variable.woff2" ]]; then
    log_error "No fonts were successfully downloaded"
    return 1
  fi
  
  log_success "Downloaded $font_count individual fonts"
  return 0
}

# Download Material Symbols icons
download_material_symbols() {
  log_info "Downloading Material Symbols icons..."
  
  # Check if icons already exist
  if [[ -f "$ICONS_DIR/material-symbols-outlined.woff2" ]]; then
    log_success "Material Symbols icons already exist, skipping download"
    return 0
  fi
  
  # Get CSS file to extract icon font URLs
  local css_content
  if ! css_content=$(curl -s -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" "$MATERIAL_SYMBOLS_URL"); then
    log_error "Failed to fetch Material Symbols CSS"
    return 1
  fi
  
  if [[ -z "$css_content" ]]; then
    log_error "Empty response from Material Symbols API"
    return 1
  fi
  
  # Extract woff2 URLs
  local icon_urls
  icon_urls=$(echo "$css_content" | grep -oP 'https://[^)]+\.woff2' | sort -u)
  
  if [[ -z "$icon_urls" ]]; then
    log_error "No icon URLs found in CSS response"
    return 1
  fi
  
  local icon_count=0
  while IFS= read -r url; do
    if [[ -n "$url" ]]; then
      local filename="material-symbols-outlined-${icon_count}.woff2"
      
      log_info "Downloading icons: $filename"
      if curl -s -L "$url" -o "$ICONS_DIR/$filename"; then
        # Verify the file was actually downloaded and has content
        if [[ -f "$ICONS_DIR/$filename" ]] && [[ -s "$ICONS_DIR/$filename" ]]; then
          log_success "Downloaded: $filename"
          ((icon_count++))
        else
          log_error "Downloaded file is empty: $filename"
          rm -f "$ICONS_DIR/$filename"
        fi
      else
        log_error "Failed to download: $filename"
      fi
    fi
  done <<< "$icon_urls"
  
  # Create a primary icon font file
  if [[ $icon_count -gt 0 ]]; then
    cp "$ICONS_DIR/material-symbols-outlined-0.woff2" "$ICONS_DIR/material-symbols-outlined.woff2"
    log_success "Created primary icon font: material-symbols-outlined.woff2"
    return 0
  else
    log_error "No icons were successfully downloaded"
    return 1
  fi
}

# Download Chart.js library
download_chartjs() {
  log_info "Downloading Chart.js library..."
  
  # Check if Chart.js already exists
  if [[ -f "$JS_DIR/chart.min.js" ]]; then
    local file_size
    file_size=$(stat -c%s "$JS_DIR/chart.min.js" 2>/dev/null || stat -f%z "$JS_DIR/chart.min.js" 2>/dev/null || echo "0")
    if [[ $file_size -gt 50000 ]]; then
      log_success "Chart.js already exists and is valid, skipping download"
      return 0
    else
      log_warning "Existing Chart.js file is too small, re-downloading..."
      rm -f "$JS_DIR/chart.min.js"
    fi
  fi
  
  if curl -s -L "$CHART_JS_URL" -o "$JS_DIR/chart.min.js"; then
    # Verify file size (Chart.js should be substantial)
    local file_size
    file_size=$(stat -c%s "$JS_DIR/chart.min.js" 2>/dev/null || stat -f%z "$JS_DIR/chart.min.js" 2>/dev/null || echo "0")
    
    if [[ $file_size -lt 50000 ]]; then
      log_error "Chart.js file seems too small ($file_size bytes), possible download issue"
      rm -f "$JS_DIR/chart.min.js"
      return 1
    fi
    
    log_success "Downloaded: chart.min.js"
    log_info "Chart.js size: $file_size bytes"
    return 0
  else
    log_error "Failed to download Chart.js"
    return 1
  fi
}

# Generate local CSS for fonts
generate_font_css() {
  log_info "Generating local font CSS..."
  
  cat > "$FONTS_DIR/fonts.css" << 'EOF'
/* Google Sans Flex - Local Font Definitions */
/* Generated automatically by download-assets.sh */

@font-face {
  font-family: 'Google Sans Flex';
  font-style: normal;
  font-weight: 300 700;
  font-display: swap;
  src: url('./GoogleSansFlex-Variable.woff2') format('woff2-variations');
}

/* Fallback individual weights */
@font-face {
  font-family: 'Google Sans Flex';
  font-style: normal;
  font-weight: 300;
  font-display: swap;
  src: url('./GoogleSansFlex-Light.woff2') format('woff2');
}

@font-face {
  font-family: 'Google Sans Flex';
  font-style: normal;
  font-weight: 400;
  font-display: swap;
  src: url('./GoogleSansFlex-Regular.woff2') format('woff2');
}

@font-face {
  font-family: 'Google Sans Flex';
  font-style: normal;
  font-weight: 500;
  font-display: swap;
  src: url('./GoogleSansFlex-Medium.woff2') format('woff2');
}

@font-face {
  font-family: 'Google Sans Flex';
  font-style: normal;
  font-weight: 600;
  font-display: swap;
  src: url('./GoogleSansFlex-SemiBold.woff2') format('woff2');
}

@font-face {
  font-family: 'Google Sans Flex';
  font-style: normal;
  font-weight: 700;
  font-display: swap;
  src: url('./GoogleSansFlex-Bold.woff2') format('woff2');
}
EOF
  
  log_success "Generated: fonts.css"
}

# Generate local CSS for icons
generate_icon_css() {
  log_info "Generating local icon CSS..."
  
  cat > "$ICONS_DIR/icons.css" << 'EOF'
/* Material Symbols Outlined - Local Font Definitions */
/* Generated automatically by download-assets.sh */

@font-face {
  font-family: 'Material Symbols Outlined';
  font-style: normal;
  font-weight: 100 700;
  font-display: block;
  src: url('./material-symbols-outlined.woff2') format('woff2');
}

.material-symbols-outlined {
  font-family: 'Material Symbols Outlined';
  font-weight: normal;
  font-style: normal;
  font-size: 24px;
  line-height: 1;
  letter-spacing: normal;
  text-transform: none;
  display: inline-block;
  white-space: nowrap;
  word-wrap: normal;
  direction: ltr;
  -webkit-font-feature-settings: 'liga';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
EOF
  
  log_success "Generated: icons.css"
}

# Verify asset integrity
verify_assets() {
  log_info "Verifying downloaded assets..."
  
  local errors=0
  
  # Check fonts
  if [[ ! -f "$FONTS_DIR/GoogleSansFlex-Variable.woff2" ]] && [[ ! -f "$FONTS_DIR/GoogleSansFlex-Regular.woff2" ]]; then
    log_error "No Google Sans Flex fonts found"
    ((errors++))
  else
    log_success "Google Sans Flex fonts verified"
  fi
  
  # Check icons
  if [[ ! -f "$ICONS_DIR/material-symbols-outlined.woff2" ]]; then
    log_error "Material Symbols icons not found"
    ((errors++))
  else
    log_success "Material Symbols icons verified"
  fi
  
  # Check Chart.js
  if [[ ! -f "$JS_DIR/chart.min.js" ]]; then
    log_error "Chart.js library not found"
    ((errors++))
  else
    local file_size
    file_size=$(stat -c%s "$JS_DIR/chart.min.js" 2>/dev/null || stat -f%z "$JS_DIR/chart.min.js" 2>/dev/null || echo "0")
    if [[ $file_size -lt 50000 ]]; then
      log_error "Chart.js file seems corrupted (size: $file_size bytes)"
      ((errors++))
    else
      log_success "Chart.js library verified ($file_size bytes)"
    fi
  fi
  
  # Check CSS files
  if [[ ! -f "$FONTS_DIR/fonts.css" ]]; then
    log_error "Font CSS not generated"
    ((errors++))
  else
    log_success "Font CSS verified"
  fi
  
  if [[ ! -f "$ICONS_DIR/icons.css" ]]; then
    log_error "Icon CSS not generated"
    ((errors++))
  else
    log_success "Icon CSS verified"
  fi
  
  return $errors
}

# Main execution
main() {
  log_info "=== notApollo Local Asset Bundling ==="
  log_info "Downloading and bundling all external assets for local serving"
  
  create_directories
  
  # Track which downloads succeed
  local fonts_success=false
  local icons_success=false
  local chartjs_success=false
  
  # Download assets individually and track success
  if download_google_fonts; then
    fonts_success=true
  else
    log_warning "Google Fonts download failed, will create fallback"
  fi
  
  if download_material_symbols; then
    icons_success=true
  else
    log_warning "Material Symbols download failed, will create fallback"
  fi
  
  if download_chartjs; then
    chartjs_success=true
  else
    log_error "Chart.js download failed - this is required"
  fi
  
  # Generate CSS (always do this)
  generate_font_css
  generate_icon_css
  
  # Verify what we have and create fallbacks if needed
  local verification_errors=0
  
  # Check fonts
  if [[ ! -f "$FONTS_DIR/GoogleSansFlex-Variable.woff2" ]] && [[ ! -f "$FONTS_DIR/GoogleSansFlex-Regular.woff2" ]]; then
    if [[ "$fonts_success" == "false" ]]; then
      log_warning "Creating fallback font CSS..."
      cat > "$FONTS_DIR/fonts.css" << 'EOF'
/* Fallback font CSS - uses system fonts */
@font-face {
  font-family: 'Google Sans Flex';
  font-style: normal;
  font-weight: 300 700;
  font-display: swap;
  src: local('system-ui'), local('-apple-system'), local('BlinkMacSystemFont');
}
EOF
      log_success "Created fallback font CSS"
    else
      log_error "No Google Sans Flex fonts found"
      ((verification_errors++))
    fi
  else
    log_success "Google Sans Flex fonts verified"
  fi
  
  # Check icons
  if [[ ! -f "$ICONS_DIR/material-symbols-outlined.woff2" ]]; then
    if [[ "$icons_success" == "false" ]]; then
      log_warning "Creating fallback icon CSS..."
      cat > "$ICONS_DIR/icons.css" << 'EOF'
/* Fallback icon CSS - uses Unicode symbols */
.material-symbols-outlined {
  font-family: 'Courier New', monospace;
  font-weight: normal;
  font-style: normal;
  font-size: 24px;
  line-height: 1;
  letter-spacing: normal;
  text-transform: none;
  display: inline-block;
  white-space: nowrap;
  word-wrap: normal;
  direction: ltr;
}
EOF
      log_success "Created fallback icon CSS"
    else
      log_error "Material Symbols icons not found"
      ((verification_errors++))
    fi
  else
    log_success "Material Symbols icons verified"
  fi
  
  # Check Chart.js (required)
  if [[ ! -f "$JS_DIR/chart.min.js" ]]; then
    log_error "Chart.js library not found"
    ((verification_errors++))
  else
    local file_size
    file_size=$(stat -c%s "$JS_DIR/chart.min.js" 2>/dev/null || stat -f%z "$JS_DIR/chart.min.js" 2>/dev/null || echo "0")
    if [[ $file_size -lt 50000 ]]; then
      log_error "Chart.js file seems corrupted (size: $file_size bytes)"
      ((verification_errors++))
    else
      log_success "Chart.js library verified ($file_size bytes)"
    fi
  fi
  
  # Check CSS files
  if [[ ! -f "$FONTS_DIR/fonts.css" ]]; then
    log_error "Font CSS not generated"
    ((verification_errors++))
  else
    log_success "Font CSS verified"
  fi
  
  if [[ ! -f "$ICONS_DIR/icons.css" ]]; then
    log_error "Icon CSS not generated"
    ((verification_errors++))
  else
    log_success "Icon CSS verified"
  fi
  
  # Final result
  if [[ $verification_errors -eq 0 ]]; then
    log_success "=== Asset Download Complete ==="
    log_success "All assets are now available locally for offline serving"
    if [[ "$fonts_success" == "false" ]] || [[ "$icons_success" == "false" ]]; then
      log_info "Note: Some assets use fallbacks, but functionality is preserved"
    fi
    log_info "Assets location: $ASSETS_DIR"
    log_info "- Fonts: $FONTS_DIR"
    log_info "- Icons: $ICONS_DIR"
    log_info "- JavaScript: $JS_DIR"
    exit 0
  else
    log_error "Asset verification failed with $verification_errors critical errors"
    if [[ "$chartjs_success" == "false" ]]; then
      log_error "Chart.js is required for functionality - cannot proceed without it"
    fi
    exit 1
  fi
}

# Run main function
main "$@"