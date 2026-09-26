// Port-Ambre shop: the building, going in, talking to the keeper, buying and selling.
import { chromium } from "playwright-core";
const b = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const p = await b.newPage({ viewport: { width: 390, height: 844 } });
p.setDefaultTimeout(6000);
const errors = []; p.on("pageerror", (e) => errors.push(e.message));
const press = async (k, n = 1) => { for (let i = 0; i < n; i++) { await p.keyboard.press(k); await p.waitForTimeout(260); } };
await p.goto("http://localhost:5173/dinogame/?demarrer&dino=Velociraptor&niveau=10&carte=ambreluneSud&x=13&y=62&pieces=100"); await p.waitForTimeout(3500);
await p.screenshot({ path: ".shots/test/boutique-dehors.png" });
// Walk up to the door and in.
await p.keyboard.down("ArrowUp"); await p.waitForTimeout(1400); await p.keyboard.up("ArrowUp"); await p.waitForTimeout(1500);
console.log("CARTE:", await p.evaluate(() => window.__game.scene.getScene("World").mapId));
// Up to the counter, talk.
await p.keyboard.down("ArrowUp"); await p.waitForTimeout(900); await p.keyboard.up("ArrowUp"); await p.waitForTimeout(300);
await press("Space"); await p.waitForTimeout(600); await press("Space", 2); await p.waitForTimeout(500);
console.log("BOUTIQUE OUVERTE:", await p.isVisible(".scr.shop"));
await p.click('[data-it="collier"]'); await p.click('[data-q="1"]'); await p.click('[data-q="1"]');
await p.screenshot({ path: ".shots/test/boutique.png" });
await p.click("[data-deal]"); await p.waitForTimeout(300);
console.log("ACHAT:", await p.locator(".toast").last().textContent());
await p.click('[data-tab="sell"]'); await p.click('[data-it="baie"]'); await p.click("[data-deal]"); await p.waitForTimeout(300);
console.log("VENTE:", await p.locator(".toast").last().textContent());
console.log("ARGENT AFFICHÉ:", await p.textContent(".money"));
console.log("ERREURS:", errors);
await b.close();
