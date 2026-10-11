// Chapitre 7 — Les Cieux Éternels : décors (props), sols, icônes, fond de combat.
// Même méthode que monts.mjs : nano-banana édite une image du jeu (référence de style) sur fond
// magenta ; objets bien séparés, détourés par props() ; sols rendus raccordables par seamless().
// Aucune ombre peinte au sol (les ombres sont calculées par le jeu).
// Boîtes explicites [x, y, l, h] mesurées sur l'aperçu (×1,264 = pixels de la source 2528×1696) :
// la détection automatique fondait plusieurs objets en un seul (bords JPEG au ras du magenta).
const px = (list) => list.map((b) => b.map((v) => Math.round(v * 1.264)));
export default ({ props, icons, seamless, sharp, find, OUT }) => {
  const jobs = [];
  // Planche 1 : nids géants (œufs / vide), pitons rocheux, rochers de la corniche. Lecture : haut 3, bas 2.
  jobs.push([`${OUT}/props/nid_cieux.png`, () => props({
    id: "5i0vi3", scale: 0.4, boxes: px([[40, 100, 780, 530], [820, 110, 730, 470], [1600, 30, 320, 800], [150, 690, 620, 600], [970, 750, 920, 520]]), outDir: `${OUT}/props`,
    names: ["nid_cieux", "nid_cieux_vide", "piton_haut", "piton_bas", "rochers_cieux"],
  })]);
  // Planche 2 : plumes géantes (3) et drapeaux de vent (2, l'un tourné à droite, l'autre à gauche).
  jobs.push([`${OUT}/props/plume_geante.png`, () => props({
    id: "beui94", scale: 0.35, boxes: px([[70, 30, 570, 650], [790, 30, 430, 650], [1390, 40, 520, 640], [130, 690, 780, 640], [1000, 690, 820, 640]]), outDir: `${OUT}/props`,
    names: ["plume_geante_1", "plume_geante_2", "plume_geante_3", "drapeau_vent_1", "drapeau_vent_2"],
  })]);
  // Planche 3 : ponts de lianes (segment horizontal, segment vertical vu de dessus, 2 piliers, segment rompu).
  jobs.push([`${OUT}/props/pont_lianes.png`, () => props({
    id: "tsg8d0", scale: 0.4, boxes: px([[10, 90, 960, 450], [1010, 40, 390, 790], [1490, 30, 460, 780], [0, 0, 1, 1], [680, 830, 1230, 500]]), outDir: `${OUT}/props`,
    names: ["pont_lianes_h", "pont_lianes_v", "pilier_pont_1", null, "pont_lianes_rompu"],
  })]);
  // pilier_pont_2 refait (11/10) : les cordes pendantes (« petits bras ») sont remplacées par un lien net.
  jobs.push([`${OUT}/props/pilier_pont_2.png`, () => props({ id: "73mwu4", scale: 0.3, outDir: `${OUT}/props`, gap: 40, names: ["pilier_pont_2"] })]);
  // L'arche du vent : un seul grand décor (deux piliers sculptés de spirales + la voûte).
  jobs.push([`${OUT}/props/arche_vent.png`, () => props({
    id: "t56t39", scale: 0.5, outDir: `${OUT}/props`, gap: 40, names: ["arche_vent"],
  })]);
  // Sols (vues de dessus, sans ombre, raccordables) : mer de nuages, pierre des pitons, fond de nid,
  // tablier du pont de lianes (planches parallèles, rangées gauche-droite).
  const GROUND = [["nuages", "01aj1w"], ["pierre_cieux", "p1oj58"], ["nid", "dw4dn8"], ["pont_lianes", "wjqazu"]];
  for (const [name, id] of GROUND) {
    jobs.push([`${OUT}/ground/${name}.png`, (out) => seamless({ id, size: 512, out })]);
  }
  // Icônes 160×160 : le Sceau des Cieux et le harnais de vol (planche j8xqan, boîtes mesurées ×1,58 ;
  // le 3e dessin de cette planche, une fiole, est écarté), puis le badge de météo « grand vent »
  // (xz39ue, refait seul : sur la planche il sortait avec un goulot de flacon).
  jobs.push([`${OUT}/ui/cieux_icones`, () => icons({
    id: "j8xqan", cols: 3, rows: 1, size: 160, outDir: `${OUT}/ui`,
    boxes: [[20, 90, 650, 650], [700, 80, 520, 700]].map((b) => b.map((v) => Math.round(v * 1.58))),
    names: ["sceau_cieux", "harnais_vol"],
  })]);
  jobs.push([`${OUT}/ui/meteo_vent.png`, () => icons({ id: "xz39ue", cols: 1, rows: 1, size: 160, outDir: `${OUT}/ui`, names: ["meteo_vent"] })]);
  // Fond de combat (même cadrage que battle/monts.jpg : deux plateaux, mer de nuages, nid au bord).
  jobs.push([`${OUT}/battle/cieux.jpg`, (out) => sharp(find("fqq4ss")).resize(1920, 1072, { fit: "cover" })
    .jpeg({ quality: 86, mozjpeg: true }).toFile(out).then(() => out)]);
  // Accessoires de l'histoire (scènes de l'Arche et des Nids) : le vieux harnais d'Hélène dans son lit de
  // plumes (60-80 cm au sol) et le masque d'obsidienne tombé dans l'herbe. Détourés, sans ombre.
  jobs.push([`${OUT}/props/vieux_harnais.png`, () => props({ id: "ntmvnu", scale: 0.4, outDir: `${OUT}/props`, gap: 40, names: ["vieux_harnais"] })]);
  jobs.push([`${OUT}/props/masque_obsidienne.png`, () => props({ id: "t57k3p", scale: 0.3, outDir: `${OUT}/props`, gap: 40, names: ["masque_obsidienne"] })]);
  // Bancs de nuages bas (pied des pitons) : 4 variantes, 2×2 sur la planche (lecture : haut gauche, haut droite, bas gauche, bas droite).
  jobs.push([`${OUT}/props/nuage_bas.png`, () => props({ id: "yksfuz", scale: 0.4, outDir: `${OUT}/props`, boxes: px([[60, 140, 810, 410], [940, 200, 1030, 330], [60, 800, 1130, 360], [1270, 730, 630, 440]]), names: ["nuage_bas_1", "nuage_bas_2", "nuage_bas_3", "nuage_bas_4"] })]);
  // L'arche vue de loin : fabriquée SANS génération depuis arche_vent.png (nano-banana rendait un fond en
  // dégradé, impossible à détourer) : teinte bleu-gris, désaturée, éclaircie, contours adoucis, plus petite.
  jobs.push([`${OUT}/props/arche_vent_loin.png`, async (out) => {
    const src = `${OUT}/props/arche_vent.png`;
    const { width } = await sharp(src).metadata();
    const w = Math.round(width * 0.55);
    const base = await sharp(src).resize(w).modulate({ saturation: 0.25, brightness: 1.12 })
      .tint({ r: 150, g: 170, b: 215 }).blur(1.4).ensureAlpha().toBuffer();
    await sharp(base).linear([1, 1, 1, 0.8], [18, 18, 26, 0]).png({ compressionLevel: 9 }).toFile(out);
    return out + " (version lointaine, brumeuse)";
  }]);
  return jobs;
};
