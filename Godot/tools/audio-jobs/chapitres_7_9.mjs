// Bruitages des chapitres 7 a 9 (ElevenLabs gratuit : ~10 credits/s, plafond de ce lot 3000 credits).
// Genere les MP3 bruts dans Godot/tools/sounds/ (comme gen-sound.mjs), puis les convertit en Ogg
// Vorbis dans Godot/assets/audio/<dossier>/ avec un niveau homogene. N'ecrase jamais un fichier existant.
// Cle : ELEVENLABS_API_KEY dans .env.local a la racine du depot (jamais affichee).
// Usage (racine du depot) : AUDIO_MODULES=<node_modules> node Godot/tools/audio-jobs/chapitres_7_9.mjs [nom...]
//   (AUDIO_MODULES : dossier node_modules contenant mpg123-decoder et wasm-media-encoders)
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

const API = "https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128";
const CLEAN = "no music, no human voice, no talking, soft and gentle, nothing frightening";
const RAW = "Godot/tools/sounds";
const OUT = "Godot/assets/audio";
const BUDGET = 3000;
const TARGET_RMS = 0.1;
const MAX_PEAK = 0.9;

// folder, name, seconds, loop, lowpass Hz (0 = none), prompt
const JOBS = [
  ["ambience", "lave-bouillonne", 10, true, 3000, "thick molten lava slowly bubbling and blooping, deep low gurgles, soft crackles, distant"],
  ["ambience", "volcan-grondement", 10, true, 800, "very deep low rumble of a distant volcano, slow sub-bass tremor, steady and calm, no hiss"],
  ["ambience", "forge-ronfle", 10, true, 3000, "blacksmith forge furnace roaring softly, steady low flame whoosh, embers, no hammering"],
  ["ambience", "vent-hauteurs", 10, true, 2500, "high altitude wind over sky and clouds, smooth low steady howl, no whistling, no gusts spikes"],
  ["ambience", "forge-eteinte", 4, false, 4000, "a forge fire dying out: a soft breath of air then a long gentle hiss of cooling embers fading"],
  ["cries", "souverain-grondement", 4, false, 1500, "very deep low groan of a huge frightened animal, enormous, sorrowful, slow, not aggressive"],
  ["cries", "souverain-souffle", 4, false, 1500, "a huge animal exhaling a long calm deep breath of relief, slow, soothing, big chest"],
  ["cries", "tyran-magma-rugissement", 4, false, 3500, "deep theatrical roar of a giant dinosaur, low and resonant, powerful but not terrifying, cinematic"],
  ["sfx", "ambre-craque", 3, false, 6000, "amber crystal cracking and splitting open, glassy crack with a short resonant shimmer"],
  ["sfx", "portail-pierre", 5, false, 5000, "heavy stone gate sliding open with grinding stone, then a gentle magical chime at the end"],
  ["sfx", "coeur-ambre-pose", 3, false, 8000, "a glowing crystal heart set into a stone hollow, soft click then a crystalline bell chime ringing out"],
  ["sfx", "tasse-porcelaine", 2, false, 8000, "a porcelain tea cup set down gently on a wooden table, small clink"],
  ["sfx", "pas-cendre", 3, false, 4000, "slow footsteps walking in soft volcanic ash, muffled crunchy shuffle, four steps"],
];

const modules = process.env.AUDIO_MODULES;
const load = (name, entry) => import(modules ? pathToFileURL(path.join(modules, name, entry)).href : name);
const { MPEGDecoder } = await load("mpg123-decoder", "index.js");
const { createOggEncoder } = await load("wasm-media-encoders", "dist/esnext/index.mjs");

const key = fs.readFileSync(".env.local", "utf8").match(/^ELEVENLABS_API_KEY=(.+)$/m)?.[1]?.trim();
if (!key) throw new Error("ELEVENLABS_API_KEY manquante dans .env.local");

function lowpass(freq, sr) {
  const w = (2 * Math.PI * freq) / sr, alpha = Math.sin(w) / (2 * Math.SQRT1_2), cs = Math.cos(w), a0 = 1 + alpha;
  return { b0: (1 - cs) / 2 / a0, b1: (1 - cs) / a0, b2: (1 - cs) / 2 / a0, a1: (-2 * cs) / a0, a2: (1 - alpha) / a0 };
}
function filter(x, c) {
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  return x.map((v) => { const y = c.b0 * v + c.b1 * x1 + c.b2 * x2 - c.a1 * y1 - c.a2 * y2; x2 = x1; x1 = v; y2 = y1; y1 = y; return y; });
}
function gainFor(ch, sr, loop) {
  let peak = 0;
  for (const c of ch) for (const v of c) peak = Math.max(peak, Math.abs(v));
  if (!peak) return 1;
  if (!loop) return MAX_PEAK / peak; // one-shots: peak-normalised
  const win = Math.floor(sr * 0.4), rms = [];
  for (let i = 0; i + win <= ch[0].length; i += win) {
    let s = 0; for (let j = i; j < i + win; j++) s += ch[0][j] ** 2; rms.push(Math.sqrt(s / win));
  }
  rms.sort((a, b) => a - b);
  const typical = rms[Math.floor(rms.length / 2)];
  return typical ? Math.min(TARGET_RMS / typical, MAX_PEAK / peak) : 1;
}

async function toOgg(mp3, dest, loop, lp) {
  const dec = new MPEGDecoder(); await dec.ready;
  const { channelData, sampleRate } = dec.decode(new Uint8Array(fs.readFileSync(mp3))); dec.free();
  let ch = channelData.slice(0, 2);
  if (lp) { const c = lowpass(lp, sampleRate); ch = ch.map((x) => filter(filter(x, c), c)); }
  const g = gainFor(ch, sampleRate, loop);
  ch = ch.map((x) => x.map((v) => v * g));
  const enc = await createOggEncoder();
  enc.configure({ channels: ch.length, sampleRate, vbrQuality: 5 });
  const parts = [];
  for (let i = 0; i < ch[0].length; i += 8192) parts.push(Buffer.from(enc.encode(ch.map((x) => x.subarray(i, i + 8192)))));
  parts.push(Buffer.from(enc.finalize()));
  fs.writeFileSync(dest, Buffer.concat(parts));
  return { seconds: ch[0].length / sampleRate, gainDb: 20 * Math.log10(g) };
}

const wanted = process.argv.slice(2);
let spent = 0;
fs.mkdirSync(RAW, { recursive: true });
for (const [folder, name, seconds, loop, lp, prompt] of JOBS) {
  if (wanted.length && !wanted.includes(name)) continue;
  const dest = `${OUT}/${folder}/${name}.ogg`;
  if (fs.existsSync(dest)) { console.log(`${dest} existe deja : ignore`); continue; }
  if (spent + seconds * 10 > BUDGET) { console.log("Plafond de credits atteint : arret."); break; }
  const raw = `${RAW}/${name}.mp3`;
  if (!fs.existsSync(raw)) {
    const res = await fetch(API, {
      method: "POST", headers: { "xi-api-key": key, "Content-Type": "application/json" },
      body: JSON.stringify({ text: `${prompt}, ${CLEAN}`, duration_seconds: seconds, prompt_influence: 0.45, loop, model_id: "eleven_text_to_sound_v2" }),
    });
    if (!res.ok) { console.log(`REFUS ${name} : HTTP ${res.status} ${(await res.text()).slice(0, 200).replace(key, "***")}`); break; }
    fs.writeFileSync(raw, Buffer.from(await res.arrayBuffer()));
    spent += seconds * 10;
  }
  const r = await toOgg(raw, dest, loop, lp);
  console.log(`${dest} : ${r.seconds.toFixed(1)} s (demande ${seconds} s), gain ${r.gainDb.toFixed(1)} dB`);
}
console.log(`Credits estimes depenses : ${spent}`);
