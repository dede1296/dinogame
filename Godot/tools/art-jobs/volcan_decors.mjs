// Chapitre 8 — Plaine Volcanique : décors (props), sols raccordables, icônes, fond de combat.
// Méthode (comme cieux_decors.mjs) : nano-banana édite une image du jeu (référence de style : palissade,
// cage, tente, traineau_suie, boîte de fer) sur fond magenta ; objets bien séparés, détourés par props() avec
// des boîtes explicites [x, y, l, h] mesurées sur l'aperçu affiché en 2000 px de large (×1,264 = pixels de la
// source 2528×1696). Aucune ombre peinte au sol. Une `cage` existe déjà (props/cage.png) : la cage fermée du
// volcan s'appelle `cage_fermee`.
const px = (list) => list.map((b) => b.map((v) => Math.round(v * 1.264)));
const SCALE = 0.4;
export default ({ props, icons, seamless, sharp, find, OUT }) => {
  const jobs = [];
  const sheet = (out, id, boxes, names, post = null) =>
    jobs.push([out, async () => {
      const done = await props({ id, scale: SCALE, boxes: px(boxes), outDir: `${OUT}/props`, names });
      for (const [name, fix] of Object.entries(post ?? {})) await recolor(sharp, `${OUT}/props/${name}.png`, fix);
      return done;
    }]);
  // Planche 1 : forges (petites : 1 allumée + 3 éteintes ; grandes : allumée, éteinte).
  sheet(`${OUT}/props/forge_allumee.png`, "ycl0ks",
    [[70, 0, 440, 610], [545, 130, 450, 500], [70, 740, 515, 520], [588, 740, 455, 520], [1040, 20, 540, 1240], [1510, 70, 440, 1220]],
    ["forge_allumee", "forge_eteinte", "forge_eteinte_2", "forge_eteinte_3", "grande_forge_allumee", "grande_forge_eteinte"]);
  // Planche 2 : cages (fermée, ouverte, grande), barricade debout / tombée, fût d'ambre noir.
  sheet(`${OUT}/props/cage_fermee.png`, "d7dkew",
    [[40, 40, 500, 500], [540, 40, 630, 500], [1225, 30, 750, 730], [35, 575, 705, 690], [780, 735, 760, 560], [1595, 800, 360, 510]],
    ["cage_fermee", "cage_ouverte", "cage_grande", "barricade", "barricade_tombee", "fut_ambre_noir"]);
  // Planche 3 : enclume, auvent, soufflet, marmite, établi de Dame Suie, gants gris.
  sheet(`${OUT}/props/enclume.png`, "2gwk3i",
    [[75, 110, 460, 470], [665, 65, 670, 590], [1375, 110, 570, 480], [55, 650, 520, 610], [590, 695, 820, 545], [1465, 835, 480, 350]],
    ["enclume", "auvent", "soufflet", "marmite", "etabli_suie", "gants_gris"]);
  // Planche 4 : sanctuaire (vasque, autel, autel fendu, coque de lave, torche, plaque de fer vierge).
  sheet(`${OUT}/props/vasque_source.png`, "2qycbh",
    [[65, 0, 570, 610], [725, 95, 540, 475], [1360, 70, 590, 500], [40, 820, 630, 390], [835, 610, 340, 670], [1415, 850, 490, 310]],
    ["vasque_source", "autel_magma", "autel_magma_fendu", "coque_lave", "torche", "plaque_fer"],
    // La lueur de la fente, peinte sur le magenta, sortait rose : ramenée à l'orange (bleu abaissé).
    { autel_magma_fendu: ([r, g, b]) => [r, g, Math.min(b, Math.round(g * 0.45))] });
  // Planche 5 : grands décors (paroi de lave, portail des Apex, camp d'Hélène).
  sheet(`${OUT}/props/lave_paroi.png`, "117g6v",
    [[35, 155, 930, 945], [1035, 100, 920, 840], [1525, 990, 430, 260]],
    ["lave_paroi", "portail_apex", "camp_helene"]);
  // Planche 6 : traîneau à roues (Mandragore), masque d'os, pierre plate.
  sheet(`${OUT}/props/traineau_roues.png`, "av1h2d",
    [[30, 60, 1400, 810], [1395, 570, 400, 280], [645, 775, 820, 520]],
    ["traineau_roues", "masque_os_sol", "pierre_plate_volcan"]);
  // Sols (vues de dessus, sans ombre, raccordables).
  const GROUND = [["cendre", "94ch8k"], ["roche_noire", "dtftta"], ["lave", "e0urt7"], ["croute_refroidie", "sq6x9o"], ["obsidienne", "3yooph"]];
  for (const [name, id] of GROUND) {
    jobs.push([`${OUT}/ground/${name}.png`, (out) => seamless({ id, size: 512, out })]);
  }
  // Icônes 160×160 : sceau du volcan, antidote d'ambre, lettre d'Isaure (planche 4:1, boîtes mesurées ×2,064).
  jobs.push([`${OUT}/ui/sceau_volcan.png`, () => icons({
    id: "pkj95s", cols: 3, rows: 1, size: 160, outDir: `${OUT}/ui`,
    boxes: [[85, 35, 440, 430], [890, 50, 280, 410], [1385, 75, 545, 375]].map((b) => b.map((v) => Math.round(v * 2.064))),
    names: ["sceau_volcan", "antidote_ambre", "lettre_isaure"],
  })]);
  // Fond de combat (même cadrage que battle/cieux.jpg : deux plateaux, vide au centre).
  jobs.push([`${OUT}/battle/volcan.jpg`, (out) => sharp(find("1jdddz")).resize(1920, 1072, { fit: "cover" })
    .jpeg({ quality: 86, mozjpeg: true }).toFile(out).then(() => out)]);
  return jobs;
};

/** Recolore, dans un PNG détouré, les pixels teintés de rose par le fond magenta (lueurs) : `fix` reçoit [r, g, b]. */
async function recolor(sharp, file, fix) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  for (let i = 0; i < data.length; i += 4) {
    if (data[i + 3] === 0 || Math.min(data[i], data[i + 2]) - data[i + 1] < 12) continue;
    const [r, g, b] = fix([data[i], data[i + 1], data[i + 2]]);
    data[i] = r; data[i + 1] = g; data[i + 2] = b;
  }
  await sharp(data, { raw: { width: info.width, height: info.height, channels: 4 } }).png({ compressionLevel: 9 }).toFile(file + ".tmp");
  const fs = await import("node:fs");
  fs.renameSync(file + ".tmp", file);
}
