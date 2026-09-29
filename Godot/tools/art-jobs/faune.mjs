// Petite faune (contrat "vivants", agent 2) : moustique, libellule, crabe, lezard, scorpion,
// scarabee, grenouille, poisson_saut, banc, meduse, ptero_vol, ichthyornis, mammifere, feuille
// (assets/art/fauna/<id>.png), plus assets/art/dinos/pteranodon_vol.png (le Ptéranodon en vol).
// Toutes faites avec nano-banana (mcp__nano-banana__edit_image, planche existante du jeu donnée
// en image principale pour hériter du style peint/contour, sujet entièrement remplacé par la
// bête décrite dans le prompt avec son anatomie réelle).
//
// Le contrat impose UNE SEULE RANGÉE HORIZONTALE de N cases ÉGALES par planche : Sprite3D
// (world/view3d/wildlife_looks.gd, déjà écrit) lit la planche avec `hframes = N`, qui suppose
// une division régulière `largeur / N` — donc toutes les cases doivent avoir la MÊME largeur
// (comme les planches de dinos existantes, cf. `sheet` dans process-art.mjs), pas une largeur
// "au plus juste" par pose. nano-banana a rendu certaines planches en grille 2x2 (crabe, lezard)
// au lieu d'une rangée, et ne cale jamais les poses sur des cases de largeur strictement égale
// (une aile déployée déborde plus loin qu'une aile repliée) : découper par simple division de la
// largeur (comme `sheet` le fait sur la grille SOURCE) coupait parfois une bête ou mordait sur sa
// voisine. `faunaRow` détecte donc chaque bête comme un blob connecté séparé (même principe que
// `findObjects` de `props` dans process-art.mjs, réécrit ici en local car `props` sort un fichier
// par objet et pas une planche), les trie en ordre de lecture (bandes de lignes, puis gauche à
// droite), les mise à l'échelle sur `frameHeight`, puis les recentre chacune dans une case de
// largeur commune (la plus large pose + marge) — la sortie a donc bien N cases égales, comme
// `hframes` l'exige, même si la largeur dessinée de chaque pose diffère.
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

/**
 * Connected blobs of opaque pixels on a downsampled mask, merged when their boxes are closer
 * than `gap` (a wingtip separated from a body by a thin anti-aliased seam, etc). Returned in
 * reading order: rows by gaps in y, then x within a row (same algorithm as `findObjects` in
 * process-art.mjs's `props`, copied here since it isn't one of the exported helpers).
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

export default ({ sharp, find, OUT }) => {
  async function loadKeyed(file) {
    const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    keyMagenta(data);
    return { data, w: info.width, h: info.height };
  }
  const rawImage = (img) => sharp(img.data, { raw: { width: img.w, height: img.h, channels: 4 } });

  /**
   * Splits a nano-banana planche into its `count` separate poses (found as connected blobs,
   * not by dividing the width into equal cells — poses never fill their "cell" the same way,
   * and equal slicing was cutting into a neighbour or clipping a wide pose). Each pose is
   * cropped independently to its own alpha box (small `margin`) and scaled to `frameHeight`;
   * since the box always hugs the drawing tightly, its bottom edge lands on the same output
   * row for every frame, so the poses stay on a common footline without needing a shared union
   * crop. Packed into ONE horizontal row, `gap` px of transparent space between frames.
   */
  async function faunaRow({ id, count, frameHeight, out, margin = 3, pad = 6, gap = 10, findGap = 6, minArea = 60, step = 4 }) {
    const img = await loadKeyed(find(id));
    const objects = findObjects(img, { gap: findGap, minArea, step });
    if (objects.length !== count) {
      throw new Error(`${out} (${id}) : ${objects.length} bêtes détectées, ${count} attendues : ${objects.map((b) => `[${b.minX},${b.minY} ${b.maxX - b.minX}x${b.maxY - b.minY}]`).join(" ")}`);
    }
    const base = rawImage(img);
    const frames = [];
    for (const b of objects) {
      const left = Math.max(0, b.minX - margin), top = Math.max(0, b.minY - margin);
      const width = Math.min(img.w - left, b.maxX - b.minX + 1 + margin * 2);
      const height = Math.min(img.h - top, b.maxY - b.minY + 1 + margin * 2);
      const scale = frameHeight / height;
      const w = Math.max(1, Math.round(width * scale));
      const buf = await base.clone().extract({ left, top, width, height }).resize(w, frameHeight).png().toBuffer();
      frames.push({ buf, w });
    }
    return packEqualCells(sharp, frames, frameHeight, out, pad, gap);
  }

  /**
   * Packs pre-scaled frames (each already resized to `frameHeight`, of varying width) into
   * ONE horizontal row of EQUAL-WIDTH cells (Sprite3D's `hframes` needs `largeur / N`, see the
   * note at the top of this file): the cell width is the widest frame plus `pad` margin, and
   * every narrower frame is centred in its cell instead of left-packed at its own width.
   */
  async function packEqualCells(sharp, frames, frameHeight, out, pad, gap, note = "") {
    const cellW = Math.max(...frames.map((f) => f.w)) + gap;
    const fw = cellW, fh = frameHeight + pad * 2;
    const composites = frames.map((f, i) => ({ input: f.buf, left: i * fw + Math.round((fw - f.w) / 2), top: pad }));
    await sharp({ create: { width: fw * frames.length, height: fh, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
      .composite(composites).png({ compressionLevel: 9 }).toFile(out);
    return `${out} (${frames.length} cases égales de ${fw}x${fh}${note})`;
  }

  const FAUNA_DIR = `${OUT}/fauna`;
  // [fauna id, nano-banana source id, N cases, frameHeight, options éventuelles]
  const FAUNA = [
    ["moustique", "pasfbe", 2, 90],
    ["libellule", "i6jmmr", 2, 96],
    ["crabe", "pdvmlm", 4, 80],
    ["lezard", "dbcc0b", 4, 70],
    ["scorpion", "xiw2xg", 4, 76],
    ["scarabee", "cvdn8f", 2, 60],
    ["grenouille", "bohthw", 3, 90],
    ["poisson_saut", "92dgq6", 4, 96, { findGap: 2, margin: 2 }], // éclaboussures proches du corps : fusion réduite
    ["banc", "yvgzgu", 2, 90, { findGap: 14, minArea: 40 }], // groupe de poissons serrés : fusionne tout le banc en 1 blob/case
    ["meduse", "qqlias", 4, 130, { findGap: 10 }],
    ["mammifere", "9d1rk2", 4, 70],
    ["feuille", "drm2ko", 3, 60],
    // Silhouettes/oiseaux de vol : planches refaites en grille 2x2 très espacée (grande marge
    // magenta entre les poses) après un premier essai en rangée 1x4 qui rognait les ailes contre
    // le bord de leur case (envergure complète plus large qu'un quart d'image) — la détection de
    // blobs suffit maintenant, plus besoin de repli par colonnes.
    ["ptero_vol", "q3a0k9", 4, 110],
    ["ichthyornis", "2w2cek", 4, 96],
  ];
  const jobs = FAUNA.map(([name, id, count, frameHeight, opts = {}]) =>
    [`${FAUNA_DIR}/${name}.png`, (out) => faunaRow({ id, count, frameHeight, out, ...opts })]);
  // Le Ptéranodon en vol (bestiaire des dinos, pas la faune) : même échelle de dessin que
  // pteranodon.png (frameHeight 190 dans cote.mjs / le JOBS principal) — garde une hauteur
  // cohérente pour que Wildlife/l'intégrateur puisse le poser à côté de l'espèce au sol. Même
  // refonte en grille 2x2 très espacée (référence pteranodon.png + sa source, envergure complète
  // jamais rognée).
  jobs.push([`${OUT}/dinos/pteranodon_vol.png`, (out) => faunaRow({ id: "keilcf", count: 4, frameHeight: 190, out })]);
  return jobs;
};
