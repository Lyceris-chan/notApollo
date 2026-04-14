# Deployment Guide

This guide covers production deployment of the notApollo network diagnostic tool on OpenWrt routers, including configuration management, monitoring, and maintenance procedures.

## Pre-Deployment Checklist

### System Requirements Verification

- [ ] OpenWrt 22.03+ installed and configured
- [ ] Minimum 32MB flash storage available
- [ ] Minimum 128MB RAM available
- [ ] Dual network interfaces configured (192.168.69.x, 192.168.70.x)
- [ ] uhttpd web server installed and running
- [ ] Required utilities available (iwinfo, ip, ping, curl)

### Network Configuration Verification

- [ ] Primary network (192.168.69.x/24) operational
- [ ] Guest network (192.168.70.x/24) operational and isolated
- [ ] DNS resolution working on both networks
- [ ] NextDNS profiles configured (8753a1, 5414da)
- [ ] dnsproxy instances running on correct ports (5354, 5355)
- [ ] Firewall rules properly configured

### Security Assessment

- [ ] No WAN interface exposure
- [ ] Internal network access controls verified
- [ ] Input validation mechanisms tested
- [ ] Rate limiting configured appropriately
- [ ] Audit logging enabled
- [ ] Security headers implemented

## Deployment Methods

### Method 1: Package-Based Deployment (Recommended)

#### 1. Build Production Package

```bash
# Clone repository
git clone <repository-url>
cd notapollo

# Build OpenWrt package
cd package/notapollo
make clean
make

# Verify package integrity
ls -la *.ipk
opkg info notapollo_*.ipk
```

#### 2. Deploy to Router

```bash
# Copy package to router
scp notapollo_*.ipk root@192.168.69.1:/tmp/

# Install on router
ssh root@192.168.69.1
opkg update
opkg install /tmp/notapollo_*.ipk

# Enable and start service
/etc/init.d/notapollo enable
/etc/init.d/notapollo start
```

#### 3. Verify Deployment

```bash
# Check service status
/etc/init.d/notapollo status

# Verify web interface
curl -s http://192.168.69.1:8080 | head -10
curl -s http://192.168.70.1:8080 | head -10

# Test API endpoints
curl -s http://192.168.69.1:8080/api/diagnostics/system | jq .status
```

### Method 2: Manual Deployment

#### 1. Prepare Assets

```bash
# Build web assets
cd www/notapollo
./scripts/setup-build.sh
./scripts/download-assets.sh
./scripts/build.sh
```

#### 2. Deploy Files

```bash
# Create directory structure on router
ssh root@192.168.69.1 "mkdir -p /www/notapollo"

# Copy web files
scp -r www/notapollo/* root@192.168.69.1:/www/notapollo/

# Set permissions
ssh root@192.168.69.1 "chmod +x /www/notapollo/api/*.sh"
ssh root@192.168.69.1 "chown -R root:root /www/notapollo/"
```

#### 3. Configure Services

```bash
# Configure uhttpd
ssh root@192.168.69.1 << 'EOF'
uci set uhttpd.notapollo=uhttpd
uci set uhttpd.notapollo.home='/www/notapollo'
uci set uhttpd.notapollo.rfc1918_filter='1'
uci set uhttpd.notapollo.max_requests='10'
uci set uhttpd.notapollo.max_connections='20'
uci add_list uhttpd.notapollo.listen_http='192.168.69.1:8080'
uci add_list uhttpd.notapollo.listen_http='192.168.70.1:8080'
uci commit uhttpd
/etc/init.d/uhttpd restart
EOF
```

## Production Configuration

### Performance Optimization

```bash
# Optimize for production load
uci set uhttpd.notapollo.script_timeout='30'
uci set uhttpd.notapollo.network_timeout='10'
uci set uhttpd.notapollo.http_keepalive='20'
uci set uhttpd.notapollo.tcp_keepalive='1'

# Configure caching
uci set uhttpd.notapollo.no_symlinks='1'
uci set uhttpd.notapollo.index_page='index.html'

# Apply configuration
uci commit uhttpd
/etc/init.d/uhttpd restart
```

### Security Hardening

```bash
# Enhanced security settings
uci set uhttpd.notapollo.rfc1918_filter='1'
uci set uhttpd.notapollo.max_requests='5'
uci set uhttpd.notapollo.max_connections='10'

# Disable unnecessary features
uci set uhttpd.notapollo.no_dirlists='1'
uci set uhttpd.notapollo.no_symlinks='1'

# Configure request limits
uci set uhttpd.notapollo.realm='notApollo Diagnostics'
uci set uhttpd.notapollo.config='/etc/httpd.conf'

uci commit uhttpd
/etc/init.d/uhttpd restart
```

### DNS Monitoring Optimization

```bash
# Configure DNS query optimization
uci set notapollo.dns=dns
uci set notapollo.dns.query_limit_daily='1000'
uci set notapollo.dns.cache_optimization='1'
uci set notapollo.dns.smart_scheduling='1'
uci set notapollo.dns.primary_profile='8753a1'
uci set notapollo.dns.dad_profile='5414da'

# Set cache monitoring intervals
uci set notapollo.dns.cache_check_interval='300'
uci set notapollo.dns.performance_threshold='0.8'

uci commit notapollo
```

## Monitoring and Maintenance

### Health Monitoring Setup

```bash
# Create monitoring script
cat > /etc/cron.d/notapollo-monitor << 'EOF'
# Check notApollo service every 5 minutes
*/5 * * * * root /usr/bin/notapollo-healthcheck
EOF

# Create health check script
cat > /usr/bin/notapollo-healthcheck << 'EOF'
#!/bin/sh
# notApollo health check script

# Check web service
if ! curl -s -f http://127.0.0.1:8080 >/dev/null 2>&1; then
    logger -t notapollo "Web service not responding, restarting uhttpd"
    /etc/init.d/uhttpd restart
fi

# Check API endpoints
if ! curl -s -f http://127.0.0.1:8080/api/diagnostics/system >/dev/null 2>&1; then
    logger -t notapollo "API not responding"
fi

# Check disk space
USAGE=$(df /www | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$USAGE" -gt 90 ]; then
    logger -t notapollo "Disk usage high: ${USAGE}%"
fi
EOF

chmod +x /usr/bin/notapollo-healthcheck
```

### Log Management

```bash
# Configure log rotation
cat > /etc/logrotate.d/notapollo << 'EOF'
/var/log/notapollo.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        /etc/init.d/uhttpd reload
    endscript
}
EOF

# Set up centralized logging
uci set system.@system[0].log_ip='192.168.69.10'
uci set system.@system[0].log_port='514'
uci commit system
/etc/init.d/log restart
```

### Performance Monitoring

```bash
# Create performance monitoring script
cat > /usr/bin/notapollo-perfmon << 'EOF'
#!/bin/sh
# Performance monitoring for notApollo

# Log system metrics
echo "$(date): CPU=$(cat /proc/loadavg | cut -d' ' -f1), MEM=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')%" >> /var/log/notapollo-perf.log

# Log DNS query usage
QUERIES=$(grep -c "query" /tmp/dnsmasq.log 2>/dev/null || echo 0)
echo "$(date): DNS_QUERIES=$QUERIES" >> /var/log/notapollo-dns.log

# Log cache performance
CACHE_HITS=$(grep -c "cached" /tmp/dnsmasq.log 2>/dev/null || echo 0)
if [ "$QUERIES" -gt 0 ]; then
    CACHE_RATE=$(echo "scale=2; $CACHE_HITS / $QUERIES * 100" | bc)
    echo "$(date): CACHE_HIT_RATE=${CACHE_RATE}%" >> /var/log/notapollo-dns.log
fi
EOF

chmod +x /usr/bin/notapollo-perfmon

# Add to cron
echo "*/15 * * * * root /usr/bin/notapollo-perfmon" >> /etc/cron.d/notapollo-monitor
```

## Backup and Recovery

### Configuration Backup

```bash
# Create backup script
cat > /usr/bin/notapollo-backup << 'EOF'
#!/bin/sh
BACKUP_DIR="/tmp/notapollo-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup web files
tar -czf "$BACKUP_DIR/www-files.tar.gz" /www/notapollo/

# Backup configuration
uci export uhttpd > "$BACKUP_DIR/uhttpd.conf"
uci export notapollo > "$BACKUP_DIR/notapollo.conf"
uci export dhcp > "$BACKUP_DIR/dhcp.conf"

# Backup logs
cp /var/log/notapollo*.log "$BACKUP_DIR/" 2>/dev/null || true

# Create archive
tar -czf "/tmp/notapollo-backup-$(date +%Y%m%d-%H%M%S).tar.gz" -C /tmp "$(basename $BACKUP_DIR)"
rm -rf "$BACKUP_DIR"

echo "Backup created: /tmp/notapollo-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
EOF

chmod +x /usr/bin/notapollo-backup
```

### Automated Backups

```bash
# Schedule daily backups
echo "0 2 * * * root /usr/bin/notapollo-backup" >> /etc/cron.d/notapollo-monitor

# Cleanup old backups (keep 7 days)
echo "0 3 * * * root find /tmp -name 'notapollo-backup-*.tar.gz' -mtime +7 -delete" >> /etc/cron.d/notapollo-monitor
```

### Recovery Procedures

```bash
# Create recovery script
cat > /usr/bin/notapollo-restore << 'EOF'
#!/bin/sh
if [ -z "$1" ]; then
    echo "Usage: $0 <backup-file.tar.gz>"
    exit 1
fi

BACKUP_FILE="$1"
RESTORE_DIR="/tmp/notapollo-restore-$$"

# Extract backup
mkdir -p "$RESTORE_DIR"
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR"

# Find backup directory
BACKUP_DIR=$(find "$RESTORE_DIR" -name "notapollo-backup-*" -type d | head -1)
if [ -z "$BACKUP_DIR" ]; then
    echo "Invalid backup file"
    exit 1
fi

# Stop services
/etc/init.d/uhttpd stop

# Restore web files
if [ -f "$BACKUP_DIR/www-files.tar.gz" ]; then
    rm -rf /www/notapollo/
    tar -xzf "$BACKUP_DIR/www-files.tar.gz" -C /
fi

# Restore configuration
if [ -f "$BACKUP_DIR/uhttpd.conf" ]; then
    uci import uhttpd < "$BACKUP_DIR/uhttpd.conf"
fi
if [ -f "$BACKUP_DIR/notapollo.conf" ]; then
    uci import notapollo < "$BACKUP_DIR/notapollo.conf"
fi

uci commit
/etc/init.d/uhttpd start

# Cleanup
rm -rf "$RESTORE_DIR"
echo "Restore completed successfully"
EOF

chmod +x /usr/bin/notapollo-restore
```

## Troubleshooting Production Issues

### Common Issues and Solutions

#### Service Not Starting

```bash
# Check service status
/etc/init.d/notapollo status

# Check system logs
logread | grep -i notapollo

# Check uhttpd status
ps | grep uhttpd
netstat -tulpn | grep :8080

# Restart services
/etc/init.d/uhttpd restart
```

#### High Memory Usage

```bash
# Check memory usage
free -m
ps aux | sort -k4 -nr | head -10

# Check for memory leaks
cat /proc/meminfo | grep -E "(MemFree|MemAvailable|Cached)"

# Restart if necessary
/etc/init.d/uhttpd restart
```

#### DNS Query Limit Exceeded

```bash
# Check current usage
grep -c "query" /tmp/dnsmasq.log

# Check cache performance
grep -c "cached" /tmp/dnsmasq.log

# Adjust query frequency
uci set notapollo.dns.query_limit_daily='500'
uci commit notapollo
```

#### Performance Issues

```bash
# Check system load
uptime
cat /proc/loadavg

# Check disk I/O
iostat 1 5

# Check network connections
netstat -an | grep :8080 | wc -l

# Optimize configuration
uci set uhttpd.notapollo.max_connections='5'
uci commit uhttpd
/etc/init.d/uhttpd restart
```

### Emergency Procedures

#### Complete Service Recovery

```bash
# Emergency restart script
cat > /usr/bin/notapollo-emergency-restart << 'EOF'
#!/bin/sh
echo "Emergency restart initiated at $(date)"

# Stop all related services
/etc/init.d/uhttpd stop
killall uhttpd 2>/dev/null

# Clear temporary files
rm -f /tmp/notapollo-*
rm -f /var/run/uhttpd.pid

# Restart services
/etc/init.d/uhttpd start

# Verify functionality
sleep 5
if curl -s -f http://127.0.0.1:8080 >/dev/null 2>&1; then
    echo "Service restored successfully"
else
    echo "Service restoration failed"
    exit 1
fi
EOF

chmod +x /usr/bin/notapollo-emergency-restart
```

#### Factory Reset Recovery

```bash
# Reset to default configuration
uci delete uhttpd.notapollo
uci commit uhttpd

# Reinstall from package
opkg remove notapollo
opkg install /tmp/notapollo_*.ipk

# Reconfigure
/etc/init.d/notapollo enable
/etc/init.d/notapollo start
```

## Scaling and Load Management

### Multi-Router Deployment

For environments with multiple routers:

```bash
# Central configuration management
cat > /usr/bin/notapollo-sync-config << 'EOF'
#!/bin/sh
ROUTERS="192.168.69.1 192.168.70.1"
CONFIG_FILE="/tmp/notapollo-config.tar.gz"

# Create configuration package
tar -czf "$CONFIG_FILE" /etc/config/notapollo /etc/config/uhttpd

# Deploy to all routers
for router in $ROUTERS; do
    scp "$CONFIG_FILE" "root@$router:/tmp/"
    ssh "root@$router" "cd /tmp && tar -xzf notapollo-config.tar.gz && uci commit && /etc/init.d/uhttpd restart"
done
EOF
```

### Load Balancing

```bash
# Configure load balancing (if using multiple instances)
uci set uhttpd.notapollo.max_connections='20'
uci set uhttpd.notapollo.script_timeout='60'
uci set uhttpd.notapollo.network_timeout='30'
uci commit uhttpd
```

## Security Maintenance

### Regular Security Updates

```bash
# Security update script
cat > /usr/bin/notapollo-security-update << 'EOF'
#!/bin/sh
# Update system packages
opkg update
opkg list-upgradable | grep -E "(uhttpd|openssl|libc)" | cut -d' ' -f1 | xargs opkg upgrade

# Check for security advisories
logger -t notapollo "Security update check completed"
EOF

# Schedule monthly security updates
echo "0 4 1 * * root /usr/bin/notapollo-security-update" >> /etc/cron.d/notapollo-monitor
```

### Access Log Analysis

```bash
# Analyze access patterns
cat > /usr/bin/notapollo-analyze-logs << 'EOF'
#!/bin/sh
LOG_FILE="/var/log/uhttpd.log"

if [ -f "$LOG_FILE" ]; then
    # Check for suspicious activity
    grep -E "(POST|PUT|DELETE)" "$LOG_FILE" | tail -20
    
    # Check for high frequency requests
    awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -10
    
    # Check for error patterns
    grep -E "(40[0-9]|50[0-9])" "$LOG_FILE" | tail -10
fi
EOF

chmod +x /usr/bin/notapollo-analyze-logs
```

This deployment guide provides comprehensive procedures for production deployment, monitoring, and maintenance of the notApollo diagnostic tool in enterprise OpenWrt environments.