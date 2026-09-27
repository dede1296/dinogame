// Turns the nano-banana sheets (JPG on flat magenta) into Godot assets (PNG with alpha).
//   - sprite sheets: cut into a grid, keyed, cropped to the union of all frames (so the
//     frames stay aligned on a common baseline), scaled, re-packed without gaps;
//   - prop sheets: keyed, split per grid cell and cropped to each prop;
//   - ground textures: made seamless (half-offset cross-fade) and scaled.
// Usage (from the repository root): node Godot/tools/process-art.mjs [name …]
//   With names, only the outputs whose path contains one of them (e.g. "parasaurolophus").
// More jobs live in Godot/tools/art-jobs/*.mjs (one file per batch: a region, a chapter), each
// exporting default (helpers) => [[out, job], …] with the helpers below.
// `sharp` comes from the repository's node_modules.
import sharp from "sharp";
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

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
  // Each drawing is found whole (a crest may stick out of its grid cell) and given to the
  // cell under its centre.
  const boxes = new Array(rows * cols).fill(null);
  for (const b of findObjects(img, { gap: -1, minArea: 400 })) {
    const c = Math.floor((b.minX + b.maxX) / 2 / cw), r = Math.floor((b.minY + b.maxY) / 2 / ch);
    const i = r * cols + c;
    if (r < rows && c < cols && (!boxes[i] || (b.maxX - b.minX) * (b.maxY - b.minY) > (boxes[i].maxX - boxes[i].minX) * (boxes[i].maxY - boxes[i].minY))) boxes[i] = b;
  }
  let unionH = 0;
  for (const b of boxes) if (b) unionH = Math.max(unionH, b.maxY - b.minY + 1);
  const scale = frameHeight / unionH;
  const base = rawImage(img);
  const composites = [];
  for (const [i, b] of boxes.entries()) {
    if (!b) continue;
    const width = b.maxX - b.minX + 1, height = b.maxY - b.minY + 1;
    const w = Math.min(cw0, Math.round(width * scale)), h = Math.min(ch0, Math.round(height * scale));
    // The box may catch the tip of a neighbouring drawing: keep only the main blob.
    const raw = await base.clone().extract({ left: b.minX, top: b.minY, width, height }).raw().toBuffer();
    keepLargestBlob(raw, width, height);
    const frame = await sharp(raw, { raw: { width, height, channels: 4 } }).resize(w, h).png().toBuffer();
    const col = i % cols, row = Math.floor(i / cols);
    composites.push({ input: frame, left: col * cw0 + Math.round((cw0 - w) / 2), top: row * ch0 + ch0 - 4 - h });
  }
  await sharp({ create: { width: cw0 * cols, height: ch0 * rows, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite(composites).png({ compressionLevel: 9 }).toFile(out);
  return `${out} (${cols}x${rows} frames de ${cw0}x${ch0})`;
}

// Lit objects painted with a glow: the glow over the magenta background stays pink.
const GLOWING = ["lanterne", "lampe", "couveuse", "squelette_geant"];   // (and a soft sand edge)

/** Clears (in place, RGBA raw) the half-transparent pinkish pixels around a glowing object. */
function removePinkHalo(data) {
  for (let i = 0; i < data.length; i += 4) {
    const r = data[i], g = data[i + 1], b = data[i + 2];
    if (data[i + 3] < 250 && Math.min(r, b) - g > 18) data[i + 3] = 0;
  }
}

/** Clears (in place, RGBA raw) every opaque blob but the largest one. */
function keepLargestBlob(data, w, h) {
  const label = new Int32Array(w * h).fill(-1);
  const sizes = [];
  for (let s = 0; s < w * h; s++) {
    if (label[s] >= 0 || data[s * 4 + 3] < 24) continue;
    const id = sizes.length;
    let size = 0;
    const stack = [s];
    label[s] = id;
    while (stack.length) {
      const j = stack.pop(), x = j % w, y = (j / w) | 0;
      size++;
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const nx = x + dx, ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        const k = ny * w + nx;
        if (label[k] >= 0 || data[k * 4 + 3] < 24) continue;
        label[k] = id;
        stack.push(k);
      }
    }
    sizes.push(size);
  }
  const keep = sizes.indexOf(Math.max(...sizes));
  for (let s = 0; s < w * h; s++) if (label[s] !== keep && data[s * 4 + 3] >= 24) data[s * 4 + 3] = 0;
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
/**
 * `boxes`: [x, y, w, h] per name, when objects touch on the sheet (each crop then keeps only
 * its largest blob, so the neighbour's edge goes).
 */
async function props({ id, scale, names, outDir, gap = 6, boxes = null }) {
  const img = await loadKeyed(find(id));
  const base = rawImage(img);
  const objects = boxes
    ? boxes.map(([x, y, w, h]) => ({ minX: x, minY: y, maxX: Math.min(img.w - 1, x + w - 1), maxY: Math.min(img.h - 1, y + h - 1) }))
    : findObjects(img, { gap });
  if (objects.length !== names.length) throw new Error(`${id} : ${objects.length} objets trouvés, ${names.length} noms attendus : ${objects.map((b) => `[${b.minX},${b.minY} ${b.maxX - b.minX}x${b.maxY - b.minY}]`).join(" ")}`);
  const done = [];
  for (const [n, b] of objects.entries()) {
    const name = names[n];
    if (!name) continue;
    const width = b.maxX - b.minX + 1, height = b.maxY - b.minY + 1;
    const out = path.join(outDir, `${name}.png`);
    const raw = await base.clone().extract({ left: b.minX, top: b.minY, width, height }).raw().toBuffer();
    if (boxes) keepLargestBlob(raw, width, height);
    if (GLOWING.includes(name)) removePinkHalo(raw);
    await sharp(raw, { raw: { width, height, channels: 4 } })
      .resize(Math.round(width * scale), Math.round(height * scale)).png({ compressionLevel: 9 }).toFile(out);
    done.push(`${name} ${Math.round(width * scale)}x${Math.round(height * scale)}`);
  }
  return `${outDir}: ${done.join(", ")}`;
}

/**
 * Icon sheet → one PNG per grid cell (names in reading order), each trimmed and fitted in size x size.
 * `boxes`: [x, y, w, h] per name instead of the grid, when an icon spills over its cell.
 */
async function icons({ id, cols, rows, names, size, outDir, boxes = null }) {
  const img = await loadKeyed(find(id));
  const base = rawImage(img);
  const cw = img.w / cols, ch = img.h / rows;
  const done = [];
  for (let i = 0; i < names.length; i++) {
    const c = i % cols, r = Math.floor(i / cols);
    const [x0, y0, x1, y1] = boxes
      ? [boxes[i][0], boxes[i][1], boxes[i][0] + boxes[i][2], boxes[i][1] + boxes[i][3]]
      : [Math.round(c * cw + INSET), Math.round(r * ch + INSET), Math.round((c + 1) * cw - INSET), Math.round((r + 1) * ch - INSET)];
    const b = alphaBox(img, x0, y0, Math.min(img.w, x1), Math.min(img.h, y1));
    if (!b) continue;
    const out = path.join(outDir, names[i] + ".png");
    const width = b.maxX - b.minX + 1, height = b.maxY - b.minY + 1;
    const raw = await base.clone().extract({ left: b.minX, top: b.minY, width, height }).raw().toBuffer();
    if (GLOWING.includes(names[i])) removePinkHalo(raw);
    await sharp(raw, { raw: { width, height, channels: 4 } })
      .resize(size, size, { fit: "contain", background: { r: 0, g: 0, b: 0, alpha: 0 } }).png({ compressionLevel: 9 }).toFile(out);
    done.push(names[i]);
  }
  return outDir + ": " + done.join(", ");
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

// [output path (for the name filter), job]
// Cell size of ankylosaurus.png (its front/back views share it).
const ANKY_CELL = [205, 148];
const JOBS = [
  [`${OUT}/characters/chloe.png`, (out) => sheet({ id: "0wbmww", rows: 4, cols: 4, frameHeight: 176, out })],
  [`${OUT}/characters/maia.png`, (out) => sheet({ id: "5fwqyr", rows: 4, cols: 4, frameHeight: 176, out })],
  [`${OUT}/dinos/velociraptor.png`, (out) => sheet({ id: "8v65ka", rows: 2, cols: 3, frameHeight: 200, out })],
  [`${OUT}/dinos/protoceratops.png`, (out) => sheet({ id: "n6zd1g", rows: 2, cols: 3, frameHeight: 150, out })],
  [`${OUT}/dinos/parasaurolophus.png`, (out) => sheet({ id: "a9ze6l", rows: 2, cols: 3, frameHeight: 170, out })],
  // Front (row 1) and back (row 2) views, in cells the size of the side-view frames.
  [`${OUT}/dinos/velociraptor_face_dos.png`, (out) => sheet({ id: "zz8efh", rows: 2, cols: 4, frameHeight: 196, cell: [254, 208], out })],
  [`${OUT}/dinos/protoceratops_face_dos.png`, (out) => sheet({ id: "3shwit", rows: 2, cols: 4, frameHeight: 148, cell: [237, 158], out })],
  [`${OUT}/dinos/parasaurolophus_face_dos.png`, (out) => sheet({ id: "us6mkv", rows: 2, cols: 4, frameHeight: 168, cell: [251, 178], out })],
  [`${OUT}/props`, (outDir) => props({
    id: "to7ui1", scale: 0.6, outDir,
    names: ["arbre_rond", "fougere_arbre", "araucaria", "buisson", "rocher", "cailloux", "tronc", "ronces",
      "hautes_herbes", "fougeres", "fleurs_roses", "fleurs_violettes", "panneau", "cloture", "ambre", "souche"],
  })],
  // Chloé in the saddle (Saddle): front, facing left, facing right, back; same scale as chloe.png.
  [`${OUT}/characters/chloe_selle.png`, (out) => sheet({ id: "jeyusd", rows: 1, cols: 4, frameHeight: 220, cell: [150, 228], out })],
  // Havre-Doré.
  ...[["ferreol", "rvfep6"], ["joss", "qhacr4"], ["pervenche", "6r0ovw"], ["rosalie", "x4wade"], ["lilou", "jq0vxj"],
    ["gaspard", "itvhg0"], ["marchande", "c8s4z6"], ["garde", "yddx5i"], ["pecheur", "3s9xxz"]].map(([name, id]) =>
    [`${OUT}/characters/${name}.png`, (out) => sheet({ id, rows: 4, cols: 4, frameHeight: 176, out })]),
  [`${OUT}/havre/objets`, () => props({ id: "nvwjlo", scale: 0.5, boxes: [[120, 50, 345, 225], [660, 50, 470, 235], [35, 315, 545, 540], [630, 315, 530, 540]], outDir: `${OUT}/props`, names: ["galet", "monticule", "etal_fruits", "etal_poisson"] })],
  [`${OUT}/plaines/crane`, () => props({ id: "4y78ve", scale: 0.5, gap: 40, outDir: `${OUT}/props`, names: ["grand_crane"] })],
  [`${OUT}/ui/objets`, () => icons({ id: "pfo4v8", cols: 3, rows: 1, size: 160, boxes: [[15, 110, 505, 540], [530, 130, 410, 500], [940, 200, 420, 370]], outDir: `${OUT}/ui`, names: ["bottes", "cuir", "boucle"] })],
  [`${OUT}/ground/grotte_sol.png`, (out) => seamless({ id: "zm7vp5", size: 512, out })],
  // Forêt Jurassique and Grotte des Échos (bestiary), with Griffe-Grise, the Ancien of the forest.
  ...[["stegosaurus", "3snkyi", 180], ["brachiosaurus", "4frcgp", 220], ["dilophosaurus", "yr1f2h", 180], ["pachycephalosaurus", "1sw9u7", 170],
    ["allosaurus", "bp96w5", 210], ["deinonychus", "7dnkzz", 190], ["microraptor", "qbu8uu", 140], ["utahraptor", "djmzdq", 230],
    ["griffe_grise", "mvpqcb", 210], ["anurognathus", "914bc7", 120]].map(([name, id, frameHeight]) =>
    [`${OUT}/dinos/${name}.png`, (out) => sheet({ id, rows: 2, cols: 3, frameHeight, out })]),
  // Their front and back views, in cells the size of their side-view frames.
  ...[["stegosaurus", "kr51lr", 178, [261, 188]], ["brachiosaurus", "jt1ujf", 218, [226, 228]], ["dilophosaurus", "wcxq3w", 178, [208, 188]],
    ["pachycephalosaurus", "w2wdyv", 168, [207, 178]], ["allosaurus", "c44irg", 208, [262, 218]], ["deinonychus", "rtix92", 188, [216, 198]],
    ["microraptor", "aw17f4", 138, [157, 148]], ["utahraptor", "8g9dhj", 228, [282, 238]], ["griffe_grise", "dlm1oz", 208, [258, 218]],
    ["anurognathus", "fnyct3", 118, [140, 128]]].map(([name, id, frameHeight, cell]) =>
    [`${OUT}/dinos/${name}_face_dos.png`, (out) => sheet({ id, rows: 2, cols: 4, frameHeight, cell, out })]),
  // Chapter 1, the Grotte des Échos: a henchman of the Ombre Noire, the first corrupted dino.
  [`${OUT}/characters/sbire.png`, (out) => sheet({ id: "slvv1l", rows: 4, cols: 4, frameHeight: 176, out })],
  [`${OUT}/dinos/protoceratops_corrompu.png`, (out) => sheet({ id: "wpkxd3", rows: 2, cols: 3, frameHeight: 150, out })],
  [`${OUT}/characters/roc.png`, (out) => sheet({ id: "b0tan1", rows: 4, cols: 4, frameHeight: 176, out })],
  [`${OUT}/characters/isaure.png`, (out) => sheet({ id: "zp5pby", rows: 4, cols: 4, frameHeight: 176, out })],
  [`${OUT}/dinos/ankylosaurus.png`, (out) => sheet({ id: "96xapm", rows: 2, cols: 3, frameHeight: 140, out })],
  [`${OUT}/dinos/ankylosaurus_face_dos.png`, (out) => sheet({ id: "gqdf4n", rows: 2, cols: 4, frameHeight: 138, cell: ANKY_CELL, out })],
  [`${OUT}/port/batiments`, () => props({ id: "2bcnde", scale: 0.5, outDir: `${OUT}/props`, names: ["maison_blanche", "maison_jaune", "maison_port", "cabinet"] })],
  [`${OUT}/port/objets`, () => props({ id: "axfrx2", scale: 0.45,
    boxes: [[96, 92, 700, 392], [856, 76, 504, 412], [1464, 80, 316, 412], [0, 0, 1, 1], [96, 516, 640, 460], [928, 580, 324, 368],
      [1440, 528, 256, 432], [0, 0, 1, 1], [120, 950, 520, 440], [900, 1044, 388, 304], [0, 0, 1, 1], [1800, 950, 510, 420],
      [176, 1392, 420, 360], [0, 0, 1, 1], [1320, 1280, 428, 460], [1920, 1376, 328, 368]], outDir: `${OUT}/props`, names: ["barque", "caisses", "tonneau", null, "filet", "bitte", "lanterne", null, "casiers", "cordage", null, "banc", "sechoir", null, "ancre", "bac_fleurs"] })],
  [`${OUT}/cabinet/mobilier`, () => props({ id: "c4yp4q", scale: 0.5, outDir: `${OUT}/props`, names: ["bureau", "bibliotheque", "couveuse", "fougere_pot", "lampe", "fauteuil", "etabli", "mur_cabinet"] })],
  [`${OUT}/cabinet/socle`, () => props({ id: "387vok", scale: 0.5, outDir: `${OUT}/props`, names: ["socle", null, null, null] })],
  [`${OUT}/dinos/triceratops.png`, (out) => sheet({ id: "9fbgbo", rows: 2, cols: 3, frameHeight: 200, out })],
  [`${OUT}/dinos/compsognathus.png`, (out) => sheet({ id: "n0lakg", rows: 2, cols: 3, frameHeight: 120, out })],
  [`${OUT}/dinos/dimorphodon.png`, (out) => sheet({ id: "xv3qwx", rows: 2, cols: 3, frameHeight: 150, out })],
  [`${OUT}/dinos/psittacosaurus.png`, (out) => sheet({ id: "7uecxo", rows: 2, cols: 3, frameHeight: 135, out })],
  [`${OUT}/dinos/troodon.png`, (out) => sheet({ id: "dxw3iu", rows: 2, cols: 3, frameHeight: 170, out })],
  [`${OUT}/dinos/triceratops_face_dos.png`, (out) => sheet({ id: "ehki7a", rows: 2, cols: 4, frameHeight: 198, cell: [305, 208], out })],
  [`${OUT}/dinos/compsognathus_face_dos.png`, (out) => sheet({ id: "0s7pno", rows: 2, cols: 4, frameHeight: 118, cell: [172, 128], out })],
  [`${OUT}/dinos/dimorphodon_face_dos.png`, (out) => sheet({ id: "gj7d8u", rows: 2, cols: 4, frameHeight: 148, cell: [177, 158], out })],
  [`${OUT}/dinos/psittacosaurus_face_dos.png`, (out) => sheet({ id: "uset4o", rows: 2, cols: 4, frameHeight: 133, cell: [205, 143], out })],
  [`${OUT}/dinos/troodon_face_dos.png`, (out) => sheet({ id: "wc8k22", rows: 2, cols: 4, frameHeight: 168, cell: [214, 178], out })],
  [`${OUT}/plaines/objets`, () => props({ id: "f424k7", scale: 0.5, outDir: `${OUT}/props`, names: ["porte_ambre", "ecaille", "serrure", "stalagmite", "cristaux", "rocher_grotte"] })],
  [`${OUT}/ground/paves.png`, (out) => seamless({ id: "rfr8xj", size: 512, out })],
  [`${OUT}/ground/plancher.png`, (out) => seamless({ id: "wyzdq7", size: 512, out })],
  [`${OUT}/ui/meteo`, () => icons({ id: "na9sb3", cols: 2, rows: 2, size: 96, outDir: `${OUT}/ui`, names: ["meteo_soleil", "meteo_lune", "meteo_pluie", "meteo_brume"] })],
  // Battle backdrops: plain resize (opaque).
  [`${OUT}/battle/plaines.jpg`, (out) => sharp(find("frasoq")).resize(1920).jpeg({ quality: 86, mozjpeg: true }).toFile(out).then(() => out)],
  [`${OUT}/battle/grotte.jpg`, (out) => sharp(find("9g4ogb")).resize(1920, 1072, { fit: "cover" }).jpeg({ quality: 86, mozjpeg: true }).toFile(out).then(() => out)],
  [`${OUT}/ground/herbe.png`, (out) => seamless({ id: "eszvx5", size: 512, out })],
  [`${OUT}/ground/terre.png`, (out) => seamless({ id: "oxlhun", size: 512, out })],
  [`${OUT}/ground/falaise.png`, (out) => seamless({ id: "o3jvsq", size: 512, out })],
  // Forêt Jurassique: battle backdrop (from the Plaines backdrop), forest-floor ground and new scenery props.
  [`${OUT}/battle/foret.jpg`, (out) => sharp(find("fyp8fd")).resize(1920, 1072, { fit: "cover" }).jpeg({ quality: 86, mozjpeg: true }).toFile(out).then(() => out)],
  [`${OUT}/ground/sous_bois.png`, (out) => seamless({ id: "zbken5", size: 512, out })],
  // Sheet has a spare log and a spare bone (the model drew two of each): kept the cleaner one of each, null for the other.
  [`${OUT}/foret/props`, () => props({
    id: "6vqggs", scale: 0.5, outDir: `${OUT}/props`,
    names: ["fougere_geante", null, "tronc_mousse", "os_dino", "champignons", "rocher_mousse", "souche_geante", null],
  })],
  [`${OUT}/foret/arbre_geant`, () => props({ id: "71zuo2", scale: 0.5, outDir: `${OUT}/props`, names: ["arbre_geant"] })],
];
const JOB_DIR = "Godot/tools/art-jobs";
const HELPERS = { sheet, props, icons, seamless, sharp, find, OUT };
if (fs.existsSync(JOB_DIR)) {
  for (const f of fs.readdirSync(JOB_DIR).filter((n) => n.endsWith(".mjs")).sort()) {
    JOBS.push(...(await import(pathToFileURL(path.resolve(JOB_DIR, f)).href)).default(HELPERS));
  }
}
const ONLY = process.argv.slice(2);
const results = await Promise.all(JOBS
  .filter(([out]) => ONLY.length === 0 || ONLY.some((name) => out.includes(name)))
  .map(([out, job]) => job(out)));
console.log(results.join("\n"));
