// Music and ambience: every theme compiles, loudness of each one (peak / RMS, no
// clipping), and the right music and ambience on the title screen, in the village, near
// the sea, in the Plains, indoors, in a wild battle and back.
import { chromium } from "playwright-core";
const b = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true, args: ["--autoplay-policy=no-user-gesture-required"] });
const p = await b.newPage({ viewport: { width: 390, height: 844 } });
p.setDefaultTimeout(8000);
const errors = []; p.on("pageerror", (e) => errors.push(e.message));

// A meter between the game and the speakers: every AudioContext's destination is
// replaced by an analyser that feeds the real one.
await p.addInitScript(() => {
  const AC = window.AudioContext;
  window.AudioContext = class extends AC {
    constructor(...a) {
      super(...a);
      const meter = this.createAnalyser();
      meter.fftSize = 2048;
      meter.connect(super.destination);
      Object.defineProperty(this, "destination", { value: meter });
      window.__meter = meter;
    }
  };
});
const measure = (ms) => p.evaluate(async (ms) => {
  const m = window.__meter, buf = new Float32Array(m.fftSize);
  let peak = 0, sum = 0, n = 0;
  const end = performance.now() + ms;
  while (performance.now() < end) {
    m.getFloatTimeDomainData(buf);
    for (const v of buf) { peak = Math.max(peak, Math.abs(v)); sum += v * v; n++; }
    await new Promise((r) => setTimeout(r, 40));
  }
  return { peak: +peak.toFixed(2), rms: +Math.sqrt(sum / n).toFixed(3) };
}, ms);
const audio = () => p.evaluate(() => ({ music: window.__audio.currentMusic(), ambience: window.__audio.currentAmbience() }));

// Title screen.
await p.goto("http://localhost:5173/dinogame/");
await p.mouse.click(5, 5); await p.waitForTimeout(1500);
console.log("TITRE :", await audio());
console.log("THÈMES :", (await p.evaluate(() => window.__audio.validateThemes())).join(", "));

// Loudness of each theme (music bus at its default level, no ambience).
const themes = await p.evaluate(() => window.__audio.validateThemes());
for (const id of themes) {
  await p.evaluate((id) => window.__audio.music(id, { fade: 0.05 }), id);
  await p.waitForTimeout(700);
  console.log(`  ${id.padEnd(9)}`, JSON.stringify(await measure(5000)));
}
await p.evaluate(() => window.__audio.music(null, { fade: 0.05 }));

// Loudness of each ambience alone.
for (const id of ["port", "plaines", "grotte", "cabinet", "maison", "foret", "cote", "volcan"]) {
  await p.evaluate((id) => window.__audio.setAmbience(id, 0.05), id);
  await p.waitForTimeout(4000);
  console.log(`  ambiance ${id.padEnd(8)}`, JSON.stringify(await measure(3000)));
}

// In the game.
const URL = "http://localhost:5173/dinogame/?demarrer&niveau=12&carte=ambreluneSud";
const world = () => p.evaluate(() => { const w = window.__game.scene.getScene("World"); return { map: w.mapId, y: w.py }; });
await p.goto(`${URL}&x=22&y=50`); await p.mouse.click(5, 5); await p.waitForTimeout(3500);
console.log("VILLAGE :", await audio(), await world());
await p.goto(`${URL}&x=22&y=66`); await p.mouse.click(5, 5); await p.waitForTimeout(3500);
console.log("PLAGE :", await audio(), await world());
await p.goto(`${URL}&x=22&y=36`); await p.mouse.click(5, 5); await p.waitForTimeout(3500);
console.log("PLAINES :", await audio(), await world());

// A wild battle, then back to the Plains.
await p.evaluate(() => { const w = window.__game.scene.getScene("World"); w.launchWild(w.roamers[0].wild, "plaines"); });
await p.waitForTimeout(2500);
console.log("COMBAT :", await audio());
// Forced escape (once: the interrupted battle loop tries to leave again).
await p.evaluate(() => { const s = window.__game.scene.getScene("Battle"), leave = s.leave.bind(s); let done = false; s.leave = (r) => { if (!done) { done = true; leave(r); } }; s.ui?.destroy(); s.leave("run"); });
await p.waitForTimeout(2500);
console.log("APRÈS LE COMBAT :", await audio());

await p.goto("http://localhost:5173/dinogame/?demarrer&carte=boutique"); await p.mouse.click(5, 5); await p.waitForTimeout(3500);
console.log("BOUTIQUE :", await audio());

// Menu › Journal: Hélène's letter listed first, and each page read aloud.
await p.goto(`${URL}&x=22&y=50`); await p.mouse.click(5, 5); await p.waitForTimeout(3500);
await p.evaluate(() => {
  window.__state.flags.letter_read = true;
  window.__state.journal = [1, 3];
  // Records the recordings started (a voiced page lasts several seconds).
  window.__voices = [];
  const start = AudioBufferSourceNode.prototype.start;
  AudioBufferSourceNode.prototype.start = function (...a) { if (this.buffer?.duration > 8) window.__voices.push(+this.buffer.duration.toFixed(1)); return start.apply(this, a); };
});
await p.click(".menubtn"); await p.waitForTimeout(600);
await p.click('[data-m="journal"]'); await p.waitForTimeout(600);
console.log("JOURNAL :", await p.$$eval(".item", (els) => els.map((e) => e.textContent.replace("Lire", "").trim())));
for (const sel of ['[data-letter]', '[data-page="3"]']) {
  await p.click(sel); await p.waitForTimeout(2500);
  console.log(`  ${sel} lu à voix haute :`, await p.evaluate(() => window.__voices.splice(0)));
  await p.click(".letter"); await p.waitForTimeout(500);
}
console.log("ERREURS:", errors);
await b.close();
