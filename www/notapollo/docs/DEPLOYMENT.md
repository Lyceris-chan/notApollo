# Deployment Guide

## OpenWrt Package Installation

### Prerequisites
- OpenWrt router with uhttpd or nginx
- Sufficient storage space (approximately 5MB)
- Network access to both 192.168.69.x and 192.168.70.x segments

### Installation Steps

1. **Copy Files**
   ```bash
   scp -r www/notapollo/ root@192.168.69.1:/www/
   ```

2. **Set Permissions**
   ```bash
   ssh root@192.168.69.1
   chmod +x /www/notapollo/api/*.sh
   chown -R root:root /www/notapollo/
   ```

3. **Configure Web Server**
   
   **For uhttpd:**
   ```bash
   cp /www/notapollo/config/uhttpd.conf /etc/config/uhttpd_notapollo
   /etc/init.d/uhttpd restart
   ```
   
   **For nginx:**
   ```bash
   cp /www/notapollo/config/nginx.conf /etc/nginx/sites-available/notapollo
   ln -s /etc/nginx/sites-available/notapollo /etc/nginx/sites-enabled/
   /etc/init.d/nginx restart
   ```

4. **Verify Installation**
   - Access http://192.168.69.1:8080
   - Access http://192.168.70.1:8080
   - Check API endpoints respond correctly

### Local Asset Setup

1. **Download Google Sans Flex Fonts**
   - Place .woff2 files in `/www/notapollo/fonts/google-sans-flex/`

2. **Download Material Symbols**
   - Place icon fonts in `/www/notapollo/icons/material-symbols/`

3. **Download Chart.js**
   - Replace `/www/notapollo/js/lib/chart.min.js` with actual Chart.js library

### Troubleshooting

- Check uhttpd/nginx logs for errors
- Verify file permissions and ownership
- Ensure network interfaces are properly configured
- Test API endpoints individually

### Security Considerations

- Firewall rules to block WAN access to port 8080
- Regular security updates
- Monitor access logs for suspicious activity
- Implement proper backup procedures