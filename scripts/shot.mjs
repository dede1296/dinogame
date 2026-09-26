// Screenshot helper: node scripts/shot.mjs "<query>" [name] [w] [h] [waitMs]
import { chromium } from "playwright-core";
const [q, name = "shot", w = 430, h = 900, wait = 3500] = process.argv.slice(2);
const browser = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const page = await browser.newPage({ viewport: { width: +w, height: +h }, deviceScaleFactor: 1 });
const errors = [];
page.on("pageerror", (e) => errors.push(e.message));
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()); });
await page.goto(`http://localhost:5173/dinogame/?${q}`);
await page.waitForTimeout(+wait);
const file = `.shots/test/${name}-${Date.now()}.png`;
await page.screenshot({ path: file });
console.log(file);
console.log("ERREURS:", errors);
await browser.close();
