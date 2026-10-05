# Prairie du Grand Crâne (zone `plaines`) : audit des points d'ancrage pour le remodelage 3D

Audit en lecture seule, 04/10/2026. Données lues dans la zone 2,5D elle-même (`regions/plaines/plaines.tscn`, ouverte hors de l'arbre par `ZoneSource`), pas seulement dans les générateurs : ce qui est dit ici est ce que le jeu fait aujourd'hui. Version lisible par machine : `plaines-ancres.json` (même dossier).

**Conventions.** `tuile` = cases du 2,5D. `px` = tuile × 48 (les scènes d'histoire parlent en pixels : `S.at(x, y)` = tuile × 48, `story/story.gd:455`). `mètres` = position dans la zone 3D = tuile × 2 sur x et z (`ZoneSource.to_3d`, `world3d/zone3d/zone_source.gd:73-76`) ; `h` = hauteur du sol en mètres (non mise à l'échelle). Azimut : degrés dans le sens horaire depuis le nord (−z), x vers l'est, z vers le sud. « À pied » : distance de marche en mètres depuis `DepuisPort`, avec les règles de `Blockers3D` d'aujourd'hui (§ 4).

## 0. L'essentiel

- **85 ancres** : 16 pebble_prop, 10 spawn, 9 sign, 8 dig_spot, 7 story_decor, 5 pickup, 5 rest, 4 pebble_pickup, 4 exit, 3 npc, 3 obstacle, 3 story_prop, 2 cave_mouth, 2 dino_npc, 2 sleeper_dino, 1 fleeing_dino, 1 moon_ford ; plus 7 habitats, 13 rectangles à garder dégagés, 13 patchs d'herbes hautes, 1 étang et 1 crique, 4 sorties.
- **Le 3D d'aujourd'hui ne porte presque aucune ancre** : seuls les `Npc` (Maïa, Maïa du défi, Élise), les props simples, les habitats, les herbes hautes et l'ambiance sont lus. Obstacles, panneaux, objets, galets, `StoryProp`, `DinoNpc` (Alpha, Grand Voyageur), dormeurs, Chipie, gué de lune, bancs/feux utilisables et sorties **n'existent pas encore** en 3D (`world3d/zone3d/zone_source.gd:109-120`, `world3d/actors/npc_source.gd:22-44`).
- **Contrainte la plus forte : les 4 serrures ne ferment plus rien.** La zone est ×2 mais les objets gardent leur taille réelle : le tronc (2,2 m), le rocher (2,0 m) et la porte d'ambre (2,0 m) bouchent des ouvertures de 4 m, la porte du Crâne (4 m) une encoche de 8 m. Mesuré : le bosquet, la grotte, le poste d'observation et le Crâne restent atteignables avec les obstacles en place (§ 4, tableau « fuites »).
- **Quatre passages de 4 m (3,5 à 4 m mesurés) sont l'histoire** : l'ouverture de l'anneau de forêt (bosquet), l'encoche de la butte (grotte), le défilé (falaises) et l'encoche du Crâne. Tout le reste de la zone est une prairie large (≥ 5 m partout).
- **Trajets** (arrivée → …) : carrefour de Maïa 89 m, Grand Voyageur 81 m, porte du Crâne 108 m, porte d'ambre 122 m, rocher/grotte 128 m, tronc 127 m (bosquet 155 m), poste d'observation 191 m, sortie forêt 140 m ; sortie du port à 3 m. À 3,44 m/s : 31 s jusqu'au Crâne, 26 s jusqu'à Maïa.
- **Hors de portée à pied** : l'îlot de l'étang (gué de pleine lune non porté en 3D), les montagnes du nord et de l'est, le dessus de la butte du Crâne. **Cul-de-sac singulier** : un rebord de 2 m à 4,8 m le long de la montagne est (289 m de marche) mène à un seul galet (`galet_plaines_04`).
- **Déplaçable** : § 3.2 (groupes de scène avec positions relatives, à déplacer en bloc), § 3.3 (les 33 coordonnées en dur de `story/*.gd`, `objectives.gd` et `tools/zones/plaines.gd` à recalculer si une ancre bouge) et § 3.4 (relations à conserver).

## 1. Les faits de la zone

| Fait | Valeur et source |
|---|---|
| Taille 2,5D | 120 × 90 cases (`data/dex_places.gd:13`), niveaux sauvages 3-7 (`tools/zones/plaines.gd:45`) |
| Taille 3D | **240 × 180 m** (échelle 2 m/case, `ZoneSource.DEFAULT_SCALE`) ; le sol continue 10 cases = **20 m** au-delà des bords (`HeightMap.MARGIN`) et la nappe de mer déborde de 260 m (`docs/migration-3d.md:230`) |
| Relief | 0 à **12,0 m** (`tools/maps/plaines_relief.png`, 5 cm par niveau de gris ; hauteurs vraies, non mises à l'échelle). Falaise = marche > **0,75 m** entre deux cases voisines (`world/region.gd:84,267`) ; 1 144 arêtes de falaise entre cases (forêt et eau comprises), 78 petites marches de 0,35-0,75 m (rampes en marches de 0,6 m) |
| Eau | **niveau d'eau −0,425 m** (`HeightMap.WATER_LEVEL`, fond creusé de 0,85 m) ; étang des Chanteurs : **50 cases (200 m²)**, cases 74-83 × 45-50 ; crique/mer du sud-ouest : **773 cases (3 092 m²)**. L'eau arrête Chloé (couche eau de `Blockers3D`) |
| Sols (cases) | grass 7340, forest 1325, water 823, tall_grass 631, path 548, sand 133 (herbes hautes = 631 cases = 2 524 m² ; forêt = 1 325 cases = 5 300 m²) |
| Chloé | rayon 0,17 m, haut 1,5 m, marche max 0,35 m, saut 0,65 m, pente max 46° (`world3d/player/player_3d.gd:23-32,77`) ; vitesse 3,44 m/s, course ×1,45 = 4,98 m/s (`actors/player.gd:15,25`) |
| Ce qui bloque | forêt (cases), eau, falaises > 0,75 m (mur des deux côtés), 4 bords, props « solides » à leur taille réelle (arbre : cylindre r 0,33 m ; tronc 2,17 × 0,63 m…) (`world3d/zone3d/blockers_3d.gd:23-148`) |
| Dinos de compagnie | agent_radius 0,5 m pour le maillage de navigation (`zone_3d.gd:_add_navigation`) |

### 1.1 Décor déjà semé en 3D (`Scatter3D`, `world3d/zone3d/scatter_3d.gd`)

**3540 éléments** : 732 props du 2,5D (chacun à sa place), 893 arbres/buissons de forêt (1 pour 6 m² de case forêt) et 1915 petites plantes de remplissage (1 pour 14 m² d'herbe rase, hors pentes), plus ≈ 6 500 touffes d'herbe haute au maximum (`TallGrass3D`, 2,6/m² avant le profil de qualité). Comptes rejoués par `scratchpad/agent_audit/decor.gd` avec les mêmes tirages.

| props posés à la main / semés par le 2,5D | nombre |
|---|---|
| fougeres | 186 |
| fleurs_roses | 136 |
| fleurs_violettes | 129 |
| buisson | 55 |
| fougere_arbre | 48 |
| arbre_rond | 41 |
| cailloux | 33 |
| araucaria | 28 |
| souche | 25 |
| ronces | 23 |
| champignons | 7 |
| rocher | 7 |
| feu_camp | 3 |
| banc | 2 |
| nid_dimorphodon | 2 |
| prele | 2 |
| pierre_plate | 1 |
| rocher_grotte | 1 |
| rocher_oeuf | 1 |
| stalagmite | 1 |
| table_observation | 1 |

Forêt (`_woods`) : arbre_rond 377, araucaria 244, buisson 152, fougere_arbre 120. Remplissage (`_fill`) : fougeres 794, fleurs_violettes 378, fleurs_roses 354, buisson 202, cailloux 187.

Modèles 3D existants (`world3d/zone3d/nature_models.gd:14-41`, 13 sortes, 21 modèles) : arbre_rond, araucaria, fougere_arbre, buisson, ronces, fougeres, prele, rocher, cailloux, souche, champignons, fleurs_roses, fleurs_violettes. **Sans modèle** (dessinés en image dressée) : banc, feu_camp, nid_dimorphodon, pierre_plate, rocher_oeuf, rocher_grotte, stalagmite, table_observation.

### 1.2 Ce que la zone a de remarquable (d'après l'histoire)

- **Le Grand Crâne**, crâne fossile géant (butte de 3,6 m, encoche de 8 m), fermé par une porte d'ambre à trois creux d'écailles ; le gardien de la Prairie, le Tricératops Alpha, y dort (`docs/histoire.md:46-47,66-69`).
- **L'étang des Chanteurs** (200 m²) : les nuits de pleine lune les Parasaurolophus chantent, un gué d'ambre mène à l'îlot où Hélène a laissé la page 2 (« Chacun chez soi ») (`histoire.md:112-117`).
- **Les falaises au nord-est** : crête, défilé de 4 m fermé par la porte d'ambre (fougère gravée), plateau à 2,4 m, terrasse à 4,8 m avec **le poste d'observation d'Hélène** (longue-vue, table, banc, feu), **nids de Dimorphodons** sur la corniche.
- **La Grotte des Échos** dans sa butte de 3,6 m (encoche sud, rocher qui la bouche, rampe est de 0,6 m par marche) et **le bosquet d'Hélène** au nord-ouest, anneau de forêt de 12 cases de rayon.
- **La route du port** qui monte dans les prés (`histoire.md:128` : « la route du port monte dans les prés ») : route de 2 cases (4 m) dans un couloir de 10 cases (20 m) coupé de forêt au sud ; **le carrefour** (Maïa, panneau, feu de camp, Grand Voyageur) à mi-hauteur ; **le sentier de la Forêt** à l'ouest (lignes 47-57, sentier de 2 cases).
- **La crique** au sud-ouest (mer, plage de sable, panneau « Baignade déconseillée », feu de camp), **le petit bois et le nid de Chipie**, **le dormeur sous son arbre**, **le rocher qui « n'est pas un œuf »**, **Élise et son Tricératops malade**, 30 galets d'ambre.
- **Montagnes** : « montagnes au nord et à l'est, forêt à l'ouest et au sud » (`tools/maps/gen-plaines.mjs:56-58`) : les crêtes de 7 à 12 m sont du décor, pas du terrain praticable.

## 2. Les ancres

Chaque ligne : id (nom de nœud du `.tscn` ou drapeau de galet), position, drapeaux qui la conditionnent, scène d'histoire jouée (ids du § 3), rayon dégagé nécessaire (`needs_clear_radius_m`, à la louche ; le détail est au § 3) et distance de marche depuis l'arrivée. Sources : `tools/zones/plaines.gd` (placement), `world/*.gd` (comportements), `story/*.gd`, `data/dialogue_db.gd`.

### 2.1 Personnages (Npc) et dinos d'histoire (DinoNpc, Sleeper, FleeingDino)

| id | nom | tuile (x ; y) | mètres (x ; z ; h) | drapeaux | scène | dégagé (m) | à pied depuis l'arrivée |
|---|---|---|---|---|---|---|---|
| `Maia` | Maïa, au carrefour | (62.6 ; 44.4) | (125.2 ; 88.8 ; h 0.07) | cache si `sceau_plaines`, event `maia` | maia_vol_boussole; boussole_rendue | 11 | 89 m |
| `MaiaDefi` | Maïa, au pied du Crâne | (100.8 ; 65.2) | (201.6 ; 130.4 ; h 0.00) | montre si `sceau_plaines`, cache si `maia_defi_1`, event `maia_defi`, absent au départ | maia_defi_1 | 6 | 99 m |
| `Alpha` | Tricératops Alpha (taille 1,2) | (107.2 ; 63.8) | (214.4 ; 127.6 ; h 0.46) | montre si `crane_ouvert`, cache si `sceau_plaines`, event `alpha_plaines` | grand_crane_ouverture; alpha_sceau | 8 | 111 m |
| `Chipie` | Chipie (Compsognathus voleuse) | (57.5 ; 42.5) | (115.0 ; 85.0 ; h -0.04) | cache si `chipie_au_nid`, apparaît: `boussole_volee` | maia_vol_boussole; poursuite_chipie | 6 | 92 m |
| `Dormeur` | Protoceratops endormi (taille 0,9) | (56.4 ; 67.4) | (112.8 ; 134.8 ; h 0.06) | event `dormeur` | dormeur | 3 | 43 m |
| `TriceratopsMalade` | Tricératops malade couché | (82.0 ; 54.4) | (164.0 ; 108.8 ; h 0.03) | montre si `havre_arrive`, réveil: `elise_fini`, event `triceratops_malade` | elise_triceratops | 10 | 83 m |
| `Elise` | Élise Sablier | (79.1 ; 56.3) | (158.2 ; 112.6 ; h -0.01) | montre si `havre_arrive`, event `elise`, absent au départ | elise_triceratops | 10 | 78 m |
| `GrandVoyageur` | Grand Voyageur (Brachiosaure, taille 1,6) | (53.4 ; 49.0) | (106.8 ; 98.0 ; h 0.05) | event `grand_voyageur` | grand_voyageur | 8 | 81 m |

### 2.2 Panneaux (`Sign`, 9)

| id | nom | tuile (x ; y) | mètres (x ; z ; h) | drapeaux | scène | dégagé (m) | à pied depuis l'arrivée |
|---|---|---|---|---|---|---|---|
| `Panneau` | Panneau du carrefour (panneau_carrefour) | (57.4 ; 44.8) | (114.8 ; 89.6 ; h -0.07) | dialogue `panneau_carrefour` | panneaux | 2 | 88 m |
| `Panneau2` | Panneau du débarcadère (panneau_debarcadere) | (61.6 ; 84.6) | (123.2 ; 169.2 ; h -0.04) | dialogue `panneau_debarcadere` | panneaux | 2 | 8 m |
| `Panneau3` | Panneau de la Grotte (panneau_grotte, retourné) | (61.2 ; 27.4) | (122.4 ; 54.8 ; h 0.21) | dialogue `panneau_grotte` | panneaux | 2 | 122 m |
| `Panneau4` | Panneau des falaises (panneau_falaises) | (94.2 ; 12.6) | (188.4 ; 25.2 ; h 4.82) | dialogue `panneau_falaises` | panneaux; poste_observation | 2 | 180 m |
| `Panneau5` | Panneau du Grand Crâne (panneau_crane) | (100.4 ; 64.8) | (200.8 ; 129.6 ; h -0.01) | dialogue `panneau_crane` | panneaux; grand_crane_ouverture | 2 | 99 m |
| `Panneau6` | Panneau de l'étang (panneau_etang) | (81.4 ; 44.3) | (162.8 ; 88.6 ; h -0.02) | dialogue `panneau_etang` | panneaux; gue_de_lune | 2 | 107 m |
| `Panneau7` | Panneau de la crique (panneau_anse) | (25.5 ; 66.5) | (51.0 ; 133.0 ; h 0.02) | dialogue `panneau_anse` | panneaux | 2 | 82 m |
| `Panneau8` | Panneau « Ceci n'est pas un œuf » | (64.0 ; 40.3) | (128.0 ; 80.6 ; h 0.00) | dialogue `panneau_oeuf` | panneaux | 2 | 98 m |
| `Panneau9` | Panneau d'escale du Grand Voyageur | (57.0 ; 50.0) | (114.0 ; 100.0 ; h 0.04) | dialogue `panneau_escale` | panneaux; grand_voyageur | 2 | 78 m |

### 2.3 Serrures et décors d'histoire (`Obstacle`, `StoryProp`, bouches de grotte)

| id | nom | tuile (x ; y) | mètres (x ; z ; h) | drapeaux | scène | dégagé (m) | à pied depuis l'arrivée |
|---|---|---|---|---|---|---|---|
| `TroncBosquet` | Tronc tombé (Obstacle, Tranche) | (20.0 ; 40.9) | (40.0 ; 81.8 ; h 0.01) | ouvert: `tronc_bosquet_tranche`, capacité `tranche` | obstacles_capacites | 6 | 127 m |
| `EntreeGrotte` | Entrée de la Grotte des Échos (CaveMouth 1,8 case) | (58.0 ; 23.0) | (116.0 ; 46.0 ; h 0.00) | — | obstacles_capacites | 6 | 131 m |
| `RocherGrotte` | Rocher de la Grotte (Obstacle, Charge) | (58.0 ; 24.6) | (116.0 ; 49.2 ; h -0.02) | ouvert: `rocher_grotte_brise`, capacité `charge` | obstacles_capacites | 6 | 128 m |
| `PorteAmbre` | Porte d'ambre (Obstacle, Résonance) | (93.0 ; 38.0) | (186.0 ; 76.0 ; h -0.04) | ouvert: `porte_ambre_ouverte`, capacité `resonance` | obstacles_capacites | 6 | 122 m |
| `AntreCrane` | Antre de l'Alpha (CaveMouth 3,6 × 3,2) | (104.0 ; 58.0) | (208.0 ; 116.0 ; h 0.00) | — | grand_crane_ouverture | 12 | 113 m |
| `PorteCrane` | Porte d'ambre du Grand Crâne (StoryProp) | (104.0 ; 62.0) | (208.0 ; 124.0 ; h 0.11) | cache si `crane_ouvert`, event `grand_crane` | grand_crane_ouverture | 12 | 108 m |
| `NidChipie` | Nid de Chipie (StoryProp buisson_nid) | (40.6 ; 34.1) | (81.2 ; 68.2 ; h 0.23) | event `nid_chipie` | nid_chipie | 5 | 117 m |
| `CrottesTriceratops` | Pile de crottes de Tricératops (StoryProp) | (79.8 ; 55.1) | (159.6 ; 110.2 ; h -0.02) | event `crottes_triceratops` | elise_triceratops | 10 | 80 m |

### 2.4 Objets à ramasser et pages du journal (`Pickup`)

| id | nom | tuile (x ; y) | mètres (x ; z ; h) | drapeaux | scène | dégagé (m) | à pied depuis l'arrivée |
|---|---|---|---|---|---|---|---|
| `AmbreProtoceratops` | Fragment d'ambre + page 1 + écaille du bosquet | (15.6 ; 27.6) | (31.2 ; 55.2 ; h -0.07) | pris: `found_journal_1`, dialogue `ambre_proto` | page1_bosquet | 3 | 155 m |
| `Ambre` | Page 3 du journal (poste d'observation) | (98.0 ; 12.6) | (196.0 ; 25.2 ; h 4.73) | pris: `found_journal_3`, dialogue `page_3` | poste_observation | 2 | 187 m |
| `Ecaille` | Écaille d'ambre des falaises | (100.0 ; 12.8) | (200.0 ; 25.6 ; h 4.75) | pris: `ecaille_falaises`, dialogue `ecaille_falaises` | poste_observation | 2 | 191 m |
| `Page2` | Page 2 du journal (îlot de l'étang) | (78.5 ; 47.7) | (157.0 ; 95.4 ; h 0.02) | pris: `found_journal_2`, dialogue `page_2` | gue_de_lune | 2 | **inaccessible à pied** |
| `CuirMue` | Cuir mué de Parasaurolophus | (84.4 ; 50.2) | (168.8 ; 100.4 ; h 0.02) | montre si `selle_demandee`, pris: `cuir_trouve`, dialogue `cuir_trouve` | cuir_selle_joss | 3 | 92 m |

### 2.5 Galets d'ambre (30 en tout : 16 dans arbres/pierres, 8 monticules, 3 à vue, 1 îlot, 2 dans le nid de Chipie)

| id | nom | tuile (x ; y) | mètres (x ; z ; h) | drapeaux | scène | dégagé (m) | à pied depuis l'arrivée |
|---|---|---|---|---|---|---|---|
| `galet_plaines_02` | Galet caché dans arbre rond (galet_plaines_02) | (113.7 ; 8.9) | (227.3 ; 17.8 ; h 4.80) | galet: `galet_plaines_02` | galets_ambre | 2 | 220 m |
| `galet_plaines_01` | Galet caché dans fougere arbre (galet_plaines_01) | (8.2 ; 15.7) | (16.5 ; 31.5 ; h 0.56) | galet: `galet_plaines_01` | galets_ambre | 2 | 189 m |
| `galet_plaines_12` | Galet caché dans cailloux (galet_plaines_12) | (62.2 ; 18.6) | (124.4 ; 37.2 ; h 3.54) | galet: `galet_plaines_12` | galets_ambre | 2 | 164 m |
| `galet_plaines_10` | Galet caché dans cailloux (galet_plaines_10) | (22.4 ; 19.4) | (44.7 ; 38.7 ; h -0.07) | galet: `galet_plaines_10` | galets_ambre | 2 | 159 m |
| `galet_plaines_08` | Galet caché dans cailloux (galet_plaines_08) | (101.7 ; 20.4) | (203.5 ; 40.8 ; h 2.40) | galet: `galet_plaines_08` | galets_ambre | 2 | 166 m |
| `galet_plaines_03` | Galet caché dans araucaria (galet_plaines_03) | (63.5 ; 26.8) | (127.0 ; 53.5 ; h 0.18) | galet: `galet_plaines_03` | galets_ambre | 2 | 124 m |
| `galet_plaines_13` | Galet caché dans cailloux (galet_plaines_13) | (46.4 ; 35.7) | (92.7 ; 71.3 ; h -0.01) | galet: `galet_plaines_13` | galets_ambre | 2 | 111 m |
| `galet_plaines_14` | Galet caché dans cailloux (galet_plaines_14) | (94.4 ; 42.7) | (188.8 ; 85.4 ; h 0.26) | galet: `galet_plaines_14` | galets_ambre | 2 | 116 m |
| `galet_plaines_06` | Galet caché dans fougere arbre (galet_plaines_06) | (44.4 ; 51.8) | (88.8 ; 103.7 ; h 0.05) | galet: `galet_plaines_06` | galets_ambre | 2 | 80 m |
| `galet_plaines_11` | Galet caché dans cailloux (galet_plaines_11) | (73.5 ; 52.6) | (147.0 ; 105.2 ; h 0.17) | galet: `galet_plaines_11` | galets_ambre | 2 | 78 m |
| `galet_plaines_04` | Galet caché dans araucaria (galet_plaines_04) | (113.3 ; 59.9) | (226.7 ; 119.7 ; h 4.80) | galet: `galet_plaines_04` | galets_ambre | 2 | 289 m |
| `galet_plaines_05` | Galet caché dans araucaria (galet_plaines_05) | (15.3 ; 64.8) | (30.6 ; 129.6 ; h -0.01) | galet: `galet_plaines_05` | galets_ambre | 2 | 103 m |
| `galet_plaines_15` | Galet caché dans cailloux (galet_plaines_15) | (75.7 ; 70.5) | (151.5 ; 141.0 ; h -0.05) | galet: `galet_plaines_15` | galets_ambre | 2 | 48 m |
| `galet_plaines_00` | Galet caché dans arbre rond (galet_plaines_00) | (67.7 ; 80.3) | (135.3 ; 160.7 ; h 0.19) | galet: `galet_plaines_00` | galets_ambre | 2 | 22 m |
| `galet_plaines_09` | Galet caché dans cailloux (galet_plaines_09) | (43.4 ; 82.6) | (86.7 ; 165.3 ; h 0.03) | galet: `galet_plaines_09` | galets_ambre | 2 | 38 m |
| `galet_plaines_07` | Galet caché dans fougere arbre (galet_plaines_07) | (85.2 ; 45.3) | (170.4 ; 90.6 ; h -0.07) | galet: `galet_plaines_07` | galets_ambre | 2 | 102 m |
| `galet_plaines_16` | Monticule à creuser (galet_plaines_16) | (45.5 ; 64.6) | (91.0 ; 129.2 ; h -0.00) | galet: `galet_plaines_16` | galets_ambre | 2 | 56 m |
| `galet_plaines_17` | Monticule à creuser (galet_plaines_17) | (70.5 ; 70.6) | (141.0 ; 141.2 ; h 0.24) | galet: `galet_plaines_17` | galets_ambre | 2 | 42 m |
| `galet_plaines_18` | Monticule à creuser (galet_plaines_18) | (30.5 ; 51.6) | (61.0 ; 103.2 ; h 0.21) | galet: `galet_plaines_18` | galets_ambre | 2 | 97 m |
| `galet_plaines_19` | Monticule à creuser (galet_plaines_19) | (53.5 ; 36.6) | (107.0 ; 73.2 ; h 0.73) | galet: `galet_plaines_19` | galets_ambre | 2 | 106 m |
| `galet_plaines_20` | Monticule à creuser (galet_plaines_20) | (88.5 ; 58.6) | (177.0 ; 117.2 ; h 0.01) | galet: `galet_plaines_20` | galets_ambre | 2 | 83 m |
| `galet_plaines_21` | Monticule à creuser (galet_plaines_21) | (102.5 ; 23.6) | (205.0 ; 47.2 ; h 1.26) | galet: `galet_plaines_21` | galets_ambre | 2 | 157 m |
| `galet_plaines_22` | Monticule à creuser (galet_plaines_22) | (15.5 ; 33.6) | (31.0 ; 67.2 ; h 0.04) | galet: `galet_plaines_22` | galets_ambre | 2 | 144 m |
| `galet_plaines_23` | Monticule à creuser (galet_plaines_23) | (109.5 ; 74.6) | (219.0 ; 149.2 ; h 0.08) | galet: `galet_plaines_23` | galets_ambre | 2 | 108 m |
| `galet_plaines_24` | Galet à vue (galet_plaines_24) | (71.5 ; 13.6) | (143.0 ; 27.2 ; h 0.80) | pris: `galet_plaines_24` | galets_ambre | 2 | 155 m |
| `galet_plaines_25` | Galet à vue (galet_plaines_25) | (102.5 ; 10.6) | (205.0 ; 21.2 ; h 4.82) | pris: `galet_plaines_25` | galets_ambre | 2 | 197 m |
| `galet_plaines_26` | Galet à vue (galet_plaines_26) | (24.5 ; 67.6) | (49.0 ; 135.2 ; h -0.02) | pris: `galet_plaines_26` | galets_ambre | 2 | 84 m |
| `galet_plaines_ilot` | Galet à vue (galet_plaines_ilot) | (79.5 ; 48.4) | (159.0 ; 96.8 ; h 0.00) | pris: `galet_plaines_ilot` | galets_ambre | 2 | **inaccessible à pied** |

Les 2 galets du nid (`galet_plaines_nid_1`, `_nid_2`) ne sont pas des nœuds : `PlainesAnnexes.nest` les pose d'un coup (`story/plaines_annexes.gd:147-149`). Les trois espèces d'arbres porteuses (arbre_rond, fougere_arbre, araucaria) et le prop `cailloux` doivent rester des objets individuels secouables / retournables (`world/search.gd:10-70`).

### 2.6 Bancs, feux de repos et décors d'histoire interactifs

| id | nom | tuile (x ; y) | mètres (x ; z ; h) | drapeaux | scène | dégagé (m) | à pied depuis l'arrivée |
|---|---|---|---|---|---|---|---|
| `RocherGrotte2` | Rocher de grotte (décor) | (55.6 ; 25.8) | (111.2 ; 51.6 ; h 0.05) | — | obstacles_capacites | 2 | 127 m |
| `Stalagmite` | Stalagmite (décor) | (54.4 ; 26.0) | (108.8 ; 52.0 ; h 0.34) | — | obstacles_capacites | 2 | 127 m |
| `TableObservation` | Table d'observation d'Hélène (examinable) | (100.0 ; 12.1) | (200.0 ; 24.2 ; h 4.74) | — | poste_observation | 2 | 191 m |
| `NidDimorphodon` | Nid de Dimorphodon (corniche) | (91.5 ; 9.0) | (183.0 ; 18.0 ; h 4.85) | — | poste_observation | 2 | 184 m |
| `NidDimorphodon2` | Nid de Dimorphodon (corniche) | (103.0 ; 9.5) | (206.0 ; 19.0 ; h 4.83) | — | poste_observation | 2 | 199 m |
| `FeuCamp` | Feu de camp du carrefour | (56.0 ; 51.0) | (112.0 ; 102.0 ; h 0.06) | — | repos_banc_feu | 5 | 76 m |
| `FeuCamp2` | Feu de camp de la crique | (31.5 ; 64.0) | (63.0 ; 128.0 ; h -0.01) | — | repos_banc_feu | 5 | 76 m |
| `FeuCamp3` | Feu de camp du poste d'observation | (95.5 ; 11.5) | (191.0 ; 23.0 ; h 4.78) | — | repos_banc_feu; poste_observation | 5 | 183 m |
| `Banc` | Banc du bord de l'étang | (73.5 ; 42.5) | (147.0 ; 85.0 ; h -0.01) | — | repos_banc_feu | 5 | 98 m |
| `Banc2` | Banc au sud du carrefour | (61.5 ; 65.5) | (123.0 ; 131.0 ; h -0.01) | — | repos_banc_feu | 5 | 46 m |
| `PierrePlate` | Pierre plate de l'îlot (décor d'examen) | (78.9 ; 47.2) | (157.8 ; 94.4 ; h -0.27) | — | gue_de_lune | 2 | **inaccessible à pied** |
| `RocherOeuf` | Rocher « qui n'est pas un œuf » | (65.0 ; 39.6) | (130.0 ; 79.2 ; h -0.02) | — | panneaux | 2 | 100 m |
| `GueDeLune` | Gué de lune (2×2 cases d'eau → pierre, pleine lune) | (78.0 ; 45.0) | (156.0 ; 90.0 ; h -0.33) | — | gue_de_lune | 8 | — |

### 2.7 Points d'arrivée (`Spawns`, 10) : tous à conserver (anciennes sauvegardes : `core/game_state.gd:75-76`)

| id | nom | tuile (x ; y) | mètres (x ; z ; h) | drapeaux | scène | dégagé (m) | à pied depuis l'arrivée |
|---|---|---|---|---|---|---|---|
| `spawn:Depart` | Point d'arrivée « Depart » | (60.0 ; 86.0) | (120.0 ; 172.0 ; h -0.00) | — | arrivee_zone | 2 | 4 m |
| `spawn:DepuisPort` | Point d'arrivée « DepuisPort » | (60.0 ; 88.2) | (120.0 ; 176.4 ; h -0.00) | — | arrivee_zone | 2 | 0 m |
| `spawn:DepuisGrotte` | Point d'arrivée « DepuisGrotte » | (58.0 ; 24.3) | (116.0 ; 48.6 ; h -0.01) | — | arrivee_zone | 2 | 128 m |
| `spawn:Debarcadere` | Point d'arrivée « Debarcadere » | (60.0 ; 78.0) | (120.0 ; 156.0 ; h 0.00) | — | arrivee_zone | 2 | 20 m |
| `spawn:Carrefour` | Point d'arrivée « Carrefour » | (60.0 ; 48.0) | (120.0 ; 96.0 ; h 0.00) | — | arrivee_zone | 2 | 80 m |
| `spawn:Falaises` | Point d'arrivée « Falaises » | (93.0 ; 33.0) | (186.0 ; 66.0 ; h -0.02) | — | arrivee_zone | 2 | 131 m |
| `spawn:Crane` | Point d'arrivée « Crane » | (100.0 ; 66.5) | (200.0 ; 133.0 ; h 0.03) | — | arrivee_zone | 2 | 96 m |
| `spawn:DepuisAntre` | Point d'arrivée « DepuisAntre » | (104.0 ; 60.0) | (208.0 ; 120.0 ; h 0.06) | — | arrivee_zone | 2 | 109 m |
| `spawn:DepuisForet` | Point d'arrivée « DepuisForet » | (2.5 ; 52.0) | (5.0 ; 104.0 ; h 0.05) | — | arrivee_zone | 2 | 138 m |
| `spawn:Voyageur` | Point d'arrivée « Voyageur » | (56.2 ; 48.4) | (112.4 ; 96.8 ; h 0.01) | — | arrivee_zone | 2 | 81 m |

### 2.8 Sorties (`Exits`, 4)

| id | vers | rect tuiles (x ; y ; l × h) | rect mètres (x ; z ; l × h) | drapeau requis | arrivée côté voisin | à pied |
|---|---|---|---|---|---|---|
| `exit:VersPortAmbre` | port_ambre | (58.00 ; 89.45 ; 4.00 × 0.55) | (116.0 ; 178.9 ; 8.0 × 1.1) | — | DepuisPlaines (17.0 ; 1.5) | 3 m |
| `exit:VersGrotteEchos` | grotte_echos | (57.20 ; 22.95 ; 1.60 × 0.50) | (114.4 ; 45.9 ; 3.2 × 1.0) | — | DepuisCarrefour (11.9 ; 16.2) | 130 m |
| `exit:VersAntreCrane` | antre_crane | (102.50 ; 58.00 ; 3.00 × 0.60) | (205.0 ; 116.0 ; 6.0 × 1.2) | crane_ouvert | DepuisPlaines (7.0 ; 10.4) | 111 m |
| `exit:VersForet` | foret | (0.00 ; 50.00 ; 0.55 × 4.00) | (0.0 ; 100.0 ; 1.1 × 8.0) | selle | DepuisPlaines (126.0 ; 52.0) | 140 m |

### 2.9 Habitats (zones de rencontre, `data/dex_places.gd` pour `zone: plaines`, identiques à ceux du `.tscn`)

| lieu | rect tuiles | rect mètres | en balade | cases d'herbe haute | espèces (niveau, poids, moment, caché/à vue) |
|---|---|---|---|---|---|
| Prairies du sud | (36 ; 56 ; 44 × 30) | (72 ; 112 ; 88 × 60) | 3 | 194 | protoceratops niv 3-5 p10 toujours caché ; parasaurolophus niv 3-5 p3 jour caché ; protoceratops niv 3-5 p10 jour à vue ; velociraptor niv 4-5 p4 nuit à vue |
| Le carrefour | (26 ; 32 ; 50 × 24) | (52 ; 64 ; 100 × 48) | 3 | 130 | protoceratops niv 3-6 p10 toujours caché ; velociraptor niv 4-6 p3 nuit caché ; protoceratops niv 3-6 p10 jour à vue ; psittacosaurus niv 4-6 p6 aube et crépuscule à vue ; velociraptor niv 4-6 p5 nuit à vue |
| Rive de la crique | (10 ; 56 ; 28 × 24) | (20 ; 112 ; 56 × 48) | 2 | 40 | parasaurolophus niv 3-5 p10 jour et crépuscule à vue ; protoceratops niv 3-5 p10 toujours caché |
| L'étang | (70 ; 43 ; 18 × 11) | (140 ; 86 ; 36 × 22) | 2 | 6 | parasaurolophus niv 3-6 p10 jour et crépuscule à vue |
| Le bosquet d'Hélène | (8 ; 20 ; 20 × 20) | (16 ; 40 ; 40 × 40) | 1 | 27 | velociraptor niv 4-6 p10 aube et crépuscule à vue ; velociraptor niv 4-6 p10 toujours caché |
| Les falaises | (81 ; 8 ; 30 × 28) | (162 ; 16 ; 60 × 56) | 3 | 93 | dimorphodon niv 5-7 p10 jour et crépuscule à vue ; psittacosaurus niv 5-7 p10 aube et crépuscule caché ; protoceratops niv 5-6 p6 toujours caché |
| Le Grand Crâne | (84 ; 48 ; 30 × 38) | (168 ; 96 ; 60 × 76) | 3 | 126 | compsognathus niv 5-7 p10 jour à vue ; ankylosaurus niv 7-8 p3 nuit à vue ; compsognathus niv 5-7 p10 toujours caché ; psittacosaurus niv 5-6 p4 aube et crépuscule caché |

**Les trois capacités d'histoire dépendent des habitats** : Charge (rocher) = Protoceratops, qui vit **dans les herbes hautes** (Prairies du sud 194 cases d'herbe, Carrefour 130, Rive de la crique 40) ; Résonance (porte d'ambre) = Parasaurolophus, à vue à l'étang et à la crique le jour/crépuscule, caché dans les Prairies du sud de jour ; Tranche (tronc) = Velociraptor, aux lisières du carrefour et des prairies la nuit, au bosquet à l'aube/crépuscule. Les habitats doivent donc rester **joignables** et garder leurs herbes hautes.

### 2.10 Hautes herbes, eau, forêts, relief (zones, pas des points)

| patch | cases | m² | boîte (x ; y ; l × h) en cases | centre (m) |
|---|---|---|---|---|
| herbes hautes 1 | 88 | 352 | (91 ; 72 ; 14 × 8) | (196.7 ; 152.0) |
| herbes hautes 2 | 87 | 348 | (39 ; 66 ; 14 × 8) | (92.6 ; 140.1) |
| herbes hautes 3 | 79 | 316 | (32 ; 36 ; 12 × 8) | (76.1 ; 80.0) |
| herbes hautes 4 | 75 | 300 | (64 ; 72 ; 12 × 8) | (140.4 ; 152.2) |
| herbes hautes 5 | 54 | 216 | (94 ; 27 ; 11 × 6) | (199.6 ; 60.1) |
| herbes hautes 6 | 45 | 180 | (65 ; 52 ; 10 × 6) | (140.1 ; 109.8) |
| herbes hautes 7 | 40 | 160 | (17 ; 61 ; 10 × 5) | (44.0 ; 127.3) |
| herbes hautes 8 | 39 | 156 | (82 ; 25 ; 8 × 6) | (172.1 ; 56.3) |
| herbes hautes 9 | 38 | 152 | (46 ; 53 ; 8 × 6) | (100.0 ; 112.2) |
| herbes hautes 10 | 38 | 152 | (107 ; 67 ; 5 × 10) | (218.9 ; 143.4) |
| herbes hautes 11 | 27 | 108 | (13 ; 25 ; 6 × 6) | (31.7 ; 55.8) |
| herbes hautes 12 | 12 | 48 | (0 ; 54 ; 3 × 4) | (3.0 ; 112.0) |
| herbes hautes 13 | 9 | 36 | (0 ; 47 ; 3 × 3) | (3.0 ; 97.0) |

| masse | cases | m² | boîte (cases) | centre (m) |
|---|---|---|---|---|
| crique / mer du sud-ouest | 773 | 3092 | (0 ; 67 ; 40 × 23) | (36.5 ; 159.6) |
| étang des Chanteurs | 50 | 200 | (74 ; 45 ; 10 × 6) | (157.7 ; 96.0) |
| forêt | 530 | 2120 | (0 ; 0 ; 30 × 47) | (18.9 ; 52.4) |
| forêt | 376 | 1504 | (65 ; 82 ; 55 × 8) | (184.9 ; 173.1) |
| forêt | 93 | 372 | (80 ; 67 ; 12 × 10) | (171.9 ; 144.1) |
| forêt | 86 | 344 | (41 ; 83 ; 14 × 7) | (97.0 ; 173.4) |
| forêt | 76 | 304 | (34 ; 26 ; 12 × 8) | (80.3 ; 60.1) |
| forêt | 65 | 260 | (0 ; 58 ; 7 × 11) | (6.7 ; 125.4) |
| forêt | 63 | 252 | (28 ; 54 ; 10 × 8) | (66.6 ; 115.9) |
| forêt | 36 | 144 | (70 ; 61 ; 8 × 6) | (148.0 ; 128.0) |

Forêts : la plus grande (530 cases) réunit la bande ouest/nord-ouest (ouverte sur le sentier, lignes 47-57) et **l'anneau du bosquet d'Hélène** (centre (18 ; 31), rayons 8,5 à 12 cases) ; la deuxième (376) borde la route du port au sud-est ; le petit bois du nid fait 76 cases ((34-45 ; 26-33)) ; un bosquet de 93 cases est à (80-91 ; 67-76).

| relief | où / hauteurs | praticable ? |
|---|---|---|
| montagnes du nord (hors de portée) | y < ~13, jusqu'à 7-10 m, marches de 2,4 m | False |
| montagnes de l'est (hors de portée) | x > ~106 (colonnes 112-119 : 2,4 / 4,8 / 7,2 / 9,6 m) | False |
| butte de la Grotte des Échos | ellipse centre (58 ; 17), rayons 13 × 8, hauteur 3,6 m ; encoche (57-58 × 23-24) au niveau 0 ; rampe est (66-71 × 15-17) de 0,6 m par marche | dessus par la rampe est ; dedans par l'encoche |
| crête et plateau des falaises (nord-est) | crête ouest x 78-80 (3,6 m), mur sud y 36-37 de x 78 à 111 (3,6 m) percé du défilé x 92-93 (niveau 0) ; plateau 2,4 m (x 84-108, y 8-20) ; terrasse haute 4,8 m (x 88-104, y 8-13) | par le défilé |
| rampes du plateau | (96-97 × 21-24) et (90-91 × 14-17), marches de 0,6 m | True |
| butte du Grand Crâne | ellipse centre (104 ; 57), rayons 8 × 5, hauteur 3,6 m ; encoche (102-105 × 58-61) au niveau 0 | dedans par l'encoche |
| rebord est (colonne x = 113, 4,8 m) | balcon d'une case (2 m) le long de la montagne de l'est, de y ≈ 9 à y ≈ 75, accessible depuis la terrasse nord-est ; porte le galet galet_plaines_04 | True |

Rectangles que le 2,5D garde **sans semis** (`KEEP_CLEAR`, `tools/zones/plaines.gd:32-37`) : ce sont les places de l'histoire.

| place | cases (x ; y ; l × h) | mètres (x ; z ; l × h) |
|---|---|---|
| carrefour | (55.0 ; 41.0 ; 10.0 × 8.0) | (110.0 ; 82.0 ; 20.0 × 16.0) |
| grotte (encoche) | (54.0 ; 22.0 ; 8.0 × 7.0) | (108.0 ; 44.0 ; 16.0 × 14.0) |
| défilé de la porte d'ambre | (88.0 ; 34.0 ; 10.0 × 6.0) | (176.0 ; 68.0 ; 20.0 × 12.0) |
| Grand Crâne | (98.0 ; 52.0 ; 12.0 × 16.0) | (196.0 ; 104.0 ; 24.0 × 32.0) |
| bosquet d'Hélène | (12.0 ; 24.0 ; 8.0 × 8.0) | (24.0 ; 48.0 ; 16.0 × 16.0) |
| poste d'observation | (90.0 ; 9.0 ; 12.0 × 5.0) | (180.0 ; 18.0 ; 24.0 × 10.0) |
| route du port (sud) | (55.0 ; 84.0 ; 10.0 × 6.0) | (110.0 ; 168.0 ; 20.0 × 12.0) |
| nid de Chipie | (38.5 ; 33.0 ; 5.0 × 3.0) | (77.0 ; 66.0 ; 10.0 × 6.0) |
| rive et îlot de l'étang | (76.0 ; 43.5 ; 6.0 × 6.0) | (152.0 ; 87.0 ; 12.0 × 12.0) |
| dormeur | (54.0 ; 65.0 ; 4.0 × 4.0) | (108.0 ; 130.0 ; 8.0 × 8.0) |
| rocher œuf | (63.5 ; 38.5 ; 3.0 × 3.0) | (127.0 ; 77.0 ; 6.0 × 6.0) |
| panneau de la crique | (24.0 ; 65.5 ; 3.0 × 2.0) | (48.0 ; 131.0 ; 6.0 × 4.0) |
| scène d'Élise (SCÈNE VIDÉE de tout décor, caméra au sud) | (76.5 ; 52.5 ; 8.0 × 10.0) | (153.0 ; 105.0 ; 16.0 × 20.0) |

## 3. Besoins de mise en scène

### 3.1 Scène par scène (positions en pixels = tuile × 48)

#### `maia_vol_boussole` : Première rencontre avec Maïa et vol de la boussole

- **Déclencheur** : Parler à Maïa (Npc « Maia », event maia). Rejouée tant que boussole_volee est faux (vieilles sauvegardes).
- **Drapeaux** : `met_maia`, `boussole_volee`, `chipie_etape=0`
- **Sources** : `story/story.gd:122-123` ; `story/plaines_annexes.gd:56-104 (_theft 71-104)` ; `story/plaines_annexes.gd:36 (CHIPIE_HIDE)` ; `tools/zones/plaines.gd:151`
- **Positions** :
  - Maïa (face à gauche) : tuile (62.6 ; 44.4), **px (3005 ; 2131)**, mètres (125.2 ; 88.8)
  - CHIPIE_HIDE : où Chipie se cache puis jaillit : tuile (59.2 ; 47.2), **px (2842 ; 2266)**, mètres (118.4 ; 94.4)
  - départ de Chipie (= waypoint 0 de sa fuite), elle y revient : tuile (57.5 ; 42.5), **px (2760 ; 2040)**, mètres (115.0 ; 85.0)
  - où Chipie vole la boussole : Maïa + (-26, +14) px : tuile (62.06 ; 44.69), **px (2979 ; 2145)**, mètres (124.1 ; 89.4)
- **Caméra** : Aucun look_at ni close_up : la caméra reste sur Chloé.
- **Trajets** : (59.2 ; 47.2) → (62.06 ; 44.69) à 260 px/s = 7.6 m ; (62.06 ; 44.69) → (57.5 ; 42.5) à 260 px/s = 10.1 m
- **Place dégagée** : Disque d'au moins 11 m de rayon autour de Maïa (contient les trois points), sol plat et sans arbre : Chipie y court à 260 px/s. Rectangle KEEP_CLEAR du carrefour : tuiles 55-65 × 41-49 (x 110-130 m, z 82-98 m).
- **Contrainte** : Le point (59.2, 47.2) est une case de CHEMIN (pas d'herbe haute), alors que le texte parle de « froissement dans les herbes hautes » et que des feuilles y volent (Search.LEAVES) : prévoir une touffe ou un buisson bas (< 0,6 m) à cet endroit.

#### `boussole_rendue` : La boussole rendue à Maïa

- **Déclencheur** : Parler à Maïa avec boussole_trouvee et sans boussole_rendue.
- **Drapeaux** : `boussole_rendue`
- **Sources** : `story/plaines_annexes.gd:61-62,163-184`
- **Positions** :
  - Maïa (hop et bow sur place) : tuile (62.6 ; 44.4), **px (3005 ; 2131)**, mètres (125.2 ; 88.8)
- **Caméra** : aucune
- **Place dégagée** : Chloé à portée d'interaction de Maïa (≈ 1,3 m) : 3 m dégagés.
- **Contrainte** : Rien de plus que la scène du carrefour.

#### `poursuite_chipie` : La poursuite de Chipie jusqu'à son nid

- **Déclencheur** : FleeingDino « Chipie » : elle apparaît à boussole_volee ; chaque fois que Chloé passe à moins de 150 px (3,1 cases) elle file au waypoint suivant (stage chipie_etape), se retourne, se moque.
- **Drapeaux** : `boussole_volee (apparition)`, `chipie_etape 0..4`, `chipie_au_nid (arrivée, elle disparaît)`
- **Sources** : `world/fleeing_dino.gd:1-90` ; `tools/zones/plaines.gd:39,227-238`
- **Positions** :
  - waypoint 0 : tuile (57.5 ; 42.5), **px (2760 ; 2040)**, mètres (115.0 ; 85.0)
  - waypoint 1 : tuile (52.5 ; 40.5), **px (2520 ; 1944)**, mètres (105.0 ; 81.0)
  - waypoint 2 : tuile (48.5 ; 37.5), **px (2328 ; 1800)**, mètres (97.0 ; 75.0)
  - waypoint 3 : tuile (44.5 ; 35.6), **px (2136 ; 1709)**, mètres (89.0 ; 71.2)
  - waypoint 4 : le nid : tuile (41.6 ; 34.8), **px (1997 ; 1670)**, mètres (83.2 ; 69.6)
- **Caméra** : aucune
- **Trajets** : (57.5 ; 42.5) → (52.5 ; 40.5) à 230 px/s = 10.8 m ; (52.5 ; 40.5) → (48.5 ; 37.5) à 230 px/s = 10.0 m ; (48.5 ; 37.5) → (44.5 ; 35.6) à 230 px/s = 8.9 m ; (44.5 ; 35.6) → (41.6 ; 34.8) à 230 px/s = 6.0 m
- **Place dégagée** : Couloir praticable et dégagé le long des 4 segments (35,6 m en tout), large d'au moins 4 m. Il passe au sud du petit bois (tuiles forêt 34-45 × 26-33) : rien de dense entre le carrefour et le nid.
- **Contrainte** : Chloé doit pouvoir suivre à pied (distance à pied carrefour → nid : 49 m) ; pas de colline entre deux waypoints (Chipie se retourne vers Chloé et se moque, il faut la ligne de vue).

#### `nid_chipie` : Le nid de Chipie (lunettes de Roc, 2 galets, boussole)

- **Déclencheur** : StoryProp « NidChipie » (event nid_chipie), buisson_nid ; scène complète quand chipie_au_nid est posé.
- **Drapeaux** : `chipie_au_nid`, `boussole_trouvee`, `lunettes_trouvees`, `galet_plaines_nid_1`, `galet_plaines_nid_2`
- **Sources** : `story/plaines_annexes.gd:108-160,438-484` ; `tools/zones/plaines.gd:239-241` ; `story/objectives.gd:10 (NEST 41,34.8)`
- **Positions** :
  - buisson-nid : tuile (40.6 ; 34.1), **px (1949 ; 1637)**, mètres (81.2 ; 68.2)
  - Chipie jaillit : nid + (66, 40) px, « à découvert, à côté de Chloé » : tuile (41.975 ; 34.93), **px (2015 ; 1677)**, mètres (84.0 ; 69.9)
  - Chipie rentre dans le nid : nid + (10, 10) px : tuile (40.82 ; 34.31), **px (1959 ; 1647)**, mètres (81.6 ; 68.6)
- **Caméra** : aucune
- **Trajets** : (40.6 ; 34.1) → (41.975 ; 34.93) à 300 px/s = 3.2 m
- **Place dégagée** : Disque de 5 m de rayon, sol plat, sans arbre ; rectangle KEEP_CLEAR tuiles 38,5-43,5 × 33-36 (x 77-87 m, z 66-72 m). Le nid est au bord sud du petit bois (forêt jusqu'à la tuile y = 33).
- **Contrainte** : Le nid doit rester à l'ORÉE du bois, côté prairie : Chloé s'y tient en face, Chipie saute sur son épaule.

#### `dormeur` : Le Protoceratops qui ronfle

- **Déclencheur** : Sleeper « Dormeur » (event dormeur), sous un arbre_rond posé à (55,4 ; 66,4).
- **Drapeaux** : `dormeur_n (compteur)`
- **Sources** : `story/plaines_annexes.gd:386-418` ; `tools/zones/plaines.gd:273-281`
- **Positions** :
  - Dormeur (protoceratops, taille 0,9, pose couchée) : tuile (56.4 ; 67.4), **px (2707 ; 3235)**, mètres (112.8 ; 134.8)
  - arbre_rond au-dessus de lui : tuile (55.4 ; 66.4), **px (2659 ; 3187)**, mètres (110.8 ; 132.8)
- **Caméra** : aucune
- **Place dégagée** : Chloé à côté de lui (fougère posée sur sa tête) : 3 m dégagés ; KEEP_CLEAR tuiles 54-58 × 65-69.
- **Contrainte** : L'arbre et le dormeur vont ensemble.

#### `gue_de_lune` : L'étang qui chante (pleine lune), le gué d'ambre et la page 2

- **Déclencheur** : MoonFord « GueDeLune » : chaque nuit de pleine lune (Game.is_full_moon, tous les 4 jours) les 2×2 cases d'eau du gué deviennent de la pierre marchable et 4 Parasaurolophus chantent sur la rive.
- **Drapeaux** : `found_journal_2`, `galet_plaines_ilot`
- **Sources** : `world/moon_ford.gd:1-90` ; `tools/zones/plaines.gd:243-260` ; `data/dialogue_db.gd:78-93 (panneau_etang, page_2)`
- **Positions** :
  - gué : coin haut-gauche, 2×2 cases d'eau (tuiles 78-79 × 45-46) : tuile (78 ; 45), **px (3744 ; 2160)**, mètres (156.0 ; 90.0)
  - îlot : tuiles 78-79 × 47-48 (herbe) : tuile (78 ; 47), **px (3744 ; 2256)**, mètres (156.0 ; 94.0)
  - chanteur 0 : tuile (73.4 ; 47.5), **px (3523 ; 2280)**, mètres (146.8 ; 95.0)
  - chanteur 1 : tuile (85.5 ; 47.6), **px (4104 ; 2285)**, mètres (171.0 ; 95.2)
  - chanteur 2 : tuile (74.2 ; 50.5), **px (3562 ; 2424)**, mètres (148.4 ; 101.0)
  - chanteur 3 : tuile (80.5 ; 51.4), **px (3864 ; 2467)**, mètres (161.0 ; 102.8)
  - Page2 (page 2 du journal) : tuile (78.5 ; 47.7), **px (3768 ; 2290)**, mètres (157.0 ; 95.4)
  - pierre_plate (décor d'examen) : tuile (78.9 ; 47.2), **px (3787 ; 2266)**, mètres (157.8 ; 94.4)
  - GaletIlot : tuile (79.5 ; 48.4), **px (3816 ; 2323)**, mètres (159.0 ; 96.8)
  - panneau_etang : tuile (81.4 ; 44.3), **px (3907 ; 2126)**, mètres (162.8 ; 88.6)
- **Caméra** : aucune
- **Trajets** : (78.5 ; 44.0) → (78.5 ; 47.0) à 0 px/s = 6.0 m
- **Place dégagée** : Rive nord du gué praticable (4 m de large, 6 m de long, de la tuile y = 44 à l'îlot y = 47) ; les 4 points de chant sont de l'herbe (vérifié : surface « grass ») à 3-9 m de l'eau, chacun dégagé sur ≥ 5 m (un Parasaurolophus adulte montré fait 5,2 m).
- **Contrainte** : L'îlot n'est PAS atteignable à pied dans le graphe actuel (3 ancres : Page2, GaletIlot, pierre_plate) : c'est normal hors pleine lune, mais Blockers3D construit ses boîtes d'eau une fois pour toutes (les cases du gué ne changent pas de sol en 3D).

#### `obstacles_capacites` : Les trois serrures : tronc (Tranche), rocher (Charge), porte d'ambre (Résonance)

- **Déclencheur** : Obstacle « TroncBosquet » (tranche), « RocherGrotte » (charge), « PorteAmbre » (resonance) : si un dino du groupe a la capacité, le compagnon vient à l'obstacle (perform_at), qui se brise ; sinon dialogue de blocage.
- **Drapeaux** : `tronc_bosquet_tranche`, `rocher_grotte_brise`, `porte_ambre_ouverte`
- **Sources** : `world/obstacle.gd:1-60` ; `tools/zones/plaines.gd:158-162,174-179,184-189` ; `data/dialogue_db.gd:108-111,166-168` ; `story/objectives.gd:12-18 (TRUNK 20,41.2 ; BOULDER 58,25 ; AMBER_DOOR 93,38.4)`
- **Positions** :
  - tronc, empreinte 104×30 px = 2,17 × 0,63 m, sur le chemin : tuile (20.0 ; 40.9), **px (960 ; 1963)**, mètres (40.0 ; 81.8)
  - rocher, 96×34 px = 2,0 × 0,7 m, bouche l'encoche : tuile (58.0 ; 24.6), **px (2784 ; 1181)**, mètres (116.0 ; 49.2)
  - porte d'ambre, 96×30 px = 2,0 × 0,6 m, dans le défilé : tuile (93.0 ; 38.0), **px (4464 ; 1824)**, mètres (186.0 ; 76.0)
- **Caméra** : aucune
- **Place dégagée** : Pour chacune : 6 m dégagés du côté d'approche (sud) pour que le compagnon (jusqu'à un Parasaurolophus) s'approche et agisse ; débris sur place.
- **Contrainte** : À TAILLE RÉELLE ces obstacles ne ferment plus rien dans la zone ×2 (ouvertures de 4 m, obstacles de 2 à 2,2 m) : voir § 4 et risque R1.

#### `page1_bosquet` : Le bosquet d'Hélène : fragment d'ambre, page 1, première écaille

- **Déclencheur** : Pickup « AmbreProtoceratops » (dialogue ambre_proto) derrière le tronc.
- **Drapeaux** : `found_journal_1`, `amber_protoceratops`, `ecaille_bosquet`
- **Sources** : `tools/zones/plaines.gd:163-166,133` ; `data/dialogue_db.gd:113-129`
- **Positions** :
  - fragment d'ambre : tuile (15.6 ; 27.6), **px (749 ; 1325)**, mètres (31.2 ; 55.2)
  - ouverture sud de l'anneau de forêt (tuiles 19-20, y > 36) : tuile (19.5 ; 38.0), **px (936 ; 1824)**, mètres (39.0 ; 76.0)
- **Caméra** : aucune
- **Place dégagée** : Intérieur du bosquet : disque de ≈ 17 m de rayon autour de (18,31) tuiles = (36 ; 62) m, sans forêt (anneau de forêt entre 8,5 et 12 tuiles de rayon). KEEP_CLEAR tuiles 12-20 × 24-32.
- **Contrainte** : L'anneau de forêt est un MUR de gameplay : son seul passage est l'ouverture de 4 m fermée par le tronc.

#### `poste_observation` : Le poste d'observation d'Hélène : page 3, 3e écaille, nids de Dimorphodons, longue-vue

- **Déclencheur** : Pickups « Ambre » (page_3) et « Ecaille » (ecaille_falaises) ; panneau_falaises ; table_observation examinable ; banc et feu de camp.
- **Drapeaux** : `found_journal_3`, `ecaille_falaises`
- **Sources** : `tools/zones/plaines.gd:190-206` ; `data/dialogue_db.gd:130-150,169` ; `world/examine.gd:350-353`
- **Positions** :
  - panneau_falaises : tuile (94.2 ; 12.6), **px (4522 ; 605)**, mètres (188.4 ; 25.2)
  - banc : tuile (96.0 ; 12.4), **px (4608 ; 595)**, mètres (192.0 ; 24.8)
  - page 3 : tuile (98.0 ; 12.6), **px (4704 ; 605)**, mètres (196.0 ; 25.2)
  - écaille : tuile (100.0 ; 12.8), **px (4800 ; 614)**, mètres (200.0 ; 25.6)
  - table d'observation : tuile (100.0 ; 12.1), **px (4800 ; 581)**, mètres (200.0 ; 24.2)
  - nid de Dimorphodon : tuile (91.5 ; 9.0), **px (4392 ; 432)**, mètres (183.0 ; 18.0)
  - nid de Dimorphodon : tuile (103.0 ; 9.5), **px (4944 ; 456)**, mètres (206.0 ; 19.0)
  - feu de camp (pose ajustée, efface les décors à moins de 2,6 cases) : tuile (96.0 ; 10.4), **px (4608 ; 499)**, mètres (192.0 ; 20.8)
- **Caméra** : aucune
- **Place dégagée** : Terrasse haute (4,8 m) : tuiles 88-104 × 8-13 = 32 × 10 m ; KEEP_CLEAR tuiles 90-102 × 9-14 (x 180-204 m, z 18-28 m). Les nids sont sur la corniche, à 3-4 m du feu.
- **Contrainte** : Accès UNIQUEMENT par le défilé (porte d'ambre) puis la rampe (96-97 × 21-24) ou la rampe (90-91 × 14-17) : marches de 0,6 m entre cases (> STEP_MAX 0,35 m de Chloé, < saut 0,65 m).

#### `grand_crane_ouverture` : Le Grand Crâne s'ouvre : les trois écailles, la porte fond, l'Alpha sort de l'ombre

- **Déclencheur** : StoryProp « PorteCrane » (event grand_crane), caché dès crane_ouvert ; 3 écailles (ecaille_bosquet, ecaille_grotte, ecaille_falaises).
- **Drapeaux** : `crane_ouvert`, `ecaille_bosquet`, `ecaille_grotte`, `ecaille_falaises`
- **Sources** : `story/plaines.gd:55-99 (grand_crane), 129-160 (_emerge, _spawn_alpha)` ; `story/plaines.gd:13-21 (constantes)` ; `tools/zones/plaines.gd:209-221` ; `story/objectives.gd:19 (SKULL 104,62.6)`
- **Positions** :
  - PorteCrane (192×30 px = 4 × 0,6 m) : tuile (104.0 ; 62.0), **px (4992 ; 2976)**, mètres (208.0 ; 124.0)
  - DEN : l'Alpha apparaît ici, dans l'ombre : tuile (104.0 ; 58.5), **px (4992 ; 2808)**, mètres (208.0 ; 117.0)
  - MOUTH : regard de la caméra (look_at MOUTH.y - 1 = (104 ; 62,2)) : tuile (104.0 ; 63.2), **px (4992 ; 3034)**, mètres (208.0 ; 126.4)
  - OUT_OF_NOTCH : sortie de l'encoche : tuile (104.9 ; 62.3), **px (5035 ; 2990)**, mètres (209.8 ; 124.6)
  - ALPHA_SPOT : l'Alpha attend ici (hauteur 0,6 m), taille 1,2 : tuile (107.2 ; 63.8), **px (5146 ; 3062)**, mètres (214.4 ; 127.6)
  - AntreCrane : bouche de la grotte, 3,6 × 3,2 : tuile (104.0 ; 58.0), **px (4992 ; 2784)**, mètres (208.0 ; 116.0)
- **Caméra** : look_at(104 ; 62,2) à px (4992 ; 2986) pendant la sortie de l'Alpha ; Stage.shake(2.0 puis 7.0) ; flash ambre ; 3 étincelles sur la porte (_sparkles + OmniLight).
- **Trajets** : (104.0 ; 58.5) → (104.9 ; 62.3) à 90 px/s = 7.8 m ; (104.9 ; 62.3) → (107.2 ; 63.8) à 90 px/s = 5.5 m
- **Place dégagée** : Encoche de 4 tuiles × 4 (8 × 8 m, au niveau 0 dans une butte de 3,6 m, tuiles 102-105 × 58-61) entièrement libre, plus l'avant-cour jusqu'à (107,2 ; 63,8) : 12 m de rayon autour de la porte. Pas d'arbre, pas de colline. KEEP_CLEAR tuiles 98-110 × 52-68.
- **Contrainte** : La porte (4 m) est plus étroite que l'encoche (8 m) : voir R1. L'Alpha est une grosse bête (taille 1,2 d'un Tricératops adulte) : le chemin DEN → OUT_OF_NOTCH → ALPHA_SPOT fait 7,8 + 5,5 m.

#### `alpha_sceau` : L'Alpha : combat d'honneur, Sceau des Plaines, page 5

- **Déclencheur** : DinoNpc « Alpha » (event alpha_plaines) visible entre crane_ouvert et sceau_plaines ; Chloé lui parle.
- **Drapeaux** : `sceau_plaines`, `found_journal_5`
- **Sources** : `story/plaines.gd:163-235`
- **Positions** :
  - Alpha : tuile (107.2 ; 63.8), **px (5146 ; 3062)**, mètres (214.4 ; 127.6)
  - retour : OUT_OF_NOTCH : tuile (104.9 ; 62.3), **px (5035 ; 2990)**, mètres (209.8 ; 124.6)
  - retour : DEN, fondu dans l'ombre : tuile (104.0 ; 58.5), **px (4992 ; 2808)**, mètres (208.0 ; 117.0)
- **Caméra** : aucune (combat sur son propre écran)
- **Trajets** : (107.2 ; 63.8) → (104.9 ; 62.3) à 80 px/s = 5.5 m ; (104.9 ; 62.3) → (104.0 ; 58.5) à 80 px/s = 7.8 m
- **Place dégagée** : Chloé à ≈ 1,3 m de la corne (pencher/lean 16 px) ; 8 m dégagés autour de l'Alpha.
- **Contrainte** : Après le Sceau, le nœud « Alpha » disparaît (hide_flag sceau_plaines) : l'avant-cour doit rester libre pour Maïa.

#### `maia_defi_1` : Défi n°1 de Maïa au pied du Crâne

- **Déclencheur** : Dès le Sceau : Maïa arrive en courant (S.stranger « MaiaDefi » ou le Npc existant), puis Npc « MaiaDefi » (show_flag sceau_plaines, hide_flag maia_defi_1) attend au pied du crâne.
- **Drapeaux** : `sceau_plaines`, `maia_defi_1`
- **Sources** : `story/plaines.gd:241-296` ; `tools/zones/plaines.gd:153-154` ; `story/objectives.gd:25 (MAIA_DUEL 100,8 ; 65,2)`
- **Positions** :
  - MAIA_FROM : elle arrive d'ici (sentier de l'ouest) et repart ici : tuile (93.0 ; 65.5), **px (4464 ; 3144)**, mètres (186.0 ; 131.0)
  - MaiaDefi : poste d'attente : tuile (100.8 ; 65.2), **px (4838 ; 3130)**, mètres (201.6 ; 130.4)
  - arrivée près de Chloé : joueur + (-90, +12) px (Chloé ≈ (107,8 ; 63,8)) : tuile (105.9 ; 64.0), **px (5083 ; 3072)**, mètres (211.8 ; 128.0)
- **Caméra** : aucune
- **Trajets** : (93.0 ; 65.5) → (105.9 ; 64.0) à 200 px/s = 26.0 m ; (105.9 ; 64.0) → (93.0 ; 65.5) à 220 px/s = 26.0 m
- **Place dégagée** : Couloir de 26 m (de la tuile x = 93 à 107) le long de y ≈ 65, large de 6 m, sans arbre ni relief > 0,5 m : Maïa y court à 200-220 px/s.
- **Contrainte** : Le sentier du Crâne « (86,42) → (94,54) → (96,64) → (104,65) » (gen-plaines.mjs:89) est exactement ce couloir.

#### `elise_triceratops` : Élise Sablier et son Tricératops malade (la baie, la pile de crottes)

- **Déclencheur** : Dès l'arrivée au Havre (havre_arrive) : Npc « Elise » (event elise), Sleeper « TriceratopsMalade », StoryProp « CrottesTriceratops » ; on entre dans la zone : le Tricératops se couche (visiteurs.plaines).
- **Drapeaux** : `havre_arrive (apparition)`, `elise_vue`, `elise_fini (il se relève)`, `elise_n`, `elise_tri_n`, `elise_pile_n`
- **Sources** : `story/visiteurs.gd:237-375 (plaines 241, elise 250, _elise_meets 281, _berry 320)` ; `tools/zones/plaines.gd:15-21,80-100` ; `story/story.gd:43-44,306-318`
- **Positions** :
  - TriceratopsMalade (couché sur le flanc) : tuile (82.0 ; 54.4), **px (3936 ; 2611)**, mètres (164.0 ; 108.8)
  - pile de crottes (70×26 px) : tuile (79.8 ; 55.1), **px (3830 ; 2645)**, mètres (159.6 ; 110.2)
  - Élise (face à gauche) : tuile (79.1 ; 56.3), **px (3797 ; 2702)**, mètres (158.2 ; 112.6)
  - close_up(lerp(tri, pile, 0,45), 9,5 m, 1 s) : tuile (81.0 ; 54.7), **px (3888 ; 2626)**, mètres (162.0 ; 109.4)
  - look_at(lerp(pile, Chloé, 0,3)) : tuile (80.55 ; 54.9), **px (3866 ; 2635)**, mètres (161.1 ; 109.8)
  - Chloé offre la baie : tri ± (64 ; 16) px (ground_near, rayon 2 cases) : tuile (83.33 ; 54.7), **px (4000 ; 2626)**, mètres (166.7 ; 109.4)
- **Caméra** : close_up à 9,5 m de distance sur le milieu tricératops/pile ; Stage.wide() ; look_at pile↔Chloé ; Élise est « juste sous lui » : un cadrage trop proche lui coupe la tête (commentaire visiteurs.gd:306-308).
- **Trajets** : (82.0 ; 54.4) → (83.33 ; 54.7) à 100 px/s = 2.7 m
- **Place dégagée** : ELISE_SCENE : rectangle tuiles 76,5-84,5 × 52,5-62,5 (x 153-169 m, z 105-125 m) VIDÉ de tout décor, parce que « la caméra regarde le nord : ce qui est au sud les cache » : en 3D, aucun arbre ni relief > 1 m dans ce rectangle et ≈ 10 m derrière lui. Hors herbes hautes (elles les cacheraient).
- **Contrainte** : À 5 m au sud de l'étang (tuiles 74-83 × 45-50). Le Tricératops se relève (stand_up) : la zone doit rester plane.

#### `grand_voyageur` : Le Grand Voyageur (voyage rapide) : éternuement, escale, trajet

- **Déclencheur** : DinoNpc « GrandVoyageur » (brachiosaurus, taille 1,6, event grand_voyageur), toujours là ; spawn « Voyageur » à 2,8 cases à l'est (56,2 ; 48,4) ; panneau_escale à (57 ; 50).
- **Drapeaux** : `voyageur_rencontre`, `escale_plaines`, `roc_voyageur`
- **Sources** : `story/voyage.gd:43-120` ; `tools/zones/plaines.gd:67-73` ; `story/story.gd:306`
- **Positions** :
  - GrandVoyageur : tuile (53.4 ; 49.0), **px (2563 ; 2352)**, mètres (106.8 ; 98.0)
  - spawn Voyageur : où Chloé redescend en arrivant par voyage rapide : tuile (56.2 ; 48.4), **px (2698 ; 2323)**, mètres (112.4 ; 96.8)
  - panneau_escale : tuile (57.0 ; 50.0), **px (2736 ; 2400)**, mètres (114.0 ; 100.0)
- **Caméra** : close_up sur sa tête (7 m, 1,2 s) à la 1re rencontre ; Stage.shake(5.0) à l'éternuement ; recul de Chloé 22 px ; il s'agenouille (bow) et son cou « sert de passerelle » ; ride : goto_zone(zone, « Voyageur »).
- **Place dégagée** : Rayon 8 m dégagé autour de lui (un cou de 1,6× un Brachiosaure) : « le coin ouvert au sud-ouest du carrefour, loin des deux routes pour que son cou ne cache pas le panneau » (plaines.gd:68-70). KEEP_CLEAR carrefour.
- **Contrainte** : Le spawn « Voyageur » est l'arrivée de tous les voyages vers la Prairie.

#### `cuir_selle_joss` : Le cuir de Parasaurolophus mué (quête de la selle de Joss)

- **Déclencheur** : Pickup « CuirMue » (peau_mue) visible dès selle_demandee ; item cuir.
- **Drapeaux** : `selle_demandee`, `cuir_trouve`
- **Sources** : `tools/zones/plaines.gd:265-272` ; `story/objectives.gd:24,168` ; `data/dialogue_db.gd:68`
- **Positions** :
  - CuirMue, rive est de l'étang : tuile (84.4 ; 50.2), **px (4051 ; 2410)**, mètres (168.8 ; 100.4)
- **Caméra** : aucune
- **Place dégagée** : Rive est de l'étang praticable, 3 m dégagés.
- **Contrainte** : Marqueur d'objectif SKIN (84,4 ; 50,2).

#### `repos_banc_feu` : Bancs et feux de repos (repos, attendre le soir/matin, sauvegarde au feu)

- **Déclencheur** : Props banc / feu_camp interactifs (Rest) ; posés sur sol plat à 2 cases (B.flat_spot), décors effacés à moins de 2,6 cases.
- **Sources** : `world/rest.gd` ; `tools/zones/plaines.gd:289-297`
- **Caméra** : aucune
- **Place dégagée** : 5 × 5 cases planes (10 × 10 m en 3D) autour de chaque banc/feu : pas de relief, pas de forêt.
- **Contrainte** : 5 sites : voir la table des ancres.

#### `galets_ambre` : Les 30 galets d'ambre (« larmes de l'île »)

- **Déclencheur** : 8 arbres secoués + 8 pierres (cailloux) retournées (props avec hidden_pebble), 8 monticules (Flair), 3 galets à vue, 2 dans le nid de Chipie, 1 sur l'îlot ; flags galet_plaines_00..26 + _ilot + _nid_1/_nid_2.
- **Drapeaux** : `galet_plaines_*`
- **Sources** : `tools/zones/plaines.gd:53-58` ; `tools/zone_builder.gd:330-358` ; `world/search.gd:10-70` ; `story/plaines_annexes.gd:187-211`
- **Caméra** : aucune
- **Place dégagée** : Chaque arbre/caillou à pebble doit rester un OBJET individuel interactif (secouer / retourner), à portée de marche ; chaque monticule sur sol plat.
- **Contrainte** : Toute régénération du décor doit conserver ces 16 props (3 espèces d'arbres, cailloux) aux mêmes endroits ou les redistribuer en gardant 30 galets accessibles à pied.

#### `panneaux` : Les 9 panneaux de la Prairie

- **Déclencheur** : Sign : dialogue_id (DialogueDB.lines)
- **Sources** : `tools/zones/plaines.gd:155-156,180,191,219,260,283,285,73` ; `data/dialogue_db.gd:70-78,96-106,169-171`
- **Caméra** : aucune
- **Place dégagée** : Portée de lecture 1,3 m, face lisible depuis le chemin.
- **Contrainte** : Leur TEXTE donne des directions (panneau_carrefour : N grotte, NE falaises, E étang puis crâne, O bosquet, S port) : la disposition 3D doit les respecter.

#### `arrivee_zone` : Entrée dans la zone (arrivée du port, sauvegardes anciennes)

- **Déclencheur** : Story.on_zone_entered(plaines) ; Game.OLD_ZONES : plaines_debarcadere→Debarcadere, plaines_sud→Carrefour, plaines_falaises→Falaises, plaines_crane→Crane.
- **Drapeaux** : `havre_arrive`
- **Sources** : `story/story.gd:43-44` ; `core/game_state.gd:75-76,548-551` ; `story/visiteurs.gd:241-246`
- **Caméra** : aucune
- **Place dégagée** : Chaque spawn à ≥ 2 m de toute ancre ou sortie.
- **Contrainte** : 10 points d'arrivée à conserver : voir la table.

#### `sorties` : Les 4 sorties (port, Grotte des Échos, antre de l'Alpha, Forêt)

- **Déclencheur** : ZoneExit : Chloé entre dans le rectangle.
- **Drapeaux** : `crane_ouvert (antre)`, `selle (forêt)`
- **Sources** : `tools/zones/plaines.gd:309-317`
- **Caméra** : aucune
- **Place dégagée** : Voir § 5.
- **Contrainte** : Voir § 5.

*Aucune scène de la Prairie n'utilise `Stage.pace` (le va-et-vient) : il n'apparaît que dans la Forêt et le Désert. Aucun `StoryTrigger` n'est posé dans la Prairie (0 dans le `.tscn`) : toutes les scènes partent d'un dialogue, d'un objet ou d'un drapeau. Les scènes de nuit au port (`Plaines.back_to_port`, `empty_cabinet`) vivent dans Port-Ambre et le Cabinet, pas ici.*

### 3.2 Groupes de scène : à déplacer en bloc

Chaque groupe liste les ancres, points de scène, points de caméra et trajets qui jouent ensemble, avec leur position **relative au pivot** (est/sud en mètres, distance, azimut). `clear_radius_m` = rayon qui contient tous les membres + 3 m. Règle commune : **translater tous les membres du même vecteur**, garder les `rel_to_pivot`, puis recalculer les constantes en dur du § 3.3. Détail machine : `scene_groups` dans le JSON.

#### Groupe `carrefour_maia` (scènes : maia_vol_boussole, boussole_rendue, poursuite_chipie (départ))

Pivot : tuile (62.6 ; 44.4), px (3005 ; 2131). Rayon dégagé du groupe : **24 m**. Rectangle à garder vide : tuiles (55 ; 41 ; 10 ; 8).

| membre | type | tuile | px | Δ est (m) | Δ sud (m) | dist (m) | azimut | ancre / note |
|---|---|---|---|---|---|---|---|---|
| Maïa | actor | (62.6 ; 44.4) | (3005 ; 2131) | 0.0 | 0.0 | 0.0 | 0° - | Maia |
| CHIPIE_HIDE : cachette puis jaillissement | scene_point | (59.2 ; 47.2) | (2842 ; 2266) | -6.8 | 5.6 | 8.8 | 231° SO |  : constante en dur CHIPIE_HIDE (plaines_annexes.gd:36) |
| Chipie : départ et retour de la scène du vol (= waypoint 0) | actor | (57.5 ; 42.5) | (2760 ; 2040) | -10.2 | -3.8 | 10.9 | 290° O | Chipie |
| Chipie vole la boussole (Maïa + (-26, +14) px) | scene_point | (62.06 ; 44.69) | (2979 ; 2145) | -1.1 | 0.6 | 1.2 | 242° SO |  : offset relatif, suit Maïa |
| panneau du carrefour | prop | (57.4 ; 44.8) | (2755 ; 2150) | -10.4 | 0.8 | 10.4 | 266° O | Panneau |
| feu de camp du carrefour | prop | (56.0 ; 51.0) | (2688 ; 2448) | -13.2 | 13.2 | 18.7 | 225° SO | FeuCamp |
| point d'arrivée « Carrefour » (vieilles sauvegardes) | spawn | (60.0 ; 48.0) | (2880 ; 2304) | -5.2 | 7.2 | 8.9 | 216° SO | spawn:Carrefour |
| Grand Voyageur (voisin du carrefour) | actor | (53.4 ; 49.0) | (2563 ; 2352) | -18.4 | 9.2 | 20.6 | 243° SO | GrandVoyageur |
| rocher « œuf » et son panneau | prop | (65.0 ; 39.6) | (3120 ; 1901) | 4.8 | -9.6 | 10.7 | 27° NE | RocherOeuf |

*Rotation / orientation :* Tournable : l'offset (-26, +14) px place Chipie à ≈ 1,2 m au sud-ouest de Maïa pour le vol de la boussole ; garder cette proximité et la cachette à ≈ 9 m, côté d'où elle surgit.

#### Groupe `poursuite_chipie` (scènes : poursuite_chipie, nid_chipie)

Pivot : tuile (57.5 ; 42.5), px (2760 ; 2040). Rayon dégagé du groupe : **48 m**. Rectangle à garder vide : tuiles (38.5 ; 33 ; 5 ; 3).

| membre | type | tuile | px | Δ est (m) | Δ sud (m) | dist (m) | azimut | ancre / note |
|---|---|---|---|---|---|---|---|---|
| waypoint 0 (départ) | path | (57.5 ; 42.5) | (2760 ; 2040) | 0.0 | 0.0 | 0.0 | 0° - | Chipie |
| waypoint 1 | path | (52.5 ; 40.5) | (2520 ; 1944) | -10.0 | -4.0 | 10.8 | 292° O |  |
| waypoint 2 | path | (48.5 ; 37.5) | (2328 ; 1800) | -18.0 | -10.0 | 20.6 | 299° NO |  |
| waypoint 3 | path | (44.5 ; 35.6) | (2136 ; 1709) | -26.0 | -13.8 | 29.4 | 298° NO |  |
| waypoint 4 (le nid) | path | (41.6 ; 34.8) | (1997 ; 1670) | -31.8 | -15.4 | 35.3 | 296° NO |  |
| buisson-nid | prop | (40.6 ; 34.1) | (1949 ; 1637) | -33.8 | -16.8 | 37.7 | 296° NO | NidChipie |
| repère d'objectif NEST | marker | (41.0 ; 34.8) | (1968 ; 1670) | -33.0 | -15.4 | 36.4 | 295° NO |  : objectives.gd:10 : 3e copie de la même coordonnée |
| Chipie jaillit du nid (nid + (66, 40) px) | scene_point | (41.975 ; 34.93) | (2015 ; 1677) | -31.0 | -15.1 | 34.5 | 296° NO |  |
| Chipie dans le nid (nid + (10, 10) px) | scene_point | (40.82 ; 34.31) | (1959 ; 1647) | -33.4 | -16.4 | 37.2 | 296° NO |  |
| petit bois (centre des tuiles forêt) | zone | (39.6 ; 29.6) | (1901 ; 1421) | -35.8 | -25.8 | 44.1 | 306° NO |  : le nid est au bord SUD de ce bois |

*Rotation / orientation :* Les waypoints sont des coordonnées absolues du .tscn (FleeingDino.waypoints) : à déplacer en bloc avec le nid ; la chaîne doit rester monotone vers l'ouest-nord-ouest, espacée de ≥ 3,1 cases (NEAR = 150 px).

#### Groupe `dormeur` (scènes : dormeur)

Pivot : tuile (56.4 ; 67.4), px (2707 ; 3235). Rayon dégagé du groupe : **17 m**. Rectangle à garder vide : tuiles (54 ; 65 ; 4 ; 4).

| membre | type | tuile | px | Δ est (m) | Δ sud (m) | dist (m) | azimut | ancre / note |
|---|---|---|---|---|---|---|---|---|
| Dormeur | actor | (56.4 ; 67.4) | (2707 ; 3235) | 0.0 | 0.0 | 0.0 | 0° - | Dormeur |
| arbre_rond au-dessus de lui | prop | (55.4 ; 66.4) | (2659 ; 3187) | -2.0 | -2.0 | 2.8 | 315° NO |  |
| banc sud du carrefour | prop | (62.8 ; 66.0) | (3014 ; 3168) | 12.8 | -2.8 | 13.1 | 78° E | Banc2 |

*Rotation / orientation :* Libre : la paire arbre + dormeur doit rester ensemble (arbre au nord-ouest, dormeur à ≈ 1,4 m).

#### Groupe `etang_gue` (scènes : gue_de_lune, cuir_selle_joss)

Pivot : tuile (79.0 ; 47.0), px (3792 ; 2256). Rayon dégagé du groupe : **19 m**. Rectangle à garder vide : tuiles (76 ; 43.5 ; 6 ; 6).

| membre | type | tuile | px | Δ est (m) | Δ sud (m) | dist (m) | azimut | ancre / note |
|---|---|---|---|---|---|---|---|---|
| gué : 2×2 cases d'eau, rive nord de l'îlot | zone | (78 ; 45) | (3744 ; 2160) | -2.0 | -4.0 | 4.5 | 333° NO | GueDeLune : devient pierre marchable à la pleine lune |
| îlot (herbe, 2×2 cases) | zone | (78 ; 47) | (3744 ; 2256) | -2.0 | 0.0 | 2.0 | 270° O |  |
| page 2 | prop | (78.5 ; 47.7) | (3768 ; 2290) | -1.0 | 1.4 | 1.7 | 216° SO | Page2 |
| pierre plate (décor d'examen) | prop | (78.9 ; 47.2) | (3787 ; 2266) | -0.2 | 0.4 | 0.4 | 207° SO | PierrePlate |
| galet de l'îlot | prop | (79.5 ; 48.4) | (3816 ; 2323) | 1.0 | 2.8 | 3.0 | 160° S | GaletIlot |
| panneau de l'étang | prop | (81.4 ; 44.3) | (3907 ; 2126) | 4.8 | -5.4 | 7.2 | 42° NE | Panneau6 |
| banc de la rive nord-ouest | prop | (75.4 ; 44.4) | (3619 ; 2131) | -7.2 | -5.2 | 8.9 | 306° NO | Banc |
| chanteur 0 | actor | (73.4 ; 47.5) | (3523 ; 2280) | -11.2 | 1.0 | 11.2 | 265° O |  |
| chanteur 1 | actor | (85.5 ; 47.6) | (4104 ; 2285) | 13.0 | 1.2 | 13.1 | 95° E |  |
| chanteur 2 | actor | (74.2 ; 50.5) | (3562 ; 2424) | -9.6 | 7.0 | 11.9 | 234° SO |  |
| chanteur 3 | actor | (80.5 ; 51.4) | (3864 ; 2467) | 3.0 | 8.8 | 9.3 | 161° S |  |
| cuir mué (rive est) | prop | (84.4 ; 50.2) | (4051 ; 2410) | 10.8 | 6.4 | 12.6 | 121° SE | CuirMue |
| prêles de la rive | prop | (72.4 ; 45.6) | (3475 ; 2189) | -13.2 | -2.8 | 13.5 | 282° O |  |
| Élise et son Tricératops (au sud, voir autre groupe) | ref | (82.0 ; 54.4) | (3936 ; 2611) | 6.0 | 14.8 | 16.0 | 158° S | TriceratopsMalade |

*Rotation / orientation :* Libre en bloc, MAIS le gué relie la rive nord (panneau, banc) à l'îlot au sud : garder « rive nord → gué → îlot » dans cet ordre, l'étang entre les deux ; la rive est (cuir) et les 4 points de chant sont à des rayons de 5 à 8 m de l'îlot.

#### Groupe `bosquet_tronc` (scènes : obstacles_capacites (tronc), page1_bosquet)

Pivot : tuile (20.0 ; 40.9), px (960 ; 1963). Rayon dégagé du groupe : **35 m**. Rectangle à garder vide : tuiles (12 ; 24 ; 8 ; 8).

| membre | type | tuile | px | Δ est (m) | Δ sud (m) | dist (m) | azimut | ancre / note |
|---|---|---|---|---|---|---|---|---|
| tronc (Obstacle, 2,17 × 0,63 m) | prop | (20.0 ; 40.9) | (960 ; 1963) | 0.0 | 0.0 | 0.0 | 0° - | TroncBosquet |
| ouverture de l'anneau de forêt (tuiles 19-20, y > 36) | zone | (20.0 ; 37.0) | (960 ; 1776) | 0.0 | -7.8 | 7.8 | 0° N |  : 2 cases = 4 m |
| fragment d'ambre + page 1 + écaille | prop | (15.6 ; 27.6) | (749 ; 1325) | -8.8 | -26.6 | 28.0 | 342° N | AmbreProtoceratops |
| centre du bosquet (ellipse de l'anneau) | zone | (18.0 ; 31.0) | (864 ; 1488) | -4.0 | -19.8 | 20.2 | 349° N |  : rayon intérieur 8,5 cases = 17 m |
| monticule galet 22 | prop | (15.5 ; 33.6) | (744 ; 1613) | -9.0 | -14.6 | 17.2 | 328° NO | galet_plaines_22 |
| fleurs/fougères fixes du bosquet (5) | decor | (17.8 ; 25.2) | (854 ; 1210) | -4.4 | -31.4 | 31.7 | 352° N |  : tools/zones/plaines.gd:133-135 |

*Rotation / orientation :* Le tronc doit rester en travers de l'OUVERTURE, perpendiculaire au chemin ; le bosquet derrière (au nord de l'ouverture). Distance tronc → ambre : 28 m à vol d'oiseau.

#### Groupe `grotte_rocher` (scènes : obstacles_capacites (rocher))

Pivot : tuile (58.0 ; 24.6), px (2784 ; 1181). Rayon dégagé du groupe : **12 m**. Rectangle à garder vide : tuiles (54 ; 22 ; 8 ; 7).

| membre | type | tuile | px | Δ est (m) | Δ sud (m) | dist (m) | azimut | ancre / note |
|---|---|---|---|---|---|---|---|---|
| rocher (Obstacle, 2,0 × 0,7 m) | prop | (58.0 ; 24.6) | (2784 ; 1181) | 0.0 | 0.0 | 0.0 | 0° - | RocherGrotte |
| bouche de la grotte (CaveMouth 1,8 case) | prop | (58.0 ; 23.0) | (2784 ; 1104) | 0.0 | -3.2 | 3.2 | 0° N | EntreeGrotte |
| sortie vers la Grotte des Échos | exit | (58.0 ; 23.2) | (2784 ; 1114) | 0.0 | -2.8 | 2.8 | 0° N | exit:VersGrotteEchos |
| retour de la Grotte (DepuisGrotte, collé au rocher) | spawn | (58.0 ; 24.3) | (2784 ; 1166) | 0.0 | -0.6 | 0.6 | 0° N | spawn:DepuisGrotte |
| panneau de la grotte | prop | (61.2 ; 27.4) | (2938 ; 1315) | 6.4 | 5.6 | 8.5 | 131° SE | Panneau3 |
| rocher_grotte (décor) | prop | (55.6 ; 25.8) | (2669 ; 1238) | -4.8 | 2.4 | 5.4 | 243° SO | RocherGrotte2 |
| cailloux (décor) | prop | (60.8 ; 25.8) | (2918 ; 1238) | 5.6 | 2.4 | 6.1 | 113° SE |  |
| stalagmite (décor) | prop | (54.4 ; 26.0) | (2611 ; 1248) | -7.2 | 2.8 | 7.7 | 249° O | Stalagmite |

*Rotation / orientation :* Tournable avec la butte : l'encoche regarde le SUD (le chemin arrive du sud). Le rocher est 1,6 case (3,2 m) devant la bouche.

#### Groupe `falaises_porte` (scènes : obstacles_capacites (porte d'ambre))

Pivot : tuile (93.0 ; 38.0), px (4464 ; 1824). Rayon dégagé du groupe : **28 m**. Rectangle à garder vide : tuiles (88 ; 34 ; 10 ; 6).

| membre | type | tuile | px | Δ est (m) | Δ sud (m) | dist (m) | azimut | ancre / note |
|---|---|---|---|---|---|---|---|---|
| porte d'ambre (Obstacle, 2,0 × 0,6 m, fougère gravée) | prop | (93.0 ; 38.0) | (4464 ; 1824) | 0.0 | 0.0 | 0.0 | 0° - | PorteAmbre |
| défilé (tuiles 92-93, y 36-37, niveau 0 dans un mur de 3,6 m) | zone | (93.0 ; 37.0) | (4464 ; 1776) | 0.0 | -2.0 | 2.0 | 0° N |  : 4 m de large |
| « Falaises » : arrivée des vieilles sauvegardes, derrière la porte | spawn | (93.0 ; 33.0) | (4464 ; 1584) | 0.0 | -10.0 | 10.0 | 0° N | spawn:Falaises |
| repère d'objectif AMBER_DOOR | marker | (93.0 ; 38.4) | (4464 ; 1843) | 0.0 | 0.8 | 0.8 | 180° S |  |
| chemin vers le plateau (suite du défilé) | path | (96.0 ; 26.0) | (4608 ; 1248) | 6.0 | -24.0 | 24.7 | 14° N |  |

*Rotation / orientation :* La porte ferme un défilé ; au sud : la prairie (le sentier arrive de (86,42) puis (93,39)), au nord : le plateau.

#### Groupe `poste_observation` (scènes : poste_observation)

Pivot : tuile (98.0 ; 12.6), px (4704 ; 605). Rayon dégagé du groupe : **23 m**. Rectangle à garder vide : tuiles (90 ; 9 ; 12 ; 5).

| membre | type | tuile | px | Δ est (m) | Δ sud (m) | dist (m) | azimut | ancre / note |
|---|---|---|---|---|---|---|---|---|
| panneau du poste | prop | (94.2 ; 12.6) | (4522 ; 605) | -7.6 | 0.0 | 7.6 | 270° O | Panneau4 |
| banc | prop | (96.0 ; 12.4) | (4608 ; 595) | -4.0 | -0.4 | 4.0 | 276° O |  |
| page 3 | prop | (98.0 ; 12.6) | (4704 ; 605) | 0.0 | 0.0 | 0.0 | 0° - | Ambre |
| écaille | prop | (100.0 ; 12.8) | (4800 ; 614) | 4.0 | 0.4 | 4.0 | 96° E | Ecaille |
| table d'observation (juste derrière l'écaille) | prop | (100.0 ; 12.1) | (4800 ; 581) | 4.0 | -1.0 | 4.1 | 76° E | TableObservation |
| feu de camp | prop | (96.0 ; 10.4) | (4608 ; 499) | -4.0 | -4.4 | 5.9 | 318° NO | FeuCamp3 |
| nid de Dimorphodon (ouest) | prop | (91.5 ; 9.0) | (4392 ; 432) | -13.0 | -7.2 | 14.9 | 299° NO | NidDimorphodon |
| nid de Dimorphodon (est) | prop | (103.0 ; 9.5) | (4944 ; 456) | 10.0 | -6.2 | 11.8 | 58° NE | NidDimorphodon2 |
| rampe vers la terrasse (90-91 × 14-17) | path | (90.5 ; 15.5) | (4344 ; 744) | -15.0 | 5.8 | 16.1 | 249° O |  |
| rampe du plateau (96-97 × 21-24) | path | (96.5 ; 22.5) | (4632 ; 1080) | -3.0 | 19.8 | 20.0 | 189° S |  |

*Rotation / orientation :* Tournable : alignement panneau → banc → page → écaille → table sur une même corniche de 10 m ; l'écaille est « posée sur la table ».

#### Groupe `crane_cour` (scènes : grand_crane_ouverture, alpha_sceau, maia_defi_1)

Pivot : tuile (104.0 ; 62.0), px (4992 ; 2976). Rayon dégagé du groupe : **27 m**. Rectangle à garder vide : tuiles (98 ; 52 ; 12 ; 16).

| membre | type | tuile | px | Δ est (m) | Δ sud (m) | dist (m) | azimut | ancre / note |
|---|---|---|---|---|---|---|---|---|
| porte d'ambre du Crâne (4 × 0,6 m) | prop | (104.0 ; 62.0) | (4992 ; 2976) | 0.0 | 0.0 | 0.0 | 0° - | PorteCrane |
| DEN : l'Alpha apparaît (fond de l'encoche) | scene_point | (104.0 ; 58.5) | (4992 ; 2808) | 0.0 | -7.0 | 7.0 | 0° N |  : plaines.gd:17 |
| bouche de l'antre (CaveMouth 3,6 × 3,2) | prop | (104.0 ; 58.0) | (4992 ; 2784) | 0.0 | -8.0 | 8.0 | 0° N | AntreCrane |
| sortie vers l'antre (3 × 0,6 cases) | exit | (104.0 ; 58.3) | (4992 ; 2798) | 0.0 | -7.4 | 7.4 | 0° N | exit:VersAntreCrane |
| retour de l'antre (DepuisAntre) | spawn | (104.0 ; 60.0) | (4992 ; 2880) | 0.0 | -4.0 | 4.0 | 0° N | spawn:DepuisAntre |
| MOUTH : cible du regard de la caméra (y - 1) | camera | (104.0 ; 62.2) | (4992 ; 2986) | 0.0 | 0.4 | 0.4 | 180° S |  : plaines.gd:18,133 |
| OUT_OF_NOTCH : sortie de l'encoche | scene_point | (104.9 ; 62.3) | (5035 ; 2990) | 1.8 | 0.6 | 1.9 | 108° E |  : plaines.gd:21 |
| ALPHA_SPOT : l'Alpha attend | actor | (107.2 ; 63.8) | (5146 ; 3062) | 6.4 | 3.6 | 7.3 | 119° SE | Alpha : hauteur du sol 0,6 m |
| panneau du Crâne | prop | (100.4 ; 64.8) | (4819 ; 3110) | -7.2 | 5.6 | 9.1 | 232° SO | Panneau5 |
| Maïa du défi (poste d'attente) | actor | (100.8 ; 65.2) | (4838 ; 3130) | -6.4 | 6.4 | 9.1 | 225° SO | MaiaDefi |
| MAIA_FROM : d'où Maïa arrive et où elle repart | scene_point | (93.0 ; 65.5) | (4464 ; 3144) | -22.0 | 7.0 | 23.1 | 252° O |  : plaines.gd:29 |
| Maïa se place près de Chloé (joueur + (-90, +12) px) | scene_point | (105.9 ; 64.0) | (5083 ; 3072) | 3.8 | 4.0 | 5.5 | 136° SE |  |
| « Crane » : arrivée des vieilles sauvegardes | spawn | (100.0 ; 66.5) | (4800 ; 3192) | -8.0 | 9.0 | 12.0 | 222° SO | spawn:Crane |
| repère d'objectif SKULL | marker | (104.0 ; 62.6) | (4992 ; 3005) | 0.0 | 1.2 | 1.2 | 180° S |  |

*Rotation / orientation :* NE PAS faire pivoter sans réécrire plaines.gd : DEN → MOUTH est le NORD → SUD, l'Alpha va vers le SUD-EST, Maïa arrive de l'OUEST et se place à l'OUEST de Chloé (offset -90 px). Déplacement en bloc (translation) sans problème si les 6 constantes sont recalculées.

#### Groupe `elise` (scènes : elise_triceratops)

Pivot : tuile (82.0 ; 54.4), px (3936 ; 2611). Rayon dégagé du groupe : **13 m**. Rectangle à garder vide : tuiles (76.5 ; 52.5 ; 8 ; 10).

| membre | type | tuile | px | Δ est (m) | Δ sud (m) | dist (m) | azimut | ancre / note |
|---|---|---|---|---|---|---|---|---|
| Tricératops malade (couché sur le flanc, face à gauche) | actor | (82.0 ; 54.4) | (3936 ; 2611) | 0.0 | 0.0 | 0.0 | 0° - | TriceratopsMalade |
| pile de crottes (70 × 26 px) | prop | (79.8 ; 55.1) | (3830 ; 2645) | -4.4 | 1.4 | 4.6 | 252° O | CrottesTriceratops |
| Élise (face à gauche) | actor | (79.1 ; 56.3) | (3797 ; 2702) | -5.8 | 3.8 | 6.9 | 237° SO | Elise |
| close_up : milieu tricératops/pile (45 % vers la pile) | camera | (81.0 ; 54.7) | (3888 ; 2626) | -2.0 | 0.6 | 2.1 | 253° O |  : visiteurs.gd:308, 9,5 m |
| look_at : pile ↔ Chloé (30 %) | camera | (80.55 ; 54.9) | (3866 ; 2635) | -2.9 | 1.0 | 3.1 | 251° O |  |
| Chloé offre la baie (tri ± 64 px, +16 px) | scene_point | (83.33 ; 54.7) | (4000 ; 2626) | 2.7 | 0.6 | 2.7 | 103° E |  : visiteurs.gd:325, ground_near rayon 2 cases |
| étang (rive sud, la plus proche) | zone | (79.0 ; 50.5) | (3792 ; 2424) | -6.0 | -7.8 | 9.8 | 322° NO |  : 5 m au nord du groupe |
| cuir mué (rive est) | prop | (84.4 ; 50.2) | (4051 ; 2410) | 4.8 | -8.4 | 9.7 | 30° NE | CuirMue |

*Rotation / orientation :* La caméra du 2,5D regarde le NORD (« ce qui est au sud les cache ») : garder le rectangle ELISE_SCENE (8 × 10 cases) dégagé au SUD du groupe ; Élise à l'OUEST-SUD-OUEST du Tricératops, la pile entre eux.

#### Groupe `voyageur` (scènes : grand_voyageur)

Pivot : tuile (53.4 ; 49.0), px (2563 ; 2352). Rayon dégagé du groupe : **24 m**. Rectangle à garder vide : tuiles (55 ; 41 ; 10 ; 8).

| membre | type | tuile | px | Δ est (m) | Δ sud (m) | dist (m) | azimut | ancre / note |
|---|---|---|---|---|---|---|---|---|
| Grand Voyageur (taille 1,6) | actor | (53.4 ; 49.0) | (2563 ; 2352) | 0.0 | 0.0 | 0.0 | 0° - | GrandVoyageur |
| point d'arrivée « Voyageur » | spawn | (56.2 ; 48.4) | (2698 ; 2323) | 5.6 | -1.2 | 5.7 | 78° E | spawn:Voyageur |
| panneau d'escale | prop | (57.0 ; 50.0) | (2736 ; 2400) | 7.2 | 2.0 | 7.5 | 106° E | Panneau9 |
| feu de camp du carrefour | prop | (56.0 ; 51.0) | (2688 ; 2448) | 5.2 | 4.0 | 6.6 | 128° SE | FeuCamp |
| Maïa (carrefour) | actor | (62.6 ; 44.4) | (3005 ; 2131) | 18.4 | -9.2 | 20.6 | 63° NE | Maia |

*Rotation / orientation :* Libre. Le spawn est à l'EST du dino, le panneau plus à l'est encore : son cou ne doit pas cacher le panneau (commentaire plaines.gd:68-70).

#### Groupe `sortie_port` (scènes : sorties, arrivee_zone)

Pivot : tuile (60.0 ; 89.7), px (2880 ; 4306). Rayon dégagé du groupe : **28 m**. Rectangle à garder vide : tuiles (55 ; 84 ; 10 ; 6).

| membre | type | tuile | px | Δ est (m) | Δ sud (m) | dist (m) | azimut | ancre / note |
|---|---|---|---|---|---|---|---|---|
| sortie vers Port-Ambre (4 × 0,55 cases, bord sud) | exit | (60.0 ; 89.7) | (2880 ; 4306) | 0.0 | 0.0 | 0.0 | 0° - | exit:VersPortAmbre |
| DepuisPort | spawn | (60.0 ; 88.2) | (2880 ; 4234) | 0.0 | -3.0 | 3.0 | 0° N | spawn:DepuisPort |
| Depart | spawn | (60.0 ; 86.0) | (2880 ; 4128) | 0.0 | -7.4 | 7.4 | 0° N | spawn:Depart |
| Debarcadere (vieilles sauvegardes) | spawn | (60.0 ; 78.0) | (2880 ; 3744) | 0.0 | -23.4 | 23.4 | 0° N | spawn:Debarcadere |
| panneau du débarcadère | prop | (61.6 ; 84.6) | (2957 ; 4061) | 3.2 | -10.2 | 10.7 | 17° N | Panneau2 |
| galet 00 / arbre rond | prop | (67.6 ; 80.3) | (3245 ; 3854) | 15.2 | -18.8 | 24.2 | 39° NE | galet_plaines_00 |

*Rotation / orientation :* Fixe : le bord sud, la route de 4 m, le couloir libre de 20 m (x 55-64) entre les deux forêts.

#### Groupe `sortie_foret` (scènes : sorties)

Pivot : tuile (0.3 ; 52.0), px (14 ; 2496). Rayon dégagé du groupe : **21 m**. Rectangle à garder vide : tuiles (0 ; 47 ; 14 ; 11).

| membre | type | tuile | px | Δ est (m) | Δ sud (m) | dist (m) | azimut | ancre / note |
|---|---|---|---|---|---|---|---|---|
| sortie vers la Forêt Jurassique (0,55 × 4 cases, bord ouest) | exit | (0.3 ; 52.0) | (14 ; 2496) | 0.0 | 0.0 | 0.0 | 0° - | exit:VersForet |
| DepuisForet | spawn | (2.5 ; 52.0) | (120 ; 2496) | 4.4 | 0.0 | 4.4 | 90° E | spawn:DepuisForet |
| repère d'objectif FORET_EXIT | marker | (1.0 ; 52.0) | (48 ; 2496) | 1.4 | 0.0 | 1.4 | 90° E |  |
| sentier (lignes 51-52) | path | (9.0 ; 52.0) | (432 ; 2496) | 17.4 | 0.0 | 17.4 | 90° E |  |
| herbes hautes de la lisière | zone | (1.0 ; 55.5) | (48 ; 2664) | 1.4 | 7.0 | 7.1 | 169° S |  |

*Rotation / orientation :* Fixe : bord ouest, mêmes lignes (50-54) que la sortie est de la Forêt (foret.gd:439).

### 3.3 Dépendances de position cachées (coordonnées en dur dans le code d'histoire)

Toute scène qui écrit une coordonnée (`S.at(x, y)`, `walk_to`, `look_at`, `close_up`, `teleport`, `ground_near`, constante `Vector2`) **au lieu de lire un acteur** casse silencieusement si l'ancre bouge. En 3D, `Stage3D` convertit les pixels absolus par `ZoneSource.to_3d` ; les **décalages relatifs en pixels** (±26, 64, 90…) deviennent donc ×2 m / 48 × 2 = 0,042 m par pixel : ils restent proportionnels aux tuiles, pas à la taille réelle des acteurs (conversion supposée d'après `Stage3D` : à confirmer avant de s'y fier).

**Dans la Prairie : 6 positions absolues dans les scènes** (5 constantes dans `story/plaines.gd`, 1 dans `story/plaines_annexes.gd` : 8 utilisations), **11 repères HUD** dans `story/objectives.gd`, **8 décalages relatifs en pixels** (`plaines.gd` 1, `plaines_annexes.gd` 5, `visiteurs.gd` 2), 2 positions dérivées d'acteurs (`visiteurs.gd:308`, `voyage.gd:72`), plus dans `tools/zones/plaines.gd` la chaîne de Chipie, les placements d'Élise, 12 rectangles `KEEP_CLEAR`, le gué et les sorties/arrivées. `visiteurs.gd` n'a aucune coordonnée absolue. Détail :

| fichier:ligne | expression | tuile | nature | utilisée à | doit suivre l'ancre | autres copies de la même donnée |
|---|---|---|---|---|---|---|
| `story/plaines.gd:15` | `ALPHA_SPOT` | (107.2 ; 63.8) | absolue | 141 walk_to ; 144 head_down | Alpha | tools/zones/plaines.gd:220 (nœud) ; story/objectives.gd:19 (ALPHA) |
| `story/plaines.gd:17` | `DEN` | (104.0 ; 58.5) | absolue | 157 apparition ; 233 retour | AntreCrane, exit:VersAntreCrane | tools/zones/plaines.gd:213 (CaveMouth 104 ; 58) |
| `story/plaines.gd:18` | `MOUTH` | (104.0 ; 63.2) | absolue | 133 look_at(MOUTH.x, MOUTH.y - 1) | PorteCrane | tools/zones/plaines.gd:215 (porte 104 ; 62) ; story/objectives.gd:18 (SKULL 104 ; 62,6) |
| `story/plaines.gd:21` | `OUT_OF_NOTCH` | (104.9 ; 62.3) | absolue | 139 et 227 walk_to | PorteCrane | — |
| `story/plaines.gd:29` | `MAIA_FROM` | (93.0 ; 65.5) | absolue | 248 stranger() ; 292 walk_to du retour | MaiaDefi | — |
| `story/plaines.gd:252` | `w.player.global_position + Vector2(-90, 12)` | — | décalage relatif en px (suit Chloé) | 252 walk_to de Maïa | (aucune) mais suppose Maïa à l'OUEST de Chloé | — |
| `story/plaines_annexes.gd:36` | `CHIPIE_HIDE` | (59.2 ; 47.2) | absolue | 81 position de départ ; 424 _rustle (feuilles) | Maia | — |
| `story/plaines_annexes.gd:82` | `maia_npc.global_position + Vector2(-26, 14)` | — | décalage relatif en px | 82 walk_to de Chipie | Maia | — |
| `story/plaines_annexes.gd:88` | `start = position initiale de Chipie` | (57.5 ; 42.5) | lue sur l'acteur (mais = waypoint 0 du .tscn) | 88 retour | Chipie.waypoints[0] | tools/zones/plaines.gd:39 |
| `story/plaines_annexes.gd:443` | `bush.position + Vector2(66, 40)` | — | décalage relatif en px | 443 sortie du nid | NidChipie | — |
| `story/plaines_annexes.gd:468` | `bush.position + Vector2(10, 10)` | — | décalage relatif en px | 468 dans le nid | NidChipie | — |
| `story/plaines_annexes.gd:472` | `chloe.global_position + Vector2(SHOULDER.x, 3)` | — | décalage relatif (épaule de Chloé) | 472 | — | — |
| `story/plaines_annexes.gd:503` | `chloe.global_position + Vector2(side * 64, 4)` | — | décalage relatif | 503 | — | — |
| `story/visiteurs.gd:284` | `elise.global_position + Vector2(-40, -10)` | — | décalage relatif de repli | 284 (si la pile manque) | CrottesTriceratops | — |
| `story/visiteurs.gd:308` | `tri.lerp(pile_px, 0.45) + close_up(…, 9.5, 1.0)` | — | dérivée des acteurs (lue) | 308 | TriceratopsMalade, CrottesTriceratops | — |
| `story/visiteurs.gd:325` | `ground_near(tri_px + Vector2(±64, 16), 2)` | — | décalage relatif + recherche de sol (rayon 2 cases) | 325 | TriceratopsMalade | — |
| `story/voyage.gd:72` | `close_up(who.global_position, 7.0, 1.2)` | — | dérivée de l'acteur (lue) | 72 | GrandVoyageur | — |
| `story/objectives.gd:10` | `NEST` | (41.0 ; 34.8) | absolue (repère HUD) | 415 | NidChipie | tools/zones/plaines.gd:39 (waypoint 4 = 41,6 ; 34,8) ; :239 (nid 40,6 ; 34,1) |
| `story/objectives.gd:11` | `MAIA_SPOT` | (62.6 ; 44.4) | absolue (repère HUD) | 417 | Maia | tools/zones/plaines.gd:151 |
| `story/objectives.gd:12` | `POND` | (79.0 ; 47.5) | absolue (repère HUD) | 422 | GueDeLune | — |
| `story/objectives.gd:15` | `TRUNK` | (20.0 ; 41.2) | absolue (repère HUD) | 147 | TroncBosquet | tools/zones/plaines.gd:158 (20 ; 40,9) |
| `story/objectives.gd:16` | `BOULDER` | (58.0 ; 25.0) | absolue (repère HUD) | 157 | RocherGrotte | tools/zones/plaines.gd:174 (58 ; 24,6) |
| `story/objectives.gd:17` | `AMBER_DOOR` | (93.0 ; 38.4) | absolue (repère HUD) | 160 | PorteAmbre | tools/zones/plaines.gd:184 (93 ; 38) |
| `story/objectives.gd:18` | `SKULL` | (104.0 ; 62.6) | absolue (repère HUD) | 143 | PorteCrane | tools/zones/plaines.gd:215 (104 ; 62) |
| `story/objectives.gd:19` | `ALPHA` | (107.2 ; 63.8) | absolue (repère HUD) | 140 | Alpha | story/plaines.gd:15 |
| `story/objectives.gd:24` | `SKIN` | (84.4 ; 50.2) | absolue (repère HUD) | 168 | CuirMue | tools/zones/plaines.gd:266 |
| `story/objectives.gd:25` | `MAIA_DUEL` | (100.8 ; 65.2) | absolue (repère HUD) | 129 | MaiaDefi | tools/zones/plaines.gd:153 |
| `story/objectives.gd:28` | `FORET_EXIT` | (1.0 ; 52.0) | absolue (repère HUD) | 181 | exit:VersForet | tools/zones/plaines.gd:317 |
| `tools/zones/plaines.gd:39` | `CHIPIE_PATH (5 waypoints)` | (57.5 ; 42.5) | absolue (copiée dans le .tscn : FleeingDino.waypoints) | fuite de Chipie | NidChipie, Chipie | story/objectives.gd:10 |
| `tools/zones/plaines.gd:16` | `ELISE_TRI / ELISE_PILE / ELISE_AT / ELISE_SCENE` | (82.0 ; 54.4) | absolue (placement et vidage du décor) | 80-100 | TriceratopsMalade, CrottesTriceratops, Elise | le rectangle ELISE_SCENE (l.21) est vidé à la construction : il ne suit pas les nœuds |
| `tools/zones/plaines.gd:32` | `KEEP_CLEAR (12 rectangles)` | — | absolue (zones sans semis) | scatter | toutes les ancres de scène | à déplacer avec elles |
| `tools/zones/plaines.gd:243` | `MoonFord position, islet, singer_spots` | (78 ; 45) | absolue dans le .tscn | gué de lune | GueDeLune, Page2, GaletIlot | tools/zones/plaines.gd:250-259 (page, galet, pierre à 0,5-1,5 case de l'îlot) |
| `tools/zones/plaines.gd:309` | `B.exit / B.spawn (rects et arrivées)` | — | absolues | 300-317 | les 4 sorties | foret.gd:438-439, port_ambre.gd:79,83, grotte_echos.gd:86-87, antre_crane.gd:63-64 : leurs spawns/rects du côté voisin |

**Plusieurs copies de la même coordonnée** (à mettre à jour ensemble) : le nid de Chipie existe en 3 versions (nœud (40,6 ; 34,1), dernier waypoint (41,6 ; 34,8), repère HUD (41 ; 34,8)) ; l'Alpha en 3 (nœud, `ALPHA_SPOT`, `ALPHA`) ; le Crâne en 4 (porte (104 ; 62), `MOUTH` (104 ; 63,2), repère `SKULL` (104 ; 62,6), `DEN` (104 ; 58,5) contre l'antre (104 ; 58)) ; Maïa du défi en 2 (nœud, `MAIA_DUEL`) ; le tronc, le rocher, la porte d'ambre, Maïa, le cuir et la sortie ouest, chacun en 2 (nœud + repère HUD).

**Comptes par fichier** (`Godot/story/*.gd`, occurrences textuelles relevées par recherche : appels `S.at(`, constantes `Vector2` de position, appels de déplacement/caméra `look_at/close_up/walk_to/teleport/stand_beside/ground_near`, littéraux `Vector2(x, y)`). Seuls les quatre premiers fichiers concernent la Prairie ; les autres sont donnés pour mémoire.

| fichier | S.at( | const Vector2 | déplacements/caméra | littéraux Vector2 | ce que c'est |
|---|---|---|---|---|---|
| `story/plaines.gd` | 19 | 10 | 16 | 17 | Plaines (8 absolues : l.133-292) + Port de nuit (l.310-341, 7) + Cabinet (l.395-398, 2) |
| `story/plaines_annexes.gd` | 7 | 6 | 13 | 12 | Plaines : CHIPIE_HIDE (2) ; Cabinet : FERN, INCUBATOR, DRAWER, WORKBENCH (5) ; 8 décalages relatifs |
| `story/visiteurs.gd` | 0 | 0 | 6 | 6 | aucune coordonnée absolue ; tout est lu sur les acteurs ou en décalage relatif |
| `story/voyage.gd` | 0 | 0 | 1 | 0 | close_up sur l'acteur |
| `story/objectives.gd` | 0 | 30 | 0 | 31 | 11 repères HUD de la Prairie (constantes en cases) |
| `story/story.gd` | 1 | 0 | 1 | 1 |  |
| `story/stage.gd` | 0 | 0 | 8 | 3 | helpers (pace, look_at, close_up) |
| `story/clins_doeil.gd` | 10 | 5 | 13 | 11 | Port/Cabinet/Forêt ; l.355 : un raptor part « vers les Plaines » en marchant (-2, -3) cases |
| `story/cote.gd` | 18 | 0 | 18 | 23 | Côte |
| `story/cote_fin.gd` | 9 | 0 | 9 | 12 | Côte |
| `story/cote_grottes.gd` | 8 | 0 | 6 | 6 | Côte |
| `story/cote_lagon.gd` | 3 | 0 | 14 | 10 | Côte |
| `story/cote_places.gd` | 1 | 53 | 0 | 56 | Côte |
| `story/cote_recif.gd` | 4 | 0 | 4 | 8 | Côte |
| `story/desert.gd` | 9 | 3 | 10 | 13 | Désert |
| `story/desert_places.gd` | 1 | 23 | 0 | 30 | Désert |
| `story/desert_sanctuaire.gd` | 14 | 0 | 23 | 15 | Désert |
| `story/doorway.gd` | 0 | 1 | 4 | 1 | Port/Cabinet |
| `story/foret.gd` | 0 | 2 | 11 | 12 | Forêt |
| `story/foret_camp.gd` | 2 | 17 | 14 | 36 | Forêt |
| `story/foret_fin.gd` | 12 | 9 | 15 | 20 | Forêt |
| `story/foret_gestes.gd` | 0 | 0 | 5 | 2 |  |
| `story/grotte.gd` | 4 | 5 | 6 | 9 | Grotte des Échos (autre zone) |
| `story/havre.gd` | 17 | 5 | 14 | 7 | Havre-Doré |
| `story/marais.gd` | 2 | 2 | 9 | 8 | Marais |
| `story/marais_stage.gd` | 0 | 0 | 3 | 5 |  |
| `story/marais_suite.gd` | 3 | 2 | 13 | 9 | Marais |
| `story/marais_temple.gd` | 1 | 2 | 5 | 4 | Marais |
| `story/monts.gd` | 7 | 2 | 16 | 15 | Monts |
| `story/monts_col.gd` | 5 | 3 | 8 | 11 | Monts |
| `story/monts_fin.gd` | 1 | 0 | 1 | 8 | Monts |
| `story/monts_grottes.gd` | 5 | 1 | 12 | 9 | Monts |
| `story/monts_places.gd` | 0 | 34 | 0 | 36 | Monts |
| `story/monts_sanctuaire.gd` | 2 | 0 | 6 | 9 | Monts |
| `story/prologue.gd` | 22 | 4 | 16 | 7 | Port-Ambre / Cabinet, pas la Prairie |

Ailleurs (hors `story/`) : `tools/zones/plaines.gd` (placements, `CHIPIE_PATH`, `KEEP_CLEAR`, `ELISE_*`, `B.exit`/`B.spawn` : lignes 16-21, 32-39, 300-317), `world/fleeing_dino.gd` (`NEAR` = 150 px, `SPEED` 230 px/s), `world/moon_ford.gd` (`singer_spots`, `islet`), et les arrivées des zones voisines (`port_ambre.gd:79,83`, `grotte_echos.gd:86-87`, `antre_crane.gd:63-64`, `foret.gd:438-439`).

### 3.4 Relations à conserver si on déplace des ancres

- **R-carrefour** : Maïa est AU CARREFOUR, point de rencontre de tous les chemins : route du port au sud, chemin de la grotte au nord, chemin du bosquet à l'ouest, chemin des falaises puis de l'étang et du crâne à l'est. Le panneau du carrefour est à 10 m à l'ouest d'elle, l'arrivée « Carrefour » à 9 m au sud-ouest, le feu de camp à 19 m et le Grand Voyageur à 21 m au sud-ouest. *(Maïa (125,2 ; 88,8) m ; panneau (114,8 ; 89,6) ; spawn Carrefour (120 ; 96) ; Voyageur (106,8 ; 98) ; feu (112 ; 102).)*
- **R-trio** : TROIS PASSAGES rayonnent depuis le carrefour, chacun fermé par une serrure (tronc/Tranche à l'ouest, rocher/Charge au nord, porte d'ambre/Résonance à l'est-nord-est) et chacun donnant sur une poche sans autre issue qui contient UNE écaille (bosquet, fond de la grotte, poste d'observation). Le Crâne (sud-est) s'ouvre avec les trois écailles et n'a besoin d'AUCUNE serrure pour être atteint à pied. *(depuis Maïa, à vol d'oiseau : tronc 85 m à l'ouest (azimut 275°), rocher 41 m au nord (347°), porte d'ambre 62 m à l'ENE (78°), porte du Crâne 90 m à l'ESE (113°). À pied depuis Maïa : tronc 88, rocher 42, porte d'ambre 64, porte du Crâne 92 (matrice du § 4).)*
- **R-panneau-directions** : Le texte du panneau du carrefour fixe la géographie : Nord = Grotte des Échos, Nord-est = les Falaises, Est = l'étang puis le Grand Crâne, Ouest = le vieux bosquet, Sud = Port-Ambre. Le 3D doit s'y plier (ou le texte sera changé). *(depuis Maïa : centre du plateau des falaises à 56° (NE, 80 m), étang à 102° (E, 34 m), Crâne à 113° (ESE, 90 m), bosquet à 275° (O), grotte à 347° (N), port à 183° (S, 91 m).)*
- **R-crane-cour** : Autour du Grand Crâne : la porte d'ambre (104 ; 62) ferme l'encoche ; l'antre est 8 m plus au NORD ; l'avant-cour au sud porte, à l'ouest-sud-ouest le panneau et Maïa du défi (collés, 1,1 m), l'arrivée « Crane » à 12 m au sud-ouest ; l'Alpha attend à 7 m à l'est-sud-est de la porte. *(porte → antre 8,0 m (0°) ; porte → DEN 7,0 m ; porte → Alpha 7,3 m (119°) ; porte → MaiaDefi 9,1 m (225°) ; porte → MAIA_FROM 23,1 m (252°) ; Alpha → MaiaDefi 13,1 m (258°).)*
- **R-etang** : L'étang a le gué AU NORD de l'îlot (la page 2 est à 5,5 m au sud du gué), le panneau et le banc sur la rive nord, les 4 chanteurs en couronne, le cuir sur la rive est ; Élise et son Tricératops sont 10 m AU SUD-EST de la rive sud. *(gué (156 ; 90) m, page 2 (157 ; 95,4), panneau (162,8 ; 88,6), Tricératops (164 ; 108,8), Élise (158,2 ; 112,6) ; rive sud → Tricératops 9,8 m (142°).)*
- **R-poste** : Le poste d'observation est sur la terrasse la plus haute (4,8 m), alignée ouest → est : panneau, banc, page 3, écaille posée sur la table (table 1,4 m derrière, au nord de l'écaille), nids aux deux extrémités, feu de camp au nord du banc. *(panneau (188,4 ; 25,2) → table (200 ; 24,2) : 11,6 m ; nids (183 ; 18) et (206 ; 19) : 23 m entre eux.)*
- **R-bosquet** : Le bosquet est une poche circulaire (rayon libre 17 m) entourée d'un mur de forêt, avec UNE ouverture de 4 m au sud (bouchée par le tronc) ; le fragment d'ambre est au NORD-NORD-OUEST du tronc, à 28 m. *(tronc (40 ; 81,8) m, ambre (31,2 ; 55,2), centre du bosquet (36 ; 62).)*
- **R-nid** : Le nid est au bord SUD du petit bois, à 49 m à pied à l'ouest-nord-ouest du carrefour, le long du chemin de l'ouest ; la fuite de Chipie suit cette direction en 4 bonds de 6,8 à 10,8 m (chaque bond ≥ 3,1 cases pour que « moins de 150 px » la déclenche). *(Maïa → nid 48,6 m à vol d'oiseau (295°).)*
- **R-adjacence** : Paires à garder collées : arbre + Dormeur (2,8 m) ; panneau d'œuf + rocher œuf (2,4 m) ; écaille + table (1,4 m) ; page 2 + pierre plate (1,3 m) + galet de l'îlot (2,4 m) ; panneau du Crâne + Maïa du défi (1,1 m) ; rocher + bouche de la grotte (3,2 m) ; pile de crottes + Tricératops (4,6 m) + Élise (2,8 m de la pile) ; Grand Voyageur + panneau d'escale (7,5 m) mais pas DEVANT lui.
- **R-visibilite** : À garder visible / dégagé : (1) le Crâne « au loin » depuis l'escale du Grand Voyageur (ligne de vue de 105 m au ESE, la butte de 3,6 m dépasse) ; (2) les falaises du nord-est depuis le carrefour ; (3) la scène d'Élise vue depuis le SUD (caméra 2,5D vers le nord ; en 3D : pas de relief > 1 m ni d'arbre dans les ≈ 10 m au sud du trio) ; (4) la sortie de l'Alpha : de l'avant-cour on doit voir tout le trajet DEN → ALPHA_SPOT (≈ 13 m) ; (5) le panneau d'escale non masqué par le cou du Voyageur ; (6) Chipie visible de Chloé à chaque bond (elle se retourne pour la narguer).
- **R-etat** : Les deux états d'une même ancre doivent exister au même endroit : Maïa du carrefour / Maïa du défi sont deux Npc distincts (hide_flag/show_flag) ; porte du Crâne (StoryProp) / Alpha (DinoNpc) / antre ; Tricératops couché / debout (même point) ; tronc, rocher, porte : présents puis détruits (Obstacle) sans changer la place libre qu'ils laissent.
- **R-bords** : Les 4 sorties et leurs arrivées : sud (route de 4 m, bande de 20 m), ouest (sentier, lignes 47-57), encoche nord de la butte, fond de l'encoche du Crâne. Côté voisin : Port-Ambre au sud (arrivée (17 ; 1,5) de sa zone 40 × 24), Forêt à l'ouest (même ligne y = 50-54). *(voir § 5)*

Paires d'ancres d'histoire à moins de 6 m l'une de l'autre (adjacences actuelles, triées) :

| a | b | distance (m) | azimut a → b (°) |
|---|---|---|---|
| `EntreeGrotte` | `exit:VersGrotteEchos` | 0.4 | 274 |
| `RocherGrotte` | `spawn:DepuisGrotte` | 0.6 | 0 |
| `AntreCrane` | `exit:VersAntreCrane` | 0.6 | 270 |
| `MaiaDefi` | `Panneau5` | 1.1 | 315 |
| `Page2` | `PierrePlate` | 1.3 | 39 |
| `Ecaille` | `TableObservation` | 1.4 | 0 |
| `spawn:DepuisGrotte` | `exit:VersGrotteEchos` | 2.2 | 329 |
| `RocherGrotte2` | `Stalagmite` | 2.4 | 261 |
| `RocherOeuf` | `Panneau8` | 2.4 | 235 |
| `EntreeGrotte` | `spawn:DepuisGrotte` | 2.6 | 180 |
| `RocherGrotte` | `exit:VersGrotteEchos` | 2.8 | 334 |
| `FeuCamp` | `Panneau9` | 2.8 | 45 |
| `CrottesTriceratops` | `Elise` | 2.8 | 210 |
| `spawn:DepuisPort` | `exit:VersPortAmbre` | 3.0 | 238 |
| `MaiaDefi` | `spawn:Crane` | 3.1 | 212 |
| `EntreeGrotte` | `RocherGrotte` | 3.2 | 180 |
| `Panneau4` | `FeuCamp3` | 3.4 | 50 |
| `spawn:DepuisAntre` | `exit:VersAntreCrane` | 3.4 | 323 |
| `Panneau5` | `spawn:Crane` | 3.5 | 193 |
| `Panneau9` | `spawn:Voyageur` | 3.6 | 333 |
| `Ambre` | `Ecaille` | 4.0 | 96 |
| `AntreCrane` | `spawn:DepuisAntre` | 4.0 | 180 |
| `PorteCrane` | `spawn:DepuisAntre` | 4.0 | 0 |
| `Ambre` | `TableObservation` | 4.1 | 76 |
| `Panneau2` | `spawn:Depart` | 4.3 | 229 |
| `spawn:Depart` | `spawn:DepuisPort` | 4.4 | 180 |
| `spawn:DepuisForet` | `exit:VersForet` | 4.4 | 309 |
| `Panneau` | `Chipie` | 4.6 | 2 |
| `TriceratopsMalade` | `CrottesTriceratops` | 4.6 | 252 |
| `PierrePlate` | `GueDeLune` | 4.8 | 338 |
| `FeuCamp` | `spawn:Voyageur` | 5.2 | 4 |
| `RocherGrotte` | `RocherGrotte2` | 5.4 | 243 |
| `Ambre` | `FeuCamp3` | 5.5 | 294 |
| `Page2` | `GueDeLune` | 5.5 | 350 |
| `RocherGrotte2` | `spawn:DepuisGrotte` | 5.7 | 58 |
| `GrandVoyageur` | `spawn:Voyageur` | 5.7 | 78 |

Remarques sur ces adjacences : `RocherGrotte` est à 0,6 m de `spawn:DepuisGrotte` (le rocher a disparu quand Chloé revient de la grotte, mais un rocher élargi couvrirait ce point) ; `spawn:DepuisAntre` est à 3,4 m de la sortie de l'antre (réarmement : le point d'arrivée doit rester hors du rectangle de sortie) ; `Panneau` (carrefour) est à 4,6 m de la case de départ de Chipie.

## 4. Graphe des trajets

**Méthode** (`scratchpad/agent_audit/bfs.gd`, lancé avec `Godot_v4.7.2-stable_win64_console.exe --headless --path Godot --script … -- dump=… out=… maps=…`). Grille de 0,5 m (480 × 360), Dijkstra à 16 directions (± 2 %), mêmes règles que `Blockers3D` : cases forêt et eau bloquées, bords fermés, falaise (> 0,75 m entre deux cases voisines, `ZoneSource.is_cliff`) = mur, props solides à taille réelle gonflés du rayon de Chloé (0,17 m). Distances de marche de centre d'accès à centre d'accès, portée d'interaction de 1,3 m comprise. Largeur de passage = 2 × la plus petite distance au mur le long du meilleur trajet (± 0,5 m). Deux modes : **maintenant** (ce que le 3D bâtit aujourd'hui : aucun obstacle d'histoire) et **fermé** (les obstacles d'histoire posés à leur taille réelle).

Aire libre : 34138 m², dont 26774 m² atteignables depuis l'arrivée (78 %). Le reste : montagnes du nord et de l'est, crête ouest et mur sud du plateau, dessus de la butte du Crâne, îlot de l'étang.

### 4.1 Distances de marche (mètres) entre les ancres principales, mode « maintenant »

```
         1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23
 1       0   20   89   82   43   83   98  107   78  117  127  155  128  130  122  131  191  107  111   96  112  141    3
 2      20    0   68   61   23   74   77   87   60   97  111  139  108  110  106  115  175   96  101   86  100  131   23
 3      89   68    0   21   49   88    9   38   41   49   88  116   42   44   64   73  132   92   99   88   96  128   91
 4      82   61   21    0   38   67   28   58   55   40   71  100   51   53   84   93  153  107  115  102  112  107   84
 5      43   23   49   38    0   62   58   72   51   74   92  120   86   89   97  106  166   98  103   88  102  119   46
 6      83   74   88   67   62    0   95  122  112   73   54   82  109  111  149  158  217  160  165  150  164   58   85
 7      98   77    9   28   58   95    0   37   44   50   90  118   34   37   59   68  128   94  101   90   99  132  100
 8     107   87   38   58   72  122   37    0   31   86  125  154   62   64   27   36   95   60   68   59   65  165  109
 9      78   60   41   55   51  112   44   31    0   90  126  155   77   79   47   56  116   52   60   46   57  159   79
10     117   97   49   40   74   73   50   86   90    0   46   75   41   43  107  116  175  140  147  136  145   89  120
11     127  111   88   71   92   54   90  125  126   46    0   29   87   89  149  158  218  179  186  173  183   46  129
12     155  139  116  100  120   82  118  154  155   75   29    0  116  118  178  187  246  207  214  201  212   74  157
13     128  108   42   51   86  109   34   62   77   41   87  116    0    3   79   88  148  123  130  121  127  129  131
14     130  110   44   53   89  111   37   64   79   43   89  118    3    0   81   90  149  124  131  123  129  131  133
15     122  106   64   84   97  149   59   27   47  107  149  178   79   81    0   10   69   62   69   61   66  192  124
16     131  115   73   93  106  158   68   36   56  116  158  187   88   90   10    0   59   72   79   71   76  201  133
17     191  175  132  153  166  217  128   95  116  175  218  246  148  149   69   59    0  131  138  129  135  260  193
18     107   96   92  107   98  160   94   60   52  140  179  207  123  124   62   72  131    0    8   12    7  212  109
19     111  101   99  115  103  165  101   68   60  147  186  214  130  131   69   79  138    8    0   16   12  219  113
20      96   86   88  102   88  150   90   59   46  136  173  201  121  123   61   71  129   12   16    0   18  206   98
21     112  100   96  112  102  164   99   65   57  145  183  212  127  129   66   76  135    7   12   18    0  216  113
22     141  131  128  107  119   58  132  165  159   89   46   74  129  131  192  201  260  212  219  206  216    0  143
23       3   23   91   84   46   85  100  109   79  120  129  157  131  133  124  133  193  109  113   98  113  143    0
```

Légende : 1 = arrivee (`spawn:DepuisPort`) ; 2 = debarcadere (`spawn:Debarcadere`) ; 3 = carrefour_maia (`Maia`) ; 4 = voyageur (`GrandVoyageur`) ; 5 = dormeur (`Dormeur`) ; 6 = panneau_anse (`Panneau7`) ; 7 = panneau_oeuf (`Panneau8`) ; 8 = etang_panneau (`Panneau6`) ; 9 = elise (`Elise`) ; 10 = nid_chipie (`NidChipie`) ; 11 = tronc (`TroncBosquet`) ; 12 = bosquet_ambre (`AmbreProtoceratops`) ; 13 = rocher (`RocherGrotte`) ; 14 = sortie_grotte (`exit:VersGrotteEchos`) ; 15 = porte_ambre (`PorteAmbre`) ; 16 = falaises_spawn (`spawn:Falaises`) ; 17 = poste_ecaille (`Ecaille`) ; 18 = crane_porte (`PorteCrane`) ; 19 = alpha (`Alpha`) ; 20 = crane_spawn (`spawn:Crane`) ; 21 = sortie_antre (`exit:VersAntreCrane`) ; 22 = sortie_foret (`exit:VersForet`) ; 23 = sortie_port (`exit:VersPortAmbre`). Matrice symétrisée (écart d'asymétrie maximal 1,9 m). Temps : diviser par **3,44 m/s** à la marche, **4,98 m/s** en courant.

### 4.2 Le graphe en clair

```
                         nord : rocher à 42 m de Maïa (la grotte est 3 m derrière)
                               |
   tronc --(88 m)-- CARREFOUR de Maïa --(64 m)-- porte d'ambre --(70 m)-- poste d'observation
   (bosquet : ambre       /    |    \                (défilé de 4 m)          (rampes de 0,6 m)
    à 28 m derrière   voyageur |     \--(38 m)-- étang --(60 m)-- Grand Crâne (92 m de Maïa)
    le tronc)          (21 m)  |                                  (encoche de 8 m, antre)
                          route de 89 m
                               |
                   ARRIVÉE (DepuisPort) ; sortie du port à 3 m

   ouest : sentier de la Forêt à 126 m de Maïa (sortie à 140 m de l'arrivée)
```

Depuis l'arrivée : carrefour 89 m (26 s) ; Grand Voyageur 81 ; étang (panneau) 107 ; porte du Crâne 108 ; Alpha 111 ; porte d'ambre 122 ; tronc 127 ; rocher 128 ; sortie grotte 130 ; spawn Falaises 131 ; sortie Forêt 140 ; bosquet (ambre) 155 ; poste d'observation (écaille) 191 ; **ancre la plus lointaine** : `galet_plaines_04` (289 m, voir ci-dessous).

### 4.3 Passages étroits (derrière quoi se trouvent des ancres), culs-de-sac

| passage | tuile | largeur (m) | ce qui n'est atteignable que par là | cul-de-sac ? |
|---|---|---|---|---|
| defile_porte_ambre | (93 ; 37) | 3.5 | tout le plateau nord-est : 12 ancres (panneau des falaises, page 3, écaille, table, 2 nids, feu, spawn Falaises) et 5 galets (Galet25, Monticule21, galet_plaines_02 et _08, galet 04 par le rebord) | oui |
| encoche_grotte | (57.5 ; 24) | 3.5 | EntreeGrotte et sortie vers la Grotte des Échos | non : sortie vers une autre zone |
| encoche_crane | (103.5 ; 59) | 3.5 | AntreCrane et sortie vers l'antre de l'Alpha | non : sortie vers une autre zone |
| ouverture_bosquet | (20 ; 40) | 4.0 | bosquet d'Hélène : fragment d'ambre/page 1, monticule galet 22 | oui |
| sentier_foret | (1 ; 51.5) | 4.0 | sortie vers la Forêt Jurassique (verrouillée par la selle) | non : sortie vers une autre zone |
| route_port | (60 ; 89) | 4.0 | sortie vers Port-Ambre (couloir libre de 20 m entre les deux forêts, route de 4 m) | non |
| rebord_est | (113 ; 27) | 1.0 | galet_plaines_04 dans un araucaria à 4,8 m, 289 m de marche | oui |
| poche_nord_ouest | (15.6 ; 13.9) | 3.0 | galet_plaines_01 (fougère arbre à (8,25 ; 15,7)), au nord de l'anneau de forêt du bosquet | oui |

Tout le reste de la zone est large (≥ 5 m). Les valeurs de 4,2 m qui reviennent près des décors sont l'effet des props voisins de l'ancre, pas des couloirs. Culs-de-sac : le **bosquet** (1 ambre, 1 monticule), le **plateau nord-est + poste d'observation** (12 ancres, 4 galets), le **rebord est** (1 galet), la **poche nord-ouest** (1 galet, derrière un col de 3 m au nord de l'anneau de forêt), le **haut de la butte de la Grotte** (par la rampe est de 0,6 m par marche : 2 galets), les **plages de la crique** (sable, 1 feu, 1 panneau, 1 galet). Les trois « poches à écaille » (bosquet, fond de la grotte, poste d'observation) ne se touchent pas.

**Inaccessible à pied aujourd'hui** : `GaletIlot`, `Page2`, `PierrePlate` (îlot de l'étang ; il faut le gué de pleine lune, que `Blockers3D` ne sait pas ouvrir), les montagnes, le dessus de la butte du Crâne (3,6 m à pic).

### 4.4 Les serrures fuient à taille réelle

| serrure | ouverture (cases) | ouverture (m) | obstacle (m) | reste de chaque côté (m) | à pied, ouvert (m) | largeur mini, ouvert | à pied, obstacle posé (m) | largeur mini, obstacle posé | fuite |
|---|---|---|---|---|---|---|---|---|---|
| tronc / bosquet d'Hélène | x 19-20, y > 36 (2 cases) | 4.0 | 2,17 × 0,63 | 0.9 | 155.3 | 4.0 | 155.3 | 1.0 | OUI |
| rocher / Grotte des Échos | x 57-58, y 23-24 (2 cases) | 4.0 | 2,0 × 0,7 | 1.0 | 129.8 | 3.5 | 129.8 | 2.5 | OUI |
| porte d'ambre / falaises | x 92-93, y 36-37 (2 cases) | 4.0 | 2,0 × 0,63 | 1.0 | 191.0 | 3.5 | 191.0 | 1.0 | OUI |
| porte d'ambre du Grand Crâne / antre | x 102-105, y 58-61 (4 cases) | 8.0 | 4,0 × 0,63 | 2.0 | 111.4 | 4.5 | 111.4 | 2.0 | OUI |

Avec l'obstacle posé, l'ancre derrière reste atteignable à **la même distance** (± 2 m) : il passe un couloir de 1 à 3 m à côté de l'obstacle. En 2,5D, 1 case = 1 m de décor réel et les ouvertures valaient 2 m : le tronc de 2,17 m les fermait exactement. Corrections possibles (au concepteur) : mettre l'obstacle à la largeur de l'ouverture (4 / 4 / 4 / 8 m, son modèle 3D à la même largeur) ou lier un blocage invisible à `cleared_flag` ; pour la porte du Crâne, 8 m de large, ou une porte à deux battants.

## 5. Contexte d'open world

Sources : table de géographie (`docs/histoire.md:122-141`), `data/atlas_db.gd:9-20`, `tools/maps/gen-couches.mjs:20-24`, sorties `B.exit` (`tools/zones/plaines.gd:309-317` et zones voisines). L'atlas (`bounds`, de 0 à 1) donne un recouvrement approximatif ; les régions sont des cellules gauchies, **ne pas en déduire des coordonnées exactes**.

| bord / voisin | côté Prairie | côté voisin et raccord | atlas / histoire |
|---|---|---|---|
| **Sud** : Port-Ambre | Prairie, bord y = 90 (z = 180 m). La route de 4 m, dans un couloir de 20 m (cases x 55-64) entre deux forêts, arrive au bord ; sortie `VersPortAmbre`, rect m (116 ; 178,9 ; 8 × 1,1), exige `prologue_done` | arrive à `DepuisPort` (60 ; 88,2) = (120 ; 176,4) m ; côté Port : sortie nord (15-19 ; 0) → `DepuisPlaines` (17 ; 1,5), zone 40 × 24 cases. Raccord latéral : Port x = 17 ↔ Prairie x = 60, donc Port(x ; y) ≈ Prairie(x + 43 ; 90 + y) (déduit des deux arrivées, à confirmer) | recouvrement atlas 9 % ; « la route du port monte dans les prés » |
| **Ouest** : Forêt Jurassique | bord x = 0, lignes 47-57 : sentier de 2 cases (lignes 51-52), herbes hautes de part et d'autre ; sortie `VersForet` rect m (0 ; 100 ; 1,1 × 8), exige le drapeau `selle` (message `foret_bloquee`) ; forêt de cases x < 4-8 partout ailleurs sur ce bord | arrive à `DepuisPlaines` (126 ; 52) de la Forêt (zone 130 × 100) ; la sortie de la Forêt est son rect (129,45 ; 50 ; 0,55 × 4) : **mêmes lignes 50-54**, Forêt(x ; y) = Prairie(x − 130 ; y). Fondu de sols sur **16 cases (32 m)** de profondeur de chaque côté, sur tout le bord (`gen-couches.mjs:22-23`, cases 0-89) : sous-bois fondu dans l'herbe, fougères et champignons sur 30 % des cases (`plaines.gd:62-63`) | recouvrement atlas 26 % (la plus grande frontière) ; « le bois qui borde les Plaines à l'ouest s'épaissit » |
| **Nord** : Plaine Volcanique / Terre des Apex | montagnes y < 13 (jusqu'à 7-10 m) : aucune sortie, pas de passage | — | recouvrement atlas 30 % (Volcan) ; à voir en arrière-plan |
| **Est** : Monts Gelés | montagnes x > 106 (jusqu'à 12 m, rebord de 2 m à x = 113) : aucune sortie | — | recouvrement atlas 14 % ; « au sud, ce sont les montagnes à l'est des Plaines » (`histoire.md:139`) ; Chap. 6 y monte par la Côte, pas par ici |
| **Sud-ouest** : mer | crique de 773 cases (3 092 m²) qui touche le bord ouest (lignes 69-89) et le bord sud (x 0-40) | — | plage de sable autour ; nappe de mer qui déborde de 260 m |
| **Est de Port-Ambre** : Havre-Doré | pas de sortie de la Prairie : on y va par la route côtière du Port (garde, Sceau des Plaines) | — | recouvrement atlas 1 % |
| Intérieur : Grotte des Échos | encoche sud de la butte, rect m (114,4 ; 45,9 ; 3,2 × 1,0) ; sans condition (le rocher bouche physiquement) | zone 24 × 18, arrive à `DepuisCarrefour` (11,9 ; 16,2), sa sortie (10-14 ; 17,45) renvoie à `DepuisGrotte` | — |
| Intérieur : antre de l'Alpha | fond de l'encoche du Crâne, rect m (205 ; 116 ; 6 × 1,2), exige `crane_ouvert` | zone 14 × 12, arrive à `DepuisPlaines` (7 ; 10,4), sa sortie (6-8 ; 11,45) renvoie à `DepuisAntre` | — |

Atlas : la Prairie couvre `Rect2(0,422 ; 0,521 ; 0,227 ; 0,299)`, ses zones sont `[plaines, grotte_echos, antre_crane]` (`data/atlas_db.gd:9`). Les arrivées de voyage rapide et des anciennes sauvegardes (`Voyageur`, `Debarcadere`, `Carrefour`, `Falaises`, `Crane`) sont des points de la Prairie, pas des raccords.

## 6. Risques : où un relief ou une forêt dense casserait l'histoire

| id | gravité | risque |
|---|---|---|
| R1 | CRITIQUE | Les serrures ne ferment plus à taille réelle (§ 4.4). Quel que soit le futur relief, il faut une décision : obstacles à la largeur de l'ouverture, ou blocage lié aux drapeaux. |
| R2 | CRITIQUE | La forêt dense EST un mur de gameplay : anneau du bosquet (la seule entrée est l'ouverture du tronc), bandes ouest et sud (le sentier de la Forêt est le seul trou de l'ouest), petit bois du nid. Une « végétation praticable » dans ces cases ouvre le bosquet sans Tranche, la Forêt sans selle et casse l'ordre « trois passages ». À distinguer : végétation praticable en prairie, forêt murale aux endroits listés (`forest_masses`). |
| R3 | CRITIQUE | Les quatre passages de 4 m (ouverture du bosquet, encoche de la grotte, défilé, encoche du Crâne) sont de l'histoire : tout relief, rocher ou arbre qui les rétrécit sous ≈ 3 m, ou leur ajoute une marche > 0,35 m (sans rampe) à l'entrée, les ferme. Les encoches sont au niveau 0 dans des buttes de 3,6 m : garder l'accès de plain-pied depuis le sud. |
| R4 | HAUT | Les 4 sorties : sud (route 4 m, couloir libre 20 m jusqu'au bord), ouest (sentier, lignes 47-57, entre murs de forêt), encoche de la grotte, encoche du Crâne. Une pente ou une forêt devant le rectangle de sortie, ou un spawn dans un obstacle élargi (`DepuisGrotte` est à 0,6 m du rocher), bloque l'entrée ou le retour. |
| R5 | HAUT | Le gué de lune : `Blockers3D` construit ses boîtes d'eau une fois ; les 4 cases du gué ne s'ouvrent pas en 3D, l'îlot (page 2, galet, pierre) est inaccessible (3 ancres). Les 4 points de chant sont à ≥ 5 m dégagés autour du bord de l'étang, rive et pente douces. |
| R6 | HAUT | L'avant-cour du Crâne : l'Alpha (taille 1,2) sort de l'encoche (8 × 8 m) et marche 7,8 + 5,5 m jusqu'à (107,2 ; 63,8) ; Maïa arrive par l'ouest en ≈ 23 m de ligne droite ; aucune colline ni arbre dans les 12 m autour de la porte. `ALPHA_SPOT` est sur une pente de 0,6 m : à garder douce. |
| R7 | HAUT | La scène d'Élise est cadrée avec `close_up` à 9,5 m ; le 2,5D vide 8 × 10 cases au SUD du trio pour ne pas le cacher. En 3D, le bras de caméra (jusqu'à 14 m, rayon 0,25 m) est repoussé par les murs/arbres solides : pas d'arbre ni de relief > 1 m sur ≈ 10 m autour du groupe et vers la caméra ; surtout pas d'herbe haute (elle cache le Tricératops couché). |
| R8 | HAUT | Rampes en marches de 0,6 m : (66-71 × 15-17) vers le haut de la butte, (90-91 × 14-17) et (96-97 × 21-24) vers le poste d'observation. 0,6 m dépasse la marche de Chloé (0,35 m) : c'est la pente lissée (17°) qui la monte. Les remplacer par une pente > 46° ou des marches > 0,65 m coupe l'accès au poste d'observation (3 ancres d'histoire dont l'écaille n°3 et la page 3). |
| R9 | HAUT | Galets : 16 sont dans des arbres/cailloux qui doivent rester des objets individuels secouables ; 8 monticules sur sol plat ; `galet_plaines_04` n'est atteignable que par un rebord de 2 m, 289 m de marche ; `galet_plaines_01` derrière un col de 3 m. Si le décor est régénéré, il faut garder 30 galets accessibles et l'indice « les larmes scintillent » (lanterne d'ambre) lisible. |
| R10 | HAUT | Les habitats portent les capacités d'histoire (Protoceratops dans les herbes hautes pour Charge, Parasaurolophus à l'étang pour Résonance, Velociraptor aux lisières de nuit pour Tranche) : supprimer ou isoler des herbes hautes ou l'étang bloque la progression. |
| R11 | MOYEN | Cohérence cartographique : le panneau du carrefour dit N grotte, NE falaises, E étang puis Crâne, O bosquet, S port ; les repères HUD (`objectives.gd`) et les sorties du voisin supposent la même carte ; l'atlas et le Dinodex lisent les rectangles des habitats. |
| R12 | MOYEN | Coordonnées en dur du § 3.3 : déplacer une ancre sans mettre à jour ses copies casse la scène sans erreur (Alpha qui apparaît dans la roche, Chipie qui disparaît, Maïa qui arrive d'un point devenu forêt, repère HUD à côté). |
| R13 | MOYEN | Chipie : l'angle de fuite doit rester dégagé (4 bonds, 35,6 m) ; la case de cachette (59,2 ; 47,2) est un chemin ; elle doit pouvoir être poursuivie à pied sans caméra bloquée par le petit bois au nord. |
| R14 | MOYEN | Hauteur des ancres : le poste d'observation est à 4,8 m, le haut de la Grotte à 3,6 m ; les ancres lisent `ZoneSource.to_3d` (relief du 2,5D) : tout nouveau relief doit conserver ces hauteurs sous les ancres ou les ancres doivent suivre le sol. |
| R15 | BAS | Le maillage de navigation des dinos (agent_radius 0,5 m, pente max 40°, montée max 0,25 m) laisse passer les ouvertures de 4 m ; un compagnon de 2 m qui suit Chloé dans le défilé reste à l'aise, un Brachiosaure de taille 1,6 non. |

## 7. Ambiguïtés et limites de cet audit

- Les largeurs de passage sont estimées sur une grille de 0,5 m (± 0,5 m) ; les distances de marche à ± 2 %. Le sol réel sous Terrain3D diffère de `ZoneSource.height_at` de quelques centimètres ; la pente (46°) et les marches de 0,35-0,75 m peuvent ouvrir ou fermer quelques cases que ce graphe traite en bloc (78 arêtes concernées, toutes dans les rampes et la butte).
- Le comportement exact d'un obstacle ou d'une porte en 3D n'existe pas encore : le mode « fermé » suppose leur empreinte du 2,5D (`Prop.KINDS`, `solid`) à taille réelle.
- Les rayons « dégagés » des ancres (`needs_clear_radius_m`) sont mes estimations à partir des distances des scènes, pas des valeurs lues dans le code ; les rectangles `KEEP_CLEAR` et `ELISE_SCENE`, eux, sont lus.
- `NEAR` de Chipie (150 px) est en pixels du 2,5D : comment le 3D le convertira (6,25 m si × 2) n'est pas décidé.
- Le raccord Port ↔ Prairie ((x + 43 ; 90 + y)) est déduit des deux arrivées, pas écrit ; les recouvrements d'atlas sont des boîtes englobantes.
- Le comptage « par fichier » du § 3.3 est textuel (recherche de motifs) : il peut compter une même coordonnée deux fois (déclaration et utilisation) ; les lignes citées sont exactes.
- Le nombre exact de touffes d'herbe haute dépend du profil de qualité ; ≈ 6 500 est un maximum.

## 8. Reproduire

Scripts (hors dépôt) dans `C:\Users\Greg\AppData\Local\Temp\claude\c--Users-Greg-Dinogame\aa9fbe3f-7ab8-4014-af30-111fefc49159\scratchpad\agent_audit\` : `dump.gd` (lit toutes les ancres), `tiles.gd` (grille des cases), `bfs.gd` (graphe de marche, 2 × ≈ 160 s), `decor.gd` (comptes de décor), `build_docs.py` / `extra.py` / `build_md.py` (écrivent ces deux fichiers). Lancement type : `"C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path C:\Users\Greg\Dinogame\Godot --script <script> -- out=<fichier>`.