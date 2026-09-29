// Retouches avant le chapitre 6 (29/09), agent images : le rocher gravé « PAR OÙ ?! » du canyon
// des Vents, un feu de camp peint (flamme animée 6 cases + bouffée de fumée — le foyer sans
// flamme, assets/art/props/feu_camp.png, existait déjà et n'a pas été retouché : il correspond
// déjà à la description, même empreinte au sol), et un vrai cycle de battement d'ailes pour
// dinos/pteranodon_vol.png. Voir vivants/PLAN_avant_ch6.md (scratchpad). Toutes les planches :
// nano-banana (edit_image/generate_image), fond magenta, une planche existante du jeu en
// référence de style quand c'est pertinent (rocher_canyon.png, flamme.png, pteranodon.png).
//
// Mêmes helpers locaux que finition.mjs (process-art.mjs n'exporte pas keyMagenta/findObjects
// aux jobs) : recopiés ici.
const KEY_LOW = 70, KEY_HIGH = 150;
const clamp = (v) => Math.max(0, Math.min(255, Math.round(v)));

function keyMagenta(data) {
  for (let i = 0; i < data.length; i += 4) {
    const r = data[i], g = data[i + 1], b = data[i + 2];
    const m = Math.min(r, b) - g;
    let a = 1 - (m - KEY_LOW) / (KEY_HIGH - KEY_LOW);
    a = Math.max(0, Math.min(1, a));
    if (a === 0) { data[i + 3] = 0; continue; }
    if (a < 1) {
      data[i] = clamp((r - (1 - a) * 255) / a);
      data[i + 2] = clamp((b - (1 - a) * 255) / a);
      data[i + 1] = clamp(g / a > 255 ? 255 : g);
    } else if (m > 10) {
      const cap = g + 10;
      if (r > cap && b > cap) { data[i] = Math.max(cap, r - m); data[i + 2] = Math.max(cap, b - m); }
    }
    data[i + 3] = Math.round(a * 255);
  }
}

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

/** Full-image alpha bounding box (a single object, no grid): pixels with alpha > threshold. */
function alphaBoxFull(img, threshold = 24) {
  let minX = Infinity, minY = Infinity, maxX = -1, maxY = -1;
  for (let y = 0; y < img.h; y++) for (let x = 0; x < img.w; x++) {
    if (img.data[(y * img.w + x) * 4 + 3] > threshold) {
      if (x < minX) minX = x; if (x > maxX) maxX = x;
      if (y < minY) minY = y; if (y > maxY) maxY = y;
    }
  }
  return { minX, minY, maxX, maxY };
}

/** Checks that no kept pixel of `out` (a strip of `cols` equal cells) touches a cell's edge. */
async function checkNoEdgeTouch(sharp, out, cols) {
  const { data, info } = await sharp(out).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const cw = info.width / cols;
  const bad = [];
  for (let c = 0; c < cols; c++) {
    const x0 = Math.round(c * cw), x1 = Math.round((c + 1) * cw);
    for (let x = x0; x < x1; x++) {
      if (data[(0 * info.width + x) * 4 + 3] > 4 || data[((info.height - 1) * info.width + x) * 4 + 3] > 4) { bad.push(`case ${c} bord haut/bas`); break; }
    }
    for (let y = 0; y < info.height; y++) {
      if (data[(y * info.width + x0) * 4 + 3] > 4 || data[(y * info.width + (x1 - 1)) * 4 + 3] > 4) { bad.push(`case ${c} bord gauche/droite`); break; }
    }
  }
  return bad.length ? `ATTENTION pixels au bord : ${[...new Set(bad)].join(", ")}` : "aucun pixel au bord d'une case (vérifié)";
}

/** Clears (in place) semi-transparent pixels still tinted magenta after keying: the fringe band
 * nano-banana's JPEG output leaves around a very soft (blurred) edge, where the unpremultiply
 * maths blows up a small residual cast instead of cancelling it (seen on fumee.png : a ~5 px pink
 * ring). Same idea as process-art.mjs's GLOWING halo removal, applied to every soft-edged asset
 * here rather than a fixed name list. */
function removeFringe(data) {
  for (let i = 0; i < data.length; i += 4) {
    if (data[i + 3] < 250 && Math.abs(Math.min(data[i], data[i + 2]) - data[i + 1]) > 18) data[i + 3] = 0;
  }
}

export default ({ sharp, props, find, OUT }) => {
  async function loadKeyed(file) {
    const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    keyMagenta(data);
    removeFringe(data);
    return { data, w: info.width, h: info.height };
  }
  const rawImage = (img) => sharp(img.data, { raw: { width: img.w, height: img.h, channels: 4 } });

  /** A horizontal row of N flames (or similar single-blob poses), bottom-aligned to a common
   * baseline, same scale for every frame (heights stay relatively different — that's the point
   * of the pose), each centred in an equal-width cell. */
  async function flameRow({ id, count, frameHeight, out, pad = 6, gap = 16, findGap = 6, minArea = 200, step = 2 }) {
    const img = await loadKeyed(find(id));
    const objects = findObjects(img, { gap: findGap, minArea, step });
    if (objects.length !== count) {
      throw new Error(`${out} (${id}) : ${objects.length} flammes détectées, ${count} attendues : ${objects.map((b) => `[${b.minX},${b.minY} ${b.maxX - b.minX}x${b.maxY - b.minY}]`).join(" ")}`);
    }
    const base = rawImage(img);
    const scale = frameHeight / Math.max(...objects.map((b) => b.maxY - b.minY + 1));
    const frames = [];
    for (const b of objects) {
      const width = b.maxX - b.minX + 1, height = b.maxY - b.minY + 1;
      const w = Math.max(1, Math.round(width * scale)), h = Math.max(1, Math.round(height * scale));
      const buf = await base.clone().extract({ left: b.minX, top: b.minY, width, height }).resize(w, h).png().toBuffer();
      frames.push({ buf, w, h });
    }
    const cellW = Math.max(...frames.map((f) => f.w)) + gap;
    const cellH = frameHeight + pad * 2;
    const composites = frames.map((f, i) => ({ input: f.buf, left: i * cellW + Math.round((cellW - f.w) / 2), top: cellH - pad - f.h }));
    await sharp({ create: { width: cellW * frames.length, height: cellH, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
      .composite(composites).png({ compressionLevel: 9 }).toFile(out);
    const check = await checkNoEdgeTouch(sharp, out, frames.length);
    return `${out} (${frames.length} cases égales de ${cellW}x${cellH}) — ${check}`;
  }

  /** A single soft object (the smoke puff): trimmed to its alpha box plus a margin (kept loose,
   * so the very blurred edge isn't cut), resized to `targetHeight`. */
  async function singleCrop({ id, out, targetHeight, margin = 40, threshold = 20 }) {
    const img = await loadKeyed(find(id));
    const b = alphaBoxFull(img, threshold);
    const left = Math.max(0, b.minX - margin), top = Math.max(0, b.minY - margin);
    const width = Math.min(img.w - left, b.maxX - b.minX + 1 + margin * 2);
    const height = Math.min(img.h - top, b.maxY - b.minY + 1 + margin * 2);
    const scale = targetHeight / height;
    const w = Math.max(1, Math.round(width * scale)), h = Math.max(1, Math.round(height * scale));
    await rawImage(img).extract({ left, top, width, height }).resize(w, h).png({ compressionLevel: 9 }).toFile(out);
    return `${out} (${w}x${h})`;
  }

  // Four separate nano-banana poses (nano-banana repeats near-identical wings when asked for a
  // whole sheet at once — see docs/direction-artistique.md « À refaire », Ptéranodon en vol
  // 29/09 — so each pose was generated on its own, edited from dinos/pteranodon.png). Anchored on
  // the eye (manually located once per source image: automatic feature detection isn't available
  // to these jobs), at a UNIFORM scale across all four so the body doesn't change size, only the
  // wings move — the same contract as a hand-drawn flight cycle. nano-banana drew the four at
  // different sizes: `k` brings each body to the first one's size (iris area and eye width
  // measured on the sources, 29/09).
  const PTERO_CELL = [347, 202];   // unchanged from today's dinos/pteranodon_vol.png.
  const PTERO_MARGIN = 8;          // px kept clear on every side, checked below.
  const PTERO_FRAMES = [
    { id: "njfvbc", eye: [1708, 1041], k: 1.0 },    // wings tout en haut
    { id: "gpxgjq", eye: [1507, 698], k: 1.49 },    // wings à plat (plane)
    { id: "jeaml4", eye: [1646, 552], k: 1.3 },     // wings tout en bas
    { id: "q0d7rq", eye: [1760, 846], k: 1.23 },    // wings remontant à mi-hauteur
  ];
  async function pteranodonCycle(out) {
    const loaded = [];
    for (const f of PTERO_FRAMES) {
      const img = await loadKeyed(find(f.id));
      loaded.push({ img, b: alphaBoxFull(img, 24), eye: f.eye, k: f.k });
    }
    const L = Math.max(...loaded.map((f) => f.k * (f.eye[0] - f.b.minX)));
    const R = Math.max(...loaded.map((f) => f.k * (f.b.maxX - f.eye[0])));
    const U = Math.max(...loaded.map((f) => f.k * (f.eye[1] - f.b.minY)));
    const D = Math.max(...loaded.map((f) => f.k * (f.b.maxY - f.eye[1])));
    const [cw, ch] = PTERO_CELL;
    const s = Math.min((cw - 2 * PTERO_MARGIN) / (L + R), (ch - 2 * PTERO_MARGIN) / (U + D));
    const exCell = PTERO_MARGIN + s * L, eyCell = PTERO_MARGIN + s * U;
    const composites = [];
    for (const [i, f] of loaded.entries()) {
      const { img, b, eye } = f;
      const sf = s * f.k;   // (this pose's own scale: the body the same size in every frame)
      const width = b.maxX - b.minX + 1, height = b.maxY - b.minY + 1;
      const raw = await rawImage(img).clone().extract({ left: b.minX, top: b.minY, width, height }).raw().toBuffer();
      const w = Math.max(1, Math.round(width * sf)), h = Math.max(1, Math.round(height * sf));
      const frame = await sharp(raw, { raw: { width, height, channels: 4 } }).resize(w, h).png().toBuffer();
      composites.push({
        input: frame,
        left: Math.round(i * cw + exCell - sf * (eye[0] - b.minX)),
        top: Math.round(eyCell - sf * (eye[1] - b.minY)),
      });
    }
    await sharp({ create: { width: cw * loaded.length, height: ch, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
      .composite(composites).png({ compressionLevel: 9 }).toFile(out);
    const check = await checkNoEdgeTouch(sharp, out, loaded.length);
    return `${out} (${loaded.length}x1 cases de ${cw}x${ch}, échelle=${s.toFixed(4)}) — ${check}`;
  }

  return [
    // 1. Le rocher gravé du canyon des Vents (même style que rocher_canyon.png), ~1,5 m,
    // « PAR OÙ ?! » gravé au couteau (réussi du premier coup par nano-banana : lettres incisées,
    // ombre claire/foncée — pas besoin du repli sharp+SVG prévu au plan).
    [`${OUT}/vivants2/rocher_grave`, () => props({ id: "ym8b1c", scale: 0.25, outDir: `${OUT}/props`, names: ["rocher_grave"] })],
    // 2. Feu de camp : props/feu_camp.png (le foyer sans flamme) existait déjà et correspond déjà
    // à la description (cercle de pierres, bûches croisées, braises au centre, ~0,9 m) : gardé tel
    // quel. Nouveau : une vraie flamme animée en 6 cases (boucle) et une bouffée de fumée pour
    // particules, fond transparent, style peint de flamme.png.
    [`${OUT}/props/flamme_anim.png`, (out) => flameRow({ id: "1qo7zv", count: 6, frameHeight: 150, out })],
    [`${OUT}/props/fumee.png`, (out) => singleCrop({ id: "muk4bg", out, targetHeight: 320 })],
    // 3. dinos/pteranodon_vol.png : vrai cycle de battement (4 cases), reprend le Ptéranodon de
    // pteranodon.png, en vol, profil vers la droite, cases de 347x202 (inchangé).
    [`${OUT}/dinos/pteranodon_vol.png`, (out) => pteranodonCycle(out)],
  ];
};
