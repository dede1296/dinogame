// Cale un son neuf sur le niveau des sons EXISTANTS de sa categorie (regle de Greg : normaliser avec les elements de meme
// categorie). Reference : tools/audio-jobs/levels_reference.json (python tools/audio-jobs/levels_reference.py).
//   RMS actif (fenetres de 50 ms > -50 dBFS) = mediane de la categorie ; pic limite (soft-clip) a
//   min(mediane des pics + 1 dB, -0,5 dBFS) ; son trop court pour un RMS actif : cale sur le pic median.
// Categories : ambience-bed, ambience-call, music, cries, sfx, footsteps/<famille> (footstep, neige, glace_craque, cendre->footstep+neige).
// Usage CLI : AUDIO_MODULES=<node_modules> node tools/audio-jobs/normalize_to_category.mjs <in.mp3> <out.ogg> <categorie> [loop]
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

const REF = JSON.parse(fs.readFileSync(new URL("./levels_reference.json", import.meta.url), "utf8")).categories;
const DB = (x) => 20 * Math.log10(Math.max(x, 1e-9));
const LIN = (d) => 10 ** (d / 20);
const WIN_S = 0.05, GATE_DB = -50, MAX_OVER = 2.5; // MAX_OVER : un pic ne depasse pas 8 dB le plafond avant limiteur

export const peakOf = (ch) => { let p = 0; for (const c of ch) for (let i = 0; i < c.length; i++) { const a = Math.abs(c[i]); if (a > p) p = a; } return p; };
const mono = (ch) => { const m = new Float32Array(ch[0].length); for (const c of ch) for (let i = 0; i < m.length; i++) m[i] += c[i] / ch.length; return m; };
/** RMS actif en dBFS (null si aucune fenetre au-dessus de -50 dBFS), apres application du gain `g` et du limiteur. */
export function activeRmsDb(ch, sr, g = 1, lim = null) {
  const m = mono(ch), w = Math.floor(sr * WIN_S), gate = LIN(GATE_DB); let s = 0, n = 0;
  for (let i = 0; i + w <= m.length; i += w) {
    let e = 0; for (let j = i; j < i + w; j++) { let v = m[j] * g; if (lim) v = softLimit(v, lim); e += v * v; }
    const r = Math.sqrt(e / w); if (r > gate) { s += r * r; n++; }
  }
  return n ? DB(Math.sqrt(s / n)) : null;
}
export function softLimit(v, lim) { const a = Math.abs(v), k = lim * 0.67; if (a <= k) return v; const r = lim - k; return Math.sign(v) * (k + r * Math.tanh((a - k) / r)); }

export function categoryLevels(cat) { // "a+b" : moyenne des medianes de deux categories (ex. footsteps/footstep+footsteps/neige)
  const cs = cat.split("+").map((n) => { const c = REF[n]; if (!c) throw new Error(`categorie inconnue : ${n} (${Object.keys(REF).join(", ")})`); return c; });
  const mean = (f) => cs.reduce((a, c) => a + f(c), 0) / cs.length;
  return { rmsDb: mean((c) => c.activeRmsDb.median), peakDb: Math.min(mean((c) => c.peakDb.median) + 1, -0.5) };
}
/** Retourne { ch, info } : canaux mis au niveau de la categorie. */
export function normalizeToCategory(ch, sr, cat) {
  const { rmsDb, peakDb } = categoryLevels(cat), lim = LIN(peakDb), pk = peakOf(ch);
  let g, mode = "rms-actif", limited = false;
  const r0 = activeRmsDb(ch, sr, 1);
  if (r0 === null || ch[0].length < sr * 0.15) { mode = "pic-median"; g = lim / pk; }
  else {
    g = LIN(rmsDb - r0);
    if (pk * g > lim * MAX_OVER) { g = (lim * MAX_OVER) / pk; limited = true; }
    for (let it = 0; it < 4 && !limited; it++) { // le limiteur rabote un peu : on remonte pour retomber sur la mediane
      const r = activeRmsDb(ch, sr, g, lim); if (r === null || Math.abs(r - rmsDb) < 0.2) break;
      g *= LIN(rmsDb - r); if (pk * g > lim * MAX_OVER) { g = (lim * MAX_OVER) / pk; limited = true; }
    }
  }
  const out = ch.map((x) => x.map((v) => softLimit(v * g, lim)));
  return { ch: out, info: { category: cat, mode, limited, gainDb: +DB(g).toFixed(1), targetRmsDb: rmsDb, capPeakDb: +peakDb.toFixed(1), peakDb: +DB(peakOf(out)).toFixed(1), activeRmsDb: (() => { const r = activeRmsDb(out, sr); return r === null ? null : +r.toFixed(1); })() } };
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [inp, outp, cat, loop] = process.argv.slice(2);
  const modules = process.env.AUDIO_MODULES;
  const load = (n, e) => import(modules ? pathToFileURL(path.join(modules, n, e)).href : n);
  const { MPEGDecoder } = await load("mpg123-decoder", "index.js");
  const { createOggEncoder } = await load("wasm-media-encoders", "dist/esnext/index.mjs");
  const dec = new MPEGDecoder(); await dec.ready;
  const { channelData, sampleRate } = dec.decode(new Uint8Array(fs.readFileSync(inp))); dec.free();
  const { ch, info } = normalizeToCategory(channelData.slice(0, 2), sampleRate, cat);
  const enc = await createOggEncoder(); enc.configure({ channels: ch.length, sampleRate, vbrQuality: 5 });
  const parts = []; for (let i = 0; i < ch[0].length; i += 8192) parts.push(Buffer.from(enc.encode(ch.map((x) => x.subarray(i, i + 8192)))));
  parts.push(Buffer.from(enc.finalize())); fs.writeFileSync(outp, Buffer.concat(parts));
  console.log(JSON.stringify(info), loop ? "(boucle : fais le fondu enchaine avant)" : "");
}
