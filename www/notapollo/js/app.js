/**
 * notApollo Diagnostic Application - Main Controller
 * Universal Network Detection and Production-Ready Implementation
 * Material 3 2026 Compliant with Comprehensive Error Handling
 */

class NotApolloApp {
  constructor() {
    this.diagnostics = null;
    this.charts = null;
    this.isInitialized = false;
    this.restartInProgress = false;
    this.countdownTimer = null;
    this.progressTimer = null;
    this.errorRetryCount = 0;
    this.maxRetries = 3;
    
    this.init();
  }
  
  async init() {
    try {
      console.log('notApollo diagnostic app initializing...');
      
      // Wait for dependencies
      await this.waitForDependencies();
      
      // Initialize components
      this.initializeEventListeners();
      this.initializeServiceWorker();
      this.setupErrorHandling();
      
      // Show loading overlay initially
      this.showLoadingOverlay();
      
      // Initialize diagnostics and charts
      await this.initializeComponents();
      
      // Hide loading overlay
      setTimeout(() => {
        this.hideLoadingOverlay();
        this.isInitialized = true;
        console.log('notApollo app initialized successfully');
      }, 2000);
      
    } catch (error) {
      console.error('Failed to initialize notApollo app:', error);
      this.handleInitializationError(error);
    }
  }
  
  async waitForDependencies() {
    // Wait for Chart.js to load
    while (typeof Chart === 'undefined') {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    // Wait for diagnostics class to be available
    while (typeof NotApolloDiagnostics === 'undefined') {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    // Wait for charts class to be available
    while (typeof NotApolloCharts === 'undefined') {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }
  
  async initializeComponents() {
    try {
      // Initialize diagnostics
      if (window.diagnostics) {
        this.diagnostics = window.diagnostics;
      } else {
        this.diagnostics = new NotApolloDiagnostics();
        window.diagnostics = this.diagnostics;
      }
      
      // Initialize charts
      if (window.charts) {
        this.charts = window.charts;
      } else {
        this.charts = new NotApolloCharts();
        window.charts = this.charts;
      }
      
      // Wait for initial data collection
      await new Promise(resolve => setTimeout(resolve, 1000));
      
    } catch (error) {
      console.error('Component initialization failed:', error);
      throw error;
    }
  }
  
  initializeEventListeners() {
    // Menu button
    const menuButton = document.getElementById('menu-button');
    if (menuButton) {
      menuButton.addEventListener('click', this.handleMenuClick.bind(this));
    }
    
    // Settings button
    const settingsButton = document.getElementById('settings-button');
    if (settingsButton) {
      settingsButton.addEventListener('click', this.handleSettingsClick.bind(this));
    }
    
    // Restart button
    const restartButton = document.getElementById('restart-button');
    if (restartButton) {
      restartButton.addEventListener('click', this.handleRestartClick.bind(this));
    }
    
    // ONT troubleshoot button
    const ontTroubleshoot = document.getElementById('ont-troubleshoot');
    if (ontTroubleshoot) {
      ontTroubleshoot.addEventListener('click', this.handleONTTroubleshoot.bind(this));
    }
    
    // Timeframe controls
    const networkTimeframe = document.getElementById('network-timeframe');
    if (networkTimeframe) {
      networkTimeframe.addEventListener('click', this.handleTimeframeChange.bind(this));
    }
    
    const resourcesTimeframe = document.getElementById('resources-timeframe');
    if (resourcesTimeframe) {
      resourcesTimeframe.addEventListener('click', this.handleTimeframeChange.bind(this));
    }
    
    // Error snackbar dismiss
    const dismissError = document.getElementById('dismiss-error');
    if (dismissError) {
      dismissError.addEventListener('click', this.dismissErrorSnackbar.bind(this));
    }
    
    // Keyboard shortcuts
    document.addEventListener('keydown', this.handleKeyboardShortcuts.bind(this));
    
    // Visibility change (tab focus/blur)
    document.addEventListener('visibilitychange', this.handleVisibilityChange.bind(this));
    
    // Online/offline events
    window.addEventListener('online', this.handleOnline.bind(this));
    window.addEventListener('offline', this.handleOffline.bind(this));
  }
  
  initializeServiceWorker() {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('sw.js')
        .then(registration => {
          console.log('Service Worker registered:', registration);
        })
        .catch(error => {
          console.warn('Service Worker registration failed:', error);
        });
    }
  }
  
  setupErrorHandling() {
    // Global error handler
    window.addEventListener('error', (event) => {
      console.error('Global error:', event.error);
      this.handleError('Application error occurred', event.error);
    });
    
    // Unhandled promise rejection handler
    window.addEventListener('unhandledrejection', (event) => {
      console.error('Unhandled promise rejection:', event.reason);
      this.handleError('Network request failed', event.reason);
    });
  }
  
  handleMenuClick() {
    // Toggle mobile menu or navigation drawer
    console.log('Menu clicked');
    // Implementation for mobile navigation
  }
  
  handleSettingsClick() {
    // Open settings panel or modal
    console.log('Settings clicked');
    this.showSettingsDialog();
  }
  
  async handleRestartClick() {
    if (this.restartInProgress) return;
    
    try {
      // Show safety countdown
      this.showRestartCountdown();
      
    } catch (error) {
      console.error('Restart initiation failed:', error);
      this.showErrorSnackbar('Failed to initiate restart');
    }
  }
  
  showRestartCountdown() {
    const restartButton = document.getElementById('restart-button');
    const countdownElement = document.getElementById('restart-countdown');
    const timerElement = document.getElementById('countdown-timer');
    
    if (!restartButton || !countdownElement || !timerElement) return;
    
    // Hide restart button and show countdown
    restartButton.style.display = 'none';
    countdownElement.style.display = 'block';
    
    let timeLeft = 5;
    timerElement.textContent = timeLeft;
    
    this.countdownTimer = setInterval(() => {
      timeLeft--;
      timerElement.textContent = timeLeft;
      
      if (timeLeft <= 0) {
        clearInterval(this.countdownTimer);
        this.executeRestart();
      }
    }, 1000);
    
    // Allow cancellation by clicking anywhere
    const cancelCountdown = () => {
      clearInterval(this.countdownTimer);
      countdownElement.style.display = 'none';
      restartButton.style.display = 'flex';
      document.removeEventListener('click', cancelCountdown);
    };
    
    setTimeout(() => {
      document.addEventListener('click', cancelCountdown);
    }, 100);
  }
  
  async executeRestart() {
    try {
      this.restartInProgress = true;
      
      // Hide countdown and show progress
      const countdownElement = document.getElementById('restart-countdown');
      const progressElement = document.getElementById('restart-progress');
      const progressFill = document.getElementById('progress-fill');
      const progressText = document.getElementById('progress-text');
      const progressTime = document.getElementById('progress-time');
      
      if (countdownElement) countdownElement.style.display = 'none';
      if (progressElement) progressElement.style.display = 'block';
      
      // Restart progress stages
      const stages = [
        { text: 'Preparing restart...', duration: 2000, progress: 10 },
        { text: 'Stopping services...', duration: 3000, progress: 30 },
        { text: 'Restarting system...', duration: 5000, progress: 60 },
        { text: 'Starting services...', duration: 8000, progress: 85 },
        { text: 'Finalizing...', duration: 2000, progress: 100 }
      ];
      
      // Execute restart API call
      const restartPromise = this.apiCall('/api/reboot.sh', { action: 'restart' });
      
      // Show progress stages
      for (let i = 0; i < stages.length; i++) {
        const stage = stages[i];
        
        if (progressText) progressText.textContent = stage.text;
        if (progressFill) progressFill.style.width = `${stage.progress}%`;
        
        const remainingTime = stages.slice(i).reduce((sum, s) => sum + s.duration, 0);
        if (progressTime) {
          progressTime.textContent = `Estimated: ${Math.ceil(remainingTime / 1000)} seconds`;
        }
        
        await new Promise(resolve => setTimeout(resolve, stage.duration));
      }
      
      // Wait for restart to complete
      await restartPromise;
      
      // Monitor for system to come back online
      this.monitorRestartCompletion();
      
    } catch (error) {
      console.error('Restart execution failed:', error);
      this.handleRestartError(error);
    }
  }
  
  async monitorRestartCompletion() {
    const maxAttempts = 30; // 5 minutes
    let attempts = 0;
    
    const checkSystem = async () => {
      try {
        const response = await fetch('/api/system.sh?action=ping', {
          method: 'GET',
          timeout: 5000
        });
        
        if (response.ok) {
          // System is back online
          this.handleRestartSuccess();
          return;
        }
      } catch (error) {
        // System still restarting
      }
      
      attempts++;
      if (attempts < maxAttempts) {
        setTimeout(checkSystem, 10000); // Check every 10 seconds
      } else {
        this.handleRestartTimeout();
      }
    };
    
    // Start monitoring after initial delay
    setTimeout(checkSystem, 30000); // Wait 30 seconds before first check
  }
  
  handleRestartSuccess() {
    const progressText = document.getElementById('progress-text');
    const progressFill = document.getElementById('progress-fill');
    
    if (progressText) progressText.textContent = 'Restart completed successfully!';
    if (progressFill) progressFill.style.width = '100%';
    
    // Refresh the page after a short delay
    setTimeout(() => {
      window.location.reload();
    }, 3000);
  }
  
  handleRestartError(error) {
    this.restartInProgress = false;
    
    const progressElement = document.getElementById('restart-progress');
    const restartButton = document.getElementById('restart-button');
    
    if (progressElement) progressElement.style.display = 'none';
    if (restartButton) restartButton.style.display = 'flex';
    
    this.showErrorSnackbar('Restart failed. Please try again.');
  }
  
  handleRestartTimeout() {
    this.showErrorSnackbar('Restart is taking longer than expected. Please check manually.');
  }
  
  handleONTTroubleshoot() {
    // Show ONT troubleshooting guide
    this.showONTTroubleshootingDialog();
  }
  
  handleTimeframeChange(event) {
    // Cycle through timeframes: 1h, 6h, 24h, 7d
    const timeframes = [1, 6, 24, 168]; // hours
    const currentIndex = parseInt(event.target.dataset.timeframe || '0');
    const nextIndex = (currentIndex + 1) % timeframes.length;
    const hours = timeframes[nextIndex];
    
    event.target.dataset.timeframe = nextIndex.toString();
    
    // Update charts
    if (this.charts) {
      this.charts.setTimeframe(hours);
    }
    
    // Update button text
    const labels = ['1h', '6h', '24h', '7d'];
    const icon = event.target.querySelector('.material-symbols-outlined');
    if (icon) {
      icon.textContent = 'schedule';
      icon.title = `Showing ${labels[nextIndex]}`;
    }
  }
  
  handleKeyboardShortcuts(event) {
    // Keyboard shortcuts for accessibility
    if (event.ctrlKey || event.metaKey) {
      switch (event.key) {
        case 'r':
          event.preventDefault();
          if (!this.restartInProgress) {
            this.handleRestartClick();
          }
          break;
        case 'f':
          event.preventDefault();
          this.refreshDiagnostics();
          break;
      }
    }
  }
  
  handleVisibilityChange() {
    if (document.hidden) {
      // Page is hidden, reduce update frequency
      if (this.diagnostics) {
        this.diagnostics.config.update_interval = 60000; // 1 minute
      }
    } else {
      // Page is visible, restore normal frequency
      if (this.diagnostics) {
        this.diagnostics.config.update_interval = 30000; // 30 seconds
      }
    }
  }
  
  handleOnline() {
    console.log('Connection restored');
    this.dismissErrorSnackbar();
    if (this.diagnostics) {
      this.diagnostics.refreshDiagnostics();
    }
  }
  
  handleOffline() {
    console.log('Connection lost');
    this.showErrorSnackbar('Connection lost. Retrying...');
  }
  
  async apiCall(endpoint, params = {}) {
    const url = new URL(endpoint, window.location.origin);
    Object.keys(params).forEach(key => url.searchParams.append(key, params[key]));
    
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000);
    
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
      
      return await response.json();
      
    } catch (error) {
      clearTimeout(timeoutId);
      throw error;
    }
  }
  
  refreshDiagnostics() {
    if (this.diagnostics) {
      this.diagnostics.refreshDiagnostics();
    }
    
    this.showSuccessSnackbar('Diagnostics refreshed');
  }
  
  showLoadingOverlay() {
    const overlay = document.getElementById('loading-overlay');
    if (overlay) {
      overlay.classList.remove('hidden');
    }
  }
  
  hideLoadingOverlay() {
    const overlay = document.getElementById('loading-overlay');
    if (overlay) {
      overlay.classList.add('hidden');
    }
  }
  
  showErrorSnackbar(message) {
    const snackbar = document.getElementById('error-snackbar');
    const errorText = document.getElementById('error-text');
    
    if (snackbar && errorText) {
      errorText.textContent = message;
      snackbar.classList.add('show');
      
      // Auto-dismiss after 5 seconds
      setTimeout(() => {
        snackbar.classList.remove('show');
      }, 5000);
    }
  }
  
  showSuccessSnackbar(message) {
    // Create temporary success snackbar
    const snackbar = document.createElement('div');
    snackbar.className = 'md3-snackbar show';
    snackbar.innerHTML = `
      <div class="snackbar-content">
        <span class="material-symbols-outlined">check_circle</span>
        <span class="snackbar-text">${message}</span>
      </div>
    `;
    
    document.body.appendChild(snackbar);
    
    setTimeout(() => {
      snackbar.classList.remove('show');
      setTimeout(() => {
        document.body.removeChild(snackbar);
      }, 300);
    }, 3000);
  }
  
  dismissErrorSnackbar() {
    const snackbar = document.getElementById('error-snackbar');
    if (snackbar) {
      snackbar.classList.remove('show');
    }
  }
  
  showSettingsDialog() {
    // Create and show settings modal
    const dialog = document.createElement('div');
    dialog.className = 'settings-dialog';
    dialog.innerHTML = `
      <div class="dialog-overlay">
        <div class="dialog-content">
          <h2>Settings</h2>
          <div class="setting-item">
            <label>Update Frequency</label>
            <select id="update-frequency">
              <option value="15000">15 seconds</option>
              <option value="30000" selected>30 seconds</option>
              <option value="60000">1 minute</option>
            </select>
          </div>
          <div class="setting-item">
            <label>Theme</label>
            <select id="theme-select">
              <option value="dark" selected>Dark</option>
              <option value="light">Light</option>
              <option value="auto">Auto</option>
            </select>
          </div>
          <div class="dialog-actions">
            <button class="md3-button-text" onclick="this.closest('.settings-dialog').remove()">Cancel</button>
            <button class="md3-button-filled" onclick="app.saveSettings(); this.closest('.settings-dialog').remove()">Save</button>
          </div>
        </div>
      </div>
    `;
    
    document.body.appendChild(dialog);
  }
  
  saveSettings() {
    const updateFrequency = document.getElementById('update-frequency')?.value;
    const theme = document.getElementById('theme-select')?.value;
    
    if (updateFrequency && this.diagnostics) {
      this.diagnostics.config.update_interval = parseInt(updateFrequency);
    }
    
    if (theme) {
      document.body.className = `md3-theme-${theme}`;
      localStorage.setItem('notapollo-theme', theme);
    }
    
    this.showSuccessSnackbar('Settings saved');
  }
  
  showONTTroubleshootingDialog() {
    const dialog = document.createElement('div');
    dialog.className = 'ont-dialog';
    dialog.innerHTML = `
      <div class="dialog-overlay">
        <div class="dialog-content">
          <h2>ONT Troubleshooting Guide</h2>
          <div class="troubleshoot-steps">
            <div class="step">
              <h3>1. Check Power LED</h3>
              <p>Should be solid green. If off, check power connection.</p>
            </div>
            <div class="step">
              <h3>2. Check Fiber LED</h3>
              <p>Should be solid green. If red or off, contact ISP.</p>
            </div>
            <div class="step">
              <h3>3. Check Ethernet LED</h3>
              <p>Should be solid green when connected to router.</p>
            </div>
            <div class="step">
              <h3>4. Power Cycle</h3>
              <p>Unplug power for 30 seconds, then reconnect.</p>
            </div>
          </div>
          <div class="dialog-actions">
            <button class="md3-button-filled" onclick="this.closest('.ont-dialog').remove()">Close</button>
          </div>
        </div>
      </div>
    `;
    
    document.body.appendChild(dialog);
  }
  
  handleError(message, error = null) {
    console.error(message, error);
    
    this.errorRetryCount++;
    
    if (this.errorRetryCount <= this.maxRetries) {
      // Retry with exponential backoff
      const delay = Math.min(30000, 1000 * Math.pow(2, this.errorRetryCount));
      setTimeout(() => {
        if (this.diagnostics) {
          this.diagnostics.refreshDiagnostics();
        }
      }, delay);
      
      this.showErrorSnackbar(`${message}. Retrying...`);
    } else {
      this.showErrorSnackbar('Multiple errors detected. Please refresh the page.');
    }
  }
  
  handleInitializationError(error) {
    console.error('Initialization failed:', error);
    
    // Show fallback UI
    const loadingOverlay = document.getElementById('loading-overlay');
    if (loadingOverlay) {
      loadingOverlay.innerHTML = `
        <div class="loading-content">
          <span class="material-symbols-outlined" style="font-size: 48px; color: var(--md-sys-color-error);">error</span>
          <div class="loading-text">Failed to initialize. Please refresh the page.</div>
          <button class="md3-button-filled" onclick="window.location.reload()" style="margin-top: 16px;">
            Refresh Page
          </button>
        </div>
      `;
    }
  }
  
  // Public API methods
  getDiagnostics() {
    return this.diagnostics;
  }
  
  getCharts() {
    return this.charts;
  }
  
  isReady() {
    return this.isInitialized;
  }
  
  destroy() {
    // Cleanup
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer);
    }
    
    if (this.progressTimer) {
      clearInterval(this.progressTimer);
    }
    
    if (this.diagnostics) {
      this.diagnostics.destroy();
    }
    
    if (this.charts) {
      this.charts.destroy();
    }
  }
}

// Global app instance
let app = null;

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  app = new NotApolloApp();
  window.app = app; // Make available globally for debugging
});

// Handle page unload
window.addEventListener('beforeunload', () => {
  if (app) {
    app.destroy();
  }
});

// Export for use in other modules
window.NotApolloApp = NotApolloApp;