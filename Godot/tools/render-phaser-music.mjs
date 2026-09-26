// Records a music theme of the Phaser version (synthesized live by nouveau/src/audio/music.js)
// into a seamless Ogg Vorbis loop for the Godot version, so both play the same music.
//
// The theme is played in headless Edge through Vite, the output is tapped as raw PCM with
// the audio clock of every block, and exactly one full cycle is cut out: passes 1..N+1
// (pass 0 has the fade-in). Starting on pass 1 means the loop begins with the reverb tail
// of the previous pass, so the wrap-around is seamless.
//
// Usage (repository root, Vite dev server running: npx vite --port 5199):
//   VORBIS_ENCODER=<path to wasm-media-encoders> node Godot/tools/render-phaser-music.mjs plaines 6
//   (6 = passes in one full cycle: every:[1,1,0] with 2 variants → lcm(3, 2))
// Nothing in nouveau/ is modified: the module is only imported in the browser.
import { chromium } from "playwright-core";
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

// Third argument "once": a jingle played once (victory, capture…): pass 0 from its very
// start plus its reverb tail, no loop.
const [theme = "plaines", cycleArg = "1", mode = "loop"] = process.argv.slice(2);
const cycle = Number(cycleArg);
const once = mode === "once";
const TAIL_S = 2.5;
const BASE = process.env.VITE_URL || "http://localhost:5199/dinogame/";
const OUT = `Godot/assets/audio/music/${theme}.ogg`;
const PEAK = 0.89; // -1 dBFS
const encoderPath = process.env.VORBIS_ENCODER || "wasm-media-encoders";
const { createOggEncoder } = await import(encoderPath.includes("/") || encoderPath.includes("\\") ? pathToFileURL(path.join(encoderPath, "dist/esnext/index.mjs")).href : encoderPath);

const browser = await chromium.launch({
  executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
  headless: true,
  args: ["--autoplay-policy=no-user-gesture-required"],
});
const page = await browser.newPage();
page.on("pageerror", (e) => console.error("page:", e.message));
// Any same-origin document works as a host for the module import.
await page.goto(`${BASE}vite.config.js`);

// Tap every AudioContext's output: blocks of PCM with their audio-clock time.
const info = await page.evaluate(async ({ theme, cycle }) => {
  const AC = window.AudioContext;
  window.AudioContext = class extends AC {
    constructor(...a) {
      super(...a);
      const tap = this.createGain();
      tap.connect(super.destination);
      const proc = this.createScriptProcessor(4096, 2, 2);
      window.__blocks = [];
      proc.onaudioprocess = (e) => {
        window.__blocks.push({ t: e.playbackTime, l: e.inputBuffer.getChannelData(0).slice(), r: e.inputBuffer.getChannelData(1).slice() });
      };
      const mute = this.createGain();
      mute.gain.value = 0;
      tap.connect(proc).connect(mute).connect(super.destination);
      Object.defineProperty(this, "destination", { value: tap });
      window.__ctx = this;
    }
  };
  // The player starts its first step at currentTime + 0.08 when it creates its timer.
  const setIntervalOrig = window.setInterval;
  window.setInterval = (fn, ms, ...rest) => {
    if (ms === 50 && window.__t0 == null && window.__ctx) window.__t0 = window.__ctx.currentTime + 0.08;
    return setIntervalOrig(fn, ms, ...rest);
  };
  const sounds = await import("/dinogame/nouveau/src/audio/sounds.js");
  const music = await import("/dinogame/nouveau/src/audio/music.js");
  const { THEMES } = await import("/dinogame/nouveau/src/data/musicThemes.js");
  const def = THEMES[theme];
  const ctx = sounds.audioContext();
  await ctx.resume();
  // Let the tap start recording before the first note (a jingle is kept from its very start).
  await new Promise((r) => setTimeout(r, 600));
  music.music(theme, { fade: 0.01 });
  const bars = def.chords.trim().split(/\s+/).length;
  const pass = bars * def.beats * 60 / def.bpm;
  return { pass, sampleRate: ctx.sampleRate, seconds: pass * (cycle + 1) + 2 };
}, { theme, cycle });

console.log(`${theme} : passage ${info.pass.toFixed(2)} s, cycle ${cycle} passages, enregistrement ${info.seconds.toFixed(0)} s…`);
await page.waitForTimeout(info.seconds * 1000);

const rec = await page.evaluate(() => {
  const toB64 = (f32) => {
    const bytes = new Uint8Array(f32.buffer);
    let s = "";
    for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
    return btoa(s);
  };
  const b = window.__blocks;
  const n = b.reduce((s, x) => s + x.l.length, 0);
  const L = new Float32Array(n), R = new Float32Array(n);
  let o = 0;
  for (const x of b) { L.set(x.l, o); R.set(x.r, o); o += x.l.length; }
  return { t0: window.__t0, first: b[0].t, L: toB64(L), R: toB64(R) };
});
await browser.close();

const f32 = (b64) => { const buf = Buffer.from(b64, "base64"); return new Float32Array(buf.buffer, buf.byteOffset, buf.length / 4); };
const L = f32(rec.L), R = f32(rec.R);
const sr = info.sampleRate;
const start = Math.round((rec.t0 + (once ? 0 : info.pass) - rec.first) * sr);
const length = Math.round((once ? info.pass + TAIL_S : info.pass * cycle) * sr);
if (start < 0 || start + length > L.length) throw new Error(`Enregistrement trop court (${L.length} échantillons, besoin de ${start + length})`);
const cut = [L.slice(start, start + length), R.slice(start, start + length)];
let peak = 0;
for (const ch of cut) for (const v of ch) peak = Math.max(peak, Math.abs(v));
if (peak < 1e-4) throw new Error("Enregistrement silencieux");
const gain = PEAK / peak;
for (const ch of cut) for (let i = 0; i < ch.length; i++) ch[i] *= gain;
// A jingle ends on its reverb tail: fade the last half second out to silence.
if (once) {
  const fade = Math.round(0.5 * sr);
  for (const ch of cut) for (let i = 0; i < fade; i++) ch[length - 1 - i] *= i / fade;
}

const encoder = await createOggEncoder();
encoder.configure({ channels: 2, sampleRate: sr, vbrQuality: 5 });
const parts = [];
const BLOCK = 8192;
for (let i = 0; i < length; i += BLOCK) parts.push(Buffer.from(encoder.encode([cut[0].subarray(i, i + BLOCK), cut[1].subarray(i, i + BLOCK)])));
parts.push(Buffer.from(encoder.finalize()));
fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, Buffer.concat(parts));
console.log(`${OUT} : ${(length / sr).toFixed(2)} s, gain x${gain.toFixed(2)}, ${Math.round(fs.statSync(OUT).size / 1024)} Ko`);
