# Direction artistique — Ambrelune (Godot)

Objectif : **l'Ambrelune actuel, avec une qualité de production supérieure**. Même univers,
mêmes personnages, mêmes couleurs ; plus de détail, plus d'animation, plus d'effets.

**Rendu 2,5D** (depuis le 2026-09-26) : un sol 3D en relief, sur lequel les images 2D (décor,
personnages, dinos) tiennent debout face à la caméra, légèrement inclinée. Conséquences pour les
images :
- tout est dessiné **de face, vu légèrement du dessus** (comme les arbres actuels), jamais en
  isométrique : une façade de maison est parallèle à l'écran ;
- les personnages ont 4 directions ; les dinos un profil et une planche face/dos ;
- pas d'ombre peinte au sol dans les images : les ombres sont calculées (soleil, lune) ;
- les très grands éléments (arbres) deviennent transparents quand ils cachent Chloé.
- le décor debout reçoit un éclairage « arrondi » (volume) et une ombre de contact au pied ;
  les parois de falaise ont leur propre texture (`assets/art/ground/falaise.png`, raccordable,
  1 répétition ≈ 2,2 m) ; l'eau lit la hauteur du sol (profondeur, écume sur la rive).
- **Monde ouvert** : les bords d'une région sont naturels, jamais un mur invisible. Montagnes en
  **corniches** de 2 niveaux (2,4 m) plutôt qu'en pente douce (une longue pente se lit comme un
  talus flou) ; forêt dense (arbres posés automatiquement, **buissons le long des chemins** pour
  ne rien masquer) ; mer avec plage de sable.
- **Entrées de grotte** : un trou sombre aux bords irréguliers, au fond d'une encoche creusée
  dans une vraie colline, jamais une porte posée dans le vide. Les portes d'ambre de l'histoire
  sont prises dans une falaise ou une encoche du relief.
- **Falaises** : roche plus grise et plus sombre que les chemins (ocre), avec une ombre au pied
  de chaque paroi, pour ne jamais confondre un chemin et un flanc de colline. Les murs de
  collision couvrent toute la profondeur de la paroi dessinée : personne ne se tient dessus.
- **Carte du monde** : style carte d'exploratrice sur papier (couleurs douces du sol, relief
  ombré depuis le nord-ouest, courbes de niveau brunes, bois en petites couronnes, trait de rive) ;
  l'inexploré reste papier blanc, avec un bord brun irrégulier comme brûlé.

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
- 1 case = 48 px en 2D = 1 m en 3D ; un niveau de relief = 1,2 m.
- Ombres : calculées en 3D (soleil, lune), pas d'ombre peinte dans les sprites.
- Effets vivants préférés aux images fixes : balancement des plantes (shader), eau animée,
  ombres de nuages, pollen, lueur de l'ambre, lumière qui tourne avec l'heure.

## Points à surveiller

- Halo rose léger autour des objets lumineux (l'ambre) : la lueur se mélange au magenta ;
  régénérer ces objets sans halo et ajouter la lueur en jeu (PointLight2D).
- Chaque espèce = une planche de profil (6 cases) + une planche face/dos (8 cases), produites
  par lots, région par région (~60 espèces, voir [bestiaire.md](bestiaire.md)).
