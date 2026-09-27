// Désert Aride (chapter 4) extra content: Tante Sirocco (a fossil-hunting nomad NPC),
// five new decor props (the Sanctuaire des Vents door, Brac's cage-wagon, a canyon rockslide,
// a giant sauropod skeleton, an oasis well) and two UI icons (sandstorm weather, a paleontologist's
// tools badge). See docs/lore.md and docs/histoire.md (chapter 4) for the lore these sit in.
export default ({ sheet, props, icons, seamless, sharp, find, OUT }) => [
  // Tante Sirocco: same 4x4 walk-sheet layout as maia.png/brac.png/pervenche.png
  // (edited from pervenche.png for style consistency: same chibi elder proportions).
  [`${OUT}/characters/tante_sirocco.png`, (out) => sheet({ id: "qyqfgn", rows: 4, cols: 4, frameHeight: 176, out })],

  // Désert decor, sheet 3: the Sanctuaire des Vents door, Brac's cage-wagon, the giant
  // sauropod skeleton, the oasis well. JPEG noise on the large flat magenta field links the
  // whole 2048x2048 canvas into a single blob under plain auto-detection, so explicit
  // (generous, slightly overlapping) quadrant boxes are used instead; keepLargestBlob per
  // box still discards that noise around each real object.
  [`${OUT}/desert2/decor1`, () => props({
    id: "5ui7fo", scale: 0.5, outDir: `${OUT}/props`,
    boxes: [[0, 0, 1100, 1100], [950, 0, 1098, 1100], [950, 950, 1098, 1098]],
    names: ["porte_vents", "chariot_cage", "puits_oasis"],
  })],
  // The giant skeleton, redrawn on its own (on sheet 3 its neck ran out of its quadrant).
  [`${OUT}/desert2/squelette`, () => props({
    id: "ada2fw", scale: 0.235, outDir: `${OUT}/props`,
    boxes: [[0, 0, 2400, 1792]],
    names: ["squelette_geant"],
  })],
  // Désert decor, sheet 4: the canyon rockslide (rempart_eboulis), the sheet's only object:
  // one full-canvas box plus keepLargestBlob strips the same JPEG background noise.
  [`${OUT}/desert2/decor2`, () => props({
    id: "agvb94", scale: 0.5, outDir: `${OUT}/props`,
    boxes: [[0, 0, 2752, 1536]],
    names: ["rempart_eboulis"],
  })],

  // UI icons (160 px, same flat treatment as meteo_pluie.png/meteo_orage.png and
  // selle.png): the sandstorm weather icon and a crossed brush+hammer badge (fossil digging).
  [`${OUT}/ui/desert2`, () => icons({
    id: "19l54b", cols: 2, rows: 1, size: 160, outDir: `${OUT}/ui`,
    names: ["meteo_sable", "pinceau_fouille"],
  })],
];
