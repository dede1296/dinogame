// Generates the dino cry recordings with ElevenLabs Sound Effects (key in .env.local,
// never committed). Output: nouveau/assets/cries/<id>.mp3, used as the raw material of
// the cries (nouveau/src/audio/cries.js varies them per species and situation).
// Usage: node scripts/gen-cries.mjs            (all missing sounds)
//        node scripts/gen-cries.mjs tyran-1    (only these ids, regenerated)
import fs from "node:fs";

const OUT = "nouveau/assets/cries";
const API = "https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_64";

// Shared ending of every prompt: a clean, isolated creature sound.
const CLEAN = "single isolated creature vocalization, close microphone, dry, no music, no ambience, no background noise, no human voice";

// One voice per family (the id matches nouveau/src/audio/cries.js), described like film
// creature sound design: which real animals it blends.
const FAMILIES = {
  tyran: "huge carnivorous theropod dinosaur (like a T-rex): deep guttural roar layered from an alligator bellow, a baby elephant trumpet and a tiger growl",
  raptor: "agile pack-hunting raptor dinosaur the size of a wolf: raspy bird-like screech mixed with a goose hiss and a hawk cry, clicking throat",
  ceratopsien: "large horned herbivore dinosaur (like a triceratops): low bellowing snort mixing a rhinoceros grunt, a buffalo moo and a bull huff",
  sauropode: "gigantic long-necked sauropod dinosaur: extremely deep booming resonant low call, like an elephant rumble mixed with a whale moan, felt more than heard",
  cuirasse: "stocky armored dinosaur (like an ankylosaurus): short heavy grunts and nasal huffs mixing a hippopotamus grunt and a wild boar snort",
  spino: "semi-aquatic sail-backed predator dinosaur (like a spinosaurus): wet crocodile hiss-growl with a gurgling throat, snapping jaws",
  hadrosaure: "duck-billed hadrosaur dinosaur with a hollow head crest: resonant honking call like a low tuba or foghorn mixed with a goose honk",
  pterosaure: "large flying reptile pterosaur: shrill squawking seabird cry mixed with a heron croak and a raspy hiss",
  marin: "large prehistoric marine reptile (like a mosasaurus): watery bubbling roar mixed with a walrus bellow and a whale call",
};

// The situations of a cry; "content" (a happy call) is derived from "neutre" in the game.
const MOODS = {
  neutre: { duration: 2.2, text: "calling out, a territorial call" },
  attaque: { duration: 1.2, text: "aggressive short attack roar as it lunges to bite, snarling" },
  degat: { duration: 0.9, text: "short pained yelp and grunt when it gets hit, surprised and hurt" },
  ko: { duration: 2.2, text: "weak exhausted groan fading out as it collapses, defeated" },
};

export const CRIES = Object.entries(FAMILIES).flatMap(([fam, voice]) =>
  Object.entries(MOODS).map(([mood, m]) => ({ id: `${fam}-${mood}`, duration: m.duration, prompt: `${voice}, ${m.text}, cinematic creature sound design, ${CLEAN}` })));

function apiKey() {
  const env = fs.readFileSync(".env.local", "utf8");
  const key = env.match(/^ELEVENLABS_API_KEY=(.+)$/m)?.[1]?.trim();
  if (!key) throw new Error("ELEVENLABS_API_KEY manquante dans .env.local");
  return key;
}

async function generate({ id, prompt, duration }, key) {
  const res = await fetch(API, {
    method: "POST",
    headers: { "xi-api-key": key, "Content-Type": "application/json" },
    body: JSON.stringify({ text: prompt, duration_seconds: duration, prompt_influence: 0.6 }),
  });
  if (!res.ok) throw new Error(`${id} : HTTP ${res.status} ${(await res.text()).slice(0, 300)}`);
  const file = `${OUT}/${id}.mp3`;
  fs.writeFileSync(file, Buffer.from(await res.arrayBuffer()));
  return `${file} (${Math.round(fs.statSync(file).size / 1024)} Ko)`;
}

const only = process.argv.slice(2);
const key = apiKey();
fs.mkdirSync(OUT, { recursive: true });
for (const cry of CRIES) {
  if (only.length ? !only.includes(cry.id) : fs.existsSync(`${OUT}/${cry.id}.mp3`)) continue;
  try { console.log("OK", await generate(cry, key)); } catch (e) { console.log("ÉCHEC", e.message); }
}
