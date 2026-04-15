#!/bin/sh
# notApollo Uninstallation Script

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

# Stop and disable service
stop_service() {
    log_info "Stopping notApollo service..."
    
    if [ -f /etc/init.d/notapollo ]; then
        /etc/init.d/notapollo stop 2>/dev/null || true
        /etc/init.d/notapollo disable 2>/dev/null || true
        log_success "Service stopped and disabled"
    else
        log_info "Service script not found, skipping"
    fi
}

# Remove package
remove_package() {
    log_info "Removing notApollo package..."
    
    if opkg list-installed | grep -q "^notapollo "; then
        opkg remove notapollo
        log_success "Package removed"
    else
        log_warning "Package not found in installed packages"
    fi
}

# Clean up remaining files
cleanup_files() {
    log_info "Cleaning up remaining files..."
    
    # Remove web files
    if [ -d /www/notapollo ]; then
        rm -rf /www/notapollo
        log_success "Web files removed"
    fi
    
    # Remove configuration
    if [ -f /etc/config/notapollo ]; then
        rm -f /etc/config/notapollo
        log_success "Configuration removed"
    fi
    
    # Remove uhttpd configuration
    if [ -f /etc/uhttpd/notapollo ]; then
        rm -f /etc/uhttpd/notapollo
        log_success "Web server configuration removed"
    fi
    
    # Remove service script (if still present)
    if [ -f /etc/init.d/notapollo ]; then
        rm -f /etc/init.d/notapollo
        log_success "Service script removed"
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
    
    # Check if package is still installed
    if opkg list-installed | grep -q "^notapollo "; then
        log_warning "Package still appears to be installed"
        issues=$((issues + 1))
    fi
    
    # Check if web files still exist
    if [ -d /www/notapollo ]; then
        log_warning "Web files still exist at /www/notapollo"
        issues=$((issues + 1))
    fi
    
    # Check if service is still running
    if pgrep -f notapollo >/dev/null 2>&1; then
        log_warning "notApollo processes still running"
        issues=$((issues + 1))
    fi
    
    # Check if web interface is still accessible
    if curl -s -f http://127.0.0.1:8080 >/dev/null 2>&1; then
        log_warning "Web interface may still be accessible"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        log_success "Removal verification passed"
    else
        log_warning "Removal verification found $issues potential issues"
    fi
}

# Show completion message
show_completion() {
    echo ""
    log_success "=== Uninstallation Complete ==="
    echo ""
    echo "notApollo has been removed from your system."
    echo ""
    echo "If you want to reinstall notApollo later:"
    echo "  wget -O - https://raw.githubusercontent.com/Lyceris-chan/notApollo/main/install-notapollo.sh | sh"
    echo ""
    echo "Or download and run the installation script manually."
}

# Main uninstallation process
main() {
    echo "notApollo Uninstallation Script"
    echo "==============================="
    echo ""
    
    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi
    
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
    remove_package
    cleanup_files
    restart_webserver
    verify_removal
    show_completion
}

# Run main function
main "$@"