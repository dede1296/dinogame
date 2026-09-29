// Côte Préhistorique : le phare en ruine de la Pointe aux Ptéranodons (bâtiment assemblé en 3D,
// tools/modeles3d/maisons.py, sorte phare_ruine). Vues peintes par nano-banana (edit_image, 2K) sur des
// guides rendus depuis le modèle (face, côté droit, dos ; même toile, 12° d'élévation), puis remises sur
// la toile des guides à 240 px/m : generated_imgs/nb-phare_ruine_<vue>.png (sources nano-banana :
// edited-2026-09-28T18-26-50-508Z-yemht4.jpg, …18-27-49-064Z-lkgn4i.jpg, …18-28-25-765Z-lp6mvm.jpg).
// Ramenées à 96 px/m (Prop.KINDS scale 0.5) ; la face est aussi l'image du jeu ; les trois vues, à la
// même échelle, vont dans generated_imgs/vues (docs/direction-artistique.md « Bâtiments assemblés »).
export default ({ props, OUT }) => [
  [`${OUT}/props/phare_ruine.png`, () => props({ id: "nb-phare_ruine_face", scale: 0.4, outDir: `${OUT}/props`,
    boxes: [[113, 155, 928, 2353]], names: ["phare_ruine"] })],
  ["generated_imgs/vues/phare_ruine_face.png", () => props({ id: "nb-phare_ruine_face", scale: 0.4,
    outDir: "generated_imgs/vues", boxes: [[113, 155, 928, 2353]], names: ["phare_ruine_face"] })],
  ["generated_imgs/vues/phare_ruine_cote.png", () => props({ id: "nb-phare_ruine_cote", scale: 0.4,
    outDir: "generated_imgs/vues", boxes: [[74, 211, 1006, 2297]], names: ["phare_ruine_cote"] })],
  ["generated_imgs/vues/phare_ruine_dos.png", () => props({ id: "nb-phare_ruine_dos", scale: 0.4,
    outDir: "generated_imgs/vues", boxes: [[113, 272, 929, 2236]], names: ["phare_ruine_dos"] })],
];
