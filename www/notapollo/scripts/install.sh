#!/bin/sh
# notApollo Installation Script for OpenWrt
# Automates the installation and configuration process

set -e

INSTALL_DIR="/www/notapollo"
BACKUP_DIR="/tmp/notapollo_backup_$(date +%Y%m%d_%H%M%S)"

echo "=== notApollo Installation Script ==="
echo "Installing to: $INSTALL_DIR"

# Create backup if existing installation
if [ -d "$INSTALL_DIR" ]; then
    echo "Backing up existing installation to: $BACKUP_DIR"
    cp -r "$INSTALL_DIR" "$BACKUP_DIR"
fi

# Set proper permissions
echo "Setting file permissions..."
find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;
chown -R root:root "$INSTALL_DIR"

# Configure uhttpd
echo "Configuring uhttpd..."
if [ -f "$INSTALL_DIR/config/uhttpd.conf" ]; then
    cp "$INSTALL_DIR/config/uhttpd.conf" /etc/config/uhttpd_notapollo
    echo "uhttpd configuration installed"
fi

# Restart web server
echo "Restarting web server..."
/etc/init.d/uhttpd restart

# Verify installation
echo "Verifying installation..."
if curl -s http://192.168.69.1:8080 > /dev/null; then
    echo "✓ Primary network access working"
else
    echo "✗ Primary network access failed"
fi

if curl -s http://192.168.70.1:8080 > /dev/null; then
    echo "✓ Dad's network access working"
else
    echo "✗ Dad's network access failed"
fi

echo "=== Installation Complete ==="
echo "Access notApollo at:"
echo "  Primary Network: http://192.168.69.1:8080"
echo "  Dad's Network:   http://192.168.70.1:8080"