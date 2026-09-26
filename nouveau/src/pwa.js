// Installable app support: service worker (production only), update notice, persistent
// storage for the saves, and an automatic save when the app goes to the background.

const UPDATE_CHECK_MS = 30 * 60 * 1000;

/**
 * @param {{ onUpdate: () => void }} opts  called when a new version has taken over this page.
 */
export function setupServiceWorker({ onUpdate }) {
  if (import.meta.env.DEV || !("serviceWorker" in navigator)) return;
  const hadController = !!navigator.serviceWorker.controller;
  navigator.serviceWorker.register("./sw.js", { scope: "./" }).then((reg) => {
    // An installed app can stay open for hours: look for a new deploy now and then.
    const check = () => reg.update().catch(() => { /* offline: try again later */ });
    setInterval(check, UPDATE_CHECK_MS);
    document.addEventListener("visibilitychange", () => { if (document.visibilityState === "visible") check(); });
  }).catch((err) => console.warn("Service worker non enregistré :", err));
  // First install: nothing to announce. Later: a new version replaced the old one.
  navigator.serviceWorker.addEventListener("controllerchange", () => { if (hadController) onUpdate(); });
}

/** Asks the browser not to evict the saves when the phone runs low on space. */
export function requestPersistentStorage() {
  navigator.storage?.persist?.().catch(() => { /* not supported: localStorage still works */ });
}

/**
 * Saves when the app is hidden or closed (switching apps, swiping it away, screen off).
 * `canSave()` says whether the game is in a stable state (not mid-battle or mid-scene).
 */
export function autosaveOnHide(canSave, save) {
  const trySave = () => { if (canSave()) save(); };
  document.addEventListener("visibilitychange", () => { if (document.visibilityState === "hidden") trySave(); });
  window.addEventListener("pagehide", trySave);
}
