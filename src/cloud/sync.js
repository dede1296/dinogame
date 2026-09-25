// Cloud save sync. localStorage stays the source of truth while playing; this module
// mirrors it to the `saves` table and pulls it back on other devices.
//
// Sync meta (per device) remembers the last state both sides agreed on, which lets us
// tell "only this device changed" (upload), "only the cloud changed" (download) and
// "both changed" (ask the player) apart.
import { supabase, cloudEnabled } from "./client.js";
import { loadSave, replaceSave, hasProgress, SAVE_EVENT, hasStorage } from "../storage/local.js";

const META_KEY = "dino-cloud-sync-v1";
const UPLOAD_DELAY_MS = 5000;

let state = {
  enabled: cloudEnabled,
  user: null,          // { id, email }
  status: "idle",      // idle | syncing | synced | offline | error | conflict
  lastSyncedAt: null,  // ms timestamp of last successful sync
  error: null,
  conflict: null,      // { local, cloud, cloudUpdatedAt }
};
const listeners = new Set();

function setState(patch) {
  state = { ...state, ...patch };
  listeners.forEach((fn) => fn());
}

export function subscribe(fn) {
  listeners.add(fn);
  return () => listeners.delete(fn);
}
export function getState() {
  return state;
}

function readMeta() {
  try { return JSON.parse(localStorage.getItem(META_KEY)) || null; } catch { return null; }
}
function writeMeta(meta) {
  try { localStorage.setItem(META_KEY, JSON.stringify(meta)); } catch {}
}

// ---------- remote row ----------
async function fetchCloud(userId) {
  const { data, error } = await supabase
    .from("saves")
    .select("data, updated_at")
    .eq("user_id", userId)
    .maybeSingle();
  if (error) throw error;
  return data ? { data: data.data, updatedAt: data.updated_at } : null;
}

async function uploadLocal(userId) {
  const local = loadSave();
  if (!local) return;
  const { savedAt, ...payload } = local;
  const { data, error } = await supabase
    .from("saves")
    .upsert({ user_id: userId, data: payload, updated_at: new Date().toISOString() })
    .select("updated_at")
    .single();
  if (error) throw error;
  writeMeta({ userId, cloudUpdatedAt: data.updated_at, localSavedAt: savedAt });
}

function applyCloud(userId, cloud) {
  const savedAt = Date.now();
  replaceSave(cloud.data, savedAt);
  writeMeta({ userId, cloudUpdatedAt: cloud.updatedAt, localSavedAt: savedAt });
  // The game reads its save once at startup, so reloading is the reliable way to apply it.
  window.location.reload();
}

// ---------- main sync decision ----------
let syncing = null;

export function syncNow() {
  if (!state.user) return Promise.resolve();
  if (!syncing) syncing = doSync().finally(() => { syncing = null; });
  return syncing;
}

async function doSync() {
  const userId = state.user.id;
  if (!navigator.onLine) { setState({ status: "offline" }); return; }
  setState({ status: "syncing", error: null });
  try {
    const cloud = await fetchCloud(userId);
    const local = loadSave();
    const meta = readMeta();
    const knownDevice = meta && meta.userId === userId;

    if (!cloud) {
      await uploadLocal(userId);
    } else if (!knownDevice) {
      // First sync of this account on this device.
      if (!hasProgress(local)) return applyCloud(userId, cloud);
      if (!hasProgress(cloud.data)) await uploadLocal(userId);
      else return setState({ status: "conflict", conflict: { local, cloud: cloud.data, cloudUpdatedAt: cloud.updatedAt } });
    } else {
      const cloudChanged = cloud.updatedAt !== meta.cloudUpdatedAt;
      const localChanged = (local?.savedAt || 0) > (meta.localSavedAt || 0);
      if (cloudChanged && localChanged) {
        return setState({ status: "conflict", conflict: { local, cloud: cloud.data, cloudUpdatedAt: cloud.updatedAt } });
      }
      if (cloudChanged) return applyCloud(userId, cloud);
      if (localChanged) await uploadLocal(userId);
    }
    setState({ status: "synced", lastSyncedAt: Date.now() });
  } catch (e) {
    setState({ status: navigator.onLine ? "error" : "offline", error: e.message || String(e) });
  }
}

// The player picked which save to keep after a conflict.
export async function resolveConflict(keep) {
  const { conflict, user } = state;
  if (!conflict || !user) return;
  setState({ conflict: null });
  if (keep === "cloud") return applyCloud(user.id, { data: conflict.cloud, updatedAt: conflict.cloudUpdatedAt });
  setState({ status: "syncing" });
  try {
    await uploadLocal(user.id);
    setState({ status: "synced", lastSyncedAt: Date.now() });
  } catch (e) {
    setState({ status: "error", error: e.message || String(e) });
  }
}

// ---------- auth ----------
// Email + password, with "Confirm email" disabled in Supabase: no email is ever sent,
// which avoids the custom-SMTP requirement for editing email templates.
export async function signIn(email, password) {
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
}

export async function signUp(email, password) {
  const { data, error } = await supabase.auth.signUp({ email, password });
  if (error) throw error;
  if (!data.session) throw new Error("EMAIL_CONFIRMATION_REQUIRED");
}

export async function signOut() {
  await supabase.auth.signOut();
  try { localStorage.removeItem(META_KEY); } catch {}
  setState({ user: null, status: "idle", lastSyncedAt: null, conflict: null });
}

// ---------- wiring ----------
let uploadTimer = null;

export function initCloudSync() {
  if (!cloudEnabled || !hasStorage) return;

  supabase.auth.onAuthStateChange((_event, session) => {
    const user = session?.user ? { id: session.user.id, email: session.user.email } : null;
    const changed = user?.id !== state.user?.id;
    setState({ user });
    if (user && changed) syncNow();
  });

  // Debounced upload after each local save.
  window.addEventListener(SAVE_EVENT, () => {
    if (!state.user || state.status === "conflict") return;
    clearTimeout(uploadTimer);
    uploadTimer = setTimeout(syncNow, UPLOAD_DELAY_MS);
  });

  window.addEventListener("online", () => syncNow());
  document.addEventListener("visibilitychange", () => {
    if (!state.user || state.status === "conflict") return;
    // Leaving the app: flush pending changes. Coming back: pick up changes from other devices.
    clearTimeout(uploadTimer);
    syncNow();
  });
}
