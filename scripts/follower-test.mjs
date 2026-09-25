// Walks with a follower in each direction and screenshots its views.
import { chromium } from "playwright-core";
const browser = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const page = await browser.newPage({ viewport: { width: 430, height: 900 }, deviceScaleFactor: 2 });
const errors = [];
page.on("pageerror", (e) => errors.push(e.message));
await page.goto("http://localhost:5173/dinogame/nouveau/?demarrer&dino=" + (process.argv[2] || "Triceratops") + "&x=22&y=52");
await page.waitForTimeout(3000);
const walk = async (k, n) => { for (let i = 0; i < n; i++) { await page.keyboard.down(k); await page.waitForTimeout(70); await page.keyboard.up(k); await page.waitForTimeout(240); } };
await walk("ArrowDown", 3); await page.waitForTimeout(400); await page.screenshot({ path: ".shots/test/10-suit-bas.png" });
await walk("ArrowUp", 4); await page.waitForTimeout(400); await page.screenshot({ path: ".shots/test/11-suit-haut.png" });
await walk("ArrowLeft", 3); await page.waitForTimeout(400); await page.screenshot({ path: ".shots/test/12-suit-gauche.png" });
console.log("ERREURS:", errors);
await browser.close();
