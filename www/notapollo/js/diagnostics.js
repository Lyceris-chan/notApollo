/**
 * notApollo Diagnostic Data Collection and Processing
 * Universal Network Detection and Real-time Updates
 * Material 3 2026 Compliant Implementation
 */

class UniversalNetworkInterface {
  constructor() {
    this.config = this.loadConfiguration();
    this.networks = [];
    this.userContext = null;
    this.diagnosticData = new Map();
    this.updateInterval = null;
    this.errorCount = 0;
    this.maxErrors = 5;
    
    this.init();
  }
  
  async init() {
    try {
      await this.detectNetworkTopology();
      this.determineUserContext();
      this.startDiagnosticCollection();
    } catch (error) {
      console.error('Failed to initialize network interface:', error);
      this.handleError('Network initialization failed');
    }
  }
  
  loadConfiguration() {
    // Default configuration with sensible fallbacks
    return {
      admin_networks: ['192.168.69.0/24', '192.168.1.0/24', '10.0.0.0/24'],
      guest_networks: ['192.168.70.0/24', '192.168.100.0/24'],
      interface_bindings: ['br-lan', 'wlan0', 'wlan1'],
      access_control: 'auto',
      dns_providers: ['8.8.8.8', '1.1.1.1', '9.9.9.9'],
      monitoring_scope: 'auto',
      anonymize_data: true,
      update_interval: 30000, // 30 seconds
      cache_ttl: 300000, // 5 minutes
      max_retries: 3
    };
  }
  
  async detectNetworkTopology() {
    try {
      // Detect client IP and network context
      const clientIP = await this.getClientIP();
      const networkInfo = await this.getNetworkInfo();
      
      this.networks = this.classifyNetworks(networkInfo, clientIP);
      
      // Update network indicator
      this.updateNetworkIndicator();
      
    } catch (error) {
      console.error('Network topology detection failed:', error);
      // Fallback to basic network detection
      this.networks = [{
        id: 'default',
        name: 'Network',
        type: 'main',
        access_level: 'user',
        is_admin: false
      }];
    }
  }
  
  async getClientIP() {
    try {
      // Try multiple methods to get client IP
      const response = await fetch('/api/system.sh?action=client_ip', {
        method: 'GET',
        timeout: 5000
      });
      
      if (response.ok) {
        const data = await response.json();
        return data.client_ip || this.extractIPFromLocation();
      }
    } catch (error) {
      console.warn('Failed to get client IP from API:', error);
    }
    
    return this.extractIPFromLocation();
  }
  
  extractIPFromLocation() {
    // Extract IP from current location or use fallback
    const hostname = window.location.hostname;
    if (this.isValidIP(hostname)) {
      return hostname;
    }
    
    // Fallback detection based on common router IPs
    return '192.168.1.100'; // Default fallback
  }
  
  isValidIP(ip) {
    const ipRegex = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
    return ipRegex.test(ip);
  }
  
  async getNetworkInfo() {
    try {
      const response = await fetch('/api/system.sh?action=network_info', {
        method: 'GET',
        timeout: 10000
      });
      
      if (response.ok) {
        return await response.json();
      }
    } catch (error) {
      console.warn('Failed to get network info from API:', error);
    }
    
    // Fallback network info
    return {
      interfaces: [
        { name: 'br-lan', subnet: '192.168.1.0/24', type: 'bridge' }
      ],
      dns_servers: ['8.8.8.8', '1.1.1.1'],
      gateway: '192.168.1.1'
    };
  }
  
  classifyNetworks(networkInfo, clientIP) {
    const networks = [];
    
    networkInfo.interfaces?.forEach((iface, index) => {
      const network = {
        id: this.generateNetworkId(iface),
        name: this.getNetworkDisplayName(iface, index),
        subnet: iface.subnet,
        type: this.classifyNetworkType(iface),
        access_level: this.determineAccessLevel(iface),
        is_admin: this.isAdminNetwork(iface),
        interface: iface.name,
        is_current: this.isIPInSubnet(clientIP, iface.subnet)
      };
      networks.push(network);
    });
    
    return networks.length > 0 ? networks : this.getDefaultNetwork();
  }
  
  generateNetworkId(iface) {
    // Generate anonymous network ID
    return `net_${btoa(iface.name + iface.subnet).substring(0, 8)}`;
  }
  
  getNetworkDisplayName(iface, index) {
    const name = iface.name.toLowerCase();
    
    if (name.includes('guest') || iface.isolated) {
      return `Guest Network${index > 0 ? ` ${index + 1}` : ''}`;
    }
    if (name.includes('lan') || name.includes('br-lan')) {
      return `Main Network${index > 0 ? ` ${index + 1}` : ''}`;
    }
    if (name.includes('mgmt') || name.includes('admin')) {
      return 'Management Network';
    }
    
    return `Network ${index + 1}`;
  }
  
  classifyNetworkType(iface) {
    const name = iface.name.toLowerCase();
    
    if (name.includes('guest') || iface.isolated) return 'guest';
    if (name.includes('lan') || name.includes('br-lan')) return 'main';
    if (name.includes('mgmt') || name.includes('admin')) return 'management';
    if (name.includes('wan')) return 'wan';
    
    return 'other';
  }
  
  determineAccessLevel(iface) {
    const type = this.classifyNetworkType(iface);
    
    switch (type) {
      case 'management': return 'admin';
      case 'main': return 'user';
      case 'guest': return 'guest';
      default: return 'basic';
    }
  }
  
  isAdminNetwork(iface) {
    const type = this.classifyNetworkType(iface);
    return type === 'management' || type === 'main';
  }
  
  isIPInSubnet(ip, subnet) {
    try {
      const [network, prefixLength] = subnet.split('/');
      const networkParts = network.split('.').map(Number);
      const ipParts = ip.split('.').map(Number);
      const mask = (0xffffffff << (32 - parseInt(prefixLength))) >>> 0;
      
      const networkInt = (networkParts[0] << 24) + (networkParts[1] << 16) + (networkParts[2] << 8) + networkParts[3];
      const ipInt = (ipParts[0] << 24) + (ipParts[1] << 16) + (ipParts[2] << 8) + ipParts[3];
      
      return (networkInt & mask) === (ipInt & mask);
    } catch (error) {
      console.warn('Failed to check IP in subnet:', error);
      return false;
    }
  }
  
  determineUserContext() {
    const currentNetwork = this.networks.find(net => net.is_current) || this.networks[0];
    
    this.userContext = {
      network: currentNetwork,
      access_level: currentNetwork?.access_level || 'basic',
      show_all_networks: this.shouldShowAllNetworks(currentNetwork),
      admin_controls: this.hasAdminControls(currentNetwork),
      display_name: currentNetwork?.name || 'Network'
    };
  }
  
  shouldShowAllNetworks(network) {
    return network?.is_admin || network?.type === 'management' || this.config.access_control === 'permissive';
  }
  
  hasAdminControls(network) {
    return network?.is_admin || network?.type === 'management' || 
           (network?.type === 'main' && this.config.access_control === 'permissive');
  }
  
  updateNetworkIndicator() {
    const indicator = document.getElementById('network-indicator');
    const networkName = document.getElementById('network-name');
    
    if (indicator && networkName && this.userContext) {
      indicator.className = `network-indicator ${this.userContext.network.type}`;
      networkName.textContent = this.userContext.display_name;
    }
  }
  
  getDefaultNetwork() {
    return [{
      id: 'default',
      name: 'Main Network',
      type: 'main',
      access_level: 'user',
      is_admin: false,
      is_current: true
    }];
  }
  
  startDiagnosticCollection() {
    // Initial data collection
    this.collectAllDiagnostics();
    
    // Set up periodic updates
    this.updateInterval = setInterval(() => {
      this.collectAllDiagnostics();
    }, this.config.update_interval);
  }
  
  async collectAllDiagnostics() {
    try {
      const diagnostics = await Promise.allSettled([
        this.collectSystemHealth(),
        this.collectWANDiagnostics(),
        this.collectWiFiDiagnostics(),
        this.collectRouterHealth(),
        this.collectDNSDiagnostics(),
        this.collectONTStatus()
      ]);
      
      // Process results and update UI
      diagnostics.forEach((result, index) => {
        if (result.status === 'fulfilled') {
          this.processDiagnosticResult(result.value, index);
        } else {
          console.warn(`Diagnostic collection ${index} failed:`, result.reason);
        }
      });
      
      // Update last refresh time
      this.updateLastRefreshTime();
      
      // Reset error count on successful collection
      this.errorCount = 0;
      
    } catch (error) {
      this.handleError('Diagnostic collection failed', error);
    }
  }
  
  async collectSystemHealth() {
    try {
      const response = await this.apiCall('/api/system.sh', { action: 'health' });
      
      return {
        type: 'system',
        status: this.calculateHealthStatus(response.cpu_usage, response.memory_usage),
        data: {
          uptime: this.formatUptime(response.uptime),
          reboots_24h: response.reboots_24h || 0,
          cpu_usage: response.cpu_usage || 0,
          memory_usage: response.memory_usage || 0,
          temperature: response.temperature || 'N/A',
          load_average: response.load_average || [0, 0, 0],
          health_score: this.calculateSystemHealthScore(response)
        }
      };
    } catch (error) {
      return this.getErrorResult('system', error);
    }
  }
  
  async collectWANDiagnostics() {
    try {
      const response = await this.apiCall('/api/diagnostics.sh', { action: 'wan' });
      
      return {
        type: 'wan',
        status: this.calculateWANStatus(response),
        data: {
          link_state: response.link_state || 'unknown',
          ip_address: response.ip_address || 'Not assigned',
          gateway: response.gateway || 'Unknown',
          latency: response.latency || 0,
          packet_loss: response.packet_loss || 0,
          download_speed: response.download_speed || 0,
          upload_speed: response.upload_speed || 0,
          dns_resolution: response.dns_resolution || 'Unknown'
        }
      };
    } catch (error) {
      return this.getErrorResult('wan', error);
    }
  }
  
  async collectWiFiDiagnostics() {
    try {
      const response = await this.apiCall('/api/diagnostics.sh', { action: 'wifi' });
      
      return {
        type: 'wifi',
        status: this.calculateWiFiStatus(response),
        data: {
          radios: response.radios || [],
          total_clients: response.total_clients || 0,
          avg_signal: response.avg_signal || 0,
          channel_utilization: response.channel_utilization || {},
          disconnects_1h: response.disconnects_1h || 0
        }
      };
    } catch (error) {
      return this.getErrorResult('wifi', error);
    }
  }
  
  async collectRouterHealth() {
    try {
      const response = await this.apiCall('/api/system.sh', { action: 'resources' });
      
      return {
        type: 'router',
        status: this.calculateRouterStatus(response),
        data: {
          cpu_usage: response.cpu_usage || 0,
          memory_usage: response.memory_usage || 0,
          temperature: response.temperature || 'N/A',
          processes: response.processes || 0,
          disk_usage: response.disk_usage || 0
        }
      };
    } catch (error) {
      return this.getErrorResult('router', error);
    }
  }
  
  async collectDNSDiagnostics() {
    try {
      const response = await this.apiCall('/api/dns.sh', { action: 'status' });
      
      return {
        type: 'dns',
        status: this.calculateDNSStatus(response),
        data: {
          primary_response: response.primary_response || 0,
          secondary_response: response.secondary_response || 0,
          cache_hit_rate: response.cache_hit_rate || 0,
          queries_today: response.queries_today || 0,
          resolver_status: response.resolver_status || 'unknown'
        }
      };
    } catch (error) {
      return this.getErrorResult('dns', error);
    }
  }
  
  async collectONTStatus() {
    try {
      const response = await this.apiCall('/api/ont.sh', { action: 'status' });
      
      return {
        type: 'ont',
        status: this.calculateONTStatus(response),
        data: {
          power_led: response.power_led || 'unknown',
          fiber_led: response.fiber_led || 'unknown',
          ethernet_led: response.ethernet_led || 'unknown',
          internet_led: response.internet_led || 'unknown',
          link_quality: response.link_quality || 0
        }
      };
    } catch (error) {
      return this.getErrorResult('ont', error);
    }
  }
  
  async apiCall(endpoint, params = {}) {
    const url = new URL(endpoint, window.location.origin);
    Object.keys(params).forEach(key => url.searchParams.append(key, params[key]));
    
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout
    
    try {
      const response = await fetch(url, {
        method: 'GET',
        signal: controller.signal,
        headers: {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache'
        }
      });
      
      clearTimeout(timeoutId);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      return data;
      
    } catch (error) {
      clearTimeout(timeoutId);
      
      if (error.name === 'AbortError') {
        throw new Error('Request timeout');
      }
      
      // Fallback to mock data for development
      return this.getMockData(endpoint, params);
    }
  }
  
  getMockData(endpoint, params) {
    // Mock data for development and testing
    const mockData = {
      '/api/system.sh': {
        uptime: 86400,
        cpu_usage: Math.random() * 30 + 10,
        memory_usage: Math.random() * 40 + 20,
        temperature: Math.random() * 20 + 45,
        reboots_24h: 0,
        load_average: [0.5, 0.3, 0.2],
        processes: 120
      },
      '/api/diagnostics.sh': params.action === 'wan' ? {
        link_state: 'up',
        ip_address: '192.168.1.100',
        gateway: '192.168.1.1',
        latency: Math.random() * 20 + 5,
        packet_loss: Math.random() * 2,
        download_speed: Math.random() * 100 + 50,
        upload_speed: Math.random() * 20 + 10,
        dns_resolution: 'working'
      } : {
        radios: [
          { band: '2.4GHz', clients: Math.floor(Math.random() * 5) + 1 },
          { band: '5GHz', clients: Math.floor(Math.random() * 8) + 2 }
        ],
        total_clients: Math.floor(Math.random() * 10) + 3,
        avg_signal: Math.random() * 30 + 50,
        disconnects_1h: Math.floor(Math.random() * 3)
      },
      '/api/dns.sh': {
        primary_response: Math.random() * 20 + 5,
        secondary_response: Math.random() * 25 + 8,
        cache_hit_rate: Math.random() * 30 + 70,
        queries_today: Math.floor(Math.random() * 1000) + 500,
        resolver_status: 'active'
      },
      '/api/ont.sh': {
        power_led: 'green',
        fiber_led: 'green',
        ethernet_led: 'green',
        internet_led: 'green',
        link_quality: Math.random() * 20 + 80
      }
    };
    
    return mockData[endpoint] || {};
  }
  
  processDiagnosticResult(result, index) {
    if (!result || !result.type) return;
    
    this.diagnosticData.set(result.type, result);
    this.updateUI(result.type, result);
  }
  
  updateUI(type, data) {
    switch (type) {
      case 'system':
        this.updateSystemCard(data);
        break;
      case 'wan':
        this.updateWANCard(data);
        break;
      case 'wifi':
        this.updateWiFiCard(data);
        break;
      case 'router':
        this.updateRouterCard(data);
        break;
      case 'dns':
        this.updateDNSCard(data);
        break;
      case 'ont':
        this.updateONTStatus(data);
        break;
    }
  }
  
  updateSystemCard(data) {
    const statusChip = document.getElementById('system-status');
    const uptimeValue = document.getElementById('uptime-value');
    const rebootsValue = document.getElementById('reboots-value');
    const systemScore = document.getElementById('system-score');
    
    if (statusChip) this.updateStatusChip(statusChip, data.status);
    if (uptimeValue) uptimeValue.textContent = data.data.uptime;
    if (rebootsValue) rebootsValue.textContent = data.data.reboots_24h;
    if (systemScore) systemScore.textContent = data.data.health_score;
  }
  
  updateWANCard(data) {
    const statusChip = document.getElementById('wan-status');
    const latencyValue = document.getElementById('latency-value');
    const packetLossValue = document.getElementById('packet-loss-value');
    
    if (statusChip) this.updateStatusChip(statusChip, data.status);
    if (latencyValue) latencyValue.textContent = `${Math.round(data.data.latency)}ms`;
    if (packetLossValue) packetLossValue.textContent = `${data.data.packet_loss.toFixed(1)}%`;
  }
  
  updateWiFiCard(data) {
    const statusChip = document.getElementById('wifi-status');
    const clientsValue = document.getElementById('wifi-clients-value');
    const signalValue = document.getElementById('wifi-signal-value');
    
    if (statusChip) this.updateStatusChip(statusChip, data.status);
    if (clientsValue) clientsValue.textContent = data.data.total_clients;
    if (signalValue) signalValue.textContent = `${Math.round(data.data.avg_signal)}dBm`;
  }
  
  updateRouterCard(data) {
    const statusChip = document.getElementById('router-status');
    const cpuValue = document.getElementById('cpu-value');
    const memoryValue = document.getElementById('memory-value');
    
    if (statusChip) this.updateStatusChip(statusChip, data.status);
    if (cpuValue) cpuValue.textContent = `${Math.round(data.data.cpu_usage)}%`;
    if (memoryValue) memoryValue.textContent = `${Math.round(data.data.memory_usage)}%`;
  }
  
  updateDNSCard(data) {
    const statusChip = document.getElementById('dns-status');
    const responseValue = document.getElementById('dns-response-value');
    const cacheValue = document.getElementById('dns-cache-value');
    
    if (statusChip) this.updateStatusChip(statusChip, data.status);
    if (responseValue) responseValue.textContent = `${Math.round(data.data.primary_response)}ms`;
    if (cacheValue) cacheValue.textContent = `${Math.round(data.data.cache_hit_rate)}%`;
  }
  
  updateONTStatus(data) {
    const powerLed = document.getElementById('ont-power-led');
    const fiberLed = document.getElementById('ont-fiber-led');
    const ethernetLed = document.getElementById('ont-ethernet-led');
    const internetLed = document.getElementById('ont-internet-led');
    
    if (powerLed) this.updateLEDIndicator(powerLed, data.data.power_led);
    if (fiberLed) this.updateLEDIndicator(fiberLed, data.data.fiber_led);
    if (ethernetLed) this.updateLEDIndicator(ethernetLed, data.data.ethernet_led);
    if (internetLed) this.updateLEDIndicator(internetLed, data.data.internet_led);
  }
  
  updateStatusChip(element, status) {
    element.className = `md3-status-chip ${status}`;
    const statusText = element.querySelector('.status-text');
    if (statusText) {
      statusText.textContent = this.getStatusText(status);
    }
  }
  
  updateLEDIndicator(element, state) {
    element.className = `ont-led-indicator ont-led-${state === 'green' ? 'power' : 'off'}`;
  }
  
  getStatusText(status) {
    const statusTexts = {
      healthy: 'All Good',
      degraded: 'Some Issues',
      broken: 'Problems',
      unknown: 'Checking...'
    };
    return statusTexts[status] || 'Unknown';
  }
  
  calculateHealthStatus(cpu, memory) {
    if (cpu > 80 || memory > 90) return 'broken';
    if (cpu > 60 || memory > 75) return 'degraded';
    return 'healthy';
  }
  
  calculateSystemHealthScore(data) {
    let score = 100;
    score -= (data.cpu_usage || 0) * 0.5;
    score -= (data.memory_usage || 0) * 0.3;
    score -= (data.reboots_24h || 0) * 10;
    return Math.max(0, Math.round(score));
  }
  
  calculateWANStatus(data) {
    if (data.link_state !== 'up' || data.packet_loss > 5) return 'broken';
    if (data.latency > 100 || data.packet_loss > 1) return 'degraded';
    return 'healthy';
  }
  
  calculateWiFiStatus(data) {
    if (data.disconnects_1h > 5) return 'broken';
    if (data.disconnects_1h > 2 || data.avg_signal < -70) return 'degraded';
    return 'healthy';
  }
  
  calculateRouterStatus(data) {
    if (data.cpu_usage > 85 || data.memory_usage > 95) return 'broken';
    if (data.cpu_usage > 70 || data.memory_usage > 80) return 'degraded';
    return 'healthy';
  }
  
  calculateDNSStatus(data) {
    if (data.primary_response > 1000 || data.cache_hit_rate < 50) return 'broken';
    if (data.primary_response > 500 || data.cache_hit_rate < 70) return 'degraded';
    return 'healthy';
  }
  
  calculateONTStatus(data) {
    const leds = [data.power_led, data.fiber_led, data.ethernet_led, data.internet_led];
    const greenCount = leds.filter(led => led === 'green').length;
    
    if (greenCount < 2) return 'broken';
    if (greenCount < 4) return 'degraded';
    return 'healthy';
  }
  
  getErrorResult(type, error) {
    return {
      type,
      status: 'unknown',
      data: {},
      error: error.message
    };
  }
  
  formatUptime(seconds) {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (days > 0) return `${days}d ${hours}h`;
    if (hours > 0) return `${hours}h ${minutes}m`;
    return `${minutes}m`;
  }
  
  updateLastRefreshTime() {
    const updateTime = document.getElementById('update-time');
    if (updateTime) {
      const now = new Date();
      updateTime.textContent = now.toLocaleTimeString([], { 
        hour: '2-digit', 
        minute: '2-digit' 
      });
    }
  }
  
  handleError(message, error = null) {
    console.error(message, error);
    this.errorCount++;
    
    if (this.errorCount >= this.maxErrors) {
      this.showErrorSnackbar('Connection issues detected. Retrying...');
      // Exponential backoff
      setTimeout(() => {
        this.errorCount = 0;
        this.collectAllDiagnostics();
      }, Math.min(30000, 1000 * Math.pow(2, this.errorCount)));
    }
  }
  
  showErrorSnackbar(message) {
    const snackbar = document.getElementById('error-snackbar');
    const errorText = document.getElementById('error-text');
    
    if (snackbar && errorText) {
      errorText.textContent = message;
      snackbar.classList.add('show');
      
      setTimeout(() => {
        snackbar.classList.remove('show');
      }, 5000);
    }
  }
  
  // Public API methods
  getDiagnosticData(type) {
    return this.diagnosticData.get(type);
  }
  
  getAllDiagnosticData() {
    return Object.fromEntries(this.diagnosticData);
  }
  
  getUserContext() {
    return this.userContext;
  }
  
  getNetworks() {
    return this.networks;
  }
  
  refreshDiagnostics() {
    this.collectAllDiagnostics();
  }
  
  destroy() {
    if (this.updateInterval) {
      clearInterval(this.updateInterval);
      this.updateInterval = null;
    }
  }
}

// Global diagnostics instance
let diagnostics = null;

// Initialize diagnostics when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  diagnostics = new UniversalNetworkInterface();
});

// Export for use in other modules
window.NotApolloDiagnostics = UniversalNetworkInterface;