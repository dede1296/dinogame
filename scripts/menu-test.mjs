// Running with B held, in-game save, and the title screen settings (volume saved).
import { chromium } from "playwright-core";
const b = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const p = await b.newPage({ viewport: { width: 430, height: 900 } });
const errors = []; p.on("pageerror", (e) => errors.push(e.message)); p.on("dialog", (d) => d.dismiss());
await p.goto("http://localhost:5173/dinogame/?demarrer&dino=Velociraptor&niveau=10&carte=ambreluneSud&x=22&y=36"); await p.waitForTimeout(3500);
await p.evaluate(() => { const w = window.__game.scene.getScene("World"); w.map.zones.forEach((z) => (z.encounters = null)); w.roamers.forEach((r) => w.removeRoamer(r)); });
const walk = async (run) => {
  const y0 = await p.evaluate(() => window.__game.scene.getScene("World").py);
  if (run) await p.keyboard.down("Shift");
  await p.keyboard.down("ArrowUp"); await p.waitForTimeout(1500); await p.keyboard.up("ArrowUp");
  if (run) await p.keyboard.up("Shift");
  await p.waitForTimeout(400);
  return y0 - await p.evaluate(() => window.__game.scene.getScene("World").py);
};
console.log("CASES EN MARCHANT:", await walk(false), "EN COURANT:", await walk(true));
// Team screen: two dinos, a hurt one; summary, swap (the new lead follows Chloé), fern from the bag.
await p.evaluate(async () => {
  const state = window.__state;
  const { createDino } = await import("/dinogame/nouveau/src/battle/dino.js");
  const i = 47; // any species
  state.party = [...state.party, createDino({ head: i, teeth: i, frontLegs: i, backLegs: i, back: i, tail: i, color: i }, 8, "Second")];
  state.party[0].hp = 5;
  state.bag = { ...state.bag, fougere: 2 };
});
await p.click(".partybtn"); await p.waitForTimeout(400);
await p.screenshot({ path: ".shots/test/equipe.png" });
await p.click('.pcard[data-i="0"]'); await p.waitForTimeout(200);
await p.click('.scr-sheet [data-i="0"]'); await p.waitForTimeout(400);
await p.screenshot({ path: ".shots/test/resume.png", fullPage: true });
await p.keyboard.press("Escape"); await p.waitForTimeout(300);
await p.click('.pcard[data-i="1"]'); await p.click('.scr-sheet [data-i="1"]'); await p.click('.pcard[data-i="0"]');
const order = await p.evaluate(async () => window.__state.party.map((d) => d.nickname));
await p.keyboard.press("Escape"); await p.waitForTimeout(1500);
console.log("ORDRE APRES ECHANGE:", order, "COMPAGNON:", await p.evaluate(() => window.__game.scene.getScene("World").follower?.texture.key.includes("-47-") ?? "aucun"));
await p.click(".bagbtn"); await p.waitForTimeout(300);
await p.click('[data-use="fougere"]'); await p.waitForTimeout(200);
await p.screenshot({ path: ".shots/test/sac.png" });
await p.click('.scr-sheet [data-i="1"]'); await p.waitForTimeout(300);
console.log("FOUGERE:", await p.textContent(".toast"));
await p.keyboard.press("Escape"); await p.waitForTimeout(300);
await p.click(".menubtn"); await p.waitForTimeout(300);
await p.screenshot({ path: ".shots/test/menu.png" });
await p.click('[data-m="save"]'); await p.waitForTimeout(300);
console.log("SAUVEGARDE:", await p.locator(".toast").last().textContent(), "ACCUEIL DANS LE MENU:", await p.isVisible('[data-m="home"]'));
await p.keyboard.press("Escape");
// Title screen: settings (volume saved on the device).
await p.goto("http://localhost:5173/dinogame/"); await p.waitForTimeout(800);
await p.screenshot({ path: ".shots/test/accueil.png" });
await p.click("#btn-settings");
await p.$eval("#vol", (el) => { el.value = 30; el.dispatchEvent(new Event("input", { bubbles: true })); });
await p.screenshot({ path: ".shots/test/accueil-reglages.png" });
console.log("VOLUME:", await p.evaluate(() => localStorage.getItem("dino-volume")));
await p.setViewportSize({ width: 1280, height: 720 });
await p.click(".back"); await p.waitForTimeout(300);
await p.screenshot({ path: ".shots/test/accueil-paysage.png" });
console.log("ERREURS:", errors); await b.close();
