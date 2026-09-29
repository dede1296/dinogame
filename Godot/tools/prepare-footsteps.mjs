// Cuts single footsteps (and other short one-shots) out of a recording made with gen-sound.mjs
// (MP3 in Godot/tools/sounds/) for Player's steps: Ogg Vorbis in Godot/assets/audio/footsteps/,
// <name>00.ogg, <name>01.ogg… Each cut starts just before its onset, fades out, and is brought
// to the same peak; a low-pass takes the shrill part away (the player does not want shrill
// sounds: each line printed says how much of the energy is left above 4 kHz).
// The cuts are chosen by hand on the recording's loudness (`at`: [start s, length s]), each one
// starting in the quiet just before a step.
// Needs mpg123-decoder and wasm-media-encoders (npm i them in a scratch folder, then pass the
// node_modules folder in AUDIO_MODULES).
// Usage (from the repository root): AUDIO_MODULES=<node_modules> node Godot/tools/prepare-footsteps.mjs [name…]
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

const SOURCES = "Godot/tools/sounds";
const OUT = "Godot/assets/audio/footsteps";
// neige: steps in powder snow (ElevenLabs, 29/09): a soft crunch, 15 % of it above 4 kHz (the
// hiss of the snow), cut at 2.5 kHz. glace_craque: short groans of glacier ice cut out of
// glace.mp3 (the ice caves' call), heard now and then under a step on the ice. (The ice steps
// themselves are the path's, played lower: no credit was left for a take of their own.)
const CUTS = {
  neige: { source: "pas_neige", lowpass: 2500, highpass: 60,
    at: [[0.54, 0.4], [1.3, 0.42], [2.06, 0.4], [2.7, 0.4], [3.3, 0.42], [4.02, 0.42]] },
  glace_craque: { source: "glace", lowpass: 2500, highpass: 60, at: [[1.06, 0.5], [1.8, 0.45], [2.62, 0.5]] },
};
const PEAK = 0.8;
const PRE_S = 0.015;     // a cut starts this long before its onset
const FADE_S = 0.12;     // and fades out over its end
const PASSES = 2;

const modules = process.env.AUDIO_MODULES;
const load = (name, entry) => import(modules ? pathToFileURL(path.join(modules, name, entry)).href : name);
const { MPEGDecoder } = await load("mpg123-decoder", "index.js");
const { createOggEncoder } = await load("wasm-media-encoders", "dist/esnext/index.mjs");

// RBJ cookbook biquads (Butterworth Q).
function biquad(kind, freq, sampleRate) {
  const w = (2 * Math.PI * freq) / sampleRate;
  const alpha = Math.sin(w) / (2 * Math.SQRT1_2);
  const cs = Math.cos(w), a0 = 1 + alpha;
  const b = kind === "low" ? [(1 - cs) / 2, 1 - cs, (1 - cs) / 2] : [(1 + cs) / 2, -(1 + cs), (1 + cs) / 2];
  return { b0: b[0] / a0, b1: b[1] / a0, b2: b[2] / a0, a1: (-2 * cs) / a0, a2: (1 - alpha) / a0 };
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

// Share (%) of the energy above 4 kHz (FFT over windows of 1024 samples).
function shareAbove4k(samples, sampleRate) {
  const N = 1024, cut = Math.ceil((4000 * N) / sampleRate);
  let high = 0, all = 0;
  for (let off = 0; off + N <= samples.length; off += N / 2) {
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

async function encode(channels, sampleRate, file) {
  const encoder = await createOggEncoder();
  encoder.configure({ channels: channels.length, sampleRate, vbrQuality: 5 });
  const parts = [];
  const BLOCK = 8192;
  for (let i = 0; i < channels[0].length; i += BLOCK) {
    parts.push(Buffer.from(encoder.encode(channels.map((ch) => ch.subarray(i, i + BLOCK)))));
  }
  parts.push(Buffer.from(encoder.finalize()));
  fs.writeFileSync(file, Buffer.concat(parts));
}

async function prepare(name) {
  const def = CUTS[name];
  const decoder = new MPEGDecoder();
  await decoder.ready;
  const { channelData, sampleRate } = decoder.decode(new Uint8Array(fs.readFileSync(`${SOURCES}/${def.source}.mp3`)));
  decoder.free();
  let channels = channelData.slice(0, 2);
  const filters = [
    ...(def.lowpass ? Array(PASSES).fill(biquad("low", def.lowpass, sampleRate)) : []),
    ...(def.highpass ? Array(PASSES).fill(biquad("high", def.highpass, sampleRate)) : []),
  ];
  channels = channels.map((ch) => filters.reduce((s, c) => filter(s, c), ch));
  for (const [i, [start, length]] of def.at.entries()) {
    const from = Math.max(0, Math.round((start - PRE_S) * sampleRate));
    const to = Math.min(channels[0].length, from + Math.round(length * sampleRate));
    const fade = Math.round(FADE_S * sampleRate);
    let peak = 0;
    const cut = channels.map((ch) => ch.slice(from, to));
    for (const ch of cut) for (const v of ch) peak = Math.max(peak, Math.abs(v));
    const gain = peak ? PEAK / peak : 1;
    for (const ch of cut) {
      for (let j = 0; j < ch.length; j++) {
        const lead = Math.min(1, j / (0.004 * sampleRate));          // no click at the start
        const tail = Math.min(1, (ch.length - j) / fade);
        ch[j] *= gain * lead * tail;
      }
    }
    const file = `${OUT}/${name}${String(i).padStart(2, "0")}.ogg`;
    await encode(cut, sampleRate, file);
    console.log(`${file} : ${start.toFixed(2)} s + ${length.toFixed(2)} s, gain ${(20 * Math.log10(gain)).toFixed(1)} dB, `
      + `> 4 kHz : ${shareAbove4k(cut[0], sampleRate).toFixed(2)} %`);
  }
}

const wanted = process.argv.slice(2);
for (const name of wanted.length ? wanted : Object.keys(CUTS)) await prepare(name);
