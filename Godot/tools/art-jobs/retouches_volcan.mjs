// Retouches du 18/10 (agent IMAGES). Sorties sous un nom provisoire `_nouveau` ; l'ancien fichier est gardé
// en `_v1`, puis le nouveau le remplace après comparaison (voir docs/direction-artistique.md § À refaire).
// Lancer avec un chemin précis : node Godot/tools/process-art.mjs characters/leonce_assis_nouveau
export default ({ sheet, OUT }) => [
  // Léonce assis, masque d'os réduit (~45 %) : chaque case retouchée par nano-banana puis recomposée
  // (derived-leonce-petit-masque.png, mêmes cases 792×672 que la source mgftbu), même mise en page 2×4.
  [`${OUT}/characters/leonce_assis_nouveau.png`, (out) =>
    sheet({ id: "derived-leonce-petit-masque", rows: 2, cols: 4, frameHeight: 173.5, cell: [240, 184], out })],
  // T-Rex de Magma : 6e case (attaque) rugissante, bouche ouverte, retouchée par nano-banana (derived-trex-magma-rugit.png =
  // la source qziwoi dont la case 6 est remplacée) ; mêmes réglages que volcan_especes.mjs.
  [`${OUT}/dinos/trex_magma_nouveau.png`, (out) =>
    sheet({ id: "derived-trex-magma-rugit", rows: 2, cols: 3, frameHeight: 260, cell: [300, 268], align: "bottom", isolate: true, out })],
  // T-Rex de Magma de face : fumée aux naseaux (4 cases de face retouchées une à une, derived-trex-magma-face-naseaux.png = source 3nzk0n).
  [`${OUT}/dinos/trex_magma_face_dos_nouveau.png`, (out) =>
    sheet({ id: "derived-trex-magma-face-naseaux", rows: 2, cols: 4, frameHeight: 258, cell: [300, 268], out })],
];

// Fonds et planches retouchés à la main hors pipeline (18/10), pour mémoire :
//  - battle/volcan.jpg : source generated_imgs/edited-…-xfmosw.jpg (plumes et drapeau retirés), plein cadre 1920×1072 ; ancien = volcan_v1.jpg
//  - props/poteau_lianes.png : bouts de corde pendants effacés par script (pixels x>=63, y>=146) ; ancien = poteau_lianes_v1.png
//  - characters/chloe_vol*.png : case de face (colonne 1) décalée de +14 px (chloe_vol) / +6 px (chloe_vol_manteau) ; anciens = *_avant.png
