// Sons des chapitres 7 a 9 avec Stable Audio Open 1.0 EN LOCAL (ComfyUI sur http://127.0.0.1:8188), gratuit.
// Un job a la fois (4 Go de VRAM). Reprend sans refaire ce qui existe : le MP3 brut (tools/sounds/sa/) puis le .ogg.
// Usage (depuis Godot/) :
//   AUDIO_MODULES=<node_modules avec mpg123-decoder et wasm-media-encoders> \
//   SA_WORKFLOW=<api_prompt.json> node tools/audio-jobs/stable_audio_local.mjs [sfx|music|nom...]
// Sorties : assets/audio/<dossier>/<nom>.ogg (jamais ecrase : `<nom>_sa.ogg` si le fichier existe deja),
//           tools/audio-jobs/stable_audio_log.json (duree, pic, RMS, graine de chaque prise).
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { randomUUID } from "node:crypto";
import { normalizeToCategory } from "./normalize_to_category.mjs";

const HOST = "http://127.0.0.1:8188";
const RAW = "tools/sounds/sa";
const OUT = "assets/audio";
const LOG = "tools/audio-jobs/stable_audio_log.json";
const WORKFLOW = process.env.SA_WORKFLOW;
const MAX_TRIES = 3; // graines successives si le son est quasi muet
const CROSSFADE_S = { ambience: 1.5, music: 2.0 };
const MAX_PEAK = 0.9, AMBIENCE_RMS = 0.1, MUSIC_RMS = 0.075;

const NEG_SFX = "music, melody, voice, speech, singing, drums beat, distortion, clipping, noise, harsh, scary";
const NEG_MUSIC = "vocals, singing, choir lyrics, spoken words, drums loud, heavy metal, distortion, horror, scary, sudden loud hits, sound effects, noise, clipping";
const G = "gentle, soft, family friendly";

// folder, name, seconds, loop, lowpass Hz (0 = aucun), steps, prompt, baseSeed
const SFX = [
  ["ambience", "lave-bouillonne", 10, true, 3000, 30, "thick molten lava slowly bubbling, deep low gloopy bubbles popping, soft crackles, distant, steady, ambience loop, field recording"],
  ["ambience", "volcan-grondement", 10, true, 800, 30, "very deep low rumble of a distant volcano, slow sub bass tremor, steady and calm, ambience loop, no hiss"],
  ["ambience", "forge-ronfle", 10, true, 3000, 30, "blacksmith forge furnace roaring softly, steady low flame whoosh, glowing embers, ambience loop, no hammering"],
  ["ambience", "vent-hauteurs", 10, true, 2500, 30, "high altitude wind blowing over clouds, smooth low steady howl, soft air rush, ambience loop, no whistling"],
  ["ambience", "forge-eteinte", 4, false, 4000, 30, "a forge fire dying out, a soft breath of air then a long gentle hiss of cooling embers fading away"],
  ["cries", "souverain-grondement", 5, false, 1500, 30, "very deep low groan of a huge sad animal, enormous, slow, sorrowful, not aggressive, creature sound"],
  ["cries", "souverain-souffle", 5, false, 1500, 30, "a huge animal exhaling a long calm deep breath of relief, slow, soothing, big chest, creature sound"],
  ["cries", "tyran-magma-rugissement", 5, false, 3500, 30, "deep theatrical roar of a giant dinosaur, low and resonant, powerful cinematic monster roar"],
  ["sfx", "ambre-craque", 3, false, 6000, 30, "amber crystal cracking and splitting open, glassy crack with a short resonant shimmer"],
  ["sfx", "portail-pierre", 6, false, 5000, 30, "heavy stone gate sliding open with grinding stone, then a gentle magical chime at the end"],
  ["sfx", "coeur-ambre-pose", 4, false, 8000, 30, "a glowing crystal heart set into a stone hollow, soft click then a crystalline bell chime ringing out"],
  ["sfx", "tasse-porcelaine", 2.5, false, 8000, 30, "a porcelain tea cup set down gently on a wooden table, small clink"],
].map((j, i) => ({ kind: "sfx", folder: j[0], name: j[1], seconds: j[2], loop: j[3], lp: j[4], steps: j[5], prompt: `${j[6]}, ${G}`, neg: NEG_SFX, seed: 1000 + i * 17 }));

const M = (name, prompt) => ({ kind: "music", folder: "music", name, seconds: 47, loop: true, lp: 0, steps: 50, prompt, neg: NEG_MUSIC, seed: 7000 + name.length * 31 });
const MUSIC = [
  M("cieux", "Gentle fantasy orchestral, soaring and airy, 80 BPM, harp arpeggios, soft strings pad, light flute melody, glockenspiel sparkles, sense of flying high above the clouds, wonder and calm, warm, seamless loop, no vocals"),
  M("nids_geants", "Soft fantasy orchestral, tender and curious, 72 BPM, celesta and pizzicato strings, warm low woodwinds, a hint of protective lullaby, giant bird nests high on cliffs, gentle wind feel, seamless loop, no vocals"),
  M("arche_du_vent", "Slow majestic fantasy orchestral, 66 BPM, solemn french horn and deep warm strings, airy choir-free pads, ancient stone arch singing in the wind, awe and quiet tension but not scary, seamless loop, no vocals"),
  M("volcan", "Warm low fantasy orchestral, 70 BPM, slow pulse of low cellos and soft taiko-like drum, distant brass swells, ash and heat, mystery and quiet danger softened for a family game, seamless loop, no vocals"),
  M("forges_ombre", "Dark but gentle fantasy, 76 BPM, rhythmic soft anvil-like percussion, low brass drones, muted strings, glowing embers, a stern hidden camp of blacksmiths, tension without horror, seamless loop, no vocals"),
  M("terre_apex", "Sparse mysterious fantasy ambience with melody, 60 BPM, deep sustained cello and low piano notes, black volcanic rock, slow breathing rhythm, vast and solemn, quiet wonder, seamless loop, no vocals"),
  M("coeur_apex", "Slow emotional fantasy orchestral, 56 BPM, round open-sky amber chamber, glassy bell tones, warm strings swelling gently, hopeful and sacred, seamless loop, no vocals"),
  M("souverain", "Epic but family-friendly fantasy boss theme, 100 BPM, powerful low strings and brass, steady war drums, noble and sorrowful rather than evil, a huge frightened creature, seamless loop, no vocals"),
  M("jetee", "Tender nostalgic fantasy theme, 68 BPM, solo acoustic guitar and soft strings, sea breeze, reunion and farewell on a wooden pier at dusk, warm and hopeful, seamless loop, no vocals"),
];

const modules = process.env.AUDIO_MODULES;
const load = (name, entry) => import(modules ? pathToFileURL(path.join(modules, name, entry)).href : name);
const { MPEGDecoder } = await load("mpg123-decoder", "index.js");
const { createOggEncoder } = await load("wasm-media-encoders", "dist/esnext/index.mjs");

// ---------- ComfyUI ----------
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function generate(job, seed, rawPath) {
  const wf = JSON.parse(fs.readFileSync(WORKFLOW, "utf8"));
  wf["6"].inputs.text = job.prompt;
  wf["7"].inputs.text = job.neg;
  wf["11"].inputs.seconds = job.seconds;
  wf["3"].inputs.seed = seed;
  wf["3"].inputs.steps = job.steps;
  wf["20"].inputs.filename_prefix = `audio/ambrelune/${path.basename(rawPath, ".mp3")}`;
  wf["20"].inputs.format = "mp3";
  const res = await fetch(`${HOST}/prompt`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ prompt: wf, client_id: randomUUID() }) });
  if (!res.ok) throw new Error(`POST /prompt : HTTP ${res.status} ${(await res.text()).slice(0, 300)}`);
  const id = (await res.json()).prompt_id;
  for (;;) {
    await sleep(4000);
    const h = await (await fetch(`${HOST}/history/${id}`)).json();
    const e = h[id];
    if (!e) continue;
    if (e.status?.status_str === "error") throw new Error(`ComfyUI : echec du job ${id}`);
    if (!e.status?.completed) continue;
    const f = Object.values(e.outputs).flatMap((o) => Object.values(o).flat()).find((x) => x?.filename);
    if (!f) throw new Error(`pas de sortie pour ${id}`);
    const q = new URLSearchParams({ filename: f.filename, subfolder: f.subfolder ?? "", type: f.type ?? "output" });
    const r = await fetch(`${HOST}/view?${q}`);
    if (!r.ok) throw new Error(`GET /view : HTTP ${r.status}`);
    fs.writeFileSync(rawPath, Buffer.from(await r.arrayBuffer()));
    return;
  }
}

// ---------- traitement ----------
function lowpass(freq, sr) {
  const w = (2 * Math.PI * freq) / sr, alpha = Math.sin(w) / (2 * Math.SQRT1_2), cs = Math.cos(w), a0 = 1 + alpha;
  return { b0: (1 - cs) / 2 / a0, b1: (1 - cs) / a0, b2: (1 - cs) / 2 / a0, a1: (-2 * cs) / a0, a2: (1 - alpha) / a0 };
}
function filter(x, c) {
  const out = new Float32Array(x.length);
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < x.length; i++) {
    const v = x[i], y = c.b0 * v + c.b1 * x1 + c.b2 * x2 - c.a1 * y1 - c.a2 * y2;
    x2 = x1; x1 = v; y2 = y1; y1 = y; out[i] = y;
  }
  return out;
}
function stats(ch) {
  let peak = 0, sum = 0, n = 0;
  for (const c of ch) for (let i = 0; i < c.length; i++) { const a = Math.abs(c[i]); if (a > peak) peak = a; sum += c[i] * c[i]; n++; }
  const win = 22050, rms = [];
  for (let i = 0; i + win <= ch[0].length; i += win) { let s = 0; for (let j = i; j < i + win; j++) s += ch[0][j] ** 2; rms.push(Math.sqrt(s / win)); }
  const mean = rms.reduce((a, b) => a + b, 0) / (rms.length || 1);
  const sd = Math.sqrt(rms.reduce((a, b) => a + (b - mean) ** 2, 0) / (rms.length || 1));
  const quiet = rms.filter((r) => r < peak * 0.02).length; // fenetres de 0,5 s quasi muettes
  return { peak, rms: Math.sqrt(sum / n), levelCv: mean ? sd / mean : 0, quietWindows: quiet, windows: rms.length };
}
function crossfadeLoop(ch, sr, seconds) {
  const F = Math.floor(sr * seconds), N = ch[0].length, L = N - F;
  return ch.map((x) => {
    const o = new Float32Array(L);
    for (let i = 0; i < L; i++) {
      if (i < F) { const t = i / F, a = Math.sin(t * Math.PI / 2), b = Math.cos(t * Math.PI / 2); o[i] = x[i] * a + x[N - F + i] * b; }
      else o[i] = x[i];
    }
    return o;
  });
}
const DB = (x) => 20 * Math.log10(x || 1e-9);
const peakOf = (ch) => { let p = 0; for (const c of ch) for (let i = 0; i < c.length; i++) { const a = Math.abs(c[i]); if (a > p) p = a; } return p; };
function rmsRange(ch, a, b) { let s = 0, n = 0; for (const c of ch) for (let i = a; i < b; i++) { s += c[i] * c[i]; n++; } return Math.sqrt(s / (n || 1)); }
// RMS des seules fenetres de 50 ms actives (>= -40 dB sous le pic) : ignore les silences d'un son ponctuel.
function activeRms(ch, sr) {
  const win = Math.floor(sr * 0.05), th = peakOf(ch) * 0.01; let s = 0, n = 0;
  for (let i = 0; i + win <= ch[0].length; i += win) { const r = rmsRange(ch, i, i + win); if (r >= th) { s += r * r; n++; } }
  return Math.sqrt(s / (n || 1));
}
function trimEnds(ch, sr) { // silence de tete/queue sous -45 dB (relatif au pic) ; garde 30 ms avant et 150 ms apres
  const N = ch[0].length, th = peakOf(ch) * 10 ** (-45 / 20); let first = 0, last = N - 1;
  const loud = (i) => ch.some((c) => Math.abs(c[i]) > th);
  while (first < N - 1 && !loud(first)) first++;
  while (last > first && !loud(last)) last--;
  const a = Math.max(0, first - Math.floor(sr * 0.03)), b = Math.min(N, last + 1 + Math.floor(sr * 0.15));
  const fin = Math.floor(sr * 0.003), fout = Math.min(b - a, Math.floor(sr * 0.1));
  return ch.map((x) => { const o = x.slice(a, b); for (let i = 0; i < fin && i < o.length; i++) o[i] *= i / fin; for (let i = 0; i < fout; i++) o[o.length - 1 - i] *= i / fout; return o; });
}
async function encode(ch, sr, dest, quality) {
  const enc = await createOggEncoder();
  enc.configure({ channels: ch.length, sampleRate: sr, vbrQuality: quality });
  const parts = [];
  for (let i = 0; i < ch[0].length; i += 8192) parts.push(Buffer.from(enc.encode(ch.map((x) => x.subarray(i, i + 8192)))));
  parts.push(Buffer.from(enc.finalize()));
  fs.writeFileSync(dest, Buffer.concat(parts));
}
async function decode(mp3) {
  const dec = new MPEGDecoder(); await dec.ready;
  const { channelData, sampleRate } = dec.decode(new Uint8Array(fs.readFileSync(mp3))); dec.free();
  return { ch: channelData.slice(0, 2), sr: sampleRate };
}
const categoryOf = (job) => job.kind === "music" ? "music" : job.folder === "cries" ? "cries" : job.folder === "ambience" ? (job.loop ? "ambience-bed" : "ambience-call") : "sfx";
async function convert(mp3, dest, job) {
  let { ch, sr } = await decode(mp3);
  const before = stats(ch);
  if (job.lp) { const c = lowpass(job.lp, sr); ch = ch.map((x) => filter(filter(x, c), c)); }
  // boucle : fondu enchaine AVANT la normalisation ; ponctuel : silences de tete/queue coupes
  ch = job.loop ? crossfadeLoop(ch, sr, job.kind === "music" ? CROSSFADE_S.music : CROSSFADE_S.ambience) : trimEnds(ch, sr);
  const norm = normalizeToCategory(ch, sr, categoryOf(job));
  ch = norm.ch;
  await encode(ch, sr, dest, job.kind === "music" ? 6 : 5);
  const a = stats(ch);
  return { seconds: +(ch[0].length / sr).toFixed(2), ...norm.info, levelDb: norm.info.activeRmsDb, peak: +a.peak.toFixed(3), rms: +a.rms.toFixed(4), levelCv: +a.levelCv.toFixed(2), quietWindows: a.quietWindows, windows: a.windows, rawPeak: +before.peak.toFixed(3), rawRms: +before.rms.toFixed(4) };
}
const isSilent = (st) => st.peak < 0.03 || st.rms < 0.004;

// ---------- boucle principale ----------
const log = fs.existsSync(LOG) ? JSON.parse(fs.readFileSync(LOG, "utf8")) : {};
const save = () => fs.writeFileSync(LOG, JSON.stringify(log, null, 1));
fs.mkdirSync(RAW, { recursive: true });
const REDO = !!globalThis.process.env.REDO; // REDO=1 : refait les .ogg depuis les MP3 en cache, sans Stable Audio
const args = globalThis.process.argv.slice(2);
const all = [...SFX, ...MUSIC];
// Musique ecartee (Greg, 19/10 : timbre d orgue, 3 accords) : jamais lancee par defaut, seulement sur demande explicite.
const selected = all.filter((j) => (!args.length && j.kind !== "music") || args.includes(j.kind) || args.includes(j.name));

function finalPath(job) {
  const plain = `${OUT}/${job.folder}/${job.name}.ogg`;
  return fs.existsSync(plain) && !(log[job.name]?.chosenFile === plain) ? `${OUT}/${job.folder}/${job.name}_sa.ogg` : plain;
}

for (const job of selected) {
  const entry = (log[job.name] ??= { kind: job.kind, takes: {} });
  const variants = ["a", "b"];
  for (const v of variants) {
    if (entry.takes[v]?.ok && !REDO) continue;
    for (let k = 0; k < MAX_TRIES; k++) {
      const seed = job.seed + (v === "b" ? 500 : 0) + k * 1000;
      const raw = `${RAW}/${job.name}_${v}_${seed}.mp3`;
      const tmp = `${RAW}/${job.name}_${v}.ogg`;
      const t0 = Date.now();
      try {
        if (!fs.existsSync(raw)) await generate(job, seed, raw);
        const st = await convert(raw, tmp, job);
        const silent = isSilent({ peak: st.rawPeak, rms: st.rawRms });
        entry.takes[v] = { seed, ok: !silent, ...st, tmp, genSeconds: Math.round((Date.now() - t0) / 1000) };
        console.log(`${job.name}[${v}] graine ${seed} : ${st.seconds}s pic ${st.peak} rms ${st.rms} (brut pic ${st.rawPeak} rms ${st.rawRms})${silent ? " MUET -> autre graine" : ""}`);
        save();
        if (!silent) break;
      } catch (e) { console.log(`ERREUR ${job.name}[${v}] : ${e.message}`); entry.takes[v] = { seed, ok: false, error: e.message }; save(); await sleep(5000); }
    }
  }
  const a = entry.takes.a, b = entry.takes.b;
  // Defaut mesure : quasi muet, ecrete a la source (pic brut >= 0,99), trop de fenetres muettes dans une boucle.
  const defect = (t) => !t?.ok || t.rawPeak >= 0.99 || (job.loop && t.quietWindows > t.windows / 3);
  const crest = (t) => t.rawPeak / (t.rawRms || 1);
  let pick;
  if (!a?.ok && !b?.ok) pick = null;
  else if (!b?.ok) pick = "a";
  else if (!a?.ok) pick = "b";
  else if (job.kind === "music") pick = !defect(a) ? "a" : !defect(b) ? "b" : "a"; // musique : la 1re sauf defaut
  else if (defect(a) !== defect(b)) pick = defect(a) ? "b" : "a";
  else pick = job.loop && crest(b) < crest(a) * 0.75 ? "b" : "a"; // ambiance : la plus reguliere (moins de pics)
  if (!pick) { console.log(`ECHEC ${job.name} : aucune prise utilisable`); entry.chosen = null; save(); continue; }
  const dest = finalPath(job);
  fs.copyFileSync(entry.takes[pick].tmp, dest);
  entry.chosen = pick; entry.chosenFile = dest; save();
  console.log(`=> ${dest} (prise ${pick})`);
}

// ---------- pas dans la cendre : decoupe en pas individuels -> assets/audio/footsteps/cendre00..05.ogg ----------
const STEP_JOB = { kind: "sfx", folder: "sfx", seconds: 2, steps: 30, neg: NEG_SFX, loop: false, prompt: `single footstep on dry volcanic ash, crunchy, close-up, no echo, ${G}` };
const STEP_SEEDS = [3001, 3002, 3003];
function splitSteps(ch, sr) { // un pas = 0,2-0,4 s a partir d'un transitoire
  const hop = Math.floor(sr * 0.005), m = ch[0], env = [];
  for (let i = 0; i + hop <= m.length; i += hop) { let p = 0; for (let j = i; j < i + hop; j++) p = Math.max(p, Math.abs(m[j])); env.push(p); }
  const top = Math.max(...env), th = top * 0.2, onsets = [];
  for (let i = 1; i < env.length; i++) if (env[i] > th && env[i - 1] <= th && (!onsets.length || (i - onsets.at(-1)) * hop > sr * 0.3)) onsets.push(i);
  return onsets.map((o, k) => {
    const a = Math.max(0, o * hop - Math.floor(sr * 0.01));
    const nextOn = onsets[k + 1] !== undefined ? onsets[k + 1] * hop - Math.floor(sr * 0.02) : m.length;
    const b = Math.min(nextOn, a + Math.floor(sr * 0.35), m.length);
    if ((b - a) / sr < 0.2) return null;
    const fin = Math.floor(sr * 0.005), fout = Math.floor(sr * 0.06);
    return ch.map((x) => { const o2 = x.slice(a, b); for (let i = 0; i < fin; i++) o2[i] *= i / fin; for (let i = 0; i < fout; i++) o2[o2.length - 1 - i] *= i / fout; return o2; });
  }).filter(Boolean);
}
if (!args.length || args.includes("cendre")) {
  for (const seed of STEP_SEEDS) {
    const raw = `${RAW}/cendre_${seed}.mp3`;
    try { if (!fs.existsSync(raw)) await generate(STEP_JOB, seed, raw); } catch (e) { console.log(`ERREUR cendre ${seed} : ${e.message}`); }
  }
  const cands = [];
  for (const f of fs.readdirSync(RAW).filter((x) => /^(cendre_\d+|pas-cendre_.*)\.mp3$/.test(x)).sort()) {
    const { ch, sr } = await decode(`${RAW}/${f}`);
    const lp = lowpass(7000, sr), f2 = ch.map((x) => filter(x, lp));
    const peak = peakOf(f2);
    if (peak < 0.03) { console.log(`${f} : quasi muet, ignore`); continue; }
    for (const s of splitSteps(f2, sr)) cands.push({ src: f, ch: s, sr, crest: peakOf(s) });
    console.log(`${f} : ${cands.filter((c) => c.src === f).length} pas detectes`);
  }
  const chosen = cands.sort((a, b) => b.crest - a.crest).slice(0, 6);
  fs.mkdirSync(`${OUT}/footsteps`, { recursive: true });
  log.cendre = { steps: [] };
  for (const [i, c] of chosen.entries()) {
    const n = normalizeToCategory(c.ch, c.sr, "footsteps/footstep+footsteps/neige"), dest = `${OUT}/footsteps/cendre${String(i).padStart(2, "0")}.ogg`;
    await encode(n.ch, c.sr, dest, 5);
    log.cendre.steps.push({ file: dest, from: c.src, seconds: +(n.ch[0].length / c.sr).toFixed(2), ...n.info });
    console.log(`${dest} : ${(n.ch[0].length / c.sr).toFixed(2)}s pic ${n.info.peakDb} dB RMS actif ${n.info.activeRmsDb} dB (de ${c.src})`);
  }
  if (chosen.length < 6) console.log(`ATTENTION : seulement ${chosen.length} pas nets sur 6`);
  save();
}
console.log("Termine.");
