#!/bin/bash
# Local development server for notApollo
# Serves assets locally for development and testing

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
readonly DEFAULT_PORT=8080
readonly DEFAULT_HOST="0.0.0.0"

# Server configuration
PORT="${PORT:-$DEFAULT_PORT}"
HOST="${HOST:-$DEFAULT_HOST}"
DOCUMENT_ROOT="$PROJECT_DIR"

# Logging functions
log_info() {
  echo "[SERVER] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}

log_success() {
  echo "[SUCCESS] $*" >&2
}

# Check for available HTTP servers
detect_server() {
  if command -v python3 >/dev/null 2>&1; then
    echo "python3"
  elif command -v python >/dev/null 2>&1; then
    echo "python"
  elif command -v node >/dev/null 2>&1; then
    echo "node"
  elif command -v php >/dev/null 2>&1; then
    echo "php"
  elif command -v busybox >/dev/null 2>&1 && busybox httpd --help >/dev/null 2>&1; then
    echo "busybox"
  else
    echo "none"
  fi
}

# Start Python HTTP server
start_python_server() {
  local python_cmd="$1"
  
  log_info "Starting Python HTTP server..."
  log_info "Document root: $DOCUMENT_ROOT"
  log_info "Listening on: http://$HOST:$PORT"
  
  cd "$DOCUMENT_ROOT"
  
  if [[ "$python_cmd" == "python3" ]]; then
    python3 -m http.server "$PORT" --bind "$HOST"
  else
    python -m SimpleHTTPServer "$PORT"
  fi
}

# Start Node.js HTTP server
start_node_server() {
  log_info "Starting Node.js HTTP server..."
  log_info "Document root: $DOCUMENT_ROOT"
  log_info "Listening on: http://$HOST:$PORT"
  
  node -e "
    const http = require('http');
    const fs = require('fs');
    const path = require('path');
    const url = require('url');
    
    const mimeTypes = {
      '.html': 'text/html',
      '.css': 'text/css',
      '.js': 'application/javascript',
      '.json': 'application/json',
      '.woff2': 'font/woff2',
      '.woff': 'font/woff',
      '.ttf': 'font/ttf',
      '.ico': 'image/x-icon',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.gif': 'image/gif',
      '.svg': 'image/svg+xml'
    };
    
    const server = http.createServer((req, res) => {
      let pathname = url.parse(req.url).pathname;
      
      // Default to index.html
      if (pathname === '/') {
        pathname = '/index.html';
      }
      
      const filePath = path.join('$DOCUMENT_ROOT', pathname);
      
      fs.readFile(filePath, (err, data) => {
        if (err) {
          res.writeHead(404, {'Content-Type': 'text/plain'});
          res.end('404 Not Found');
          return;
        }
        
        const ext = path.extname(filePath);
        const mimeType = mimeTypes[ext] || 'application/octet-stream';
        
        res.writeHead(200, {'Content-Type': mimeType});
        res.end(data);
      });
    });
    
    server.listen($PORT, '$HOST', () => {
      console.log('Server running at http://$HOST:$PORT/');
    });
  "
}

# Start PHP built-in server
start_php_server() {
  log_info "Starting PHP built-in server..."
  log_info "Document root: $DOCUMENT_ROOT"
  log_info "Listening on: http://$HOST:$PORT"
  
  cd "$DOCUMENT_ROOT"
  php -S "$HOST:$PORT"
}

# Start BusyBox HTTP server
start_busybox_server() {
  log_info "Starting BusyBox HTTP server..."
  log_info "Document root: $DOCUMENT_ROOT"
  log_info "Listening on: http://$HOST:$PORT"
  
  cd "$DOCUMENT_ROOT"
  busybox httpd -f -p "$PORT" -h "$DOCUMENT_ROOT"
}

# Create a simple HTTP server using netcat (fallback)
start_netcat_server() {
  log_info "Starting simple netcat HTTP server..."
  log_info "Document root: $DOCUMENT_ROOT"
  log_info "Listening on: http://$HOST:$PORT"
  log_info "Note: This is a basic server for testing only"
  
  cd "$DOCUMENT_ROOT"
  
  while true; do
    {
      echo "HTTP/1.1 200 OK"
      echo "Content-Type: text/html"
      echo "Connection: close"
      echo ""
      if [[ -f "index.html" ]]; then
        cat "index.html"
      else
        echo "<h1>notApollo Development Server</h1>"
        echo "<p>Document root: $DOCUMENT_ROOT</p>"
        echo "<p>Available files:</p><ul>"
        find . -name "*.html" -o -name "*.css" -o -name "*.js" | head -20 | while read -r file; do
          echo "<li><a href=\"$file\">$file</a></li>"
        done
        echo "</ul>"
      fi
    } | nc -l -p "$PORT" -q 1
  done
}

# Check if port is available
check_port() {
  if command -v netstat >/dev/null 2>&1; then
    if netstat -tuln 2>/dev/null | grep -q ":$PORT "; then
      log_error "Port $PORT is already in use"
      return 1
    fi
  elif command -v ss >/dev/null 2>&1; then
    if ss -tuln 2>/dev/null | grep -q ":$PORT "; then
      log_error "Port $PORT is already in use"
      return 1
    fi
  fi
  return 0
}

# Verify assets before serving
verify_assets() {
  log_info "Verifying assets before serving..."
  
  if [[ -f "$SCRIPT_DIR/verify-assets.sh" ]]; then
    if "$SCRIPT_DIR/verify-assets.sh" >/dev/null 2>&1; then
      log_success "Asset verification passed"
    else
      log_error "Asset verification failed"
      log_info "Run '$SCRIPT_DIR/download-assets.sh' to download missing assets"
      return 1
    fi
  else
    log_info "Asset verification script not found, skipping verification"
  fi
}

# Show server information
show_info() {
  log_info "=== notApollo Local Development Server ==="
  log_info "Server URL: http://$HOST:$PORT"
  log_info "Document Root: $DOCUMENT_ROOT"
  
  # Show network interfaces
  if command -v ip >/dev/null 2>&1; then
    log_info "Available network interfaces:"
    ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print "  - " $2}' | head -5
  elif command -v ifconfig >/dev/null 2>&1; then
    log_info "Available network interfaces:"
    ifconfig | grep "inet " | grep -v "127.0.0.1" | awk '{print "  - " $2}' | head -5
  fi
  
  log_info ""
  log_info "Access the application at:"
  log_info "  - Local: http://localhost:$PORT"
  log_info "  - Network: http://$HOST:$PORT"
  log_info ""
  log_info "Press Ctrl+C to stop the server"
}

# Handle cleanup on exit
cleanup() {
  log_info "Shutting down server..."
  exit 0
}

trap cleanup INT TERM

# Main function
main() {
  local server_type
  local force_server=""
  
  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -p|--port)
        PORT="$2"
        shift 2
        ;;
      -h|--host)
        HOST="$2"
        shift 2
        ;;
      -s|--server)
        force_server="$2"
        shift 2
        ;;
      --no-verify)
        SKIP_VERIFY=true
        shift
        ;;
      --help)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -p, --port PORT     Server port (default: $DEFAULT_PORT)"
        echo "  -h, --host HOST     Server host (default: $DEFAULT_HOST)"
        echo "  -s, --server TYPE   Force server type (python3|python|node|php|busybox)"
        echo "  --no-verify         Skip asset verification"
        echo "  --help              Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                          # Start server on default port"
        echo "  $0 -p 3000                  # Start server on port 3000"
        echo "  $0 -h 192.168.1.100 -p 8080 # Start server on specific interface"
        echo "  $0 -s python3               # Force Python 3 server"
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        exit 1
        ;;
    esac
  done
  
  # Verify assets unless skipped
  if [[ "${SKIP_VERIFY:-false}" != "true" ]]; then
    verify_assets || exit 1
  fi
  
  # Check if port is available
  check_port || exit 1
  
  # Detect or use forced server type
  if [[ -n "$force_server" ]]; then
    server_type="$force_server"
  else
    server_type=$(detect_server)
  fi
  
  # Show server information
  show_info
  
  # Start appropriate server
  case "$server_type" in
    "python3")
      start_python_server "python3"
      ;;
    "python")
      start_python_server "python"
      ;;
    "node")
      start_node_server
      ;;
    "php")
      start_php_server
      ;;
    "busybox")
      start_busybox_server
      ;;
    "none")
      log_error "No suitable HTTP server found"
      log_info "Please install one of: python3, python, node, php, or busybox"
      log_info "Attempting fallback netcat server..."
      if command -v nc >/dev/null 2>&1; then
        start_netcat_server
      else
        log_error "Netcat not available, cannot start server"
        exit 1
      fi
      ;;
    *)
      log_error "Unknown server type: $server_type"
      exit 1
      ;;
  esac
}

# Run main function
main "$@"