# Installation Guide

This guide covers the complete installation process for the notApollo network diagnostic tool on OpenWrt routers.

## Prerequisites

### Hardware Requirements
- ASUS RT-AX53U router (or compatible OpenWrt device)
- Minimum 32MB flash storage
- Minimum 128MB RAM
- Dual network interface configuration

### Software Requirements
- OpenWrt 22.03 or later
- uhttpd web server (usually pre-installed)
- Basic shell utilities (ash, grep, awk, sed)
- Network utilities (ping, ip, iwinfo)

### Network Configuration
- Primary network: 192.168.69.x/24
- Guest network: 192.168.70.x/24
- Router accessible on both interfaces

## Installation Methods

### Method 1: OpenWrt Package Installation (Recommended)

1. **Build the package:**
   ```bash
   cd package/notapollo
   make
   ```

2. **Install the package:**
   ```bash
   opkg install notapollo_*.ipk
   ```

3. **Enable the service:**
   ```bash
   /etc/init.d/notapollo enable
   /etc/init.d/notapollo start
   ```

### Method 2: Manual Installation

1. **Copy web files:**
   ```bash
   cd www/notapollo
   make install
   ```

2. **Configure uhttpd:**
   ```bash
   uci set uhttpd.notapollo=uhttpd
   uci set uhttpd.notapollo.home='/www/notapollo'
   uci add_list uhttpd.notapollo.listen_http='192.168.69.1:8080'
   uci add_list uhttpd.notapollo.listen_http='192.168.70.1:8080'
   uci commit uhttpd
   /etc/init.d/uhttpd restart
   ```

3. **Set up diagnostic scripts:**
   ```bash
   chmod +x /www/notapollo/api/*.sh
   ```

## Post-Installation Setup

### 1. Verify Installation

Access the diagnostic interface:
- Primary network: http://192.168.69.1:8080
- Guest network: http://192.168.70.1:8080

### 2. Configure DNS Monitoring

The system automatically detects your DNS configuration. For optimal performance:

```bash
# Verify dnsproxy instances are running
netstat -tulpn | grep ":535[45]"

# Check dnsmasq configuration
uci show dhcp.@dnsmasq[0] | grep -E "(cachesize|noresolv)"
```

### 3. Test Functionality

1. **System Health**: Verify uptime and system information display
2. **Network Tests**: Check WAN connectivity and WiFi status
3. **DNS Resolution**: Test both network segments
4. **Charts**: Confirm real-time data visualization works
5. **Mobile Access**: Test responsive interface on mobile devices

### 4. Security Configuration

```bash
# Set up basic access controls (optional)
uci set uhttpd.notapollo.rfc1918_filter='1'
uci set uhttpd.notapollo.max_requests='10'
uci set uhttpd.notapollo.max_connections='20'
uci commit uhttpd
/etc/init.d/uhttpd restart
```

## Troubleshooting Installation

### Common Issues

#### Service Not Starting
```bash
# Check service status
/etc/init.d/notapollo status

# Check logs
logread | grep notapollo

# Manual start with debugging
/etc/init.d/notapollo start
```

#### Web Interface Not Accessible
```bash
# Verify uhttpd is running
ps | grep uhttpd

# Check port binding
netstat -tulpn | grep :8080

# Test local access
wget -O - http://127.0.0.1:8080 2>/dev/null | head -10
```

#### Missing Dependencies
```bash
# Install required packages
opkg update
opkg install uhttpd-mod-ubus
opkg install iwinfo
opkg install curl
```

#### Permission Issues
```bash
# Fix script permissions
chmod +x /www/notapollo/api/*.sh
chown -R root:root /www/notapollo/
```

### DNS Monitoring Issues

#### High Query Usage
```bash
# Check current query count
grep -c "query" /tmp/dnsmasq.log

# Verify cache hit rates
grep "cached" /tmp/dnsmasq.log | wc -l
```

#### Cache Performance Problems
```bash
# Check dnsproxy status
ps | grep dnsproxy

# Verify cache configuration
cat /etc/config/dhcp | grep -A 10 dnsproxy
```

## Advanced Configuration

### Custom Port Configuration

To use a different port:

```bash
uci set uhttpd.notapollo.listen_http='192.168.69.1:9090'
uci set uhttpd.notapollo.listen_http='192.168.70.1:9090'
uci commit uhttpd
/etc/init.d/uhttpd restart
```

### SSL/HTTPS Setup

For secure access:

```bash
# Generate self-signed certificate
openssl req -x509 -newkey rsa:2048 -keyout /etc/notapollo.key -out /etc/notapollo.crt -days 365 -nodes

# Configure HTTPS
uci set uhttpd.notapollo.listen_https='192.168.69.1:8443'
uci set uhttpd.notapollo.listen_https='192.168.70.1:8443'
uci set uhttpd.notapollo.cert='/etc/notapollo.crt'
uci set uhttpd.notapollo.key='/etc/notapollo.key'
uci commit uhttpd
/etc/init.d/uhttpd restart
```

### Performance Tuning

For better performance on resource-constrained devices:

```bash
# Reduce update frequency
uci set notapollo.general.update_interval='30'

# Limit concurrent connections
uci set uhttpd.notapollo.max_connections='5'

# Enable compression
uci set uhttpd.notapollo.compression='1'

uci commit
/etc/init.d/uhttpd restart
```

## Uninstallation

### Package Removal
```bash
opkg remove notapollo
```

### Manual Cleanup
```bash
# Remove web files
rm -rf /www/notapollo/

# Remove uhttpd configuration
uci delete uhttpd.notapollo
uci commit uhttpd
/etc/init.d/uhttpd restart

# Remove service files
rm -f /etc/init.d/notapollo
rm -f /etc/config/notapollo
```

## Backup and Restore

### Backup Configuration
```bash
# Backup web files
tar -czf notapollo-backup.tar.gz /www/notapollo/

# Backup configuration
uci export uhttpd > uhttpd-backup.conf
uci export notapollo > notapollo-backup.conf
```

### Restore Configuration
```bash
# Restore web files
tar -xzf notapollo-backup.tar.gz -C /

# Restore configuration
uci import uhttpd < uhttpd-backup.conf
uci import notapollo < notapollo-backup.conf
uci commit
```

## Next Steps

After successful installation:

1. Read the [User Guide](USER_GUIDE.md) to learn how to use the interface
2. Check the [Configuration Guide](CONFIGURATION.md) for customization options
3. Review the [Troubleshooting Guide](TROUBLESHOOTING.md) for common issues
4. Consider setting up [automated monitoring](MONITORING.md) for production use

## Support

If you encounter issues during installation:

1. Check the troubleshooting section above
2. Review system logs: `logread | grep -i error`
3. Verify network connectivity and DNS resolution
4. Consult the project documentation or file an issue