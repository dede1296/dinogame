// Installable Ambrelune (PWA), on a production build served locally:
// install criteria, service worker, offline play, autosave on close, update after a deploy.
// Usage: node scripts/pwa-test.mjs   (builds into a temp folder and serves it on port 4199)
import { chromium } from "playwright-core";
import { execSync, spawn } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const OUT = path.join(os.tmpdir(), "ambrelune-pwa-test");
const PORT = 4199;
const URL = `http://localhost:${PORT}/dinogame/`;
const build = () => execSync(`npx vite build --outDir "${OUT}" --emptyOutDir`, { stdio: "ignore" });
const buildId = () => fs.readFileSync(path.join(OUT, "sw.js"), "utf8").match(/BUILD = "([^"]+)"/)[1];
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

build();
const server = spawn(`npx vite preview --outDir "${OUT}" --port ${PORT} --strictPort`, { shell: true, stdio: "ignore" });
await sleep(2500);
const browser = await chromium.launch({ executablePath: "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", headless: true });
const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });
const errors = [];
const watch = (p) => p.on("pageerror", (e) => errors.push(e.message));
const version = "nouveau/src/version.js";
const original = fs.readFileSync(version, "utf8");

try {
  // 1. Install criteria (Chromium's own check) and service worker control.
  let page = await ctx.newPage(); watch(page);
  await page.goto(URL); await page.waitForTimeout(2500);
  await page.reload(); await page.waitForTimeout(1500);
  const cdp = await ctx.newCDPSession(page);
  const { installabilityErrors: installErrors } = await cdp.send("Page.getInstallabilityErrors");
  const { url: manifestUrl, errors: manifestErrors } = await cdp.send("Page.getAppManifest");
  const manifest = JSON.parse(await (await page.request.get(manifestUrl)).text());
  console.log("MANIFESTE:", manifestUrl.replace(`http://localhost:${PORT}`, ""), manifest.name, manifest.display, manifest.start_url, "erreurs:", manifestErrors.length);
  console.log("INSTALLABLE:", installErrors.length === 0 ? "oui" : installErrors.map((e) => e.errorId));
  console.log("SW CONTRÔLE LA PAGE:", await page.evaluate(() => navigator.serviceWorker.controller?.scriptURL.replace(location.origin, "")));
  console.log("CACHES:", await page.evaluate(async () => (await caches.keys()).join(", ")));

  // 2. Play, then close the app: the autosave keeps the position.
  await page.click("#btn-new"); await page.click('[data-slot="1"]'); await page.waitForTimeout(4000);
  for (let i = 0; i < 12; i++) { await page.keyboard.press("Space"); await page.waitForTimeout(250); } // skip the intro
  await page.keyboard.down("ArrowUp"); await page.waitForTimeout(900); await page.keyboard.up("ArrowUp"); await page.waitForTimeout(400);
  const before = await page.evaluate(() => { const w = window.__game.scene.getScene("World"); return `${w.mapId} ${w.px},${w.py}`; });
  await page.close({ runBeforeUnload: true });
  page = await ctx.newPage(); watch(page);
  await page.goto(URL); await page.waitForTimeout(1500);
  await page.click("#btn-continue"); await page.waitForTimeout(3500);
  const after = await page.evaluate(() => { const w = window.__game.scene.getScene("World"); return `${w.mapId} ${w.px},${w.py}`; });
  console.log("SAUVEGARDE AUTO À LA FERMETURE:", before === after ? `ok (${after})` : `ÉCHEC avant ${before} après ${after}`);

  // 3. Offline: the app still starts and a game loads.
  await ctx.setOffline(true);
  await page.goto(URL).catch(() => {}); await page.waitForTimeout(1500);
  const offlineTitle = await page.isVisible("#btn-continue");
  await page.click("#btn-continue"); await page.waitForTimeout(3500);
  console.log("HORS LIGNE:", offlineTitle && await page.evaluate(() => !!window.__game?.scene.getScene("World")?.map) ? "ok (accueil + partie)" : "ÉCHEC");
  await ctx.setOffline(false);

  // 4. Update: a new deploy replaces the old version and its cache.
  await page.goto(URL); await page.waitForTimeout(1000);
  const oldBuild = buildId();
  fs.writeFileSync(version, original.replace(/VERSION = "([^"]+)"/, (m, v) => `VERSION = "${v}-test"`));
  build();
  fs.writeFileSync(version, original);
  const newBuild = buildId();
  const reloaded = page.waitForEvent("load", { timeout: 15000 }).then(() => true).catch(() => false);
  await page.evaluate(async () => (await navigator.serviceWorker.getRegistration()).update());
  const didReload = await reloaded; await page.waitForTimeout(1500);
  const caches2 = await page.evaluate(async () => (await caches.keys()).join(", "));
  console.log("MISE À JOUR:", `${oldBuild} → ${newBuild}`, "| rechargée sur l'accueil:", didReload, "| caches:", caches2, caches2.includes(oldBuild) ? "(ancien cache encore là !)" : "(ancien cache supprimé)");
  // 5. The classic game still works at /ancien/, and the old address redirects to Ambrelune.
  await page.goto(URL.replace("/dinogame/", "/dinogame/ancien/")); await page.waitForTimeout(2500);
  console.log("ANCIEN JEU (/ancien/):", await page.evaluate(() => document.querySelector("#root")?.children.length > 0 ? `ok (${document.title})` : "ÉCHEC"));
  await page.goto(`${URL}nouveau/`); await page.waitForURL(URL, { timeout: 8000 }).catch(() => {}); await page.waitForTimeout(1500);
  console.log("ANCIENNE ADRESSE /nouveau/ →", page.url().replace(`http://localhost:${PORT}`, ""), await page.isVisible("#menu") ? "(accueil Ambrelune)" : "(ÉCHEC)");
  console.log("ERREURS:", errors);
} finally {
  fs.writeFileSync(version, original);
  await browser.close();
  server.kill();
  if (process.platform === "win32") execSync(`for /f "tokens=5" %a in ('netstat -ano ^| findstr :${PORT} ^| findstr LISTENING') do taskkill /F /PID %a`, { stdio: "ignore", shell: "cmd.exe" });
}
