// Converts the chosen Kenney (CC0) OGG sounds into small mono WAV files that every phone can play.
// Usage: node scripts/convert-sfx.mjs  (packs unzipped in .shots/kenney)
import { chromium } from "playwright-core";
import fs from "node:fs";

const K = ".shots/kenney";
const PICK = {
  step_grass_0: "impact-sounds/Audio/footstep_grass_000.ogg",
  step_grass_1: "impact-sounds/Audio/footstep_grass_001.ogg",
  step_grass_2: "impact-sounds/Audio/footstep_grass_002.ogg",
  step_grass_3: "impact-sounds/Audio/footstep_grass_003.ogg",
  step_wood_0: "impact-sounds/Audio/footstep_wood_000.ogg",
  step_wood_1: "impact-sounds/Audio/footstep_wood_001.ogg",
  step_stone_0: "impact-sounds/Audio/footstep_concrete_000.ogg",
  step_stone_1: "impact-sounds/Audio/footstep_concrete_001.ogg",
  step_stone_2: "impact-sounds/Audio/footstep_concrete_002.ogg",
  step_carpet_0: "impact-sounds/Audio/footstep_carpet_000.ogg",
  step_carpet_1: "impact-sounds/Audio/footstep_carpet_001.ogg",
  door_open: "rpg-audio/Audio/doorOpen_1.ogg",
  door_close: "rpg-audio/Audio/doorClose_2.ogg",
  bump: "impact-sounds/Audio/impactSoft_medium_000.ogg",
  ui_move: "interface-sounds/Audio/select_002.ogg",
  ui_ok: "interface-sounds/Audio/click_002.ogg",
  ui_back: "interface-sounds/Audio/back_002.ogg",
  ui_open: "interface-sounds/Audio/open_002.ogg",
  ui_close: "interface-sounds/Audio/close_002.ogg",
  text: "interface-sounds/Audio/tick_001.ogg",
  item: "interface-sounds/Audio/confirmation_002.ogg",
  coins: "rpg-audio/Audio/handleCoins.ogg",
  page: "rpg-audio/Audio/bookFlip2.ogg",
  cloth: "rpg-audio/Audio/cloth1.ogg",
  rock_0: "impact-sounds/Audio/impactMining_000.ogg",
  rock_1: "impact-sounds/Audio/impactMining_003.ogg",
  rock_heavy: "impact-sounds/Audio/impactPlate_heavy_002.ogg",
  wood_heavy: "impact-sounds/Audio/impactWood_heavy_001.ogg",
  chop: "rpg-audio/Audio/chop.ogg",
  slice: "rpg-audio/Audio/knifeSlice.ogg",
  hit_0: "impact-sounds/Audio/impactPunch_heavy_000.ogg",
  hit_1: "impact-sounds/Audio/impactPunch_heavy_002.ogg",
  hit_soft: "impact-sounds/Audio/impactPunch_medium_001.ogg",
  glass: "interface-sounds/Audio/glass_002.ogg",
  machine: "interface-sounds/Audio/glitch_002.ogg",
  latch: "rpg-audio/Audio/metalLatch.ogg",
};

function wav(samples, rate) {
  const buf = Buffer.alloc(44 + samples.length * 2);
  buf.write("RIFF", 0); buf.writeUInt32LE(36 + samples.length * 2, 4); buf.write("WAVE", 8);
  buf.write("fmt ", 12); buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(1, 22);
  buf.writeUInt32LE(rate, 24); buf.writeUInt32LE(rate * 2, 28); buf.writeUInt16LE(2, 32); buf.writeUInt16LE(16, 34);
  buf.write("data", 36); buf.writeUInt32LE(samples.length * 2, 40);
  samples.forEach((s, i) => buf.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(s * 32767))), 44 + i * 2));
  return buf;
}

const browser = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const page = await browser.newPage();
await page.goto("about:blank");
const RATE = 22050;
let total = 0;
for (const [name, file] of Object.entries(PICK)) {
  const b64 = fs.readFileSync(`${K}/${file}`).toString("base64");
  const samples = await page.evaluate(async ({ b64, RATE }) => {
    const bytes = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
    const tmp = new OfflineAudioContext(1, 1, 44100);
    const decoded = await tmp.decodeAudioData(bytes.buffer);
    const off = new OfflineAudioContext(1, Math.ceil(decoded.duration * RATE), RATE);
    const src = off.createBufferSource(); src.buffer = decoded; src.connect(off.destination); src.start();
    const out = (await off.startRendering()).getChannelData(0);
    // Trim trailing silence.
    let end = out.length;
    while (end > 0 && Math.abs(out[end - 1]) < 0.002) end--;
    return Array.from(out.subarray(0, end + 200));
  }, { b64, RATE });
  const data = wav(samples, RATE);
  fs.writeFileSync(`nouveau/assets/sfx/${name}.wav`, data);
  total += data.length;
}
console.log(Object.keys(PICK).length, "sons,", Math.round(total / 1024), "Ko");
await browser.close();
