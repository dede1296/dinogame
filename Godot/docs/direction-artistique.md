# Direction artistique — Ambrelune (Godot)

Objectif : **l'Ambrelune actuel, avec une qualité de production supérieure**. Même univers,
même vue, mêmes personnages et mêmes couleurs que la version Phaser ; plus de détail, plus
d'animation, plus d'effets.

## Style

- Illustration cartoon **peinte à la main** : contours **brun foncé** nets, ombrage peint doux,
  **lumière dorée venant du haut à gauche**, ambiance chaleureuse et lisible (jeu pour Chloé :
  amical, jamais effrayant).
- Vue **top-down trois-quarts** (on voit le dessus et la face des objets), comme la version Phaser.
- Personnages en **proportions chibi** (~2,5 têtes), expressifs.
- Dinos : silhouettes claires, couleurs naturalistes légèrement saturées, ventre clair,
  yeux expressifs. Les familles restent reconnaissables (raptor, cératopsien…).
- Décors : végétation préhistorique (fougères arborescentes, araucarias, fougères), fleurs
  roses, jaunes et violettes, pierres grises, bois brun chaud.

## Palette de référence

| Rôle | Couleur |
|---|---|
| Fond d'interface (ardoise) | `#1b1f28` |
| Accent ambre (bordures, titres) | `#c98a2a` / clair `#fac259` |
| Texte clair | `#f5eddb` |
| Herbe | verts chauds `#5f9a36` → `#8fbf45` |
| Chemins | ocre `#c79a5a`, bords plus sombres |
| Eau | `#22607a` (profond) → `#54a0a0` (bord), écume `#edf2db` |
| Contours | brun `#2a180c` |

Chloé : cheveux auburn en queue de cheval (barrette sarcelle), t-shirt sarcelle, gilet
d'explorateur kaki, short olive, bottines brunes, sac ambre.
Maïa : peau brun chaud, cheveux bouclés noirs, bandana rouge, débardeur moutarde, short
cargo marine, corde à l'épaule.

## Production des images (nano-banana)

- Toujours décrire le style ci-dessus dans le prompt ; pour un nouveau personnage, **éditer
  une planche existante** (référence de style) plutôt que partir de zéro.
- Fond **magenta pur `#FF00FF`** uni, sans ombre au sol ni texte → détourage par
  `tools/process-art.mjs` (décontamination des bords incluse).
- Planches de personnages : grille **4×4** (bas, gauche, droite, haut × 4 pas).
  Planches de dinos : **2×3** (3 pas de marche ; repos, repos 2, attaque), profil **vers la droite**.
  Planches de décor : objets bien séparés (détection automatique, ordre de lecture).
- Textures de sol : vues de dessus, sans ombre directionnelle, rendues raccordables par l'outil.
- Résolution : générer en 2K, exporter à **2× la taille d'affichage** (le jeu est pensé en
  1280×720 et affiché à ~2× sur le S25 Ultra) ; le mipmapping gère les réductions.

## Échelle et conventions

- Grille logique **48 px** (comme Phaser). Chloé ≈ 95 px de haut à l'écran de base.
- L'origine d'un objet = son point de contact au sol (tri en Y).
- Ombres de contact : ovales doux générés (`world/shadow.gd`), pas d'ombre peinte dans les sprites.
- Effets vivants préférés aux images fixes : balancement des plantes (shader), eau animée,
  ombres de nuages, pollen, lueur de l'ambre.

## Points à surveiller

- Halo rose léger autour des objets lumineux (l'ambre) : la lueur se mélange au magenta ;
  régénérer ces objets sans halo et ajouter la lueur en jeu (PointLight2D).
- Les dinos hybrides demanderont des **planches par parties** (tête, corps, pattes, queue)
  assemblées en jeu (rig 2D) : à valider sur 2 espèces à l'étape hybridation.
