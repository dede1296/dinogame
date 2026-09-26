// Generates the ambience recordings with ElevenLabs Sound Effects (key in .env.local,
// never committed). Output: nouveau/assets/ambience/<id>.mp3, mixed by
// nouveau/src/audio/ambience.js (long beds looped with a cross-fade, short calls
// scattered at random).
// Usage: node scripts/gen-ambience.mjs              (all missing sounds)
//        node scripts/gen-ambience.mjs vagues ...   (only these ids, regenerated)
import fs from "node:fs";

const OUT = "nouveau/assets/ambience";
const API = "https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_64";

// Shared ending of every prompt: a clean field recording, never music or voices.
const CLEAN = "natural field recording, stereo, high quality, no music, no human voice, no talking";
const BED = "steady and even from start to end, seamless loop";

export const AMBIENCES = [
  // ---------------- Chapter 1 (beds: long loops)
  { id: "vagues", duration: 22, loop: true, prompt: `gentle small waves lapping on a sandy beach, soft foam washing in and out, calm sea, ${BED}` },
  { id: "vent", duration: 22, loop: true, prompt: `light breeze blowing through tall grass and ferns in an open meadow, soft rustling, occasional gentle gust, ${BED}` },
  { id: "prairie", duration: 22, loop: true, prompt: `peaceful sunny meadow in the morning: distant songbirds, a few crickets and buzzing insects, soft breeze, ${BED}` },
  { id: "village", duration: 22, loop: true, prompt: `small fishing harbour close up: moored wooden boats creaking and knocking softly against the dock, water lapping against the pier, ropes and rigging clinking in the breeze, clearly audible, ${BED}` },
  { id: "grotte", duration: 22, loop: true, prompt: `inside a deep dark cave: slow water drops echoing, faint hollow wind whistling like a distant flute through rock, deep rumble, ${BED}` },
  { id: "labo", duration: 20, loop: true, prompt: `old scientific laboratory at night: low hum of an old machine, liquid softly bubbling in glass flasks, occasional glass clink, ${BED}` },
  { id: "maison", duration: 20, loop: true, prompt: `cosy old wooden cottage interior, close microphone: clear loud tick-tock of a big pendulum clock on the wall, soft wind against the window, old floorboards creaking now and then, clearly audible, ${BED}` },
  { id: "feu", duration: 16, loop: true, prompt: `small campfire crackling and popping softly, close, ${BED}` },
  // ---------------- Short calls, scattered at random over the beds
  { id: "mouettes", duration: 4, prompt: "a few seagulls calling in the distance above the sea, then silence" },
  { id: "oiseau-1", duration: 3, prompt: "a single small songbird singing a short cheerful melodic phrase, close, then silence" },
  { id: "oiseau-2", duration: 3, prompt: "a blackbird singing a short fluty song, then silence" },
  { id: "oiseau-3", duration: 3, prompt: "a wood pigeon cooing softly twice, then silence" },
  { id: "rafale", duration: 6, prompt: "a single gust of wind rising and fading over an open plain, whoosh through grass" },
  { id: "goutte", duration: 3, prompt: "a few single water drops falling into a puddle in a cave, with long echo" },
  // ---------------- Later chapters (see HISTOIRE.md)
  { id: "foret", duration: 22, loop: true, prompt: `dense prehistoric jungle: exotic birds calling, insects buzzing, leaves rustling, distant hoots, humid and lush, ${BED}` },
  { id: "marais", duration: 22, loop: true, prompt: `misty swamp at dusk: frogs croaking, insects, slow bubbling mud, water dripping, ${BED}` },
  { id: "desert", duration: 22, loop: true, prompt: `hot empty desert canyon: dry wind blowing sand, faint whistling between rocks, ${BED}` },
  { id: "cote", duration: 22, loop: true, prompt: `rocky ocean coast: big waves crashing on rocks, sea spray, strong sea wind, distant seagulls, ${BED}` },
  { id: "monts", duration: 22, loop: true, prompt: `frozen high mountain pass: cold howling wind, blowing snow, icy and lonely, ${BED}` },
  { id: "cieux", duration: 22, loop: true, prompt: `very high mountain summit above the clouds: wide airy wind, distant large birds calling far away, ${BED}` },
  { id: "volcan", duration: 22, loop: true, prompt: `active volcano: deep earth rumble, lava bubbling and hissing, hot vents steaming, ${BED}` },
];

function apiKey() {
  const env = fs.readFileSync(".env.local", "utf8");
  const key = env.match(/^ELEVENLABS_API_KEY=(.+)$/m)?.[1]?.trim();
  if (!key) throw new Error("ELEVENLABS_API_KEY manquante dans .env.local");
  return key;
}

async function generate(key, a) {
  const res = await fetch(API, {
    method: "POST",
    headers: { "xi-api-key": key, "Content-Type": "application/json" },
    body: JSON.stringify({ text: `${a.prompt}, ${CLEAN}`, duration_seconds: a.duration, prompt_influence: 0.45, loop: !!a.loop, model_id: "eleven_text_to_sound_v2" }),
  });
  if (!res.ok) throw new Error(`${a.id} : HTTP ${res.status} ${(await res.text()).slice(0, 200)}`);
  const file = `${OUT}/${a.id}.mp3`;
  fs.writeFileSync(file, Buffer.from(await res.arrayBuffer()));
  return `${file} (${Math.round(fs.statSync(file).size / 1024)} Ko)`;
}

// Only when run directly (the game reads nothing from here).
if (process.argv[1]?.endsWith("gen-ambience.mjs")) {
  const key = apiKey();
  const only = process.argv.slice(2);
  fs.mkdirSync(OUT, { recursive: true });
  for (const a of AMBIENCES) {
    if (only.length ? !only.includes(a.id) : fs.existsSync(`${OUT}/${a.id}.mp3`)) continue;
    try { console.log("OK", await generate(key, a)); } catch (e) { console.log("ÉCHEC", e.message); }
  }
}
