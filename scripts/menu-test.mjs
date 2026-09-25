// Options menu (volume saved, save button) and running with B held.
import { chromium } from "playwright-core";
const b = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const p = await b.newPage({ viewport: { width: 430, height: 900 } });
const errors = []; p.on("pageerror", (e) => errors.push(e.message)); p.on("dialog", (d) => d.dismiss());
await p.goto("http://localhost:5173/dinogame/nouveau/?demarrer&dino=Velociraptor&niveau=10&carte=ambreluneSud&x=22&y=36"); await p.waitForTimeout(3500);
await p.evaluate(() => { const w = window.__game.scene.getScene("World"); w.map.zones.forEach((z) => (z.encounters = null)); w.roamers.forEach((r) => w.removeRoamer(r)); });
const walk = async (run) => {
  const y0 = await p.evaluate(() => window.__game.scene.getScene("World").py);
  if (run) await p.keyboard.down("Shift");
  await p.keyboard.down("ArrowUp"); await p.waitForTimeout(1500); await p.keyboard.up("ArrowUp");
  if (run) await p.keyboard.up("Shift");
  await p.waitForTimeout(400);
  return y0 - await p.evaluate(() => window.__game.scene.getScene("World").py);
};
console.log("CASES EN MARCHANT:", await walk(false), "EN COURANT:", await walk(true));
await p.click(".menubtn"); await p.waitForTimeout(300);
await p.click('[data-t="options"]');
await p.$eval('[data-opt="volume"]', (el) => { el.value = 30; el.dispatchEvent(new Event("input", { bubbles: true })); el.dispatchEvent(new Event("change", { bubbles: true })); });
await p.click('[data-opt="save"]'); await p.waitForTimeout(300);
await p.screenshot({ path: ".shots/test/menu-options.png" });
console.log("VOLUME:", await p.evaluate(() => localStorage.getItem("dino-volume")), "TOAST:", await p.textContent(".toast"));
console.log("ERREURS:", errors); await b.close();
