// Passe de finition des chapitres 1 à 5 (29/09), agent A : objets tenus pendant une scène,
// décors fixes manquants, trois petites bêtes. Voir vivants/PLAN_finition.md (scratchpad) et
// docs/direction-artistique.md « Détails vivants ». Toutes les planches : nano-banana
// (edit_image), une planche existante du jeu en référence de style, fond magenta.
//
// `derived-finition-corde-nid.jpg` : nano-banana a peint une ombre portée floue sous la corde et
// le nid vide (deux fois demandé, deux refus de l'effacer) ; peinte en magenta à la main dans une
// copie (docs/direction-artistique.md convention « À refaire »), rien d'autre changé.
//
// Faune (contrat de vivants/PLAN.md : une seule rangée de N cases égales, fond transparent, vu de
// dessus/profil tourné vers la droite) : mêmes helpers que tools/art-jobs/faune.mjs (`faunaRow`,
// recopié ici en local : process-art.mjs n'exporte pas `findObjects`/la détection de blobs).
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

export default ({ sharp, props, find, OUT }) => {
  async function loadKeyed(file) {
    const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    keyMagenta(data);
    return { data, w: info.width, h: info.height };
  }
  const rawImage = (img) => sharp(img.data, { raw: { width: img.w, height: img.h, channels: 4 } });

  async function packEqualCells(frames, frameHeight, out, pad, gap) {
    const cellW = Math.max(...frames.map((f) => f.w)) + gap;
    const fw = cellW, fh = frameHeight + pad * 2;
    const composites = frames.map((f, i) => ({ input: f.buf, left: i * fw + Math.round((fw - f.w) / 2), top: pad }));
    await sharp({ create: { width: fw * frames.length, height: fh, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
      .composite(composites).png({ compressionLevel: 9 }).toFile(out);
    return `${out} (${frames.length} cases égales de ${fw}x${fh})`;
  }

  /** Same contract as faune.mjs's faunaRow (bêtes détectées en blobs, pas en grille). */
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
    return packEqualCells(frames, frameHeight, out, pad, gap);
  }

  const FAUNA_DIR = `${OUT}/fauna`;
  return [
    // 1. Objets tenus pendant une scène (props, pas posés dans les zones ; l'intégrateur les fait
    // apparaître) : la boîte cabossée de Griffe-Grise (foret.gd:301), le piège à mâchoires
    // (foret.gd:387), le tube de cuivre de la Voix (marais.gd:586), la boîte ronde du Vieux
    // Rempart (desert.gd:560), le registre de bord des Grottes marines (cote_grottes.gd:293).
    [`${OUT}/finition/objets_tenus`, () => props({
      id: "edited-2026-09-29T07-47-46-032Z-kyfvlk", scale: 0.5, outDir: `${OUT}/props`,
      names: ["boite_fer_blanc", "piege_machoires", "tube_cuivre", "boite_ronde", "registre"],
    })],
    // roue_chariot : desert_sanctuaire.gd charge déjà assets/art/props/roue_chariot.png s'il
    // existe (const PAINTED_WHEEL) et l'utilise à la place de _wheel_picture (dessinée par code) :
    // rien à câbler, juste fournir l'image (carrée, la roue vue de face, cerclée de fer).
    [`${OUT}/finition/roue_chariot`, () => props({
      id: "edited-2026-09-29T07-48-56-340Z-e3k9ro", scale: 1.0, gap: 40, outDir: `${OUT}/props`,
      names: ["roue_chariot"],
    })],
    // 2. Décors fixes manquants : le nid de Dimorphodons (petit, falaise des Plaines), le
    // buisson-nid de Chipie (remplace le "buisson" provisoire de tools/zones/plaines.gd), le
    // rocher en forme d'œuf (remplace le "rocher" provisoire), la frise de masques d'os (au-dessus
    // de la porte d'ambre du temple, tools/zones/marais.gd).
    [`${OUT}/finition/decor_falaises`, () => props({
      id: "edited-2026-09-29T07-48-02-595Z-fz3vxo", scale: 0.5, outDir: `${OUT}/props`,
      names: ["nid_dimorphodon", "buisson_nid", "rocher_oeuf", "frise_masques_plaque"],   // (the frieze: art-jobs/frise.mjs since 29/09)
    })],
    // La vieille corde qui pend de la falaise (Sanctuaire des Vents, desert_sanctuaire.gd:677) et
    // le nid de tortues VIDE (Côte, cote_lagon.gd:329 : l'intégrateur fera l'échange une fois
    // "tortues_sauvees"). derived-… : voir la note en tête de fichier (ombre portée effacée).
    [`${OUT}/finition/corde_nid_vide`, () => props({
      id: "derived-finition-corde-nid", scale: 0.5, outDir: `${OUT}/props`,
      names: ["corde_falaise", "nid_tortue_vide"],
    })],
    // Le Cabinet : la lanterne à son crochet (état normal) et le crochet vide (elle a disparu :
    // plaines.gd:394, foret_fin.gd:757 ; tools/zones/cabinet.gd pose les deux, un flagged_prop.gd
    // maison choisit lequel montrer selon "roc_dehors"), et la bouilloire sur son petit poêle
    // (cote.gd:699).
    [`${OUT}/finition/cabinet`, () => props({
      id: "edited-2026-09-29T07-49-23-871Z-7v7pi6", scale: 0.5, outDir: `${OUT}/props`,
      names: ["lanterne_crochet", "crochet_vide", "bouilloire_poele"],
    })],
    // 3. Petites bêtes (contrat faune de vivants/PLAN.md, world/view3d/wildlife.gd) : escargot de
    // sous-bois (4 cases), file de fourmis vue de dessus (2 cases), petite ammonite vivante qui
    // nage (4 cases). L'intégrateur les ajoute à data/wildlife_db.gd.
    [`${FAUNA_DIR}/escargot.png`, (out) => faunaRow({ id: "edited-2026-09-29T07-48-28-017Z-1ci70l", count: 4, frameHeight: 60, out, findGap: 1 })],
    [`${FAUNA_DIR}/fourmis.png`, (out) => faunaRow({ id: "edited-2026-09-29T07-48-37-407Z-l1hu58", count: 2, frameHeight: 40, out, findGap: 3 })],
    [`${FAUNA_DIR}/ammonite.png`, (out) => faunaRow({ id: "edited-2026-09-29T07-48-48-700Z-t2qux8", count: 4, frameHeight: 90, out, findGap: 1 })],
  ];
};
