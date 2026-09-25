// ============ PERSISTENCE LAYER ============
export const STORAGE_KEY = "cabinet-de-chloe-v1";
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

export function writeSave(data) {
  if (!hasStorage) return;
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  } catch (e) {}
}
