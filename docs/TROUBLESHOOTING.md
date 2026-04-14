# Troubleshooting Guide

This guide helps resolve common issues with the notApollo network diagnostic tool.

## Quick Diagnostics

### Service Status Check

```bash
# Check if notApollo service is running
/etc/init.d/notapollo status

# Check uhttpd web server
ps | grep uhttpd
netstat -tulpn | grep :8080

# Test web interface accessibility
curl -s http://192.168.69.1:8080 | head -5
curl -s http://192.168.70.1:8080 | head -5

# Check API endpoints
curl -s http://192.168.69.1:8080/api/diagnostics/system | jq .status
```

### System Resource Check

```bash
# Check available memory
free -m

# Check disk space
df -h /www

# Check system load
uptime
cat /proc/loadavg

# Check for errors in logs
logread | grep -i error | tail -10
```

## Common Issues

### 1. Web Interface Not Accessible

#### Symptoms
- Cannot access http://192.168.69.1:8080 or http://192.168.70.1:8080
- Connection timeout or refused
- Page not loading

#### Diagnosis
```bash
# Check if uhttpd is running
ps | grep uhttpd

# Check port binding
netstat -tulpn | grep :8080

# Check uhttpd configuration
uci show uhttpd.notapollo

# Check firewall rules
iptables -L | grep 8080
```

#### Solutions

**Solution 1: Restart uhttpd service**
```bash
/etc/init.d/uhttpd restart
```

**Solution 2: Check and fix configuration**
```bash
# Verify configuration
uci show uhttpd.notapollo

# Fix missing configuration
uci set uhttpd.notapollo=uhttpd
uci set uhttpd.notapollo.home='/www/notapollo'
uci add_list uhttpd.notapollo.listen_http='192.168.69.1:8080'
uci add_list uhttpd.notapollo.listen_http='192.168.70.1:8080'
uci commit uhttpd
/etc/init.d/uhttpd restart
```

**Solution 3: Check file permissions**
```bash
# Fix file permissions
chmod -R 644 /www/notapollo/
chmod +x /www/notapollo/api/*.sh
chown -R root:root /www/notapollo/
```

### 2. API Endpoints Returning Errors

#### Symptoms
- API calls return 500 Internal Server Error
- JSON responses contain error messages
- Diagnostic data not updating

#### Diagnosis
```bash
# Test API endpoints directly
curl -v http://192.168.69.1:8080/api/diagnostics/system

# Check script permissions
ls -la /www/notapollo/api/

# Check for missing dependencies
which iwinfo ip ping curl jq

# Check script execution
/www/notapollo/api/system.sh
```

#### Solutions

**Solution 1: Fix script permissions**
```bash
chmod +x /www/notapollo/api/*.sh
```

**Solution 2: Install missing dependencies**
```bash
opkg update
opkg install iwinfo curl jsonfilter
```

**Solution 3: Debug script execution**
```bash
# Run script manually to see errors
sh -x /www/notapollo/api/system.sh
```

### 3. DNS Monitoring Issues

#### Symptoms
- DNS status shows as broken or degraded
- High NextDNS query usage warnings
- Cache performance appears poor

#### Diagnosis
```bash
# Check DNS resolution
nslookup google.com 192.168.69.1
nslookup google.com 192.168.70.1

# Check dnsproxy processes
ps | grep dnsproxy
netstat -tulpn | grep ":535[45]"

# Check dnsmasq configuration
uci show dhcp.@dnsmasq[0] | grep -E "(cachesize|noresolv)"

# Check query counts
grep -c "query" /tmp/dnsmasq.log
grep -c "cached" /tmp/dnsmasq.log
```

#### Solutions

**Solution 1: Restart DNS services**
```bash
/etc/init.d/dnsmasq restart
killall dnsproxy
# Wait for automatic restart or manually restart dnsproxy
```

**Solution 2: Check DNS configuration**
```bash
# Verify dnsmasq is in noresolv mode
uci set dhcp.@dnsmasq[0].noresolv='1'
uci set dhcp.@dnsmasq[0].cachesize='0'
uci commit dhcp
/etc/init.d/dnsmasq restart
```

**Solution 3: Optimize query frequency**
```bash
# Reduce DNS testing frequency if usage is high
uci set notapollo.dns.query_limit_daily='500'
uci set notapollo.dns.cache_optimization='1'
uci commit notapollo
```

### 4. Real-Time Updates Not Working

#### Symptoms
- Dashboard data not refreshing automatically
- Charts not updating with new data
- "Last updated" timestamp not changing

#### Diagnosis
```bash
# Test Server-Sent Events endpoint
curl -N http://192.168.69.1:8080/api/diagnostics/stream

# Check browser console for JavaScript errors
# (Access via browser developer tools)

# Check if data collection scripts are working
/www/notapollo/api/diagnostics.sh
```

#### Solutions

**Solution 1: Check SSE endpoint**
```bash
# Verify SSE is working
timeout 10 curl -N http://192.168.69.1:8080/api/diagnostics/stream
```

**Solution 2: Clear browser cache**
- Hard refresh the page (Ctrl+F5 or Cmd+Shift+R)
- Clear browser cache and cookies
- Try in incognito/private browsing mode

**Solution 3: Check JavaScript errors**
- Open browser developer tools (F12)
- Check Console tab for errors
- Look for network errors in Network tab

### 5. Mobile Interface Issues

#### Symptoms
- Interface not responsive on mobile devices
- Touch targets too small
- Charts not rendering properly on mobile

#### Diagnosis
```bash
# Check if mobile CSS is loading
curl -s http://192.168.69.1:8080/css/app.css | grep -i mobile

# Verify viewport meta tag in HTML
curl -s http://192.168.69.1:8080 | grep viewport
```

#### Solutions

**Solution 1: Clear mobile browser cache**
- Clear cache and data for the browser app
- Try different mobile browser
- Disable any browser extensions

**Solution 2: Check CSS loading**
```bash
# Verify CSS files are accessible
curl -I http://192.168.69.1:8080/css/material3.css
curl -I http://192.168.69.1:8080/css/app.css
```

**Solution 3: Test responsive design**
- Use browser developer tools to simulate mobile
- Test on actual mobile device
- Check for JavaScript errors on mobile

### 6. High Memory Usage

#### Symptoms
- Router becomes slow or unresponsive
- Out of memory errors in logs
- Web interface becomes sluggish

#### Diagnosis
```bash
# Check memory usage
free -m
cat /proc/meminfo

# Check process memory usage
ps aux | sort -k4 -nr | head -10

# Check for memory leaks
cat /proc/slabinfo | grep -E "(size|active)"
```

#### Solutions

**Solution 1: Restart services**
```bash
/etc/init.d/uhttpd restart
/etc/init.d/dnsmasq restart
```

**Solution 2: Optimize configuration**
```bash
# Reduce connection limits
uci set uhttpd.notapollo.max_connections='5'
uci set uhttpd.notapollo.max_requests='3'
uci commit uhttpd
/etc/init.d/uhttpd restart
```

**Solution 3: Clear temporary files**
```bash
# Clean up temporary files
rm -f /tmp/notapollo-*
rm -f /tmp/dnsmasq.log.old
```

### 7. Chart Rendering Issues

#### Symptoms
- Charts not displaying or appearing blank
- Chart data not updating
- JavaScript errors related to Chart.js

#### Diagnosis
```bash
# Check if Chart.js is loading
curl -I http://192.168.69.1:8080/js/lib/chart.min.js

# Check API data format
curl -s http://192.168.69.1:8080/api/diagnostics/all | jq .

# Check browser console for Chart.js errors
```

#### Solutions

**Solution 1: Verify Chart.js library**
```bash
# Check if Chart.js file exists and is readable
ls -la /www/notapollo/js/lib/chart.min.js
```

**Solution 2: Clear browser cache**
- Hard refresh to reload JavaScript files
- Clear browser cache completely
- Disable browser extensions that might interfere

**Solution 3: Check data format**
```bash
# Verify API returns valid JSON
curl -s http://192.168.69.1:8080/api/diagnostics/system | jq .
```

## Performance Issues

### Slow Response Times

#### Diagnosis
```bash
# Check system load
uptime
iostat 1 5

# Check network latency
ping -c 5 192.168.69.1

# Time API responses
time curl -s http://192.168.69.1:8080/api/diagnostics/all > /dev/null
```

#### Solutions

**Solution 1: Optimize data collection**
```bash
# Reduce update frequency
uci set notapollo.general.update_interval='30'
uci commit notapollo
```

**Solution 2: Enable compression**
```bash
# Enable gzip compression in uhttpd
uci set uhttpd.notapollo.compression='1'
uci commit uhttpd
/etc/init.d/uhttpd restart
```

### High CPU Usage

#### Diagnosis
```bash
# Monitor CPU usage
top -n 1
cat /proc/loadavg

# Check for runaway processes
ps aux | sort -k3 -nr | head -10
```

#### Solutions

**Solution 1: Limit concurrent connections**
```bash
uci set uhttpd.notapollo.max_connections='3'
uci commit uhttpd
/etc/init.d/uhttpd restart
```

**Solution 2: Optimize scripts**
```bash
# Check for inefficient commands in scripts
grep -r "while.*sleep" /www/notapollo/api/
```

## Network-Specific Issues

### Primary Network (192.168.69.x) Issues

#### Symptoms
- Can't access interface from primary network
- DNS resolution not working on primary network

#### Solutions
```bash
# Check primary network interface
ip addr show br-lan
ip route show | grep 192.168.69

# Test primary network DNS
nslookup google.com 192.168.69.1
```

### Guest Network (192.168.70.x) Issues

#### Symptoms
- Can't access interface from guest network
- Different behavior between networks

#### Solutions
```bash
# Check guest network interface
ip addr show br-guest
ip route show | grep 192.168.70

# Verify firewall rules allow access
iptables -L | grep 192.168.70
```

## Recovery Procedures

### Complete Service Reset

```bash
#!/bin/sh
# Complete notApollo service reset

echo "Stopping services..."
/etc/init.d/uhttpd stop

echo "Cleaning temporary files..."
rm -f /tmp/notapollo-*
rm -f /var/run/uhttpd.pid

echo "Resetting configuration..."
uci delete uhttpd.notapollo
uci commit uhttpd

echo "Reinstalling configuration..."
uci set uhttpd.notapollo=uhttpd
uci set uhttpd.notapollo.home='/www/notapollo'
uci add_list uhttpd.notapollo.listen_http='192.168.69.1:8080'
uci add_list uhttpd.notapollo.listen_http='192.168.70.1:8080'
uci commit uhttpd

echo "Starting services..."
/etc/init.d/uhttpd start

echo "Verifying functionality..."
sleep 3
if curl -s -f http://127.0.0.1:8080 >/dev/null 2>&1; then
    echo "✓ Service restored successfully"
else
    echo "✗ Service restoration failed"
fi
```

### Factory Reset

```bash
# Remove all notApollo components
opkg remove notapollo
rm -rf /www/notapollo/
uci delete uhttpd.notapollo
uci commit uhttpd
/etc/init.d/uhttpd restart

# Reinstall from scratch
# (Follow installation guide)
```

## Getting Help

### Log Collection

When reporting issues, collect these logs:

```bash
# System logs
logread > /tmp/system.log

# uhttpd logs
cat /var/log/uhttpd.log > /tmp/uhttpd.log

# DNS logs
cat /tmp/dnsmasq.log > /tmp/dns.log

# Configuration dump
uci export > /tmp/config.dump

# System information
cat /proc/cpuinfo > /tmp/system.info
free -m >> /tmp/system.info
df -h >> /tmp/system.info
```

### Diagnostic Information

Include this information when reporting issues:

- OpenWrt version: `cat /etc/openwrt_release`
- Router model: `cat /tmp/sysinfo/model`
- notApollo version: `opkg list-installed | grep notapollo`
- Browser and version
- Network segment (primary/guest)
- Steps to reproduce the issue
- Error messages or symptoms
- Recent changes to configuration

### Support Channels

1. **Documentation**: Check all documentation in the `docs/` directory
2. **GitHub Issues**: Report bugs and request features
3. **GitHub Discussions**: Ask questions and get community help
4. **OpenWrt Forums**: For OpenWrt-specific issues

### Emergency Contacts

For critical production issues:
- Check the deployment guide for emergency procedures
- Use the emergency restart script provided above
- Consider temporary failover to alternative monitoring solutions