#!/bin/bash
# Direct uninstallation script for notApollo
# Removes files installed by install-direct.sh

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
readonly INSTALL_DIR="/www/notapollo"
readonly CONFIG_FILE="/etc/config/notapollo"
readonly INIT_SCRIPT="/etc/init.d/notapollo"
readonly UHTTPD_CONFIG="/etc/uhttpd/notapollo"

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Stop and disable service
stop_service() {
    log_info "Stopping notApollo service..."
    
    if [ -f "$INIT_SCRIPT" ]; then
        "$INIT_SCRIPT" stop 2>/dev/null || true
        "$INIT_SCRIPT" disable 2>/dev/null || true
        log_success "Service stopped and disabled"
    else
        log_info "Service script not found, skipping"
    fi
}

# Remove web files
remove_web_files() {
    log_info "Removing web files..."
    
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        log_success "Web files removed from $INSTALL_DIR"
    else
        log_info "Web files directory not found, skipping"
    fi
}

# Remove configuration
remove_config() {
    log_info "Removing configuration..."
    
    if [ -f "$CONFIG_FILE" ]; then
        rm -f "$CONFIG_FILE"
        log_success "Configuration removed"
    else
        log_info "Configuration file not found, skipping"
    fi
}

# Remove service script
remove_service() {
    log_info "Removing service script..."
    
    if [ -f "$INIT_SCRIPT" ]; then
        rm -f "$INIT_SCRIPT"
        log_success "Service script removed"
    else
        log_info "Service script not found, skipping"
    fi
}

# Remove uhttpd configuration
remove_uhttpd_config() {
    log_info "Removing uhttpd configuration..."
    
    if [ -f "$UHTTPD_CONFIG" ]; then
        rm -f "$UHTTPD_CONFIG"
        log_success "uhttpd configuration removed"
    else
        log_info "uhttpd configuration not found, skipping"
    fi
}

# Restart web server
restart_webserver() {
    log_info "Restarting web server..."
    
    if /etc/init.d/uhttpd restart; then
        log_success "Web server restarted"
    else
        log_warning "Failed to restart web server"
    fi
}

# Verify removal
verify_removal() {
    log_info "Verifying removal..."
    
    local issues=0
    
    # Check if web files still exist
    if [ -d "$INSTALL_DIR" ]; then
        log_warning "Web files still exist at $INSTALL_DIR"
        ((issues++))
    fi
    
    # Check if configuration still exists
    if [ -f "$CONFIG_FILE" ]; then
        log_warning "Configuration still exists at $CONFIG_FILE"
        ((issues++))
    fi
    
    # Check if service script still exists
    if [ -f "$INIT_SCRIPT" ]; then
        log_warning "Service script still exists at $INIT_SCRIPT"
        ((issues++))
    fi
    
    # Check if service is still running
    if pgrep -f notapollo >/dev/null 2>&1; then
        log_warning "notApollo processes still running"
        ((issues++))
    fi
    
    # Check if web interface is still accessible
    if curl -s -f http://127.0.0.1:8080 >/dev/null 2>&1; then
        log_warning "Web interface may still be accessible"
        ((issues++))
    fi
    
    if [ $issues -eq 0 ]; then
        log_success "Removal verification passed"
    else
        log_warning "Removal verification found $issues potential issues"
    fi
    
    return $issues
}

# Show completion message
show_completion() {
    echo ""
    log_success "=== Direct Uninstallation Complete ==="
    echo ""
    echo "notApollo has been removed from your system."
    echo ""
    echo "If you want to reinstall notApollo later:"
    echo "  Run the install-direct.sh script again"
    echo ""
    echo "Or use the package-based installation:"
    echo "  wget -O - https://raw.githubusercontent.com/Lyceris-chan/notApollo/main/install-notapollo.sh | sh"
}

# Main uninstallation process
main() {
    echo "notApollo Direct Uninstallation Script"
    echo "======================================"
    echo ""
    
    check_root
    
    # Confirm uninstallation
    printf "Are you sure you want to uninstall notApollo? [y/N]: "
    read -r confirm
    case "$confirm" in
        [yY]|[yY][eE][sS])
            log_info "Proceeding with uninstallation..."
            ;;
        *)
            log_info "Uninstallation cancelled"
            exit 0
            ;;
    esac
    
    stop_service
    remove_web_files
    remove_config
    remove_service
    remove_uhttpd_config
    restart_webserver
    verify_removal
    show_completion
}

# Run main function
main "$@"