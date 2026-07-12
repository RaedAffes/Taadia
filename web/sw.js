const CACHE_NAME = 'ta3dia-v6';
const CACHE_ASSETS = 'ta3dia-assets-v6';
const CACHE_CROSS = 'ta3dia-cross-v6';

const PRECACHE_URLS = [
  './',
  './index.html',
  './flutter_bootstrap.js',
  './main.dart.js',
  './flutter.js',
  './manifest.json',
  './favicon.png',
  './version.json',
  './assets/assets/fonts/Amiri.ttf',
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      await cache.addAll(PRECACHE_URLS).catch((err) => {
        console.warn('Precache partial failure:', err);
      });
    })()
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const cacheNames = await caches.keys();
      await Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME && name !== CACHE_ASSETS && name !== CACHE_CROSS)
          .map((name) => caches.delete(name))
      );
      await self.clients.claim();
    })()
  );
});

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  if (request.method !== 'GET') {
    event.respondWith(fetch(request));
    return;
  }

  // Cross-origin: network-only for APIs, cache-first for CDN assets
  if (url.origin !== self.location.origin) {
    if (url.hostname === 'firestore.googleapis.com' || url.hostname.includes('googleapis.com') || url.hostname.includes('firebaseio.com')) {
      event.respondWith(
        fetch(request).catch(() => new Response(null, { status: 503 }))
      );
      return;
    }
    event.respondWith(
      (async () => {
        const cached = await caches.match(request);
        if (cached) return cached;
        try {
          const response = await fetch(request);
          if (response && response.status === 200) {
            const clone = response.clone();
            caches.open(CACHE_CROSS).then((cache) => cache.put(request, clone));
          }
          return response;
        } catch () {
          return cached || new Response(null, { status: 503 });
        }
      })()
    );
    return;
  }

  const pathname = url.pathname;
  const isAsset = pathname.startsWith('/assets/');
  const isCanvaskit = pathname.startsWith('/canvaskit/');
  const isMainJs = pathname.endsWith('main.dart.js') || pathname == './main.dart.js';
  const isFlutterJs = pathname === '/flutter.js' || pathname === '/flutter_bootstrap.js';
  const isFlutterJsNetwork = pathname === '/flutter_bootstrap.js';
  const isStatic = pathname.endsWith('.png') || pathname.endsWith('.ico') || pathname.endsWith('.json') || pathname.endsWith('.svg') || pathname.endsWith('.woff') || pathname.endsWith('.woff2') || pathname.endsWith('.ttf') || pathname.endsWith('.wasm');

  // Network-first for flutter_bootstrap.js (app init)
  if (isFlutterJsNetwork) {
    event.respondWith(
      (async () => {
        try {
          const response = await fetch(request);
          if (response && response.status === 200) {
            const clone = response.clone();
            const cache = await caches.open(CACHE_NAME);
            cache.put(request, clone);
          }
          return response;
        } catch () {
          return caches.match(request);
        }
      })()
    );
    return;
  }

  // Network-first for main.dart.js (always get latest)
  if (isMainJs) {
    event.respondWith(
      (async () => {
        try {
          const response = await fetch(request);
          if (response && response.status === 200) {
            const clone = response.clone();
            const cache = await caches.open(CACHE_NAME);
            cache.put(request, clone);
          }
          return response;
        } catch () {
          return caches.match(request);
        }
      })()
    );
    return;
  }

  // Cache-first for immutable Flutter assets
  if (isAsset || isCanvaskit || isMainJs || isFlutterJs || isStatic) {
    event.respondWith(
      (async () => {
        const cached = await caches.match(request);
        if (cached) return cached;
        try {
          const response = await fetch(request);
          if (response && response.status === 200) {
            const clone = response.clone();
            const cache = await caches.open(CACHE_NAME);
            cache.put(request, clone);
          }
          return response;
        } catch () {
          return caches.match('./index.html');
        }
      })()
    );
    return;
  }

  // Network-first for index.html and the root
  if (pathname === '/' || pathname === '/index.html') {
    event.respondWith(
      (async () => {
        try {
          const response = await fetch(request);
          if (response && response.status === 200) {
            const clone = response.clone();
            const cache = await caches.open(CACHE_NAME);
            cache.put(request, clone);
          }
          return response;
        } catch () {
          return caches.match(request);
        }
      })()
    );
    return;
  }

  // Default: network-first with cache fallback
  event.respondWith(
    (async () => {
      try {
        const response = await fetch(request);
        if (response && response.status === 200) {
          const clone = response.clone();
          const cache = await caches.open(CACHE_NAME);
          cache.put(request, clone);
        }
        return response;
      } catch () {
        return caches.match(request);
      }
    })()
  );
});
