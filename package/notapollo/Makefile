# OpenWrt Package Makefile for notApollo
# Comprehensive network diagnostic webpage with local asset bundling
# Integrates with the build system for complete offline operation

include $(TOPDIR)/rules.mk

PKG_NAME:=notapollo
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=notApollo Team <team@notapollo.dev>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_DIR:=$(CURDIR)/../../www/notapollo

# Build dependencies for asset downloading and processing
PKG_BUILD_DEPENDS:=curl/host

include $(INCLUDE_DIR)/package.mk

define Package/notapollo
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Network diagnostic webpage with Material 3 design
  URL:=https://github.com/notapollo/notapollo
  DEPENDS:=+uhttpd +curl +iwinfo +ip-full +bind-dig +coreutils-stat +coreutils-timeout +procps-ng-ps +logread
  PKGARCH:=all
endef

define Package/notapollo/description
  notApollo is a comprehensive network diagnostic webpage for OpenWrt routers.
  
  Features:
  - Material 3 dark theme design with Google Sans Flex typography
  - Dual network interface support (192.168.69.1:8080, 192.168.70.1:8080)
  - Real-time monitoring of WAN, WiFi, DNS, and system health
  - Smart DNS optimization with cache integration and NextDNS query management
  - User-friendly language for non-technical users
  - ONT/Fiber troubleshooting guidance with LED status interpretation
  - Safe router reboot with 5-second countdown confirmation
  - Local asset serving (fonts, icons, libraries) for offline operation
  - Cross-layer network intelligence and correlation
  - Mobile-optimized responsive design with touch-friendly interactions
  - Production-ready error handling and security features
  
  All external dependencies are bundled locally during build for reliable operation
  without internet connectivity requirements.
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	
	# Copy source files from www/notapollo directory
	$(CP) $(PKG_SOURCE_DIR)/* $(PKG_BUILD_DIR)/
	
	# Copy package-specific files
	$(CP) $(CURDIR)/files/* $(PKG_BUILD_DIR)/
	
	# Make build scripts executable
	find $(PKG_BUILD_DIR)/scripts -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
endef

define Build/Compile
	# === Local Asset Bundling Phase ===
	# Download and bundle all external assets for offline operation
	
	cd $(PKG_BUILD_DIR) && \
	echo "=== Downloading Google Sans Flex fonts, Material Symbols icons, and Chart.js ===" && \
	./scripts/download-assets.sh || { \
		echo "Asset download failed, checking for cached assets..."; \
		if [ ! -f fonts/google-sans-flex/GoogleSansFlex-Regular.woff2 ] || \
		   [ ! -f icons/material-symbols/material-symbols-outlined.woff2 ] || \
		   [ ! -f js/lib/chart.min.js ]; then \
			echo "ERROR: Required assets missing and download failed"; \
			echo "Please ensure internet connectivity during build or provide cached assets"; \
			exit 1; \
		else \
			echo "Using existing cached assets"; \
		fi; \
	}
	
	# Verify asset integrity and generate inventory
	cd $(PKG_BUILD_DIR) && \
	echo "=== Verifying asset integrity ===" && \
	./scripts/verify-assets.sh || { \
		echo "ERROR: Asset verification failed"; \
		echo "Assets may be corrupted or incomplete"; \
		exit 1; \
	}
	
	# Build production version with minification and optimization
	cd $(PKG_BUILD_DIR) && \
	echo "=== Building production version ===" && \
	./scripts/build.sh production || { \
		echo "ERROR: Production build failed"; \
		exit 1; \
	}
	
	# Use distribution files if build created them
	if [ -d $(PKG_BUILD_DIR)/dist ]; then \
		echo "=== Using optimized distribution files ==="; \
		rm -rf $(PKG_BUILD_DIR)/www_source; \
		mv $(PKG_BUILD_DIR) $(PKG_BUILD_DIR)_temp; \
		mv $(PKG_BUILD_DIR)_temp/dist $(PKG_BUILD_DIR); \
		cp -r $(PKG_BUILD_DIR)_temp/api $(PKG_BUILD_DIR)/ 2>/dev/null || true; \
		cp -r $(PKG_BUILD_DIR)_temp/config $(PKG_BUILD_DIR)/ 2>/dev/null || true; \
		cp -r $(PKG_BUILD_DIR)_temp/scripts $(PKG_BUILD_DIR)/ 2>/dev/null || true; \
		cp -r $(PKG_BUILD_DIR)_temp/docs $(PKG_BUILD_DIR)/ 2>/dev/null || true; \
		cp $(PKG_BUILD_DIR)_temp/*.md $(PKG_BUILD_DIR)/ 2>/dev/null || true; \
		cp $(PKG_BUILD_DIR)_temp/asset-inventory.json $(PKG_BUILD_DIR)/ 2>/dev/null || true; \
		cp $(PKG_BUILD_DIR)_temp/build-report.txt $(PKG_BUILD_DIR)/ 2>/dev/null || true; \
		cp $(PKG_BUILD_DIR)_temp/version.json $(PKG_BUILD_DIR)/ 2>/dev/null || true; \
		rm -rf $(PKG_BUILD_DIR)_temp; \
	fi
	
	# Final verification of build output
	echo "=== Final build verification ==="
	if [ ! -f $(PKG_BUILD_DIR)/index.html ]; then \
		echo "ERROR: index.html not found in build output"; \
		exit 1; \
	fi
	
	# Verify API scripts are present and executable
	if [ -d $(PKG_BUILD_DIR)/api ]; then \
		find $(PKG_BUILD_DIR)/api -name "*.sh" -exec chmod +x {} \; ; \
		echo "API scripts prepared"; \
	else \
		echo "WARNING: API directory not found"; \
	fi
	
	# Create build metadata
	echo "notApollo OpenWrt Package" > $(PKG_BUILD_DIR)/BUILD_INFO.txt
	echo "Build Date: $$(date -u)" >> $(PKG_BUILD_DIR)/BUILD_INFO.txt
	echo "Package Version: $(PKG_VERSION)-$(PKG_RELEASE)" >> $(PKG_BUILD_DIR)/BUILD_INFO.txt
	echo "Local Assets: Bundled" >> $(PKG_BUILD_DIR)/BUILD_INFO.txt
	echo "Build Type: Production (Minified)" >> $(PKG_BUILD_DIR)/BUILD_INFO.txt
	
	echo "=== Build Complete ==="
endef

define Package/notapollo/install
	# === Web Application Installation ===
	$(INSTALL_DIR) $(1)/www/notapollo
	$(CP) $(PKG_BUILD_DIR)/* $(1)/www/notapollo/
	
	# Remove build-only files from target
	rm -f $(1)/www/notapollo/Makefile 2>/dev/null || true
	rm -rf $(1)/www/notapollo/build 2>/dev/null || true
	rm -rf $(1)/www/notapollo/.git* 2>/dev/null || true
	
	# === Configuration Files ===
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/etc/config/notapollo $(1)/etc/config/notapollo
	
	# === Service Management ===
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/etc/init.d/notapollo $(1)/etc/init.d/notapollo
	
	# === uhttpd Configuration for Dual Interface ===
	$(INSTALL_DIR) $(1)/etc/uhttpd
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/config/uhttpd.conf $(1)/etc/uhttpd/notapollo 2>/dev/null || \
	echo "# notApollo uhttpd configuration" > $(1)/etc/uhttpd/notapollo
	
	# === Set Proper Permissions ===
	# API scripts must be executable
	find $(1)/www/notapollo/api -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
	
	# Build and maintenance scripts
	find $(1)/www/notapollo/scripts -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
	
	# Ensure web files have correct permissions
	find $(1)/www/notapollo -type f -name "*.html" -exec chmod 644 {} \; 2>/dev/null || true
	find $(1)/www/notapollo -type f -name "*.css" -exec chmod 644 {} \; 2>/dev/null || true
	find $(1)/www/notapollo -type f -name "*.js" -exec chmod 644 {} \; 2>/dev/null || true
	find $(1)/www/notapollo -type f -name "*.json" -exec chmod 644 {} \; 2>/dev/null || true
	find $(1)/www/notapollo -type f -name "*.woff2" -exec chmod 644 {} \; 2>/dev/null || true
	find $(1)/www/notapollo -type f -name "*.ico" -exec chmod 644 {} \; 2>/dev/null || true
	find $(1)/www/notapollo -type f -name "*.png" -exec chmod 644 {} \; 2>/dev/null || true
	
	# === Installation Verification Script ===
	echo "#!/bin/sh" > $(1)/www/notapollo/verify-installation.sh
	echo "# notApollo Installation Verification" >> $(1)/www/notapollo/verify-installation.sh
	echo "echo 'Verifying notApollo installation...'" >> $(1)/www/notapollo/verify-installation.sh
	echo "cd /www/notapollo" >> $(1)/www/notapollo/verify-installation.sh
	echo "if [ -f scripts/verify-assets.sh ]; then" >> $(1)/www/notapollo/verify-installation.sh
	echo "  ./scripts/verify-assets.sh" >> $(1)/www/notapollo/verify-installation.sh
	echo "else" >> $(1)/www/notapollo/verify-installation.sh
	echo "  echo 'Basic verification: checking core files...'" >> $(1)/www/notapollo/verify-installation.sh
	echo "  [ -f index.html ] && echo 'OK: index.html found' || echo 'ERROR: index.html missing'" >> $(1)/www/notapollo/verify-installation.sh
	echo "  [ -d api ] && echo 'OK: API directory found' || echo 'ERROR: API directory missing'" >> $(1)/www/notapollo/verify-installation.sh
	echo "  [ -f css/app.css ] || [ -f css/app.min.css ] && echo 'OK: CSS found' || echo 'ERROR: CSS missing'" >> $(1)/www/notapollo/verify-installation.sh
	echo "  [ -f js/app.js ] || [ -f js/app.min.js ] && echo 'OK: JavaScript found' || echo 'ERROR: JavaScript missing'" >> $(1)/www/notapollo/verify-installation.sh
	echo "fi" >> $(1)/www/notapollo/verify-installation.sh
	echo "echo 'Verification complete.'" >> $(1)/www/notapollo/verify-installation.sh
	chmod +x $(1)/www/notapollo/verify-installation.sh
	
	# === Create Asset Information Display ===
	echo "#!/bin/sh" > $(1)/www/notapollo/show-build-info.sh
	echo "# Display notApollo build and asset information" >> $(1)/www/notapollo/show-build-info.sh
	echo "echo '=== notApollo Build Information ==='" >> $(1)/www/notapollo/show-build-info.sh
	echo "[ -f /www/notapollo/BUILD_INFO.txt ] && cat /www/notapollo/BUILD_INFO.txt" >> $(1)/www/notapollo/show-build-info.sh
	echo "echo ''" >> $(1)/www/notapollo/show-build-info.sh
	echo "echo '=== Asset Inventory ==='" >> $(1)/www/notapollo/show-build-info.sh
	echo "[ -f /www/notapollo/asset-inventory.json ] && echo 'Asset inventory: /www/notapollo/asset-inventory.json'" >> $(1)/www/notapollo/show-build-info.sh
	echo "[ -f /www/notapollo/build-report.txt ] && echo 'Build report: /www/notapollo/build-report.txt'" >> $(1)/www/notapollo/show-build-info.sh
	echo "[ -f /www/notapollo/version.json ] && echo 'Version info: /www/notapollo/version.json'" >> $(1)/www/notapollo/show-build-info.sh
	echo "echo ''" >> $(1)/www/notapollo/show-build-info.sh
	echo "echo '=== Directory Size ==='" >> $(1)/www/notapollo/show-build-info.sh
	echo "du -sh /www/notapollo 2>/dev/null || echo 'Size calculation unavailable'" >> $(1)/www/notapollo/show-build-info.sh
	chmod +x $(1)/www/notapollo/show-build-info.sh
endef

define Package/notapollo/postinst
#!/bin/sh
# Post-installation configuration and verification

if [ -z "$${IPKG_INSTROOT}" ]; then
	echo "=== Configuring notApollo Network Diagnostic Webpage ==="
	
	# Verify installation integrity
	echo "Verifying installation..."
	if [ -x /www/notapollo/verify-installation.sh ]; then
		/www/notapollo/verify-installation.sh
	else
		echo "Basic verification..."
		[ -f /www/notapollo/index.html ] && echo "✓ Core files installed" || echo "✗ Installation incomplete"
	fi
	
	# Display build information
	if [ -x /www/notapollo/show-build-info.sh ]; then
		/www/notapollo/show-build-info.sh
	fi
	
	# Configure and start service
	echo ""
	echo "Configuring service..."
	
	# Enable and start the service
	/etc/init.d/notapollo enable
	
	# Check if uhttpd is running and restart it to pick up new configuration
	if /etc/init.d/uhttpd status >/dev/null 2>&1; then
		echo "Restarting uhttpd to apply notApollo configuration..."
		/etc/init.d/uhttpd restart
	fi
	
	# Start notApollo service
	/etc/init.d/notapollo start
	
	# Wait a moment for service to start
	sleep 2
	
	# Verify service is running
	if /etc/init.d/notapollo status >/dev/null 2>&1; then
		echo "✓ notApollo service started successfully"
	else
		echo "⚠ Service start may have failed, check logs with: logread | grep notapollo"
	fi
	
	echo ""
	echo "=== Installation Complete ==="
	echo "notApollo is now available at:"
	echo "  Primary Network: http://192.168.69.1:8080"
	echo "  Dad's Network:   http://192.168.70.1:8080"
	echo ""
	echo "Features enabled:"
	echo "  ✓ Material 3 dark theme design"
	echo "  ✓ Dual network interface serving"
	echo "  ✓ Real-time diagnostic monitoring"
	echo "  ✓ Smart DNS optimization with cache integration"
	echo "  ✓ User-friendly language for non-technical users"
	echo "  ✓ ONT/Fiber troubleshooting guidance"
	echo "  ✓ Safe router reboot with countdown"
	echo "  ✓ Local asset serving (offline capable)"
	echo "  ✓ Mobile-optimized responsive design"
	echo "  ✓ Production-ready error handling"
	echo ""
	echo "Configuration: /etc/config/notapollo"
	echo "Service management: /etc/init.d/notapollo {start|stop|restart|status}"
	echo "Asset verification: /www/notapollo/verify-installation.sh"
	echo "Build information: /www/notapollo/show-build-info.sh"
	echo ""
	echo "For troubleshooting, check system logs: logread | grep -E '(notapollo|uhttpd)'"
fi
endef

define Package/notapollo/prerm
#!/bin/sh
# Pre-removal cleanup

if [ -z "$${IPKG_INSTROOT}" ]; then
	echo "Stopping notApollo service..."
	/etc/init.d/notapollo stop 2>/dev/null || true
	/etc/init.d/notapollo disable 2>/dev/null || true
	
	echo "notApollo service stopped and disabled"
	echo "Web files will be removed after package removal"
fi
endef

define Package/notapollo/postrm
#!/bin/sh
# Post-removal cleanup

if [ -z "$${IPKG_INSTROOT}" ]; then
	echo "Cleaning up notApollo configuration..."
	
	# Remove configuration files if they exist
	rm -f /etc/uhttpd/notapollo 2>/dev/null || true
	
	# Restart uhttpd to remove notApollo configuration
	if /etc/init.d/uhttpd status >/dev/null 2>&1; then
		echo "Restarting uhttpd to remove notApollo configuration..."
		/etc/init.d/uhttpd restart
	fi
	
	echo "notApollo has been completely removed"
	echo "Configuration backup may remain in /etc/config/notapollo-opkg"
fi
endef

# Package configuration backup
define Package/notapollo/conffiles
/etc/config/notapollo
endef

$(eval $(call BuildPackage,notapollo))