// Riding a dino: button only with a big enough dino, getting on, speed, the 4 directions,
// getting off, automatic dismount at a door, and a hybrid mount.
import { chromium } from "playwright-core";
const b = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const p = await b.newPage({ viewport: { width: 390, height: 844 } });
p.setDefaultTimeout(6000);
const errors = []; p.on("pageerror", (e) => errors.push(e.message));
const URL = "http://localhost:5173/dinogame/?demarrer&niveau=12&carte=ambreluneSud";
const world = () => p.evaluate(() => { const w = window.__game.scene.getScene("World"); return { map: w.mapId, x: w.px, y: w.py, riding: w.riding }; });
const walk = async (key, ms) => { await p.keyboard.down(key); await p.waitForTimeout(ms); await p.keyboard.up(key); await p.waitForTimeout(500); };
const clear = () => p.evaluate(() => { const w = window.__game.scene.getScene("World"); w.map.zones.forEach((z) => (z.encounters = null)); w.roamers.forEach((r) => w.removeRoamer(r)); });

// A Velociraptor is too small to carry Chloé.
await p.goto(`${URL}&dino=Velociraptor&x=22&y=36`); await p.waitForTimeout(3500);
console.log("VELOCIRAPTOR, bouton Monter visible :", await p.isVisible(".ridebtn"));

// A Triceratops can.
await p.goto(`${URL}&dino=Triceratops&x=22&y=36`); await p.waitForTimeout(3500); await clear();
console.log("TRICÉRATOPS, bouton Monter visible :", await p.isVisible(".ridebtn"));
let a = await world(); await walk("ArrowUp", 1500); const onFoot = a.y - (await world()).y;
await p.click(".ridebtn"); await p.waitForTimeout(900);
console.log("MONTÉ :", (await world()).riding);
for (const [k, n] of [["ArrowDown", "bas"], ["ArrowLeft", "gauche"], ["ArrowRight", "droite"], ["ArrowUp", "haut"]]) {
  await p.keyboard.down(k); await p.waitForTimeout(90); await p.keyboard.up(k); await p.waitForTimeout(450);
  await p.screenshot({ path: `.shots/test/monture-${n}.png`, clip: { x: 95, y: 250, width: 200, height: 240 } });
}
a = await world(); await walk("ArrowUp", 1500); const riding = a.y - (await world()).y;
console.log("CASES EN 1,5 s : à pied", onFoot, "| à dos de dino", riding);
await p.click(".ridebtn"); await p.waitForTimeout(600);
console.log("DESCENDU :", !(await world()).riding, "| dino derrière :", await p.evaluate(() => { const w = window.__game.scene.getScene("World"); return w.fx !== w.px || w.fy !== w.py; }));

// Riding into the shop's door: off the dino before going in.
await p.goto(`${URL}&dino=Triceratops&x=13&y=62`); await p.waitForTimeout(3500); await clear();
await p.click(".ridebtn"); await p.waitForTimeout(900);
await walk("ArrowUp", 900); await p.waitForTimeout(1200);
console.log("PORTE DE LA BOUTIQUE :", await world(), "| bouton visible dedans :", await p.isVisible(".ridebtn"));

// A hybrid mount (Velociraptor with Iguanodon legs) — drawn with Chloé on its back.
await p.goto(`${URL}&dino=Velociraptor&x=22&y=36`); await p.waitForTimeout(3500); await clear();
await p.evaluate(async () => {
  const w = window.__game.scene.getScene("World");
  const v = w.followerDino.build.head, ig = (await import("/dinogame/src/data/dinos.js")).DINOS.findIndex((d) => d.name === "Iguanodon");
  const hybrid = { build: { ...w.followerDino.build, backLegs: ig, back: ig } };
  w.follower.destroy(); w.follower = null;
  await w.createFollower(hybrid);
  w.follower.setPosition(w.px * 48 + 24, (w.py + 1) * 48 - 4); w.fx = w.px; w.fy = w.py;
  w.riding = true; w.player.setCrop(0, 0, 48, 45); w.faceFollower(1, 0);
});
await p.waitForTimeout(400);
await p.screenshot({ path: ".shots/test/monture-hybride.png", clip: { x: 95, y: 250, width: 200, height: 240 } });
console.log("ERREURS:", errors);
await b.close();
