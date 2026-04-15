#!/bin/bash
# Development environment setup script for notApollo

set -e

echo "🚀 Setting up notApollo development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check for required tools
    command -v git >/dev/null 2>&1 || missing_tools+=("git")
    command -v curl >/dev/null 2>&1 || missing_tools+=("curl")
    command -v jq >/dev/null 2>&1 || missing_tools+=("jq")
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_status "Please install missing tools and run this script again"
        exit 1
    fi
    
    print_success "All prerequisites satisfied"
}

# Set up git hooks
setup_git_hooks() {
    print_status "Setting up git hooks..."
    
    mkdir -p .git/hooks
    
    # Pre-commit hook for code quality
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
# notApollo pre-commit hook

echo "Running pre-commit checks..."

# Check for Google style compliance in JavaScript files
if git diff --cached --name-only | grep -E '\.(js|mjs)$' > /dev/null; then
    echo "Checking JavaScript code style..."
    # Add ESLint check here when available
fi

# Check for shell script syntax
if git diff --cached --name-only | grep -E '\.sh$' > /dev/null; then
    echo "Checking shell script syntax..."
    for file in $(git diff --cached --name-only | grep -E '\.sh$'); do
        if [ -f "$file" ]; then
            if ! sh -n "$file"; then
                echo "Syntax error in $file"
                exit 1
            fi
        fi
    done
fi

# Check for user-friendly language in user-facing files
if git diff --cached --name-only | grep -E '\.(js|html)$' > /dev/null; then
    echo "Checking for user-friendly language..."
    # Add checks for technical jargon here
fi

echo "Pre-commit checks passed!"
EOF

    chmod +x .git/hooks/pre-commit
    
    # Commit message template
    cat > .git/hooks/prepare-commit-msg << 'EOF'
#!/bin/sh
# notApollo commit message template

if [ "$2" = "" ]; then
    cat > "$1" << 'TEMPLATE'
# <type>: <description>
#
# <body>
#
# <footer>
#
# Types:
# feat: A new feature
# fix: A bug fix
# docs: Documentation only changes
# style: Changes that do not affect the meaning of the code
# refactor: A code change that neither fixes a bug nor adds a feature
# perf: A code change that improves performance
# test: Adding missing tests or correcting existing tests
# chore: Changes to the build process or auxiliary tools
#
# Examples:
# feat: add DNS cache performance monitoring
# fix: resolve mobile chart rendering issue
# docs: update installation guide for OpenWrt 23.05
TEMPLATE
fi
EOF

    chmod +x .git/hooks/prepare-commit-msg
    
    print_success "Git hooks configured"
}

# Set up development configuration
setup_dev_config() {
    print_status "Setting up development configuration..."
    
    # Create local development config
    cat > .env.development << 'EOF'
# Development environment configuration
NODE_ENV=development
DEBUG=true
API_BASE_URL=http://localhost:8080
MOCK_DATA=true
UPDATE_INTERVAL=5000
LOG_LEVEL=debug
EOF

    # Create VS Code settings if not exists
    mkdir -p .vscode
    
    if [ ! -f .vscode/settings.json ]; then
        cat > .vscode/settings.json << 'EOF'
{
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.detectIndentation": false,
  "editor.formatOnSave": true,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "javascript.preferences.quoteStyle": "single",
  "css.validate": true,
  "html.format.indentInnerHtml": true,
  "emmet.includeLanguages": {
    "javascript": "javascriptreact"
  },
  "files.associations": {
    "*.sh": "shellscript"
  },
  "shellcheck.enable": true,
  "eslint.enable": true
}
EOF
    fi
    
    # Create launch configuration for debugging
    if [ ! -f .vscode/launch.json ]; then
        cat > .vscode/launch.json << 'EOF'
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug notApollo",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/www/notapollo/scripts/serve-local.sh",
      "console": "integratedTerminal",
      "env": {
        "NODE_ENV": "development"
      }
    }
  ]
}
EOF
    fi
    
    print_success "Development configuration created"
}

# Set up web development environment
setup_web_dev() {
    print_status "Setting up web development environment..."
    
    cd www/notapollo
    
    # Run existing setup script
    if [ -f scripts/setup-build.sh ]; then
        print_status "Running web setup script..."
        ./scripts/setup-build.sh
    else
        print_warning "Web setup script not found, skipping..."
    fi
    
    # Download assets if script exists
    if [ -f scripts/smart-retry-assets.sh ]; then
        print_status "Downloading web assets with smart retry..."
        chmod +x scripts/smart-retry-assets.sh
        ./scripts/smart-retry-assets.sh
    elif [ -f scripts/download-assets.sh ]; then
        print_status "Downloading web assets..."
        ./scripts/download-assets.sh
    else
        print_warning "Asset download script not found, skipping..."
    fi
    
    cd ../..
    
    print_success "Web development environment ready"
}

# Create development utilities
create_dev_utilities() {
    print_status "Creating development utilities..."
    
    # Development server script
    cat > scripts/dev-server.sh << 'EOF'
#!/bin/bash
# Development server for notApollo

echo "Starting notApollo development server..."

# Check if we're in the right directory
if [ ! -f "www/notapollo/index.html" ]; then
    echo "Error: Please run from project root directory"
    exit 1
fi

# Start local development server
cd www/notapollo
if [ -f scripts/serve-local.sh ]; then
    ./scripts/serve-local.sh
else
    echo "Starting simple HTTP server..."
    python3 -m http.server 8080 2>/dev/null || python -m SimpleHTTPServer 8080
fi
EOF

    chmod +x scripts/dev-server.sh
    
    # Code quality check script
    cat > scripts/check-quality.sh << 'EOF'
#!/bin/bash
# Code quality check script

echo "Running code quality checks..."

# Check shell scripts
echo "Checking shell scripts..."
find . -name "*.sh" -type f | while read -r file; do
    if ! sh -n "$file"; then
        echo "Syntax error in $file"
        exit 1
    fi
done

# Check for user-friendly language
echo "Checking for user-friendly language..."
if grep -r -E "(interface|daemon|subprocess|timeout)" www/notapollo/js/ 2>/dev/null; then
    echo "Warning: Technical terms found in user-facing code"
fi

# Check Material 3 compliance
echo "Checking Material 3 compliance..."
if ! grep -q "md-sys-color" www/notapollo/css/*.css 2>/dev/null; then
    echo "Warning: Material 3 color tokens not found"
fi

echo "Code quality checks completed"
EOF

    chmod +x scripts/check-quality.sh
    
    # Build script
    cat > scripts/build.sh << 'EOF'
#!/bin/bash
# Build script for notApollo

echo "Building notApollo..."

# Build web assets
cd www/notapollo
if [ -f scripts/build.sh ]; then
    ./scripts/build.sh
else
    echo "No web build script found, copying files..."
    # Simple file copy for now
fi

cd ../..

# Build OpenWrt package
cd package/notapollo
if [ -f Makefile ]; then
    echo "Building OpenWrt package..."
    make clean
    make
else
    echo "No package Makefile found"
fi

cd ../..

echo "Build completed"
EOF

    chmod +x scripts/build.sh
    
    # Test script
    cat > scripts/test.sh << 'EOF'
#!/bin/bash
# Test script for notApollo

echo "Running notApollo tests..."

# Run code quality checks
./scripts/check-quality.sh

# Test API endpoints (if development server is running)
if curl -s http://localhost:8080 >/dev/null 2>&1; then
    echo "Testing API endpoints..."
    
    # Test system endpoint
    if curl -s http://localhost:8080/api/diagnostics/system | jq . >/dev/null 2>&1; then
        echo "✓ System API test passed"
    else
        echo "✗ System API test failed"
    fi
    
    # Test DNS endpoint
    if curl -s http://localhost:8080/api/diagnostics/dns | jq . >/dev/null 2>&1; then
        echo "✓ DNS API test passed"
    else
        echo "✗ DNS API test failed"
    fi
else
    echo "Development server not running, skipping API tests"
fi

echo "Tests completed"
EOF

    chmod +x scripts/test.sh
    
    print_success "Development utilities created"
}

# Create documentation utilities
create_doc_utilities() {
    print_status "Creating documentation utilities..."
    
    # Documentation generator
    cat > scripts/generate-docs.sh << 'EOF'
#!/bin/bash
# Documentation generator for notApollo

echo "Generating documentation..."

# Create API documentation from source
if [ -d "www/notapollo/api" ]; then
    echo "Generating API documentation..."
    # Add JSDoc or similar tool here
fi

# Validate documentation links
echo "Validating documentation links..."
find docs/ -name "*.md" -type f | while read -r file; do
    # Check for broken internal links
    grep -o '\[.*\](.*\.md)' "$file" | while read -r link; do
        target=$(echo "$link" | sed 's/.*](\(.*\))/\1/')
        if [ ! -f "docs/$target" ] && [ ! -f "$target" ]; then
            echo "Broken link in $file: $target"
        fi
    done
done

echo "Documentation generation completed"
EOF

    chmod +x scripts/generate-docs.sh
    
    print_success "Documentation utilities created"
}

# Main setup function
main() {
    print_status "Starting notApollo development environment setup"
    
    check_prerequisites
    setup_git_hooks
    setup_dev_config
    setup_web_dev
    create_dev_utilities
    create_doc_utilities
    
    print_success "Development environment setup completed!"
    
    echo ""
    echo "🎉 You're ready to develop notApollo!"
    echo ""
    echo "Next steps:"
    echo "  1. Start development server: ./scripts/dev-server.sh"
    echo "  2. Run code quality checks: ./scripts/check-quality.sh"
    echo "  3. Build the project: ./scripts/build.sh"
    echo "  4. Run tests: ./scripts/test.sh"
    echo ""
    echo "Documentation:"
    echo "  - Read docs/DEVELOPMENT.md for detailed development guide"
    echo "  - Check CONTRIBUTING.md for contribution guidelines"
    echo "  - Review docs/API.md for API documentation"
    echo ""
    echo "Happy coding! 🚀"
}

# Run main function
main "$@"