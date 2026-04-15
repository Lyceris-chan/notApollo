#!/bin/bash
# Build script for notApollo - CSS/JS minification and optimization
# Follows Google code style guidelines for build scripts

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
readonly BUILD_DIR="$PROJECT_DIR/build"
readonly DIST_DIR="$PROJECT_DIR/dist"

# Source directories
readonly CSS_SRC="$PROJECT_DIR/css"
readonly JS_SRC="$PROJECT_DIR/js"
readonly FONTS_SRC="$PROJECT_DIR/fonts"
readonly ICONS_SRC="$PROJECT_DIR/icons"
readonly IMAGES_SRC="$PROJECT_DIR/images"

# Build configuration
readonly ENABLE_MINIFICATION=true
readonly ENABLE_GZIP=true
readonly ENABLE_BROTLI=false  # Not available on most OpenWrt systems

# Logging functions
log_info() {
  echo "[BUILD] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}

log_success() {
  echo "[SUCCESS] $*" >&2
}

# Check dependencies
check_dependencies() {
  local missing_deps=()
  
  # Check for basic tools
  command -v node >/dev/null 2>&1 || missing_deps+=("node")
  command -v gzip >/dev/null 2>&1 || missing_deps+=("gzip")
  
  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log_error "Missing dependencies: ${missing_deps[*]}"
    log_info "Installing minimal CSS/JS minifiers..."
    install_minifiers
  fi
}

# Install minimal minifiers if Node.js is not available
install_minifiers() {
  log_info "Creating simple minification tools..."
  
  # Create simple CSS minifier
  cat > "$SCRIPT_DIR/minify-css.sh" << 'EOF'
#!/bin/bash
# Simple CSS minifier for systems without Node.js
input_file="$1"
output_file="$2"

if [[ -z "$input_file" || -z "$output_file" ]]; then
  echo "Usage: $0 <input.css> <output.css>"
  exit 1
fi

# Basic CSS minification using sed
sed -e 's/\/\*[^*]*\*\///g' \
    -e 's/^[[:space:]]*//g' \
    -e 's/[[:space:]]*$//g' \
    -e '/^$/d' \
    -e 's/[[:space:]]*{[[:space:]]*/{ /g' \
    -e 's/[[:space:]]*}[[:space:]]*/} /g' \
    -e 's/[[:space:]]*;[[:space:]]*/; /g' \
    -e 's/[[:space:]]*:[[:space:]]*/: /g' \
    -e 's/[[:space:]]*,[[:space:]]*/, /g' \
    "$input_file" > "$output_file"
EOF

  # Create simple JS minifier
  cat > "$SCRIPT_DIR/minify-js.sh" << 'EOF'
#!/bin/bash
# Simple JS minifier for systems without Node.js
input_file="$1"
output_file="$2"

if [[ -z "$input_file" || -z "$output_file" ]]; then
  echo "Usage: $0 <input.js> <output.js>"
  exit 1
fi

# Basic JS minification using sed
sed -e 's/\/\/.*$//g' \
    -e 's/\/\*[^*]*\*\///g' \
    -e 's/^[[:space:]]*//g' \
    -e 's/[[:space:]]*$//g' \
    -e '/^$/d' \
    "$input_file" > "$output_file"
EOF

  chmod +x "$SCRIPT_DIR/minify-css.sh" "$SCRIPT_DIR/minify-js.sh"
  log_success "Created simple minification tools"
}

# Clean build directories
clean_build() {
  log_info "Cleaning build directories..."
  rm -rf "$BUILD_DIR" "$DIST_DIR"
  mkdir -p "$BUILD_DIR" "$DIST_DIR"
}

# Copy static assets
copy_assets() {
  log_info "Copying static assets..."
  
  # Copy fonts
  if [[ -d "$FONTS_SRC" ]]; then
    cp -r "$FONTS_SRC" "$BUILD_DIR/"
    log_success "Copied fonts"
  fi
  
  # Copy icons
  if [[ -d "$ICONS_SRC" ]]; then
    cp -r "$ICONS_SRC" "$BUILD_DIR/"
    log_success "Copied icons"
  fi
  
  # Copy images
  if [[ -d "$IMAGES_SRC" ]]; then
    cp -r "$IMAGES_SRC" "$BUILD_DIR/"
    log_success "Copied images"
  fi
  
  # Copy other static files
  for file in "$PROJECT_DIR"/*.html "$PROJECT_DIR"/*.json "$PROJECT_DIR"/*.js; do
    if [[ -f "$file" ]]; then
      cp "$file" "$BUILD_DIR/"
    fi
  done
  
  # Copy API scripts
  if [[ -d "$PROJECT_DIR/api" ]]; then
    cp -r "$PROJECT_DIR/api" "$BUILD_DIR/"
    chmod +x "$BUILD_DIR/api"/*.sh
    log_success "Copied API scripts"
  fi
  
  # Copy config files
  if [[ -d "$PROJECT_DIR/config" ]]; then
    cp -r "$PROJECT_DIR/config" "$BUILD_DIR/"
    log_success "Copied config files"
  fi
}

# Minify CSS files
minify_css() {
  log_info "Minifying CSS files..."
  
  mkdir -p "$BUILD_DIR/css"
  
  local css_files=("$CSS_SRC"/*.css)
  local combined_css="$BUILD_DIR/css/app.min.css"
  
  # Combine and minify CSS
  > "$combined_css"  # Create empty file
  
  for css_file in "${css_files[@]}"; do
    if [[ -f "$css_file" ]]; then
      local filename
      filename=$(basename "$css_file")
      log_info "Processing: $filename"
      
      if [[ "$ENABLE_MINIFICATION" == true ]]; then
        if command -v node >/dev/null 2>&1; then
          # Use Node.js for better minification if available
          node -e "
            const fs = require('fs');
            const css = fs.readFileSync('$css_file', 'utf8');
            const minified = css
              .replace(/\/\*[\s\S]*?\*\//g, '')
              .replace(/\s+/g, ' ')
              .replace(/;\s*}/g, '}')
              .replace(/\s*{\s*/g, '{')
              .replace(/;\s*/g, ';')
              .replace(/:\s*/g, ':')
              .replace(/,\s*/g, ',')
              .trim();
            process.stdout.write(minified);
          " >> "$combined_css"
        else
          # Use simple minifier
          "$SCRIPT_DIR/minify-css.sh" "$css_file" - >> "$combined_css"
        fi
      else
        cat "$css_file" >> "$combined_css"
      fi
      
      echo "" >> "$combined_css"  # Add newline between files
    fi
  done
  
  # Create gzipped version
  if [[ "$ENABLE_GZIP" == true ]]; then
    gzip -9 -c "$combined_css" > "$combined_css.gz"
    log_success "Created gzipped CSS ($(stat -c%s "$combined_css.gz" 2>/dev/null || stat -f%z "$combined_css.gz" 2>/dev/null) bytes)"
  fi
  
  log_success "CSS minification complete ($(stat -c%s "$combined_css" 2>/dev/null || stat -f%z "$combined_css" 2>/dev/null) bytes)"
}

# Minify JavaScript files
minify_js() {
  log_info "Minifying JavaScript files..."
  
  mkdir -p "$BUILD_DIR/js"
  
  # Copy and minify Chart.js library
  if [[ -f "$JS_SRC/lib/chart.min.js" ]]; then
    cp "$JS_SRC/lib/chart.min.js" "$BUILD_DIR/js/"
    log_success "Copied Chart.js library"
  fi
  
  # Combine application JS files
  local js_files=("$JS_SRC"/*.js)
  local combined_js="$BUILD_DIR/js/app.min.js"
  
  > "$combined_js"  # Create empty file
  
  for js_file in "${js_files[@]}"; do
    if [[ -f "$js_file" && "$js_file" != *"/lib/"* ]]; then
      local filename
      filename=$(basename "$js_file")
      log_info "Processing: $filename"
      
      if [[ "$ENABLE_MINIFICATION" == true ]]; then
        if command -v node >/dev/null 2>&1; then
          # Use Node.js for better minification if available
          node -e "
            const fs = require('fs');
            const js = fs.readFileSync('$js_file', 'utf8');
            const minified = js
              .replace(/\/\/.*$/gm, '')
              .replace(/\/\*[\s\S]*?\*\//g, '')
              .replace(/\s+/g, ' ')
              .replace(/;\s*}/g, ';}')
              .replace(/\s*{\s*/g, '{')
              .replace(/;\s*/g, ';')
              .replace(/,\s*/g, ',')
              .trim();
            process.stdout.write(minified);
          " >> "$combined_js"
        else
          # Use simple minifier
          "$SCRIPT_DIR/minify-js.sh" "$js_file" - >> "$combined_js"
        fi
      else
        cat "$js_file" >> "$combined_js"
      fi
      
      echo "" >> "$combined_js"  # Add newline between files
    fi
  done
  
  # Create gzipped version
  if [[ "$ENABLE_GZIP" == true ]]; then
    gzip -9 -c "$combined_js" > "$combined_js.gz"
    log_success "Created gzipped JS ($(stat -c%s "$combined_js.gz" 2>/dev/null || stat -f%z "$combined_js.gz" 2>/dev/null) bytes)"
  fi
  
  log_success "JavaScript minification complete ($(stat -c%s "$combined_js" 2>/dev/null || stat -f%z "$combined_js" 2>/dev/null) bytes)"
}

# Update HTML to use minified assets
update_html() {
  log_info "Updating HTML to use minified assets..."
  
  local html_files=("$BUILD_DIR"/*.html)
  
  for html_file in "${html_files[@]}"; do
    if [[ -f "$html_file" ]]; then
      local filename
      filename=$(basename "$html_file")
      log_info "Updating: $filename"
      
      # Update CSS references
      sed -i.bak 's|css/material3\.css|css/app.min.css|g' "$html_file"
      sed -i.bak 's|css/app\.css||g' "$html_file"
      
      # Update JS references
      sed -i.bak 's|js/app\.js|js/app.min.js|g' "$html_file"
      
      # Remove backup files
      rm -f "$html_file.bak"
      
      log_success "Updated: $filename"
    fi
  done
}

# Create distribution package
create_distribution() {
  log_info "Creating distribution package..."
  
  # Copy build to dist
  cp -r "$BUILD_DIR"/* "$DIST_DIR/"
  
  # Create version info
  cat > "$DIST_DIR/version.json" << EOF
{
  "version": "1.0.0",
  "build_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "build_type": "$(if [[ "$ENABLE_MINIFICATION" == true ]]; then echo "minified"; else echo "development"; fi)",
  "assets": {
    "css_minified": $ENABLE_MINIFICATION,
    "js_minified": $ENABLE_MINIFICATION,
    "gzip_enabled": $ENABLE_GZIP
  }
}
EOF
  
  # Calculate total size
  local total_size
  total_size=$(du -sb "$DIST_DIR" | cut -f1)
  
  log_success "Distribution created: $DIST_DIR"
  log_success "Total size: $total_size bytes"
}

# Generate build report
generate_report() {
  log_info "Generating build report..."
  
  local report_file="$DIST_DIR/build-report.txt"
  
  cat > "$report_file" << EOF
notApollo Build Report
=====================
Build Date: $(date)
Build Type: $(if [[ "$ENABLE_MINIFICATION" == true ]]; then echo "Production (Minified)"; else echo "Development"; fi)

Asset Sizes:
EOF
  
  # CSS sizes
  if [[ -f "$BUILD_DIR/css/app.min.css" ]]; then
    local css_size
    css_size=$(stat -c%s "$BUILD_DIR/css/app.min.css" 2>/dev/null || stat -f%z "$BUILD_DIR/css/app.min.css" 2>/dev/null)
    echo "- CSS (minified): $css_size bytes" >> "$report_file"
    
    if [[ -f "$BUILD_DIR/css/app.min.css.gz" ]]; then
      local css_gz_size
      css_gz_size=$(stat -c%s "$BUILD_DIR/css/app.min.css.gz" 2>/dev/null || stat -f%z "$BUILD_DIR/css/app.min.css.gz" 2>/dev/null)
      echo "- CSS (gzipped): $css_gz_size bytes" >> "$report_file"
    fi
  fi
  
  # JS sizes
  if [[ -f "$BUILD_DIR/js/app.min.js" ]]; then
    local js_size
    js_size=$(stat -c%s "$BUILD_DIR/js/app.min.js" 2>/dev/null || stat -f%z "$BUILD_DIR/js/app.min.js" 2>/dev/null)
    echo "- JS (minified): $js_size bytes" >> "$report_file"
    
    if [[ -f "$BUILD_DIR/js/app.min.js.gz" ]]; then
      local js_gz_size
      js_gz_size=$(stat -c%s "$BUILD_DIR/js/app.min.js.gz" 2>/dev/null || stat -f%z "$BUILD_DIR/js/app.min.js.gz" 2>/dev/null)
      echo "- JS (gzipped): $js_gz_size bytes" >> "$report_file"
    fi
  fi
  
  # Chart.js size
  if [[ -f "$BUILD_DIR/js/chart.min.js" ]]; then
    local chart_size
    chart_size=$(stat -c%s "$BUILD_DIR/js/chart.min.js" 2>/dev/null || stat -f%z "$BUILD_DIR/js/chart.min.js" 2>/dev/null)
    echo "- Chart.js: $chart_size bytes" >> "$report_file"
  fi
  
  # Font sizes
  echo "" >> "$report_file"
  echo "Font Assets:" >> "$report_file"
  find "$BUILD_DIR/fonts" -name "*.woff2" -exec basename {} \; 2>/dev/null | while read -r font; do
    local font_size
    font_size=$(stat -c%s "$BUILD_DIR/fonts/google-sans-flex/$font" 2>/dev/null || stat -f%z "$BUILD_DIR/fonts/google-sans-flex/$font" 2>/dev/null || echo "0")
    echo "- $font: $font_size bytes" >> "$report_file"
  done
  
  # Icon sizes
  echo "" >> "$report_file"
  echo "Icon Assets:" >> "$report_file"
  find "$BUILD_DIR/icons" -name "*.woff2" -exec basename {} \; 2>/dev/null | while read -r icon; do
    local icon_size
    icon_size=$(stat -c%s "$BUILD_DIR/icons/material-symbols/$icon" 2>/dev/null || stat -f%z "$BUILD_DIR/icons/material-symbols/$icon" 2>/dev/null || echo "0")
    echo "- $icon: $icon_size bytes" >> "$report_file"
  done
  
  # Total size
  local total_size
  total_size=$(du -sb "$DIST_DIR" | cut -f1)
  echo "" >> "$report_file"
  echo "Total Distribution Size: $total_size bytes" >> "$report_file"
  
  log_success "Build report generated: $report_file"
}

# Main build function
main() {
  local build_type="${1:-production}"
  
  log_info "=== notApollo Build System ==="
  log_info "Build type: $build_type"
  
  # Set build configuration based on type
  if [[ "$build_type" == "development" ]]; then
    ENABLE_MINIFICATION=false
    ENABLE_GZIP=false
  fi
  
  check_dependencies
  clean_build
  copy_assets
  
  if [[ "$ENABLE_MINIFICATION" == true ]]; then
    minify_css
    minify_js
    update_html
  else
    # Just copy CSS and JS without minification
    cp -r "$CSS_SRC" "$BUILD_DIR/" 2>/dev/null || true
    cp -r "$JS_SRC" "$BUILD_DIR/" 2>/dev/null || true
  fi
  
  create_distribution
  generate_report
  
  log_success "=== Build Complete ==="
  log_success "Distribution ready: $DIST_DIR"
  
  if [[ "$build_type" == "production" ]]; then
    log_info "Production build with minification and compression"
  else
    log_info "Development build without minification"
  fi
}

# Handle command line arguments
case "${1:-production}" in
  "development"|"dev")
    main "development"
    ;;
  "production"|"prod"|"")
    main "production"
    ;;
  "clean")
    log_info "Cleaning build directories..."
    rm -rf "$BUILD_DIR" "$DIST_DIR"
    log_success "Clean complete"
    ;;
  *)
    echo "Usage: $0 [production|development|clean]"
    echo "  production  - Build with minification and compression (default)"
    echo "  development - Build without minification for debugging"
    echo "  clean       - Remove build directories"
    exit 1
    ;;
esac