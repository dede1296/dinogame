// Chapitre 9 — Terre des Apex : personnages. Hélène (nouveau : marche 4×4 d'après bertille.png ; assise au
// fauteuil et au sol 2×4 d'après roc_assis.png / isaure_sans_masque_assise.png).
// Mises en page : 4×4 (rangée 1 = dos, 2 = gauche, 3 = droite, 4 = face, comme bertille.png) ; 2×4 assis
// (rangée 1 = assis [face, gauche, droite, dos], rangée 2 = debout : étalon d'échelle / soutenue).
// nano-banana a dessiné 6 colonnes pour le fauteuil : recomposées en 4 (le profil droit = le gauche retourné).
import fs from "node:fs";
import path from "node:path";

export default ({ sheet, sharp, find, OUT }) => {
  const jobs = [];
  // Ordre des rangées du jeu : face, gauche, droite, dos (comme chloe.png). Dessinée dos en premier (comme
  // bertille.png, sa base) : rangées 1 et 4 échangées après découpe.
  jobs.push([`${OUT}/characters/helene.png`, async (out) => {
    const done = await sheet({ id: "xwrbny", rows: 4, cols: 4, frameHeight: 176, out });
    await swapRows(sharp, out, 4, [3, 1, 2, 0]);
    return done + " — rangées remises dans l'ordre face, gauche, droite, dos";
  }]);
  jobs.push([`${OUT}/characters/helene_assise.png`, async (out) => {
    const id = await composeCells(sharp, find, "jj7k9o", 6, 2, "helene-assise",
      [[0, 0], [0, 2], [0, 2, true], [0, 5], [1, 0], [1, 3], [1, 3, true], [1, 5]]);
    return sheet({ id, rows: 2, cols: 4, frameHeight: 176, cell: [240, 184], out });
  }]);
  // Assise au sol, soutenue (rangée 1), puis debout soutenue, un bras tendu vers une épaule (rangée 2).
  // Rangée 1 : le profil gauche est le profil droit retourné.
  jobs.push([`${OUT}/characters/helene_sol.png`, async (out) => {
    const id = await composeCells(sharp, find, "xvlwuf", 4, 2, "helene-sol",
      [[0, 0], [0, 2, true], [0, 2], [0, 3], [1, 0], [1, 1], [1, 2], [1, 3]]);
    return sheet({ id, rows: 2, cols: 4, frameHeight: 176, cell: [240, 184], out });
  }]);
  // Isaure (sans masque, cheveux déjà attachés) tenant à la main le masque en carton de Maïa : 4×4 comme isaure_sans_masque.png.
  jobs.push([`${OUT}/characters/isaure_masque_carton.png`, (out) => sheet({ id: "3lzyat", rows: 4, cols: 4, frameHeight: 176, out })]);
  return jobs;
};

/** Recompose une planche 4×2 propre depuis une source de `cols` × `rows` cases égales : `picks` = 8 entrées
 * [rangée, colonne, miroir?] (rangée 1 puis rangée 2). Réécrit le fichier dérivé à chaque fois. */
async function composeCells(sharp, find, srcId, cols, rows, name, picks) {
  const src = find(srcId);
  const out = path.join(path.dirname(src), `derived-cases-${name}.png`);
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

/** Réordonne les rangées d'une planche : `order[i]` = rangée source de la rangée i. */
async function swapRows(sharp, file, rows, order) {
  const buf = await sharp(file).png().toBuffer();
  const { width, height } = await sharp(buf).metadata();
  const rh = Math.round(height / rows);
  const parts = await Promise.all(order.map(async (src, i) => ({
    input: await sharp(buf).extract({ left: 0, top: src * rh, width, height: rh }).png().toBuffer(), left: 0, top: i * rh })));
  await sharp({ create: { width, height: rh * rows, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite(parts).png({ compressionLevel: 9 }).toFile(file + ".tmp");
  fs.renameSync(file + ".tmp", file);
}
