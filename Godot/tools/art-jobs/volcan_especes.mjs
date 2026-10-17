// Chapitre 8 — Plaine Volcanique : 4 espèces (profil 3×2 + face/dos 4×2) et leurs variantes corrompues.
// Méthode (comme cieux_especes.mjs) : nano-banana édite la planche d'une espèce voisine (style et grille :
// triceratops, ankylosaurus, allosaurus) avec l'anatomie réelle dans le prompt ; la planche face/dos part de
// la planche de profil de l'espèce, la grille de face/dos de l'espèce voisine en référence.
// Corrompus : mêmes conventions que carnotaurus_corrompu (veines lilas, yeux blanc-violet, éclats d'ambre noir).
// Les sources sont dans generated_imgs/ (id = fin du nom du fichier).
import fs from "node:fs";

// [nom, profil, face/dos, hauteur de cadre du profil]
const SPECIES = [
  ["styracosaurus", "2zlo6c", "0jjpk6", 190],
  ["saichania", "nqxxfx", "jflp0s", 145],
  ["daspletosaurus", "gcup48", "d5uzul", 215],
  ["trex_magma", "qziwoi", "3nzk0n", 260],
];
// Corrompus (profil seulement ; la face et le dos passent par le shader, comme les autres corrompus).
const CORRUPTED = [
  ["styracosaurus_corrompu", "eqy4c6", 190],
  ["saichania_corrompu", "ei9loc", 145],
  ["daspletosaurus_corrompu", "3m2yrg", 215],
  ["allosaurus_corrompu", "hez5o8", 210],
  ["majungasaurus_corrompu", "c8hppz", 200],
];

export default ({ sheet, sharp, OUT }) => {
  const jobs = [];
  for (const [name, id, , frameHeight] of SPECIES) {
    jobs.push([`${OUT}/dinos/${name}.png`, (out) => sheet({ id, rows: 2, cols: 3, frameHeight, align: "bottom", isolate: true, out })]);
  }
  for (const [name, , id, frameHeight] of SPECIES) {
    jobs.push([`${OUT}/dinos/${name}_face_dos.png`, async (out) => {
      const profile = `${OUT}/dinos/${name}.png`;
      if (!fs.existsSync(profile)) throw new Error(`${name} : produire d'abord le profil (${profile})`);
      const meta = await sharp(profile).metadata();
      const cell = [Math.round(meta.width / 3), Math.round(meta.height / 2)];
      return sheet({ id, rows: 2, cols: 4, frameHeight: frameHeight - 2, cell, out });
    }]);
  }
  for (const [name, id, frameHeight] of CORRUPTED) {
    jobs.push([`${OUT}/dinos/${name}.png`, (out) => sheet({ id, rows: 2, cols: 3, frameHeight, align: "bottom", isolate: true, out })]);
  }
  return jobs;
};
