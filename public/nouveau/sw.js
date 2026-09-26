// Ambrelune used to live at /dinogame/nouveau/ with a worker here. It moved to /dinogame/
// (with its own worker at /dinogame/sw.js). Phones that still run the old worker pick up
// this file on their next update check: it takes over, uninstalls itself, and reloads the
// open pages so they follow the redirect. Its old caches are cleaned by the new worker.
self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (event) => {
  event.waitUntil(
    self.registration.unregister()
      .then(() => self.clients.matchAll({ type: "window" }))
      .then((clients) => clients.forEach((c) => c.navigate(c.url))),
  );
});
