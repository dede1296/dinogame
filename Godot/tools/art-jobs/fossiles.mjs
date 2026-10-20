// Post-game, lot B' : les fossiles légendaires (docs/post-game-plan.md § 2).
//  - 3 espèces ressuscitables : saltasaurus (Titanosaure d'Or), kronosaurus (marin, 4 nageoires), gigantoraptor
//    (bipède plumé) : profil 3×2 + face/dos 4×2 (cellule du profil), + `kronosaurus_nage.png` (Chloé à plat ventre
//    sur son dos, 3×2, cycle de nage) ;
//  - props `crane_titanosaure_paroi`, `crane_kronosaurus_sable` ;
//  - icônes `ui/os_{titanosaure,kronosaurus,gigantoraptor}` + `ui/carnet_os` ;
//  - planches du squelette `ui/squelette_<id>.png` : UNE rangée de 5 cellules égales, de gauche à droite
//    crâne, colonne, côtes, pattes (nageoires), queue ; le jeu allume une cellule par os trouvé.
// Méthode : nano-banana édite une planche voisine (brachiosaurus / plesiosaurus+ankylosaurus / oviraptor) avec l'anatomie
// réelle dans le prompt ; sources dans generated_imgs/ (id = fin du nom). Les compositions intermédiaires (rangée de
// dos, rangée de 5 pièces) sont écrites dans generated_imgs/derived-fossiles-*.jpg.
import fs from "node:fs";

const SRC = "generated_imgs";
const MAGENTA = { r: 255, g: 0, b: 255 };

// [nom, id du profil 3×2, id face/dos, hauteur de cadre du profil]
const SPECIES = [
  ["saltasaurus", "br1u7k", null, 190],       // face/dos composé (voir FACE_DOS_COMPOSED)
  ["kronosaurus", "cf3719", "y9pd3n", 170],
  ["gigantoraptor", "8m0hl2", "8zc0tn", 230],
];
// Saltasaurus : la 1re planche face/dos (nayuwo) a la face juste mais le dos recopié de profil dans 2 colonnes ;
// la 2e (56k8v7) a les 4 dos justes en rangée du haut : rangée haute de nayuwo + rangée haute de 56k8v7.
const FACE_DOS_COMPOSED = { saltasaurus: { front: "nayuwo", back: "56k8v7" } };

// Squelettes : [nom, id source, bornes x (px de l'image affichée à 2000 de large ×1,584), y de départ]
const D = 1.584;
const SKELETONS = [
  ["saltasaurus", "dr9nyw", [[100, 420], [430, 740], [740, 1190], [1230, 1530], [1570, 1920]], 0],
  ["kronosaurus", "k4i69q", [[50, 660], [690, 900], [910, 1300], [1310, 1720], [1730, 1950]], [312, 312, 312, 0, 0]],
  ["gigantoraptor", "yv45wn", [[60, 450], [470, 740], [770, 1180], [1185, 1590], [1595, 1960]], 0],
];

const findFile = (id) => {
  const name = fs.readdirSync(SRC).find((n) => n.includes(id));
  if (!name) throw new Error(`Image source introuvable : ${id}`);
  return `${SRC}/${name}`;
};

/** Rangée haute de `front` au-dessus de la rangée haute de `back` (même grille 2 lignes), écrite en jpg. */
async function composeFaceDos(sharp, { front, back }, outFile) {
  const a = sharp(findFile(front)), b = sharp(findFile(back));
  const { width, height } = await a.metadata();
  const half = Math.round(height / 2);
  const top = await a.clone().extract({ left: 0, top: 0, width, height: half }).toBuffer();
  const bottom = await b.clone().extract({ left: 0, top: 0, width, height: half }).toBuffer();
  await sharp({ create: { width, height: half * 2, channels: 3, background: MAGENTA } })
    .composite([{ input: top, left: 0, top: 0 }, { input: bottom, left: 0, top: half }])
    .jpeg({ quality: 95 }).toFile(outFile);
}

/** Cinq pièces (bornes x) recentrées dans cinq cellules égales sur fond magenta, écrites en jpg. */
async function composePieces(sharp, id, ranges, yFrom, outFile) {
  const file = findFile(id);
  const meta = await sharp(file).metadata();
  const boxes = ranges.map(([x0, x1]) => [Math.round(x0 * D), Math.min(meta.width, Math.round(x1 * D))]);
  const cellW = Math.max(...boxes.map(([x0, x1]) => x1 - x0)) + 80;
  const tops = Array.isArray(yFrom) ? yFrom : ranges.map(() => yFrom);
  const h = meta.height;
  const parts = [];
  for (const [i, [x0, x1]] of boxes.entries()) {
    const input = await sharp(file).extract({ left: x0, top: tops[i], width: x1 - x0, height: h - tops[i] }).toBuffer();
    parts.push({ input, left: i * cellW + Math.round((cellW - (x1 - x0)) / 2), top: 0 });
  }
  await sharp({ create: { width: cellW * 5, height: h, channels: 3, background: MAGENTA } })
    .composite(parts).jpeg({ quality: 95 }).toFile(outFile);
}

export default ({ sheet, props, icons, sharp, OUT }) => {
  const jobs = [];
  for (const [name, id, , frameHeight] of SPECIES) {
    jobs.push([`${OUT}/dinos/${name}.png`, (out) => sheet({ id, rows: 2, cols: 3, frameHeight, align: "bottom", isolate: true, out })]);
  }
  for (const [name, , faceDosId, frameHeight] of SPECIES) {
    jobs.push([`${OUT}/dinos/${name}_face_dos.png`, async (out) => {
      const profile = `${OUT}/dinos/${name}.png`;
      if (!fs.existsSync(profile)) throw new Error(`${name} : produire d'abord le profil (${profile})`);
      const meta = await sharp(profile).metadata();
      const cell = [Math.round(meta.width / 3), Math.round(meta.height / 2)];
      let id = faceDosId;
      if (FACE_DOS_COMPOSED[name]) {
        id = `derived-fossiles-${name}-face-dos`;
        await composeFaceDos(sharp, FACE_DOS_COMPOSED[name], `${SRC}/${id}.jpg`);
      }
      return sheet({ id, rows: 2, cols: 4, frameHeight: frameHeight - 2, cell, out });
    }]);
  }
  // Kronosaurus en nage, Chloé à plat ventre sur son dos (3×2 : cycle de nage haut/bas/milieu, deux fois).
  jobs.push([`${OUT}/dinos/kronosaurus_nage.png`, (out) => sheet({ id: "bk7t6v", rows: 2, cols: 3, frameHeight: 200, align: "bottom", isolate: true, out })]);
  jobs.push([`${OUT}/props/crane_titanosaure_paroi.png`, () => props({ id: "x3fzbh", scale: 0.4, outDir: `${OUT}/props`, names: ["crane_titanosaure_paroi"] })]);
  jobs.push([`${OUT}/props/crane_kronosaurus_sable.png`, () => props({ id: "z14x8r", scale: 0.4, outDir: `${OUT}/props`, names: ["crane_kronosaurus_sable"] })]);
  jobs.push([`${OUT}/ui/os_icones`, () => icons({
    id: "kyvk17", cols: 2, rows: 2, size: 160, outDir: `${OUT}/ui`,
    names: ["os_titanosaure", "os_kronosaurus", "os_gigantoraptor", "carnet_os"],
  })]);
  for (const [name, id, ranges, yFrom] of SKELETONS) {
    jobs.push([`${OUT}/ui/squelette_${name}.png`, async (out) => {
      const derived = `derived-fossiles-squelette-${name}`;
      await composePieces(sharp, id, ranges, yFrom, `${SRC}/${derived}.jpg`);
      return sheet({ id: derived, rows: 1, cols: 5, frameHeight: 200, pad: 8, out });
    }]);
  }
  return jobs;
};
