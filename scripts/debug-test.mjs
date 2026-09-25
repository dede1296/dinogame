// Debug mode: 5 taps on the title show the button; each checkpoint loads without errors on a free tile.
import { chromium } from "playwright-core";
const b = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const p = await b.newPage({ viewport: { width: 430, height: 900 } });
// A real game in slot 1 that debug mode must never touch.
await p.addInitScript(() => { if (!localStorage.getItem("dino-hybride-v2")) localStorage.setItem("dino-hybride-v2", JSON.stringify({ party: [], flags: {}, savedAt: 1 })); });
const errors = []; p.on("pageerror", (e) => errors.push(e.message));
p.on("dialog", (d) => d.accept());
const URL = "http://localhost:5173/dinogame/nouveau/";
await p.goto(URL); await p.waitForTimeout(800);
await p.evaluate(() => localStorage.removeItem("dino-debug"));
await p.reload(); await p.waitForTimeout(800);
for (let i = 0; i < 5; i++) await p.click("#title h1");
console.log("BOUTON DEBUG VISIBLE:", await p.isVisible("#debug"));
for (const id of ["ch1", "ch1-grotte", "ch1-alpha", "ch1-tronc", "ch2"]) {
  await p.goto(URL); await p.waitForTimeout(600);
  await p.click("#debug");
  await Promise.all([p.waitForNavigation(), p.click(`[data-cp="${id}"]`)]);
  await p.waitForTimeout(3500);
  const r = await p.evaluate(() => {
    const w = window.__game?.scene.getScene("World");
    if (!w?.map) return "pas de monde";
    const blocked = w.solid[w.py]?.[w.px];
    return `${w.mapId} (${w.px},${w.py}) sol bloqué=${blocked} script=${w.scriptRunning} équipe=${JSON.parse(localStorage.getItem("dino-hybride-v2-debug")).party.map((d) => d.speciesName + " " + d.level).join(", ")}`;
  });
  console.log(id, "→", r);
  await p.screenshot({ path: `.shots/test/debug-${id}.png` });
}
console.log("PARTIE 1 INTACTE:", await p.evaluate(() => JSON.parse(localStorage.getItem("dino-hybride-v2")).savedAt === 1));
console.log("ERREURS:", errors);
await b.close();
