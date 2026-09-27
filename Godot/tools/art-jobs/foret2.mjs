// Forêt Jurassique, étape 2 : le camp de l'Ombre Noire (Brac, le Masque, dinos corrompus,
// décor de camp) and the crack in the western ridge + the Masque's rope bridge.
export default ({ sheet, props, icons, OUT }) => [
  // Brac le braconnier and the Masque d'Obsidienne : same 4x4 walk-sheet layout as maia.png.
  [`${OUT}/characters/brac.png`, (out) => sheet({ id: "opmlu1", rows: 4, cols: 4, frameHeight: 176, out })],
  [`${OUT}/characters/masque.png`, (out) => sheet({ id: "ctb9cj", rows: 4, cols: 4, frameHeight: 176, out })],
  // Corrupted look of six species (black-amber veins, greyer skin, violet eyes) : same sheet
  // layout and frameHeight as their plain sheet in process-art.mjs (the game swaps one for
  // the other), so the frame grid lines up.
  [`${OUT}/dinos/velociraptor_corrompu.png`, (out) => sheet({ id: "scmsy3", rows: 2, cols: 3, frameHeight: 200, out })],
  [`${OUT}/dinos/ankylosaurus_corrompu.png`, (out) => sheet({ id: "kv41i3", rows: 2, cols: 3, frameHeight: 140, out })],
  [`${OUT}/dinos/parasaurolophus_corrompu.png`, (out) => sheet({ id: "t0rbqp", rows: 2, cols: 3, frameHeight: 170, out })],
  [`${OUT}/dinos/utahraptor_corrompu.png`, (out) => sheet({ id: "ot7dbf", rows: 2, cols: 3, frameHeight: 230, out })],
  [`${OUT}/dinos/deinonychus_corrompu.png`, (out) => sheet({ id: "w0nbv6", rows: 2, cols: 3, frameHeight: 190, out })],
  [`${OUT}/dinos/dilophosaurus_corrompu.png`, (out) => sheet({ id: "mch0j0", rows: 2, cols: 3, frameHeight: 180, out })],
  // Camp decor: tent, empty cage, black-amber crate, papers table, palisade segment (one sheet).
  [`${OUT}/camp/decor1`, () => props({
    id: "7maqt4", scale: 0.5, outDir: `${OUT}/props`,
    names: ["tente", "cage", "caisse_ambre_noir", "table_papiers", "palissade"],
  })],
  // The crack in the western ridge (Forêt) that Coup de crâne breaks open.
  [`${OUT}/camp/mur_fissure`, () => props({ id: "acc9xg", scale: 0.5, outDir: `${OUT}/props`, names: ["mur_fissure"] })],
  // The Masque's rope bridge between two arbre_geant trunks (very wide, own sheet).
  [`${OUT}/foret/passerelle`, () => props({ id: "cuidpm", scale: 0.45, gap: 40, outDir: `${OUT}/props`, names: ["passerelle"] })],
  // UI icon: the Forest Seal (amber, raptor claw print), same treatment as selle.png.
  [`${OUT}/ui/sceau_foret`, () => icons({ id: "va3j7j", cols: 1, rows: 1, size: 160, outDir: `${OUT}/ui`, names: ["sceau_foret"] })],
];
