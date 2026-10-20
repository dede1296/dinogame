// Sons des géants du post-game (Stable Audio Open 1.0 EN LOCAL via ComfyUI, gratuit), réglés sur la médiane de leur catégorie.
//   geant-baillement (cries, grave et long), geant-pas (sfx, un pas sourd), geant-ronfle (ambience-bed, boucle douce).
// Même chaîne que stable_audio_local.mjs (workflow API de ComfyUI, MP3 bruts dans tools/sounds/sa/), en plus court.
// Usage (depuis Godot/) :
//   AUDIO_MODULES=<node_modules avec mpg123-decoder et wasm-media-encoders> SA_WORKFLOW=<api_prompt.json> node tools/audio-jobs/geants_sons.mjs [nom...]
// Sorties : assets/audio/<dossier>/geant-*.ogg (jamais écrasé : supprimer le fichier pour le refaire), journal dans stable_audio_log.json.
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { randomUUID } from "node:crypto";
import { normalizeToCategory } from "./normalize_to_category.mjs";

const HOST = "http://127.0.0.1:8188";
const RAW = "tools/sounds/sa";
const LOG = "tools/audio-jobs/stable_audio_log.json";
const NEG = "music, melody, voice, speech, singing, drums beat, distortion, clipping, noise, harsh, scary, roar, aggressive";
const G = "gentle, soft, family friendly";
// dossier, nom, secondes, boucle, passe-bas Hz, catégorie de niveau, prompt, graine
const JOBS = [
  ["cries", "geant-baillement", 5, false, 1200, "cries", "a gigantic gentle animal waking up and yawning, one very long deep low groaning yawn with a soft breathy end, huge chest, sleepy, creature sound", 4101],
  ["sfx", "geant-pas", 3, false, 700, "sfx", "a single heavy dull footstep of an enormous animal on soft earth, deep thump with a short low rumble, slow, muffled", 4202],
  ["ambience", "geant-ronfle", 10, true, 900, "ambience-bed", "a huge animal snoring slowly and softly while it sleeps, deep low rumbling breaths in and out, steady, calm, ambience loop", 4303],
];
const modules = process.env.AUDIO_MODULES;
const load = (n, e) => import(modules ? pathToFileURL(path.join(modules, n, e)).href : n);
const { MPEGDecoder } = await load("mpg123-decoder", "index.js");
const { createOggEncoder } = await load("wasm-media-encoders", "dist/esnext/index.mjs");
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function generate(prompt, seconds, seed, rawPath) {
  const wf = JSON.parse(fs.readFileSync(process.env.SA_WORKFLOW, "utf8"));
  Object.assign(wf["6"].inputs, { text: `${prompt}, ${G}` });
  Object.assign(wf["7"].inputs, { text: NEG });
  wf["11"].inputs.seconds = seconds; wf["3"].inputs.seed = seed; wf["3"].inputs.steps = 30;
  wf["20"].inputs.filename_prefix = `audio/ambrelune/${path.basename(rawPath, ".mp3")}`; wf["20"].inputs.format = "mp3";
  const res = await fetch(`${HOST}/prompt`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ prompt: wf, client_id: randomUUID() }) });
  if (!res.ok) throw new Error(`POST /prompt : HTTP ${res.status}`);
  const id = (await res.json()).prompt_id;
  for (;;) {
    await sleep(4000);
    const e = (await (await fetch(`${HOST}/history/${id}`)).json())[id];
    if (!e) continue;
    if (e.status?.status_str === "error") throw new Error(`ComfyUI : échec du job ${id}`);
    if (!e.status?.completed) continue;
    const f = Object.values(e.outputs).flatMap((o) => Object.values(o).flat()).find((x) => x?.filename);
    const q = new URLSearchParams({ filename: f.filename, subfolder: f.subfolder ?? "", type: f.type ?? "output" });
    fs.writeFileSync(rawPath, Buffer.from(await (await fetch(`${HOST}/view?${q}`)).arrayBuffer()));
    return;
  }
}
function lowpass(x, freq, sr) {
  const w = (2 * Math.PI * freq) / sr, al = Math.sin(w) / (2 * Math.SQRT1_2), cs = Math.cos(w), a0 = 1 + al;
  const [b0, b1, a1, a2] = [(1 - cs) / 2 / a0, (1 - cs) / a0, (-2 * cs) / a0, (1 - al) / a0];
  const o = new Float32Array(x.length); let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < x.length; i++) { const y = b0 * x[i] + b1 * x1 + b0 * x2 - a1 * y1 - a2 * y2; x2 = x1; x1 = x[i]; y2 = y1; y1 = y; o[i] = y; }
  return o;
}
const peakOf = (ch) => { let p = 0; for (const c of ch) for (let i = 0; i < c.length; i++) p = Math.max(p, Math.abs(c[i])); return p; };
function trimEnds(ch, sr) {
  const N = ch[0].length, th = peakOf(ch) * 10 ** (-45 / 20); let a = 0, b = N - 1;
  const loud = (i) => ch.some((c) => Math.abs(c[i]) > th);
  while (a < N - 1 && !loud(a)) a++;
  while (b > a && !loud(b)) b--;
  a = Math.max(0, a - Math.floor(sr * 0.03)); b = Math.min(N, b + 1 + Math.floor(sr * 0.15));
  const fin = Math.floor(sr * 0.003), fout = Math.min(b - a, Math.floor(sr * 0.1));
  return ch.map((x) => { const o = x.slice(a, b); for (let i = 0; i < fin; i++) o[i] *= i / fin; for (let i = 0; i < fout; i++) o[o.length - 1 - i] *= i / fout; return o; });
}
function crossfadeLoop(ch, sr, s) {
  const F = Math.floor(sr * s), N = ch[0].length, L = N - F;
  return ch.map((x) => { const o = new Float32Array(L); for (let i = 0; i < L; i++) { if (i < F) { const t = i / F; o[i] = x[i] * Math.sin(t * Math.PI / 2) + x[N - F + i] * Math.cos(t * Math.PI / 2); } else o[i] = x[i]; } return o; });
}
async function encode(ch, sr, dest) {
  const enc = await createOggEncoder(); enc.configure({ channels: ch.length, sampleRate: sr, vbrQuality: 5 });
  const parts = [];
  for (let i = 0; i < ch[0].length; i += 8192) parts.push(Buffer.from(enc.encode(ch.map((x) => x.subarray(i, i + 8192)))));
  parts.push(Buffer.from(enc.finalize()));
  fs.writeFileSync(dest, Buffer.concat(parts));
}

const log = fs.existsSync(LOG) ? JSON.parse(fs.readFileSync(LOG, "utf8")) : {};
fs.mkdirSync(RAW, { recursive: true });
const wanted = process.argv.slice(2);
for (const [folder, name, seconds, loop, lp, cat, prompt, seed0] of JOBS.filter((j) => !wanted.length || wanted.includes(j[1]))) {
  const dest = `assets/audio/${folder}/${name}.ogg`;
  if (fs.existsSync(dest)) { console.log(`${name} : déjà là`); continue; }
  const raw = `${RAW}/${name}_${seed0}.mp3`;
  if (!fs.existsSync(raw)) await generate(prompt, seconds, seed0, raw);
  const dec = new MPEGDecoder(); await dec.ready;
  const { channelData, sampleRate } = dec.decode(new Uint8Array(fs.readFileSync(raw))); dec.free();
  let ch = channelData.slice(0, 2).map((x) => lowpass(lowpass(x, lp, sampleRate), lp, sampleRate));
  ch = loop ? crossfadeLoop(ch, sampleRate, 1.5) : trimEnds(ch, sampleRate);
  const norm = normalizeToCategory(ch, sampleRate, cat);
  await encode(norm.ch, sampleRate, dest);
  log[name] = { kind: "sfx", takes: { a: { ok: true, seed: seed0, seconds: +(norm.ch[0].length / sampleRate).toFixed(2), ...norm.info } }, chosenFile: dest };
  fs.writeFileSync(LOG, JSON.stringify(log, null, 1));
  console.log(name, JSON.stringify(norm.info));
}
