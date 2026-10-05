# Port-Ambre — plan de conception 3D

> Zone `port_ambre` (village de pêcheurs, prologue, retour au port), version PC 3D sous Godot
> (Terrain3D). Document de conception seul : **aucun code, aucune donnée modifiée**. Lu dans
> `tools/zones/port_ambre.gd`, `story/prologue.gd`, `story/plaines.gd` (retour au port),
> `story/clins_doeil.gd` (la porte du Cabinet), `story/voyage.gd`, `data/dialogue_db.gd`,
> `data/wildlife_db.gd`, `docs/lore.md`, `docs/histoire.md`, `docs/direction-artistique.md`
> (bâtiments assemblés). Règles générales : `../conception-zones-3d.md`.
>
> **Repère** : mètres 3D, origine au coin **nord-ouest**, **x vers l'est**, **z vers le sud**,
> y = hauteur au-dessus de la mer (0). Une case du 2,5D (tx, ty) est à (2·tx, 2·ty). Le 2,5D fait
> 40 × 24 cases, soit 80 × 48 m. La Prairie est au nord : Port x = Prairie x − 86 (plan de la
> Prairie, § 7 : route à x 116-124 de la Prairie = x 30-38 ici, à 2,5 m).

## 1. Audit : ce que l'histoire impose

Tout ce qui suit est lu dans les scripts ; les positions sont en cases du 2,5D → mètres 3D.

### 1.1 Personnages et dinos d'histoire

| Nœud | Qui | Cases (x ; y) | Mètres (x ; z) | Condition | Rôle |
|---|---|---|---|---|---|
| `IsaureQuai` | Isaure, au bout du ponton | (20,3 ; 21,4) | (40,6 ; 42,8) | cachée après `prologue_arrived` | arrivée : regarde les falaises au nord avec Chloé |
| `MaiaQuai` | Maïa, en haut du ponton | (19,8 ; 15,8) | (39,6 ; 31,6) | idem | descend le ponton vers Chloé (19,8 ; 17,2 → 19,8) |
| Caillou (acteur de scène) | Protoceratops de Maïa, sieste | (21,3 ; 15,5) | (42,6 ; 31,0) | prologue | la caméra le montre ; il trottine ensuite vers le Cabinet |
| `Isaure` | Isaure, sur le quai | (22,6 ; 15,7) | (45,2 ; 31,4) | après `prologue_done`, dialogue `isaure` | « Tu vois cette jetée ? … tellement il y avait de barques » |
| `Garde` | Le garde du Havre | (37,6 ; 8,6) | (75,2 ; 17,2) | dialogue `garde_route` | ne laisse passer qu'avec `sceau_plaines` |
| `GrandVoyageur` | Brachiosaure (taille 1,6, ~14 m) | (26,6 ; 15,4) | (53,2 ; 30,8) | event `grand_voyageur` | escale du voyage rapide ; « le quai est le seul terrain assez ouvert » |
| `RocNuit` (acteur) | Roc avec sa lanterne | sort du Cabinet (31,5 ; 9,1) | (63 ; 18,2) | `maia_defi_1`, nuit | va vers le nord par « le vieux sentier derrière le Cabinet » |
| `RocPorte` + raptor (acteurs) | Roc montre sa serrure neuve | devant la porte du Cabinet | (63 ; 18,2) | `sceau_foret`, jour | un raptor ouvre la porte : la porte 3D doit être une vraie porte (`Doorway`) |

### 1.2 Trajets de scène (à garder libres, sol plat, largeur ≥ 3 m)

| Scène | Trajet (cases → mètres) | Contrainte |
|---|---|---|
| Arrivée : Isaure et Maïa au Cabinet (`prologue.gd:75-78`) | quai (19,8 ; 15,8) → (18,2 ; 15,6) → nord jusqu'à la rue (18,2 ; 10,2) → est (31,4 ; 10,2) → porte (32 ; 8,9) ; en mètres : la **ruelle du ponton** x 36-38, z 31 → 20, puis la **rue** z 20-21 de x 36 à 64 | la ruelle ponton → rue et la rue jusqu'au Cabinet restent droites et dégagées ; Caillou suit par x 37,2 |
| Caméra : « la grande maison couverte de lierre, à l'est du village » | `Stage.look_at` (31,5 ; 9,4) → (63 ; 18,8) | le Cabinet doit être **reconnaissable de loin** depuis le quai : le plus haut toit, du lierre |
| Retour au port (`plaines.gd:302-346`) | Chloé observe de `PORT_WATCH` (26 ; 10,6) → (52 ; 21,2), regarde la porte du Cabinet (63 ; 18,2) ; Roc : (33,6 ; 9,4) → (35,2 ; 6) → (36 ; 3) soit (67,2 ; 18,8) → (70,4 ; 12) → (72 ; 6), caméra sur (34,2 ; 6,4) → (68,4 ; 12,8) | **un sentier existe réellement** au coin est du Cabinet, qui monte vers le nord dans le bois ; rien de solide sur ces points ; vue dégagée depuis (52 ; 21,2) |
| Allumage des lanternes (`_light_lanterns`) | toutes les `OmniLight3D` avec meta `lamp`, de l'ouest à l'est, 0,45 s chacune | les lanternes 3D portent le meta `lamp` ; leur nombre fixe la durée (4 → 1,8 s ; 8 → 3,6 s) |

### 1.3 Sorties, arrivées, panneaux, ponton

| Nœud | Cases | Mètres | Note |
|---|---|---|---|
| sortie `VersPlaines` | rect (15 ; 0 ; 4 × 0,55) | (30 ; 0 ; 8 × 1,1) | exige `prologue_done`, sinon `port_bloque` ; bord nord, x aligné sur la route de la Prairie (116-124) |
| sortie `VersHavreDore` | rect (39,45 ; 9 ; 0,55 × 3) | (78,9 ; 18 ; 1,1 × 6) | exige `sceau_plaines`, sinon `route_cotiere` ; bord est |
| sortie `VersCabinet` | rect (30,9 ; 8,35 ; 1,2 × 0,5) | (61,8 ; 16,7 ; 2,4 × 1) | la porte du Cabinet ; `cabinet` est une zone intérieure |
| arrivées | `Depart` (19 ; 21,2) · `DepuisPlaines` (17 ; 1,5) · `DepuisCabinet` (31,5 ; 9,7) · `DepuisHavre` (37,8 ; 10,5) · `Voyageur` (23,8 ; 15,9) | (38 ; 42,4) · (34 ; 3) · (63 ; 19,4) · (75,6 ; 21) · (47,6 ; 31,8) | tous conservés (vieilles sauvegardes) |
| `panneau_plaines` (retourné) | (20,8 ; 2,8) | (41,6 ; 5,6) | « Nord : la Prairie. Est : le Cabinet » |
| `panneau_route_cotiere` | (36,2 ; 8,7) | (72,4 ; 17,4) | « Péage : un Sceau d'Alpha » |
| `panneau_escale` | (27,6 ; 16,5) | (55,2 ; 33) | planche plantée, fougère gravée, « traces de pas énormes » |
| ponton (`B.dock`) | rect (18 ; 17 ; 3 × 6) | (36 ; 34 ; 6 × 12) | bois, dans la mer ; `Depart` et Isaure dessus |
| barques amarrées | (23,2 ; 20,4) (15,6 ; 19,6) (28,5 ; 19,2) | (46,4 ; 40,8) (31,2 ; 39,2) (57 ; 38,4) | flottantes, le long du quai |

### 1.4 Ce qui ne doit pas bouger

- Le **ponton au sud** avec `Depart` et Isaure dessus ; le **quai** comme seul terrain ouvert pour le
  Grand Voyageur, **à l'est du ponton** ; le **Cabinet à l'est du village**, sa porte au sud sur la
  rue ; le **vieux sentier derrière le Cabinet** qui part vers le nord ; la **route nord** vers la
  Prairie à x 30-38 ; la **route est** gardée, au bord est ; le regard d'Isaure « vers le nord » sur
  des falaises où l'ambre luit (il faut une paroi veinée d'ambre visible depuis le ponton).
- Les relations de texte : « la grande maison couverte de lierre, à l'est du village » ; « la
  Prairie du Grand Crâne est au nord du village » ; « Havre-Doré est au bout de la route, à l'est ».
- Habitats : aucun (pas de rencontre à Port-Ambre, `dex_places.gd`) ; profil faune `port`.
- Les 4 bâtiments 2,5D ont **déjà leur modèle 3D assemblé** (`assets/models/volumes/` :
  maison_blanche, maison_jaune, maison_port, cabinet) ; le Cabinet et ses portes servent aux
  scènes `Doorway` (Roc sort, le raptor ouvre, Isaure et Maïa entrent).

## 2. Le parti : « le village sur sa marche, entre la mer et le bois »

1. **Cadre agrandi à 120 × 64 m** (le 2,5D ×2 occupe x 0-80, z 0-48, sans déplacement) : les
   40 m de l'est deviennent le **début de la route côtière**, « entre mer et collines », avec le
   poste du garde et la **Pointe d'Ambre**, falaise veinée d'ambre qui tombe dans la mer : c'est
   ce qu'Isaure montre en arrivant. Les 16 m du sud sont de la mer (le ponton s'y avance).
2. **Trois marches de terrain** : la terrasse des maisons (3 m) et la rue (2,5 m), le quai (1,2 m),
   la mer (0). Pas d'escalier : des rampes douces (la ruelle du ponton, la rampe de la halle).
3. **Un village en déclin, pas mort** : neuf bâtiments au lieu de quatre, mais la moitié a les
   volets clos, les filets sèchent vides, une seule barque rentre à l'aube. La **halle aux
   poissons**, ouverte et à moitié vide, est au cœur du quai ouest.
4. **Le Cabinet domine** : sur la terrasse, au coin est, le plus grand toit, couvert de lierre, une
   lanterne allumée la nuit à sa porte. Derrière lui le vieux sentier monte au **Guet**, un petit
   belvédère sur le village et la baie (récompense du cul-de-sac que Roc emprunte).
5. **La révélation à l'arrivée en barque** : du ponton on voit tout le village étagé, le Cabinet à
   droite, la Pointe d'Ambre qui brille plus loin à droite, le bois et le Seuil de la Prairie au fond.
6. **La révélation depuis la Prairie** : la route descend du Seuil entre les arbres du Bois du Port,
   et au débouché du bois (z 6) le village, le ponton et la mer apparaissent d'un coup.

## 3. Composition (positions en mètres, façade = milieu du pied, +z = devant)

### 3.1 Les rues

| Voie | Tracé | Largeur | Sol | Pente |
|---|---|---|---|---|
| Rue principale | z 18-24, de x 4 (grève) à x 82 (poste du garde) | 6 m | pavés usés, herbe entre | plate à 2,5 m |
| Route côtière | de (82 ; 21) à (120 ; 21), monte à 3,5 m au bord est | 4 m | terre et pavés épars | 2,6 % |
| Route de la Prairie | de (34 ; 18) à (34 ; 0), entre deux rangées d'arbres | 4 m (couloir libre 8 m) | terre | plate (2,5 m), le Seuil est au-delà |
| Ruelle du ponton | de (37 ; 24) à (37 ; 30) : rampe 2,5 → 1,2 m | 4 m | pavés | 22 % → **à adoucir : rampe sur 8 m (z 22-30) = 16 %** |
| Rampe de la halle | de (22 ; 24) à (18 ; 30) | 3 m | pavés | 16 % |
| Quai | z 30-34, x 8-72, bord de pierre à 1,2 m, bittes | 4 m | dalles | plat |
| Vieux sentier de Roc | (67 ; 18) → (70 ; 12) → (72 ; 6) → le Guet (78 ; 4), à 7 m | 1,5 m (sente) | terre, racines | 12° max |
| Grève | x 0-8, z 24-40, sable qui descend à la mer | — | sable | 8 % |

### 3.2 Les bâtiments (9 ; les 4 premiers existent en 3D)

| Bâtiment | Façade (x ; z) | Emprise L × P (m) | Qui y vit / à quoi ça sert | Modèle |
|---|---|---|---|---|
| maison_blanche | (13 ; 16,6) | 6,8 × 6,2 | la famille du vieux pêcheur Nestor (PNJ proposé) ; jardinière, chat de pierre | existe |
| maison_jaune | (25,2 ; 16,6) | 5,9 × 6,1 | Berthe, la fumeuse de poissons (PNJ proposé) ; fumée du toit le matin | existe |
| **maison du filetier** (nouveau) | (36 ; 16,6) | 6 × 6 | face au débouché de la ruelle : volets clos, filets pendus, « À vendre » effacé | à modeler |
| maison_port | (48 ; 16,6) | 6,1 × 5,3 | **la maison d'Isaure et Maïa** (capitaine : bandeau, rames, lanterne de marine) — à trancher § 5 | existe |
| cabinet | (63 ; 16,6) | 8 × 7,3 | le Cabinet d'Hélène (Roc) ; lierre, lanterne à la porte, girouette-fougère | existe |
| **remise à filets** (nouveau) | (78 ; 16,6) | 5 × 4 | appentis bas au bout du village ; borne la rue avant le poste du garde | à modeler |
| **poste du garde** (nouveau) | (90 ; 17,5) | 3 × 3 | guérite + barrière mobile sur la route ; le garde devant, le panneau à côté | à modeler |
| **cabanes de pêcheurs** ×2 (nouveau) | (14 ; 29,5) et (26 ; 29,5), face au quai (+z) | 5 × 4 chacune | dos à la rue (mur aveugle à z 25,5), séchoirs et casiers devant ; une habitée, une close | à modeler (2 dessins) |
| **halle aux poissons** (nouveau) | (20 ; 27), ouverte sur 4 piliers | 8 × 5, 4 m de haut | étals de pierre vides, un seul poisson, bancs ; la vie du quai | à modeler |
| **hangar à barques** (nouveau) | (6 ; 30), porte vers la grève (−x) | 7 × 5 | une barque retournée, cale de halage sur le sable | à modeler |

Règle de la DA : chaque bâtiment a son dessin (pas de doublon dans une ville), origine au pied de la
façade, porte réelle (`Doorway`), toits distincts (tuiles, ardoise, bardeaux).

### 3.3 Le quai et la place du Port (x 44-66, z 24-34 : terrain ouvert, rien de haut)

- Le **Grand Voyageur** à (53,2 ; 30,8), orienté est-ouest le long du quai ; son panneau d'escale à
  (55,2 ; 33) ; arrivée `Voyageur` à (47,6 ; 31,8). Dégagement 16 × 10 m sans décor moyen.
- **Isaure** à (45,2 ; 31,4), face à la mer, près de la bitte de (44 ; 33,6) ; **Caillou** dort à
  (42,6 ; 31) pendant le prologue : une dalle au soleil, à côté d'un tonneau.
- Vignettes : l'ancre rouillée (58,4 ; 27,2), les caisses et tonneaux (59 ; 31) (52 ; 29), le
  cordage (44 ; 32,8), les bittes (9 ; 33,6) (22 ; 33,6) (52 ; 33,6) (66 ; 33,6), un bac à fleurs
  (68 ; 26,4) : les props 2,5D gardés ou peu déplacés (aucun n'est une ancre d'histoire).
- Le **ponton** (36-42 ; 34-46), 6 × 12 m, planches grises, un bollard au bout, la barque de
  l'arrivée amarrée à l'est (46,4 ; 40,8) ; deux autres barques (31,2 ; 39,2) et (57 ; 38,4).

### 3.4 Repères visibles de loin

| Repère | Où | Visible depuis | Annonce |
|---|---|---|---|
| Le Cabinet (toit 9 m, lierre, lanterne) | (63 ; 13) | le ponton, la rue, la route de la Prairie, le Guet | Roc, l'est du village |
| La Pointe d'Ambre (falaise 8 m, veines qui luisent la nuit) | x 96-120, z 28-40 | le ponton (regard d'Isaure « vers les falaises »), le quai | la route côtière, le Havre au-delà |
| Le ponton et la barque | (39 ; 44) | tout le village | l'arrivée, Isaure |
| Le Grand Voyageur | (53 ; 31) | tout le village | l'escale |
| La halle aux poissons (toit 4 m) | (20 ; 27) | le ponton, la rue | le quai ouest, la vie du port |
| Le débouché du Bois du Port (deux grands arbres-portes) | (34 ; 6) | la rue, le quai | la Prairie |
| Le Guet (belvédère, un banc, un vieux pin) | (78 ; 4), 7 m | la rue est, le quai | le vieux sentier de Roc |
| La rangée de lanternes (8) la nuit | z 18, x 10 → 86 | partout | la scène du soir |

## 4. Relief, végétation, faune

### 4.1 Relief (Terrain3D, jamais de marche)

| Lieu | Hauteur | Forme |
|---|---|---|
| mer | 0 (fond −3) | de z 34 au sud ; profondeur lisible (bande claire 2 m le long du quai) ; **le quai est un mur de pierre de 1,2 m** (prop, pas de pente) |
| grève ouest | 0 → 1,5 | sable x 0-8, z 24-40 ; galets, bois flotté, crabes |
| quai | 1,2 | dalle x 8-72, z 30-34 |
| cabanes et halle | 1,2 → 2,5 | pente 16 % entre z 24 et 30, coupée par la rampe de la halle et la ruelle |
| rue | 2,5 | plate ; terrasse des maisons à 3 m (seuils) |
| Bois du Port | 3 → 5 | monte vers le Seuil de la Prairie (5,8 m, 20 m au nord du bord) ; la route reste à 2,5-3 m jusqu'au bord (raccord 2,5 m) |
| le Guet | 7 | butte 12 × 10 m au nord-est, flanc sud en herbe à 25°, la sente en lacet |
| collines de l'est | 4 → 12 | au nord de la route côtière (z < 14, x > 84), pentes herbe 30° puis paroi roche à partir de 10 m |
| Pointe d'Ambre | 3,5 → 8 puis à-pic | au sud de la route (z > 28, x > 92) : dos d'herbe rase, puis **falaise à 70°** vers la mer, strates et veines d'ambre (modules émissifs) |
| bord est | 3,5 | la route au raccord avec Havre-Doré, z 18-24 |

### 4.2 Végétation praticable

- **Bois du Port** (nord, z 0-12 hors route) : arbre_rond et araucaria, canopée 2 / 100 m², sous-bois
  1,5 (fougères arborescentes, buissons), couvre-sol 5 : **traversable** sauf la **lisière dense**
  du bord nord hors du couloir de la route (haie de troncs à 4 m et fougères géantes, comme le
  plan de la Prairie § 7 : « bois du Port (haie) »).
- **Jardins des maisons** : jardinières, un figuier devant la maison blanche, lierre sur le Cabinet,
  fleurs roses aux pieds des lanternes ; le couvre-sol ne bloque jamais.
- **Collines de l'est** : herbe rase, buissons secs, trois araucarias tordus par le vent, oyats
  sur la Pointe ; rien qui barre la route.
- **Bord ouest** : grève, puis les rochers de la crique de la Prairie (hors zone) : des rochers
  visibles ferment le passage, pas un mur invisible.
- **Infranchissable visible** : la mer profonde, le mur du quai, la falaise de la Pointe, la haie
  du bord nord, la barrière du garde (prop mobile, ouverte après `sceau_plaines`).

### 4.3 Faune (profil `port` de `wildlife_db.gd`, inchangé)

| Espèce (`KINDS`) | Nombre | Où elle se montre ici |
|---|---|---|
| `crabe` | 3 | sur la grève et le sable sous la halle ; fuient à 2,2 m |
| `poisson_saut` | 1 | au large du ponton, vu de la caméra seulement |
| `ichthyornis` | 1 | tourne au-dessus de la baie ; se pose (proposition) sur les bittes et le toit de la halle |
| `ptero_vol` | 1 | haut, vers la Pointe |
| effet `plancton` (60) | nuit | l'eau du port scintille au pied du ponton |

**Propositions d'ajout** (3 lignes dans `PLACES[&"port"]`, à trancher) : `ammonite` ×2 dans l'eau
peu profonde le long du quai ; `meduse` ×1 la nuit, luisante, au large du ponton (comme la Côte) ;
`mammifere` ×1 la nuit entre les cabanes. **Dinos du village** (acteurs décoratifs, sans dialogue) :
Caillou pendant le prologue seulement ; proposition d'un **vieux Parasaurolophus de trait**
attelé à la charrette à filets devant la halle le jour, couché endormi dans le hangar la nuit (un
dino ne se couche que pour dormir). Pas d'habitat ni de rencontre : le village reste un refuge.

### 4.4 La vie des PNJ (proposition : dialogues à écrire, pas dans les scripts)

| PNJ | Jour | Soir / nuit | Ce qu'il raconte |
|---|---|---|---|
| Isaure (existe) | sur le quai face à la mer (45,2 ; 31,4) | idem (son dialogue ne dépend pas de l'heure) | la pêche, Hélène, la jetée d'autrefois, le Havre |
| Le garde (existe) | à son poste (75,2 ; 17,2) | idem, lanterne | « Ordre du Comptoir » |
| Nestor (nouveau) | répare un filet sur le banc de la halle | sur le pas de la maison blanche | « Il paie. Au port, plus personne ne paie. » (sans dire qui) |
| Berthe (nouveau) | au séchoir devant sa cabane | rentre à la maison jaune, fumée | le poisson, les gens partis au Havre |
| Un enfant (nouveau) | court sur le ponton, jette des cailloux | à la fenêtre | « T'as vu le gros dino ? Il s'arrête toujours là. » (le Voyageur) |

## 5. Risques et points à trancher par Greg

1. **Cadre 120 × 64 m (recommandé) ou 80 × 48 m.** Avec 120 × 64, le groupe du garde (garde,
   panneau, arrivée `DepuisHavre`, sortie est) glisse de **Δ (+40 ; 0)** en translation pure ; tout
   le reste est à Δ (0 ; 0). Le raccord avec Havre-Doré reste au bord est, z 18-24, à 3,5 m.
   Avec 80 × 48, pas de Pointe d'Ambre ni de route : le garde est collé au Cabinet.
2. **Échelle des bâtiments : ×2 comme la zone (recommandé).** En 2,5D une maison fait 3-4 cases ;
   gardée en « taille réelle » elle ferait 3,4 m de large pour une Chloé de 1,5 m, et les scènes de
   porte (`Doorway`, Roc, le raptor) ne tiendraient pas. ×2 donne des maisons de 6-8 m, réalistes.
3. **maison_port = maison d'Isaure et Maïa (recommandé).** Elles « rentrent » après le Cabinet et
   Isaure vit au port ; la maison au bandeau, la plus proche du quai, leur va. Sinon : une maison de
   la capitaine à modeler sur la grève ouest.
4. **Nouveaux PNJ** (Nestor, Berthe, l'enfant) **et le dino de trait : oui, avec des répliques
   courtes** (données `dialogue_db.gd`, à écrire par l'agent histoire). Sans eux, le village n'a que
   le garde et Isaure comme vivants.
5. **Faune enrichie** (ammonite, méduse la nuit, mammifère) : recommandé, trois lignes de données.
6. **Le vieux sentier de Roc finit au Guet (recommandé)** : belvédère avec banc, récompense du
   cul-de-sac ; Roc y disparaît en fondu « vers le nord ». Sinon le sentier se perd dans la haie.
7. **Lanternes : 8 au lieu de 4** (allumage 3,6 s dans la scène du soir, acceptable) ; si Greg
   veut plus, réduire le pas de 0,45 s (une ligne de code, hors de ce plan).
8. **Pente de la ruelle du ponton** : 16 % sur 8 m (recommandé) ; une alternative est deux
   paliers reliés par deux rampes de 8 %, plus longs (la ruelle passe alors à x 36-40, z 22-30).
9. **Risque Doorway** : les scènes du Cabinet (Roc sort la nuit, le raptor ouvre, Isaure et Maïa
   entrent) demandent que le modèle `cabinet.glb` 3D ait une porte animable et `view.door(house)`
   en 3D ; aujourd'hui le 3D ne porte pas les portes (audit Prairie § 0). À prévoir par l'agent
   gameplay avant de construire la zone.

## 5 bis. Décisions (carte blanche de Greg, 05/10)

Greg a laissé carte blanche : toutes les recommandations du § 5 sont retenues. Le plan ci-dessus
est donc le plan à construire.

| Point | Décision |
|---|---|
| 1. Cadre | **120 × 64 m** ; groupe du garde (garde, panneau, `DepuisHavre`, sortie est) à Δ (+40 ; 0), tout le reste Δ (0 ; 0) |
| 2. Échelle des bâtiments | **×2** comme la zone (maisons 6-8 m, Cabinet 8 × 7,3 m) |
| 3. maison_port | **la maison d'Isaure et Maïa** (bandeau, rames, lanterne de marine) |
| 4. Nouveaux PNJ et dino de trait | **oui** : Nestor, Berthe, l'enfant, le vieux Parasaurolophus de trait ; répliques courtes à écrire par l'agent histoire |
| 5. Faune | **profil `port` enrichi** : ammonite ×2, méduse ×1 la nuit, mammifère ×1 la nuit |
| 6. Sentier de Roc | **finit au Guet** (belvédère, banc, vieux pin, 7 m) |
| 7. Lanternes | **8**, de l'ouest à l'est (allumage 3,6 s) |
| 8. Ruelle du ponton | **rampe 16 % sur 8 m** (z 22-30) |
| 9. Portes 3D (`Doorway`) | **PRÉREQUIS DE CONSTRUCTION** : avant de bâtir la zone, le Cabinet doit avoir une porte 3D animable et `view.door(house)` doit répondre en 3D (Roc sort la nuit, le raptor ouvre, Isaure et Maïa entrent, Chloé entre au Cabinet). Sans cela, ne pas construire le village. |

## 6. Vue de dessus proposée (1 caractère = 4 m ; approximatif ; x 0-120 → colonnes, z 0-64 → lignes)

```
      x: 0   8   16  24  32  40  48  56  64  72  80  88  96  104 112 120
z  0    ^^^^^^^^^^^^^^^^^^^^^=^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   bois dense (haie) sauf la route (=)
z  4    ^^^^^^^^^^^^^^^^^^^^^=^^^^^^^^^^^^^^^^^^oG^^^^^^^^^^^^^^^^^^^^^^^   G = le Guet (7 m) ; o = fin du sentier de Roc
z  8    ^^^^^^^^^^^^^^^^^^^^S=^^^^^^^^^^^^^^^^^^|^^^^^^hhhhhhhhhhhhhhhhhh   S = panneau Prairie ; | = sentier ; h = collines
z 12    ::::::::::::::::::::.=..................|.....hhhhhhhhhhhhhhhhhh   : jardins, terrasse des maisons (3 m)
z 16    ::##B##::##J##::#F#.=.#I#..###CAB###.|.#R#..::::hhhhhhhhhhhh   B blanche, J jaune, F filetier, I Isaure, CAB Cabinet, R remise
z 20    ============================================#g===================   rue (2,5 m) → route côtière ; # g = poste et garde, barrière
z 24    ss..cc..hhhh.cc.....==..................::....ppppppppppppppp   ss grève ; cc cabanes ; hhhh halle ; == ruelle ; p Pointe (herbe rase)
z 28    ssHH.cc.hhhh.cc..a..==..VVVVVVV..c.t....::...pppppcccccccccc   HH hangar ; a ancre ; V Grand Voyageur ; c caisses ; cc falaise
z 32    ssQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ::....cccccccccccccc   Q quai (1,2 m) ; bittes ; Isaure à x 45
z 36    ~~~~~~~b~~~~~~~~~PPP~b~~~~~b~~~~~~~~~~~~~~~~~~~~~~~ccccccccccc   P ponton ; b barques
z 40    ~~~~~~~~~~~~~~~~~PPP~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   Depart et Isaure du prologue au bout du ponton
z 44    ~~~~~~~~~~~~~~~~~PPP~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
z 48    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   mer (0), fond −3
z 52-64 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

Coordonnées clés (m) : sortie Prairie (30-38 ; 0) · panneau Prairie (41,6 ; 5,6) · Cabinet (63 ;
16,6), porte (63 ; 18,2) · `PORT_WATCH` (52 ; 21,2) · sentier de Roc (67,2 ; 18,8) → (72 ; 6) →
Guet (78 ; 4) · garde (115,2 ; 17,2) et panneau (112,4 ; 17,4) [Δ +40] · sortie Havre (118,9-120 ;
18-24) [Δ +40], arrivée `DepuisHavre` (115,6 ; 21) [Δ +40] · Isaure (45,2 ; 31,4) · Caillou (42,6 ;
31) · Grand Voyageur (53,2 ; 30,8), escale (55,2 ; 33), arrivée (47,6 ; 31,8) · ponton (36-42 ;
34-46), `Depart` (38 ; 42,4), Isaure du prologue (40,6 ; 42,8), Maïa (39,6 ; 31,6) · halle (20 ; 27)
· cabanes (14 ; 29,5) (26 ; 29,5) · hangar (6 ; 30) · Pointe d'Ambre (96-120 ; 28-40).

## 7. Ce que je demande aux agents suivants

- **Relief** : les quatre niveaux (0 / 1,2 / 2,5 / 3) et les trois rampes ; le Guet ; les collines
  et la falaise de la Pointe (paroi > 50° peinte roche, modules à veines d'ambre) ; raccord nord à
  2,5 m (x 30-38), raccord est à 3,5 m (z 18-24).
- **Modélisation** (bâtiments assemblés, `tools/modeles3d/maisons.py`) : maison du filetier,
  remise, poste du garde + barrière, 2 cabanes, halle ouverte, hangar à barques ; props : mur de
  quai (module 4 m), bittes, barque (déjà `float`), charrette à filets, lanterne 3D avec
  `OmniLight3D` + meta `lamp`, séchoir, casiers, ancre.
- **Décor** : les 8 lanternes de l'ouest à l'est ; la place du Port dégagée (16 × 10 m) ; le lierre
  du Cabinet ; les vignettes du quai ; les volets clos.
- **Histoire / gameplay** : porter `Doorway` en 3D pour le Cabinet ; déplacer le groupe du garde de
  Δ (+40 ; 0) dans `tools/zones/port_ambre.gd` ; écrire les PNJ proposés ; vérifier que la caméra
  3D de l'arrivée cadre bien le Cabinet depuis (39,6 ; 31,6).
