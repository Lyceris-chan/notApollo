#!/bin/bash
# Asset verification and integrity checking for notApollo
# Ensures all required assets are present and valid

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Asset directories
readonly FONTS_DIR="$PROJECT_DIR/fonts/google-sans-flex"
readonly ICONS_DIR="$PROJECT_DIR/icons/material-symbols"
readonly JS_DIR="$PROJECT_DIR/js/lib"
readonly CSS_DIR="$PROJECT_DIR/css"

# Expected assets with minimum sizes (bytes)
declare -A REQUIRED_FONTS=(
  ["GoogleSansFlex-Variable.woff2"]=50000
  ["GoogleSansFlex-Regular.woff2"]=20000
  ["GoogleSansFlex-Medium.woff2"]=20000
  ["GoogleSansFlex-Bold.woff2"]=20000
)

declare -A REQUIRED_ICONS=(
  ["material-symbols-outlined.woff2"]=100000
)

declare -A REQUIRED_JS=(
  ["chart.min.js"]=200000
)

declare -A REQUIRED_CSS=(
  ["material3.css"]=5000
  ["app.css"]=3000
)

# Logging functions
log_info() {
  echo "[VERIFY] $*" >&2
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

# Check if file exists and meets minimum size requirement
check_file() {
  local file_path="$1"
  local min_size="$2"
  local file_name
  file_name=$(basename "$file_path")
  
  if [[ ! -f "$file_path" ]]; then
    log_error "Missing: $file_name"
    return 1
  fi
  
  local file_size
  file_size=$(stat -c%s "$file_path" 2>/dev/null || stat -f%z "$file_path" 2>/dev/null || echo "0")
  
  if [[ $file_size -lt $min_size ]]; then
    log_error "Too small: $file_name ($file_size bytes, expected >$min_size bytes)"
    return 1
  fi
  
  log_success "Valid: $file_name ($file_size bytes)"
  return 0
}

# Verify font files
verify_fonts() {
  log_info "Verifying font assets..."
  
  local errors=0
  
  # Check if fonts directory exists
  if [[ ! -d "$FONTS_DIR" ]]; then
    log_error "Fonts directory not found: $FONTS_DIR"
    return 1
  fi
  
  # Check required font files
  for font_file in "${!REQUIRED_FONTS[@]}"; do
    local font_path="$FONTS_DIR/$font_file"
    local min_size="${REQUIRED_FONTS[$font_file]}"
    
    if ! check_file "$font_path" "$min_size"; then
      ((errors++))
    fi
  done
  
  # Check for font CSS
  if [[ -f "$FONTS_DIR/fonts.css" ]]; then
    log_success "Font CSS found: fonts.css"
  else
    log_warning "Font CSS not found: fonts.css (will be generated)"
  fi
  
  # Verify font file headers (basic WOFF2 validation)
  for font_file in "$FONTS_DIR"/*.woff2; do
    if [[ -f "$font_file" ]]; then
      local header
      header=$(hexdump -C "$font_file" | head -1 | cut -d' ' -f2-5)
      if [[ "$header" == "77 4f 46 32" ]]; then  # WOFF2 magic number
        log_success "Valid WOFF2 header: $(basename "$font_file")"
      else
        log_error "Invalid WOFF2 header: $(basename "$font_file")"
        ((errors++))
      fi
    fi
  done
  
  if [[ $errors -eq 0 ]]; then
    log_success "All font assets verified"
  else
    log_error "Font verification failed ($errors errors)"
  fi
  
  return $errors
}

# Verify icon files
verify_icons() {
  log_info "Verifying icon assets..."
  
  local errors=0
  
  # Check if icons directory exists
  if [[ ! -d "$ICONS_DIR" ]]; then
    log_error "Icons directory not found: $ICONS_DIR"
    return 1
  fi
  
  # Check required icon files
  for icon_file in "${!REQUIRED_ICONS[@]}"; do
    local icon_path="$ICONS_DIR/$icon_file"
    local min_size="${REQUIRED_ICONS[$icon_file]}"
    
    if ! check_file "$icon_path" "$min_size"; then
      ((errors++))
    fi
  done
  
  # Check for icon CSS
  if [[ -f "$ICONS_DIR/icons.css" ]]; then
    log_success "Icon CSS found: icons.css"
  else
    log_warning "Icon CSS not found: icons.css (will be generated)"
  fi
  
  # Verify icon file headers (basic WOFF2 validation)
  for icon_file in "$ICONS_DIR"/*.woff2; do
    if [[ -f "$icon_file" ]]; then
      local header
      header=$(hexdump -C "$icon_file" | head -1 | cut -d' ' -f2-5)
      if [[ "$header" == "77 4f 46 32" ]]; then  # WOFF2 magic number
        log_success "Valid WOFF2 header: $(basename "$icon_file")"
      else
        log_error "Invalid WOFF2 header: $(basename "$icon_file")"
        ((errors++))
      fi
    fi
  done
  
  if [[ $errors -eq 0 ]]; then
    log_success "All icon assets verified"
  else
    log_error "Icon verification failed ($errors errors)"
  fi
  
  return $errors
}

# Verify JavaScript files
verify_javascript() {
  log_info "Verifying JavaScript assets..."
  
  local errors=0
  
  # Check if JS directory exists
  if [[ ! -d "$JS_DIR" ]]; then
    log_error "JavaScript directory not found: $JS_DIR"
    return 1
  fi
  
  # Check required JS files
  for js_file in "${!REQUIRED_JS[@]}"; do
    local js_path="$JS_DIR/$js_file"
    local min_size="${REQUIRED_JS[$js_file]}"
    
    if ! check_file "$js_path" "$min_size"; then
      ((errors++))
    fi
  done
  
  # Verify Chart.js specifically
  if [[ -f "$JS_DIR/chart.min.js" ]]; then
    # Check for Chart.js signature
    if grep -q "Chart.js" "$JS_DIR/chart.min.js" 2>/dev/null; then
      log_success "Chart.js signature verified"
    else
      log_warning "Chart.js signature not found (may be heavily minified)"
    fi
    
    # Check for basic JavaScript syntax
    if head -c 1000 "$JS_DIR/chart.min.js" | grep -q "function\|var\|const\|let" 2>/dev/null; then
      log_success "Chart.js contains valid JavaScript"
    else
      log_error "Chart.js does not appear to contain valid JavaScript"
      ((errors++))
    fi
  fi
  
  if [[ $errors -eq 0 ]]; then
    log_success "All JavaScript assets verified"
  else
    log_error "JavaScript verification failed ($errors errors)"
  fi
  
  return $errors
}

# Verify CSS files
verify_css() {
  log_info "Verifying CSS assets..."
  
  local errors=0
  
  # Check if CSS directory exists
  if [[ ! -d "$CSS_DIR" ]]; then
    log_error "CSS directory not found: $CSS_DIR"
    return 1
  fi
  
  # Check required CSS files
  for css_file in "${!REQUIRED_CSS[@]}"; do
    local css_path="$CSS_DIR/$css_file"
    local min_size="${REQUIRED_CSS[$css_file]}"
    
    if ! check_file "$css_path" "$min_size"; then
      ((errors++))
    fi
  done
  
  # Verify CSS syntax (basic check)
  for css_file in "$CSS_DIR"/*.css; do
    if [[ -f "$css_file" ]]; then
      local filename
      filename=$(basename "$css_file")
      
      # Check for basic CSS syntax
      if grep -q "{.*}" "$css_file" 2>/dev/null; then
        log_success "Valid CSS syntax: $filename"
      else
        log_error "Invalid CSS syntax: $filename"
        ((errors++))
      fi
      
      # Check for Material 3 tokens in material3.css
      if [[ "$filename" == "material3.css" ]]; then
        if grep -q "md-sys-color" "$css_file" 2>/dev/null; then
          log_success "Material 3 tokens found in $filename"
        else
          log_error "Material 3 tokens not found in $filename"
          ((errors++))
        fi
      fi
    fi
  done
  
  if [[ $errors -eq 0 ]]; then
    log_success "All CSS assets verified"
  else
    log_error "CSS verification failed ($errors errors)"
  fi
  
  return $errors
}

# Check font references in CSS
verify_font_references() {
  log_info "Verifying font references in CSS..."
  
  local errors=0
  
  # Check if CSS files reference the correct font paths
  for css_file in "$CSS_DIR"/*.css; do
    if [[ -f "$css_file" ]]; then
      local filename
      filename=$(basename "$css_file")
      
      # Check for Google Sans Flex references
      if grep -q "Google Sans Flex" "$css_file" 2>/dev/null; then
        log_success "Google Sans Flex referenced in $filename"
        
        # Check if font paths are correct
        local font_paths
        font_paths=$(grep -o "url([^)]*)" "$css_file" 2>/dev/null | grep -o "[^'\"]*\.woff2" || true)
        
        while IFS= read -r font_path; do
          if [[ -n "$font_path" ]]; then
            # Convert relative path to absolute
            local full_path
            if [[ "$font_path" == ../* ]]; then
              full_path="$PROJECT_DIR/${font_path#../}"
            else
              full_path="$CSS_DIR/$font_path"
            fi
            
            if [[ -f "$full_path" ]]; then
              log_success "Font file exists: $font_path"
            else
              log_error "Font file missing: $font_path"
              ((errors++))
            fi
          fi
        done <<< "$font_paths"
      fi
      
      # Check for Material Symbols references
      if grep -q "Material Symbols" "$css_file" 2>/dev/null; then
        log_success "Material Symbols referenced in $filename"
      fi
    fi
  done
  
  if [[ $errors -eq 0 ]]; then
    log_success "All font references verified"
  else
    log_error "Font reference verification failed ($errors errors)"
  fi
  
  return $errors
}

# Generate asset inventory
generate_inventory() {
  log_info "Generating asset inventory..."
  
  local inventory_file="$PROJECT_DIR/asset-inventory.json"
  
  cat > "$inventory_file" << EOF
{
  "generated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "fonts": {
EOF
  
  # Add font files
  local first_font=true
  for font_file in "$FONTS_DIR"/*.woff2; do
    if [[ -f "$font_file" ]]; then
      local filename
      filename=$(basename "$font_file")
      local file_size
      file_size=$(stat -c%s "$font_file" 2>/dev/null || stat -f%z "$font_file" 2>/dev/null || echo "0")
      
      if [[ "$first_font" == false ]]; then
        echo "," >> "$inventory_file"
      fi
      echo "    \"$filename\": {" >> "$inventory_file"
      echo "      \"size\": $file_size," >> "$inventory_file"
      echo "      \"path\": \"fonts/google-sans-flex/$filename\"" >> "$inventory_file"
      echo -n "    }" >> "$inventory_file"
      first_font=false
    fi
  done
  
  cat >> "$inventory_file" << EOF

  },
  "icons": {
EOF
  
  # Add icon files
  local first_icon=true
  for icon_file in "$ICONS_DIR"/*.woff2; do
    if [[ -f "$icon_file" ]]; then
      local filename
      filename=$(basename "$icon_file")
      local file_size
      file_size=$(stat -c%s "$icon_file" 2>/dev/null || stat -f%z "$icon_file" 2>/dev/null || echo "0")
      
      if [[ "$first_icon" == false ]]; then
        echo "," >> "$inventory_file"
      fi
      echo "    \"$filename\": {" >> "$inventory_file"
      echo "      \"size\": $file_size," >> "$inventory_file"
      echo "      \"path\": \"icons/material-symbols/$filename\"" >> "$inventory_file"
      echo -n "    }" >> "$inventory_file"
      first_icon=false
    fi
  done
  
  cat >> "$inventory_file" << EOF

  },
  "javascript": {
EOF
  
  # Add JS files
  local first_js=true
  for js_file in "$JS_DIR"/*.js; do
    if [[ -f "$js_file" ]]; then
      local filename
      filename=$(basename "$js_file")
      local file_size
      file_size=$(stat -c%s "$js_file" 2>/dev/null || stat -f%z "$js_file" 2>/dev/null || echo "0")
      
      if [[ "$first_js" == false ]]; then
        echo "," >> "$inventory_file"
      fi
      echo "    \"$filename\": {" >> "$inventory_file"
      echo "      \"size\": $file_size," >> "$inventory_file"
      echo "      \"path\": \"js/lib/$filename\"" >> "$inventory_file"
      echo -n "    }" >> "$inventory_file"
      first_js=false
    fi
  done
  
  cat >> "$inventory_file" << EOF

  }
}
EOF
  
  log_success "Asset inventory generated: $inventory_file"
}

# Main verification function
main() {
  local mode="${1:-full}"
  local total_errors=0
  
  log_info "=== notApollo Asset Verification ==="
  log_info "Mode: $mode"
  
  case "$mode" in
    "fonts")
      verify_fonts || ((total_errors++))
      ;;
    "icons")
      verify_icons || ((total_errors++))
      ;;
    "js"|"javascript")
      verify_javascript || ((total_errors++))
      ;;
    "css")
      verify_css || ((total_errors++))
      ;;
    "references")
      verify_font_references || ((total_errors++))
      ;;
    "inventory")
      generate_inventory
      ;;
    "full"|"")
      verify_fonts || ((total_errors++))
      verify_icons || ((total_errors++))
      verify_javascript || ((total_errors++))
      verify_css || ((total_errors++))
      verify_font_references || ((total_errors++))
      generate_inventory
      ;;
    *)
      echo "Usage: $0 [full|fonts|icons|js|css|references|inventory]"
      echo "  full        - Verify all assets (default)"
      echo "  fonts       - Verify font files only"
      echo "  icons       - Verify icon files only"
      echo "  js          - Verify JavaScript files only"
      echo "  css         - Verify CSS files only"
      echo "  references  - Verify font references in CSS"
      echo "  inventory   - Generate asset inventory JSON"
      exit 1
      ;;
  esac
  
  if [[ $total_errors -eq 0 ]]; then
    log_success "=== Asset Verification Complete ==="
    log_success "All assets verified successfully"
  else
    log_error "=== Asset Verification Failed ==="
    log_error "Total errors: $total_errors"
    exit 1
  fi
}

# Run main function
main "$@"