// Persistent game state for the new game (separate save from the classic game).

const SAVE_KEY = "dino-hybride-v2";

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
    money: 0,
    playTime: 0,
    savedAt: null,
  };
}

export const state = load() || fresh();

function load() {
  try {
    const raw = localStorage.getItem(SAVE_KEY);
    return raw ? { ...fresh(), ...JSON.parse(raw) } : null;
  } catch {
    return null;
  }
}

export function save() {
  try {
    state.savedAt = Date.now();
    localStorage.setItem(SAVE_KEY, JSON.stringify(state));
    return true;
  } catch {
    return false;
  }
}

export function hasSave() {
  try { return localStorage.getItem(SAVE_KEY) !== null; } catch { return false; }
}

export function resetState() {
  Object.assign(state, fresh());
  try { localStorage.removeItem(SAVE_KEY); } catch {}
}

export const flag = (k) => !!state.flags[k];
export const setFlag = (k, v = true) => { state.flags[k] = v; };

export function addItem(id, qty = 1) {
  state.bag[id] = (state.bag[id] || 0) + qty;
}
