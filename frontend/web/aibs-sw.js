/* Opt-in static shell only: never cache API, auth, or third-party requests. */
importScripts('offline-assets.js');
const cacheName = 'aibs-shell-' + self.AIBS_OFFLINE_VERSION;
self.addEventListener('install', event => event.waitUntil((async () => {
  const cache = await caches.open(cacheName);
  await cache.addAll(self.AIBS_OFFLINE_ASSETS);
  await self.skipWaiting();
})()));
self.addEventListener('activate', event => event.waitUntil((async () => {
  for (const name of await caches.keys()) if (name.startsWith('aibs-shell-') && name !== cacheName) await caches.delete(name);
  await self.clients.claim();
})()));
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || url.origin !== self.location.origin) return;
  const key = url.pathname === '/' ? 'index.html' : url.pathname.slice(1);
  if (!self.AIBS_OFFLINE_ASSETS.includes(key)) return;
  event.respondWith(fetch(event.request).catch(async () => {
    const cache = await caches.open(cacheName);
    return await cache.match(key) || Response.error();
  }));
});
