// Turns the nano-banana sheets (JPG on flat magenta) into Godot assets (PNG with alpha).
//   - sprite sheets: cut into a grid, keyed, cropped to the union of all frames (so the
//     frames stay aligned on a common baseline), scaled, re-packed without gaps;
//   - prop sheets: keyed, split per grid cell and cropped to each prop;
//   - ground textures: made seamless (half-offset cross-fade) and scaled.
// Usage (from the repository root): node Godot/tools/process-art.mjs
// `sharp` comes from the repository's node_modules (already used by the Phaser tools).
import sharp from "sharp";
import fs from "node:fs";
import path from "node:path";

const SRC = "generated_imgs";
const OUT = "Godot/assets/art";
const find = (id) => {
  const name = fs.readdirSync(SRC).find((n) => n.includes(id));
  if (!name) throw new Error(`Image source introuvable : ${id}`);
  return path.join(SRC, name);
};

// Chroma key on magenta: "magentaness" = min(r, b) - g.
const KEY_LOW = 70;   // below: fully opaque
const KEY_HIGH = 150; // above: fully transparent
const INSET = 8;      // px trimmed from each grid cell (thin grid lines in some sheets)

/** Keys out the magenta background in place (RGBA raw buffer) and removes the pink spill. */
function keyMagenta(data) {
  for (let i = 0; i < data.length; i += 4) {
    const r = data[i], g = data[i + 1], b = data[i + 2];
    const m = Math.min(r, b) - g;
    let a = 1 - (m - KEY_LOW) / (KEY_HIGH - KEY_LOW);
    a = Math.max(0, Math.min(1, a));
    if (a === 0) { data[i + 3] = 0; continue; }
    if (a < 1) {
      // observed = a*fg + (1-a)*magenta  →  fg = (observed - (1-a)*magenta) / a
      data[i] = clamp((r - (1 - a) * 255) / a);
      data[i + 2] = clamp((b - (1 - a) * 255) / a);
      data[i + 1] = clamp(g / a > 255 ? 255 : g);
    } else if (m > 10) {
      // Opaque but tinted by the background: pull red/blue down to the pixel's other channel.
      const cap = g + 10;
      if (r > cap && b > cap) { data[i] = Math.max(cap, r - m); data[i + 2] = Math.max(cap, b - m); }
    }
    data[i + 3] = Math.round(a * 255);
  }
}
const clamp = (v) => Math.max(0, Math.min(255, Math.round(v)));

async function loadKeyed(file) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  keyMagenta(data);
  return { data, w: info.width, h: info.height };
}

/** Bounding box of pixels with alpha > threshold inside a rectangle, or null. */
function alphaBox(img, x0, y0, x1, y1, threshold = 24) {
  let minX = Infinity, minY = Infinity, maxX = -1, maxY = -1;
  for (let y = y0; y < y1; y++) {
    for (let x = x0; x < x1; x++) {
      if (img.data[(y * img.w + x) * 4 + 3] > threshold) {
        if (x < minX) minX = x; if (x > maxX) maxX = x;
        if (y < minY) minY = y; if (y > maxY) maxY = y;
      }
    }
  }
  return maxX < 0 ? null : { minX, minY, maxX, maxY };
}

const rawImage = (img) => sharp(img.data, { raw: { width: img.w, height: img.h, channels: 4 } });

/**
 * Sprite sheet → packed atlas. All frames share the union crop, so the character keeps
 * the same anchor in every frame. `frameHeight`: output height of one frame.
 */
async function sheet({ id, rows, cols, frameHeight, out, cell = null }) {
  if (cell) return sheetInCells({ id, rows, cols, frameHeight, out, cell });
  const img = await loadKeyed(find(id));
  const cw = img.w / cols, ch = img.h / rows;
  let u = null;
  for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) {
    const b = alphaBox(img, Math.round(c * cw + INSET), Math.round(r * ch + INSET), Math.round((c + 1) * cw - INSET), Math.round((r + 1) * ch - INSET));
    if (!b) continue;
    // Union in cell-local coordinates.
    const lb = { minX: b.minX - c * cw, minY: b.minY - r * ch, maxX: b.maxX - c * cw, maxY: b.maxY - r * ch };
    u = u ? { minX: Math.min(u.minX, lb.minX), minY: Math.min(u.minY, lb.minY), maxX: Math.max(u.maxX, lb.maxX), maxY: Math.max(u.maxY, lb.maxY) } : lb;
  }
  const pad = 4;
  const srcW = Math.ceil(u.maxX - u.minX) + 1, srcH = Math.ceil(u.maxY - u.minY) + 1;
  const scale = frameHeight / srcH;
  const fw = Math.round(srcW * scale) + pad * 2, fh = frameHeight + pad * 2;
  const composites = [];
  const base = rawImage(img);
  for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) {
    const left = Math.round(c * cw + u.minX), top = Math.round(r * ch + u.minY);
    const frame = await base.clone().extract({ left, top, width: srcW, height: srcH })
      .resize(fw - pad * 2, fh - pad * 2).png().toBuffer();
    composites.push({ input: frame, left: c * fw + pad, top: r * fh + pad });
  }
  await sharp({ create: { width: fw * cols, height: fh * rows, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite(composites).png({ compressionLevel: 9 }).toFile(out);
  return `${out} (${cols}x${rows} frames de ${fw}x${fh})`;
}

/**
 * Same as `sheet`, but every frame is placed in a cell of fixed size `cell` = [w, h],
 * centred and standing on the bottom edge. Used for extra views of a dino (front/back),
 * so they share the frame size and foot line of its side-view sheet.
 */
async function sheetInCells({ id, rows, cols, frameHeight, out, cell: [cw0, ch0] }) {
  const img = await loadKeyed(find(id));
  const cw = img.w / cols, ch = img.h / rows;
  const boxes = [];
  let unionH = 0;
  for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) {
    const b = alphaBox(img, Math.round(c * cw + INSET), Math.round(r * ch + INSET), Math.round((c + 1) * cw - INSET), Math.round((r + 1) * ch - INSET));
    boxes.push(b);
    if (b) unionH = Math.max(unionH, b.maxY - b.minY + 1);
  }
  const scale = frameHeight / unionH;
  const base = rawImage(img);
  const composites = [];
  for (const [i, b] of boxes.entries()) {
    if (!b) continue;
    const width = b.maxX - b.minX + 1, height = b.maxY - b.minY + 1;
    const w = Math.min(cw0, Math.round(width * scale)), h = Math.min(ch0, Math.round(height * scale));
    const frame = await base.clone().extract({ left: b.minX, top: b.minY, width, height }).resize(w, h).png().toBuffer();
    const col = i % cols, row = Math.floor(i / cols);
    composites.push({ input: frame, left: col * cw0 + Math.round((cw0 - w) / 2), top: row * ch0 + ch0 - 4 - h });
  }
  await sharp({ create: { width: cw0 * cols, height: ch0 * rows, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite(composites).png({ compressionLevel: 9 }).toFile(out);
  return `${out} (${cols}x${rows} frames de ${cw0}x${ch0})`;
}

/**
 * Finds the separate objects of a prop sheet: connected blobs of opaque pixels (on a
 * downsampled mask), merged when their boxes are closer than `gap` (pebbles next to a
 * boulder, petals of a flower clump). Returned in reading order: rows by gaps in y, then x.
 */
function findObjects(img, { step = 4, gap = 6, minArea = 60 } = {}) {
  const w = Math.floor(img.w / step), h = Math.floor(img.h / step);
  const label = new Int32Array(w * h).fill(-1);
  const boxes = [];
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const i = y * w + x;
    if (label[i] >= 0 || img.data[((y * step) * img.w + x * step) * 4 + 3] < 128) continue;
    const box = { minX: x, minY: y, maxX: x, maxY: y, area: 0 };
    const stack = [i];
    label[i] = boxes.length;
    while (stack.length) {
      const j = stack.pop(), jx = j % w, jy = (j / w) | 0;
      box.area++;
      box.minX = Math.min(box.minX, jx); box.maxX = Math.max(box.maxX, jx);
      box.minY = Math.min(box.minY, jy); box.maxY = Math.max(box.maxY, jy);
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const nx = jx + dx, ny = jy + dy;
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        const k = ny * w + nx;
        if (label[k] >= 0 || img.data[((ny * step) * img.w + nx * step) * 4 + 3] < 128) continue;
        label[k] = boxes.length;
        stack.push(k);
      }
    }
    boxes.push(box);
  }
  // Merge nearby blobs until stable.
  let groups = boxes.map((b) => ({ ...b }));
  for (let merged = true; merged;) {
    merged = false;
    outer: for (let a = 0; a < groups.length; a++) for (let b = a + 1; b < groups.length; b++) {
      const A = groups[a], B = groups[b];
      const dx = Math.max(0, Math.max(A.minX, B.minX) - Math.min(A.maxX, B.maxX));
      const dy = Math.max(0, Math.max(A.minY, B.minY) - Math.min(A.maxY, B.maxY));
      if (dx <= gap && dy <= gap) {
        groups[a] = { minX: Math.min(A.minX, B.minX), minY: Math.min(A.minY, B.minY), maxX: Math.max(A.maxX, B.maxX), maxY: Math.max(A.maxY, B.maxY), area: A.area + B.area };
        groups.splice(b, 1);
        merged = true;
        break outer;
      }
    }
  }
  groups = groups.filter((g) => g.area >= minArea);
  // Reading order: a new row starts when an object's centre is below the current row's bottom.
  groups.sort((a, b) => (a.minY + a.maxY) - (b.minY + b.maxY));
  const rows = [];
  for (const g of groups) {
    const cy = (g.minY + g.maxY) / 2;
    const row = rows.find((r) => cy >= r.top && cy <= r.bottom);
    if (row) { row.items.push(g); row.top = Math.min(row.top, g.minY); row.bottom = Math.max(row.bottom, g.maxY); }
    else rows.push({ top: g.minY, bottom: g.maxY, items: [g] });
  }
  return rows.flatMap((r) => r.items.sort((a, b) => a.minX - b.minX))
    .map((g) => ({ minX: g.minX * step, minY: g.minY * step, maxX: Math.min(img.w - 1, (g.maxX + 1) * step), maxY: Math.min(img.h - 1, (g.maxY + 1) * step) }));
}

/** Prop sheet → one PNG per object, cropped to it. `names` in reading order (null = skip). */
async function props({ id, scale, names, outDir }) {
  const img = await loadKeyed(find(id));
  const base = rawImage(img);
  const objects = findObjects(img);
  if (objects.length !== names.length) throw new Error(`${id} : ${objects.length} objets trouvés, ${names.length} noms attendus`);
  const done = [];
  for (const [n, b] of objects.entries()) {
    const name = names[n];
    if (!name) continue;
    const width = b.maxX - b.minX + 1, height = b.maxY - b.minY + 1;
    const out = path.join(outDir, `${name}.png`);
    await base.clone().extract({ left: b.minX, top: b.minY, width, height })
      .resize(Math.round(width * scale), Math.round(height * scale)).png({ compressionLevel: 9 }).toFile(out);
    done.push(`${name} ${Math.round(width * scale)}x${Math.round(height * scale)}`);
  }
  return `${outDir}: ${done.join(", ")}`;
}

/** Ground texture → seamless square: cross-fades the image with its half-offset copy. */
async function seamless({ id, size, out }) {
  const { data, info } = await sharp(find(id)).resize(size, size).removeAlpha().raw().toBuffer({ resolveWithObject: true });
  const n = size, res = Buffer.alloc(n * n * 3);
  const h = n / 2;
  for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) {
    // Weight of the original: 1 in the centre, 0 at the edges (where the shifted copy is seamless).
    const wx = 1 - Math.abs(x - h + 0.5) / h, wy = 1 - Math.abs(y - h + 0.5) / h;
    const w = Math.min(1, Math.max(0, Math.min(wx, wy) * 2.2));
    const sx = (x + h) % n, sy = (y + h) % n;
    for (let k = 0; k < 3; k++) res[(y * n + x) * 3 + k] = Math.round(data[(y * n + x) * 3 + k] * w + data[(sy * n + sx) * 3 + k] * (1 - w));
  }
  // At the edges only the shifted copy remains, and its opposite edges are neighbours in
  // the source image: the result wraps without a seam.
  await sharp(res, { raw: { width: n, height: n, channels: 3 } }).png({ compressionLevel: 9 }).toFile(out);
  return `${out} (${n}x${n}, raccordable)`;
}

for (const d of ["characters", "dinos", "props", "ground", "battle", "ui"]) fs.mkdirSync(path.join(OUT, d), { recursive: true });

const results = await Promise.all([
  sheet({ id: "0wbmww", rows: 4, cols: 4, frameHeight: 176, out: `${OUT}/characters/chloe.png` }),
  sheet({ id: "5fwqyr", rows: 4, cols: 4, frameHeight: 176, out: `${OUT}/characters/maia.png` }),
  sheet({ id: "8v65ka", rows: 2, cols: 3, frameHeight: 200, out: `${OUT}/dinos/velociraptor.png` }),
  sheet({ id: "n6zd1g", rows: 2, cols: 3, frameHeight: 150, out: `${OUT}/dinos/protoceratops.png` }),
  // Front (row 1) and back (row 2) views, in cells the size of the side-view frames.
  sheet({ id: "xljkyo", rows: 2, cols: 4, frameHeight: 196, cell: [254, 208], out: `${OUT}/dinos/velociraptor_face_dos.png` }),
  sheet({ id: "mmzqed", rows: 2, cols: 4, frameHeight: 148, cell: [237, 158], out: `${OUT}/dinos/protoceratops_face_dos.png` }),
  props({
    id: "to7ui1", scale: 0.6, outDir: `${OUT}/props`,
    names: ["arbre_rond", "fougere_arbre", "araucaria", "buisson", "rocher", "cailloux", "tronc", "ronces",
      "hautes_herbes", "fougeres", "fleurs_roses", "fleurs_violettes", "panneau", "cloture", "ambre", "souche"],
  }),
  // Battle backdrops: plain resize (opaque).
  sharp(find("frasoq")).resize(1920).jpeg({ quality: 86, mozjpeg: true }).toFile(`${OUT}/battle/plaines.jpg`).then(() => `${OUT}/battle/plaines.jpg`),
  seamless({ id: "eszvx5", size: 512, out: `${OUT}/ground/herbe.png` }),
  seamless({ id: "oxlhun", size: 512, out: `${OUT}/ground/terre.png` }),
]);
console.log(results.join("\n"));
