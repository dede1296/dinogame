import fs from "node:fs";
import path from "node:path";
// Clins d'œil à Jurassic Park (29/09, agent A) : 12 décors + l'icône ambre_moustique. Chaque image
// est l'édition d'une planche existante comme référence de style (même rendu peint, même trait),
// avec un fond magenta plat propre. Voir <scratchpad>/jp/PLAN.md (contrat des sortes) et
// docs/histoire.md pour la scène de chaque clin d'œil. Placement et textes : agent B.
export default ({ sheet, props, icons, sharp, find, OUT }) => [
  // Cabinet de Roc, 4 objets : la griffe fossile sur son socle (bureau de Roc), l'affiche
  // "Monsieur Ambre explique..." (murale, 3 cases de BD), le vieux feutre d'Hélène sur sa patère
  // (mural, près de la porte), la canne de Roc au pommeau d'ambre (moustique inclus, comme le
  // galet caché). Chacune éditée depuis un prop du Cabinet déjà en jeu pour le style.
  [`${OUT}/props/griffe_fossile`, () => props({ id: "2vug7b", scale: 0.5, outDir: `${OUT}/props`, names: ["griffe_fossile"] })],
  [`${OUT}/props/chapeau_helene`, () => props({ id: "rsp9bn", scale: 0.5, outDir: `${OUT}/props`, names: ["chapeau_helene"] })],
  // canne_roc : pommeau = œuf d'ambre orange transparent avec un moustique dedans (déjà bon depuis
  // la 1re passe, vérifié à l'œil le 29/09 pour la NOUVELLE DIRECTION — inchangé).
  [`${OUT}/props/canne_roc`, () => props({ id: "ej70pa", scale: 0.5, outDir: `${OUT}/props`, names: ["canne_roc"] })],
  // Le moustique dans l'ambre : le galet cache (Forêt) + l'icône ui/ambre_moustique.png (même
  // planche, recadrage carré serré pour l'icône).
  [`${OUT}/props/ambre_moustique`, () => props({ id: "kv2far", scale: 0.5, outDir: `${OUT}/props`, names: ["ambre_moustique"] })],
  [`${OUT}/ui/ambre_moustique`, () => icons({ id: "kv2far", cols: 1, rows: 1, size: 160, outDir: `${OUT}/ui`, names: ["ambre_moustique"] })],
  // Forêt : la vieille clôture de rondins brisée de l'intérieur (le panneau "Ne pas nourrir les
  // animaux" est un décor existant, posé à côté par l'agent B — pas dans cette image).
  [`${OUT}/props/cloture_brisee`, () => props({ id: "ea40rw", scale: 0.5, outDir: `${OUT}/props`, names: ["cloture_brisee"] })],
  // Havre-Doré : le coffre cerclé de fer devant le Comptoir de Ferréol, la table de cuisine (bocal
  // de biscuits ouvert) derrière l'Herboristerie de Pervenche.
  [`${OUT}/props/coffre_comptoir`, () => props({ id: "yu5f9h", scale: 0.5, outDir: `${OUT}/props`, names: ["coffre_comptoir"] })],
  [`${OUT}/props/table_cuisine`, () => props({ id: "x6s6qz", scale: 0.5, outDir: `${OUT}/props`, names: ["table_cuisine"] })],
  // Sanctuaire de Givre : la petite flaque de fonte ronde (les cercles qui tremblent, avant le Titan).
  // Recadrée sur la flaque et écrasée en 512×246 (debout en billboard, elle se lit « à plat »),
  // éclaircie de 15 % (elle se perdait sur la glace), puis détourée sur son rebord : le rocher
  // enneigé autour faisait un rectangle gris au sol. Il ne reste que l'eau et son liseré, sous les
  // ondes de PuddleRipple.
  [`${OUT}/props/flaque_ronde`, async () => {
    const done = await props({ id: "rqnwww", scale: 0.5, outDir: `${OUT}/props`, names: ["flaque_ronde"] });
    const file = `${OUT}/props/flaque_ronde.png`;
    const { width, height } = await sharp(file).metadata();
    const [top, bottom] = [0.15, 0.78];   // the band around the puddle (shares of the height)
    const flat = await sharp(file)
      .extract({ left: 0, top: Math.round(height * top), width, height: Math.round(height * (bottom - top)) })
      .resize(512, 246, { fit: "fill" })
      .modulate({ brightness: 1.15 }).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    const { data, info } = flat;
    // The rim, in shares of the picture (measured on it); `soft`: the last share of the radius fades.
    const [cx, cy, rx, ry, soft] = [0.497, 0.49, 0.372, 0.447, 0.03];
    for (let y = 0; y < info.height; y++) {
      for (let x = 0; x < info.width; x++) {
        const d = Math.hypot((x / info.width - cx) / rx, (y / info.height - cy) / ry);
        const i = (y * info.width + x) * 4 + 3;
        data[i] = Math.round(data[i] * Math.min(1, Math.max(0, (1 - d) / soft)));
      }
    }
    await sharp(data, { raw: info }).png({ compressionLevel: 9 }).toFile(file);
    return done + ` — écrasée à 55 %, éclaircie, détourée en ellipse (${info.width}×${info.height})`;
  }],

  // === NOUVELLE DIRECTION (29/09, 17h30) : références reconnaissables (allure, jamais logo/titre/visage). ===

  // creme_raser refaite : bombe de mousse à raser à spirale de barbier (réf. 1), bouchon bleu marine,
  // étiquette "MOUSSE A RASER" (sans accent : capitales sans accent, usage français courant en
  // packaging — pas un raté de rendu). Toujours ouverte par le fond, 3 fioles violettes dedans.
  [`${OUT}/props/creme_raser`, () => props({ id: "917fqc", scale: 0.5, outDir: `${OUT}/props`, names: ["creme_raser"] })],

  // affiche_ambre → affiche_adn : "Monsieur ADN" (réf. 2, corps en double hélice de perles), même
  // poster/mise en page à 3 cases que l'ancienne affiche, mêmes répliques françaises (accents bien
  // rendus au 1er essai). Remplace affiche_ambre au Cabinet (nouvelle sorte : world/prop.gd).
  [`${OUT}/props/affiche_adn`, () => props({ id: "kmzyqy", scale: 0.5, outDir: `${OUT}/props`, names: ["affiche_adn"] })],

  // barque_arbre → voiture_arbre : éditée depuis le grand arbre du Forêt (arbre_geant.png) lui-même,
  // pour être le même "grand arbre" (même hauteur réelle) qu'on croise déjà dans la zone — une vieille
  // voiture d'expédition (réf. 3 : livrée vert/jaune, coulures rouge sombre, pare-buffle noir, jantes
  // jaunes, numéro "04" peint à la main, AUCUN logo/texte de marque) coincée dans ses branches. La
  // barque du Marais est retirée (voir demandes.md : migration de sorte pour l'agent B).
  [`${OUT}/props/voiture_arbre`, async () => {
    const oldTree = await sharp(`${OUT}/props/arbre_geant.png`).metadata();
    const done = await props({ id: "pzottd", scale: 1, outDir: `${OUT}/props`, names: ["voiture_arbre"] });
    const newTree = await sharp(`${OUT}/props/voiture_arbre.png`).metadata();
    // Same real height as arbre_geant (scale 0.47 in world/prop.gd, docs K≈45 rule): scale so this
    // picture's trimmed height maps to the same metres as the old tree's trimmed height.
    const targetScale = (oldTree.height * 0.47) / newTree.height;
    const resized = await sharp(`${OUT}/props/voiture_arbre.png`)
      .resize(Math.round(newTree.width * targetScale / 1), Math.round(newTree.height * targetScale / 1)).png({ compressionLevel: 9 }).toBuffer();
    fs.writeFileSync(`${OUT}/props/voiture_arbre.png`, resized);
    return done + ` — recalée sur la hauteur réelle d'arbre_geant.png (scale finale ${targetScale.toFixed(4)}, world/prop.gd: scale=1.0 déjà appliqué dans l'image)`;
  }],

  // banderole_fouilles refaite : toile noire vierge (réf. 4 pour la couleur/le tissu), texte composé
  // ICI en SVG (rouge #E23123, contour or #F0B83E — palette du film fournie par l'utilisateur) pour
  // garantir l'accent de "RÉGNAIENT" (nano-banana l'avait raté en 1re passe sur ce même texte).
  [`${OUT}/props/banderole_fouilles`, async () => {
    const done = await props({ id: "3e9nk8", scale: 0.5, outDir: `${OUT}/props`, names: ["banderole_fouilles"] });
    await addBanderoleText(`${OUT}/props/banderole_fouilles.png`, sharp);
    return done + " — texte composé en SVG (accents garantis)";
  }],

  // crottes_triceratops (nouveau) : grosse pile de crottes, drôle pas dégoûtante (quête du Dr Sablier,
  // Plaines). Scale initiale 1.0, ajustée ci-dessous une fois la taille réelle mesurée (~0,9 m, la
  // hauteur d'une pile que Chloé fouille debout — pas de collision, comme un tas au sol).
  [`${OUT}/props/crottes_triceratops`, () => props({ id: "9ldhdx", scale: 0.5, outDir: `${OUT}/props`, names: [null, "crottes_triceratops"] })],

  // chevre (29/09) : la chèvre de Mémé Pervenche, volée par les sbires de Brac pour servir d'appât
  // au camp (clin d'œil : l'appât attaché… puis plus là). De profil vers la droite, collier de cuir
  // et bout de corde rongé au collier : la même image sert attachée au piquet et rentrée au Havre.
  [`${OUT}/props/chevre`, () => props({ id: "vtqzqm", scale: 0.5, outDir: `${OUT}/props`, names: ["chevre"] })],

  // triceratops_dort (30/09) : le Tricératops malade d'Élise Sablier, couché sur le flanc et
  // endormi (DinoSpecies.sleep_sheet). Posé dans une case de la taille de celles de sa planche
  // (305×208), les pattes sur la ligne de sol du projet (0,96 de la case) : le sprite garde ainsi
  // le même décalage au sol que ses autres images.
  [`${OUT}/dinos/triceratops_dort.png`, async (out) => {
    await props({ id: "mc36qj", scale: 1, outDir: `${OUT}/dinos`, names: ["triceratops_dort"] });
    const [cw, ch, foot] = [305, 208, 0.96];
    const drawn = await sharp(out).metadata();
    const scale = Math.min((cw - 8) / drawn.width, (ch * foot - 4) / drawn.height);
    const w = Math.round(drawn.width * scale), h = Math.round(drawn.height * scale);
    const body = await sharp(out).resize(w, h).png().toBuffer();
    const laid = await sharp({ create: { width: cw, height: ch, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
      .composite([{ input: body, left: Math.round((cw - w) / 2), top: Math.round(ch * foot) - h }])
      .png({ compressionLevel: 9 }).toBuffer();
    fs.writeFileSync(out, laid);
    return `${out} (couché, ${w}x${h} dans une case de ${cw}x${ch})`;
  }],

  // === PERSONNAGES CLINS D'ŒIL (29/09) : planches de marche 4x4, éditées depuis un personnage
  // existant de même gabarit (méthode chloe_manteau/maia_manteau, tools/art-jobs/monts.mjs) pour
  // garder la grille de pas, puis recalées avec alignWithBase (±3 px) sur ce même personnage source.
  // Tenues du film (réf. 7 pour l'allure SEULEMENT — jamais envoyée au modèle : elle faisait échouer
  // la génération, filtrée comme visage reconnaissable), jamais de visage d'acteur, jamais de logo. ===

  [`${OUT}/characters/hamon.png`, async (out) => {
    const done = await sheet({ id: "9t62ec", rows: 4, cols: 4, frameHeight: 176, out });
    await alignWithBase(out, `${OUT}/characters/roc.png`, 4, 4, sharp);
    return done + " — recalée sur roc.png";
  }],
  [`${OUT}/characters/granit.png`, async (out) => {
    const done = await sheet({ id: "pc9xvr", rows: 4, cols: 4, frameHeight: 176, out });
    await alignWithBase(out, `${OUT}/characters/garde.png`, 4, 4, sharp);
    return done + " — recalée sur garde.png";
  }],
  // elise : nano-banana a dessiné 6 colonnes au lieu de 4 (3 essais, même défaut) — on ne garde que
  // les 4 premières colonnes (pickColumns), une marche cohérente sur la planche source (rzvzwh).
  [`${OUT}/characters/elise.png`, async (out) => {
    const id = await pickColumns(sharp, find, "rzvzwh", "elise-4col", 4, 6, [0, 1, 2, 3]);
    const done = await sheet({ id, rows: 4, cols: 4, frameHeight: 176, out });
    await alignWithBase(out, `${OUT}/characters/isaure.png`, 4, 4, sharp);
    return done + " — 6→4 colonnes (pickColumns), recalée sur isaure.png";
  }],
  // elise_accroupie : même grille 4x2 que chloe_accroupie.png (cell 123x184), éditée depuis elle.
  // La rangée 0 de la planche source (ldmdhd) a une case cassée (le blob detection de sheetInCells
  // perd la vue 3/4, artefact fantôme) — la rangée 1 (le doublon voulu, comme dans chloe_accroupie
  // elle-même) est propre : gardée et dupliquée (même méthode que oneRowDuplicated, monts.mjs).
  // sheetInCells (le mode `cell`) perdait une case (blob detection) même sur une planche propre ;
  // le mode grille simple (sans `cell`, alphaBox par case fixe, pas de blob cross-cellule) est fiable.
  [`${OUT}/characters/elise_accroupie.png`, async (out) => {
    const id = await duplicateCleanRow(sharp, find, "ldmdhd", "elise-accroupie-clean", 2, 4, 1);
    const done = await sheet({ id, rows: 2, cols: 4, frameHeight: 156, out });
    // (cells the size of elise.png's frames, 115 × 184, feet 4 px above the bottom: the pose stands
    // where she stood, as chloe_accroupie does for Chloé)
    await padCells(out, 4, 2, 115, 184, 4, sharp);
    await clearGridLines(out, sharp);
    return done + " — cases de 115×184";
  }],
  // elise_agenouillee (30/09) : Élise fouille la pile À GENOUX, pas accroupie sur les talons.
  // Même grille et mêmes cases que elise_accroupie, éditée depuis la même planche source.
  [`${OUT}/characters/elise_agenouillee.png`, async (out) => {
    const id = await duplicateCleanRow(sharp, find, "tt5isn", "elise-agenouillee-clean", 2, 4, 1);
    const done = await sheet({ id, rows: 2, cols: 4, frameHeight: 156, out });
    await padCells(out, 4, 2, 115, 184, 4, sharp);
    await clearGridLines(out, sharp);
    return done + " — cases de 115×184";
  }],
  // malcombe : même défaut (6 colonnes, 2 essais) — gardé les 4 premières colonnes de w8vnuc.
  [`${OUT}/characters/malcombe.png`, async (out) => {
    const id = await pickColumns(sharp, find, "w8vnuc", "malcombe-4col", 4, 6, [0, 1, 2, 3]);
    const done = await sheet({ id, rows: 4, cols: 4, frameHeight: 176, out });
    await alignWithBase(out, `${OUT}/characters/gaspard.png`, 4, 4, sharp);
    return done + " — 6→4 colonnes (pickColumns), recalée sur gaspard.png";
  }],
];

/** A nano-banana sheet came out with more columns than asked (observed quirk, elise/malcombe here):
 * keeps only `keepCols` (0-based, in reading order) of `totalCols`, across all `totalRows` rows,
 * composited into a fresh magenta canvas of the kept width, so `sheet()` can cut it normally
 * afterwards as a plain totalRows x keepCols.length grid. */
async function pickColumns(sharp, find, id, name, totalRows, totalCols, keepCols) {
  const src = find(id);
  const out = path.join(path.dirname(src), `derived-${name}.png`);
  const { width, height } = await sharp(src).metadata();
  const cw = width / totalCols, ch = height / totalRows;
  const composites = [];
  for (let r = 0; r < totalRows; r++) {
    for (const [i, c] of keepCols.entries()) {
      const buf = await sharp(src)
        .extract({ left: Math.round(c * cw), top: Math.round(r * ch), width: Math.round(cw), height: Math.round(ch) })
        .png().toBuffer();
      composites.push({ input: buf, left: Math.round(i * cw), top: Math.round(r * ch) });
    }
  }
  await sharp({ create: { width: Math.round(cw * keepCols.length), height: Math.round(ch * totalRows), channels: 3, background: { r: 255, g: 0, b: 255 } } })
    .composite(composites).png().toFile(out);
  return path.basename(out, ".png");
}

/** Keeps only row `keepRow` (0-based) of a `rows`x`cols` grid and duplicates it into a fresh
 * `rows`x`cols` canvas — for a sheet where one row came out broken but another is a clean duplicate
 * of the same poses (same trick as monts.mjs's oneRowDuplicated, generalised to any row count). */
async function duplicateCleanRow(sharp, find, id, name, rows, cols, keepRow) {
  const src = find(id);
  const out = path.join(path.dirname(src), `derived-${name}.png`);
  const { width, height } = await sharp(src).metadata();
  const ch = Math.round(height / rows);
  const rowBuf = await sharp(src).extract({ left: 0, top: keepRow * ch, width, height: ch }).toBuffer();
  const composites = [];
  for (let r = 0; r < rows; r++) composites.push({ input: rowBuf, left: 0, top: r * ch });
  await sharp({ create: { width, height: ch * rows, channels: 3, background: { r: 255, g: 0, b: 255 } } })
    .composite(composites).png().toFile(out);
  return path.basename(out, ".png");
}

// Shifts each cell's drawing of `file` sideways so its centre (of its opaque pixels) sits where the
// drawing of the same cell of `base` sits (copied from tools/art-jobs/monts.mjs — not exported there).
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
    const i = r * cols + c, dx = Math.round((want[i] - have[i]) * cw);
    for (let y = Math.floor(r * ch); y < (r + 1) * ch; y++) for (let x = Math.floor(c * cw); x < (c + 1) * cw; x++) {
      const tx = x + dx;
      if (tx < Math.floor(c * cw) || tx >= (c + 1) * cw) continue;
      data.copy(moved, (y * info.width + tx) * 4, (y * info.width + x) * 4, (y * info.width + x) * 4 + 4);
    }
  }
  await sharp(moved, { raw: { width: info.width, height: info.height, channels: 4 } }).png({ compressionLevel: 9 }).toFile(file + ".tmp.png");
  fs.renameSync(file + ".tmp.png", file);
}

/** Composes the banderole_fouilles text in SVG (guarantees the French accents, nano-banana had
 * dropped one on "régnaient" in pass 1 on this same sentence): finds the black cloth's bounding box
 * (opaque + dark pixels, excludes the transparent background and the lighter wood poles/sand), then
 * paints "QUAND LES DINOSAURES" / "RÉGNAIENT SUR LA TERRE" across it, red fill + gold stroke (palette
 * du film fournie par l'utilisateur), uneven per-word sizes like the reference banner. */
async function addBanderoleText(file, sharp) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  // The cloth = the rows and columns mostly made of dark pixels (not every dark pixel: the poles'
  // outlines and the shadows on the sand would widen the box and push the text off the cloth).
  const dark = (x, y) => { const i = (y * info.width + x) * 4; return data[i + 3] >= 200 && data[i] < 90 && data[i + 1] < 90 && data[i + 2] < 90; };
  const cols = new Array(info.width).fill(0), rows = new Array(info.height).fill(0);
  for (let y = 0; y < info.height; y++) for (let x = 0; x < info.width; x++) if (dark(x, y)) { cols[x]++; rows[y]++; }
  const span = (counts) => { const top = Math.max(...counts), keep = counts.map((c) => c >= top * 0.55); return [keep.indexOf(true), keep.lastIndexOf(true)]; };
  const [minX, maxX] = span(cols), [minY, maxY] = span(rows);
  const w = maxX - minX, h = maxY - minY;
  const marginX = w * 0.07, availW = w - marginX * 2;
  const line1Y = minY + h * 0.45, line2Y = minY + h * 0.88;
  const RED = "#E23123", GOLD = "#F0B83E";
  const CHAR_W = 0.7, GAP_EM = 0.3;   // bold-italic average glyph width, inter-word gap, in em
  // Fits a line of [text, weight] words (weight = relative font size) to `availW`: solves the base
  // em size so the sum of estimated word widths + gaps matches availW, capped by `maxSize` (so a
  // short line does not blow up to a huge, out-of-proportion size).
  const fitLine = (words, maxSize) => {
    const units = words.reduce((s, [t, wt]) => s + t.length * CHAR_W * wt, 0) + GAP_EM * (words.length - 1);
    return Math.min(maxSize, availW / units);
  };
  const draw = (words, y, maxSize) => {
    const base = fitLine(words, maxSize);
    const widths = words.map(([t, wt]) => t.length * CHAR_W * wt * base);
    const totalW = widths.reduce((a, b) => a + b, 0) + GAP_EM * base * (words.length - 1);
    let x = minX + marginX + (availW - totalW) / 2;
    const parts = [];
    for (const [i, [t, wt]] of words.entries()) {
      const size = base * wt, wPx = widths[i];
      parts.push(`<text x="${(x + wPx / 2).toFixed(1)}" y="${y}" font-family="Arial, Helvetica, sans-serif" font-weight="900" font-style="italic" font-size="${size.toFixed(1)}" fill="${RED}" stroke="${GOLD}" stroke-width="${Math.max(2, size * 0.08).toFixed(1)}" stroke-linejoin="round" paint-order="stroke" text-anchor="middle">${t}</text>`);
      x += wPx + GAP_EM * base;
    }
    return parts.join("");
  };
  const maxLineSize = h * 0.4;
  const cx = minX + w / 2, cy = (line1Y + line2Y) / 2;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${info.width}" height="${info.height}">
    <g transform="rotate(-1.2 ${cx} ${cy})">
      ${draw([["QUAND", 1], ["LES", 0.85], ["DINOSAURES", 1.55]], line1Y, maxLineSize)}
      ${draw([["RÉGNAIENT", 1.3], ["SUR LA", 0.85], ["TERRE", 1.45]], line2Y, maxLineSize)}
    </g>
  </svg>`;
  const out = await sharp(file).composite([{ input: Buffer.from(svg), left: 0, top: 0 }]).png({ compressionLevel: 9 }).toBuffer();
  fs.writeFileSync(file, out);
}


// Puts each cell's drawing of `file` (a sheet of cols × rows cells) into a cell of cellW × cellH,
// centred, its lowest pixel `foot` px above the cell's bottom (a pose sheet then shares the frame
// size and foot line of the person's walking sheet).
async function padCells(file, cols, rows, cellW, cellH, foot, sharp) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const cw = info.width / cols, ch = info.height / rows, parts = [];
  for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) {
    let x0 = 1e9, x1 = -1, y1 = -1;
    const IN = 3;   // (px of each source cell left out: the thin grid lines of the drawing)
    for (let y = Math.floor(r * ch); y < (r + 1) * ch; y++) for (let x = Math.floor(c * cw) + IN; x < (c + 1) * cw - IN; x++)
      if (data[(y * info.width + x) * 4 + 3] > 8) { x0 = Math.min(x0, x); x1 = Math.max(x1, x); y1 = Math.max(y1, y); }
    if (x1 < 0) continue;
    let y0 = 1e9;
    for (let y = Math.floor(r * ch); y <= y1; y++) for (let x = x0; x <= x1; x++) if (data[(y * info.width + x) * 4 + 3] > 8) { y0 = Math.min(y0, y); break; }
    const w = Math.min(cellW, x1 - x0 + 1), h = Math.min(cellH - foot, y1 - y0 + 1);
    const piece = await sharp(file).extract({ left: x0, top: y1 - h + 1, width: w, height: h }).png().toBuffer();
    parts.push({ input: piece, left: c * cellW + Math.round((cellW - w) / 2), top: r * cellH + cellH - foot - h });
  }
  const out = await sharp({ create: { width: cellW * cols, height: cellH * rows, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite(parts).png({ compressionLevel: 9 }).toBuffer();
  fs.writeFileSync(file, out);
}


// Clears the thin light grid lines a drawing kept between its cells: a pixel column (or row) made
// mostly of light, greyish pixels from end to end (a person never is) loses them.
async function clearGridLines(file, sharp) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  // (light greyish, or faint: the lines are often half-keyed, a thin magenta haze)
  const light = (i) => data[i + 3] > 0 && (data[i + 3] < 170 || (data[i] > 170 && data[i + 1] > 155 && data[i + 2] > 170 && Math.abs(data[i] - data[i + 2]) < 25));
  for (let x = 0; x < info.width; x++) {
    let n = 0;
    for (let y = 0; y < info.height; y++) if (light((y * info.width + x) * 4)) n++;
    if (n < info.height * 0.35) continue;
    for (let y = 0; y < info.height; y++) { const i = (y * info.width + x) * 4; if (light(i)) data[i + 3] = 0; }
  }
  for (let y = 0; y < info.height; y++) {
    let n = 0;
    for (let x = 0; x < info.width; x++) if (light((y * info.width + x) * 4)) n++;
    if (n < info.width * 0.35) continue;
    for (let x = 0; x < info.width; x++) { const i = (y * info.width + x) * 4; if (light(i)) data[i + 3] = 0; }
  }
  const out = await sharp(data, { raw: { width: info.width, height: info.height, channels: 4 } }).png({ compressionLevel: 9 }).toBuffer();
  fs.writeFileSync(file, out);
}
