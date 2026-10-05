# Havre-Doré — plan de conception 3D

> Zone `havre_dore` (la ville marchande de la baie du sud-est : les commerces, le Relais des
> Dresseurs, le Comptoir d'Ambre, les visiteurs, la nuit de la barque), version PC 3D sous Godot
> (Terrain3D). Document de conception seul : **aucun code, aucune donnée modifiée**. Lu dans
> `tools/zones/havre_dore.gd`, `story/havre.gd`, `story/clins_doeil.gd` (Anurognathus, cuisine de
> Pervenche, la chèvre), `story/visiteurs.gd` (Hamon, Malcombe), `story/voyage.gd`,
> `data/dialogue_db.gd`, `data/wildlife_db.gd`, `docs/lore.md` § Havre-Doré, `docs/histoire.md`
> § Interlude, `docs/direction-artistique.md` (bâtiments assemblés).
>
> **Repère** : mètres 3D, origine au coin **nord-ouest**, **x vers l'est**, **z vers le sud**,
> y = hauteur au-dessus de la mer. Case 2,5D (tx, ty) → (2·tx, 2·ty). Le 2,5D fait 56 × 32 cases,
> soit 112 × 64 m. On y arrive par l'ouest, de la route côtière de Port-Ambre.

## 1. Audit : ce que l'histoire impose

### 1.1 Les commerces et la rue haute (façades au sud, sur la rue z 18-24)

| Bâtiment (StoryProp) | Façade (x ; z) | Emprise L × P (m) | Tenancier (Npc, où il se tient) | Scène / event |
|---|---|---|---|---|
| Herboristerie | (12 ; 16,6) | 6,9 × 6,6 | Mémé Pervenche (12 ; 19) | `shop_herboristerie` (boutique, la chèvre) |
| Mercerie « Au Fil d'Ambre » | (27 ; 16,6) | 6,3 × 5,4 | Rosalie (27 ; 19) | `shop_mercerie` |
| Relais des Dresseurs | (45 ; 16,6) | 7,8 × 8,2 | Maïa devant (49,2 ; 19,8) ; Gaspard (39,2 ; 22,4) face à l'est ; Lilou (52,8 ; 22,4) face à l'ouest | `relais` (le tableau), `dresseur_*` (duels) |
| Comptoir d'Ambre (retourné) | (66 ; 16,6) | 8,4 × 7,7 | Maître Ferréol (66 ; 19,2) | `ferreol` ; le **coffre** à (62,4 ; 18) devant sa fenêtre, l'**Anurognathus** dessus |
| Sellerie | (84 ; 16,6) | 6,7 × 6,4 | Joss (84 ; 19,2) | `joss` (la selle) |
| Enseignes | (18 ; 17,4) (32,6 ; 17,4) (52,8 ; 17,4) (58,4 ; 17,4) (90 ; 17,4) | — | — | textes de `dialogue_db.gd` |

Les boutiques sont des écrans (`ShopScreen`) : **pas de zone intérieure** ; `Doorway.shop_in/out`
fait entrer le tenancier puis Chloé par la porte du modèle, puis ressortir. Les portes 3D doivent
donc exister et s'ouvrir (voir risque § 5).

### 1.2 Les maisons, l'entrepôt, le quai

| Bâtiment | Façade (x ; z) | Emprise | Note |
|---|---|---|---|
| havre_maison_1 (retournée) | (99 ; 16,6) | 7 × 6,1 | bout est de la rue haute |
| havre_maison_2 (retournée) | (12 ; 34,6) | 5,6 × 5,6 | rue basse, face au quai |
| havre_maison_3 | (27 ; 34,6) | 7 × 6,1 | rue basse |
| havre_maison_4 (retournée) | (80 ; 34,6) | 6,7 × 5,9 | rue basse, à l'ouest de l'entrepôt |
| Entrepôt du Comptoir (StoryProp, retourné) | (97 ; 34,6) | 10,1 × 5,5 | **porte au sud sur le quai** (Ferréol en sort la nuit) ; enseigne (106 ; 35,4) ; cache du ch. 5 |
| Ponton ouest (`B.dock`) | x 20-26, z 46-58 | 6 × 12 | le pêcheur (23,2 ; 42,8) à sa racine |
| Ponton du Comptoir | x 92-98, z 46-60 | 6 × 14 | la barque d'Isaure accoste à son flanc ouest |

### 1.3 Les scènes et leurs places (à garder exactement)

| Scène | Positions (m) | Contrainte |
|---|---|---|
| **Arrivée** (`havre.gd:55-83`) | Chloé à `DepuisPort` (3,6 ; 21) ; Maïa vient du Relais (49,2 ; 19,8) jusqu'à (6,5 ; 21) ; la caméra montre le Relais (45 ; 20,4), le Comptoir (66 ; 20,4), la Sellerie (84 ; 20,4) ; Maïa retourne à (49,2 ; 19,8) | la **rue haute est droite et ouverte** de x 0 à 90 ; les trois façades se voient depuis l'entrée ouest |
| **Duels** (Gaspard, Lilou) | sur la rue devant le Relais | `S.duel` = écran de combat : pas de place spéciale, juste les deux PNJ atteignables |
| **La cuisine de Pervenche** (`clins_doeil.gd:462-551`) | table (19,5 ; 9,8) dans la **ruelle** entre les murs x 17,6 et 22 ; déclencheur (19,5 ; 13,2) r 2 m ; Chloé s'accroupit à (20,3 ; 11,5) ; les deux Compsognathus viennent de (18,8 ; 3,8) et (20,2 ; 2,6) **« du côté des arbres »**, mangent à (18,4 ; 9,6) (18,2 ; 10,8) et repartent ; Pervenche passe la tête à (18,8 ; 15,6) depuis le coin (18,8 ; 19) et rentre à (12 ; 19) | la ruelle est **vue depuis la rue**, 4,4 m de large, **la forêt à son bout nord** (fougères à z < 5) ; rien entre la table et la rue ; les bacs à fleurs au coin de la boutique |
| **La chèvre Bardane** | (19,6 ; 22,6), montrée après `brac_battu` | à l'embouchure de la ruelle, côté rue, face à la porte de sa maîtresse |
| **L'Anurognathus** (`anuro`) | coffre (62,4 ; 18), dino dessus (+0,6 m) ; Chloé se met à côté, Ferréol à (66 ; 19,2) regarde | le coffre devant la fenêtre du Comptoir, 1,2 m dégagé autour |
| **M. Hamon** (`visiteurs.gd:71-111`) | (68,4 ; 33,2), « près du banc est de la place, regarde la mer » ; se tourne vers le nord (les collines) | le banc (64,8 ; 33,8) à côté ; vue sur la mer et sur les collines depuis la place |
| **Ivan Malcombe** | (49 ; 44,4), « au bord du quai » face à la mer | bord du quai libre sur 3 m |
| **La nuit de la barque** (`havre.gd:281-332`) | la barque sans lumière à (88,6 ; 55,6), **à l'ouest du ponton du Comptoir** ; Isaure débarque à (95 ; 54,4), remonte le ponton (95 ; 50) ; Chloé est téléportée **derrière les caisses** à (88,6 ; 42,2), regarde (97 ; 40) ; Ferréol sort de la porte de l'entrepôt (97 ; 36,6) jusqu'à (97 ; 40,8) ; Isaure monte à (95 ; 42,8) ; une caisse change de bord ; chacun repart | **caisses à (88,4 ; 43,8) et tonneau (90,6 ; 43,6)** : la cachette ; ligne de vue dégagée (88,6 ; 42,2) → (97 ; 40,8) ; le ponton et l'entrepôt alignés à x 92-98 |
| **Grand Voyageur** (`voyage.gd`) | dino à (9,6 ; 42,4), arrivée (14,8 ; 41,2), planche d'escale (6 ; 44,8) | **bout ouest du quai**, sous l'entrée, « loin du marché » : 16 × 10 m dégagés |
| **Sortie / arrivées** | sortie ouest (0 ; 18 ; 1,1 × 6) → Port-Ambre `DepuisHavre` ; `Depart` (6 ; 21), `DepuisPort` (3,6 ; 21) | une seule sortie, au bord ouest, z 18-24 ; raccord à 3,5 m |

### 1.4 Ce qui ne doit pas bouger

- Tout le § 1.1-1.3 : **le plan 3D garde toutes les ancres à Δ (0 ; 0)**. Le 2,5D est déjà juste :
  rue haute des commerces, place du marché au milieu, rue basse des maisons, quai, deux pontons.
- Les relations de texte : « le Relais, là-haut » ; « Joss, la grande maison à l'est » ; « au bout
  du quai, une barque accoste sans lumière, juste devant l'entrepôt du Comptoir » ; « la ruelle
  derrière la boutique » de Pervenche ; « un banc face à l'île » (Hamon).
- Les 10 bâtiments ont **déjà leur modèle 3D assemblé** (`assets/models/volumes/havre_*.glb`), tous
  distincts (règle de la DA : pas de doublon dans une ville).
- Habitats : aucun (`dex_places.gd`) ; profil faune `port` (ambiance commune au village et à la ville).

## 2. Le parti : « la ville en terrasses qui brille »

1. **Cadre agrandi à 136 × 72 m** : le 2,5D ×2 (x 0-112, z 0-64) inchangé ; **à l'est** (x 112-136)
   le **Clos des Dresseurs**, un quartier neuf avec ses maisons, un enclos à dinos harnachés et la
   **digue** qui ferme la baie ; **au sud** 8 m de mer en plus pour les pontons.
2. **Quatre terrasses** vers la mer : les jardins et la lisière (4-6 m), la rue haute des commerces
   (3,4 m), la place du marché qui descend en pente douce (3,2 → 2,2 m), la rue basse (2 m) et le
   quai (1,4 m) ; la mer à 0. Les deux **ruelles** (x 8-12 et x 100-104) sont les rampes.
3. **La révélation** : la route côtière arrive par un col entre les collines et la Pointe ; au bord
   ouest la ville apparaît étagée, toits neufs, la rangée des enseignes, la place qui déborde, les
   mâts du port et la grue du Comptoir au fond. Le contraste avec Port-Ambre se voit en une image.
4. **Une ville qui vit de l'ambre** : caisses marquées du Comptoir partout sur le quai, un porteur
   harnaché, la grue qui charge, des lanternes « à chaque coin de rue » (12), des toits neufs ; et
   derrière, le marché, le Relais, les dinos équipés des dresseurs : « tout le monde a des dinos ».
5. **Les collines au nord** cernent la ville (8-14 m) : pas de passage ; la forêt descend jusqu'au
   dos des boutiques (la ruelle de Pervenche y touche), chaque boutique a son jardin.
6. **Repère de nuit** : les lanternes, la lanterne de la digue, la fenêtre du Comptoir allumée tard.

## 3. Composition (positions en mètres, façade = milieu du pied, +z = devant)

### 3.1 Les voies

| Voie | Tracé | Largeur | Sol | Hauteur |
|---|---|---|---|---|
| Rue haute | z 18-24, x 0 → 112, puis vers le Clos jusqu'à x 130 | 6 m | pavés neufs, caniveau | 3,4 m |
| Place du marché | x 44-68, z 24-36, ouverte sur la rue haute et la rue basse | 24 × 12 | dalles, deux étals, deux bancs, fontaine (nouveau, 60 ; 27) | 3,2 → 2,2 (8 %) |
| Ruelle ouest | x 8-12, z 24-36 | 4 m | pavés, rampe 3,4 → 2 (12 %) | — |
| Ruelle est | x 100-104, z 24-36 | 4 m | idem | — |
| Rue basse | z 36-40, x 4 → 108, puis le Clos | 4 m | pavés | 2 m |
| Quai | z 40-46, x 0 → 112, mur de pierre à 1,4 m, bittes à z 45,6 | 6 m | dalles | 1,4 m |
| Ruelle de Pervenche | x 17,6-22, z 4 → 18 | 4,4 m | terre, herbe, la table | 3,5 m, plat |
| Passage du Relais | x 50-62, z 6 → 18 (entre Relais et Comptoir) | 6 m (enseignes aux bords) | terre battue | 3,6 m |
| Cour de Joss | x 70-80, z 8 → 18 (entre Comptoir et Sellerie) | 10 m | terre, râteliers de selles | 3,6 m |
| Chemin du Clos | de (112 ; 21) à (130 ; 26), puis la digue | 4 m | pavés puis dalles | 3,4 → 2,5 |
| Digue | de (118 ; 46) en courbe à (132 ; 62), fanal au bout | 3 m | pierre | 1,6 m |

### 3.2 Les bâtiments (10 existants + 6 nouveaux)

| Bâtiment | Façade (x ; z) | Emprise | Qui / quoi | Modèle |
|---|---|---|---|---|
| Herboristerie Pervenche | (12 ; 16,6) | 6,9 × 6,6 | bocaux, herbes séchées au linteau ; **jardin de simples** derrière (x 4-16, z 6-14 : carrés surélevés, murets) | existe |
| Mercerie « Au Fil d'Ambre » | (27 ; 16,6) | 6,3 × 5,4 | Rosalie ; manteaux de duvet pendus à la fenêtre ; cour à linge derrière | existe |
| Relais des Dresseurs | (45 ; 16,6) | 7,8 × 8,2 | le tableau des rangs ; **cloche et manivelle au pignon** (les « machines » de Granit) ; **enclos du Relais** derrière (x 40-62, z 6-14) | existe |
| Comptoir d'Ambre | (66 ; 16,6) | 8,4 × 7,7 | Ferréol ; vitrine, coffre, Anurognathus ; fenêtre allumée la nuit | existe |
| Sellerie Joss | (84 ; 16,6) | 6,7 × 6,4 | selles aux râteliers de la cour, un mannequin de dino sellé | existe |
| havre_maison_1 | (99 ; 16,6) | 7 × 6,1 | la marchande | existe |
| havre_maison_2 / _3 | (12 ; 34,6) / (27 ; 34,6) | 5,6 × 5,6 / 7 × 6,1 | le pêcheur ; une famille de dresseurs | existe |
| **maison_5** (nouveau) | (37 ; 34,6) | 6 × 6 | ferme le côté ouest de la place sur la rue basse | à modeler |
| havre_maison_4 | (80 ; 34,6) | 6,7 × 5,9 | Gaspard y loge (porte ouverte, un protocératops attaché) | existe |
| Entrepôt du Comptoir | (97 ; 34,6) | 10,1 × 5,5 | porte double au sud ; caisses, bâche, **la grue** devant sur le quai | existe |
| **Clos des Dresseurs** : maisons 6, 7, 8 (nouveau) | (118 ; 16,6) (128 ; 16,6) (124 ; 36) | 6 × 6 chacune, 3 dessins | Lilou (maison 7), deux familles ; linge, selles au mur | à modeler |
| **enclos à dinos** (nouveau, clôture `cloture` existante) | x 114-130, z 24-34 | 16 × 10 | abreuvoir, râtelier, 3 dinos harnachés (voir § 4.3) | prop clôture + abreuvoir |
| **fanal de la digue** (nouveau) | (132 ; 62) | 2 × 2, 6 m | lanterne de pierre, repère de nuit | à modeler |
| **grue du Comptoir** (nouveau) | (99 ; 44), sur le quai à la racine du ponton | 4 × 4, 10 m | grue de bois à roue et manivelles, cloche ; charge une caisse (anim lente) | à modeler |
| **fontaine de la place** (nouveau) | (60 ; 27) | 3 m ∅ | eau claire, un petit dino de pierre ; bancs autour | à modeler |

### 3.3 Le quai et la place : vignettes

- **Place** : étal de fruits (50 ; 28,4), étal de poisson (61,6 ; 28,4), la marchande (55,2 ; 30)
  entre les deux, tonneau (55,8 ; 33,2), caisses (42,8 ; 31,2), bancs (46,8 ; 33,8) et (64,8 ; 33,8),
  bacs à fleurs (45,2 ; 25,2) (66,8 ; 25,2) ; Hamon au banc est ; parasols de toile sur les étals.
- **Quai ouest** (x 4-40) : la grande escale du Voyageur (x 2-18, z 36-48 dégagés), filet (16 ; 43,6),
  casiers (30 ; 43,6), le pêcheur (23,2 ; 42,8) au ponton ouest, barques (30 ; 48,4) (44 ; 49,2).
- **Quai du milieu** (x 40-76) : cordage (40 ; 44,6), Malcombe (49 ; 44,4), ancre (56 ; 43,6),
  séchoir (66 ; 43,2), barque (70 ; 48,6), caisses (76 ; 42,8).
- **Quai du Comptoir** (x 76-112) : les caisses marquées du Comptoir (88,4 ; 43,8) (89,2 ; 35,8)
  (102 ; 42,8), tonneaux, la grue (99 ; 44), le ponton (92-98 ; 46-60), barque (104 ; 49,6) ;
  **rien entre (88,6 ; 42,2) et (97 ; 40,8)** sauf les caisses de la cachette à l'ouest de Chloé.
- **Lanternes** (12, `OmniLight3D`, meta `lamp`) : rue haute x 20, 36, 56, 76, 92, 110 ; rue basse
  x 36, 72, 100 ; place (48 ; 26) (62 ; 35) ; Clos (120 ; 22).

### 3.4 Repères visibles de loin

| Repère | Où | Visible depuis | Annonce |
|---|---|---|---|
| La rangée des enseignes et des toits neufs (colorés) | rue haute | l'entrée ouest (toute la rue en enfilade) | les commerces (la caméra de Maïa) |
| Le Relais (le plus haut, 9 m, cloche au pignon) | (45 ; 13) | l'entrée, la place, le quai | « le Relais, là-haut » |
| La grue du Comptoir (10 m) | (99 ; 44) | l'entrée, toute la baie | l'entrepôt, le ponton de la nuit |
| La place et sa fontaine | (60 ; 27) | la rue haute, la rue basse | le marché |
| Le fanal de la digue | (132 ; 62) | partout la nuit | le bord est de la baie |
| Le Grand Voyageur | (9,6 ; 42,4) | la rue haute, le quai | l'escale |
| Les collines boisées (8-14 m) | z < 4 | partout | la limite nord, le dos de la ville |

## 4. Relief, végétation, faune

### 4.1 Relief (Terrain3D, jamais de marche)

| Lieu | Hauteur | Forme |
|---|---|---|
| mer | 0 (fond −3) | de z 46 au sud ; bande claire le long du quai ; le **mur de quai** (prop 1,4 m) |
| quai | 1,4 | dalle x 0-112 (et le Clos jusqu'à la digue) |
| rue basse | 2 | plate ; pente 15 % sur 4 m entre rue basse et quai → **adoucir en pente continue de z 36 à 46 (6 %)** : la rue basse à 2 m, le quai à 1,4 m |
| place | 3,2 → 2,2 | plan incliné 8 % nord-sud ; les étals et les bancs sur des assiettes plates |
| ruelles | 3,4 → 2 | rampes 12 % sur 12 m |
| rue haute | 3,4 | plate ; seuils des boutiques à 3,5 |
| jardins et cours | 3,5 → 4,5 | pente douce vers le nord, murets de pierre (props) entre les parcelles |
| lisière et collines | 5 → 14 | forêt dès z 4 (les fougères des Compsognathus), flancs 30° puis paroi roche à partir de 10 m ; crête du bord nord 14 m |
| bord ouest | 3,5 | la route côtière entre la colline (nord) et la pente vers le quai ouest (sud, herbe 15 %) |
| est : le Clos | 2,5-3,4 | terrasse douce ; au-delà de x 130 la colline est (10 m) ferme la baie |
| digue | 1,6 | pierre, 3 m de large, en courbe ; eau profonde des deux côtés |

### 4.2 Végétation praticable

- **Lisière nord** : forêt dense (canopée 3 / 100 m², troncs à 4 m, fougères géantes) au-delà de z 4 :
  **infranchissable visible** ; entre z 4 et 8, bois clair traversable (araucaria, fougères
  arborescentes) où les Compsognathus se faufilent.
- **Jardins** : simples de Pervenche (carrés, lavande-fougère, prêles), cour de Rosalie (linge),
  enclos du Relais (herbe rase, un arbre_rond), cour de Joss (terre, un figuier), potagers derrière
  les maisons de la rue basse ; murets de 0,8 m (on peut sauter : 0,65 m ? → **murets de 0,9 m**) ;
  portillons ouverts là où l'on doit passer.
- **Place et rues** : bacs à fleurs, deux platanes (arbre_rond) sur la place (48 ; 34) et (64 ; 25),
  lierre sur l'entrepôt, vigne sur la Sellerie ; le couvre-sol ne bloque jamais.
- **Quai** : rien de végétal, sauf des algues sur le mur et des oyats au pied de la digue.
- **Bord ouest sous la route** : pente d'herbe avec trois rochers et un vieux pin : ferme sans mur.

### 4.3 Faune (profil `port` de `wildlife_db.gd` aujourd'hui) et dinos de la ville

| Espèce (`KINDS`) | Nombre | Où elle se montre ici |
|---|---|---|
| `crabe` | 3 | sur les marches du quai et au pied de la digue |
| `poisson_saut` | 1 | entre les deux pontons |
| `ichthyornis` | 1 | au-dessus de l'étal de poisson et du ponton ouest |
| `ptero_vol` | 1 | haut, au-dessus des collines |
| effet `plancton` (60) | nuit | l'eau du port scintille |

**Proposition d'un profil `havre` distinct** (données, § 5) : `crabe` 3, `poisson_saut` 1,
`ichthyornis` 2, `papillon` 4 (jardins et bacs à fleurs), `fourmis` 2 (sous l'étal de fruits),
`mammifere` 1 (la nuit, dans la ruelle de Pervenche), `plancton`.

**Dinos de la ville** (acteurs décoratifs `DinoNpc`, sans dialogue, un cri quand on les touche) :
- les équipes des dresseurs **dans l'enclos du Relais** quand ils ne se battent pas : Protoceratops
  et Psittacosaurus de Gaspard, Dimorphodon (perché sur le râtelier), Parasaurolophus et
  Velociraptor de Lilou — tous **sellés ou harnachés** (variantes de peau avec cuir) ;
- le **porteur du Comptoir** : un Parasaurolophus adulte bâté de deux caisses, devant l'entrepôt le
  jour, dans l'enclos du Clos la nuit ;
- dans l'**enclos du Clos** : un Ankylosaurus de bât, un Tricératops sellé, un jeune Psittacosaurus ;
- les **deux Compsognathus** de la cuisine (scène, acteurs créés par `cuisine`) ; l'**Anurognathus**
  du coffre (ancre) ; **Bardane** la chèvre (ancre, après `brac_battu`) ;
- Caillou, Tricératops de Maïa à partir du ch. 3, à côté d'elle devant le Relais (à voir avec la
  logique de Maïa dans `havre.gd` : non prévu aujourd'hui).
Un dino ne se couche que pour dormir : la nuit, les dinos des enclos dorment couchés ; le jour ils
sont debout, en poses d'attente.

### 4.4 La vie des PNJ (existants ; horaires = proposition)

| PNJ | Jour | Soir | Nuit |
|---|---|---|---|
| Pervenche, Rosalie, Ferréol, Joss | devant leur porte (positions d'ancre) | idem, lanterne allumée | portes fermées, fenêtre du Comptoir allumée |
| Maïa | devant le Relais (49,2 ; 19,8) | idem | absente (chez Joss ?) : à voir avec l'histoire |
| Gaspard, Lilou | sur la rue devant le Relais | dans l'enclos avec leurs dinos (positions d'ancre gardées : ils y reviennent) | rentrés (maison 4, maison 7) |
| La marchande | entre ses étals (55,2 ; 30) | range les parasols | rentrée (maison 1) |
| Le pêcheur | au ponton ouest (23,2 ; 42,8) | banc du quai | « je répare mes filets » : reste, c'est lui qui voit les barques sans lanterne |
| Hamon, Malcombe | place / quai | idem | absents (le bateau du mardi les loge ailleurs) |
| nouveaux (proposés) : un gamin au Relais, une porteuse du Comptoir | place, quai | — | — |

Les horaires déplacent un PNJ **hors d'une scène** seulement : les ancres de § 1 sont les positions
de jour et les scènes (arrivée, nuit de la barque, cuisine) se jouent avec les positions d'ancre.

## 5. Risques et points à trancher par Greg

1. **Cadre 136 × 72 m avec le Clos des Dresseurs et la digue (recommandé) ou 112 × 64 m.** Dans les
   deux cas **toutes les ancres restent à Δ (0 ; 0)**. Le Clos donne les habitations et les dinos
   harnachés que le texte promet (« tout le monde a des dinos ») sans toucher au centre.
2. **Échelle des bâtiments ×2** comme la zone (maisons 6-8 m, entrepôt 10 m) : recommandé, même
   raison qu'à Port-Ambre (Chloé 1,5 m, portes `Doorway`).
3. **Profil faune `havre`** distinct de `port` (papillons, fourmis, mammifère la nuit) : recommandé ;
   c'est une entrée de `PLACES` et `ambience_id = &"havre"` dans la zone (données + une ligne).
4. **Dinos harnachés décoratifs** (enclos du Relais, du Clos, le porteur) : recommandé ; demande des
   variantes de peau « avec selle / bât » sur les modèles 3D existants (protoceratops,
   psittacosaurus, parasaurolophus, velociraptor, dimorphodon, ankylosaurus, triceratops : tous dans
   `assets/models3d/dinos/`).
5. **La grue du Comptoir** (clin d'œil aux « machines à manivelles et sonnettes » de Granit) :
   recommandé comme repère du quai ; sinon un simple mât de charge.
6. **La place en pente douce (8 %, recommandé) ou en deux terrasses** reliées par une rampe centrale
   (plus de murets, plus de props, mais des étals bien à plat).
7. **Horaires des PNJ** (soir / nuit) : recommandé, sans toucher aux positions d'ancre ; Maïa et
   le pêcheur à voir avec l'agent histoire (Maïa dort « chez Joss » plus tard dans l'histoire).
8. **Risque Doorway** : les boutiques, le Comptoir et l'entrepôt ont besoin de portes 3D qui
   s'ouvrent (`Doorway.shop_in/out`, `npc_out/in`) ; le 3D ne porte pas encore les portes. À
   prévoir avant la construction, comme pour le Cabinet.
9. **Risque de la nuit de la barque** : la barque est posée par `cote_stage.prop("barque")` en
   pixels, la caméra regarde (95,6 ; 49) ; en 3D il faut que la nappe de mer soit à 0 là et que le
   ponton du Comptoir n'ait pas de garde-corps à l'ouest (Isaure « descend » de la barque).
10. **Taille des pontons** : 6 × 12 et 6 × 14 m (×2) ; un ponton de pêche de 6 m de large est large
    mais sert au Voyageur voisin et aux barques : garder.

## 5 bis. Décisions (carte blanche de Greg, 05/10)

Greg a laissé carte blanche : toutes les recommandations du § 5 sont retenues. Le plan ci-dessus
est donc le plan à construire.

| Point | Décision |
|---|---|
| 1. Cadre | **136 × 72 m** avec le Clos des Dresseurs et la digue ; **toutes les ancres à Δ (0 ; 0)** |
| 2. Échelle des bâtiments | **×2** comme la zone (boutiques 6-8 m, entrepôt 10 m) |
| 3. Faune | **profil `havre` distinct** : crabe 3, poisson_saut 1, ichthyornis 2, papillon 4, fourmis 2, mammifère 1 (nuit), plancton ; `ambience_id = &"havre"` |
| 4. Dinos harnachés décoratifs | **oui** : enclos du Relais, enclos du Clos, porteur du Comptoir ; variantes « sellé / bâté » des 7 modèles 3D cités |
| 5. Grue du Comptoir | **oui**, repère du quai (10 m, roue, manivelles, cloche, charge lente) |
| 6. Place | **pente douce 8 %** (3,2 → 2,2 m), étals et bancs sur assiettes plates |
| 7. Horaires des PNJ | **oui** (jour / soir / nuit, § 4.4) sans toucher aux positions d'ancre ; Maïa et le pêcheur réglés par l'agent histoire |
| 8. Portes 3D (`Doorway`) | **PRÉREQUIS DE CONSTRUCTION** : les 3 boutiques, le Comptoir et l'entrepôt doivent avoir des portes 3D qui s'ouvrent (`shop_in/out`, `npc_out/in`) avant de bâtir la ville ; même chantier que le Cabinet de Port-Ambre. |
| 9. Nuit de la barque | **mer à 0 au flanc ouest du ponton du Comptoir, pas de garde-corps** ; la barque de scène posée à (88,6 ; 55,6) |
| 10. Pontons | **6 × 12 et 6 × 14 m** gardés |

## 6. Vue de dessus proposée (1 caractère = 4 m ; approximatif ; x 0-136 → colonnes, z 0-72 → lignes)

```
      x: 0   8   16  24  32  40  48  56  64  72  80  88  96  104 112 120 128 136
z  0    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   forêt dense, collines 8-14 m
z  4    ^^^^^^^^^c^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   c = d'où viennent les Compsognathus
z  8    .jjj.|t.ll.....eeeeee.....oooo.........................|........   j jardin de simples ; | t ruelle + table ; ll linge
z 12    .jjj.|..ll.....eeeeee.....oooo........................ |........   eeeeee enclos du Relais ; oooo cour de Joss
z 16    .#HE#.|.#ME#...##REL##..##COM##..#SEL#.#M1#..........#M6#.#M7#.   HE herboristerie, ME mercerie, REL Relais, COM Comptoir (coffre à x 62)
z 20    ====b=================G==L==================================b===   rue haute 3,4 m ; b = Bardane ; G Gaspard, L Lilou ; Maïa x 49
z 24    ..==.................PPPPPP..........................==.....====   == ruelles (rampes) ; P place (étals x 50 et 62, fontaine x 60)
z 28    ..==.................PPPPPP..........................==..EEEEEEEE   E enclos du Clos (dinos harnachés)
z 32    ..==.................PPPPHP..........................==..EEEEEEEE   H Hamon (68 ; 33), bancs x 47 et 65
z 36    .#M2#..#M3#..#M5#....PPPPPP........#M4#.##ENTREPOT##.==.....#M8#   rue basse 2 m ; ENTREPOT porte au sud (97 ; 36,6)
z 40    ==================================================================   rue basse / haut du quai
z 44    VVVVV.f.p..k....r..M..a....s....c....c..k.gG.ccc..........DD...   V Voyageur ; p pêcheur ; M Malcombe (49) ; k caisses (88) ; gG grue (99)
z 48    ~~~~~bPPP~~~~b~~~~~~~~~~~~~~b~~~~~~~~~~~~~~~bPPP~~~b~~~~~~~~~DD~~   P pontons (20-26 et 92-98) ; b barques ; barque d'Isaure à (88,6 ; 55,6)
z 52    ~~~~~~PPP~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~PPP~~~~~~~~~~~~~DD~   Isaure débarque à (95 ; 54,4)
z 56    ~~~~~~PPP~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~PPP~~~~~~~~~~~~~~DD   D digue (1,6 m), fanal au bout (132 ; 62)
z 60-72 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~PPP~~~~~~~~~~~~~~~F   mer (0), fond −3
```

Coordonnées clés (m) : entrée (0 ; 18-24), `DepuisPort` (3,6 ; 21), `Depart` (6 ; 21) · Pervenche
(12 ; 19), table (19,5 ; 9,8), déclencheur (19,5 ; 13,2), chèvre (19,6 ; 22,6) · Rosalie (27 ; 19) ·
Gaspard (39,2 ; 22,4), Maïa (49,2 ; 19,8), Lilou (52,8 ; 22,4) · coffre (62,4 ; 18), Ferréol (66 ;
19,2) · Joss (84 ; 19,2) · marchande (55,2 ; 30), Hamon (68,4 ; 33,2), Malcombe (49 ; 44,4) ·
pêcheur (23,2 ; 42,8) · Voyageur (9,6 ; 42,4), arrivée (14,8 ; 41,2), escale (6 ; 44,8) · entrepôt
(97 ; 34,6), porte (97 ; 36,6), cachette (88,6 ; 42,2), caisses (88,4 ; 43,8), ponton (92-98 ; 46-60),
barque de nuit (88,6 ; 55,6), débarquement (95 ; 54,4) · grue (99 ; 44) · Clos (112-136 ; 12-40),
enclos (114-130 ; 24-34) · digue (118 ; 46) → (132 ; 62).

## 7. Ce que je demande aux agents suivants

- **Relief** : les terrasses (3,4 / 3,2→2,2 / 2 / 1,4 / 0) et les deux ruelles-rampes ; la lisière et
  les collines du nord (paroi roche > 10 m) ; la colline est ; raccord ouest à 3,5 m (z 18-24).
- **Modélisation** (bâtiments assemblés, `maisons.py`, dessins distincts) : maison_5, maisons 6-8 du
  Clos, fanal, grue du Comptoir (anim lente), fontaine, mur de quai, murets de jardin 0,9 m,
  abreuvoir, râtelier de selles, parasols d'étal ; variantes « sellé / bâté » des 7 dinos cités.
- **Décor** : les 12 lanternes (meta `lamp`) ; les caisses du Comptoir marquées ; la cachette de la
  nuit exactement à (88,4 ; 43,8) ; la place dégagée pour le Voyageur (x 2-18, z 36-48) ; les
  fougères au bout de la ruelle de Pervenche.
- **Histoire / gameplay** : porter `Doorway` en 3D (boutiques, Comptoir, entrepôt) ; profil faune
  `havre` ; horaires des PNJ ; dinos décoratifs des enclos ; vérifier la caméra de l'arrivée (les
  trois façades depuis (3,6 ; 21)) et celle de la nuit (le bout du ponton depuis la cachette).
