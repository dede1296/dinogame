// Dinodex: the starting dino is caught, a wild dino crossed on the map becomes "seen",
// the grid shows eggs / faded / coloured pictures, and each entry opens.
import { chromium } from "playwright-core";
const b = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const p = await b.newPage({ viewport: { width: 390, height: 844 } });
const errors = []; p.on("pageerror", (e) => errors.push(e.message));
await p.goto("http://localhost:5173/dinogame/?demarrer&dino=Velociraptor&niveau=10&carte=ambreluneSud&x=22&y=36"); await p.waitForTimeout(3500);
// Bring Chloé next to a visible wild dino.
const crossed = await p.evaluate(async () => {
  const w = window.__game.scene.getScene("World");
  const r = w.roamers.find((e) => e.sprite);
  r.rule.wander = 0;
  w.occupied.delete(`${w.px},${w.py}`);
  w.px = r.x; w.py = r.y + 2; w.player.setPosition(w.px * 48 + 24, (w.py + 1) * 48);
  await new Promise((res) => setTimeout(res, 900));
  return { name: r.wild.speciesName, toast: document.querySelector(".toast")?.textContent };
});
console.log("CROISÉ:", crossed);
await p.click(".dexbtn"); await p.waitForTimeout(500);
console.log("COMPTEUR:", (await p.textContent(".dex-count")).replace(/\s+/g, " ").trim());
console.log("ÉTATS:", await p.evaluate(() => ["caught", "seen", "unseen"].map((s) => `${s}=${document.querySelectorAll(".dcard." + s).length}`).join(" ")));
await p.screenshot({ path: ".shots/test/dex.png" });
await p.click(".dcard.unseen"); await p.waitForTimeout(400);
await p.screenshot({ path: ".shots/test/dex-oeuf.png" });
await p.keyboard.press("Escape"); await p.waitForTimeout(300);
await p.click(".dcard.seen"); await p.waitForTimeout(400);
await p.screenshot({ path: ".shots/test/dex-vu.png" });
await p.keyboard.press("Escape"); await p.waitForTimeout(300);
await p.click(".dcard.caught"); await p.waitForTimeout(400);
await p.screenshot({ path: ".shots/test/dex-possede.png" });
await p.keyboard.press("Escape"); await p.waitForTimeout(300);
await p.click('[data-f="caught"]'); await p.waitForTimeout(300);
console.log("FILTRE POSSÉDÉS:", await p.locator(".dcard").count(), "| ERREURS:", errors);
await b.close();
