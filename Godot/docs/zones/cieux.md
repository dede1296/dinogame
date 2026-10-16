# Cieux Éternels (carte) — chapitre 7

> Agent CARTE, 11/10. Les trois zones `cieux`, `nids_geants`, `arche_du_vent` (`regions/cieux/`), générées par
> `tools/zones/cieux.gd`, `nids_geants.gd`, `arche_du_vent.gd` (peinture commune `cieux_canvas.gd`, décor
> `cieux_decor.gd`, pieds des décors `cieux_pieds.gd`) ; lieux nommés dans `story/cieux_places.gd` (`CieuxPlaces`).
> Construire : `--script res://tools/build_zone.gd -- cieux --force` (idem pour les deux autres) : chaque plan
> affiche ses vérifications. Tester : `tools/scenarios/vis_cieux.gd` (lieux, accès à pied, décor qui flotte,
> cordes des ponts, jonctions, heures, météos, zoom) et `perf_cieux.gd` (images par seconde).

## Le parti

Trois zones l'une au-dessus de l'autre, qui montent vers le nord (la caméra regarde le nord : les parois des
pitons font face au joueur, rien de haut ne cache le chemin) :
- **`cieux` — Les Pitons** (100 × 86 cases) : le couloir des Monts débouche (bord sud) sur une arête au-dessus des
  nuages, puis le Piton d'Arrivée (10,8 m, feu, panneaux). Le premier pont de lianes mène au Guet (11,4 m, le
  carrefour) ; à l'ouest la Mer de nuages (un grand piton dont le creux est plein de nuages où l'on marche ;
  Tupandactylus à l'aube) ; au nord les Vents (12 m) puis le Haut (12,6 m) sous le Rempart, que la rampe taillée
  traverse jusqu'aux Nids (bord nord) ; à l'est une boucle (le Fendu, le long pont, le piton des
  Rhamphorhynques) et le Belvédère (13,2 m, le plus haut à pied : page 31, un banc).
- **`nids_geants`** (70 × 60) : la rampe sort du Rempart sur l'Aire des Plumes (13,8 m, feu sous un nid effondré),
  une rampe vers les nids (14,4 m : nids « grands comme des barques », jeunes Quetzalcoatlus, Tapejara, page 32),
  une autre vers le Grand Nid (15 m : carré de 9 × 7 libre, le Roi au bord nord tourné vers l'entrée), un pont de
  lianes vers l'aiguille du bord nord : la sortie vers l'Arche (fermée tant que `vol_obtenu` est faux).
- **`arche_du_vent`** (56 × 44) : la plateforme d'atterrissage (15 m, le haut de l'aiguille), une rampe vers la
  terrasse (16,2 m) : le carré de la scène (12 × 10, plat, nu), l'arche au nord de ce carré, le cairn d'Hélène
  (page 34), le feu à l'abri du pilier ouest, la descente de cendre au nord-ouest (fermée : `volcan_bloque`).

## Le vide entre les pitons, les ponts

- Le vide est **la mer de nuages, plus bas** : des cases de sol peintes en nuages (`nuages.png`), 3 à 8 m sous
  les plateaux. À pied, les **falaises ordinaires** arrêtent Chloé (comme les crevasses des Monts) ; en vol, on
  passe au-dessus ; on ne s'y pose pas : méta `vol_vide_sous` (10 m aux Pitons, 13,2 m aux Nids et à l'Arche,
  où la mer de nuages est plus haute ; les deux mers se rejoignent à 9,8 m au bord commun).
- Un **pont de lianes** est une bande de sol de 2 cases à la hauteur des plateaux, toujours droite (nord-sud ou
  est-ouest : en biais, il se casse en marches), son tablier en planches (`pont_lianes.png`), des poteaux sur ses
  bords ; le long du pont, les nuages montent en bancs jusqu'à 1,2 m sous le tablier (il rase les nuages).
- Lieux qu'on n'atteint qu'en volant (sans danger, pas nécessaires) : l'îlot de la page 33, l'aiguille au nid
  (un galet), le balcon des brumes (un vieux coffre, un fossile), le nid oublié (une fougère) ; de vieux ponts
  rompus pendent des bords qui leur font face. Aires où se poser : `CieuxPlaces.ATTERRISSAGES_*`, chacune avec un
  drapeau de vent.

## Cordes des ponts

Retour de Greg (11/10) : « aux nids géants, aucune corde ne relie les piquets ». Le garde-corps court
désormais de poteau en poteau, de chaque côté de chaque pont qui a des poteaux.
- **Déclarées dans la zone** : un nœud `Cordes` (type `Node`, dernier enfant de la racine de la zone), sa
  métadonnée `paires` = les poteaux à relier par leur nom dans `Entities` :
  `[["PilierPont1", "PilierPont3"], ["PilierPont3", "PilierPont5"], …]`. `cieux_decor.gd` les produit :
  `bridge_posts` rend, côté par côté, les paires de poteaux voisins (la corde s'arrête là où un poteau manque :
  au bout d'un pont, ou d'un côté qui n'en a pas) ; `ropes()` écrit le nœud après `settle_all` (un poteau
  retiré emporte ses cordes). Dans l'éditeur, déplacer un poteau déplace sa corde ; ajouter une corde =
  ajouter une paire. Aujourd'hui : 23 cordes aux Pitons, 4 aux Nids, aucune à l'Arche (pas de pont de lianes).
- **Dessinées par la vue** (`world/view3d/ropes.gd`, classe `Ropes`, appelée par `WorldView.show_zone`) : un
  seul maillage par zone (des rubans tournés vers la caméra, `corde.gdshader` : torsade ocre peinte, contour
  brun, éclairée comme un cylindre), une corde nouée là où l'image du poteau dessine la sienne (`ATTACH` :
  ~1 m au-dessus de son pied), affaissée en chaînette de 8 % de sa longueur (~0,8 m au milieu d'une travée de
  3 m) ; ses bouts passent derrière l'image du poteau. Aucune collision (rien en 2D : les ponts restent
  praticables). Ombre aplatie fine (`ombre_corde.gdshader`, mécanisme `FlatShadows`, genre `corde_pont`) en
  qualité Moyenne et Haute ; en Basse, les cordes restent, sans ombre. Coût mesuré : 2 appels de dessin et
  ~1 000 triangles de plus, images par seconde inchangées (138 contre 137 sans).
- **Le soleil vient toujours du sud** (derrière la caméra) : comme celle des poteaux, l'ombre d'une corde
  tombe presque derrière la corde elle-même à l'écran ; elle se voit peu, c'est normal.
- **Ponts rompus** (`pont_lianes_rompu`) : une seule image, planches, poteaux et cordes cassées qui pendent
  dessinés dedans ; aucune corde déclarée : rien n'est tendu au-dessus du vide.
- **Les quatre ponts nord-sud des Pitons** (Guet → Vents, Vents → Haut, Fendu → Rhamphorhynques, Fendu →
  Belvédère) **n'ont aucun poteau**, donc aucune corde : la base de pierre des piliers est mesurée en travers
  de l'image, donc en travers du tablier sur un pont nord-sud ; celle de `pilier_pont_2` (0,80 m) y reste au
  mieux 0,32 m au-dessus du dessus bombé du tablier (`cieux_pieds.gd`, tolérance 5 cm) ; `pieu_corde` (base
  de 6 cm) y tiendrait. À décider : un poteau étroit pour ces ponts (repli par poteau dans `bridge_posts`),
  ou un tablier plus plat ; les cordes suivraient d'elles-mêmes.
- Test : `vis_cieux.gd` « verifier » : chaque corde déclarée relie deux poteaux de la zone à moins de 7 m.

## Règles que les plans tiennent (et que le test vérifie)

- **Rien ne flotte** (retour de Greg, 11/10 : « les pitons volent de part et d'autre des chemins ») : la vue pose
  un décor au niveau de sa case, alors que le sol dessiné, échantillonné tous les demi-mètres, descend déjà vers
  le vide au bord d'un pont ou d'un plateau ; les poteaux des ponts, posés à 0,88 case de l'axe, pendaient donc
  0,4 à 0,8 m au-dessus de la pente. Désormais chaque décor est mesuré (`cieux_pieds.gd` : base dessinée de
  l'image, son pied, la largeur de sa base, contre le sol dessiné) et déplacé là où il tient (tolérance 5 cm) ;
  les poteaux se posent sur le plat du tablier, pied tourné vers l'axe. Les aiguilles dans les nuages ont le pied
  enfoncé dans les nuages (pas de remplaçant dont la base serait posée sur eux).
- **Pas de ligne nette entre deux sols** (retour de Greg) : la neige est la 1re couche (sur un sentier, elle
  devient un sentier de neige tassée, comme aux Monts) ; elle couvre tout au bord des Monts et s'efface vers les
  Nids et au bord de l'Arche, qui n'en ont pas ; la paille des nids et les nuages de la Mer s'effilochent sur
  2 cases ; le bord des Monts se prolonge au sud des Pitons par une lisière de rocs enneigés (12,6 m, bord
  irrégulier) qui tombe dans les nuages.
- Accès à pied depuis l'entrée vers chaque lieu clé (le corps de Chloé balayé le long du chemin, autour des
  décors solides), îlots seulement en vol, aucun décor solide sur un chemin.

## Le patch commun (appliqué à l'intégration, 11/10)

ZONES (`world.gd`), noms (`zone_map.gd`), falaises de roche grise et touffes de toundra (`world_view.gd`), les
décors de l'agent IMAGES dans `Prop.KINDS` (`prop.gd`), petite faune (`wildlife_db.gd`), atlas (`gen-atlas.mjs`, qui
reprend aussi le nom « Prairie du Grand Crâne »). Les trois zones ont été régénérées ensuite (« tous les lieux sont
bons »), `vis_cieux.gd` : 3 × « 0 vérification(s) en échec ».
