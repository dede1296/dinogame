# Conception d'une zone 3D — règles générales

> Méthode et règles pour concevoir chaque zone de la version PC 3D (Terrain3D), réutilisables de la
> Prairie aux Cieux. Première application : `zones-3d/plaines-plan.md`. Le format de données est
> `zones-3d/<zone>-layout.json` (§ 8) ; l'outil de vérification est `zones-3d/plaines-plan-outil.py`
> (images + atteignabilité + temps + pentes), réutilisable pour toute zone.

## 1. La méthode en cinq passes

1. **Compréhension** : relire l'histoire de la zone (`histoire.md`), l'audit des ancres
   (`zones-3d/<zone>-audit.md`, `<zone>-ancres.json`), l'état 2,5D (`tools/zones/<zone>.gd`,
   `tools/maps/gen-<zone>.mjs`) ; prendre des captures ; noter ce qui ne va pas (monotonie,
   lisibilité, marches, forêts-murs, culs-de-sac sans récompense).
2. **Partis** : esquisser deux ou trois organisations de la zone (où est le centre, d'où vient-on,
   que voit-on en arrivant, où sont les hauteurs) ; comparer lisibilité, rythme, temps de trajet,
   richesse ; en garder un, dire pourquoi les autres sont écartés.
3. **Plan détaillé** : le JSON (relief, eau, sentiers, secteurs, repères, vignettes, clairières,
   blockers, bords, ancres par groupe), l'image vue de dessus, l'image du relief, le texte.
4. **Autocritique** : simuler un joueur qui arrive sans carte, fait chaque passage et ressort ;
   compter les secondes ; chercher où il se perd, où un repère manque, où un cul-de-sac ne
   récompense pas, où la végétation bloque ; **vérifier par script** (BFS sur grille de 0,5 m) que
   chaque ancre reste atteignable, qu'aucune ancre d'au-delà d'un passage ne l'est avant, qu'aucun
   passage ne fait moins de 1,2 m, qu'aucun sentier ne dépasse sa pente ; corriger et refaire.
5. **Livraison** : image, relief, JSON, texte, et un rapport avec les choix à trancher et les
   demandes aux agents suivants (relief, eau, végétation, décor, modélisation, histoire).

## 2. Équilibre et expérience du joueur

- **Un centre** : la zone a un lieu où l'on revient (hub), avec son repère vivant (PNJ, panneau,
  feu) ; les objectifs partent de là à distance comparable (±30 %), en marchant 25 à 60 s.
- **Comprendre sans carte** : chaque objectif est annoncé par un **repère visible de loin** (un
  objet de 10 m et plus, une silhouette unique, une couleur, une lumière) placé *dans l'axe* de la
  route qui y mène ; un joueur qui tourne sur lui-même au hub voit tous les repères.
- **La révélation** : l'arrivée dans la zone passe par un seuil (crête, porte, lisière) qui cache
  puis découvre d'un coup la composition : le repère principal au centre du cadre.
- **Rythme** : alterner ouvert (prairies, places) / resserré (chemins creux, gorges, sous-bois) /
  surprise (clairière, vallon caché, plongée sur l'eau). Jamais 60 m du même registre.
- **Pas de cul-de-sac sans récompense** : vue, objet (galet, page), détail vivant, scène, repos.
- **Boucles** : au moins une grande boucle qui relie les secteurs sans repasser par le hub.
- **Temps** : Chloé marche à 1,6 m/s, court à 5 m/s ; une zone de 240 × 180 m se traverse en 50 s
  en courant ; un passage complet aller tient en 20-90 s de marche.
- **Taille** : ×2 du 2,5D par défaut ; on peut agrandir ou déformer si le plan l'exige, à condition
  de garder les raccords avec les voisines (positions et hauteurs des sorties).

## 3. L'histoire : ancres et groupes de scène

- Les ancres (PNJ, panneaux, serrures, objets, sorties, points d'arrivée, habitats, herbes hautes)
  viennent de l'audit ; **toutes** sont présentes dans le plan.
- Elles se déplacent **par groupe de scène, en translation pure** (les scènes utilisent des
  directions absolues : jamais de rotation d'un groupe sans réécrire la scène) ; le JSON garde
  `old` et `new` pour chaque ancre et `delta_m` par groupe : c'est le champ de déformation des
  scènes. Les déplacements sont doux (groupes voisins avec des Δ proches, jamais deux groupes
  qui se croisent).
- **La logique reste vraie** : relations (« au carrefour », « au sud de l'étang », « derrière le
  tronc »), ordre libre des passages, accessibilité, places des scènes (couloirs de course, rayons
  dégagés, rectangle vidé devant la caméra), serrures qui ferment vraiment (le prop remplit
  l'ouverture ; l'audit mesure les fuites).
- Les constantes en dur de `story/*.gd` sont listées avec leurs nouvelles valeurs
  (`hardcoded_constants`).
- Les sorties restent sur les bords que donne la géographie de `histoire.md`.

## 4. Le relief (Terrain3D)

- **Jamais de marche** : pentes continues ; Terrain3D à 0,5 m ; ondulations (±0,5 m, longueur
  d'onde 20-30 m) partout sauf près des sentiers, de l'eau et dans les clairières.
- **Pentes** : sentiers principaux ≤ 12°, sentes ≤ 15°, hors sentier praticable jusqu'à 42° ; au-delà
  de 50° c'est une **paroi** : peinte roche (strates), avec éboulis au pied et, sur les grandes
  faces, des modules de paroi ; jamais une pente d'herbe infranchissable.
- **Rampes** : tout plateau accessible a sa rampe (carve) de 3,5 à 7 m de large, 8 à 16 % ; une
  encoche ou une gorge a des murs des deux côtés et un fond en pente douce.
- **Hauteurs** : prairie 3 m au-dessus de la mer ; collines 5-10 m ; plateaux d'histoire 7-14 m ;
  fonds de décor (montagnes) 26-40 m, infranchissables par leur pente.
- **Eau** : nappes plates (étang, mer) avec rive praticable et bandes de profondeur lisibles ; eau
  profonde (> 0,6 m) bloque ; un ruisseau (Waterways) descend avec le sol et ne bloque pas.
- Le sol est **raboté sous les sentiers** (profil lissé) : la route dicte le terrain, pas l'inverse.

## 5. La végétation praticable

- Trois strates par secteur : canopée, sous-bois, couvre-sol, en instances / 100 m², avec des
  essences pondérées (voir `areas[].vegetation`).
- **Traversable** : canopée ≤ 2,4 / 100 m² (troncs à 6-8 m), buissons en bouquets, jamais en rangée
  fermée ; le couvre-sol ne bloque jamais.
- **Fermé, et visible** : haie de ronces / blocs / troncs couchés (1,6 m et plus, 3 m d'épaisseur),
  talus (> 0,7 m), lisière dense aux bords de zone (troncs à 4 m avec sous-bois solide) ; jamais une
  forêt-mur ni un mur invisible.
- Sentiers dégagés : 1,5 m (principal), 1,2 m (sente), 1 m (piste) de tout décor solide.
- Clairières : places des scènes et des récompenses, sans décor moyen ou grand (sauf les ancres).
- Herbes hautes : les nappes de rencontre, sans décor solide.
- Lumière : penser la canopée pour le soleil (trouées, sous-bois, crêtes au coucher).

## 6. Les props

- **Hiérarchie** : repères (visibles > 100 m) → grands (10-50 m) → moyens → petits. La richesse
  guide le regard : dense autour des repères et des vignettes, rare entre.
- **Groupes** : un grand prop a toujours sa cour de moyens et de petits (rocher + cailloux +
  fougères + une fleur) ; un seul objet isolé au milieu d'une prairie est une exception voulue
  (l'arbre du dormeur).
- **Vignettes composées** : 20-30 par zone, numérotées, avec orientation et liste d'éléments : ce
  que l'on voit depuis le sentier, ce qu'une bulle décrit (règle « détails vivants »).
- **Zones calmes** : rien de moyen ou de grand ; elles reposent l'œil et laissent la place aux scènes.
- Chaque nouveau prop est listé avec ses dimensions, ses variantes, sa priorité, son budget.

## 7. Budgets (GTX 1650 Ti, Forward+, > 90 im/s)

- 11 ms par image ; < 2,5 M triangles dans le champ, < 700 draw calls.
- Instances : ~1 300 arbres, ~900 sous-bois, ~5 000 couvre-sol, ~300 rochers par zone de 240 × 180 m.
- MultiMesh par sorte et par carré de 32 m, LOD générés, portées : couvre-sol 90 m, buissons 140 m,
  arbres 240 m avec fondu ; ombres portées seulement pour arbres, rochers, os, héros.
- Un prop héros (Grand Crâne) ≤ 25 000 tris ; arbres 2 500 / 600 (LOD2) ; buissons 900 ; rochers 1 200.
- Terrain3D : 0,5 m, 8 textures au plus ; eau en miroir 0,3 × une image sur deux.

## 8. Format `<zone>-layout.json` (schéma `ambrelune-zone-layout/2`)

Positions en mètres, repère `ZoneSource` : origine au coin nord-ouest, x vers l'est, z vers le sud,
y = hauteur au-dessus de la mer. Clés :

| Clé | Contenu |
|---|---|
| `zone`, `name`, `size_m`, `tile_scale`, `frame`, `parti`, `size_note`, `levels_m` | identité, taille, repère, parti en une phrase, hauteurs de référence |
| `relief.base_m`, `relief.modifiers[]` | modificateurs appliqués dans l'ordre : `dome` (center, radii, rot_deg, height, flat), `plateau` (polygon ou center+radii, level, edge_m, wobble_m), `ridge` (points, half_width_m, height, falloff_m, absolute), `gradient` (axis, from, to), `water_basin` (polygon, level, depth, inner_m, outer_m), `carve` (points, width_m, levels ou follow_ground+offset_m, blend_m), `noise` (amplitude_m, wavelength_m, clear_paths_m), après l'eau `plateau_ellipse_after_water` (îlot), `rect_after_water` (gué) ; `op` = add / max / set |
| `water[]` | mer, étangs (ellipse, level, depth), sources, ruisseaux (points, width_m, depth), cascades |
| `paths[]` | polylignes : kind main / secondary / trail, width_m, clear_m, grade_max_deg, points, note |
| `areas[]` | secteurs : polygon (+ polygon2), ambiance, vegetation {canopy, understory, ground : per_100m2 + species pondérées}, props_set, tall_grass (ellipses), calm, walkable, note |
| `landmarks[]` | repères : at, type, size_m, visible_from, note |
| `vignettes[]` | at, yaw_deg, type, elements[], clear_radius |
| `clearings[]` | center, radius, reason |
| `blockers[]` | hedge / bank (polyline, width_m, height_m, gap, closed), trunk, boulder (eboulis_m), door, moon_ford, cliff, deep_water, forest_edge (polygon) ; reason |
| `edges` | par bord : neighbour, join (kind, x_range/z_range, height_m, width_m), neighbour_offset_note, elsewhere, backdrop |
| `scene_groups` | par groupe : delta_m, note, audit_group |
| `anchors[]` | id, group, kind, old / new (ou old_points / new_points, old_rect / new_rect), moved_m, note |
| `hardcoded_constants` | les constantes de `story/*.gd` avec leurs nouvelles valeurs |
| `audit_reconciliation` | ce qui a été repris de l'audit, les risques traités |
| `budget`, `new_props[]` | budgets ; props à modéliser (dims_m, tris, variants, priority) |

Les agents lisent : relief → `relief`, `water`, `paths` (profil) ; végétation → `areas`,
`clearings`, `paths.clear_m`, `blockers` ; décor → `landmarks`, `vignettes`, `anchors`,
`new_props` ; histoire → `scene_groups`, `anchors`, `hardcoded_constants`.

## 9. Checklist de validation (avant de livrer, puis après construction)

- [ ] Toutes les ancres de l'audit sont dans le JSON, avec `old` et `new`, par groupe (translation pure).
- [ ] BFS (0,5 m, pente ≤ 42°, eau > 0,6 m bloquante, érosion 3 × 3) : chaque ancre atteignable
      depuis l'arrivée avec les passages ouverts ; aucune ancre d'au-delà d'un passage atteignable avant.
- [ ] Aucun passage de moins de 1,2 m ; aucun sentier au-dessus de sa pente maxi ; aucune cellule
      de sentier sur une paroi ou dans l'eau profonde (quelques-unes aux bords : à lisser).
- [ ] Aucun prop solide sur un sentier ni dans son dégagement ; aucun décor dans une clairière
      hors ancres ; aucun décor solide dans les herbes hautes.
- [ ] Chaque serrure ferme vraiment (le prop remplit l'ouverture) ; 6 m dégagés du côté d'approche.
- [ ] Les places de scène respectées (couloirs de course, rayons dégagés, rectangles vidés).
- [ ] Chaque objectif a un repère visible depuis le hub et depuis l'arrivée ; chaque cul-de-sac a sa récompense.
- [ ] Les sorties sont aux bords prévus, aux hauteurs de raccord ; le fond de décor montre la voisine.
- [ ] Aucun mur invisible : tout ce qui bloque est une haie, un talus, une paroi, un tronc ou de l'eau que l'on voit.
- [ ] Jamais de marche de grille ; les pentes > 50° sont peintes roche.
- [ ] Budget tenu (instances, triangles, draw calls) ; > 90 im/s mesurés à l'aube (le moment le plus lourd).
- [ ] Les temps de trajet du plan sont retrouvés en jeu (±20 %).
