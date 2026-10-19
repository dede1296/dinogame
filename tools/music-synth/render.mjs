// Renders a score (scores/<name>.js) or an original theme of the Phaser version into an .ogg.
//
//   node render.mjs <score>                    → Godot/assets/audio/music/<score>.ogg (refuses to overwrite)
//   node render.mjs <score> --out x.ogg        → elsewhere; --force to overwrite
//   node render.mjs theme:monts --passes 2     → out/theme-monts.ogg: an original theme, `passes` loop passes
//                                                 (as Godot/tools/render-phaser-music.mjs recorded them)
//   node render.mjs theme:victoire --once      → a jingle: pass 0 and its reverb tail
//   node render.mjs <score> --stats            → only the statistics of the score (no audio)
//   node render.mjs <score> --lint             → held notes outside their chord (a check of the writing)
//   node render.mjs <score> --seamcheck        → a loop's seam against a continuous render of three passes
// Options: --raw (peak at -1 dBFS like the Phaser recordings, no level matching), --ceiling -1.0 (dBFS),
// --wav (also out/<name>.wav, the signal before encoding), --full --cycles n (debugging: the whole render).
//
// The audio is rendered by headless Edge (playwright-core) with an OfflineAudioContext: the very Web
// Audio instruments of the Phaser version (synth/audio/instruments.js), see engine/offline.js. The level
// follows Greg's rule (docs/musiques-composees.md): the active RMS (50 ms windows above -50 dBFS, mono)
// is set on the MEDIAN of the game's existing music (Godot/tools/audio-jobs/levels_reference.json),
// with a soft look-ahead limiter (peak ≤ -0.5 dBFS once encoded). A loop is limited around its seam.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { chromium } from "playwright-core";
import { createOggEncoder } from "wasm-media-encoders";
import { scoreStats, themeStats, clashes } from "./engine/stats.js";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(HERE, "../..");
const MUSIC_DIR = path.join(REPO, "Godot/assets/audio/music");
const LEVELS = path.join(REPO, "Godot/tools/audio-jobs/levels_reference.json");
const EDGE = process.env.EDGE || "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe";
const ORIGIN = "http://synth.local";
const DB = (x) => 20 * Math.log10(Math.max(x, 1e-12));
const LIN = (d) => 10 ** (d / 20);

// ---------------------------------------------------------------- arguments
const args = process.argv.slice(2);
const flag = (n) => args.includes(n);
const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
const name = args.find((a, i) => !a.startsWith("--") && !(i > 0 && args[i - 1].startsWith("--") && ["--out", "--passes", "--ceiling", "--seed", "--cycles"].includes(args[i - 1])));
if (!name) { console.error("Usage : node render.mjs <partition | theme:<id>> [--out f.ogg] [--force] [--passes n] [--once] [--raw] [--stats]"); process.exit(2); }
const isTheme = name.startsWith("theme:");
const id = isTheme ? name.slice(6) : name;

// ---------------------------------------------------------------- levels
const WIN_S = 0.05, GATE_DB = -50;
/** Active RMS in dBFS: mono mix, 50 ms windows above -50 dBFS (levels_reference.py). */
export function activeRmsDb(ch, sr) {
  const n = ch[0].length, w = Math.floor(sr * WIN_S), gate = LIN(GATE_DB);
  let s = 0, k = 0;
  for (let i = 0; i + w <= n; i += w) {
    let e = 0;
    for (let j = i; j < i + w; j++) { const v = (ch[0][j] + ch[1][j]) / 2; e += v * v; }
    const r = Math.sqrt(e / w);
    if (r > gate) { s += r * r; k++; }
  }
  return k ? DB(Math.sqrt(s / k)) : -Infinity;
}
const peakOf = (ch) => { let p = 0; for (const c of ch) for (let i = 0; i < c.length; i++) p = Math.max(p, Math.abs(c[i])); return p; };

function targetLevel() {
  try { return JSON.parse(fs.readFileSync(LEVELS, "utf8")).categories.music.activeRmsDb.median; }
  catch { return -14.5; } // (measured on 19/10 over the 15 tracks of the game)
}

/**
 * Soft look-ahead limiter: the gain falls smoothly over 5 ms before a peak that would pass `ceiling`
 * and comes back in ~150 ms. `circular`: the signal is a loop, its end goes on into its start.
 */
function limit(ch, sr, ceiling, circular) {
  const n = ch[0].length;
  const pad = circular ? Math.min(n, Math.round(1.0 * sr)) : 0;
  const N = n + 2 * pad;
  const at = (c, i) => ch[c][((i - pad) % n + n) % n];
  const look = Math.max(1, Math.round(0.005 * sr));
  const need = new Float32Array(N);
  for (let i = 0; i < N; i++) {
    const inside = circular || (i >= pad && i < pad + n);
    const p = inside ? Math.max(Math.abs(at(0, i)), Math.abs(at(1, i))) : 0;
    need[i] = p > ceiling ? ceiling / p : 1;
  }
  // min over [i, i + look] (a monotone deque), then averaged over the `look` samples before.
  const wmin = new Float32Array(N);
  const dq = new Int32Array(N);
  let h = 0, t = 0;
  for (let i = N - 1; i >= 0; i--) {
    while (t > h && need[dq[t - 1]] >= need[i]) t--;
    dq[t++] = i;
    while (dq[h] > i + look) h++;
    wmin[i] = need[dq[h]];
  }
  const g = new Float32Array(N);
  let acc = look; // sum of wmin over [i - look + 1, i] (1 before the start)
  const rel = Math.exp(-1 / (0.15 * sr));
  let prev = 1;
  for (let i = 0; i < N; i++) {
    acc += wmin[i] - (i >= look ? wmin[i - look] : 1);
    prev = Math.min(acc / look, 1 - (1 - prev) * rel);
    g[i] = prev;
  }
  return ch.map((c) => {
    const out = new Float32Array(n);
    for (let i = 0; i < n; i++) {
      const v = c[i] * g[i + pad];
      out[i] = Math.max(-ceiling, Math.min(ceiling, v)); // (a safety: never reached in practice)
    }
    return out;
  });
}

function setLevel(ch, sr, { target, ceiling, circular }) {
  let gDb = target - activeRmsDb(ch, sr);
  let out = ch;
  for (let it = 0; it < 4; it++) {
    const g = LIN(gDb);
    out = limit(ch.map((c) => c.map((v) => v * g)), sr, ceiling, circular);
    const r = activeRmsDb(out, sr);
    if (Math.abs(r - target) < 0.05) break;
    gDb += target - r;
  }
  // How hard the limiter worked: its deepest reduction, where, and for how long it went past 1 dB.
  const g = LIN(gDb);
  let worst = 1, at = 0, over1 = 0;
  for (let i = 0; i < out[0].length; i++) {
    const a = Math.max(Math.abs(ch[0][i]), Math.abs(ch[1][i])) * g;
    if (a < 1e-3) continue;
    const r = Math.max(Math.abs(out[0][i]), Math.abs(out[1][i])) / a;
    if (r < worst) { worst = r; at = i; }
    if (r < LIN(-1)) over1++;
  }
  return { ch: out, gainDb: gDb, limiter: { maxReductionDb: +DB(worst).toFixed(2), atSeconds: +(at / sr).toFixed(2), secondsBeyond1dB: +(over1 / sr).toFixed(2) } };
}

// ---------------------------------------------------------------- rendering in Edge
async function renderInBrowser(spec) {
  const browser = await chromium.launch({ executablePath: EDGE, headless: true, args: ["--autoplay-policy=no-user-gesture-required"] });
  try {
    const page = await browser.newPage();
    page.on("pageerror", (e) => console.error("page :", e.message));
    page.on("console", (m) => { if (m.type() === "error") console.error("console :", m.text()); });
    await page.route(`${ORIGIN}/**`, (route) => {
      const rel = decodeURIComponent(new URL(route.request().url()).pathname).replace(/^\/+/, "");
      if (rel === "" || rel === "index.html") return route.fulfill({ contentType: "text/html", body: "<!doctype html><meta charset=utf-8><link rel=icon href=\"data:,\"><title>synth</title>" });
      const file = path.join(HERE, rel);
      if (!file.startsWith(HERE) || !fs.existsSync(file)) return route.fulfill({ status: 404, body: "" });
      return route.fulfill({ contentType: "text/javascript", body: fs.readFileSync(file) });
    });
    await page.goto(`${ORIGIN}/index.html`);
    const info = await page.evaluate(async (spec) => (await import("/engine/offline.js")).render(spec), spec);
    const CHUNK = 1 << 20;
    const ch = [new Float32Array(info.length), new Float32Array(info.length)];
    for (let c = 0; c < 2; c++) {
      for (let o = 0; o < info.length; o += CHUNK) {
        const n = Math.min(CHUNK, info.length - o);
        const b64 = await page.evaluate(async ([c, from, n]) => (await import("/engine/offline.js")).readChunk(c, from, n), [c, info.start + o, n]);
        const buf = Buffer.from(b64, "base64");
        ch[c].set(new Float32Array(buf.buffer, buf.byteOffset, buf.length / 4), o);
      }
    }
    return { info, ch };
  } finally {
    await browser.close();
  }
}

/** 32-bit float WAV (for checking the encoder: --wav). */
function writeWav(ch, sr, file) {
  const n = ch[0].length, data = Buffer.alloc(n * 8);
  for (let i = 0; i < n; i++) { data.writeFloatLE(ch[0][i], i * 8); data.writeFloatLE(ch[1][i], i * 8 + 4); }
  const h = Buffer.alloc(44);
  h.write("RIFF", 0); h.writeUInt32LE(36 + data.length, 4); h.write("WAVE", 8); h.write("fmt ", 12);
  h.writeUInt32LE(16, 16); h.writeUInt16LE(3, 20); h.writeUInt16LE(2, 22); h.writeUInt32LE(sr, 24);
  h.writeUInt32LE(sr * 8, 28); h.writeUInt16LE(8, 32); h.writeUInt16LE(32, 34); h.write("data", 36); h.writeUInt32LE(data.length, 40);
  fs.writeFileSync(file, Buffer.concat([h, data]));
}

async function encodeOgg(ch, sr, file) {
  const enc = await createOggEncoder();
  enc.configure({ channels: 2, sampleRate: sr, vbrQuality: 5 });
  const parts = [];
  for (let i = 0; i < ch[0].length; i += 8192) parts.push(Buffer.from(enc.encode([ch[0].subarray(i, i + 8192), ch[1].subarray(i, i + 8192)])));
  parts.push(Buffer.from(enc.finalize()));
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, Buffer.concat(parts));
}

// ---------------------------------------------------------------- main
const outDir = path.join(HERE, "out");
fs.mkdirSync(outDir, { recursive: true });

if (flag("--lint")) {
  // Notes held a beat or more outside their bar's chord: a written appoggiatura is fine, a slip is not.
  for (const c of await clashes(id)) console.log(`${c.section} m.${c.bar} ${c.inst} ${c.note} sur ${c.chord} (${c.beats} t)`);
  process.exit(0);
}

if (flag("--stats")) {
  const stats = isTheme ? await themeStats(id) : await scoreStats(id);
  console.log(JSON.stringify(stats, null, 1));
  process.exit(0);
}

const once = flag("--once");
const spec = isTheme
  ? { kind: "theme", name: id, first: once ? 0 : 1, count: once ? 1 : Number(opt("--passes", "1")), loop: !once, tail: 2.5, bus: !flag("--nobus"), seed: Number(opt("--seed", "20261019")) }
  : { kind: "score", name: id, seed: Number(opt("--seed", "20261019")), full: flag("--full"), cycles: opt("--cycles") ? Number(opt("--cycles")) : undefined };
const out = path.resolve(opt("--out", isTheme ? path.join(outDir, `theme-${id}.ogg`) : path.join(MUSIC_DIR, `${id}.ogg`)));

if (flag("--seamcheck")) {
  // The loop's seam against a continuous render: three passes are played; the file would be the
  // second one, so its end followed by its start must equal the boundary between passes 2 and 3.
  const { info, ch } = await renderInBrowser({ ...spec, full: true, cycles: 3 });
  const L = info.cycleFrames, S = info.loopStart, w = Math.round(0.1 * info.sampleRate);
  let maxDiff = 0, e = 0;
  for (const c of ch) {
    for (let k = -w; k < w; k++) {
      const wrapped = k < 0 ? c[S + L + k] : c[S + k];   // file end, then file start
      const cont = c[S + L + k];                          // what really follows
      maxDiff = Math.max(maxDiff, Math.abs(wrapped - cont));
      e += cont * cont;
    }
  }
  const rms = Math.sqrt(e / (4 * w));
  console.log(JSON.stringify({ name: id, cycleSeconds: +(L / info.sampleRate).toFixed(4), seamMaxDiff: +maxDiff.toExponential(2), seamRegionRms: +rms.toFixed(4), seamMaxDiffDb: +(DB(maxDiff) - DB(rms)).toFixed(1) }));
  process.exit(0);
}

if (fs.existsSync(out) && !flag("--force")) { console.error(`${out} existe déjà : rien n'est écrasé (--force pour le remplacer).`); process.exit(1); }

const t0 = Date.now();
const { info, ch: raw } = await renderInBrowser(spec);
const sr = info.sampleRate;
let ch = raw, gainDb = 0, limiter = null;
const ceiling = LIN(Number(opt("--ceiling", "-1.0")));
if (flag("--raw")) {
  // As the Phaser recordings: the peak at -1 dBFS (render-phaser-music.mjs).
  const g = 0.89 / peakOf(raw);
  ch = raw.map((c) => c.map((v) => v * g));
  gainDb = DB(g);
} else {
  ({ ch, gainDb, limiter } = setLevel(raw, sr, { target: targetLevel(), ceiling, circular: info.loop }));
}
if (!info.loop) {
  // A piece played once: 5 ms in, its reverb tail faded out over its last second.
  const n = ch[0].length, fin = Math.round(0.005 * sr), fout = Math.min(n, Math.round(1.0 * sr));
  for (const c of ch) {
    for (let i = 0; i < fin; i++) c[i] *= i / fin;
    for (let i = 0; i < fout; i++) c[n - 1 - i] *= 0.5 - 0.5 * Math.cos((Math.PI * i) / fout);
  }
}
await encodeOgg(ch, sr, out);
if (flag("--wav")) writeWav(ch, sr, path.join(outDir, `${path.basename(out, ".ogg")}.wav`));
const report = {
  file: path.relative(REPO, out).replaceAll("\\", "/"), loop: info.loop, seconds: +(ch[0].length / sr).toFixed(3),
  activeRmsDb: +activeRmsDb(ch, sr).toFixed(2), peakDb: +DB(peakOf(ch)).toFixed(2), gainDb: +gainDb.toFixed(2),
  rawPeakDb: +DB(peakOf(raw)).toFixed(2), rawActiveRmsDb: +activeRmsDb(raw, sr).toFixed(2), limiter,
  events: info.events, sections: info.sections, loopStartsBeforeDownbeat: info.loop ? info.rotationSeconds : undefined, renderSeconds: +((Date.now() - t0) / 1000).toFixed(1),
};
fs.writeFileSync(path.join(outDir, `${path.basename(out, ".ogg")}.json`), JSON.stringify(report, null, 1));
console.log(JSON.stringify(report));
