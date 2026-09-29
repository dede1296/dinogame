// Chapitre 6 — Les Monts Gelés (bestiaire, décors, textures de sol, Bertille, combats, icônes).
// Espèces : mêmes méthode que cote.mjs / especes_marais_desert.mjs (nano-banana édite une planche
// existante en référence de style/grille ; anatomie réelle donnée dans chaque prompt, vérifiée
// image par image avant d'accepter). Vues face/dos ajoutées dans une 2de passe (FACE_DOS), une fois
// les tailles de sortie des planches de profil mesurées par un premier passage de process-art.mjs.
import fs from "node:fs";
import path from "node:path";

export default ({ sheet, props, icons, seamless, sharp, find, OUT }) => {
  // [name, source id, frameHeight] — profile sheets (3x2 : 3 pas de marche, repos, repos 2, attaque).
  const PROFILES = [
    // Pachyrhinosaurus : corrigé une fois (mz96zk) pour effacer les petites cornes frontales et
    // marquer la bosse nasale plate — nano-banana a peu bougé (garde une bosse sur la joue plutôt
    // que sur le nez, et deux petites cornes au-dessus des yeux) : voir « À refaire ».
    ["pachyrhinosaurus", "mz96zk", 200],
    // edmontosaurus, leaellynasaura, minmi : plus bas (nano-banana a dessiné 3×3 au lieu de 3×2,
    // recomposées/nettoyées par recompose3x3to3x2 + dropEdgeFragments).
    ["nanuqsaurus", "kfm3cu", 215],
    ["cryolophosaure_titan", "vqdguw", 210],
  ];
  // [name, source id, frameHeight (profile - 2), cell [w, h] from the profile sheet's output]
  // Cell sizes filled in after `node tools/process-art.mjs pachyrhinosaurus edmontosaurus
  // leaellynasaura minmi nanuqsaurus cryolophosaure_titan` measured the profile outputs.
  const FACE_DOS = [
    ["pachyrhinosaurus", "2kxk34", 198, [223, 208]],
    ["edmontosaurus", "yaanxz", 218, [227, 228]],
    ["leaellynasaura", "cdsbtq", 148, [157, 158]],
    ["minmi", "ziixix", 143, [152, 153]],
    ["nanuqsaurus", "bp5aso", 213, [247, 223]],
    ["cryolophosaure_titan", "gy7c4b", 208, [222, 218]],
  ];
  const jobs = PROFILES.map(([name, id, frameHeight]) =>
    [`${OUT}/dinos/${name}.png`, (out) => sheet({ id, rows: 2, cols: 3, frameHeight, out })]);
  // edmontosaurus et minmi : nano-banana a dessiné 3×3 (9 poses) au lieu des 3×2 demandées, deux
  // fois de suite pour edmontosaurus (mx3yvh, retenté en 9xsb0x, encore 3×3) et une fois pour
  // minmi (em4m3v, retenté en a5fmgf, encore 3×3 — signalé par l'agent mécaniques à 11:42).
  // Plutôt que retenter une 3e fois, on découpe la planche telle qu'elle est (sheet() en 3×3,
  // alignement union sur les 9 cases) puis on recompose les 6 cases voulues en 3×2. leaellynasaura
  // (h6i5yf) est déjà en 3×2, pas besoin de ce recomposage.
  // Les 3 planches (leaellynasaura comprise) gardaient un éclat de la case voisine au bord
  // (museau/queue qui empiète, signalé par l'agent mécaniques à 12:04) : `dropEdgeFragments`
  // ne garde, par case, que le plus gros blob opaque connecté (le dino), efface le reste.
  jobs.push([`${OUT}/dinos/edmontosaurus.png`, async (out) => {
    const r = await recompose3x3to3x2({
      id: "9xsb0x", frameHeight: 220, out, sheet, sharp,
      // 3 pas de marche (rangée du haut) ; repos, repos 2 (rangée du milieu, gueule fermée) ;
      // attaque = (1,2), gueule ouverte, alerte — la case cabrée (2,2) a la tête tronquée en haut
      // (dessinée à cheval sur sa rangée source), évitée.
      pick: [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2]],
    });
    await dropEdgeFragments(out, 2, 3, sharp);
    return r + " (bords nettoyés)";
  }]);
  jobs.push([`${OUT}/dinos/minmi.png`, async (out) => {
    const r = await recompose3x3to3x2({
      id: "a5fmgf", frameHeight: 145, out, sheet, sharp,
      // La case (1,0) sort d'une teinte tan trop claire (défaut nano-banana) : évitée. Repos =
      // (1,1) et (2,0) (couleur correcte) ; attaque = (1,2), la queue qui fouette.
      pick: [[0, 0], [0, 1], [0, 2], [1, 1], [2, 0], [1, 2]],
    });
    await dropEdgeFragments(out, 2, 3, sharp);
    return r + " (bords nettoyés)";
  }]);
  jobs.push([`${OUT}/dinos/leaellynasaura.png`, async (out) => {
    const r = await sheet({ id: "h6i5yf", rows: 2, cols: 3, frameHeight: 150, out });
    await dropEdgeFragments(out, 2, 3, sharp);
    return r + " (bords nettoyés)";
  }]);
  for (const [name, id, frameHeight, cell] of FACE_DOS) {
    if (id === "TBD" || !cell) continue;
    jobs.push([`${OUT}/dinos/${name}_face_dos.png`, (out) => sheet({ id, rows: 2, cols: 4, frameHeight, cell, out })]);
  }
  // Aconit : Nanuqsaurus corrompu par Dame Suie (mêmes veines d'ambre noir que les autres
  // "*_corrompu.png"), édité depuis la planche de profil déjà corrigée du Nanuqsaurus. TBD tant
  // que ce 2d passage n'a pas tourné.
  const NANUQSAURUS_CORROMPU_ID = "efdksq";
  if (NANUQSAURUS_CORROMPU_ID !== "TBD") {
    jobs.push([`${OUT}/dinos/nanuqsaurus_corrompu.png`, (out) => sheet({ id: NANUQSAURUS_CORROMPU_ID, rows: 2, cols: 3, frameHeight: 215, out })]);
  }

  // Bertille (planche de marche 4x4, comme les autres personnages), 1,60 m (data/heights.gd).
  // Refaite une fois (oup5ib) : parka doublée de DUVET plutôt que de fourrure (demande de
  // l'utilisateur, 29/09 : pas de mammifères sur l'île) ; le premier essai (h43o4k) disait
  // « fourrure » dans le prompt.
  jobs.push([`${OUT}/characters/bertille.png`, (out) => sheet({ id: "oup5ib", rows: 4, cols: 4, frameHeight: 176, out })]);

  // Le vêtement chaud (AJOUT du plan, 29/09) : manteau de duvet de Chloé, à pied et en selle
  // (Region.cold, actors/outfits.gd, agent mécaniques), icône côté objet (agent histoire).
  // 29/09 (intégrateur) : nano-banana n'a pas dessiné les pas au même endroit de leurs cases (jusqu'à
  // 25 px d'une image à l'autre : Chloé tressautait en marchant) : chaque image est recalée sur le
  // centre de celle de chloe.png à la même place (alignWithBase).
  jobs.push([`${OUT}/characters/chloe_manteau.png`, async (out) => {
    const done = await sheet({ id: "zwx4i5", rows: 4, cols: 4, frameHeight: 176, out });
    await alignWithBase(out, `${OUT}/characters/chloe.png`, 4, 4, sharp);
    return done + " — recalée sur chloe.png";
  }]);
  // 2 essais : q8lic4 n'ajoutait pas vraiment de manteau (à peine plus épais que le gilet) ;
  // f6i1dy (avec chloe_manteau.png en référence de couleurs) a bien le manteau ambre/kaki, mais
  // nano-banana a dessiné 2 rangées de 4 (comme POSE4 dans variantes.mjs) : la rangée du haut sans
  // monture (juste debout, mesure de référence, inutile), la rangée du bas EN SELLE (celle qu'on
  // veut) — on ne garde que la rangée du bas avant de la couper en 1×4.
  // 29/09 (intégrateur) : f6i1dy dessinait un Parasaurolophus sous Chloé (elle aurait été assise sur
  // deux dinos) ; refait depuis la source de chloe_selle.png elle-même (jeyusd : mêmes poses, à
  // califourchon sur rien) avec chloe_manteau en référence de couleurs : 08rxw6, une rangée de 4.
  jobs.push([`${OUT}/characters/chloe_selle_manteau.png`, (out) =>
    sheet({ id: "08rxw6", rows: 1, cols: 4, frameHeight: 220, cell: [150, 228], out })]);
  jobs.push([`${OUT}/ui/manteau_duvet.png`, () => icons({ id: "4mibvb", cols: 1, rows: 1, size: 160, outDir: `${OUT}/ui`, names: ["manteau_duvet"] })]);
  // Poses en manteau demandées par l'agent histoire (29/09) : accroupi (Grelot, Roc au col) et
  // mains tendues (les dormeurs de glace) ; `Outfits.POSES["chloe"]["coat"]` les prend d'elle-même.
  // chloe_main : nmxyhq est déjà 2×4 (comme chloe_main.png lui-même, union crop, pas de `cell`).
  jobs.push([`${OUT}/characters/chloe_manteau_main.png`, (out) => sheet({ id: "nmxyhq", rows: 2, cols: 4, frameHeight: 176, out })]);
  // chloe_accroupie : z841uv est 3×4 (nano-banana a encore ajouté une rangée, les 3 identiques) au
  // lieu de 2×4 — on ne garde que la 1re rangée, dupliquée (comme la 2e rangée, doublon inutilisé,
  // de chloe_accroupie.png lui-même) pour retomber sur le même appel `cell: [123, 184]`.
  jobs.push([`${OUT}/characters/chloe_manteau_accroupie.png`, async (out) => {
    const id = await oneRowDuplicated(sharp, find, "z841uv", "chloe-manteau-accroupie", 3, 0);
    return sheet({ id, rows: 2, cols: 4, frameHeight: 156, cell: [123, 184], out });
  }]);

  // Maïa's own coat (29/09, demande de l'utilisateur : le texte des Monts dit « un grand manteau »).
  // Same idea as chloe_manteau (edited from her own maia.png, same grid, then recalée sur maia.png
  // with alignWithBase — nano-banana drew this one's steps well aligned already, but the check is
  // run regardless), a different colour from Chloé's amber coat (petrol/teal here), hood trimmed in
  // down (no fur), her red headband and neckerchief kept. 7o6wnu : clean 4×4, correctly ordered.
  jobs.push([`${OUT}/characters/maia_manteau.png`, async (out) => {
    const done = await sheet({ id: "7o6wnu", rows: 4, cols: 4, frameHeight: 176, out });
    await alignWithBase(out, `${OUT}/characters/maia.png`, 4, 4, sharp);
    return done + " — recalée sur maia.png";
  }]);
  // maia_manteau_assise : same finition-B technique as variantes.mjs's SITTING/orderViews (row 1 =
  // the seated pose in 4 views, row 2 = her standing, drawn only for scale), redone locally here
  // (this file's own job, not variantes.mjs) with EXPLICIT boxes instead of grid arithmetic: dsq96c
  // drew row 1 correctly ordered (front, left, right, back — no reordering needed) but row 2 with 6
  // standing repeats instead of 4 (not a uniform column count with row 1), so a uniform cols=4
  // extract() would misalign every cell. maiaManteauAssiseSource() below picks the 4 seated crops and
  // one standing crop (repeated; its own view doesn't matter, it only sets the scale) into a fresh
  // uniform 4×2 canvas that sheet() can cut normally.
  jobs.push([`${OUT}/characters/maia_manteau_assise.png`, async (out) => {
    const id = await maiaManteauAssiseSource(sharp, find, "dsq96c");
    return sheet({ id, rows: 2, cols: 4, frameHeight: 173.5, cell: [240, 184], out });
  }]);

  // Hélène's mittens (29/09, demande de l'utilisateur) : icône seule, même méthode que manteau_duvet.
  jobs.push([`${OUT}/ui/moufles.png`, () => icons({ id: "mapfp3", cols: 1, rows: 1, size: 160, outDir: `${OUT}/ui`, names: ["moufles"] })]);

  // La fiole vide de Dame Suie (29/09, demande de l'utilisateur) : étiquette « Givre n° 3 » à peine
  // lisible. ttezpz : 2e passe (continue_editing) après un 1er essai (6hq60c) à l'étiquette trop nette.
  // scale : world/prop.gd (KINDS.fiole_vide, mesurée après un 1er passage de ce job — voir son
  // commentaire, la formule K≈45 de docs/direction-artistique.md « Tailles réelles »).
  jobs.push([`${OUT}/props/fiole_vide.png`, () => props({ id: "ttezpz", scale: 0.5, outDir: `${OUT}/props`, names: ["fiole_vide"] })]);

  // Textures de sol (vues de dessus, sans ombre, rendues raccordables par seamless()).
  const GROUND = [
    ["neige", "80o5n3"],
    ["neige_chemin", "pu5og1"],
    ["glace", "camjqw"],
    ["falaise_neige", "p9ucsc"],
    ["sol_grotte_glace", "1x9q8i"],
  ];
  for (const [name, id] of GROUND) {
    jobs.push([`${OUT}/ground/${name}.png`, (out) => seamless({ id, size: 512, out })]);
  }

  // Décors (2 planches nano-banana, 5 objets bien séparés chacune, disposés en 3 haut / 2 bas).
  // bloc_glace : intérieur rendu semi-transparent après découpe (dino endormi visible à travers) —
  // pixels clairs (glace) assombris en alpha, contour brun foncé gardé opaque pour une silhouette
  // nette.
  jobs.push([`${OUT}/props/bloc_glace.png`, async (out) => {
    const r = await props({
      id: "gmmgda", scale: 0.5, outDir: `${OUT}/props`,
      // Explicit boxes (measured on the 2400x1792 sheet): auto-detection either merged every
      // object into one blob (gap 2 and 6: a bounding-box gap of 2 downsampled px between the
      // door-like top row and the bottom row) or split a couple of them with a stray melt-drip
      // blob (gap -1) — a hand-picked box per object (+30 px margin) sidesteps both.
      boxes: [[46, 78, 792, 816], [838, 306, 664, 520], [1470, 54, 916, 876], [278, 946, 900, 816], [1370, 942, 824, 792]],
      names: ["bloc_glace", "oeufs_glace", "mur_glace", "stalactites_glace", "cristaux_glace"],
    });
    await makeInteriorTranslucent(out, sharp);
    return r + " (bloc_glace : intérieur semi-transparent)";
  }]);
  jobs.push([`${OUT}/props/porte_givre.png`, () => props({
    id: "1ateu7", scale: 0.5, gap: -1, outDir: `${OUT}/props`,
    names: ["porte_givre_biais", "traineau_suie", "fioles_suie", "abri_roche", "statue_cryolophosaure"],   // (the door: retouches_ch6.mjs since 29/09, this one was drawn at an angle)
  })]);

  // Touffes des cases « herbes hautes » des Monts (WorldView.ZONE_TUFT) : hautes_herbes.png
  // redessinée en toundra (brins paille et olive, pointes givrées, neige au pied), même cadrage
  // (agent mécaniques, 29/09). À peu près la taille de hautes_herbes.png (233 x 217).
  jobs.push([`${OUT}/props/herbes_toundra.png`, () => props({
    id: "51xph5", scale: 0.35, outDir: `${OUT}/props`, names: ["herbes_toundra"],
  })]);

  // Fonds de combat (même cadrage que battle/cote.jpg : redessinés dessus, décor de combat gardé).
  const BATTLE = [
    ["monts", "i8uyy7"],
    ["grotte_glace", "294j3q"],
    ["sanctuaire_givre", "yq8cs3"],
  ];
  for (const [name, id] of BATTLE) {
    jobs.push([`${OUT}/battle/${name}.jpg`, (out) => sharp(find(id)).resize(1920, 1072, { fit: "cover" }).jpeg({ quality: 86, mozjpeg: true }).toFile(out).then(() => out)]);
  }

  // Icônes (sceau des Monts + 2 badges météo), une planche 1x3.
  jobs.push([`${OUT}/ui/monts_icones`, () => icons({ id: "7byhss", cols: 3, rows: 1, size: 160, outDir: `${OUT}/ui`,
    names: ["sceau_monts", "meteo_neige", "meteo_blizzard"] })]);

  return jobs;
};

/** A profile sheet nano-banana drew as 3×3 (9 poses) instead of the requested 3×2: `sheet()`
 * still cuts and union-aligns it cleanly as 3×3 (rows/cols matching what was actually drawn), then
 * this picks 6 of those 9 cells (`pick`: [[row, col], …], 6 entries, in reading order for the new
 * 3×2 sheet) and recomposites them into the normal 3×2 canvas. */
async function recompose3x3to3x2({ id, frameHeight, pick, out, sheet, sharp }) {
  const tmp = out.replace(/\.png$/, "_tmp9x9.png");
  await sheet({ id, rows: 3, cols: 3, frameHeight, out: tmp });
  const meta = await sharp(tmp).metadata();
  const fw = meta.width / 3, fh = meta.height / 3;
  const parts = await Promise.all(pick.map(async ([r, c], i) => ({
    input: await sharp(tmp).extract({ left: c * fw, top: r * fh, width: fw, height: fh }).png().toBuffer(),
    left: (i % 3) * fw, top: Math.floor(i / 3) * fh,
  })));
  await sharp({ create: { width: fw * 3, height: fh * 2, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite(parts).png({ compressionLevel: 9 }).toFile(out);
  fs.unlinkSync(tmp);
  return `${out} (recomposé 3×3 → 3×2 depuis ${id}, cases [${pick.map(([r, c]) => r + "," + c).join("] [")}])`;
}

/** A grid sheet where each cell may carry a stray edge fragment of its neighbour (a snout, a
 * tail tip crossing the cell boundary in the source, kept by the union crop): per cell, keeps
 * only the largest 4-connected blob of opaque pixels and clears every other one (same idea as
 * process-art.mjs's own keepLargestBlob, not exported, so redone here per grid cell). */
async function dropEdgeFragments(file, rows, cols, sharp) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const w = info.width, h = info.height, cw = w / cols, ch = h / rows;
  for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) {
    const x0 = Math.round(c * cw), x1 = Math.round((c + 1) * cw);
    const y0 = Math.round(r * ch), y1 = Math.round((r + 1) * ch);
    const cw2 = x1 - x0, ch2 = y1 - y0;
    const label = new Int32Array(cw2 * ch2).fill(-1);
    const sizes = [];
    for (let s = 0; s < cw2 * ch2; s++) {
      const gx = x0 + (s % cw2), gy = y0 + ((s / cw2) | 0);
      if (label[s] >= 0 || data[(gy * w + gx) * 4 + 3] < 24) continue;
      const id = sizes.length;
      let size = 0;
      const stack = [s];
      label[s] = id;
      while (stack.length) {
        const j = stack.pop(), lx = j % cw2, ly = (j / cw2) | 0;
        size++;
        for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
          const nx = lx + dx, ny = ly + dy;
          if (nx < 0 || ny < 0 || nx >= cw2 || ny >= ch2) continue;
          const k = ny * cw2 + nx;
          const gx2 = x0 + nx, gy2 = y0 + ny;
          if (label[k] >= 0 || data[(gy2 * w + gx2) * 4 + 3] < 24) continue;
          label[k] = id;
          stack.push(k);
        }
      }
      sizes.push(size);
    }
    if (sizes.length <= 1) continue;
    const keep = sizes.indexOf(Math.max(...sizes));
    for (let s = 0; s < cw2 * ch2; s++) {
      if (label[s] >= 0 && label[s] !== keep) {
        const gx = x0 + (s % cw2), gy = y0 + ((s / cw2) | 0);
        data[(gy * w + gx) * 4 + 3] = 0;
      }
    }
  }
  await sharp(data, { raw: { width: w, height: h, channels: 4 } }).png({ compressionLevel: 9 }).toFile(file);
}

/** nano-banana drew more rows than asked (all identical, no extra info): crops out row
 * `rowIndex` of `totalRows` and duplicates it into a 2-row canvas, so the result can go through
 * the same `sheet({rows: 2, cols: 4, cell: […]})` call as the base sheet (its own unused 2nd row
 * duplicate, e.g. chloe_accroupie.png). */
async function oneRowDuplicated(sharp, find, id, name, totalRows, rowIndex) {
  const src = find(id);
  const out = path.join(path.dirname(src), `derived-${name}.png`);
  if (!fs.existsSync(out)) {
    const { width, height } = await sharp(src).metadata();
    const rh = Math.round(height / totalRows);
    const row = await sharp(src).extract({ left: 0, top: rowIndex * rh, width, height: rh }).png().toBuffer();
    await sharp({ create: { width, height: rh * 2, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
      .composite([{ input: row, left: 0, top: 0 }, { input: row, left: 0, top: rh }])
      .png().toFile(out);
  }
  return path.basename(out, ".png");
}

/** nano-banana drew an unrequested 2nd row (a standing reference, like POSE4 in variantes.mjs):
 * saves just the bottom half of the source as a derived file (found by its name, no id needed
 * again) and returns that name for `sheet()`/`find()`. */
async function bottomRowOnly(sharp, find, id, name) {
  const src = find(id);
  const out = path.join(path.dirname(src), `derived-${name}.png`);
  if (!fs.existsSync(out)) {
    const { height } = await sharp(src).metadata();
    await sharp(src).extract({ left: 0, top: Math.floor(height / 2), width: (await sharp(src).metadata()).width, height: height - Math.floor(height / 2) }).png().toFile(out);
  }
  return path.basename(out, ".png");
}

/** maia_manteau_assise (29/09): builds a fresh, uniform 4×2 canvas from explicit crop boxes measured
 * on the 2752×1536 source (dsq96c) — row 1 = the 4 seated views (already in the wanted order, front/
 * left/right/back, no reordering needed), row 2 = one standing crop, reused in every column (only its
 * height matters, it just sets the scale, like variantes.mjs's SITTING row 2). Padded 30 px per box
 * (clamped to the sheet) so anti-aliased edges/fur trim are not clipped. */
async function maiaManteauAssiseSource(sharp, find, id) {
  const src = find(id);
  const out = path.join(path.dirname(src), "derived-vues-maia-manteau-assise.png");
  if (fs.existsSync(out)) return path.basename(out, ".png");
  const { width: W, height: H } = await sharp(src).metadata();
  const PAD = 30;
  const pad = ([x0, y0, x1, y1]) => [Math.max(0, x0 - PAD), Math.max(0, y0 - PAD), Math.min(W, x1 + PAD), Math.min(H, y1 + PAD)];
  const SEATED = [[80, 28, 472, 728], [768, 40, 1304, 712], [1448, 40, 1992, 712], [2272, 28, 2676, 716]].map(pad);
  const STANDING = pad([64, 776, 420, 1512]);
  const crop = async ([x0, y0, x1, y1]) => sharp(src).extract({ left: x0, top: y0, width: x1 - x0, height: y1 - y0 }).png().toBuffer();
  const cw = 700, ch = 740;   // (a canvas cell wide enough for every crop; sheet() re-crops to content anyway)
  const place = async (buf, col, row) => {
    const { width, height } = await sharp(buf).metadata();
    return { input: buf, left: col * cw + Math.round((cw - width) / 2), top: row * ch + Math.round((ch - height) / 2) };
  };
  const composites = [];
  for (const [i, box] of SEATED.entries()) composites.push(await place(await crop(box), i, 0));
  const standBuf = await crop(STANDING);
  for (let i = 0; i < 4; i++) composites.push(await place(standBuf, i, 1));
  await sharp({ create: { width: cw * 4, height: ch * 2, channels: 3, background: { r: 255, g: 0, b: 255 } } })
    .composite(composites).png().toFile(out);
  return path.basename(out, ".png");
}

/** bloc_glace: darkens the alpha of the pale icy fill (keeps the dark outline opaque), so a
 * sleeping dino placed behind shows dimly through the block (docs/direction-artistique.md,
 * decor list for the Monts). */
async function makeInteriorTranslucent(file, sharp) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const ALPHA_FACTOR = 0.6, DARK_LUM = 90;
  for (let i = 0; i < data.length; i += 4) {
    const a = data[i + 3];
    if (a === 0) continue;
    const lum = (data[i] + data[i + 1] + data[i + 2]) / 3;
    if (lum >= DARK_LUM) data[i + 3] = Math.round(a * ALPHA_FACTOR);
  }
  await sharp(data, { raw: { width: info.width, height: info.height, channels: 4 } })
    .png({ compressionLevel: 9 }).toFile(file);
}


// Shifts each cell's drawing of `file` sideways so its centre (of its opaque pixels) sits where the
// drawing of the same cell of `base` sits (a walking sheet whose steps were drawn off-centre: the
// character would jitter left and right while walking). Heights are left as they are.
async function alignWithBase(file, base, rows, cols, sharp) {
  const centres = async (f) => {
    const { data, info } = await sharp(f).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    const cw = info.width / cols, ch = info.height / rows, out = [];
    for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) {
      let sx = 0, n = 0;
      for (let y = Math.floor(r * ch); y < (r + 1) * ch; y++) for (let x = Math.floor(c * cw); x < (c + 1) * cw; x++)
        if (data[(y * info.width + x) * 4 + 3] > 128) { sx += x - c * cw; n++; }
      out.push(n ? sx / n / cw : 0.5);   // (as a share of the cell's width)
    }
    return { out, info, data };
  };
  const want = (await centres(base)).out;
  const { out: have, info, data } = await centres(file);
  const cw = info.width / cols, ch = info.height / rows;
  const moved = Buffer.alloc(data.length);   // (transparent)
  for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) {
    const i = r * cols + c, dx = Math.round((want[i] - have[i]) * cw);
    for (let y = Math.floor(r * ch); y < (r + 1) * ch; y++) for (let x = Math.floor(c * cw); x < (c + 1) * cw; x++) {
      const tx = x + dx;
      if (tx < Math.floor(c * cw) || tx >= (c + 1) * cw) continue;   // (stays inside its cell)
      data.copy(moved, (y * info.width + tx) * 4, (y * info.width + x) * 4, (y * info.width + x) * 4 + 4);
    }
  }
  await sharp(moved, { raw: { width: info.width, height: info.height, channels: 4 } }).png({ compressionLevel: 9 }).toFile(file + ".tmp.png");
  const fs = await import("node:fs");
  fs.renameSync(file + ".tmp.png", file);
}
