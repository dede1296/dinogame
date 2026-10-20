// os-trouve.ogg (post-game, lot B') : un « toc » sec (os contre la pierre) puis un petit carillon de trois notes.
// Synthétisé ici (pas de génération : déterministe, gratuit), puis calé sur le niveau des sfx existants
// (normalize_to_category, catégorie « sfx »). N'écrase jamais un fichier existant (`os-trouve_v2.ogg` sinon).
// Usage (depuis Godot/) : AUDIO_MODULES=<node_modules avec wasm-media-encoders> node tools/audio-jobs/os_trouve.mjs
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { normalizeToCategory } from "./normalize_to_category.mjs";

const SR = 44100;
const SECONDS = 1.6;
const modules = process.env.AUDIO_MODULES;
const { createOggEncoder } = await import(modules ? pathToFileURL(path.join(modules, "wasm-media-encoders", "dist/esnext/index.mjs")).href : "wasm-media-encoders");

const out = new Float32Array(Math.floor(SR * SECONDS));
let seed = 12345;
const rnd = () => ((seed = (seed * 1664525 + 1013904223) >>> 0) / 4294967296) * 2 - 1;

/** « toc » : corps grave qui retombe vite + un claquement de bruit adouci. */
function addKnock(at) {
  let lp = 0;
  for (let i = 0; i < SR * 0.12; i++) {
    const t = i / SR, env = Math.exp(-t * 55);
    lp += 0.25 * (rnd() - lp);
    out[Math.floor(at * SR) + i] += env * (0.7 * Math.sin(2 * Math.PI * (210 - 400 * t) * t) + 0.5 * lp);
  }
}

/** Cloche : fondamentale + partiels légèrement inharmoniques, attaque nette, longue chute. */
function addBell(at, freq, level) {
  const partials = [[1, 1, 3.2], [2.76, 0.35, 5], [5.4, 0.15, 8]];
  for (let i = 0; i < SR * 1.1; i++) {
    const t = i / SR, idx = Math.floor(at * SR) + i;
    if (idx >= out.length) break;
    let v = 0;
    for (const [k, a, decay] of partials) v += a * Math.exp(-t * decay) * Math.sin(2 * Math.PI * freq * k * t);
    out[idx] += level * Math.min(1, t * 800) * v;
  }
}

addKnock(0.02);
[[0.2, 1318.5, 0.35], [0.33, 1568, 0.3], [0.46, 2093, 0.32]].forEach(([at, f, l]) => addBell(at, f, l));

const { ch, info } = normalizeToCategory([out], SR, "sfx");
let dest = "assets/audio/sfx/os-trouve.ogg";
if (fs.existsSync(dest)) dest = "assets/audio/sfx/os-trouve_v2.ogg";
const enc = await createOggEncoder();
enc.configure({ channels: 1, sampleRate: SR, vbrQuality: 5 });
const parts = [];
for (let i = 0; i < ch[0].length; i += 8192) parts.push(Buffer.from(enc.encode([ch[0].subarray(i, i + 8192)])));
parts.push(Buffer.from(enc.finalize()));
fs.writeFileSync(dest, Buffer.concat(parts));
console.log(dest, JSON.stringify(info));
