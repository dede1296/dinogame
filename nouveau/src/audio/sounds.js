// Sampled sound effects (Kenney.nl, CC0), converted to small WAV files by scripts/convert-sfx.mjs.
// One shared AudioContext, unlocked on the first touch or key press (required on iOS).

const NAMES = [
  "step_grass_0", "step_grass_1", "step_grass_2", "step_grass_3", "step_wood_0", "step_wood_1",
  "step_stone_0", "step_stone_1", "step_stone_2", "step_carpet_0", "step_carpet_1",
  "door_open", "door_close", "bump", "ui_move", "ui_ok", "ui_back", "ui_open", "ui_close", "text",
  "item", "coins", "page", "cloth", "rock_0", "rock_1", "rock_heavy", "wood_heavy", "chop", "slice",
  "hit_0", "hit_1", "hit_soft", "glass", "machine", "latch",
];

// Sounds with several takes: play("step_grass") picks one at random.
const VARIANTS = {};
for (const n of NAMES) {
  const m = n.match(/^(.*)_(\d)$/);
  if (m) (VARIANTS[m[1]] ||= []).push(n);
}

let ctx = null;
let master = null;
const buffers = {};
let loading = null;

export function audioContext() {
  if (!ctx) {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    ctx = new AC();
    master = ctx.createGain();
    master.gain.value = 0.8;
    master.connect(ctx.destination);
  }
  if (ctx.state === "suspended") ctx.resume();
  return ctx;
}

export function masterOut() {
  audioContext();
  return master;
}

function loadAll() {
  if (loading) return loading;
  const c = audioContext();
  if (!c) return Promise.resolve();
  loading = Promise.all(NAMES.map(async (n) => {
    try {
      const res = await fetch(new URL(`../../assets/sfx/${n}.wav`, import.meta.url));
      const data = await res.arrayBuffer();
      buffers[n] = await new Promise((ok, ko) => c.decodeAudioData(data, ok, ko));
    } catch { /* a missing sound must never break the game */ }
  }));
  return loading;
}

export function unlockAudio() {
  const once = () => {
    audioContext();
    loadAll();
    window.removeEventListener("pointerdown", once);
    window.removeEventListener("keydown", once);
  };
  window.addEventListener("pointerdown", once);
  window.addEventListener("keydown", once);
}

/**
 * Plays a sound. `name` is a file name, or a family name picking a random take ("step_grass").
 * @param opts { volume = 1, rate = 1, jitter = 0 (random pitch spread), delay = 0 (s) }
 */
export function play(name, { volume = 1, rate = 1, jitter = 0, delay = 0 } = {}) {
  if (!ctx || ctx.state !== "running") return;
  const pool = VARIANTS[name];
  const key = pool ? pool[Math.floor(Math.random() * pool.length)] : name;
  const buf = buffers[key];
  if (!buf) return;
  const src = ctx.createBufferSource();
  src.buffer = buf;
  src.playbackRate.value = rate * (1 + (Math.random() * 2 - 1) * jitter);
  const g = ctx.createGain();
  g.gain.value = volume;
  src.connect(g).connect(master);
  src.start(ctx.currentTime + delay);
}
