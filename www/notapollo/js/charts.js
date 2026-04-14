/**
 * notApollo Chart Configuration and Data Visualization
 * Chart.js Integration with Material 3 2026 Design
 * Real-time Updates and Interactive Features
 */

class NotApolloCharts {
  constructor() {
    this.charts = new Map();
    this.chartData = new Map();
    this.updateInterval = null;
    this.maxDataPoints = 50;
    this.colors = this.getChartColors();
    
    this.init();
  }
  
  init() {
    // Wait for Chart.js to load
    if (typeof Chart === 'undefined') {
      setTimeout(() => this.init(), 100);
      return;
    }
    
    this.configureChartDefaults();
    this.initializeCharts();
    this.startDataCollection();
  }
  
  getChartColors() {
    // Material 3 2026 compliant chart colors
    return {
      primary: '#a8c7fa',
      secondary: '#bec6dc',
      tertiary: '#d0bcff',
      success: '#4caf50',
      warning: '#ff9800',
      error: '#f44336',
      surface: '#1c2024',
      onSurface: '#e2e2e9',
      outline: '#44474f',
      grid: '#44474f',
      text: '#c4c6d0'
    };
  }
  
  configureChartDefaults() {
    Chart.defaults.font.family = 'Google Sans Flex, sans-serif';
    Chart.defaults.font.size = 12;
    Chart.defaults.color = this.colors.text;
    Chart.defaults.backgroundColor = this.colors.surface;
    Chart.defaults.borderColor = this.colors.outline;
    Chart.defaults.plugins.legend.display = false;
    Chart.defaults.responsive = true;
    Chart.defaults.maintainAspectRatio = false;
    Chart.defaults.interaction.intersect = false;
    Chart.defaults.interaction.mode = 'index';
    
    // Configure scales
    Chart.defaults.scales.linear.grid.color = this.colors.grid;
    Chart.defaults.scales.linear.ticks.color = this.colors.text;
    Chart.defaults.scales.category.grid.color = this.colors.grid;
    Chart.defaults.scales.category.ticks.color = this.colors.text;
  }
  
  initializeCharts() {
    this.createSystemChart();
    this.createWANChart();
    this.createWiFiChart();
    this.createRouterChart();
    this.createDNSChart();
    this.createNetworkPerformanceChart();
    this.createSystemResourcesChart();
  }
  
  createSystemChart() {
    const ctx = document.getElementById('system-chart');
    if (!ctx) return;
    
    const chart = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['Healthy', 'Issues'],
        datasets: [{
          data: [85, 15],
          backgroundColor: [this.colors.success, this.colors.surface],
          borderColor: [this.colors.success, this.colors.outline],
          borderWidth: 2,
          cutout: '70%'
        }]
      },
      options: {
        plugins: {
          tooltip: {
            enabled: false
          }
        },
        animation: {
          animateRotate: true,
          duration: 1000
        }
      }
    });
    
    this.charts.set('system', chart);
  }
  
  createWANChart() {
    const ctx = document.getElementById('wan-chart');
    if (!ctx) return;
    
    const chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: this.generateTimeLabels(20),
        datasets: [{
          label: 'Latency (ms)',
          data: this.generateMockData(20, 10, 50),
          borderColor: this.colors.primary,
          backgroundColor: this.addAlpha(this.colors.primary, 0.1),
          borderWidth: 2,
          fill: true,
          tension: 0.4,
          pointRadius: 0,
          pointHoverRadius: 4
        }]
      },
      options: {
        scales: {
          x: {
            display: false
          },
          y: {
            beginAtZero: true,
            grid: {
              color: this.colors.grid
            },
            ticks: {
              callback: (value) => `${value}ms`
            }
          }
        },
        plugins: {
          tooltip: {
            backgroundColor: this.colors.surface,
            titleColor: this.colors.onSurface,
            bodyColor: this.colors.text,
            borderColor: this.colors.outline,
            borderWidth: 1,
            callbacks: {
              label: (context) => `Latency: ${context.parsed.y}ms`
            }
          }
        }
      }
    });
    
    this.charts.set('wan', chart);
  }
  
  createWiFiChart() {
    const ctx = document.getElementById('wifi-chart');
    if (!ctx) return;
    
    const chart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: ['2.4GHz', '5GHz', '6GHz'],
        datasets: [{
          label: 'Connected Clients',
          data: [3, 7, 2],
          backgroundColor: [
            this.colors.primary,
            this.colors.secondary,
            this.colors.tertiary
          ],
          borderColor: [
            this.colors.primary,
            this.colors.secondary,
            this.colors.tertiary
          ],
          borderWidth: 1,
          borderRadius: 4
        }]
      },
      options: {
        scales: {
          x: {
            grid: {
              display: false
            }
          },
          y: {
            beginAtZero: true,
            ticks: {
              stepSize: 1,
              callback: (value) => Math.floor(value)
            }
          }
        },
        plugins: {
          tooltip: {
            backgroundColor: this.colors.surface,
            titleColor: this.colors.onSurface,
            bodyColor: this.colors.text,
            borderColor: this.colors.outline,
            borderWidth: 1,
            callbacks: {
              label: (context) => `${context.parsed.y} clients`
            }
          }
        }
      }
    });
    
    this.charts.set('wifi', chart);
  }
  
  createRouterChart() {
    const ctx = document.getElementById('router-chart');
    if (!ctx) return;
    
    const chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: this.generateTimeLabels(15),
        datasets: [
          {
            label: 'CPU Usage (%)',
            data: this.generateMockData(15, 20, 60),
            borderColor: this.colors.warning,
            backgroundColor: this.addAlpha(this.colors.warning, 0.1),
            borderWidth: 2,
            fill: false,
            tension: 0.4,
            pointRadius: 0
          },
          {
            label: 'Memory Usage (%)',
            data: this.generateMockData(15, 30, 70),
            borderColor: this.colors.primary,
            backgroundColor: this.addAlpha(this.colors.primary, 0.1),
            borderWidth: 2,
            fill: false,
            tension: 0.4,
            pointRadius: 0
          }
        ]
      },
      options: {
        scales: {
          x: {
            display: false
          },
          y: {
            beginAtZero: true,
            max: 100,
            ticks: {
              callback: (value) => `${value}%`
            }
          }
        },
        plugins: {
          legend: {
            display: true,
            position: 'bottom',
            labels: {
              usePointStyle: true,
              padding: 15,
              font: {
                size: 11
              }
            }
          },
          tooltip: {
            backgroundColor: this.colors.surface,
            titleColor: this.colors.onSurface,
            bodyColor: this.colors.text,
            borderColor: this.colors.outline,
            borderWidth: 1
          }
        }
      }
    });
    
    this.charts.set('router', chart);
  }
  
  createDNSChart() {
    const ctx = document.getElementById('dns-chart');
    if (!ctx) return;
    
    const chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: this.generateTimeLabels(12),
        datasets: [{
          label: 'Response Time (ms)',
          data: this.generateMockData(12, 5, 25),
          borderColor: this.colors.tertiary,
          backgroundColor: this.addAlpha(this.colors.tertiary, 0.1),
          borderWidth: 2,
          fill: true,
          tension: 0.4,
          pointRadius: 0,
          pointHoverRadius: 4
        }]
      },
      options: {
        scales: {
          x: {
            display: false
          },
          y: {
            beginAtZero: true,
            ticks: {
              callback: (value) => `${value}ms`
            }
          }
        },
        plugins: {
          tooltip: {
            backgroundColor: this.colors.surface,
            titleColor: this.colors.onSurface,
            bodyColor: this.colors.text,
            borderColor: this.colors.outline,
            borderWidth: 1,
            callbacks: {
              label: (context) => `Response: ${context.parsed.y}ms`
            }
          }
        }
      }
    });
    
    this.charts.set('dns', chart);
  }
  
  createNetworkPerformanceChart() {
    const ctx = document.getElementById('network-performance-chart');
    if (!ctx) return;
    
    const chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: this.generateTimeLabels(30),
        datasets: [
          {
            label: 'Latency (ms)',
            data: this.generateMockData(30, 10, 80),
            borderColor: this.colors.primary,
            backgroundColor: this.addAlpha(this.colors.primary, 0.1),
            borderWidth: 2,
            fill: false,
            tension: 0.3,
            yAxisID: 'y'
          },
          {
            label: 'Packet Loss (%)',
            data: this.generateMockData(30, 0, 5),
            borderColor: this.colors.error,
            backgroundColor: this.addAlpha(this.colors.error, 0.1),
            borderWidth: 2,
            fill: false,
            tension: 0.3,
            yAxisID: 'y1'
          }
        ]
      },
      options: {
        interaction: {
          mode: 'index',
          intersect: false
        },
        scales: {
          x: {
            title: {
              display: true,
              text: 'Time',
              color: this.colors.text
            }
          },
          y: {
            type: 'linear',
            display: true,
            position: 'left',
            title: {
              display: true,
              text: 'Latency (ms)',
              color: this.colors.text
            },
            ticks: {
              callback: (value) => `${value}ms`
            }
          },
          y1: {
            type: 'linear',
            display: true,
            position: 'right',
            title: {
              display: true,
              text: 'Packet Loss (%)',
              color: this.colors.text
            },
            grid: {
              drawOnChartArea: false
            },
            ticks: {
              callback: (value) => `${value}%`
            }
          }
        },
        plugins: {
          legend: {
            display: true,
            position: 'top',
            labels: {
              usePointStyle: true,
              padding: 20
            }
          },
          tooltip: {
            backgroundColor: this.colors.surface,
            titleColor: this.colors.onSurface,
            bodyColor: this.colors.text,
            borderColor: this.colors.outline,
            borderWidth: 1
          }
        }
      }
    });
    
    this.charts.set('network-performance', chart);
  }
  
  createSystemResourcesChart() {
    const ctx = document.getElementById('system-resources-chart');
    if (!ctx) return;
    
    const chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: this.generateTimeLabels(25),
        datasets: [
          {
            label: 'CPU Usage (%)',
            data: this.generateMockData(25, 15, 75),
            borderColor: this.colors.warning,
            backgroundColor: this.addAlpha(this.colors.warning, 0.1),
            borderWidth: 2,
            fill: '+1',
            tension: 0.3
          },
          {
            label: 'Memory Usage (%)',
            data: this.generateMockData(25, 25, 85),
            borderColor: this.colors.primary,
            backgroundColor: this.addAlpha(this.colors.primary, 0.1),
            borderWidth: 2,
            fill: 'origin',
            tension: 0.3
          },
          {
            label: 'Temperature (°C)',
            data: this.generateMockData(25, 45, 65),
            borderColor: this.colors.error,
            backgroundColor: this.addAlpha(this.colors.error, 0.1),
            borderWidth: 2,
            fill: false,
            tension: 0.3,
            yAxisID: 'y1'
          }
        ]
      },
      options: {
        interaction: {
          mode: 'index',
          intersect: false
        },
        scales: {
          x: {
            title: {
              display: true,
              text: 'Time',
              color: this.colors.text
            }
          },
          y: {
            beginAtZero: true,
            max: 100,
            title: {
              display: true,
              text: 'Usage (%)',
              color: this.colors.text
            },
            ticks: {
              callback: (value) => `${value}%`
            }
          },
          y1: {
            type: 'linear',
            display: true,
            position: 'right',
            title: {
              display: true,
              text: 'Temperature (°C)',
              color: this.colors.text
            },
            grid: {
              drawOnChartArea: false
            },
            ticks: {
              callback: (value) => `${value}°C`
            }
          }
        },
        plugins: {
          legend: {
            display: true,
            position: 'top',
            labels: {
              usePointStyle: true,
              padding: 20
            }
          },
          tooltip: {
            backgroundColor: this.colors.surface,
            titleColor: this.colors.onSurface,
            bodyColor: this.colors.text,
            borderColor: this.colors.outline,
            borderWidth: 1
          }
        }
      }
    });
    
    this.charts.set('system-resources', chart);
  }
  
  startDataCollection() {
    // Update charts every 30 seconds
    this.updateInterval = setInterval(() => {
      this.updateAllCharts();
    }, 30000);
    
    // Initial update
    setTimeout(() => this.updateAllCharts(), 2000);
  }
  
  updateAllCharts() {
    if (window.diagnostics) {
      const data = window.diagnostics.getAllDiagnosticData();
      
      Object.keys(data).forEach(type => {
        this.updateChart(type, data[type]);
      });
    }
  }
  
  updateChart(type, data) {
    const chart = this.charts.get(type);
    if (!chart || !data) return;
    
    switch (type) {
      case 'system':
        this.updateSystemChart(chart, data);
        break;
      case 'wan':
        this.updateWANChart(chart, data);
        break;
      case 'wifi':
        this.updateWiFiChart(chart, data);
        break;
      case 'router':
        this.updateRouterChart(chart, data);
        break;
      case 'dns':
        this.updateDNSChart(chart, data);
        break;
    }
  }
  
  updateSystemChart(chart, data) {
    const healthScore = data.data.health_score || 85;
    chart.data.datasets[0].data = [healthScore, 100 - healthScore];
    chart.update('none');
  }
  
  updateWANChart(chart, data) {
    const latency = data.data.latency || 0;
    this.addDataPoint(chart, latency);
  }
  
  updateWiFiChart(chart, data) {
    if (data.data.radios && data.data.radios.length > 0) {
      const clientCounts = data.data.radios.map(radio => radio.clients || 0);
      chart.data.datasets[0].data = clientCounts;
      chart.update('none');
    }
  }
  
  updateRouterChart(chart, data) {
    const cpuUsage = data.data.cpu_usage || 0;
    const memoryUsage = data.data.memory_usage || 0;
    
    this.addDataPoint(chart, cpuUsage, 0);
    this.addDataPoint(chart, memoryUsage, 1);
  }
  
  updateDNSChart(chart, data) {
    const responseTime = data.data.primary_response || 0;
    this.addDataPoint(chart, responseTime);
  }
  
  addDataPoint(chart, value, datasetIndex = 0) {
    const dataset = chart.data.datasets[datasetIndex];
    if (!dataset) return;
    
    dataset.data.push(value);
    
    // Remove old data points
    if (dataset.data.length > this.maxDataPoints) {
      dataset.data.shift();
      chart.data.labels.shift();
    }
    
    // Add new time label
    if (datasetIndex === 0) {
      chart.data.labels.push(this.getCurrentTimeLabel());
    }
    
    chart.update('none');
  }
  
  generateTimeLabels(count) {
    const labels = [];
    const now = new Date();
    
    for (let i = count - 1; i >= 0; i--) {
      const time = new Date(now.getTime() - (i * 30000)); // 30 second intervals
      labels.push(time.toLocaleTimeString([], { 
        hour: '2-digit', 
        minute: '2-digit',
        second: '2-digit'
      }));
    }
    
    return labels;
  }
  
  getCurrentTimeLabel() {
    return new Date().toLocaleTimeString([], { 
      hour: '2-digit', 
      minute: '2-digit',
      second: '2-digit'
    });
  }
  
  generateMockData(count, min, max) {
    const data = [];
    let lastValue = (min + max) / 2;
    
    for (let i = 0; i < count; i++) {
      // Generate realistic fluctuating data
      const change = (Math.random() - 0.5) * (max - min) * 0.2;
      lastValue = Math.max(min, Math.min(max, lastValue + change));
      data.push(Math.round(lastValue * 10) / 10);
    }
    
    return data;
  }
  
  addAlpha(color, alpha) {
    // Convert hex color to rgba
    const hex = color.replace('#', '');
    const r = parseInt(hex.substr(0, 2), 16);
    const g = parseInt(hex.substr(2, 2), 16);
    const b = parseInt(hex.substr(4, 2), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }
  
  // Public API methods
  getChart(type) {
    return this.charts.get(type);
  }
  
  updateChartData(type, data) {
    this.updateChart(type, data);
  }
  
  resizeCharts() {
    this.charts.forEach(chart => {
      chart.resize();
    });
  }
  
  setTimeframe(hours) {
    // Update chart timeframes
    this.charts.forEach(chart => {
      if (chart.config.type === 'line') {
        const pointCount = Math.min(this.maxDataPoints, hours * 2); // 2 points per hour
        chart.data.labels = this.generateTimeLabels(pointCount);
        chart.data.datasets.forEach(dataset => {
          dataset.data = this.generateMockData(pointCount, 0, 100);
        });
        chart.update();
      }
    });
  }
  
  exportChart(type, format = 'png') {
    const chart = this.charts.get(type);
    if (!chart) return null;
    
    return chart.toBase64Image(format, 1.0);
  }
  
  destroy() {
    if (this.updateInterval) {
      clearInterval(this.updateInterval);
      this.updateInterval = null;
    }
    
    this.charts.forEach(chart => {
      chart.destroy();
    });
    
    this.charts.clear();
  }
}

// Global charts instance
let charts = null;

// Initialize charts when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  // Wait for Chart.js to load
  const initCharts = () => {
    if (typeof Chart !== 'undefined') {
      charts = new NotApolloCharts();
    } else {
      setTimeout(initCharts, 100);
    }
  };
  
  initCharts();
});

// Handle window resize
window.addEventListener('resize', () => {
  if (charts) {
    charts.resizeCharts();
  }
});

// Export for use in other modules
window.NotApolloCharts = NotApolloCharts;