// Spawns in tall grass with a dino, forces an encounter and screenshots it.
import { chromium } from "playwright-core";
const browser = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const page = await browser.newPage({ viewport: { width: 430, height: 900 }, deviceScaleFactor: 2 });
const errors = [];
page.on("pageerror", (e) => errors.push(e.message));
await page.goto("http://localhost:5173/dinogame/?demarrer&dino=Spinosaurus&rencontre&x=27&y=36");
await page.waitForTimeout(3000);
await page.screenshot({ path: ".shots/test/08-herbes.png" });
await page.keyboard.down("ArrowDown"); await page.waitForTimeout(80); await page.keyboard.up("ArrowDown");
await page.waitForTimeout(4500);
await page.screenshot({ path: ".shots/test/09-rencontre.png" });
console.log("TEXTE:", await page.evaluate(() => document.querySelector(".dialog .txt")?.textContent));
console.log("ERREURS:", errors);
await browser.close();
