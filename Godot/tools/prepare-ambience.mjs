// Prepares the ambience recordings (ElevenLabs, MP3 in nouveau/assets/ambience/, or in
// Godot/tools/sounds/ for the ones made for Godot with gen-sound.mjs) for the
// game: MP3 → Ogg Vorbis in Godot/assets/audio/ambience/, each brought to the same typical
// loudness, so the levels in data/ambience_db.gd mean the same for every sound.
// Typical = the median loudness of short windows (one gust or one bird call does not decide
// the level of a whole recording); never louder than MAX_PEAK. Some recordings also get a
// steady whistle removed (a pure tone ElevenLabs sometimes renders for "insects"): NOTCHES;
// or everything shrill cut (crickets and hiss hide in the highs): LOWPASS; or a rumble below
// hearing cut (it would decide the loudness): HIGHPASS. Each line printed says how much of the
// energy is left above 4 kHz (the player does not want shrill sounds: keep it near 0 %).
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
  "feu", "grotte", "goutte", "labo", "maison", "desert", "eau", "monts", "rafale-grave", "blizzard", "glace"];
// Made from another recording: output name -> source name.
const FROM = { "rafale-grave": "rafale" };
// Hz. labo: whistles at 5.6 and 16.5 kHz, half its energy above 12 kHz. (The web's
// foret.mp3 is not used: a cricket drone, 92 % of its energy above 4 kHz, and a whistle
// sweeping 2-2.9 kHz; filtered, nothing worth keeping is left. Likewise the web's marais.mp3,
// 99.5 % of its energy crammed into 1-3 kHz with a screaming peak near 2 kHz, and vent.mp3,
// 94 % above 4 kHz: both dropped, no filter could save them. desert.mp3 is clean (92.5 % below
// 500 Hz) bar a faint peak near 2 kHz worth ~0.1 % of its energy — too small to matter, no
// filter applied. eau: three ElevenLabs takes at a calm marsh/frog ambience came back as a
// piercing 1-2 kHz chirp (same shape as the failed marais.mp3); a fourth, quieter/muffled take
// ("no splash, no droplets, deep muffled tone") finally came back clean (97 % below 500 Hz) and
// is used as-is — the marsh's water bed. No usable frog take was found in three tries; the
// marsh ambience leans on brise/goutte/birds instead (see ambience_db.gd).
// Monts Gelés (29/09): monts.mp3 (web) is clean, 0.02 % above 4 kHz, no narrow peak: as-is.
// rafale.mp3 has 45 % of its energy above 4 kHz (a hiss, whistles at 7.7 and 9.8 kHz):
// "rafale-grave" is it cut to a low whoosh for the Monts (0.01 % above 4 kHz; its sub-bass
// rumble cut too, or it would set the loudness); rafale.ogg itself is left as it was (the
// Plaines, the Désert's sandstorm). goutte.mp3: its drop is at 0.9-1.3 kHz, 10 % of clicks
// above 4 kHz, cut (0.03 %). blizzard, glace (tools/sounds, gen-sound.mjs): a deep howling
// blizzard (100 % below 1 kHz) and a low groan of glacier ice (100 % below 2 kHz): as-is.
const NOTCHES = {};
const LOWPASS = { brise: 2500, labo: 1800, goutte: 3000, "rafale-grave": 1000 };
const HIGHPASS = { "rafale-grave": 80 };
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

// RBJ cookbook high-pass biquad (Butterworth Q).
function highpass(freq, sampleRate) {
  const w = (2 * Math.PI * freq) / sampleRate;
  const alpha = Math.sin(w) / (2 * Math.SQRT1_2);
  const cs = Math.cos(w), a0 = 1 + alpha;
  return { b0: (1 + cs) / 2 / a0, b1: -(1 + cs) / a0, b2: (1 + cs) / 2 / a0, a1: (-2 * cs) / a0, a2: (1 - alpha) / a0 };
}

// Share (%) of the energy above 4 kHz (FFT over windows of 4096 samples, first channel).
function shareAbove4k(samples, sampleRate) {
  const N = 4096, cut = Math.ceil((4000 * N) / sampleRate);
  let high = 0, all = 0;
  for (let off = 0; off + N <= samples.length; off += N) {
    const re = new Float64Array(N), im = new Float64Array(N);
    for (let i = 0; i < N; i++) re[i] = samples[off + i] * (0.5 - 0.5 * Math.cos((2 * Math.PI * i) / (N - 1)));
    fft(re, im);
    for (let k = 1; k < N / 2; k++) {
      const e = re[k] * re[k] + im[k] * im[k];
      all += e;
      if (k >= cut) high += e;
    }
  }
  return all ? (100 * high) / all : 0;
}

function fft(re, im) {
  const n = re.length;
  for (let i = 1, j = 0; i < n; i++) {
    let bit = n >> 1;
    for (; j & bit; bit >>= 1) j ^= bit;
    j ^= bit;
    if (i < j) { [re[i], re[j]] = [re[j], re[i]]; [im[i], im[j]] = [im[j], im[i]]; }
  }
  for (let len = 2; len <= n; len <<= 1) {
    const ang = (-2 * Math.PI) / len;
    for (let i = 0; i < n; i += len) {
      for (let k = 0; k < len / 2; k++) {
        const wr = Math.cos(ang * k), wi = Math.sin(ang * k);
        const h = i + k + len / 2;
        const tr = re[h] * wr - im[h] * wi, ti = re[h] * wi + im[h] * wr;
        re[h] = re[i + k] - tr; im[h] = im[i + k] - ti;
        re[i + k] += tr; im[i + k] += ti;
      }
    }
  }
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
  const source = SOURCES.map((dir) => `${dir}/${FROM[name] ?? name}.mp3`).find((f) => fs.existsSync(f));
  const { channelData, sampleRate } = decoder.decode(new Uint8Array(fs.readFileSync(source)));
  decoder.free();
  let channels = channelData.slice(0, 2);
  const filters = [
    ...(NOTCHES[name] ?? []).flatMap((f) => Array(PASSES).fill(notch(f, sampleRate))),
    ...(LOWPASS[name] ? Array(PASSES).fill(lowpass(LOWPASS[name], sampleRate)) : []),
    ...(HIGHPASS[name] ? Array(PASSES).fill(highpass(HIGHPASS[name], sampleRate)) : []),
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
    + (NOTCHES[name] ? `, notch ${NOTCHES[name].join(", ")} Hz` : "") + (LOWPASS[name] ? `, passe-bas ${LOWPASS[name]} Hz` : "")
    + (HIGHPASS[name] ? `, passe-haut ${HIGHPASS[name]} Hz` : "") + `, > 4 kHz : ${shareAbove4k(channels[0], sampleRate).toFixed(2)} %`);
}

const wanted = process.argv.slice(2);
for (const name of wanted.length ? wanted : NAMES) await prepare(name);
