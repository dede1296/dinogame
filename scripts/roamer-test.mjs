// Visible wild dinos: walks into one, checks the battle starts, flees, and checks it left the map.
import { chromium } from "playwright-core";
const browser = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const page = await browser.newPage({ viewport: { width: 430, height: 900 }, deviceScaleFactor: 1 });
const errors = [];
page.on("pageerror", (e) => errors.push(e.message));
await page.goto("http://localhost:5173/dinogame/nouveau/?demarrer&dino=Spinosaurus&niveau=30&carte=grotte1&x=12&y=15");
await page.waitForTimeout(3500);
// Put Chloé just left of the first roamer, facing it, then walk into it.
const info = await page.evaluate(() => {
  const w = window.__game.scene.getScene("World");
  const r = w.roamers.find((e) => !w.blocked(e.x - 1, e.y) && e.sprite);
  r.rule.wander = 0; // keep it still for the test
  w.occupied.delete(`${w.px},${w.py}`);
  w.px = r.x - 1; w.py = r.y; w.dir = "right";
  w.player.setPosition(w.px * 48 + 24, (w.py + 1) * 48);
  return { count: w.roamers.length, x: r.x, y: r.y, species: r.wild.speciesName };
});
console.log("ROAMERS:", info);
await page.keyboard.down("ArrowRight"); await page.waitForTimeout(120); await page.keyboard.up("ArrowRight");
await page.waitForTimeout(3500);
await page.screenshot({ path: ".shots/test/roamer-combat.png" });
console.log("COMBAT:", await page.evaluate(() => window.__game.scene.isActive("Battle")));
// Flee: end the battle through the scene, as the "Fuir" button would.
await page.evaluate(() => window.__game.scene.getScene("Battle").leave("run"));
await page.waitForTimeout(1500);
console.log("RESTE SUR LA CARTE:", await page.evaluate(({ x, y }) => !!window.__game.scene.getScene("World").entityAt(x, y), info));
console.log("ERREURS:", errors);
await browser.close();
