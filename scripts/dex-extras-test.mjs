// Cries (generated, not silent), tapping the companion, a shiny wild dino in battle,
// the Dinodex habitats, and Professor Roc's reward at 10 species caught.
import { chromium } from "playwright-core";
const b = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true, args: ["--autoplay-policy=no-user-gesture-required"] });
const p = await b.newPage({ viewport: { width: 390, height: 844 } });
p.setDefaultTimeout(6000);
const errors = []; p.on("pageerror", (e) => errors.push(e.message));
await p.goto("http://localhost:5173/dinogame/?demarrer&dino=Velociraptor&niveau=12&carte=ambreluneSud&x=22&y=36"); await p.waitForTimeout(3500);

// 1. Every cry voice renders to real sound.
const cries = await p.evaluate(async () => {
  const { scheduleCry } = await import("/dinogame/src/audio/cry.js");
  const { DINOS } = await import("/dinogame/src/data/dinos.js");
  const voices = [...new Set(DINOS.map((d) => d.cry))];
  const out = {};
  for (const v of voices) {
    const i = DINOS.findIndex((d) => d.cry === v);
    const off = new OfflineAudioContext(1, 44100 * 3, 44100);
    scheduleCry(off, off.destination, { head: i, teeth: i, frontLegs: i, backLegs: i, back: i, tail: i, color: i });
    const data = (await off.startRendering()).getChannelData(0);
    let sum = 0; for (let k = 0; k < data.length; k++) sum += data[k] * data[k];
    out[v] = Math.sqrt(sum / data.length).toFixed(3);
  }
  return out;
});
console.log("CRIS (niveau sonore moyen par voix):", cries);

// 2. Tap the companion: it hops.
await p.mouse.click(10, 10); // unlock audio
await p.waitForTimeout(800);
const hop = await p.evaluate(async () => {
  const w = window.__game.scene.getScene("World"), f = w.follower;
  const cam = w.cameras.main, c = document.querySelector("canvas").getBoundingClientRect(), k = c.width / cam.width;
  return { x: c.x + (f.x - cam.worldView.x) * cam.zoom * k, y: c.y + (f.y - f.displayHeight * 0.4 - cam.worldView.y) * cam.zoom * k, y0: f.y };
});
await p.mouse.click(hop.x, hop.y); await p.waitForTimeout(150);
console.log("COMPAGNON TOUCHÉ, IL SAUTE:", await p.evaluate((y0) => window.__game.scene.getScene("World").follower.y < y0 - 3, hop.y0));

// 3. A shiny wild dino in battle.
await p.evaluate(async () => {
  const { rollWild } = await import("/dinogame/nouveau/src/battle/wild.js");
  const { makeShiny } = await import("/dinogame/nouveau/src/battle/shiny.js");
  window.__game.scene.getScene("World").launchWild(makeShiny(rollWild([["Maiasaura", 1, [3, 3]]])), "plaines");
});
const msgs = [];
for (let i = 0; i < 16; i++) { const m = ((await p.textContent(".bmsg").catch(() => "")) || "").trim(); if (m && msgs.at(-1) !== m) msgs.push(m); if (i === 6) await p.screenshot({ path: ".shots/test/shiny-combat.png" }); await p.waitForTimeout(400); }
console.log("COMBAT CHROMATIQUE:", msgs.find((m) => m.includes("chromatique")) || "pas de message", "| carte:", await p.textContent(".card.foe .nm"));
await p.evaluate(() => window.__game.scene.getScene("Battle").leave("run")); await p.waitForTimeout(1500);

// 4. Dinodex habitats, and the shiny noted in the Maiasaura entry.
await p.click(".dexbtn"); await p.waitForTimeout(400);
await p.click('[data-f="habitats"]'); await p.waitForTimeout(300);
console.log("HABITATS:", (await p.locator(".hab-top").allTextContents()).join(" | "));
await p.screenshot({ path: ".shots/test/dex-habitats.png" });
await p.locator(".dcard", { hasText: "Maiasaura" }).first().click(); await p.waitForTimeout(300);
console.log("FICHE MAIASAURA:", (await p.textContent(".dex-entry .sum-sec")).replace(/\s+/g, " ").trim());
await p.click("[data-cry]");
await p.keyboard.press("Escape"); await p.keyboard.press("Escape"); await p.waitForTimeout(300);

// 5. Professor Roc: 10 species caught → a reward.
const texts = await p.evaluate(async () => {
  const state = window.__state;
  const { DINOS } = await import("/dinogame/src/data/dinos.js");
  Object.assign(state.flags, { met_roc: true, starter: true, roc_after: true });
  state.dex = state.dex || { seen: {}, caught: {} };
  for (const d of DINOS.slice(0, 10)) { state.dex.seen[d.name] = { at: Date.now(), count: 1 }; state.dex.caught[d.name] = { at: Date.now() }; }
  const before = state.bag.collier || 0;
  const w = window.__game.scene.getScene("World");
  const said = [];
  const orig = w.scriptApi ? null : null;
  const obs = new MutationObserver(() => { const t = document.querySelector(".dialog")?.textContent; if (t && said.at(-1) !== t) said.push(t); });
  obs.observe(document.body, { childList: true, subtree: true, characterData: true });
  const run = w.runScript("roc");
  for (let i = 0; i < 14; i++) { await new Promise((r) => setTimeout(r, 350)); document.querySelector(".dialog")?.click(); }
  await run; obs.disconnect();
  return { said: said.filter((t) => /Dinodex|reçois|espèces/.test(t)), colliers: `${before} → ${state.bag.collier}`, flag: state.flags.rocDexReward };
});
console.log("PROF. ROC:", texts);
console.log("ERREURS:", errors);
await b.close();
