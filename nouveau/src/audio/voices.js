// Character voices in dialogues.
// - Every line: little "voice" blips while the text scrolls, like Animal Crossing or
//   Pokémon, with a pitch and timbre per character.
// - A few key lines (data/voiceLines.js): a real recorded voice instead.
// Both follow the "Voix" volume (Réglages).

import { audioContext, masterOut } from "./sounds.js";
import { VOICE_LINES, voiceLineFor } from "../data/voiceLines.js";

const VOICE_VOLUME_KEY = "dino-voice-volume";
const DEFAULT_VOICE_VOLUME = 0.7;
let voiceVolume = readVolume();
let voiceBus = null;

function readVolume() {
  try {
    const v = parseFloat(localStorage.getItem(VOICE_VOLUME_KEY));
    return Number.isFinite(v) ? Math.min(1, Math.max(0, v)) : DEFAULT_VOICE_VOLUME;
  } catch { return DEFAULT_VOICE_VOLUME; }
}

export const getVoiceVolume = () => voiceVolume;

export function setVoiceVolume(v) {
  voiceVolume = Math.min(1, Math.max(0, v));
  try { localStorage.setItem(VOICE_VOLUME_KEY, String(voiceVolume)); } catch { /* storage unavailable */ }
  if (voiceBus) voiceBus.gain.value = voiceVolume;
}

function bus(ctx) {
  if (!voiceBus) {
    voiceBus = ctx.createGain();
    voiceBus.gain.value = voiceVolume;
    voiceBus.connect(masterOut());
  }
  return voiceBus;
}

// ---------------------------------------------------------------- blips
// pitch (Hz), wave, formant (the vowel colour, Hz), every: one blip per this many letters.
const PROFILES = {
  "Prof. Roc": { pitch: 150, wave: "triangle", formant: 900, every: 4 },
  "Maïa": { pitch: 360, wave: "square", formant: 1700, every: 3 },
  "Chloé": { pitch: 300, wave: "triangle", formant: 1500, every: 3 },
  "Hélène": { pitch: 250, wave: "sine", formant: 1100, every: 4 },
  "Rosalie": { pitch: 280, wave: "triangle", formant: 1300, every: 3 },
  "Mamie Rose": { pitch: 230, wave: "sine", formant: 1000, every: 4 },
  "Pêcheur": { pitch: 130, wave: "sawtooth", formant: 800, every: 4 },
  "Randonneur": { pitch: 170, wave: "triangle", formant: 1000, every: 3 },
  "Petit Léo": { pitch: 420, wave: "square", formant: 2000, every: 2 },
};
// Anyone else (villagers, hooded grunts…): a neutral middle voice.
const DEFAULT_PROFILE = { pitch: 200, wave: "triangle", formant: 1100, every: 3 };
const BLIP_S = 0.055;
const BLIP_LEVEL = 0.07;

export const blipEvery = (speaker) => (PROFILES[speaker] || DEFAULT_PROFILE).every;

/** One little voice blip for `speaker` (narration has none). */
export function blip(speaker) {
  const ctx = audioContext();
  if (!speaker || !ctx || ctx.state !== "running" || !voiceVolume) return;
  const p = PROFILES[speaker] || DEFAULT_PROFILE;
  const t = ctx.currentTime;
  const osc = ctx.createOscillator();
  osc.type = p.wave;
  osc.frequency.value = p.pitch * (1 + (Math.random() * 2 - 1) * 0.12);
  const vowel = ctx.createBiquadFilter();
  vowel.type = "bandpass";
  vowel.frequency.value = p.formant * (0.85 + Math.random() * 0.3);
  vowel.Q.value = 3;
  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t);
  env.gain.linearRampToValueAtTime(BLIP_LEVEL * 4, t + 0.006);
  env.gain.exponentialRampToValueAtTime(0.0001, t + BLIP_S);
  osc.connect(vowel).connect(env).connect(bus(ctx));
  osc.start(t);
  osc.stop(t + BLIP_S + 0.01);
}

// ---------------------------------------------------------------- recorded lines
const buffers = new Map(); // line id -> Promise<AudioBuffer | null>

function load(id) {
  if (!buffers.has(id)) {
    buffers.set(id, (async () => {
      const ctx = audioContext();
      const res = await fetch(new URL(`../../assets/voices/${id}.mp3`, import.meta.url));
      if (!res.ok) return null;
      const data = await res.arrayBuffer();
      // A missing file comes back as an HTML page: do not try to decode it.
      if (!(res.headers.get("content-type") || "").includes("audio")) return null;
      return await ctx.decodeAudioData(data);
    })().catch(() => null));
  }
  return buffers.get(id);
}

/** Loads the recorded lines of a scene ahead (ids from data/voiceLines.js). */
export function preloadVoices(prefix) {
  if (!audioContext()) return;
  VOICE_LINES.filter((l) => l.id.startsWith(prefix)).forEach((l) => load(l.id));
}

/**
 * Plays the recording of a voiced line (by id, or by its exact text).
 * Returns a function that stops it, or null when there is no recording to play.
 */
export async function speakLine(idOrText) {
  const ctx = audioContext();
  if (!ctx || ctx.state !== "running" || !voiceVolume) return null;
  const id = VOICE_LINES.some((l) => l.id === idOrText) ? idOrText : voiceLineFor(idOrText)?.id;
  if (!id) return null;
  const buf = await load(id);
  if (!buf) return null;
  const src = ctx.createBufferSource();
  src.buffer = buf;
  src.connect(bus(ctx));
  src.start();
  return () => { try { src.stop(); } catch { /* already ended */ } };
}

/** True when this text is one of the voiced lines. */
export const isVoiced = (text) => !!voiceLineFor(text);
