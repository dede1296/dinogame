// Generates the voiced dialogue lines with ElevenLabs text-to-speech (key in .env.local,
// never committed). Lines and voices: nouveau/src/data/voiceLines.js.
// Output: nouveau/assets/voices/<id>.mp3
// Usage: node scripts/gen-voices.mjs            (all missing lines)
//        node scripts/gen-voices.mjs roc-1 ...  (only these ids, regenerated)
import fs from "node:fs";
import { VOICE_ACTORS, VOICE_LINES } from "../nouveau/src/data/voiceLines.js";

const OUT = "nouveau/assets/voices";
const API = "https://api.elevenlabs.io/v1";
const MODEL = "eleven_multilingual_v2";

const key = fs.readFileSync(".env.local", "utf8").match(/^ELEVENLABS_API_KEY=(.+)$/m)?.[1]?.trim();
if (!key) throw new Error("ELEVENLABS_API_KEY manquante dans .env.local");
const headers = { "xi-api-key": key, "Content-Type": "application/json" };

// Library voices must be added to the account once before they can speak.
async function ensureVoices() {
  const mine = (await (await fetch(`${API}/voices`, { headers })).json()).voices.map((v) => v.voice_id);
  for (const [speaker, v] of Object.entries(VOICE_ACTORS)) {
    if (!v.owner || mine.includes(v.id)) continue; // ElevenLabs' own voices need no adding
    const res = await fetch(`${API}/voices/add/${v.owner}/${v.id}`, { method: "POST", headers, body: JSON.stringify({ new_name: `Ambrelune ${speaker}` }) });
    const body = await res.json();
    if (!res.ok) throw new Error(`Voix de ${speaker} : ${JSON.stringify(body).slice(0, 200)}`);
    v.id = body.voice_id || v.id;
    console.log(`Voix ajoutée : ${speaker} → ${v.name}`);
  }
}

async function speak(line) {
  const actor = VOICE_ACTORS[line.speaker];
  const res = await fetch(`${API}/text-to-speech/${actor.id}?output_format=mp3_44100_64`, {
    method: "POST", headers,
    body: JSON.stringify({ text: line.text, model_id: MODEL, language_code: "fr", voice_settings: { stability: 0.5, similarity_boost: 0.75, style: 0.3 } }),
  });
  if (!res.ok) throw new Error(`${line.id} : HTTP ${res.status} ${(await res.text()).slice(0, 200)}`);
  const file = `${OUT}/${line.id}.mp3`;
  fs.writeFileSync(file, Buffer.from(await res.arrayBuffer()));
  return `${file} (${Math.round(fs.statSync(file).size / 1024)} Ko)`;
}

const only = process.argv.slice(2);
fs.mkdirSync(OUT, { recursive: true });
await ensureVoices();
for (const line of VOICE_LINES) {
  if (only.length ? !only.includes(line.id) : fs.existsSync(`${OUT}/${line.id}.mp3`)) continue;
  try { console.log("OK", await speak(line)); } catch (e) { console.log("ÉCHEC", e.message); }
}
