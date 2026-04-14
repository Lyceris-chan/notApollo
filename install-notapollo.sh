#!/bin/sh
# notApollo Installation Script
# Automatically detects OpenWrt version and architecture, then downloads and installs the appropriate package

set -e

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

# Detect OpenWrt version and architecture
detect_system() {
    if [ ! -f /etc/openwrt_release ]; then
        log_error "This script requires OpenWrt. /etc/openwrt_release not found."
        exit 1
    fi
    
    . /etc/openwrt_release
    
    OPENWRT_VERSION=$(echo "$DISTRIB_RELEASE" | cut -d. -f1-2)
    OPENWRT_ARCH=$(uname -m)
    
    # Map architecture names
    case "$OPENWRT_ARCH" in
        mips|mipsel) TARGET="ramips-mt76x8" ;;
        x86_64) TARGET="x86-64" ;;
        aarch64) TARGET="mediatek-filogic" ;;
        *) 
            log_warning "Unknown architecture: $OPENWRT_ARCH"
            TARGET="ramips-mt76x8"
            ;;
    esac
    
    log_info "Detected OpenWrt $OPENWRT_VERSION on $OPENWRT_ARCH (target: $TARGET)"
}

# Download package from GitHub releases
download_package() {
    local github_repo="Lyceris-chan/notApollo"
    local release_url="https://api.github.com/repos/$github_repo/releases/latest"
    
    log_info "Fetching latest release information..."
    
    # Get latest release info
    if command -v curl >/dev/null 2>&1; then
        release_info=$(curl -s "$release_url")
    elif command -v wget >/dev/null 2>&1; then
        release_info=$(wget -qO- "$release_url")
    else
        log_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    # Find matching package
    package_name="notapollo_*-${OPENWRT_VERSION}-${TARGET}.ipk"
    download_url=$(echo "$release_info" | grep -o "https://.*${TARGET}\.ipk" | head -1)
    
    if [ -z "$download_url" ]; then
        log_error "No package found for OpenWrt $OPENWRT_VERSION on $TARGET"
        log_info "Available packages:"
        echo "$release_info" | grep -o "notapollo_.*\.ipk" | head -5
        exit 1
    fi
    
    package_file=$(basename "$download_url")
    
    log_info "Downloading $package_file..."
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "/tmp/$package_file" "$download_url"
    else
        wget -O "/tmp/$package_file" "$download_url"
    fi
    
    log_success "Downloaded to /tmp/$package_file"
}

# Install package
install_package() {
    log_info "Installing notApollo package..."
    
    # Update package lists
    opkg update
    
    # Install package
    if opkg install "/tmp/$package_file"; then
        log_success "notApollo installed successfully!"
    else
        log_error "Installation failed. Check the error messages above."
        exit 1
    fi
    
    # Clean up
    rm -f "/tmp/$package_file"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check if service exists
    if [ -f /etc/init.d/notapollo ]; then
        log_success "Service script installed"
    else
        log_warning "Service script not found"
    fi
    
    # Check if web files exist
    if [ -d /www/notapollo ]; then
        log_success "Web interface installed"
    else
        log_warning "Web interface not found"
    fi
    
    # Try to start service
    if /etc/init.d/notapollo start; then
        log_success "Service started successfully"
    else
        log_warning "Service failed to start"
    fi
    
    # Check if web interface is accessible
    sleep 3
    if curl -s -f http://127.0.0.1:8080 >/dev/null 2>&1; then
        log_success "Web interface is accessible"
    else
        log_warning "Web interface may not be accessible yet"
    fi
}

# Show access information
show_access_info() {
    echo ""
    log_success "=== Installation Complete ==="
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
    echo "For troubleshooting, check the logs:"
    echo "  logread | grep notapollo"
}

# Main installation process
main() {
    echo "notApollo Installation Script"
    echo "============================="
    echo ""
    
    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi
    
    detect_system
    download_package
    install_package
    verify_installation
    show_access_info
}

# Run main function
main "$@"