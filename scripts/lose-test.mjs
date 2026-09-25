// A level-1 Compsognathus against wild dinos: should lose and wake up at the Cabinet.
import { chromium } from "playwright-core";
const browser = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const page = await browser.newPage({ viewport: { width: 430, height: 900 }, deviceScaleFactor: 1 });
const errors = [];
page.on("pageerror", (e) => errors.push(e.message));
await page.goto("http://localhost:5173/dinogame/nouveau/?demarrer&dino=Compsognathus&niveau=1&rencontre&x=27&y=36");
await page.waitForTimeout(2500);
await page.keyboard.down("ArrowDown"); await page.waitForTimeout(80); await page.keyboard.up("ArrowDown");
for (let t = 0; t < 160; t++) {
  await page.waitForTimeout(500);
  const b = await page.$$(".bgrid button:not([disabled])");
  const labels = await page.$$eval(".bgrid button", (x) => x.map((y) => y.textContent));
  if (b.length && labels[0].includes("Attaque")) await b[0].click();
  else if (b.length) await b[0].click();
  if (t > 5 && !(await page.$(".bhud"))) break;
}
await page.waitForTimeout(2500);
console.log("LIEU:", await page.evaluate(() => document.querySelector(".banner span")?.textContent));
await page.screenshot({ path: ".shots/test/defaite.png" });
console.log("ERREURS:", errors);
await browser.close();
