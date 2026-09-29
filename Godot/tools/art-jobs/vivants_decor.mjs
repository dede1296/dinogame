// « Détails vivants » (29/09): the scenery the texts describe but the zones did not show — story
// props of chapters 1 to 5, the Côte's shore and reef kinds its zone plans were waiting for
// (stand-ins meanwhile), plants proper to each milieu (current and future zones). Made with
// nano-banana (edit_image, the port or forest prop sheets as style reference), flat magenta.
// See docs/direction-artistique.md « Détails vivants ». derived-… sheets: a nano-banana output
// with a leftover of the reference sheet painted out (magenta), nothing else changed.
export default ({ props, OUT }) => [
  // The Côte's shore (tools/zones/cote.gd BEACH/DUNES/ROCKY tables, _reef): shells, stranded
  // kelp, driftwood, a shore boulder, a reef rock, dune plants. (The left log, merged with a
  // leftover bollard of the reference sheet, is not used.)
  [`${OUT}/vivants/cote_plage`, () => props({
    id: "derived-vivants-cote-plage", scale: 0.5, outDir: `${OUT}/props`,
    names: ["coquillages", "algues", null, "bois_flotte", "rocher_cote", "rocher_recif", "oyats"],
  })],
  // The Côte's story: the Pteranodons' nest (colony scene, the headland's ledges), the turtles'
  // nest (the little turtles' quest), Hélène's iron box in its niche (page 23), the seaside fan
  // palm, a carved stone of the ancients (bone mask: the Cale, the reef), « H. + I. » carved in
  // the smugglers' cave (page 21). (The model drew the carved rock twice: the lower one, cut by
  // the sheet's edge, is not used.)
  [`${OUT}/vivants/cote_histoire`, () => props({
    id: "2b5l5h", scale: 0.5, outDir: `${OUT}/props`,
    names: ["nid_pteranodon", "nid_tortue", "boite_fer", "gravure_hi", "palmier_cote", "masque_pierre", null],
  })],
  // Under the sea (Récif du Sanctuaire; the lagoon's floor): kelp and coral, the kinds its zone
  // plan was waiting for (Examine.UNDERWATER_LINES "varech", "corail"), and more reef life.
  [`${OUT}/vivants/sous_mer`, () => props({
    id: "47d5pc", scale: 0.5, outDir: `${OUT}/props`,
    names: ["varech", "corail", "corail_branches", "anemones", "eponges", "herbier"],
  })],
  // Relics and traces of the story: the stone altar of the Cœurs (temple, sanctuary: the amber
  // lock stood in), the Spinosaurus statue of the temple's hall, the carved stone (« La Voix »,
  // « Griffe-Grise », « Le Vieux Rempart »), a plain flat stone (the model's extra: « sous une
  // pierre plate »), a cut stake (the empty ring of the Alpha's clearing), the moulted
  // Parasaurolophus skin (Joss's leather), the giant ferns flattened in the clearing.
  [`${OUT}/vivants/reliques`, () => props({
    id: "zfeem3", scale: 0.5, outDir: `${OUT}/props`,
    // (the skin's fern fronds touch the flattened ferns: explicit boxes, measured on the sheet)
    boxes: [[132, 108, 600, 804], [788, 84, 812, 940], [1644, 144, 688, 428], [1688, 688, 600, 368],
      [280, 964, 248, 728], [644, 1150, 962, 524], [1615, 1110, 745, 580]],
    names: ["autel", "statue_spinosaure", "pierre_gravee", "pierre_plate", "pieu_corde", "peau_mue", "fougeres_ecrasees"],
  })],
  // The people's things: Tante Sirocco's digging mat, a giant vertebra she dusts, petrified ribs
  // in the sand (Désert); Dame Suie's basket of vials (Marais); the henchmen's pickaxe and bucket
  // of amber (Grotte des Échos); the table of Hélène's observation post (Plaines). (First, a
  // stray tuft of mushrooms copied from the reference sheet: not used.)
  [`${OUT}/vivants/objets`, () => props({
    id: "eiofry", scale: 0.5, outDir: `${OUT}/props`,
    // (the sand under the vertebra touches its neighbours: explicit boxes, measured on the sheet)
    boxes: [[48, 110, 950, 590], [918, 100, 728, 744], [1640, 108, 716, 568],
      [116, 1120, 680, 566], [800, 966, 676, 768], [1592, 1008, 752, 748]],
    names: ["natte_fouilles", "vertebre", "cotes_sable", "panier_fioles", "outils_mine", "table_observation"],
  })],
  // Plants of the Mesozoic for the current milieux (docs/direction-artistique.md « Flore »):
  // horsetails (marsh, jungle, oasis), a cycad (coast, jungle, oasis), a young ginkgo (jungle,
  // meadow), dry horsetails and reeds (the Marais drying up at the Désert's gate), a squat
  // xerophytic conifer (Frenelopsis: desert), a lichen-covered desert boulder. (derived-…: a
  // ghost log and a ball from the reference painted out.)
  [`${OUT}/vivants/flore`, () => props({
    id: "derived-vivants-flore-actuelle", scale: 0.5, outDir: `${OUT}/props`,
    names: ["prele", "cycas", "ginkgo", "roseaux_secs", "conifere_sec", "rocher_lichen"],
  })],
  // Plants for the zones to come: Monts Gelés (a snowy fir, a frosted juniper-like shrub, a
  // snow-capped lichen boulder), Cieux Éternels (a wind-bent pine on its ledge), Plaine
  // Volcanique (a charred trunk with embers, pioneer ferns in the ash). (derived-…: two ghosts of
  // the reference's log and mushrooms painted out.)
  [`${OUT}/vivants/flore_future`, () => props({
    id: "derived-vivants-flore-future", scale: 0.5, outDir: `${OUT}/props`,
    // (the snow patches nearly touch: explicit boxes, measured on the sheet)
    boxes: [[88, 40, 588, 972], [796, 110, 756, 546], [1668, 64, 652, 540],
      [76, 1060, 778, 630], [828, 790, 736, 942], [1620, 1068, 712, 624]],
    names: ["sapin_neige", "buisson_givre", "rocher_neige", "pin_tordu", "tronc_calcine", "fougere_cendre"],
  })],
  // The Cabinet's specimen shelf (jars, a Compsognathus skull, the teapot Roc moves aside, ch. 5),
  // and plants for the Terre des Apex and the Cieux Éternels: a Williamsonia (bennettitale), an
  // early magnolia, a giant horsetail (Neocalamites, Equisetites), a giant nest on a sky needle,
  // a trunk wrapped in lianas. (derived-…: a ghost log of the reference painted out; explicit
  // boxes, measured.)
  [`${OUT}/vivants/apex`, () => props({
    id: "derived-vivants-apex", scale: 0.5, outDir: `${OUT}/props`,
    boxes: [[74, 38, 778, 824], [926, 62, 748, 868], [1730, 50, 598, 806],
      [118, 826, 468, 888], [626, 782, 652, 904], [1766, 914, 550, 784]],
    names: ["etagere_bocaux", "bennettitale", "magnolia", "prele_geante", "nid_geant", "liane_tronc"],
  })],
];
