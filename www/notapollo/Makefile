# Makefile for notApollo OpenWrt Package
# Builds and packages the diagnostic webpage with local asset bundling

include $(TOPDIR)/rules.mk

PKG_NAME:=notapollo
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/notapollo
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Network diagnostic webpage for OpenWrt
  DEPENDS:=+uhttpd +curl +iwinfo +coreutils-stat
  MAINTAINER:=notApollo Team
endef

define Package/notapollo/description
  A comprehensive network diagnostic webpage with Material 3 design.
  Provides real-time monitoring of WAN, WiFi, DNS, and system health
  with dual network interface support and local asset serving.
  All external dependencies (fonts, icons, libraries) are bundled locally.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./www/* $(PKG_BUILD_DIR)/
	
	# Make build scripts executable
	chmod +x $(PKG_BUILD_DIR)/scripts/*.sh
endef

define Build/Compile
	# Download and bundle local assets
	cd $(PKG_BUILD_DIR) && ./scripts/download-assets.sh
	
	# Verify assets
	cd $(PKG_BUILD_DIR) && ./scripts/verify-assets.sh
	
	# Build production version with minification
	cd $(PKG_BUILD_DIR) && ./scripts/build.sh production
	
	# Use distribution files for packaging
	if [ -d $(PKG_BUILD_DIR)/dist ]; then \
		rm -rf $(PKG_BUILD_DIR)/www_backup; \
		mv $(PKG_BUILD_DIR) $(PKG_BUILD_DIR)/www_backup; \
		mv $(PKG_BUILD_DIR)/www_backup/dist $(PKG_BUILD_DIR); \
		cp -r $(PKG_BUILD_DIR)/www_backup/api $(PKG_BUILD_DIR)/ || true; \
		cp -r $(PKG_BUILD_DIR)/www_backup/config $(PKG_BUILD_DIR)/ || true; \
		cp -r $(PKG_BUILD_DIR)/www_backup/scripts $(PKG_BUILD_DIR)/ || true; \
	fi
endef

define Package/notapollo/install
	$(INSTALL_DIR) $(1)/www/notapollo
	$(CP) $(PKG_BUILD_DIR)/* $(1)/www/notapollo/
	
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./config/uhttpd.conf $(1)/etc/config/uhttpd_notapollo
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./scripts/notapollo $(1)/etc/init.d/notapollo
	
	# Set executable permissions for API and build scripts
	find $(1)/www/notapollo/api -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
	find $(1)/www/notapollo/scripts -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
	
	# Create asset verification on target
	echo "#!/bin/sh" > $(1)/www/notapollo/verify-installation.sh
	echo "# Verify notApollo installation" >> $(1)/www/notapollo/verify-installation.sh
	echo "cd /www/notapollo && ./scripts/verify-assets.sh" >> $(1)/www/notapollo/verify-installation.sh
	chmod +x $(1)/www/notapollo/verify-installation.sh
endef

define Package/notapollo/postinst
#!/bin/sh
if [ -z "${IPKG_INSTROOT}" ]; then
	echo "Configuring notApollo..."
	
	# Verify installation
	if [ -f /www/notapollo/verify-installation.sh ]; then
		echo "Verifying assets..."
		/www/notapollo/verify-installation.sh
	fi
	
	# Restart web server
	/etc/init.d/uhttpd restart
	
	echo "notApollo installed successfully!"
	echo "Access at: http://192.168.69.1:8080 or http://192.168.70.1:8080"
	echo ""
	echo "Asset information:"
	if [ -f /www/notapollo/asset-inventory.json ]; then
		echo "  Asset inventory: /www/notapollo/asset-inventory.json"
	fi
	if [ -f /www/notapollo/build-report.txt ]; then
		echo "  Build report: /www/notapollo/build-report.txt"
	fi
fi
endef

$(eval $(call BuildPackage,notapollo))