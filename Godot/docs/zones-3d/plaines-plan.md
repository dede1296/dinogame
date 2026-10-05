# Prairie du Grand Crâne — plan de remodelage 3D

> Zone 1 (`plaines`), version PC 3D sous Godot (Terrain3D). Plan à valider par Greg sur l'image
> `plaines-plan.png` (vue de dessus) et `plaines-plan-relief.png` (relief seul). Les données sont dans
> `plaines-layout.json` (format décrit dans `../conception-zones-3d.md`), les ancres de l'histoire
> dans `plaines-ancres.json` et `plaines-audit.md` (audit du 04/10). Vérification automatique :
> `plaines-verification.txt` (atteignabilité, temps, pentes), produite par `plaines-plan-outil.py`.
>
> **Repère** : mètres dans la zone 3D (`ZoneSource`) : origine au coin **nord-ouest**, **x vers
> l'est** (0 → 240), **z vers le sud** (0 → 180), **y = hauteur** au-dessus de la mer (0). Une case
> du 2,5D (tx, ty) est à (2·tx, 2·ty).

## 1. Le parti : « l'amphithéâtre du Crâne »

Dix lignes :

1. La Prairie est une **cuvette douce** (3 m) cernée de hauteurs : la colline de la Grotte au nord
   (9,5 m), le **rempart d'ambre** des Falaises au nord-est (10 m), les Monts à l'est (26 m et plus),
   le Seuil du Port au sud (5,8 m), la crique en bas à l'ouest (mer à 0).
2. **Au cœur de la cuvette, le Grand Crâne** sur son tertre (10 m) : un vrai modèle 3D de 16 m de large,
   visible de partout, face au sud, au-dessus de l'Étang des Chanteurs. Il quitte son coin sud-est
   du 2,5D pour devenir ce autour de quoi tout tourne (le groupe de scène entier le suit : antre,
   panneau, Alpha, Maïa, sorties).
3. **Le carrefour de Maïa** est à son pied sud-ouest (butte du panneau, 4 m) : de là, les trois
   routes des trois passages partent en étoile, chacune annoncée par un repère visible : l'Arbre
   d'Hélène (15 m) à l'ouest, la bouche noire dans le cirque de la colline au nord, l'encoche sombre
   de la gorge dans le rempart doré au nord-est.
4. **La révélation** : la route du port grimpe le Seuil entre deux rochers-portes, et tout se
   découvre d'un coup : l'étang qui brille, le Crâne au-dessus, le rempart au fond.
5. **L'eau raconte le lieu** : la source sort de sous le Crâne, au pied du parvis, remplit l'étang ;
   le ru s'en échappe, coupe la route du port à un gué de pierres et se jette dans la crique.
6. **Trois passages à distance égale** : tronc 60 m, rocher 45 m, porte d'ambre 83 m (par le corridor
   des Vertèbres, entre le tertre et le rempart). Le Crâne lui-même à 48 m.
7. **Chaque passage change de registre** : le chemin creux entre deux talus de ronces (bosquet), le
   cirque minéral et son écho (Grotte), la gorge, puis le vallon secret et les terrasses (Falaises).
8. **De la végétation où l'on se promène** : bois clairs traversables (Chipie, crique, sud-est), le
   bosquet d'Hélène fermé par une **haie visible** (ronces, blocs, troncs couchés) et non par une
   forêt-mur ; lisières denses seulement aux bords de la zone.
9. **Des récompenses au bout de chaque détour** : belvédère de la colline, la Pointe de la crique,
   la cascade des Monts, le poste d'Hélène, la clairière du bois du Sud-Est, les éboulis du sud.
10. **Le rythme** : ouvert (Seuil, carrefour, prairies) / resserré (gué, chemin creux, encoche, gorge,
    corridor) / surprise (clairière d'Hélène, vallon des Nids, le parvis au-dessus de l'étang).

### Ce qui est audacieux (à présenter à Greg)

- **Le Grand Crâne déplacé au centre-est** (de (208,124) à (172,100), −36 m / −24 m) avec tout son
  groupe de scène : il domine le hub au lieu d'être au fond d'un couloir. C'est le plus gros
  déplacement du plan.
- **L'étang déplacé sous le parvis** (de (158,96) à (134,123), −24 / +28) : les parasaurolophus
  chantent à la pleine lune sous le crâne ; la prairie d'Élise suit, sur la rive sud.
- **La source du Crâne et le ru** : une logique d'eau inventée (pas dans le 2,5D), qui demande le
  plugin Waterways (repli : deux nappes plates et un ressaut au gué).
- **Le tronc de Tranche rapproché de 18 m**, au bout d'un vrai chemin creux ; le bosquet reste où il est.
- **Le rempart percé 12 m plus au nord** et les terrasses resserrées (vallon z 24-58, poste à z 20).
- **Le Seuil du Port**, dos de terrain à 5,8 m qui cache la cuvette jusqu'à la révélation.

### Partis écartés

- **B « la crête-promenade »** : la route du port sur une crête, le carrefour sur une butte haute,
  les passages dans trois vallons. Rejeté : le Crâne devait être plus haut que le carrefour pour
  dominer (tertre de 14 m, trop raide), et les trois vallons cachaient les passages les uns aux
  autres : moins lisible.
- **C « les trois vallons »** : trois vallées radiales séparées par des éperons boisés. Rejeté :
  la zone devenait trois couloirs, la grande prairie ouverte du sud (protocératops, Élise) n'y
  trouvait plus sa place, et les herbes hautes de rencontre non plus.
- **Garder le Crâne dans son coin** (plan v1, ±3 m) : fait et vérifié, puis abandonné quand Greg a
  libéré les ancres : avec le Crâne à 110 m du carrefour, le hub n'avait pas de centre.

### Choix à trancher

1. **Le Crâne au centre (recommandé) ou dans son coin** (plan v1, déplacements ≤ 3 m) : le v1 reste
   reproductible (`plaines-layout-source.py`, groupe `G_crane` à Δ (0,0)).
2. **Le ru avec Waterways** (vrai courant qui descend, gué à pierres) **ou en repli** (deux nappes
   plates, un ressaut au gué).
3. **Taille** : 240 × 180 m conservés (raccords inchangés). Option **+20 m au nord** (240 × 200) pour
   des terrasses plus amples ; tout ce qui est au nord de z 80 glisserait de 20 m. Je recommande de
   garder 240 × 180 pour la première construction.

## 2. Circulation

### Les sentiers (`paths` du JSON)

| Sentier | Type | Largeur | Trajet | Pente maxi |
|---|---|---|---|---|
| route_port | principal | 3 m | port (120,180) → Portes du Seuil (120,163) → gué du ru (118,127) → butte du carrefour (111,101) | 12° |
| route_grotte | principal | 3 m | carrefour → encoche de la Grotte (116,52) | 5,5° |
| route_bosquet | principal | 3 m | carrefour → prairie du Voyageur → chemin creux (70,98)-(58,86) → tronc → clairière (33,57) | 9,7° |
| route_crane | principal | 3 m | carrefour → rive nord de l'étang → rampe des Vertèbres → arche (146,107) → parvis → crâne (172,104) | 5,8° |
| route_corridor | principal | 3 m | carrefour → corridor entre tertre et rempart → embouchure de la gorge (190,74) | 10° |
| sentier_gorge | sente | 2 m | gorge → porte d'ambre (190,64) → vallon → ravin → terrasses → poste (194,20) | 13,4° |
| sente_belvedere | sente | 1,8 m | encoche → Hauts du Col → rampe est → belvédère (128,29) | 12° |
| sente_est | sente | 1,8 m | la grande boucle : pied du rempart → éboulis → cascade → dos du tertre → bois du Sud-Est → Seuil | 12° |
| sente_crique | sente | 1,8 m | gué → le long du ru → feu et panneau de la crique → la Pointe | 7° |
| sente_foret | sente | 2 m | (70,98) → piste de la Forêt → sortie ouest (0,104) | 2,7° |
| sente_chipie, sente_sud, sente_dormeur, sente_rive_sud, sentier_vallon, sente_cascade, sente_eboulis | pistes | 1,2-1,5 m | voir le JSON | ≤ 9° |

Règles : sol raboté sous chaque sentier (profil lissé), **jamais de marche** ; aucun décor solide à
moins de 1,5 m du bord d'un sentier principal (1,2 m des sentes, 1 m des pistes) ; les sentiers
principaux sont en terre ocre, les sentes en herbe foulée.

### Temps de trajet (plus court chemin praticable, calculé sur la grille de 0,5 m)

Chloé marche à 1,6 m/s, court à 5 m/s.

| Trajet | Distance | Marche | Course |
|---|---|---|---|
| port → Maïa (carrefour) | 77 m | 48 s | 15 s |
| port → gué du ru | 47 m | 29 s | 9 s |
| carrefour → tronc de Tranche | 60 m | 38 s | 12 s |
| tronc → fragment d'ambre (clairière) | 38 m | 24 s | 8 s |
| carrefour → rocher de Charge | 45 m | 28 s | 9 s |
| carrefour → porte d'ambre | 83 m | 52 s | 17 s |
| porte d'ambre → poste d'observation | 46 m | 29 s | 9 s |
| carrefour → Grand Crâne (panneau) | 48 m | 30 s | 10 s |
| carrefour → nid de Chipie | 48 m | 30 s | 10 s |
| carrefour → belvédère | 77 m | 48 s | 15 s |
| carrefour → sortie Forêt | 112 m | 70 s | 22 s |
| gué → crique (panneau) | 65 m | 41 s | 13 s |
| carrefour → cascade des Monts | 122 m | 76 s | 24 s |
| Grand Crâne → port (retour) | 101 m | 63 s | 20 s |

Un passage complet (aller) : bosquet 63 s, Grotte 28 s (+ la grotte elle-même), Falaises 83 s en
marchant ; en courant 20 / 9 / 27 s. Le tour complet des trois passages et du Crâne, en courant,
tient en 3 minutes sans les scènes.

### Lisibilité : les repères (`landmarks`)

| Repère | Où | Visible depuis | Ce qu'il annonce |
|---|---|---|---|
| Le Grand Crâne (16 × 9 × 12 m) | (172,100), face au sud | le Seuil (60 m), le carrefour, l'étang, le belvédère, le poste, le corridor | le but |
| Le rempart d'ambre | z 56-66, x 156-240 | toute la cuvette | la porte d'ambre (encoche sombre à x 190) |
| La colline de la Grotte | (114,30), 9,5 m | le carrefour (70 m), le Seuil | le rocher et la bouche, au fond du cirque |
| L'Arbre d'Hélène (15 m) | (30,58) | le carrefour (90 m), le Seuil, le belvédère | le bosquet |
| Les Portes du Seuil | (120,163) | la route du port | la révélation |
| Les Vertèbres + l'arche des côtes | (126→150, 101→110) | le carrefour, l'étang | la montée au parvis |
| Le Grand Voyageur | (98.8,106) | la cuvette | le carrefour (repère vivant) |
| La Pointe | (48,141) | la plage | la crique |
| Le poste d'Hélène | (196,18), 14 m | le vallon ; de là-haut, toute la zone | la fin du passage 3 |

## 3. Les secteurs d'ambiance (`areas`)

Chaque secteur a sa lumière, son sol, sa végétation (densités en instances / 100 m², strates
canopée / sous-bois / couvre-sol) et ses props. En clair :

| Secteur | Ce qu'on y ressent | Canopée | Sous-bois | Couvre-sol |
|---|---|---|---|---|
| Le Bois du Port | l'ombre avant la lumière, la mer qu'on entend | 2,2 | 3 | 5 |
| Le Seuil du Port | la côte, deux rochers-portes, puis tout s'ouvre | 0,25 | 0,6 | 2 (fleurs jaunes) |
| La Vallée du Ru | clapotis, prêles, libellules, fougères arborescentes | 0,8 | 1,8 | 5 |
| Le Carrefour (calme) | ouvert, chaud, tout se voit | 0,15 | 0,3 | 1,5 |
| La Prairie du Grand Voyageur | herbe qui ondule, fleurs en dérives, le brachiosaure | 0,3 | 0,5 | 2,5 |
| Le Bois de Chipie | bois clair, on y entre partout, trucs brillants | 1,8 | 2,5 | 6 |
| Les Lisières | herbe courte, buissons isolés, raptors au crépuscule | 0,4 | 0,8 | 2 |
| L'Encoche de la Grotte (calme) | minéral, frais, l'écho | 0 | 0,6 | 6 (cailloux) |
| La Colline de la Grotte | roche et herbe rase, araucarias tordus, le belvédère | 0,5 | 0,7 | 3 |
| Les Hauts du Col (calme) | prairie haute et silencieuse, vent | 0,3 | 0,6 | 2 |
| L'Étang des Chanteurs (calme) | miroir d'eau sous le parvis, prêles, roseaux | 0,6 | 1,5 | 3 |
| La Prairie d'Élise (calme) | rase, en pleine lumière, rien ne cache la scène | 0 | 0 | 1 |
| La Rampe des Vertèbres | la colonne d'un géant sort de l'herbe | 0,2 | 0,5 | 2,5 (os) |
| Le Parvis du Grand Crâne (calme) | solennel, trois serrures qui luisent, le silence | 0 | 0,3 | 2 (os) |
| Le Tertre du Crâne | racines, roche, araucarias noueux, compsognathus | 0,6 | 1,2 | 3 |
| Le Corridor | allée d'herbe et de blocs, la paroi dorée à gauche | 0,3 | 0,6 | 3 |
| Les Éboulis de l'Est (calme) | pierriers, la cascade au nord, ankylosaures la nuit au sud | 0,3 | 0,5 | 5 |
| Les Prairies du Sud | la grande prairie, herbes hautes par nappes | 0,25 | 0,4 | 2 |
| Le Bois du Sud-Est | bois rond et sombre, clairière avec une trouée de soleil | 2,4 | 3 | 6 |
| La Crique | sable, bois flotté, la dent de mosasaure, un peu inquiétant | 0,3 | 0,6 (oyats) | 2,5 |
| Le Bois de la Crique | frais, fougères arborescentes, on traverse en diagonale | 1,8 | 2,2 | 6 |
| Le Chemin Creux | l'ombre tombe entre deux talus de ronces, puis le tronc | 1,2 | 6 (ronces) | 6 |
| Le Bosquet d'Hélène | jardin sauvage caché, lumière tamisée, fleurs partout | 1,6 | 2 | 8 (fleurs) |
| La Lisière de la Forêt | les fougères deviennent géantes, les troncs se rapprochent | 3 | 4 | 8 |
| Le Vallon des Nids | vallon secret derrière la porte, dimorphodons | 0,4 | 1 | 3 |
| Les Terrasses du Poste (calme) | deux marches vers le ciel, vent, nids, la vue | 0,3 | 0,5 | 2,5 |

Lumière : le soleil tourne (Sky3D) ; les secteurs sont pensés pour lui : le parvis et la face du
Crâne regardent le sud (éclairés toute la journée, dorés au coucher), la clairière d'Hélène est une
trouée dans la canopée (rayons au matin), le corridor est à l'ombre du rempart l'après-midi, le
rempart lui-même prend le coucher de soleil, les veines d'ambre luisent la nuit.

## 4. Le relief (Terrain3D)

Hauteurs en mètres au-dessus de la mer. **Jamais de marche de grille** : Terrain3D à 0,5 m, pentes
continues ; les parois sont des pentes > 50° peintes roche (strates) avec, sur les grandes faces,
des modules de paroi à veines d'ambre.

| Lieu | Hauteur | Forme | Accès |
|---|---|---|---|
| mer, crique | 0 (fond −3) | plage de sable en pente douce (9 m) | plage praticable ; eau profonde bloque |
| prairie | 3 (±0,55 d'ondulations, longueur d'onde 26 m) | cuvette très douce centrée sur l'étang (2,8) | partout |
| butte du carrefour | 4 | dôme de 11 × 9 m | partout |
| Seuil du Port | 5,8 | dos de terrain est-ouest (crête z 158-164), flancs à 8° | la route, les prairies |
| étang | eau 2,4, fond 0,8 | ellipse 23 × 14 m ; îlot à 2,9 ; gué à 2,3 (0,1 m d'eau) | rives partout ; îlot par le gué à la pleine lune |
| ru | suit le sol −0,5 | lit de 2,4 m, berges de 2,5 m | on y marche (0,3 m) |
| bosquet d'Hélène | 5 | dôme large (32 × 27 m) | par le chemin creux (talus de 1,8 m) |
| bois de Chipie, bois de la crique, bois du Sud-Est | 4 / 4 / 4,6 | dômes | partout |
| colline de la Grotte | 9,5 | dôme 27 × 19 m, flancs 30-35° ; **face sud en cirque** (paroi 2,5 m) | rampe est (14 %) vers le belvédère ; l'encoche (7 m de large, 3,6 m) percée dans la face sud |
| Hauts du Col | 5,5 | dôme entre la colline et l'éperon | la sente |
| rempart des Falaises | 10 (crête z 60 → 56) | arête de 6 m d'épaisseur, face sud de 7 m à 65-70° | **seulement par la gorge** (x 190, 5 m de large, 3 → 7 m, 9°) |
| éperon ouest | 10 | arête x 158, z 8-62 | non |
| vallon des Nids | 7 | plateau ondulé derrière le rempart (talus de 5 m) | la gorge |
| terrasse basse / poste | 10 / 14 | deux plateaux à parois de 2 m | ravins de 4 m et 3,5 m de large (14-16 %) |
| tertre du Crâne | 10 | plateau 44 × 24 m, flancs de 5 m (roche et racines, 54°) | **non** ; l'encoche (8 m) à 6,5 m au sud, le parvis |
| parvis | 6,5 | dalle plate de x 148 à 190, z 100-118, talus de 3 m vers l'étang | rampe des Vertèbres (3,2 → 6,5 sur 24 m, 8,5°) |
| Monts (est) | 3 → 26 | paroi à partir de x 227, éboulis au pied | éboulis praticables jusqu'à x 230 |
| montagnes (nord) | 10 → 36 | paroi au nord de z 12 | non |

Champ de hauteurs cible : `plaines-relief-cible.png` (16 bits, 0,5 m par pixel, 480 × 360,
valeur = (h + 10) × 1000) : l'agent relief peut l'importer tel quel dans Terrain3D comme point de
départ, puis sculpter à la main (ondulations, bords des plateaux, berges) sans changer les hauteurs
aux ancres ni les pentes des sentiers.

Contrôle : 74 % de la zone praticable, 11,9 % de parois, 6,8 % d'eau profonde ; 31 cellules de
sentier sur 8 916 tombent sur une pente > 42° (bords du gué et de la gorge, à lisser à la main).

## 5. La végétation

**Strates** : canopée (arbre_rond, araucaria, fougère arborescente, l'Arbre d'Hélène), sous-bois
(buisson, ronces, fougère arborescente jeune, prêle, roseaux, fougère géante), couvre-sol
(fougères, fleurs roses / violettes / **jaunes** (nouvelles), champignons, cailloux, os, coquillages).

**Praticable** : un bois « traversable » a ses troncs espacés de 6-8 m (canopée ≤ 2,4 / 100 m²), ses
buissons en bouquets jamais en rangée ; le couvre-sol ne bloque jamais. Les **herbes hautes**
(rencontres) restent les nappes du 2,5D, déplacées avec leurs secteurs, sans aucun décor solide.

**Infranchissable, et pourquoi on le voit** (`blockers`) :
- la **haie du bosquet d'Hélène** : anneau de ronces de 1,6 m, blocs et troncs couchés (3,5 m
  d'épaisseur) ; la seule ouverture (4,5 m) est le chemin creux, barré par le tronc de Tranche (5 m) ;
- les **talus du chemin creux** (1,8 m de terre et de ronces : plus haut que le saut, 0,65 m) ;
- les **lisières denses** du bord ouest (troncs à 4 m, troncs couchés, fougères géantes entre eux)
  et du bord sud hors du couloir de 20 m de la route ;
- l'**eau profonde** (bandes de profondeur lisibles), les **parois** (roche peinte).
Jamais de forêt-mur ni de mur invisible : si un endroit ne doit pas être franchi, on y met une haie,
une paroi, un tronc couché ou de l'eau que l'on voit.

**Sentiers et clairières** : les clairières (`clearings`, 22) sont les places des scènes et des
récompenses : rien de moyen ou de grand à l'intérieur hors les ancres ; les sentiers ont leur
dégagement (1,5 / 1,2 / 1 m).

## 6. Les props

**Hiérarchie** : repères (§ 2) → grands (arche des côtes, arche de pierre de la gorge, troncs
couchés de 8 et 12 m, rochers de 3 m, l'Arbre d'Hélène, les vertèbres) → moyens (souches, buissons,
rochers de 1 m, nids, bancs, feux, panneaux, pierres plates, bille de bois) → petits (cailloux,
fleurs, champignons, os, coquillages).

**Groupes** : un grand prop n'est jamais seul : un rocher de 3 m a ses cailloux, ses fougères et
une fleur ; un tronc couché a ses champignons et sa souche ; une vertèbre a ses os et son herbe rase.

**Vignettes composées** (27, numérotées sur l'image, détail dans le JSON) : l'arrivée du port (V01),
les Portes du Seuil (V02), le gué du ru (V03), la butte du carrefour (V04), le rocher-œuf (V05), la
course de Chipie (V06), l'encoche de la Grotte (V07), le belvédère (V08), la porte d'ambre (V09),
la source du Crâne (V10), le poste d'observation (V11), l'anse aux roseaux (V12), l'îlot et le gué
de lune (V13), la rive des chanteurs (V14), les Vertèbres (V15), l'arche des côtes (V16), le parvis
(V17), l'arbre du dormeur (V18), la crique (V19), la prairie d'Élise (V20), la lisière de la Forêt
(V21), les éboulis du sud (V22), le tronc de Tranche (V23), la clairière d'Hélène (V24), la
clairière du bois du Sud-Est (V25), la cascade des Monts (V26), le dos du tertre (V27).

**Zones calmes** : le carrefour (18 m, rien de plus haut qu'un buisson jusqu'à 24 m), le parvis,
l'encoche, l'étang, la prairie d'Élise, les Hauts du Col, les terrasses, les éboulis.

**Dégagement** : 1,5 m des sentiers principaux ; 6 m côté sud de chaque serrure (le compagnon doit
pouvoir agir) ; les couloirs de course de Chipie (4 m, au sud du bois de Chipie) et de Maïa
(26 m × 6 m, plats, sur le parvis) ; le rectangle d'Élise (16 × 20 m) sans rien, ni herbe haute ni
relief > 1 m à 10 m autour.

## 7. Les bords (open world)

| Bord | Voisine | Raccord | Ailleurs sur ce bord |
|---|---|---|---|
| sud (z 180) | Port-Ambre | la route, x 116-124, à 2,5 m, couloir libre de 20 m (x 110-130) entre les deux bois ; l'origine de Port-Ambre à x = 86 de la Prairie pour aligner les routes | bois du Port (haie), la crique (mer) à l'ouest de x 84 |
| ouest (x 0) | Forêt Jurassique | la piste, z 100-108 (mêmes lignes que la sortie est de la Forêt), à 3,5 m | lisière dense ; le sous-bois de la Forêt déborde de 12 m |
| nord (z 0) | — | — | montagnes (10 → 36 m) ; la Grotte des Échos est une zone intérieure (bouche à 116,46) |
| est (x 240) | Monts Gelés (plus tard) | — (pas de passage au ch. 1) | paroi des Monts (3 → 26 m), éboulis praticables, la cascade |

Le relief des bords est lisible de loin (fond de décor : futaie géante à l'ouest, sommets au
nord, Monts à l'est, mer au sud-ouest) : on voit la zone voisine avant d'y entrer, comme le veut
`histoire.md` § Géographie.

## 8. Les ancres de l'histoire : ce qui bouge, par groupe de scène

Toutes les ancres de l'audit sont présentes ; elles bougent par **translation pure de groupe**
(jamais de rotation : l'histoire utilise des directions absolues, voir audit § 3.2). Le JSON donne
pour chaque ancre `old` (2,5D × 2) et `new`, et pour chaque groupe son Δ : c'est l'entrée du champ
de déformation des scènes.

| Groupe (audit) | Δ (m) | Ce qui bouge | Pourquoi |
|---|---|---|---|
| G_crane (crane_cour) | **(−36, −24)** | crâne (172,100), antre (172,92), panneau (164.8,105.6), Alpha (178.4,103.6), MaiaDefi (165.6,106.4), MAIA_FROM (150,107), spawns, sortie | le Crâne au cœur de la cuvette |
| G_etang / G_etang_ilot (etang_gue) | **(−24, +28)** | étang, îlot, gué (élargi à 6 × 6 m), page 2, chanteurs, banc, panneau, peau muée, prêles | l'étang sous le parvis ; « Est : l'étang, puis le Grand Crâne » |
| G_elise (elise) | (−27, +22) | Tricératops (137,130.8), pile, Élise (131.2,134.6), rectangle vide | toujours sur la rive sud, hors du Seuil et des herbes hautes |
| G_carrefour (carrefour_maia + voyageur) | (−8, +8) | Maïa (117.2,96.8), panneau (106.8,97.6), feu, escale, Grand Voyageur (98.8,106) | le hub au pied de la rampe |
| G_chipie (poursuite_chipie) | (−8, +8) | la course et le nid (73.2,76.2), CHIPIE_HIDE | elle part de Maïa |
| G_tronc (bosquet_tronc, le tronc) | (+18, +4,2) | le tronc (58,86) | au bout du chemin creux, passage 1 plus court |
| G_porte (falaises_porte) | (+4, −12) | la porte (190,64), spawn Falaises | la gorge perce le rempart plus au nord |
| G_poste (poste_observation) | (0, −4) | banc, panneau, page 3, écaille, table, feu, nids | terrasses resserrées |
| G_oeuf | (−4, +4,8) | rocher-œuf (126,84) et panneau | dégagé de la route du corridor |
| G_bosquet, G_grotte, G_dormeur, G_crique, G_port, G_foret | (0, 0) | inchangés | raccords et scènes déjà bien placés |

Les constantes en pixels de `story/plaines.gd` (`ALPHA_SPOT`, `DEN`, `MOUTH`, `OUT_OF_NOTCH`,
`MAIA_FROM`), de `story/plaines_annexes.gd` (`CHIPIE_HIDE`) et de `tools/zones/plaines.gd`
(`CHIPIE_PATH`, `ELISE_*`) ont leurs nouvelles valeurs (cases et mètres) dans
`plaines-layout.json` → `hardcoded_constants`.

Les habitats (`dex_places.gd`) suivent les lieux (`anchors[habitats].new_rects`) ; les 13 rectangles
`KEEP_CLEAR` du 2,5D sont remplacés par les `clearings` du JSON.

## 9. Autocritique (passe 4) : ce que la simulation a changé

Simulation d'un joueur qui arrive par le port sans connaître la zone, puis fait les trois passages
et ressort, sur le plan v1 (ancres fixes) puis v2 (ancres libres) :

- **v1** : le Crâne était au bout d'un couloir de 110 m depuis le carrefour, le bosquet à 100 m, la
  Grotte à 39 m : déséquilibré, et le hub n'avait pas de centre visible. La BFS a trouvé que ma
  première lisière dense coupait la sortie vers la Forêt, que le crâne ne bloquait pas l'antre,
  que la route de l'étang longeait la face du rempart (marche de 1,4 m), que trois sentes
  dépassaient 20° (rive de l'étang dans le fondu de l'étang, sente du ru sur sa berge, pied des
  Monts sur le gradient de 55°) : corrigé. L'îlot a demandé quatre essais (îlot trop large qui
  touchait la rive, gué trop étroit après érosion, marche de 44° entre le gué et l'îlot).
- **v2** (ancres libres) : le couloir de course de Maïa (26 m) tombait sur la rampe (1 m de relief) :
  le parvis a été étendu à x 148 pour qu'il soit plat. La prairie d'Élise était sur le flanc du
  Seuil et son banc du dormeur dans le rectangle vide : le Seuil est descendu de 7 m vers le sud
  (crête z 163) et le groupe d'Élise a glissé de 3 m. Le couloir d'arrivée du port était de 8 m :
  élargi à 20 m comme le demande l'audit. Le rayon dégagé du carrefour est passé de 14 à 18 m (+
  couronne basse jusqu'à 24 m).
- **Vérification finale** (`plaines-verification.txt`) : les 85 ancres (70 entrées, certaines
  groupées) sont **toutes atteignables** depuis le port avec les passages ouverts, et **aucune
  ancre d'au-delà d'un passage n'est atteignable avant** (bosquet, grotte, vallon, poste, antre,
  îlot) ; largeur de passage ≥ 1,2 m partout (érosion 3 × 3 à 0,5 m) ; tous les sentiers sous leur
  pente maxi.
- **Où le joueur pourrait hésiter** : au carrefour, cinq routes partent (port, bosquet, Grotte,
  corridor, Crâne) ; le panneau et les repères les distinguent, mais la **route du corridor et la
  rampe des Vertèbres partent toutes deux vers l'est** : la rampe est bordée d'os (on comprend
  qu'elle mène au crâne), le corridor s'ouvre entre le tertre et le rempart avec la porte visible
  au bout. À surveiller en jeu.
- **Culs-de-sac** : tous récompensés (belvédère, Pointe, cascade, éboulis du sud, poste, clairière
  du Sud-Est, nid de Chipie, îlot). Le Vallon des Nids est un cul-de-sac derrière la porte : il
  contient le poste, deux nappes d'herbes hautes, les dimorphodons et un galet.

## 10. Budget (GTX 1650 Ti, Forward+, > 90 im/s)

11 ms par image. Instances : ~1 300 arbres, 900 buissons / ronces / fougères arborescentes, 5 000
couvre-sol, 320 rochers, 40 os, 90 props moyens. Triangles : arbre 2 500 (LOD2 600), buisson 900,
rocher de 3 m 1 200, vertèbre 800, arche des côtes 3 000, Grand Crâne 25 000 ; cible < 2,5 M
triangles dans le champ, < 700 draw calls (MultiMesh par sorte et par carré de 32 m, LOD générés) ;
couvre-sol invisible au-delà de 90 m, buissons 140 m, arbres 240 m avec fondu ; ombres portées
seulement pour arbres, rochers, os, crâne ; Terrain3D à 0,5 m, 8 textures au plus ; eau en miroir
0,3 × une image sur deux (réglage actuel). Mesure du 04/10 : la Prairie actuelle tourne à 130-230
im/s selon l'heure avec 4 100 instances de décor ; le plan en ajoute ~60 % mais les range plus près
du sol et en LOD : à mesurer dès la première construction.

## 11. Nouveaux props à modéliser (`new_props`, dimensions L × H × P en m, priorité)

1. **Le Grand Crâne** 16 × 9 × 12, ~25 000 tris : crâne fossile de cératopsien géant, collerette
   en mur du fond, bec, orbites de 2 m, trois serrures d'ambre (0,6 m) sur le front, gueule ouverte
   = passage vers l'antre (3,6 × 3,2 m) scellé d'ambre translucide avant `crane_ouvert` ; os ivoire
   veiné, mousse et lichen, un petit arbre sur la collerette.
2. **Vertèbre géante** 3 × 2,5 × 2,2 (3 variantes) ; **côte géante** 7-9 m (2) ; **l'arche des côtes**
   7 × 5 × 1,2 (portée libre 6 m, collision sur les pieds seulement) ; **fémur géant** 5 m ; petits os (3).
3. **Rochers** : 3 m (3 variantes), **rocher de Charge** (3 m, fissuré), **rocher-œuf** (1,6 × 2 m,
   lisse), pierre plate à s'asseoir, éboulis (2), **arche de pierre** 9 × 7 au-dessus de la gorge,
   **modules de paroi à veines d'ambre** 6 × 6 (3, émissifs).
4. **La porte d'ambre** 5 × 4 (translucide, fougère gravée, s'illumine) ; **bouche de grotte** 3 × 2,8.
5. **Le tronc de Tranche** 5 × 1,1 (+ version tranchée en deux) ; **troncs couchés** 8 et 12 m ;
   **haie de ronces** 3 × 1,6 (module dense, 2 variantes) ; **l'Arbre d'Hélène** 10 × 15 ; souche-banc ;
   pierre moussue ; fougère géante 3 × 2,5 ; souche géante ; buisson sec.
6. **Fleurs jaunes** ; **tapis de fleurs** 2 × 2 (nappe pas chère) ; roseaux ; nénuphars ; bille de
   bois coulée ; bois flotté (2) ; peau muée ; tas de crottes ; cristaux d'ambre (émissifs).
7. **Panneau** 3D (+ planche plantée de l'escale), **banc**, **feu de camp** (flamme + lumière), table
   du poste, longue-vue sur pied, nid de dimorphodon, buisson-nid de Chipie, la source (bassin de
   roche), pont de rondins 4 × 1,6, pierres de gué.

Tous en style cartoon commun (`toon.gdshader`, contour brun), origine au pied, +Z devant.

## 12. Ce que je demande aux agents suivants

- **Relief** : importer `plaines-relief-cible.png` dans Terrain3D (0,5 m, (h + 10) × 1000), puis
  sculpter : ondulations naturelles, bords des plateaux cassés (wobble), berges, aucune marche ;
  respecter les hauteurs aux ancres (`anchors[].new` + `height` du contrôle) et les pentes des
  sentiers (`paths[].grade_max_deg`) ; peindre roche sur les pentes > 50°, terre sur les sentiers
  principaux, sable sur la plage et les rives, sous-bois dans les bois et la lisière ouest, herbe
  sèche dorée sur la rampe et le parvis. Ouvrir/fermer la boîte d'eau du gué avec `MoonFord`
  (audit R5) : à prévoir dans `Blockers3D`.
- **Eau** : l'étang (nappe à 2,4), la mer (0), le ru avec Waterways (ou le repli), la source, la
  cascade (particules + son).
- **Végétation** : semer par secteur avec les densités du JSON (`areas[].vegetation`), hors
  `clearings`, hors herbes hautes, hors sentiers (+ dégagement), en bouquets ; planter les haies et
  lisières denses comme des objets solides visibles ; un arbre aux 8 points `galets_arbres`.
- **Décor** : poser les 27 vignettes, les repères et les groupes de props ; respecter la
  hiérarchie et les zones calmes ; les ancres aux positions `new`.
- **Modélisation** : la liste § 11, dans l'ordre des priorités (1 = le Grand Crâne, les os, les
  rochers, la porte, le tronc, les haies, l'Arbre d'Hélène, le panneau, le banc, le feu).
- **Histoire / gameplay** : passer les scènes par le champ de déformation (`scene_groups`,
  `anchors[].old → new`), recalculer les constantes de `hardcoded_constants`, déplacer les habitats
  (`anchors[habitats].new_rects`), vérifier le texte du panneau du carrefour.
