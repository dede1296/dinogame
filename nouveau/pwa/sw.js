// Ambrelune service worker (template: BUILD and PRECACHE are filled in at build time by
// nouveau/pwa/vitePlugin.js). Scope: /dinogame/nouveau/ only.
//
// - The game page is always fetched from the network first (so a new deploy shows up on
//   the next launch); the cached copy is only used offline or on a very slow network.
// - The game's files (JS, sounds, images, icons) are cached at install. Their names contain
//   a content hash, so they never go stale.
// - Every deploy produces a new BUILD: the new worker replaces the old one right away and
//   deletes the old caches, so an old version can never stay stuck.
// - Google Fonts (the handwriting font) are cached as they are used.

const BUILD = "__BUILD__";
const PRECACHE = __PRECACHE__;
const CACHE = `ambrelune-${BUILD}`;
const FONT_CACHE = "ambrelune-fonts";
const NETWORK_TIMEOUT_MS = 4000;
const INDEX_URL = new URL("./", self.registration.scope).href;

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE)
      .then((cache) => cache.addAll(PRECACHE.map((url) => new Request(url, { cache: "reload" }))))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k.startsWith("ambrelune-") && k !== CACHE && k !== FONT_CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener("fetch", (event) => {
  const req = event.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  if (req.mode === "navigate" && url.origin === self.location.origin) {
    event.respondWith(pageNetworkFirst(req));
  } else if (url.origin === self.location.origin) {
    // ignoreVary: module scripts send an Origin header that some servers list in Vary.
    event.respondWith(caches.match(req, { cacheName: CACHE, ignoreVary: true }).then((hit) => hit || fetch(req)));
  } else if (url.hostname === "fonts.googleapis.com" || url.hostname === "fonts.gstatic.com") {
    event.respondWith(fontStaleWhileRevalidate(req));
  }
});

async function pageNetworkFirst(req) {
  const cache = await caches.open(CACHE);
  try {
    const res = await withTimeout(fetch(req), NETWORK_TIMEOUT_MS);
    if (res.ok) cache.put(INDEX_URL, res.clone());
    return res;
  } catch {
    const cached = await cache.match(INDEX_URL);
    if (cached) return cached;
    return fetch(req); // no copy yet: let the browser show its own offline error
  }
}

async function fontStaleWhileRevalidate(req) {
  const cache = await caches.open(FONT_CACHE);
  const cached = await cache.match(req);
  const fresh = fetch(req).then((res) => { if (res.ok || res.type === "opaque") cache.put(req, res.clone()); return res; }).catch(() => cached);
  return cached || fresh;
}

function withTimeout(promise, ms) {
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error("timeout")), ms);
    promise.then((v) => { clearTimeout(t); resolve(v); }, (e) => { clearTimeout(t); reject(e); });
  });
}
