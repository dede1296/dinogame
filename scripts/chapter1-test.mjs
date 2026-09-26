// Plays the second half of chapter 1 end to end: boulder, cave, grunts, forced hybrid,
// Alpha, ladder, trunk + Maïa, then the hybridizer. Usage: node scripts/chapter1-test.mjs [niveau]
import { chromium } from "playwright-core";
const LEVEL = process.argv[2] || 14;
const browser = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const page = await browser.newPage({ viewport: { width: 430, height: 900 }, deviceScaleFactor: 1 });
await page.addInitScript(() => { window.__noAutosave = true; }); // the test edits the save itself
// The debug slot card only shows on the title screen when debug mode is on.
await page.addInitScript(() => localStorage.setItem("dino-debug", "1"));
const errors = [];
page.on("pageerror", (e) => errors.push(e.message));
const URL = "http://localhost:5173/dinogame/nouveau/?";
const tap = async (k) => { await page.keyboard.down(k); await page.waitForTimeout(60); await page.keyboard.up(k); await page.waitForTimeout(420); };
const st = () => page.evaluate(() => JSON.parse(localStorage.getItem("dino-hybride-v2-debug")));
const liveFlags = () => page.evaluate(() => { try { return JSON.parse(localStorage.getItem("dino-hybride-v2-debug")).flags; } catch { return {}; } });
// Like resting at a campfire: full HP (read back by the game on load via normalizeDino/heal).
async function rest() {
  await page.evaluate(() => { const s = JSON.parse(localStorage.getItem("dino-hybride-v2-debug")); s.party.forEach((d) => { d.hp = 999; d.status = null; }); s.healOnLoad = true; localStorage.setItem("dino-hybride-v2-debug", JSON.stringify(s)); });
}
async function go(q) {
  await rest();
  await page.goto(URL + q);
  await page.waitForTimeout(700);
  if (await page.$("#btn-load:not([disabled])")) { await page.click("#btn-load"); await page.click("[data-slot=\"debug\"]"); }
  await page.waitForTimeout(2200);
}
// Advances dialogues, picks the first choice / first battle button, until done() is true.
async function drive(done, max = 400) {
  for (let i = 0; i < max; i++) {
    if (await done()) return true;
    const btns = await page.$$(".bgrid button:not([disabled])");
    if (btns.length) {
      // In the move list, pick the strongest attack; elsewhere the first button.
      const labels = await Promise.all(btns.map((b) => b.textContent()));
      const power = labels.map((l) => +(l.match(/Puiss. (d+)/)?.[1] || 0));
      const best = power.some((p) => p > 0) ? power.indexOf(Math.max(...power)) : 0;
      await btns[best].click(); await page.waitForTimeout(250); continue;
    }
    const ch = await page.$(".choices button");
    if (ch) { console.log("  choix:", await ch.textContent()); await ch.click(); await page.waitForTimeout(250); continue; }
    if (await page.$(".dialog")) { await page.keyboard.press(" "); await page.waitForTimeout(150); continue; }
    if (await page.$(".bmsg")) { await page.click(".bmsg").catch(() => {}); }
    await page.waitForTimeout(250);
  }
  return false;
}
const shot = (n) => page.screenshot({ path: `.shots/test/c1-${n}-${Date.now()}.png` });
const step = async (name, fn) => { const ok = await fn(); console.log((ok ? "OK   " : "ÉCHEC ") + name); if (!ok) await shot(name.replace(/\W+/g, "_")); };

await page.goto(URL + `demarrer&dino=Triceratops&niveau=${LEVEL}&x=36&y=23`);
await page.waitForTimeout(2800);
await step("rocher brisé par Charge", async () => { await tap("ArrowUp"); await tap(" "); return drive(async () => (await liveFlags()).rocher_brise && !(await page.$(".dialog"))); });
await step("entrée dans la grotte", async () => { await tap("ArrowUp"); await page.waitForTimeout(1500); return (await st()).map === "grotte1"; });
await shot("grotte-entree");
await step("sbire Kraz battu", async () => { await go("carte=grotte1&x=8&y=10"); await tap("ArrowUp"); return drive(async () => (await liveFlags()).sbire1_battu && !(await page.$(".dialog"))); });
await step("descente au niveau 2", async () => { await go("carte=grotte1&x=5&y=4"); await tap("ArrowUp"); await page.waitForTimeout(1500); return (await st()).map === "grotte2"; });
await step("sbire Vesna battue", async () => { await go("carte=grotte2&x=8&y=5"); await tap("ArrowRight"); return drive(async () => (await liveFlags()).sbire2_battu && !(await page.$(".dialog"))); });
await step("hybride forcé apaisé", async () => { await go("carte=grotte2&x=20&y=6"); await tap("ArrowRight"); return drive(async () => (await liveFlags()).hybride_battu && !(await page.$(".dialog"))); });
console.log("  équipe:", (await st()).party.map((d) => `${d.nickname} (${d.speciesName}) niv.${d.level}`).join(", "));
await step("Tricératops Alpha vaincu", async () => { await go("carte=grotte2&x=22&y=17"); await tap("ArrowLeft"); await tap("ArrowLeft"); return drive(async () => (await liveFlags()).alpha_battu && !(await page.$(".dialog"))); });
await shot("alpha-apres");
const s1 = await st();
console.log("  sceau:", s1.bag.sceau_plaines, "journal:", s1.journal, "pièces:", s1.money);
await step("échelle vers le crâne", async () => { await go("carte=grotte2&x=14&y=17"); await tap("ArrowUp"); await tap(" "); await drive(async () => (await st()).map === "ambreluneSud", 40); await page.waitForTimeout(1500); const s = await st(); return s.map === "ambreluneSud" && s.x === 26 && s.y === 17; });
await step("tronc tranché + Maïa battue", async () => { await go("x=22&y=1"); await tap("ArrowUp"); await tap(" "); return drive(async () => (await liveFlags()).maia_battue && !(await page.$(".dialog"))); });
await step("route de la forêt", async () => {
  await go("x=22&y=1"); await tap("ArrowUp");
  let seen = false;
  for (let i = 0; i < 30; i++) {
    const txt = await page.$eval(".dialog", (d) => d.textContent).catch(() => null);
    if (txt?.includes("Chapitre 2")) seen = true;
    if (txt) await page.keyboard.press(" ");
    else if (seen) break;
    await page.waitForTimeout(250);
  }
  return seen;
});
await step("hybrideur : greffe de griffes de raptor", async () => {
  await page.evaluate(() => { const s = JSON.parse(localStorage.getItem("dino-hybride-v2-debug")); s.amber = ["Velociraptor"]; s.map = "cabinet"; localStorage.setItem("dino-hybride-v2-debug", JSON.stringify(s)); });
  await go("carte=cabinet&x=6&y=3");
  await tap("ArrowUp"); await tap(" ");
  // dino 1, ambre 1, partie : Pattes avant (3e), confirmer.
  const picks = [0, 0, 2, 0];
  let idle = 0;
  for (let i = 0; i < 200; i++) {
    const ch = await page.$$(".choices button");
    if (ch.length) { const k = picks.shift() ?? 0; console.log("  choix:", await ch[k].textContent()); await ch[k].click(); await page.waitForTimeout(250); continue; }
    if (await page.$(".dialog")) { await page.keyboard.press(" "); await page.waitForTimeout(150); idle = 0; continue; }
    if (!picks.length && ++idle > 8) break;
    await page.waitForTimeout(250);
  }
  const d = (await st()).party[0];
  console.log("  ", d.nickname, d.speciesName, d.moves.map((m) => m.id).join(","));
  return d.origin && d.speciesName.includes("hybride");
});
await shot("fin");
console.log("ERREURS:", errors);
await browser.close();
