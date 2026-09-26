// Plays the opening of the new game in a real (headless) Edge and takes screenshots.
// Usage: node scripts/play-test.mjs   (needs `npx vite` running on port 5173)
import { chromium } from "playwright-core";
import fs from "node:fs";

const EDGE = "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe";
const URL = "http://localhost:5173/dinogame/?demarrer";
const OUT = ".shots/test";
fs.mkdirSync(OUT, { recursive: true });

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
const page = await browser.newPage({ viewport: { width: 430, height: 900 }, deviceScaleFactor: 2 });
const errors = [];
page.on("pageerror", (e) => errors.push(e.message));
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()); });

const wait = (ms) => page.waitForTimeout(ms);
const shot = (name) => page.screenshot({ path: `${OUT}/${name}.png` });
async function walk(key, steps) {
  for (let i = 0; i < steps; i++) {
    await page.keyboard.down(key);
    await wait(70);
    await page.keyboard.up(key);
    await wait(230);
  }
}
async function a(times = 1) {
  for (let i = 0; i < times; i++) { await page.keyboard.press("Space"); await wait(350); }
}
const dialogText = () => page.evaluate(() => document.querySelector(".dialog .txt")?.textContent || "");
async function readAll(max = 12) {
  const lines = [];
  for (let i = 0; i < max; i++) {
    await wait(700);
    const t = await dialogText();
    if (!t) break;
    lines.push(t);
    await a();
  }
  return lines;
}

await page.goto(URL);
await wait(2500);
await shot("01-arrivee");
console.log("INTRO:", await readAll());

await walk("ArrowUp", 21);
await shot("02-place");
await walk("ArrowRight", 7);
await walk("ArrowUp", 2);
await wait(1200);
await shot("03-cabinet");

await walk("ArrowUp", 3);
await a();
console.log("ROC:", await readAll());
await walk("ArrowRight", 3);
await a();
// Advance the pedestal text until the choice appears, then pick the first option.
for (let i = 0; i < 6 && !(await page.$(".choices")); i++) { await wait(600); await a(); }
await shot("04-choix");
await a();
console.log("APRES:", await readAll());
await wait(1500);
await shot("05-compagnon");

// Out to the plains: through the door, north, into the tall grass.
await walk("ArrowLeft", 3);
await walk("ArrowDown", 4);
await wait(1500);
await walk("ArrowDown", 1);
await walk("ArrowLeft", 7);
await walk("ArrowUp", 7);
console.log("MAIA:", await readAll());
await shot("06-plaines");
let met = false;
for (let i = 0; i < 40 && !met; i++) {
  await walk(i % 8 < 4 ? "ArrowLeft" : "ArrowRight", 1);
  if (i < 6) await walk("ArrowUp", 1);
  met = !!(await dialogText());
}
await wait(1500);
await shot("07-rencontre");
console.log("RENCONTRE:", await dialogText());

console.log("ERREURS:", errors.length ? errors : "aucune");
await browser.close();
