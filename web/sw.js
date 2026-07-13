const CACHE_NAME = 'ta3dia-v13';
const CACHE_ASSETS = 'ta3dia-assets-v13';
const CACHE_CROSS = 'ta3dia-cross-v13';

const SHELL_URLS = [
  './',
  './index.html',
  './flutter_bootstrap.js',
  './main.dart.js',
  './flutter.js',
  './manifest.json',
  './favicon.png',
  './version.json',
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      try {
        await cache.addAll(SHELL_URLS);
      } catch (err) {
        console.warn('Precache partial failure:', err);
      }
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

      let remoteVersion = null;
      try {
        const resp = await fetch('./version.json?' + Date.now(), { cache: 'no-store' });
        if (resp.ok) {
          const data = await resp.json();
          remoteVersion = data.version;
        }
      } catch (_) {}

      const clients = await self.clients.matchAll();
      for (const client of clients) {
        client.postMessage({ type: 'SW_ACTIVATED' });
        if (remoteVersion) {
          client.postMessage({ type: 'CHECK_VERSION', version: remoteVersion });
        }
      }
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

  if (url.origin !== self.location.origin) {
    if (
      url.hostname === 'firestore.googleapis.com' ||
      url.hostname.includes('googleapis.com') ||
      url.hostname.includes('firebaseio.com')
    ) {
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
        } catch (e) {
          return cached || new Response(null, { status: 503 });
        }
      })()
    );
    return;
  }

  const pathname = url.pathname;

  if (pathname === '/' || pathname === '/index.html' || pathname === '/main.dart.js' || pathname === '/flutter_bootstrap.js' || pathname === '/version.json') {
    event.respondWith(
      (async () => {
        try {
          const response = await fetch(request);
          return response;
        } catch (e) {
          return caches.match(request) || new Response(null, { status: 503 });
        }
      })()
    );
    return;
  }

  const isAsset = pathname.startsWith('/assets/');
  const isCanvaskit = pathname.startsWith('/canvaskit/');
  const isStatic = pathname.endsWith('.png') || pathname.endsWith('.ico') || pathname.endsWith('.json') || pathname.endsWith('.svg') || pathname.endsWith('.woff') || pathname.endsWith('.woff2') || pathname.endsWith('.ttf') || pathname.endsWith('.wasm');

  if (isAsset || isCanvaskit || isStatic) {
    event.respondWith(
      (async () => {
        const cached = await caches.match(request);
        if (cached) return cached;
        try {
          const response = await fetch(request);
          if (response && response.status === 200) {
            const clone = response.clone();
            const cache = await caches.open(CACHE_ASSETS);
            cache.put(request, clone);
          }
          return response;
        } catch (e) {
          return caches.match('./index.html');
        }
      })()
    );
    return;
  }

  event.respondWith(
    (async () => {
      try {
        const response = await fetch(request);
        return response;
      } catch (e) {
        return caches.match(request) || new Response(null, { status: 503 });
      }
    })()
  );
});
