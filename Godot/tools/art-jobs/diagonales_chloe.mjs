// Mémo de méthode (pas un job process-art) : planches de marche en trois-quarts de Chloé,
// assets/art/characters/{chloe,chloe_bottes,chloe_manteau}_diag.png (19/10).
// Format : même cellule que X.png (123×184, 122×185, 143×184), 4 colonnes (cycle) × 2 lignes :
//   ligne 0 = bas-gauche (trois-quarts face), ligne 1 = haut-gauche (trois-quarts dos). Les diagonales droites = miroir en jeu.
// Colonnes : 0 jambes ensemble, 1 grand pas (pied gauche devant), 2 pied arrière levé, 3 pied avant en balancement.
// Recette (nano-banana, edit_image, fond magenta #FF00FF, aspect 2:3, 1 image / appel) :
//  1. fiche bas-gauche et haut-gauche : essai validé agrandi ×4 sur magenta + vues de chloe.png en référence ;
//     corrections : yeux marron foncé, taches de rousseur discrètes, queue de cheval courte, gilet simplifié.
//  2. images du cycle : toutes éditées depuis la fiche (une consigne = une jambe/bras), jamais de dérive de proportions.
//  3. bottes / manteau : chaque image de chloe_* éditée avec la planche concernée en référence (vues face/profil/dos),
//     en ne changeant que bottes (hautes, tige lacée, bouton doré, semelle orange) ou tenue (manteau moutarde, col fourrure,
//     mitaines, collants verts, bottes à revers crème) ; poses identiques à la planche de base.
//  4. détourage : fond magenta -> alpha, plus grande composante, échelle UNIQUE par ligne (hauteur médiane -> 175 px),
//     pieds à 4 px du bas, centre = milieu du buste (60 % du haut). Pas de process-art.mjs.
// Limite connue : en trois-quarts, nano-banana colle à la pose de la fiche ; le pas inverse (autre jambe devant) n'est pas
// distinct, d'où les poses « pied arrière levé » et « pied avant en balancement ».
export default () => [];
