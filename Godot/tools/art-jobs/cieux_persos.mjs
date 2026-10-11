// Chapitre 7 — Les Cieux Éternels : Chloé en vol, Isaure sans masque, Maïa en tenue des Cieux.
// Chaque planche est éditée par nano-banana depuis la planche existante du personnage (silhouette,
// vêtements, cheveux gardés), jamais d'une page blanche (docs/sprites-mouvements.md).
const SHRINK = 0.75;   // échelle de Chloé en vol par rapport à sa pose en selle
const SEAT_PX = 68;    // point d'assise au-dessus du bas de la case (actors/saddle.gd)

export default ({ sheet, sharp, find, OUT }) => {
  const jobs = [];
  // Chloé en vol : mêmes cases que chloe_selle.png (1×4 : face, profil gauche, profil droit, dos,
  // cellule 150×228). 2e version (11/10, remarque de Greg : « mal assise, trop en avant, trop grande,
  // une jambe doit être cachée ») : éditée depuis chloe_selle / chloe_selle_manteau (même assise),
  // buste droit, mains sur deux poignées à hauteur de poitrine, queue de cheval au vent ; de profil une
  // seule jambe (l'autre est cachée par le corps du ptérosaure), de face et de dos une jambe de chaque
  // côté ; puis RÉDUITE de SHRINK autour du point d'assise (SEAT_PX de saddle.gd : 68 px au-dessus du
  // bas de la case), pour que Chloé (1,50 m) reste petite devant un ptérosaure.
  jobs.push([`${OUT}/characters/chloe_vol.png`, async (out) => {
    const done = await sheet({ id: "87z9r0", rows: 1, cols: 4, frameHeight: 220, cell: [150, 228], out });
    await shrinkAboutSeat(out, 4, SHRINK, SEAT_PX, sharp);
    return done + ` — réduite à ${SHRINK}`;
  }]);
  jobs.push([`${OUT}/characters/chloe_vol_manteau.png`, async (out) => {
    const done = await sheet({ id: "tfs02d", rows: 1, cols: 4, frameHeight: 220, cell: [150, 228], out });
    await shrinkAboutSeat(out, 4, SHRINK, SEAT_PX, sharp);
    return done + ` — réduite à ${SHRINK}`;
  }]);
  // Isaure sans masque (la scène de l'Arche du vent) : éditée depuis la planche du Masque (masque.png :
  // même cape sombre, mêmes pas) avec isaure.png en référence du visage ; capuche rabattue, visage nu,
  // calme et fatigué ; 2e version (6vxe57, 11/10 : visage de la mi-quarantaine, cernes légers, rides fines,
  // mèches grises ; l'essai plus poussé uhcsmz faisait 65 ans) ; 4×4 propre, profils dans le bon ordre. Recalée sur masque.png (pas).
  jobs.push([`${OUT}/characters/isaure_sans_masque.png`, async (out) => {
    const done = await sheet({ id: "bdwuiz", rows: 4, cols: 4, frameHeight: 176, out });
    await alignWithBase(out, `${OUT}/characters/masque.png`, 4, 4, sharp);
    return done + " — recalée sur masque.png";
  }]);
  // 1re version (visage trop enfantin, jugée à refaire le 11/10), gardée pour comparaison.
  jobs.push([`${OUT}/characters/isaure_sans_masque_v1.png`, async (out) => {
    const done = await sheet({ id: "vm0x0z", rows: 4, cols: 4, frameHeight: 176, out });
    await alignWithBase(out, `${OUT}/characters/masque.png`, 4, 4, sharp);
    return done + " — v1";
  }]);
  // Maïa en tenue des Cieux (manteau ciel de plumes et de laine), éditée depuis maia.png (zpx6bd).
  jobs.push([`${OUT}/characters/maia_arche.png`, async (out) => {
    const done = await sheet({ id: "zpx6bd", rows: 4, cols: 4, frameHeight: 176, out });
    await alignWithBase(out, `${OUT}/characters/maia.png`, 4, 4, sharp);
    return done + " — recalée sur maia.png";
  }]);
  // Isaure sans masque, assise (même mise en page que maia_manteau_assise : 2 × 4, cases 240 × 184, rangée 1 =
  // assise [face, gauche, droite, dos], rangée 2 = debout, étalon d'échelle, inutilisée). vrmeo8 : les deux
  // profils assis regardent à droite : le premier est retourné en miroir pour regarder à gauche.
  jobs.push([`${OUT}/characters/isaure_sans_masque_assise.png`, async (out) => {
    const id = await eraseGridLines(sharp, find, "l2zqu4", "isaure-assise", 4, 2);   // (3e version : visage cohérent ; la 2e = `_assise_v2.png`)
    const done = await sheet({ id, rows: 2, cols: 4, frameHeight: 173.5, cell: [240, 184], out });
    await mirrorCell(out, 1, 0, 4, 2, sharp);   // (le 2e dessin assis regardait à droite)
    return done + " — l2zqu4, grille effacée, profil gauche retourné";
  }]);
  return jobs;
};

/** Retourne en miroir la case (colonne c, rangée r) d'une planche de cols × rows cases égales. */
async function mirrorCell(file, c, r, cols, rows, sharp) {
  const buf = await sharp(file).png().toBuffer();
  const { width, height } = await sharp(buf).metadata();
  const cw = Math.round(width / cols), ch = Math.round(height / rows);
  const flipped = await sharp(buf).extract({ left: c * cw, top: r * ch, width: cw, height: ch }).flop().png().toBuffer();
  const blank = await sharp({ create: { width: cw, height: ch, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 1 } } }).png().toBuffer();
  const cleared = await sharp(buf).composite([{ input: blank, left: c * cw, top: r * ch, blend: "dest-out" }]).png().toBuffer();
  await sharp(cleared).composite([{ input: flipped, left: c * cw, top: r * ch }]).png({ compressionLevel: 9 }).toFile(file + ".tmp.png");
  (await import("node:fs")).renameSync(file + ".tmp.png", file);
}

/** Recale chaque case de `file` sur le centre de la même case de `base` (pas dessinés trop décalés :
 * le personnage tressauterait en marchant). Même méthode que monts.mjs. */
async function alignWithBase(file, base, rows, cols, sharp) {
  const centres = async (f) => {
    const { data, info } = await sharp(f).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    const cw = info.width / cols, ch = info.height / rows, out = [];
    for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) {
      let sx = 0, n = 0;
      for (let y = Math.floor(r * ch); y < (r + 1) * ch; y++) for (let x = Math.floor(c * cw); x < (c + 1) * cw; x++)
        if (data[(y * info.width + x) * 4 + 3] > 128) { sx += x - c * cw; n++; }
      out.push(n ? sx / n / cw : 0.5);
    }
    return { out, info, data };
  };
  const want = (await centres(base)).out;
  const { out: have, info, data } = await centres(file);
  const cw = info.width / cols, ch = info.height / rows;
  const moved = Buffer.alloc(data.length);
  for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) {
    const dx = Math.round((want[r * cols + c] - have[r * cols + c]) * cw);
    for (let y = Math.floor(r * ch); y < (r + 1) * ch; y++) for (let x = Math.floor(c * cw); x < (c + 1) * cw; x++) {
      const tx = x + dx;
      if (tx < Math.floor(c * cw) || tx >= (c + 1) * cw) continue;
      data.copy(moved, (y * info.width + tx) * 4, (y * info.width + x) * 4, (y * info.width + x) * 4 + 4);
    }
  }
  await sharp(moved, { raw: { width: info.width, height: info.height, channels: 4 } }).png({ compressionLevel: 9 }).toFile(file + ".tmp.png");
  (await import("node:fs")).renameSync(file + ".tmp.png", file);
}

/** Échange deux cases (colonnes a et b) d'une planche d'une seule rangée de `cols` cases égales. */
export async function swapCells(file, a, b, cols, sharp) {
  const buf = await sharp(file).png().toBuffer();
  const { width, height } = await sharp(buf).metadata();
  const cw = Math.round(width / cols);
  const order = Array.from({ length: cols }, (_, c) => (c === a ? b : c === b ? a : c));
  const parts = await Promise.all(order.map(async (src, dst) => ({
    input: await sharp(buf).extract({ left: src * cw, top: 0, width: cw, height }).png().toBuffer(), left: dst * cw, top: 0,
  })));
  await sharp({ create: { width: cw * cols, height, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite(parts).png({ compressionLevel: 9 }).toFile(file + ".tmp.png");
  (await import("node:fs")).renameSync(file + ".tmp.png", file);
}

/** Réduit de `k` le dessin de chaque case (une rangée de `cols`) autour du point d'assise (centre de la
 * case, `seat` px au-dessus du bas) : le bassin ne bouge pas, tout le reste se rapproche de lui. */
async function shrinkAboutSeat(file, cols, k, seat, sharp) {
  const buf = await sharp(file).png().toBuffer();
  const { width, height } = await sharp(buf).metadata();
  const cw = Math.round(width / cols);
  const sx = cw / 2, sy = height - seat;
  const parts = await Promise.all(Array.from({ length: cols }, async (_, c) => {
    const cell = await sharp(buf).extract({ left: c * cw, top: 0, width: cw, height }).png().toBuffer();
    const w = Math.round(cw * k), h = Math.round(height * k);
    return { input: await sharp(cell).resize(w, h).png().toBuffer(), left: c * cw + Math.round(sx - sx * k), top: Math.round(sy - sy * k) };
  }));
  await sharp({ create: { width, height, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite(parts).png({ compressionLevel: 9 }).toFile(file + ".tmp.png");
  (await import("node:fs")).renameSync(file + ".tmp.png", file);
}

/** nano-banana a tracé des traits noirs de grille entre les cases : peints en magenta (±7 px) dans une copie. */
async function eraseGridLines(sharp, find, srcId, name, cols, rows) {
  const src = find(srcId);
  const out = (await import("node:path")).join((await import("node:path")).dirname(src), `derived-sans-grille-${name}.png`);
  if ((await import("node:fs")).existsSync(out)) return (await import("node:path")).basename(out, ".png");
  const { data, info } = await sharp(src).removeAlpha().raw().toBuffer({ resolveWithObject: true });
  const W = info.width, H = info.height, HALF = 7;
  const paint = (x, y) => { const i = (y * W + x) * 3; data[i] = 255; data[i + 1] = 0; data[i + 2] = 255; };
  for (let c = 1; c < cols; c++) { const x0 = Math.round(c * W / cols); for (let x = x0 - HALF; x <= x0 + HALF; x++) for (let y = 0; y < H; y++) if (x >= 0 && x < W) paint(x, y); }
  for (let r = 1; r < rows; r++) { const y0 = Math.round(r * H / rows); for (let y = y0 - HALF; y <= y0 + HALF; y++) for (let x = 0; x < W; x++) if (y >= 0 && y < H) paint(x, y); }
  await sharp(data, { raw: { width: W, height: H, channels: 3 } }).png().toFile(out);
  return (await import("node:path")).basename(out, ".png");
}
