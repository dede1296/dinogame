// Plays a full wild battle: attacks until the end, screenshots along the way.
import { chromium } from "playwright-core";
const browser = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const page = await browser.newPage({ viewport: { width: 430, height: 900 }, deviceScaleFactor: 2 });
const errors = [];
page.on("pageerror", (e) => errors.push(e.message));
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()); });
const dino = process.argv[2] || "Velociraptor", mode = process.argv[3] || "attack";
await page.goto(`http://localhost:5173/dinogame/?demarrer&dino=${dino}&rencontre&x=27&y=36`);
await page.waitForTimeout(2500);
await page.keyboard.down("ArrowDown"); await page.waitForTimeout(80); await page.keyboard.up("ArrowDown");
const msgs = [];
let shots = 0;
for (let t = 0; t < 120; t++) {
  await page.waitForTimeout(500);
  const txt = await page.evaluate(() => document.querySelector(".bmsg")?.textContent || "");
  if (txt && msgs[msgs.length - 1] !== txt) msgs.push(txt);
  const buttons = await page.$$(".bgrid button:not([disabled])");
  if (buttons.length) {
    if (shots < 2) { await page.screenshot({ path: `.shots/test/b${shots++}.png` }); }
    const labels = await page.$$eval(".bgrid button", (b) => b.map((x) => x.textContent));
    if (labels[0].includes("Attaque")) {
      if (mode === "catch" && msgs.length > 6) await buttons[1].click(); else await buttons[0].click();
    } else if (labels.some((l) => l.includes("Collier"))) {
      const i = labels.findIndex((l) => l.includes("Collier")); await (await page.$$(".bgrid button"))[i].click();
    } else {
      await buttons[Math.floor(Math.random() * buttons.length)].click();
    }
    if (t % 6 === 2) await page.screenshot({ path: `.shots/test/b-action-${t}.png` });
  }
  const inBattle = await page.evaluate(() => !!document.querySelector(".bhud"));
  if (!inBattle && t > 5) break;
}
await page.waitForTimeout(1200);
await page.screenshot({ path: ".shots/test/b-fin.png" });
console.log(msgs.join("\n"));
console.log("ERREURS:", errors);
await browser.close();
