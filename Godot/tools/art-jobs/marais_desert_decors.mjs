// Marais Brumeux and Désert Aride: battle backdrops, ground textures, scenery props,
// Dame Suie (the Ombre Noire's chemist, first met in the Marais) and 5 UI icons
// (the two new Sceaux, the amber Heart, the swim vest, a fossil). See docs/histoire.md
// (chapters 3–4) and docs/bestiaire.md (Marais, Désert) for the lore these decors sit in.
export default ({ sheet, props, icons, seamless, sharp, find, OUT }) => [
  // Battle backdrops: edits of the Plaines backdrop (frasoq) that keep its exact composition
  // and the two round estrades, same treatment as battle/foret.jpg and battle/grotte.jpg.
  [`${OUT}/battle/marais.jpg`, (out) => sharp(find("p25ih6")).resize(1920, 1072, { fit: "cover" }).jpeg({ quality: 86, mozjpeg: true }).toFile(out).then(() => out)],
  [`${OUT}/battle/temple.jpg`, (out) => sharp(find("0quwti")).resize(1920, 1072, { fit: "cover" }).jpeg({ quality: 86, mozjpeg: true }).toFile(out).then(() => out)],
  [`${OUT}/battle/desert.jpg`, (out) => sharp(find("7emrg3")).resize(1920, 1072, { fit: "cover" }).jpeg({ quality: 86, mozjpeg: true }).toFile(out).then(() => out)],

  // Ground textures (top-down, made seamless by cross-fade).
  [`${OUT}/ground/vase.png`, (out) => seamless({ id: "qd3jax", size: 512, out })],
  [`${OUT}/ground/dalles_temple.png`, (out) => seamless({ id: "p44ys9", size: 512, out })],
  [`${OUT}/ground/sable.png`, (out) => seamless({ id: "1g9o7e", size: 512, out })],
  [`${OUT}/ground/roche_canyon.png`, (out) => seamless({ id: "atnnrh", size: 512, out })],

  // Dame Suie, the Ombre Noire's chemist (chapter 3, Marais): same 4x4 walk-sheet layout
  // as maia.png/brac.png/isaure.png (edited from isaure.png for style consistency).
  [`${OUT}/characters/dame_suie.png`, (out) => sheet({ id: "awr0la", rows: 4, cols: 4, frameHeight: 176, out })],

  // Marais decor, sheet 1: reeds, mangrove tree, lily pads, stilt hut, the eroded dino statue.
  [`${OUT}/marais/decor1`, () => props({
    id: "8h4k6w", scale: 0.5, outDir: `${OUT}/props`,
    names: ["roseaux", "arbre_noye", "nenuphars", "cabane_pilotis", "statue_dino"],
  })],
  // Marais decor, sheet 2: broken column, sluice wheel, fresco, the temple door, roots.
  [`${OUT}/marais/decor2`, () => props({
    id: "6np5fw", scale: 0.5, outDir: `${OUT}/props`,
    names: ["colonne", "vanne", "fresque", "porte_temple", "racines"],
  })],

  // Désert decor, sheet 1: the giant rib fossile, the giant skull, a canyon boulder,
  // the rock arch, the oasis palm. The skull and the boulder sit close enough that automatic
  // detection merges them, hence explicit boxes (measured on the 2400x1792 sheet).
  [`${OUT}/desert/decor1`, () => props({
    id: "sh22pv", scale: 0.5, outDir: `${OUT}/props`,
    boxes: [[60, 84, 704, 744], [808, 148, 772, 648], [1580, 148, 780, 648], [264, 916, 860, 796], [1256, 896, 908, 824]],
    names: ["os_geant", "crane_geant_desert", "rocher_canyon", "arche_rocheuse", "palmier_oasis"],
  })],
  // Désert decor, sheet 2: the Oviraptor nest, the wind totem, a dry bush, a nomad tent.
  [`${OUT}/desert/decor2`, () => props({
    id: "2pjm6c", scale: 0.5, outDir: `${OUT}/props`,
    names: ["nid_oviraptor", "totem_vents", "buisson_sec", "tente_nomade"],
  })],

  // UI icons (160 px, same treatment as selle.png): the amber Heart (no glow halo — the
  // in-game glow comes from a PointLight2D, see docs/direction-artistique.md), the two new
  // Sceaux (Marais: fin/sail print; Désert: horn print), the swim vest, the ammonite fossil.
  // Sheet has a spare/duplicate vest (the model drew two): boxes pick only the 5 needed icons.
  [`${OUT}/ui/marais_desert`, () => icons({
    id: "xkkgm0", cols: 1, rows: 1, size: 160, outDir: `${OUT}/ui`,
    boxes: [[20, 10, 895, 750], [915, 10, 950, 750], [1865, 10, 887, 750], [20, 771, 895, 750], [1865, 771, 887, 750]],
    names: ["coeur_ambre", "sceau_marais", "sceau_desert", "gilet_nage", "fossile"],
  })],
];
