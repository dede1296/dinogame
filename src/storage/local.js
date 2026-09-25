// ============ PERSISTENCE LAYER ============
// The game always saves to localStorage first (works offline). Each save carries a
// `savedAt` timestamp that only moves when the content actually changes, so the cloud
// sync can tell whether this device has unsynced progress.
export const STORAGE_KEY = "cabinet-de-chloe-v1";
export const SAVE_EVENT = "dino-save-changed";

export const hasStorage = (() => {
  try {
    if (typeof window === "undefined" || !window.localStorage) return false;
    window.localStorage.setItem("__test", "1");
    window.localStorage.removeItem("__test");
    return true;
  } catch (e) { return false; }
})();

export function loadSave() {
  if (!hasStorage) return null;
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch (e) { return null; }
}

function withoutMeta(data) {
  const { savedAt, ...rest } = data || {};
  return rest;
}

export function writeSave(data) {
  if (!hasStorage) return;
  try {
    const previous = loadSave();
    if (previous && JSON.stringify(withoutMeta(previous)) === JSON.stringify(withoutMeta(data))) return;
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify({ ...withoutMeta(data), savedAt: Date.now() }));
    window.dispatchEvent(new Event(SAVE_EVENT));
  } catch (e) {}
}

// Replaces the local save wholesale (used when restoring from the cloud).
export function replaceSave(data, savedAt) {
  if (!hasStorage) return;
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify({ ...withoutMeta(data), savedAt }));
  } catch (e) {}
}

// True when a save holds real progress worth protecting, not just the starting state.
export function hasProgress(data) {
  if (!data) return false;
  return (data.level || 1) > 1
    || (data.totalWins || 0) > 0
    || (data.saved?.length || 0) > 0
    || Object.keys(data.bestiary || {}).length > 0;
}

// Short human summary of a save, shown when the player must choose between two.
export function describeSave(data) {
  if (!data) return "Aucune sauvegarde";
  return `${data.name || "Mon Hybride"} · Niv.${data.level || 1} · ${data.totalWins || 0} victoire(s) · ${(data.saved || []).length} dino(s) archivé(s)`;
}
