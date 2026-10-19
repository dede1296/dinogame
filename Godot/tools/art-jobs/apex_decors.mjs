// Chapitre 9 — Terre des Apex : props, sols raccordables. (Les icônes et le fond de combat : apex_ui.mjs.)
// Méthode : nano-banana édite une image du jeu (portail_apex, ambre, banc, torche) sur fond magenta ; boîtes
// [x, y, l, h] mesurées sur l'aperçu affiché en 2000 px de large, converties dans la résolution de la source.
// Aucune ombre peinte au sol. `portail_apex.png` (fermé) et `banc.png` existent déjà : rien de nouveau pour le banc.
const px = (list, k) => list.map((b) => b.map((v) => Math.round(v * k)));
export default ({ props, seamless, OUT }) => {
  const jobs = [];
  const sheet = (out, id, boxes, k, scale, names) =>
    jobs.push([out, () => props({ id, scale, boxes: px(boxes, k), outDir: `${OUT}/props`, names })]);
  // Portail ouvert (1024×1024 : seule la pièce entière).
  sheet(`${OUT}/props/portail_apex_ouvert.png`, "lffo06", [[20, 10, 984, 1010]], 1, 0.47, ["portail_apex_ouvert"]);
  // Le grand bloc : entier (Souverain et Hélène dedans), fendu en étoile, éclaté (planche 3168 px).
  sheet(`${OUT}/props/bloc_souverain.png`, "4xj84r", [[20, 20, 650, 820], [690, 20, 640, 820], [1340, 280, 630, 540]],
    1.584, 0.8, ["bloc_souverain", "bloc_souverain_fendu", "bloc_souverain_eclate"]);
  // Blocs des géants 1 à 4 (planche 2752 px) : patte à faux, cou enroulé, plaques et queue, petit bloc à plume.
  sheet(`${OUT}/props/bloc_geant_1.png`, "qj05d2", [[60, 25, 610, 770], [700, 25, 610, 770], [1350, 25, 620, 770], [570, 735, 310, 375]],
    1.376, 0.8, ["bloc_geant_1", "bloc_geant_2", "bloc_geant_3", "bloc_geant_4"]);
  sheet(`${OUT}/props/cairn_helene.png`, "qj05d2", [[1160, 765, 390, 330]], 1.376, 0.12, ["cairn_helene"]);
  // Petits objets (planche 3168 px) : tasse bleue ébréchée, caisse de carnets, torche éteinte, masque en carton posé.
  sheet(`${OUT}/props/tasse_bleue.png`, "tnkzz6", [[10, 205, 435, 490]], 1.584, 0.1, ["tasse_bleue"]);
  sheet(`${OUT}/props/caisse_carnets.png`, "tnkzz6", [[470, 40, 670, 710]], 1.584, 0.094, ["caisse_carnets"]);
  sheet(`${OUT}/props/torche_eteinte.png`, "tnkzz6", [[1080, 10, 400, 850]], 1.584, 0.094, ["torche_eteinte"]);
  sheet(`${OUT}/props/masque_carton_sol.png`, "tnkzz6", [[1450, 260, 545, 430]], 1.584, 0.06, ["masque_carton_sol"]);
  // Isaure assise, Hélène contre elle (prop fixe, 1024 px).
  sheet(`${OUT}/props/isaure_helene.png`, "yxmzjf", [[40, 50, 940, 930]], 1, 0.14, ["isaure_helene"]);
  // Sols (vues de dessus, sans ombre, raccordables, 512×512). veines_ambre* : trois états de la même texture
  // (ambre = normal, blanc = pendant l'éveil, or = après) ; à fondre par le jeu.
  const GROUND = [["roche_apex", "j2pjju"], ["roche_apex_fond", "82tmki"], ["veines_ambre", "9tvl9o"],
    ["veines_ambre_blanc", "vuy5g8"], ["veines_ambre_or", "lwcvm1"]];
  for (const [name, id] of GROUND) jobs.push([`${OUT}/ground/${name}.png`, (out) => seamless({ id, size: 512, out })]);
  return jobs;
};
