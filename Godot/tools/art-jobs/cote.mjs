// Côte Préhistorique (chapitre 5, bestiaire) : 7 espèces, faites avec nano-banana
// (mcp__nano-banana__edit_image, édition d'une planche existante en référence de style/grille ;
// vues face/dos éditées depuis une planche PURE face/dos existante, avec la planche de profil déjà
// corrigée donnée en referenceImages pour l'anatomie/les couleurs — sinon nano-banana recopie le 3/4
// ou garde l'anatomie de la référence de style). Poses de nage (jamais de pattes au sol) pour les
// 5 reptiles marins ; anatomie vérifiée image par image (nombre de membres) avant d'accepter.
//
// Aussi : le correctif hors-chapitre de majungasaurus_face_dos.png (ses cases 0 et 3 étaient de
// 3/4 au lieu d'être de face/dos ; demandé par l'utilisateur le 28/09), fait avec la même méthode
// (référence de grille = carnotaurus_face_dos.png, référence d'anatomie = majungasaurus.png).
export default ({ sheet, icons, OUT }) => {
  // [name, source id, frameHeight, options] — profile sheets (3x2: 3 pas de nage/marche, repos, repos 2, attaque).
  // REDONE = the sheets redone on 28/09 evening: figures whole in their cells (margin >= 6 px, checked),
  // poses aligned on their lowest point (no jump between the rest and the swim).
  const REDONE = { pad: 8, align: "bottom" };
  const PROFILES = [
    ["archelon", "zgpmo9", 170],
    ["pteranodon", "ghw5k1", 190],
    ["plesiosaurus", "96zeg5", 190, REDONE],
    ["masiakasaurus", "l2izwd", 175],
    ["ichthyosaurus", "mn2wt8", 170],
    ["elasmosaurus", "rngjif", 220],
    ["mosasaure_abyssal", "9z2mct", 220],
  ];
  // [name, source id, frameHeight (profile height - 2), cell [w, h] from the profile sheet's actual output]
  // Cell sizes filled in after a first `node tools/process-art.mjs archelon pteranodon …` run
  // measured the profile outputs (see the report) — same pattern as especes_marais_desert.mjs.
  const FACE_DOS = [
    ["archelon", "bw6be7", 168, [227, 178]],
    ["pteranodon", "xzmtyz", 188, [220, 198]],
    // (derived-…: cells of two nano-banana outputs, the clean ones of each: wihtis 0, 1, 0 mirrored, mw245j 3-7)
    ["plesiosaurus", "derived-plesiosaurus-face-dos", 188, [301, 206], REDONE],
    ["masiakasaurus", "t06c10", 173, [221, 183]],
    ["ichthyosaurus", "m8k7n6", 168, [239, 178]],
    ["elasmosaurus", "hrxb06", 218, [237, 228]],
    ["mosasaure_abyssal", "tdva5e", 218, [342, 228]],
  ];
  const jobs = PROFILES.map(([name, id, frameHeight, options = {}]) =>
    [`${OUT}/dinos/${name}.png`, (out) => sheet({ id, rows: 2, cols: 3, frameHeight, ...options, out })]);
  for (const [name, id, frameHeight, cell, options = {}] of FACE_DOS) {
    jobs.push([`${OUT}/dinos/${name}_face_dos.png`, (out) => sheet({ id, rows: 2, cols: 4, frameHeight, cell, pad: options.pad, out })]);
  }
  // Hors chapitre 5 : correctif Majungasaurus (voir docs/direction-artistique.md § À refaire).
  jobs.push([`${OUT}/dinos/majungasaurus_face_dos.png`, (out) => sheet({ id: "8funs8", rows: 2, cols: 4, frameHeight: 198, cell: [244, 208], out })]);
  // UI icons (160 px, like the other Sceaux): the Sceau de la Côte (midnight-blue amber, a curling
  // wave, Hélène's fern) and Maïa's black cardboard mask (the Masque's shape, handmade, taped).
  jobs.push([`${OUT}/ui/cote_icones`, () => icons({ id: "dnt37k", cols: 2, rows: 1, size: 160, outDir: `${OUT}/ui`,
    names: ["sceau_cote", "masque_carton"] })]);
  return jobs;
};
