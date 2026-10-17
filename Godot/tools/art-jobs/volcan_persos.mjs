// Chapitre 8 — Plaine Volcanique : personnages (Dame Suie sans lunettes, Brac assis sur une cage, Léonce assis
// avec son masque d'os, Maïa assise sur une pierre). Chaque planche est éditée par nano-banana depuis la
// planche existante du personnage (collée sur magenta), jamais d'une page blanche (docs/sprites-mouvements.md).
// Mises en page : 4×4 (Dame Suie, comme dame_suie.png) ; 2×4 assis (rangée 1 = assis [face, gauche, droite, dos],
// rangée 2 = debout, étalon d'échelle, inutilisée), comme sbire_assis.png / maia_assise.png.
import fs from "node:fs";
import path from "node:path";

export default ({ sheet, sharp, find, OUT }) => {
  const jobs = [];
  // Dame Suie sans lunettes (la grande forge, quand elle baisse les verres) : mêmes cases que dame_suie.png.
  jobs.push([`${OUT}/characters/dame_suie_sans_lunettes.png`, async (out) => {
    const done = await sheet({ id: "5vvd0k", rows: 4, cols: 4, frameHeight: 176, out });
    await alignWithBase(out, `${OUT}/characters/dame_suie.png`, 4, 4, sharp);
    return done + " — recalée sur dame_suie.png";
  }]);
  // Brac assis sur une cage retournée. nano-banana a dessiné 6 colonnes : on recompose 4 colonnes ;
  // rangée 2 (debout, inutilisée) : le profil gauche est le profil droit retourné.
  jobs.push([`${OUT}/characters/brac_assis_cage.png`, async (out) => {
    const id = await composeCells(sharp, find, "qfcog6", 6, 2, "brac-cage",
      [[0, 0], [0, 2], [0, 3], [0, 4], [1, 0], [1, 2, true], [1, 2], [1, 4]]);
    return sheet({ id, rows: 2, cols: 4, frameHeight: 176, cell: [240, 184], out });
  }]);
  // Léonce sans masque, assis, le masque d'os sur le genou (base : sbire_assis.png).
  jobs.push([`${OUT}/characters/leonce_assis.png`, (out) =>
    sheet({ id: "mgftbu", rows: 2, cols: 4, frameHeight: 173.5, cell: [240, 184], out })]);
  // Maïa assise sur une pierre plate (la pierre fait partie du dessin : cellules plus grandes, 260×240).
  jobs.push([`${OUT}/characters/maia_pierre.png`, (out) =>
    sheet({ id: "vubpdc", rows: 2, cols: 4, frameHeight: 230, cell: [260, 240], out })]);
  return jobs;
};

/** Recompose une planche 4×2 propre depuis une source de `cols` × `rows` cases égales : `picks` = 8 entrées
 * [rangée, colonne, miroir?] (rangée 1 puis rangée 2), posées dans des cases égales sur fond magenta. */
async function composeCells(sharp, find, srcId, cols, rows, name, picks) {
  const src = find(srcId);
  const out = path.join(path.dirname(src), `derived-cases-${name}.png`);
  if (fs.existsSync(out)) return path.basename(out, ".png");
  const { width: W, height: H } = await sharp(src).metadata();
  const cw = Math.floor(W / cols), ch = Math.floor(H / rows);
  const parts = [];
  for (const [i, [r, c, flip]] of picks.entries()) {
    let cell = sharp(src).extract({ left: c * cw, top: r * ch, width: cw, height: ch });
    if (flip) cell = cell.flop();
    parts.push({ input: await cell.png().toBuffer(), left: (i % 4) * cw, top: Math.floor(i / 4) * ch });
  }
  await sharp({ create: { width: cw * 4, height: ch * 2, channels: 3, background: { r: 255, g: 0, b: 255 } } })
    .composite(parts).png().toFile(out);
  return path.basename(out, ".png");
}

/** Recale chaque case de `file` sur le centre de la même case de `base` (pas dessinés trop décalés :
 * le personnage tressauterait en marchant). Même méthode que cieux_persos.mjs. */
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
  fs.renameSync(file + ".tmp.png", file);
}
