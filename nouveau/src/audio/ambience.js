// Ambience: the sounds of a place under the music (recordings made with ElevenLabs by
// scripts/gen-ambience.mjs, in nouveau/assets/ambience/).
// - Beds: long recordings looped with a cross-fade, so the seam is never heard.
//   Some follow where Chloé is: the sea gets louder near the beach, a campfire when close.
// - Calls: short sounds (birds, seagulls, a gust of wind, a drop) scattered at random,
//   from random sides, so the place never sounds like a loop.
// It follows the "Ambiance" volume (Réglages).

import { audioContext } from "./sounds.js";
import { storedVolume } from "./mixer.js";

const volume = storedVolume("dino-ambience-volume", 0.8);
const XFADE_S = 2.5; // overlap of two passes of a bed
const FADE_S = 1.5; // change of place
const DUCKED = 0.5; // under a recorded voice line

// A bed: [sound, level, follows?]. `follows`: "sea" or "fire", a 0..1 level set by the map.
// A call: { ids, every: [min, max] seconds, vol, follows? }.
const BIRDS = ["oiseau-1", "oiseau-2", "oiseau-3"];
export const AMBIENCES = {
  port: {
    beds: [["village", 1], ["vagues", 0.9, "sea"], ["feu", 1, "fire"]],
    calls: [{ ids: ["mouettes"], every: [12, 28], vol: 0.45, follows: "sea" }, { ids: ["oiseau-1", "oiseau-2"], every: [14, 32], vol: 0.3 }],
  },
  plaines: {
    beds: [["prairie", 0.55], ["vent", 0.35], ["feu", 1, "fire"]],
    calls: [{ ids: BIRDS, every: [5, 14], vol: 0.4 }, { ids: ["rafale"], every: [18, 40], vol: 0.4 }],
  },
  grotte: {
    beds: [["grotte", 0.75], ["feu", 1, "fire"]],
    calls: [{ ids: ["goutte"], every: [4, 12], vol: 0.45 }],
  },
  cabinet: { beds: [["labo", 1]], calls: [] },
  maison: { beds: [["maison", 0.9]], calls: [] },
  boutique: { beds: [["maison", 0.55]], calls: [] },
  // Later chapters.
  foret: { beds: [["foret", 0.6]], calls: [{ ids: BIRDS, every: [6, 16], vol: 0.3 }] },
  marais: { beds: [["marais", 0.6]], calls: [{ ids: ["goutte"], every: [8, 20], vol: 0.3 }] },
  desert: { beds: [["desert", 0.55]], calls: [{ ids: ["rafale"], every: [12, 30], vol: 0.45 }] },
  cote: { beds: [["cote", 0.6], ["vagues", 0.5, "sea"]], calls: [{ ids: ["mouettes"], every: [8, 20], vol: 0.45 }] },
  monts: { beds: [["monts", 0.6]], calls: [{ ids: ["rafale"], every: [10, 25], vol: 0.5 }] },
  cieux: { beds: [["cieux", 0.6]], calls: [{ ids: ["rafale"], every: [12, 30], vol: 0.4 }] },
  volcan: { beds: [["volcan", 0.65]], calls: [] },
};

let bus = null, duck = null, pause = null;
let current = null; // { id, beds, timers }
let mix = { sea: 0, fire: 0 };
const buffers = new Map(); // sound -> Promise<AudioBuffer | null>

function outputs(ctx) {
  if (!bus) {
    bus = ctx.createGain();
    bus.gain.value = volume.get();
    // Knocks, ticks and crackles are sharp: a limiter keeps them from ever clipping.
    const limiter = ctx.createDynamicsCompressor();
    limiter.threshold.value = -10;
    limiter.ratio.value = 10;
    limiter.attack.value = 0.003;
    limiter.release.value = 0.15;
    bus.connect(limiter).connect(ctx.destination);
    duck = ctx.createGain();
    duck.connect(bus);
    pause = ctx.createGain();
    pause.connect(duck);
    ctx.addEventListener?.("statechange", () => { if (ctx.state === "running" && current && !current.started) start(current); });
  }
  return pause;
}

function load(ctx, name) {
  if (!buffers.has(name)) {
    buffers.set(name, (async () => {
      const res = await fetch(new URL(`../../assets/ambience/${name}.mp3`, import.meta.url));
      if (!res.ok || !(res.headers.get("content-type") || "").includes("audio")) return null;
      return normalize(await ctx.decodeAudioData(await res.arrayBuffer()));
    })().catch(() => null));
  }
  return buffers.get(name);
}

// The recordings come out at very different levels: bring each one to the same typical
// loudness (without clipping), so the levels in AMBIENCES mean the same for all.
// Typical = the median loudness of short windows, so one loud gust or a single bird
// does not decide the level of a whole recording.
const TARGET_RMS = 0.1;
const MAX_PEAK = 0.9;
const WINDOW_S = 0.4;
function normalize(buf) {
  const d0 = buf.getChannelData(0), win = Math.floor(buf.sampleRate * WINDOW_S);
  let peak = 0;
  for (let ch = 0; ch < buf.numberOfChannels; ch++) for (const v of buf.getChannelData(ch)) peak = Math.max(peak, Math.abs(v));
  const windows = [];
  for (let i = 0; i + win <= d0.length; i += win) {
    let sum = 0;
    for (let j = i; j < i + win; j++) sum += d0[j] * d0[j];
    windows.push(Math.sqrt(sum / win));
  }
  const typical = windows.sort((a, b) => a - b)[Math.floor(windows.length / 2)];
  if (!typical || !peak) return buf;
  const gain = Math.min(TARGET_RMS / typical, MAX_PEAK / peak);
  for (let ch = 0; ch < buf.numberOfChannels; ch++) {
    const d = buf.getChannelData(ch);
    for (let i = 0; i < d.length; i++) d[i] *= gain;
  }
  return buf;
}

// One bed: passes of the recording, each fading into the next.
function startBed(ctx, amb, [name, level, follows]) {
  const out = ctx.createGain();
  out.gain.value = follows ? level * mix[follows] : level;
  out.connect(amb.out);
  const bed = { name, level, follows, out, stopped: false };
  load(ctx, name).then((buf) => {
    if (!buf || bed.stopped) return;
    const len = buf.duration;
    let at = ctx.currentTime + 0.05;
    let offset = Math.random() * Math.max(0, len - XFADE_S * 2); // beds never start in sync
    const pass = () => {
      if (bed.stopped) return;
      const src = ctx.createBufferSource();
      src.buffer = buf;
      const g = ctx.createGain();
      const playFor = len - offset;
      g.gain.setValueAtTime(0, at);
      // The very first pass comes in quickly (the whole ambience already fades in).
      g.gain.linearRampToValueAtTime(1, at + (bed.src ? XFADE_S : 0.1));
      g.gain.setValueAtTime(1, at + playFor - XFADE_S);
      g.gain.linearRampToValueAtTime(0, at + playFor);
      src.connect(g).connect(out);
      src.start(at, offset);
      src.stop(at + playFor + 0.05);
      bed.src = src;
      const next = at + playFor - XFADE_S;
      bed.timer = setTimeout(pass, Math.max(0, (next - ctx.currentTime - 1) * 1000));
      at = next;
      offset = 0;
    };
    pass();
  });
  return bed;
}

// Calls: every few seconds, one of the sounds from a random side.
function startCalls(ctx, amb, call) {
  const timer = { id: null };
  const next = () => {
    const [min, max] = call.every;
    timer.id = setTimeout(async () => {
      if (amb.stopped) return;
      const level = call.follows ? mix[call.follows] : 1;
      if (level > 0.05 && ctx.state === "running") {
        const buf = await load(ctx, call.ids[Math.floor(Math.random() * call.ids.length)]);
        if (buf && !amb.stopped) {
          const src = ctx.createBufferSource();
          src.buffer = buf;
          src.playbackRate.value = 0.94 + Math.random() * 0.12;
          const g = ctx.createGain();
          g.gain.value = call.vol * level * (0.6 + Math.random() * 0.4);
          let tail = src.connect(g);
          if (ctx.createStereoPanner) { const p = ctx.createStereoPanner(); p.pan.value = Math.random() * 1.4 - 0.7; tail = tail.connect(p); }
          tail.connect(amb.out);
          src.start();
        }
      }
      next();
    }, (min + Math.random() * (max - min)) * 1000);
  };
  next();
  return timer;
}

function start(amb) {
  const ctx = audioContext();
  if (!ctx || ctx.state !== "running") return;
  amb.started = true;
  const def = AMBIENCES[amb.id];
  amb.out.gain.setValueAtTime(0, ctx.currentTime);
  amb.out.gain.linearRampToValueAtTime(1, ctx.currentTime + FADE_S);
  amb.beds = def.beds.map((b) => startBed(ctx, amb, b));
  amb.calls = def.calls.map((c) => startCalls(ctx, amb, c));
}

function stop(amb, fade) {
  const ctx = audioContext();
  amb.stopped = true;
  amb.beds?.forEach((b) => { b.stopped = true; clearTimeout(b.timer); });
  amb.calls?.forEach((t) => clearTimeout(t.id));
  if (!ctx) return;
  amb.out.gain.cancelScheduledValues(ctx.currentTime);
  amb.out.gain.setValueAtTime(amb.out.gain.value, ctx.currentTime);
  amb.out.gain.linearRampToValueAtTime(0, ctx.currentTime + fade);
  setTimeout(() => { amb.beds?.forEach((b) => { try { b.src?.stop(); } catch { /* ended */ } }); amb.out.disconnect(); }, (fade + 0.2) * 1000);
}

// ---------------------------------------------------------------- public
export const getAmbienceVolume = () => volume.get();

export function setAmbienceVolume(v) {
  const val = volume.set(v);
  if (bus) bus.gain.value = val;
}

/** The ambience of the place (for the tests). */
export const currentAmbience = () => current?.id ?? null;

/** Cross-fades to the ambience `id` (AMBIENCES), or silence with null. */
export function setAmbience(id, fade = FADE_S) {
  if ((current?.id ?? null) === (id || null)) return;
  if (current) stop(current, fade);
  current = null;
  const ctx = audioContext();
  if (!id || !ctx || !AMBIENCES[id]) return;
  const out = ctx.createGain();
  out.gain.value = 0;
  out.connect(outputs(ctx));
  current = { id, out, started: false, stopped: false };
  start(current);
}

/** Levels (0..1) of the beds that follow the map: { sea, fire }. */
export function setAmbienceMix(levels) {
  mix = { ...mix, ...levels };
  const ctx = audioContext();
  if (!ctx || !current?.beds) return;
  for (const b of current.beds) {
    if (b.follows) b.out.gain.setTargetAtTime(b.level * mix[b.follows], ctx.currentTime, 0.4);
  }
}

/** Silences the place during a battle (and back afterwards). */
export function pauseAmbience(on) {
  const ctx = audioContext();
  if (!ctx) return;
  outputs(ctx).gain.setTargetAtTime(on ? 0 : 1, ctx.currentTime, on ? 0.2 : 0.8);
}

/** Lowers the place under a recorded voice line. */
export function duckAmbience(on) {
  const ctx = audioContext();
  if (!ctx || !duck) return;
  duck.gain.setTargetAtTime(on ? DUCKED : 1, ctx.currentTime, on ? 0.15 : 0.6);
}
