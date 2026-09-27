// Prepares the ambience recordings (ElevenLabs, MP3 in nouveau/assets/ambience/, or in
// Godot/tools/sounds/ for the ones made for Godot with gen-sound.mjs) for the
// game: MP3 → Ogg Vorbis in Godot/assets/audio/ambience/, each brought to the same typical
// loudness, so the levels in data/ambience_db.gd mean the same for every sound.
// Typical = the median loudness of short windows (one gust or one bird call does not decide
// the level of a whole recording); never louder than MAX_PEAK. Some recordings also get a
// steady whistle removed (a pure tone ElevenLabs sometimes renders for "insects"): NOTCHES;
// or everything shrill cut (crickets and hiss hide in the highs): LOWPASS.
// Needs mpg123-decoder and wasm-media-encoders (npm i them in a scratch folder, then pass
// the node_modules folder in AUDIO_MODULES).
// Usage (from the repository root): AUDIO_MODULES=<node_modules> node Godot/tools/prepare-ambience.mjs [name…]
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

const SOURCES = ["Godot/tools/sounds", "nouveau/assets/ambience"];
const OUT = "Godot/assets/audio/ambience";
// Loops (beds) and short calls used by the game's places (see AmbienceDB).
const NAMES = ["brise", "rafale", "oiseau-1", "oiseau-2", "oiseau-3", "village", "vagues", "mouettes",
  "feu", "grotte", "goutte", "labo", "maison"];
const NOTCHES = {};
const LOWPASS = { brise: 2500, labo: 1800 };   // Hz (labo: whistles at 5.6 and 16.5 kHz, half its energy above 12 kHz)
const TARGET_RMS = 0.1;
const MAX_PEAK = 0.9;
const WINDOW_S = 0.4;
const Q = 9;         // notch: narrow, only the whistle goes
const PASSES = 2;    // each notch applied twice for a deeper cut
const PRIME_S = 1.0; // the loop's end runs through the filter first: the loop point stays seamless

const modules = process.env.AUDIO_MODULES;
const load = (name, entry) => import(modules ? pathToFileURL(path.join(modules, name, entry)).href : name);
const { MPEGDecoder } = await load("mpg123-decoder", "index.js");
const { createOggEncoder } = await load("wasm-media-encoders", "dist/esnext/index.mjs");

function notch(freq, sampleRate) {
  const w = (2 * Math.PI * freq) / sampleRate;
  const alpha = Math.sin(w) / (2 * Q);
  const a0 = 1 + alpha;
  return { b0: 1 / a0, b1: (-2 * Math.cos(w)) / a0, b2: 1 / a0, a1: (-2 * Math.cos(w)) / a0, a2: (1 - alpha) / a0 };
}

function filter(samples, c) {
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  const out = new Float32Array(samples.length);
  for (let i = 0; i < samples.length; i++) {
    const x = samples[i];
    const y = c.b0 * x + c.b1 * x1 + c.b2 * x2 - c.a1 * y1 - c.a2 * y2;
    x2 = x1; x1 = x; y2 = y1; y1 = y;
    out[i] = y;
  }
  return out;
}

// RBJ cookbook low-pass biquad (Butterworth Q).
function lowpass(freq, sampleRate) {
  const w = (2 * Math.PI * freq) / sampleRate;
  const alpha = Math.sin(w) / (2 * Math.SQRT1_2);
  const cs = Math.cos(w), a0 = 1 + alpha;
  return { b0: (1 - cs) / 2 / a0, b1: (1 - cs) / a0, b2: (1 - cs) / 2 / a0, a1: (-2 * cs) / a0, a2: (1 - alpha) / a0 };
}

function filtered(channels, filters, sampleRate) {
  const prime = Math.min(Math.round(PRIME_S * sampleRate), channels[0].length);
  return channels.map((ch) => {
    let buf = new Float32Array(prime + ch.length);
    buf.set(ch.subarray(ch.length - prime), 0);
    buf.set(ch, prime);
    for (const c of filters) buf = filter(buf, c);
    return buf.subarray(prime);
  });
}

function loudnessGain(channels, sampleRate) {
  let peak = 0;
  for (const ch of channels) for (const v of ch) peak = Math.max(peak, Math.abs(v));
  const win = Math.floor(sampleRate * WINDOW_S);
  const windows = [];
  for (let i = 0; i + win <= channels[0].length; i += win) {
    let sum = 0;
    for (let j = i; j < i + win; j++) sum += channels[0][j] * channels[0][j];
    windows.push(Math.sqrt(sum / win));
  }
  windows.sort((a, b) => a - b);
  const typical = windows[Math.floor(windows.length / 2)];
  if (!typical || !peak) return 1;
  return Math.min(TARGET_RMS / typical, MAX_PEAK / peak);
}

async function prepare(name) {
  const decoder = new MPEGDecoder();
  await decoder.ready;
  const source = SOURCES.map((dir) => `${dir}/${name}.mp3`).find((f) => fs.existsSync(f));
  const { channelData, sampleRate } = decoder.decode(new Uint8Array(fs.readFileSync(source)));
  decoder.free();
  let channels = channelData.slice(0, 2);
  const filters = [
    ...(NOTCHES[name] ?? []).flatMap((f) => Array(PASSES).fill(notch(f, sampleRate))),
    ...(LOWPASS[name] ? Array(PASSES).fill(lowpass(LOWPASS[name], sampleRate)) : []),
  ];
  if (filters.length) channels = filtered(channels, filters, sampleRate);
  const gain = loudnessGain(channels, sampleRate);
  channels = channels.map((ch) => ch.map((v) => v * gain));
  const encoder = await createOggEncoder();
  encoder.configure({ channels: channels.length, sampleRate, vbrQuality: 5 });
  const parts = [];
  const BLOCK = 8192;
  for (let i = 0; i < channels[0].length; i += BLOCK) {
    parts.push(Buffer.from(encoder.encode(channels.map((ch) => ch.subarray(i, i + BLOCK)))));
  }
  parts.push(Buffer.from(encoder.finalize()));
  fs.writeFileSync(`${OUT}/${name}.ogg`, Buffer.concat(parts));
  console.log(`${OUT}/${name}.ogg : ${(channels[0].length / sampleRate).toFixed(1)} s, gain ${(20 * Math.log10(gain)).toFixed(1)} dB`
    + (NOTCHES[name] ? `, notch ${NOTCHES[name].join(", ")} Hz` : "") + (LOWPASS[name] ? `, passe-bas ${LOWPASS[name]} Hz` : ""));
}

const wanted = process.argv.slice(2);
for (const name of wanted.length ? wanted : NAMES) await prepare(name);
