#!/bin/bash
# Direct installation script for notApollo
# Installs files directly without using opkg packages
# Checks dependencies and only retries failed steps

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

log_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

log_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly WWW_SOURCE="$PROJECT_ROOT/www/notapollo"
readonly INSTALL_DIR="/www/notapollo"
readonly CONFIG_DIR="/etc/config"
readonly INIT_DIR="/etc/init.d"
readonly UHTTPD_DIR="/etc/uhttpd"

# Required dependencies
readonly REQUIRED_PACKAGES=(
    "uhttpd"
    "curl"
    "iwinfo"
    "ip-full"
    "bind-dig"
    "coreutils-stat"
    "coreutils-timeout"
    "procps-ng-ps"
    "logread"
)

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Check if we're on OpenWrt
check_openwrt() {
    if [ ! -f /etc/openwrt_release ]; then
        log_error "This script requires OpenWrt. /etc/openwrt_release not found."
        exit 1
    fi
    
    . /etc/openwrt_release
    log_info "Detected OpenWrt $DISTRIB_RELEASE ($DISTRIB_CODENAME)"
}

# Check dependencies
check_dependencies() {
    log_info "Checking required dependencies..."
    
    local missing_packages=()
    local available_packages
    
    # Update package list
    log_info "Updating package lists..."
    opkg update
    
    # Get list of installed packages
    local installed_packages
    installed_packages=$(opkg list-installed | cut -d' ' -f1)
    
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! echo "$installed_packages" | grep -q "^$package$"; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        log_warning "Missing required packages: ${missing_packages[*]}"
        log_info "Installing missing packages..."
        
        for package in "${missing_packages[@]}"; do
            log_info "Installing $package..."
            if opkg install "$package"; then
                log_success "Installed $package"
            else
                log_error "Failed to install $package"
                return 1
            fi
        done
    else
        log_success "All required dependencies are installed"
    fi
}

# Download assets with smart retry
download_assets() {
    log_info "Downloading and verifying assets..."
    
    cd "$WWW_SOURCE"
    
    # Make scripts executable
    chmod +x scripts/*.sh 2>/dev/null || true
    
    # Check what assets are missing
    local missing_assets=()
    
    if [ ! -f "fonts/google-sans-flex/GoogleSansFlex-Regular.woff2" ] && [ ! -f "fonts/google-sans-flex/GoogleSansFlex-Variable.woff2" ]; then
        missing_assets+=("fonts")
    fi
    
    if [ ! -f "icons/material-symbols/material-symbols-outlined.woff2" ]; then
        missing_assets+=("icons")
    fi
    
    if [ ! -f "js/lib/chart.min.js" ]; then
        missing_assets+=("chartjs")
    fi
    
    if [ ${#missing_assets[@]} -eq 0 ]; then
        log_success "All assets are already present"
        return 0
    fi
    
    log_info "Missing assets: ${missing_assets[*]}"
    
    # Try to download missing assets with smart retry
    if [ -f "./scripts/smart-retry-assets.sh" ]; then
        log_info "Using smart retry asset download..."
        chmod +x ./scripts/smart-retry-assets.sh
        if timeout 600 ./scripts/smart-retry-assets.sh; then
            log_success "Smart asset download completed successfully"
            return 0
        else
            log_warning "Smart asset download failed"
        fi
    else
        log_info "Using standard asset download with retry..."
        for attempt in {1..3}; do
            log_info "Asset download attempt $attempt/3..."
            
            if timeout 300 ./scripts/download-assets.sh; then
                log_success "Assets downloaded successfully on attempt $attempt"
                return 0
            else
                log_warning "Asset download failed on attempt $attempt"
                if [ $attempt -lt 3 ]; then
                    log_info "Retrying in 10 seconds..."
                    sleep 10
                fi
            fi
        done
    fi
    
    # If download failed, check if we can proceed with existing assets
    log_warning "Asset download failed after 3 attempts"
    log_info "Checking if we can proceed with existing assets..."
    
    # Check if Chart.js is available (most critical)
    if [ ! -f "js/lib/chart.min.js" ]; then
        log_error "Chart.js is required but not available. Cannot proceed."
        return 1
    fi
    
    # Create fallback font CSS if fonts failed
    if [ ! -f "fonts/google-sans-flex/GoogleSansFlex-Regular.woff2" ]; then
        log_warning "Google Fonts not available, creating fallback CSS..."
        mkdir -p fonts/google-sans-flex
        cat > fonts/google-sans-flex/fonts.css << 'EOF'
/* Fallback font CSS - uses system fonts */
body, .material-symbols-outlined {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}
EOF
        log_success "Created fallback font CSS"
    fi
    
    # Create fallback icon CSS if icons failed
    if [ ! -f "icons/material-symbols/material-symbols-outlined.woff2" ]; then
        log_warning "Material Symbols not available, creating fallback CSS..."
        mkdir -p icons/material-symbols
        cat > icons/material-symbols/icons.css << 'EOF'
/* Fallback icon CSS - uses Unicode symbols */
.material-symbols-outlined {
  font-family: monospace;
  font-size: 24px;
  line-height: 1;
}
EOF
        log_success "Created fallback icon CSS"
    fi
    
    log_success "Proceeding with available assets and fallbacks"
}

# Install web files
install_web_files() {
    log_info "Installing web files..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy all web files
    cp -r "$WWW_SOURCE"/* "$INSTALL_DIR/"
    
    # Set proper permissions
    find "$INSTALL_DIR" -type f -name "*.html" -exec chmod 644 {} \; 2>/dev/null || true
    find "$INSTALL_DIR" -type f -name "*.css" -exec chmod 644 {} \; 2>/dev/null || true
    find "$INSTALL_DIR" -type f -name "*.js" -exec chmod 644 {} \; 2>/dev/null || true
    find "$INSTALL_DIR" -type f -name "*.json" -exec chmod 644 {} \; 2>/dev/null || true
    find "$INSTALL_DIR" -type f -name "*.woff2" -exec chmod 644 {} \; 2>/dev/null || true
    find "$INSTALL_DIR" -type f -name "*.ico" -exec chmod 644 {} \; 2>/dev/null || true
    find "$INSTALL_DIR" -type f -name "*.png" -exec chmod 644 {} \; 2>/dev/null || true
    
    # Make API scripts executable
    find "$INSTALL_DIR/api" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    find "$INSTALL_DIR/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    
    log_success "Web files installed to $INSTALL_DIR"
}

# Install configuration
install_config() {
    log_info "Installing configuration..."
    
    # Install main config
    if [ -f "$PROJECT_ROOT/package/notapollo/files/etc/config/notapollo" ]; then
        cp "$PROJECT_ROOT/package/notapollo/files/etc/config/notapollo" "$CONFIG_DIR/"
        log_success "Configuration installed"
    else
        log_warning "Configuration file not found, creating default..."
        cat > "$CONFIG_DIR/notapollo" << 'EOF'
config notapollo 'main'
	option enabled '1'
	option port '8080'
	option interface '192.168.69.1 192.168.70.1'
EOF
        log_success "Default configuration created"
    fi
}

# Install service
install_service() {
    log_info "Installing service..."
    
    if [ -f "$PROJECT_ROOT/package/notapollo/files/etc/init.d/notapollo" ]; then
        cp "$PROJECT_ROOT/package/notapollo/files/etc/init.d/notapollo" "$INIT_DIR/"
        chmod +x "$INIT_DIR/notapollo"
        log_success "Service script installed"
    else
        log_warning "Service script not found, creating basic service..."
        cat > "$INIT_DIR/notapollo" << 'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10

USE_PROCD=1
PROG=/usr/sbin/uhttpd
CONF_FILE=/etc/uhttpd/notapollo

start_service() {
    procd_open_instance
    procd_set_param command $PROG -f -h /www/notapollo -r notApollo -x /cgi-bin -t 60 -T 30 -k 20 -A 1 -n 3 -N 200 -R -p 192.168.69.1:8080 -p 192.168.70.1:8080
    procd_set_param respawn
    procd_close_instance
}
EOF
        chmod +x "$INIT_DIR/notapollo"
        log_success "Basic service script created"
    fi
}

# Configure uhttpd
configure_uhttpd() {
    log_info "Configuring uhttpd..."
    
    mkdir -p "$UHTTPD_DIR"
    
    cat > "$UHTTPD_DIR/notapollo" << 'EOF'
# notApollo uhttpd configuration
# Serves on dual interfaces for primary and guest networks
config uhttpd 'notapollo'
	option home '/www/notapollo'
	option rfc1918_filter '0'
	option max_requests '3'
	option max_connections '100'
	option cert '/etc/uhttpd.crt'
	option key '/etc/uhttpd.key'
	option cgi_prefix '/cgi-bin'
	option script_timeout '60'
	option network_timeout '30'
	option http_keepalive '20'
	option tcp_keepalive '1'
	list listen_http '192.168.69.1:8080'
	list listen_http '192.168.70.1:8080'
EOF
    
    log_success "uhttpd configuration created"
}

# Start services
start_services() {
    log_info "Starting services..."
    
    # Enable and start notapollo service
    "$INIT_DIR/notapollo" enable 2>/dev/null || true
    
    if "$INIT_DIR/notapollo" start; then
        log_success "notApollo service started"
    else
        log_warning "Failed to start notApollo service, trying uhttpd restart..."
        /etc/init.d/uhttpd restart
        sleep 2
        if "$INIT_DIR/notapollo" start; then
            log_success "notApollo service started after uhttpd restart"
        else
            log_error "Failed to start notApollo service"
            return 1
        fi
    fi
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    local issues=0
    
    # Check web files
    if [ -f "$INSTALL_DIR/index.html" ]; then
        log_success "Web interface installed"
    else
        log_error "Web interface not found"
        ((issues++))
    fi
    
    # Check service
    if [ -f "$INIT_DIR/notapollo" ]; then
        log_success "Service script installed"
    else
        log_error "Service script not found"
        ((issues++))
    fi
    
    # Check if service is running
    if "$INIT_DIR/notapollo" status >/dev/null 2>&1; then
        log_success "Service is running"
    else
        log_warning "Service may not be running"
        ((issues++))
    fi
    
    # Check web accessibility
    sleep 3
    if curl -s -f http://127.0.0.1:8080 >/dev/null 2>&1; then
        log_success "Web interface is accessible"
    else
        log_warning "Web interface may not be accessible yet"
        ((issues++))
    fi
    
    if [ $issues -eq 0 ]; then
        log_success "Installation verification passed"
    else
        log_warning "Installation verification found $issues potential issues"
    fi
    
    return $issues
}

# Show completion message
show_completion() {
    echo ""
    log_success "=== Direct Installation Complete ==="
    echo ""
    echo "notApollo is now available at:"
    echo "  Primary Network: http://192.168.69.1:8080"
    echo "  Guest Network:   http://192.168.70.1:8080"
    echo ""
    echo "Service management:"
    echo "  Start:   /etc/init.d/notapollo start"
    echo "  Stop:    /etc/init.d/notapollo stop"
    echo "  Restart: /etc/init.d/notapollo restart"
    echo "  Status:  /etc/init.d/notapollo status"
    echo ""
    echo "Configuration: /etc/config/notapollo"
    echo "Web files:     /www/notapollo/"
    echo ""
    echo "To uninstall: $SCRIPT_DIR/uninstall-direct.sh"
}

# Main installation process
main() {
    echo "notApollo Direct Installation Script"
    echo "===================================="
    echo ""
    
    check_root
    check_openwrt
    check_dependencies
    download_assets
    install_web_files
    install_config
    install_service
    configure_uhttpd
    start_services
    verify_installation
    show_completion
}

# Run main function
main "$@"