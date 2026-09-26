// Rest at the Plains campfire, then lose a battle: Chloé must wake up at the fire, not the Cabinet.
import { chromium } from "playwright-core";
const browser = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const page = await browser.newPage({ viewport: { width: 430, height: 900 }, deviceScaleFactor: 1 });
// The debug slot card only shows on the title screen when debug mode is on.
await page.addInitScript(() => localStorage.setItem("dino-debug", "1"));
const errors = [];
page.on("pageerror", (e) => errors.push(e.message));
const tap = async (k) => { await page.keyboard.down(k); await page.waitForTimeout(80); await page.keyboard.up(k); await page.waitForTimeout(350); };
await page.goto("http://localhost:5173/dinogame/?demarrer&dino=Compsognathus&niveau=1&x=16&y=26");
await page.waitForTimeout(2500);
await tap("ArrowUp");
await page.screenshot({ path: ".shots/test/feu-" + Date.now() + ".png" });
await tap(" ");
await page.waitForTimeout(1200); await tap(" ");
await page.waitForTimeout(500);
const choices = await page.$$eval(".choices button, .choice button, button", (x) => x.map((y) => y.textContent).filter((t) => t.includes("reposer")));
console.log("CHOIX:", choices);
await page.click("text=Se reposer et sauvegarder");
for (let i = 0; i < 6; i++) { await page.waitForTimeout(900); await tap(" "); }
console.log("RESPAWN:", await page.evaluate(() => localStorage.getItem("dino-hybride-v2-debug") && JSON.parse(localStorage.getItem("dino-hybride-v2-debug")).respawn));
// Now force an encounter in the grass below and lose.
await page.goto("http://localhost:5173/dinogame/?rencontre&x=16&y=28");
await page.waitForTimeout(800);
await page.click("#btn-load"); await page.click("[data-slot=\"debug\"]");
await page.waitForTimeout(2500);
await tap("ArrowLeft");
for (let t = 0; t < 160; t++) {
  await page.waitForTimeout(500);
  const b = await page.$$(".bgrid button:not([disabled])");
  if (b.length) await b[0].click();
  if (t > 5 && !(await page.$(".bhud"))) break;
}
await page.waitForTimeout(2500);
const s = await page.evaluate(() => JSON.parse(localStorage.getItem("dino-hybride-v2-debug")));
console.log("APRES DEFAITE:", s.map, s.x, s.y, "PV:", s.party.map((d) => d.hp));
console.log("TOAST:", await page.evaluate(() => document.body.innerText.match(/Tu te réveilles[^\n]*/)?.[0]));
await page.screenshot({ path: ".shots/test/reveil-" + Date.now() + ".png" });
console.log("ERREURS:", errors);
await browser.close();
