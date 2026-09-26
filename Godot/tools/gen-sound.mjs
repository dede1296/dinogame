// Generates a sound with ElevenLabs Sound Effects (key ELEVENLABS_API_KEY in the repository's
// .env.local, never committed) into Godot/assets/audio/<path>.mp3.
// Usage (from the repository root):
//   node Godot/tools/gen-sound.mjs ambience/pluie 22 loop "light gentle rain on grass and leaves…"
import fs from "node:fs";
import path from "node:path";

const API = "https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128";
const CLEAN = "natural field recording, stereo, high quality, no music, no human voice, no talking";

const [target, seconds, loopArg, ...words] = process.argv.slice(2);
if (!target || !seconds || words.length === 0) {
  console.error('Usage : node Godot/tools/gen-sound.mjs <dossier/nom> <secondes> <loop|once> "<description>"');
  process.exit(1);
}
const env = fs.readFileSync(".env.local", "utf8");
const key = env.match(/^ELEVENLABS_API_KEY=(.+)$/m)?.[1]?.trim();
if (!key) throw new Error("ELEVENLABS_API_KEY manquante dans .env.local");

const res = await fetch(API, {
  method: "POST",
  headers: { "xi-api-key": key, "Content-Type": "application/json" },
  body: JSON.stringify({
    text: `${words.join(" ")}, ${CLEAN}`,
    duration_seconds: Number(seconds),
    prompt_influence: 0.45,
    loop: loopArg === "loop",
    model_id: "eleven_text_to_sound_v2",
  }),
});
if (!res.ok) throw new Error(`HTTP ${res.status} ${(await res.text()).slice(0, 300)}`);
const file = path.join("Godot/assets/audio", `${target}.mp3`);
fs.mkdirSync(path.dirname(file), { recursive: true });
fs.writeFileSync(file, Buffer.from(await res.arrayBuffer()));
console.log(`${file} (${Math.round(fs.statSync(file).size / 1024)} Ko)`);
