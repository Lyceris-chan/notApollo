#!/bin/bash
# Quick start script for notApollo development

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

# Check if we're in the right directory
check_directory() {
    if [ ! -f "README.md" ] || [ ! -d "www/notapollo" ]; then
        log_error "Please run this script from the notApollo project root directory"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    command -v git >/dev/null 2>&1 || missing_tools+=("git")
    command -v curl >/dev/null 2>&1 || missing_tools+=("curl")
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install missing tools and run this script again"
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

# Set up development environment
setup_development() {
    log_info "Setting up development environment..."
    
    # Run the main setup script
    if [ -f "scripts/setup-dev.sh" ]; then
        ./scripts/setup-dev.sh
    else
        log_warning "Development setup script not found, continuing with manual setup..."
    fi
    
    # Set up web development
    cd www/notapollo
    
    if [ -f "scripts/setup-build.sh" ]; then
        log_info "Setting up build environment..."
        ./scripts/setup-build.sh --build-type development
    fi
    
    cd ../..
    
    log_success "Development environment ready"
}

# Download assets
download_assets() {
    log_info "Downloading required assets..."
    
    cd www/notapollo
    
    if [ -f "scripts/smart-retry-assets.sh" ]; then
        log_info "Using smart retry asset download..."
        chmod +x scripts/smart-retry-assets.sh
        ./scripts/smart-retry-assets.sh
    elif [ -f "scripts/download-assets.sh" ]; then
        log_info "Using standard asset download..."
        ./scripts/download-assets.sh
    else
        log_warning "No asset download script found"
    fi
    
    cd ../..
    
    log_success "Assets downloaded"
}

# Start development server
start_server() {
    log_info "Starting development server..."
    
    cd www/notapollo
    
    if [ -f "scripts/serve-local.sh" ]; then
        log_success "Development server starting..."
        log_info "Access the interface at: http://localhost:8080"
        log_info "Press Ctrl+C to stop the server"
        ./scripts/serve-local.sh
    else
        log_error "Development server script not found"
        exit 1
    fi
}

# Show help
show_help() {
    cat << EOF
notApollo Quick Start Script

Usage: $0 [OPTIONS]

Options:
  --setup-only    Set up development environment without starting server
  --server-only   Start development server (assumes setup is complete)
  --help          Show this help message

Examples:
  $0              # Full setup and start server
  $0 --setup-only # Set up environment only
  $0 --server-only # Start server only

This script will:
1. Check prerequisites (git, curl)
2. Set up the development environment
3. Download required assets (Google Fonts, Chart.js, Material Symbols)
4. Start the local development server

After setup, you can:
- Edit files in www/notapollo/
- View changes at http://localhost:8080
- Build packages with: cd package/notapollo && make
- Run tests with: ./scripts/test.sh

EOF
}

# Main function
main() {
    local setup_only=false
    local server_only=false
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case $1 in
            --setup-only)
                setup_only=true
                shift
                ;;
            --server-only)
                server_only=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo "notApollo Quick Start"
    echo "===================="
    echo ""
    
    check_directory
    check_prerequisites
    
    if [ "$server_only" = false ]; then
        setup_development
        download_assets
    fi
    
    if [ "$setup_only" = false ]; then
        start_server
    else
        echo ""
        log_success "Setup complete!"
        log_info "To start the development server, run:"
        log_info "  cd www/notapollo && ./scripts/serve-local.sh"
    fi
}

# Run main function
main "$@"