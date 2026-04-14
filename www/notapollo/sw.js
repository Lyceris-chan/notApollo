// Service Worker for notApollo
// Provides offline functionality and caching

const CACHE_NAME = 'notapollo-v1';
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/css/material3.css',
  '/css/app.css',
  '/js/app.js',
  '/js/diagnostics.js',
  '/js/charts.js',
  '/js/lib/chart.min.js',
  '/manifest.json'
];

// Install event - cache static assets
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(STATIC_ASSETS))
  );
});

// Fetch event - serve from cache with network fallback
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        return response || fetch(event.request);
      })
  );
});