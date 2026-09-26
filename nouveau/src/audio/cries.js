// Dino cries. Each family has recorded voices (generated with ElevenLabs Sound Effects,
// see scripts/gen-cries.mjs): a call, an attack, a hurt yelp and a fainting groan. They are
// replayed higher or lower depending on the species' size, with variations: distance,
// left/right position and cave echo. If a recording cannot load, the old synthesizer
// (src/audio/synth.js) makes the cry instead.

import { DINOS } from "../../../src/data/dinos.js";
import { scheduleCry } from "../../../src/audio/cry.js";
import { audioContext, masterOut, echoInput } from "./sounds.js";

const RENDER_SECONDS = 4;
const SILENCE = 0.003;
const cache = new Map(); // file or synth key -> Promise<AudioBuffer | null>

// Cries have their own volume (Réglages › Cris des dinos), on top of the effects volume.
const CRY_VOLUME_KEY = "dino-cry-volume";
const DEFAULT_CRY_VOLUME = 0.5;
let cryVolume = readCryVolume();
let cryBus = null;

function readCryVolume() {
  try {
    const v = parseFloat(localStorage.getItem(CRY_VOLUME_KEY));
    return Number.isFinite(v) ? Math.min(1, Math.max(0, v)) : DEFAULT_CRY_VOLUME;
  } catch { return DEFAULT_CRY_VOLUME; }
}

export const getCryVolume = () => cryVolume;

export function setCryVolume(v) {
  cryVolume = Math.min(1, Math.max(0, v));
  try { localStorage.setItem(CRY_VOLUME_KEY, String(cryVolume)); } catch { /* storage unavailable */ }
  if (cryBus) cryBus.gain.value = cryVolume;
}

function bus(ctx) {
  if (!cryBus) {
    cryBus = ctx.createGain();
    cryBus.gain.value = cryVolume;
    cryBus.connect(masterOut());
  }
  return cryBus;
}

const FAMILY_VOICE = {
  tyrant: "tyran", raptor: "raptor", ceratopsian: "ceratopsien", sauropod: "sauropode", armored: "cuirasse",
  spino: "spino", hadrosaur: "hadrosaure", flyer: "pterosaure", marine: "marin",
};

// file: which recording; rate: pitch and speed; gain: loudness; maxLen: cut after (s);
// slide: pitch drops to rate × slide by the end; wobble: shaky pitch.
const MOODS = {
  normal: { file: "neutre", rate: 1, gain: 1 },
  happy: { file: "neutre", rate: 1.22, gain: 0.8, maxLen: 1 },
  weak: { file: "neutre", rate: 0.9, gain: 0.6, wobble: true },
  attack: { file: "attaque", rate: 1, gain: 0.95 },
  roar: { file: "attaque", rate: 0.9, gain: 1.25 },
  hurt: { file: "degat", rate: 1, gain: 1 },
  faint: { file: "ko", rate: 1, gain: 1, slide: 0.85 },
};

// Big heads sound lower, small ones higher (head size 1–10 in the species data).
const pitchOf = (build) => 1.25 - (DINOS[build.head]?.head.size ?? 5) * 0.045;

function recording(build, file) {
  const voice = FAMILY_VOICE[DINOS[build.head]?.family];
  if (!voice) return Promise.resolve(null);
  const key = `${voice}-${file}`;
  if (!cache.has(key)) cache.set(key, loadRecording(key).catch(() => null));
  return cache.get(key);
}

async function loadRecording(key) {
  const ctx = audioContext();
  const res = await fetch(new URL(`../../assets/cries/${key}.mp3`, import.meta.url));
  if (!res.ok) return null;
  const data = await res.arrayBuffer();
  if (!(res.headers.get("content-type") || "").includes("audio")) return null;
  const buf = await ctx.decodeAudioData(data);
  return normalize(trimSilence(buf));
}

// Fallback: the synthesized cry of this body.
const synthKey = (build) => `synth-${[build.head, build.teeth, build.tail, build.backLegs, build.back].join("-")}`;
function synth(build) {
  const key = synthKey(build);
  if (!cache.has(key)) cache.set(key, renderOffline(build).catch(() => null));
  return cache.get(key);
}

async function soundFor(build, mood) {
  return (await recording(build, mood.file)) || (await synth(build));
}

async function renderOffline(build) {
  const live = audioContext();
  const rate = live?.sampleRate || 44100;
  const OAC = window.OfflineAudioContext || window.webkitOfflineAudioContext;
  if (!OAC) return null;
  const off = new OAC(2, Math.round(rate * RENDER_SECONDS), rate);
  scheduleCry(off, off.destination, build);
  return normalize(trimSilence(await off.startRendering()));
}

// Voices differ a lot in loudness: bring every cry to the same peak level.
const TARGET_PEAK = 0.6;
const MAX_BOOST = 12;
function normalize(buf) {
  let peak = 0;
  for (let c = 0; c < buf.numberOfChannels; c++) for (const v of buf.getChannelData(c)) peak = Math.max(peak, Math.abs(v));
  if (!peak) return buf;
  const k = Math.min(MAX_BOOST, TARGET_PEAK / peak);
  for (let c = 0; c < buf.numberOfChannels; c++) { const d = buf.getChannelData(c); for (let i = 0; i < d.length; i++) d[i] *= k; }
  return buf;
}

// Drops the silent tail so short moods and cut-offs line up with the actual sound.
function trimSilence(buf) {
  const data = buf.getChannelData(0);
  let end = data.length - 1;
  while (end > 0 && Math.abs(data[end]) < SILENCE) end--;
  const len = Math.min(data.length, end + Math.round(buf.sampleRate * 0.05));
  const out = new AudioBuffer({ numberOfChannels: buf.numberOfChannels, length: Math.max(1, len), sampleRate: buf.sampleRate });
  for (let c = 0; c < buf.numberOfChannels; c++) out.copyToChannel(buf.getChannelData(c).subarray(0, len), c);
  return out;
}

/** Loads a dino's cries in advance, so their first play has no delay. */
export function preloadCry(d) {
  if (!audioContext()) return;
  for (const file of ["neutre", "attaque", "degat", "ko"]) recording(d.build || d, file);
}

/**
 * Plays the cry of dino `d` (or a build).
 * opts: mood (see MOODS), volume 0..1, pan -1..1, distance 0 (close) .. 1 (far, muffled), echo 0..1
 */
export async function playCry(d, { mood = "normal", volume = 1, pan = 0, distance = 0, echo = 0 } = {}) {
  const ctx = audioContext();
  if (!ctx || ctx.state !== "running") return;
  const build = d.build || d;
  const m = MOODS[mood] || MOODS.normal;
  const buf = await soundFor(build, m);
  if (!buf) return;
  const t = ctx.currentTime + 0.01;
  const rate = m.rate * pitchOf(build) * (1 + (Math.random() * 2 - 1) * 0.04);
  const length = Math.min(buf.duration / rate, m.maxLen ?? Infinity);

  const src = ctx.createBufferSource();
  src.buffer = buf;
  src.playbackRate.setValueAtTime(rate, t);
  if (m.slide) src.playbackRate.linearRampToValueAtTime(rate * m.slide, t + length);
  if (m.wobble) {
    const lfo = ctx.createOscillator(), depth = ctx.createGain();
    lfo.frequency.value = 9;
    depth.gain.value = rate * 0.08;
    lfo.connect(depth).connect(src.playbackRate);
    lfo.start(t); lfo.stop(t + length + 0.1);
  }

  const gain = ctx.createGain();
  const level = Math.max(0, Math.min(1.5, volume * m.gain));
  gain.gain.setValueAtTime(level, t);
  gain.gain.setValueAtTime(level, t + Math.max(0, length - 0.12));
  gain.gain.linearRampToValueAtTime(0, t + length);

  // Far away: quieter highs, like through the trees.
  const tone = ctx.createBiquadFilter();
  tone.type = "lowpass";
  tone.frequency.value = 9000 - Math.min(1, distance) * 7800;
  const panner = ctx.createStereoPanner ? ctx.createStereoPanner() : null;
  if (panner) panner.pan.value = Math.max(-1, Math.min(1, pan));

  let out = src.connect(tone).connect(gain);
  if (panner) out = out.connect(panner);
  out.connect(bus(ctx));
  if (echo > 0) {
    const send = ctx.createGain();
    send.gain.value = echo;
    out.connect(send).connect(echoInput());
    send.gain.value = echo * cryVolume;
  }
  src.start(t);
  src.stop(t + length + 0.05);
}
