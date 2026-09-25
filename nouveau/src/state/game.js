// Persistent game state for the new game (separate save from the classic game).

// Three save slots, plus a separate one for debug mode so it never touches real games.
// Slot 1 keeps the original key, so older saves show up there.
export const SLOTS = [1, 2, 3];
const keyOf = (slot) => (slot === 1 ? "dino-hybride-v2" : `dino-hybride-v2-${slot}`);
let slot = 1;

function fresh() {
  return {
    version: 1,
    map: "ambreluneSud",
    x: null,
    y: null,
    dir: "up",
    flags: {},
    bag: {},        // itemId -> quantity
    amber: [],      // species names whose amber fragment was found
    fossils: [],    // fossil parts found
    journal: [],    // page numbers found
    party: [],      // dinos: { species, nickname, level, xp }
    // Where Chloé wakes up after losing a battle: the last place she rested.
    respawn: { map: "cabinet", x: 6, y: 5, dir: "up", name: "au Cabinet" },
    money: 0,
    playTime: 0,
    savedAt: null,
  };
}

export const state = fresh();

function read(s) {
  try {
    const raw = localStorage.getItem(keyOf(s));
    return raw ? { ...fresh(), ...JSON.parse(raw) } : null;
  } catch {
    return null;
  }
}

function replaceState(next) {
  for (const k of Object.keys(state)) delete state[k];
  Object.assign(state, next);
}

/** Makes `s` (1, 2, 3 or "debug") the active slot and loads it (or a fresh game). */
export function useSlot(s) {
  slot = s;
  replaceState(read(s) || fresh());
}

/** Short summary of a slot for the title screen, or null when empty. */
export function slotInfo(s) {
  const d = read(s);
  if (!d) return null;
  return { lead: d.party[0] || null, count: d.party.length, savedAt: d.savedAt, flags: d.flags };
}

export function deleteSlot(s) {
  try { localStorage.removeItem(keyOf(s)); } catch { /* storage unavailable */ }
}

export function save() {
  try {
    state.savedAt = Date.now();
    localStorage.setItem(keyOf(slot), JSON.stringify(state));
    return true;
  } catch {
    return false;
  }
}

export function hasSave(s = slot) {
  try { return localStorage.getItem(keyOf(s)) !== null; } catch { return false; }
}

export function resetState() {
  replaceState(fresh());
  deleteSlot(slot);
}

export const flag = (k) => !!state.flags[k];
export const setFlag = (k, v = true) => { state.flags[k] = v; };

export function addItem(id, qty = 1) {
  state.bag[id] = (state.bag[id] || 0) + qty;
}
