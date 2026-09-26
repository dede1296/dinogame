// Turns the nano-banana illustrations (JPG, flat slate background) into game assets:
// icons get a transparent background and are shrunk to display size; the letter paper is cropped.
// Usage: node scripts/process-art.mjs
import sharp from "sharp";
import fs from "node:fs";

const SRC = "generated_imgs";
const OUT = "nouveau/assets/ui";
const find = (id) => `${SRC}/${fs.readdirSync(SRC).find((n) => n.includes(id))}`;

const ICONS = {
  fougere: "myqpi9", baie: "tuci35", collier: "qpujbh", ambre: "vq0i7y", fossile: "1fsk6b",
  journal: "zcx4vk", piece: "oiupys", sceau_plaines: "bjqxil", sac: "z8g1q8", equipe: "8ftl0r",
};
const ICON_SIZE = 160;
// Background removal by flood fill from the image border, so dark outlines inside
// the object are kept. Pixels closer than KEY_DIST to the background colour are
// background; edge pixels fade out over FEATHER.
const KEY_DIST = 24;
const FEATHER = 22;

async function keyOut(file, out) {
  const { data, info } = await sharp(file).resize(ICON_SIZE * 2, ICON_SIZE * 2).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const { width: w, height: h } = info;
  const bg = [data[0], data[1], data[2]]; // top-left corner = background
  const dist = (i) => Math.hypot(data[i * 4] - bg[0], data[i * 4 + 1] - bg[1], data[i * 4 + 2] - bg[2]);
  const isBg = new Uint8Array(w * h);
  const stack = [];
  for (let x = 0; x < w; x++) stack.push(x, (h - 1) * w + x);
  for (let y = 0; y < h; y++) stack.push(y * w, y * w + w - 1);
  while (stack.length) {
    const i = stack.pop();
    if (isBg[i] || dist(i) > KEY_DIST) continue;
    isBg[i] = 1;
    const x = i % w, y = (i / w) | 0;
    if (x > 0) stack.push(i - 1);
    if (x < w - 1) stack.push(i + 1);
    if (y > 0) stack.push(i - w);
    if (y < h - 1) stack.push(i + w);
  }
  for (let i = 0; i < w * h; i++) {
    if (isBg[i]) { data[i * 4 + 3] = 0; continue; }
    const x = i % w, y = (i / w) | 0;
    const nearBg = (x > 0 && isBg[i - 1]) || (x < w - 1 && isBg[i + 1]) || (y > 0 && isBg[i - w]) || (y < h - 1 && isBg[i + w]);
    if (nearBg) data[i * 4 + 3] = Math.round(Math.min(1, Math.max(0.35, (dist(i) - KEY_DIST) / FEATHER)) * 255);
  }
  await sharp(data, { raw: info }).resize(ICON_SIZE, ICON_SIZE).webp({ quality: 88, alphaQuality: 90 }).toFile(out);
}

fs.mkdirSync(OUT, { recursive: true });
for (const [name, id] of Object.entries(ICONS)) await keyOut(find(id), `${OUT}/${name}.webp`);

// Letter paper: trim the table edge around the sheet.
const paper = find("nslnem");
const m = await sharp(paper).metadata();
const cx = Math.round(m.width * 0.035), cy = Math.round(m.height * 0.03);
await sharp(paper).extract({ left: cx, top: cy, width: m.width - 2 * cx, height: m.height - 2 * cy }).resize({ width: 720 }).webp({ quality: 80 }).toFile(`${OUT}/papier.webp`);
console.log(fs.readdirSync(OUT).map((n) => `${n} ${Math.round(fs.statSync(`${OUT}/${n}`).size / 1024)} Ko`).join("\n"));

// App icons for the installable Ambrelune (PWA). The emblem sits inside the central
// safe zone, so the same picture serves as the "maskable" icon Android crops.
const APP_ICON = find("q1fu47");
const ICON_DIR = "public/nouveau/icons";
fs.mkdirSync(ICON_DIR, { recursive: true });
for (const [name, size] of [["icon-192.png", 192], ["icon-512.png", 512], ["apple-touch-icon.png", 180], ["favicon-48.png", 48]]) {
  await sharp(APP_ICON).resize(size, size).png({ compressionLevel: 9, palette: true, quality: 90, dither: 1 }).toFile(`${ICON_DIR}/${name}`);
}
console.log(fs.readdirSync(ICON_DIR).map((n) => `${n} ${Math.round(fs.statSync(`${ICON_DIR}/${n}`).size / 1024)} Ko`).join("\n"));
