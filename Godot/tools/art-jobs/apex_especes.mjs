// Chapitre 9 — Terre des Apex : le Souverain (espèce `souverain`) et ses variantes.
// Anatomie : très grand archosaure archaïque (~12 m), quadrupède bas et massif, tête longue de théropode,
// cou épais, longue queue lourde, dos cuirassé d'une double rangée de plaques osseuses dont les fissures
// luisent d'ambre. Pas de cornes, pas d'ailes, pas un dragon.
// Méthode : nano-banana édite la planche de l'Ankylosaurus (style, grille) ; la planche face/dos part de la
// planche de profil de l'espèce ; corrompu = veines violettes + éclats d'ambre noir ; apaisé = veines éteintes.
// nano-banana a dessiné 3×3 (9 poses) au lieu de 3×2 : recomposé en 3×2 (comme monts.mjs).
// Sources dans generated_imgs/ (id = fin du nom du fichier).
import fs from "node:fs";

const FRAME = 220;
// Cases choisies [rangée, colonne] dans la planche 3×3 : 3 pas, repos, repos 2 (tête basse), attaque.
const PICK_SAIN = [[0, 0], [0, 1], [0, 2], [1, 0], [2, 1], [2, 2]];
const PICK_CORROMPU = [[0, 0], [0, 1], [0, 2], [1, 0], [2, 1], [2, 2]];
const PICK_APAISE = [[0, 0], [0, 1], [0, 2], [1, 0], [2, 1], [1, 2]]; // pas de gueule ouverte : il est apaisé

export default ({ sheet, sharp, OUT }) => {
  const jobs = [];
  const recompose = (id, pick) => async (out) => {
    const tmp = out.replace(/\.png$/, "_tmp9x9.png");
    await sheet({ id, rows: 3, cols: 3, frameHeight: FRAME, align: "bottom", isolate: true, out: tmp });
    const meta = await sharp(tmp).metadata();
    const fw = meta.width / 3, fh = meta.height / 3;
    const parts = await Promise.all(pick.map(async ([r, c], i) => ({
      input: await sharp(tmp).extract({ left: Math.round(c * fw), top: Math.round(r * fh), width: Math.round(fw), height: Math.round(fh) }).png().toBuffer(),
      left: Math.round((i % 3) * fw), top: Math.round(Math.floor(i / 3) * fh),
    })));
    await sharp({ create: { width: Math.round(fw) * 3, height: Math.round(fh) * 2, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
      .composite(parts).png({ compressionLevel: 9 }).toBuffer().then((b) => sharp(b).resize(1425, 456, { fit: "fill" }).png({ compressionLevel: 9 }).toFile(out));
    fs.unlinkSync(tmp);
    return `${out} (recomposé 3×3 → 3×2 depuis ${id})`;
  };
  jobs.push([`${OUT}/dinos/souverain.png`, recompose("vhub09", PICK_SAIN)]);
  jobs.push([`${OUT}/dinos/souverain_face_dos.png`, async (out) => {
    const profile = `${OUT}/dinos/souverain.png`;
    if (!fs.existsSync(profile)) throw new Error(`souverain : produire d'abord le profil (${profile})`);
    const meta = await sharp(profile).metadata();
    const cell = [Math.round(meta.width / 3), Math.round(meta.height / 2)];
    return sheet({ id: "05ysv1", rows: 2, cols: 4, frameHeight: FRAME - 2, cell, out });
  }]);
  jobs.push([`${OUT}/dinos/souverain_corrompu.png`, recompose("mhot3r", PICK_CORROMPU)]);
  jobs.push([`${OUT}/dinos/souverain_apaise.png`, recompose("q7xegd", PICK_APAISE)]);
  // Couché, yeux ouverts : 3 variantes (veines d'ambre / corrompu / apaisé), 2 rangées (la 2e = même pose, légère variation).
  jobs.push([`${OUT}/dinos/souverain_couche.png`, (out) => sheet({ id: "wzazvo", rows: 2, cols: 3, frameHeight: FRAME, align: "bottom", isolate: true, out })]);
  return jobs;
};
