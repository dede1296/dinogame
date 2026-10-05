# Migration 2,5D → 3D native (Godot 4.7)

Document vivant. Créé le 2026-10-04 après l'audit de la Phase 0. Règle absolue : le jeu 2,5D existant
reste la source de vérité du gameplay ; il continue de tourner pendant toute la migration.

**Trois versions coexistent** (décision de Greg, 04/10) :
- **2,5D mobile** (ce projet, Android) : le modèle de base. Il n'est ni transformé ni cassé.
- **3D PC sous Godot** : ce document. Code additif dans `world3d/`, qui réutilise le gameplay et les
  données du 2,5D.
- **3D PC sous Unreal 5.8** (`Unreal/`, chantier parallèle) : il part lui aussi du 2,5D.
  Les deux versions 3D ciblent le **PC** (clavier/souris et manette d'abord ; le tactile reste
  possible mais n'est pas prioritaire ; le web a été retiré). Machine de référence : GTX 1650 Ti.

## 1. Point de départ réel (audit)

Le jeu est déjà **à moitié 3D côté rendu** : `world/view3d/WorldView` (2 197 lignes) affiche le sol en
relief, l'eau, les quais, la lumière, le ciel, la météo, la forêt en MultiMesh et une `Camera3D`
(`CameraRig`). **Mais la simulation est 2D** : `Player` est un `CharacterBody2D`, les dinos des
`CharacterBody2D`, les zones des `Region` (Node2D + TileMapLayer), tout en pixels (48 px = 1 case =
1 m), et `WorldView` *recopie* chaque frame les nœuds 2D vers des `Sprite3D` billboard.

Conséquence heureuse : **1 case = 1 m et le relief est déjà en mètres**. La conversion pixel → mètre est
`px / 48` (`HeightMap.to_3d`), le terrain 3D existe déjà, et la hauteur est déjà échantillonnée.

## 2. Mécaniques : ce qui existe vraiment

Existe : stats par parties (6) et de combat (4), niveaux 1-50, XP, attaques apprises, lien (cœurs),
équipe de 5 + réserve, œuf, Dinodex, une monnaie (« pièce ») + objets, horloge/jours/lune/météo,
brouillard d'exploration, capacités d'exploration par famille, combat au tour par tour, capture,
sauvegarde JSON, ~719 drapeaux d'histoire, 48 espèces (`.tres`).

**N'existe PAS dans le code** (décrit au mieux dans `mecaniques.md`) : métabolisme/faim, population,
évolution, croissance juvénile → adulte, reproduction, arbre de compétences, artisanat, simulation
d'écosystème, IA de dinos au-delà d'une errance. Ce sont des **créations**, pas des migrations.
(Voir aussi `Unreal/docs/phase1/00-synthese.md`, même constat.)

## 3. Tableau de migration

Statuts : ☐ à faire · ◐ en cours · ☑ fait.

| Système existant | Équivalent 3D | Modification nécessaire | Verdict | Statut |
|---|---|---|---|---|
| `game/dino.gd`, `BattleEngine`, `UnderwaterEngine` (RefCounted) | identiques | aucune | CONSERVER | ☑ |
| `core/` Game, Save, Audio, Router, Quality | identiques | `player_position` Vector2 px → Vector3 m (+ lecture ancienne sauvegarde) | CONSERVER + 1 champ | ☐ |
| `data/*_db`, dialogues, objectifs, lieux, MovesDB, ItemsDB | identiques | aucune | CONSERVER | ☑ |
| `DinoSpecies` + 48 `.tres` | idem | ajouter `model: PackedScene`, régime, biomes, taille/masse m/kg, anims, évolution ; garder stats et sprites (combat) | ÉTENDRE | ☐ |
| `BattleScene`/`BattleHud` (CanvasLayer 2D) | idem en overlay | aucune au début (option : modèles 3D plus tard) | CONSERVER | ☑ |
| `ui/` (Control) | idem | `dialogue.gd`, `quest_tracker`, `party_bar` : accès joueur via interface, pas `global_position` | ADAPTER (3 fichiers) | ☐ |
| `Region` + TileMap + générateurs `tools/zones` | `Zone3D` lue **depuis les mêmes données** (relief, tuiles, props, habitats, sorties) | nouveau chargeur ; les zones 2D ne sont pas modifiées | ADAPTER (lecteur) | ☐ |
| Relief/`HeightMap`, sol, eau, ciel (WorldView) | déjà 3D | extraire en briques réutilisables hors du miroir | RÉUTILISER | ☐ |
| `Player` CharacterBody2D + planche chloe.png | `Player3D` CharacterBody3D + modèle riggé | faits : corps, gravité, marche/course (vitesses du 2,5D), marches ≤ 35 cm, saut, interaction, modèle riggé et animations ; reste : monture, nage, plongée, tenues (manteau), pas sonores | RÉÉCRIRE | ◐ |
| Caméra (`CameraRig`, pitch 40°) | pivot 3e personne orbitale | fait : `CameraPivot` + SpringArm3D (orbite, zoom mémorisé, collision) ; reste : `shake`, `close_up`, fondu de Chloé quand la caméra est trop près | RÉÉCRIRE | ◐ |
| `WildDino`, `Habitat`, `FleeingDino`, `Companion` | `Dinosaur3D` générique (données + états) | fait : `Dinosaur3D` + `Species3D` + `DinoBrain` (repos, promenade, regard, fuite), navigation ; reste : brouter, dormir, chasser, compagnon, spawn par habitat (phase 6) | RÉÉCRIRE | ◐ |
| `Npc`/`DinoNpc` (StaticBody2D, `walk_to`) | `Npc3D` | même API (`walk_to`, `face`, poses) | RÉÉCRIRE | ☐ |
| `Stage` (~40 gestes sur sprites 2D) | `Stage` même API sur acteurs 3D | garder les noms ; réimplanter sur `Vector3`/animations ; conversion px→m pour les scènes existantes | ADAPTER | ☐ |
| `story/` ~20 k lignes de chorégraphies (2 483 appels Stage/CS/Act, px) | idem | **gros risque** : passer par la couche de conversion plutôt que réécrire | ADAPTER (progressif) | ☐ |
| Sorties de zone, déclencheurs, ramassages (Area2D) | `Area3D` | masques de collision reprise 1:1 | RÉÉCRIRE (petit) | ☐ |
| Nage / plongée / monture / selle | idem 3D | poses ancrées sur sprites → os/sockets | RÉÉCRIRE | ☐ |
| Modèles : 39 `.glb` bâtiments | déjà 3D | exclus de l'APK (poids) | CONSERVER | ☑ |
| Personnages/dinos : planches de sprites | modèles `.glb` riggés | **pipeline d'assets complet** | CRÉER | ☐ |
| Métabolisme, population, évolution, croissance | `Dinosaur3D` composants | à concevoir ; l'existant n'a rien | CRÉER | ☐ |

## 4. Architecture cible

Principe : **GAMEPLAY / DATA / PRESENTATION** séparés, et la 3D est ajoutée **à côté** de la 2,5D.

```
Godot/
  core/ game/ data/ battle/ ui/      ← inchangés (gameplay + données + UI)
  world3d/                            ← NOUVEAU : tout le rendu/physique 3D natif
    zone3d/        ZoneLoader (Region → terrain, collisions, props, habitats, sorties en 3D)
    player/        Player3D (CharacterBody3D) + CameraPivot/SpringArm3D/Camera3D
    creatures/     Dinosaur3D + composants : Stats, Growth, Metabolism, Evolution,
                   Brain (états), Animation, Population
    stage3d/       implémentation 3D de l'API Stage
    biomes/        BiomeData (.tres) : végétation, lumière, climat, espèces, sons, POI
  data/species/    .tres existants + champs 3D ajoutés
  scenes/world3d_demo.tscn            ← zone de démonstration
```

Une espèce = un `DinoSpecies.tres` : modèle `.glb`, table d'animations (clés génériques `idle/walk/run/
attack/sleep/eat` → noms du clip), taille, masse, vitesse, régime, biomes, rareté, évolution. **Zéro code
par espèce.** Les dinos hors caméra passent en simulation « légère » (position abstraite, pas de physique ni
d'animation) — budget GTX 1650 Ti.

## 5. Risques

1. **Assets** (le plus grand). 48 espèces + Chloé + PNJ n'existent qu'en sprites. 30+ dinos riggés/animés
   sous licence compatible : l'offre libre est faible. Pistes : Quaternius, Kenney, Poly Haven, Sketchfab
   (CC0/CC-BY, attribution tracée), Fab ; génération via Blender si besoin. Chaque asset est enregistré avec sa
   licence dans `docs/licences-assets.md`. Étape de repli : placeholder cohérent (capsule/mesh simple) par espèce.
2. **`story/` en pixels** : ne pas réécrire. API `Stage` conservée, conversion px→m centralisée.
3. **Double vérité spatiale** pendant la transition (2D invisible + 3D) : la 3D native lit les mêmes
   données de zone, jamais l'inverse. Sauvegarde : position convertie, ancienne sauvegarde toujours lisible.
4. **Poids/mémoire** : l'ancien web gelait déjà (VRAM 1,1 Go à 8 zones ; le Web est retiré depuis le 2026-10-04). La 3D vise uniquement le PC : un
   preset d'export PC à part, qui exclut `world3d/` des exports mobile et inversement les planches
   2D inutiles (à faire avant la 1re livraison 3D).
5. **Régression du 2,5D mobile** : `world3d/` est additif. On reste sur la branche courante, sans changer
   de branche, parce qu'une autre session travaille sur Unreal dans le même dépôt. Les tests existants
   (`tools/scenarios/test_*`) doivent rester verts.
6. **Moteur de rendu** : le projet est en renderer *Mobile* (réglage global, partagé avec le 2,5D). Il suffit
   pour les phases 1 à 4 sur GTX 1650 Ti. Passer en *Forward+* pour la 3D PC (meilleures ombres, SDFGI,
   volumétrie) se décidera à la Phase 4, avec une surcharge par plateforme
   (`rendering_method.mobile`), pour ne pas toucher au rendu du 2,5D.

## 6. Plan par phases (aligné sur la demande)

| Phase | Contenu | Critère de réussite (testé en lançant Godot) |
|---|---|---|
| 0 | Audit (ce document) | ☑ fait le 04/10 |
| 1 | Squelette `world3d/`, scène de démo, `Player3D` capsule + caméra orbitale | ☑ fait le 04/10 : `tools/test_world3d.gd` 11/11, 0 erreur console, aucun fichier du 2,5D modifié |
| 2 | Chloé 3D (modèle riggé, Idle/Walk/Run/Jump/Interact), collisions, gravité | ☑ fait le 04/10 : modèle `chloe.glb` (23 clips), saut, interaction (panneau → dialogue du jeu), fondu près de la caméra, animateur générique ; test 26/26, 0 erreur ni avertissement |
| 3 | Premier dino 3D générique depuis `DinoSpecies` (modèle, anims, navmesh, états) | ☑ fait le 04/10 : deux Velociraptors dans la démo (un adulte niv. 14, un jeune niv. 5) ; `test_world3d.gd only=3`, 16 vérifications sur 16 |
| 4 | Petite zone 3D : terrain, végétation, rochers, eau, lumière — idéalement le coin de la Prairie du Grand Crâne chargé par `ZoneLoader` | ☑ fait le 04/10 : la **Prairie du Grand Crâne entière**, bâtie depuis la zone 2,5D, ×2 (240 × 180 m) ; `test_world3d.gd only=4`, 8 sur 8, ~320 im/s sur GTX 1650 Ti, construite en ~1,6 s |
| 5 | Reconnexion gameplay : rencontre → `BattleScene`, Dinodex, sauvegarde, dialogue, Game | ◐ boucle de jeu faite le 04/10 : partie, sauvegarde 3D, interface du jeu, compagnon, jour et nuit, rencontres, combat, capture, Dinodex ; `test_world3d.gd only=5`, 12 sur 12. Reste : PNJ, panneaux, histoire, objets, sorties |
| 6 | Population : spawn par biome, densité, simulation LOD | ◐ 04/10 : dinos par habitat et par moment du jour (règles du 2,5D), troupeaux groupés qui broutent et fuient ensemble ; `test_world3d.gd only=7`, 6 sur 6. Reste : densité, simulation LOD, coût mesuré |
| 7 | Nouvelles espèces et biomes, POI | ◐ 04/10 : les **6 espèces de la Prairie** (velociraptor, parasaurolophus, compsognathus, psittacosaurus, dimorphodon, ankylosaurus), ajoutées par fiche seule ; ≥ 10 à venir |
| 8 | Grand monde : chunks/streaming, World-origin | traversée sans chargement bloquant |

## 7. Ce qui existe (au fil des phases)

```
world3d/layers_3d.gd            couches physiques 3D (même sens que les couches 2D)
world3d/player/player_3d.*      Chloé : CharacterBody3D, origine aux pieds, modèle tourné vers +Z (glTF)
world3d/camera/camera_pivot.gd  Player3D ─ CameraPivot ─ SpringArm3D ─ Camera3D
world3d/demo/demo_3d.*          terrain d'essai (rampe douce → terrasse 1,2 m, pente trop raide,
                                marches de 15 cm, mur, rochers), construit en code, repères MARKS
world3d/input_3d.gd             commandes PC de la 3D (Espace/X : saut), posées à l'exécution
world3d/interaction/interactable_3d.gd  ce que Chloé peut utiliser (indice, dialogue du jeu)
world3d/animation/anim_set.gd   Resource : mouvement générique → clip, vitesses des allures, coupes
world3d/animation/character_animator.gd  AnimationTree générique (Chloé, PNJ, dinos)
world3d/player/chloe_anims.tres AnimSet de Chloé
assets/models3d/characters/chloe/chloe.glb  Chloé riggée, 23 clips
world3d/creatures/species_3d.gd  Resource : ce que la 3D sait d'une espèce (modèle, taille, tempérament…)
world3d/creatures/species/<id>.tres  une fiche par espèce (velociraptor)
world3d/creatures/dinosaur_3d.gd  un dino du monde 3D, toute espèce
world3d/creatures/dino_brain.gd  son comportement (machine à états)
world3d/creatures/model_size.gd  taille dessinée d'un modèle (pour le mettre à l'échelle)
assets/models3d/dinos/velociraptor/velociraptor.glb
tools/test_world3d.gd           test des phases 1 à 3 ; `only=N` pour une seule phase
                                (fenêtre requise, pas --headless)
tools/lancer-3d.cmd             lance la démo 3D
```

Lancer la démo : `Godot/tools/lancer-3d.cmd`. Tester :
`Godot_v4.7.2-stable_win64_console.exe --path Godot --script res://tools/test_world3d.gd -- out=<dossier>`.

Choix de la phase 1 :
- Les vitesses sont lues sur `Player` (2,5D) : marche 3,44 m/s, course ×1,45, bottes ×1,2 / ×1,7. Une seule source de vérité.
- Chloé monte les marches jusqu'à 35 cm (`STEP_MAX`). Un niveau de relief (1,2 m) et `CLIFF_STEP` (0,75 m) restent des falaises. Pente maximale : 46°.
- Si elle tombe hors du monde, elle revient au dernier sol touché.
- Version PC : clavier, souris, manette. Pas de contrôles tactiles à l'écran (la caméra gère quand même le doigt et le pincement).
- La démo n'active pas la sauvegarde : rien n'écrase la partie 2,5D.

Choix de la phase 2 :
- Chloé : 1,50 m, 32 kg, **fine** (capsule de 0,17 m de rayon), et non trapue ni « chibi ».
- Saut : 0,65 m au plus (≈ 0,68 m une fois intégré), bouton tenu. Un appui bref donne un saut plus bas. Tolérances : 0,12 s après avoir quitté un bord, et un appui 0,15 s avant d'atterrir est mémorisé. Contrôle en l'air réduit (40 %). Ce saut reste **sous `Region.CLIFF_STEP` (0,75 m)** : il n'ouvre jamais un passage que le 2,5D ferme. L'escalade sera une capacité à part.
- Commandes PC (`world3d/input_3d.gd`) : la carte d'entrées du projet est celle du 2,5D, et la 3D ne la change qu'à l'exécution. Espace / X : sauter. E, Entrée, A : interagir et faire avancer les dialogues. Maj / B : courir.
- Interaction : `Interactable3D` (groupe `interactable3d`, portée de 1,3 m comme le 2,5D, devant elle). Un indice flotte au-dessus. Par défaut, il lit ses `lines` dans **le dialogue du jeu (autoload Dialogue, inchangé)**.
- Animations : `CharacterAnimator` construit en code un AnimationTree. Une machine à états gère `move` (marche et course mêlées selon la vitesse au sol, accélérées au-delà du clip de course pour que les pieds ne glissent pas), `jump_start` → `air` → `land`, et la chute d'un bord. Un OneShot joue les actions (interact, wave, eat…). `AnimSet` (Resource) associe chaque mouvement générique à un clip, avec repli si un clip manque. **Le même code servira aux PNJ et à toutes les espèces de dinos.**
- Fondu : de 1,4 m à 0,6 m entre la caméra et sa tête, Chloé devient transparente à 85 %.
- Caméra : 4,5 m par défaut, pour que Chloé occupe environ un tiers de la hauteur de l'écran.

### Le modèle de Chloé (`assets/models3d/characters/chloe/chloe.glb`)
- **Source** : Quaternius, *Universal Base Characters* (corps `Superhero_Female`, affiné et mis à l'échelle). Les animations viennent de la *Universal Animation Library* 1 et 2 (version sans root motion). Les fichiers de travail (.blend, téléchargements) sont dans `assets3d_src/chloe/`, ignoré par git.
- **Fiche** : 1,50 m, regard vers +Z, pieds à l'origine. 19 482 triangles, 65 os (noms à la Unreal : `pelvis`, `Head`, `hand_r`…), peau en 2048².
- **Visage** : d'après la planche cartoon tirée des photos de Chloé (mémoire *chloe-photos-reference*). Les photos ne sont pas dans le dépôt.
- **23 clips** :
  - mouvements de base : idle, walk, run, sprint, jump_start, jump_air, jump_land ;
  - interactions : interact, pickup, pickup_ground ;
  - postures et déplacements particuliers : crouch, crouch_walk, sit_down, sit, stand_up, swim, swim_idle, push, climb ;
  - autres gestes : talk, nod, hit, roll.
- **`chloe_anims.tres` (son AnimSet)**, en **mode foulées** (corrigé le 04/10 ; Greg : « elle fait de trop grands pas, on dirait qu'elle vole sans pesanteur ») :
  - **Cause** : le clip `run` est une course en bonds d'adulte (pas de 2,26 m, 67 % du temps en l'air). Ralenti à 0,76 pour la marche du jeu, il donnait 1,6 pas/s.
  - **Correctif** : une **cadence d'enfant par vitesse** (`cadence`) : 1,55 pas/s à 0,8 m/s, 2,0 à 1,3, 2,5 à 2,2, 2,95 à 3,4, 3,25 à 5, 3,5 à 6. Le pas = vitesse ÷ cadence.
  - **Mélange** : marche (pas de 0,54 m) et course (2,26 m) sont mélangées selon la longueur de pas. Les deux clips sont étirés sur un même cycle d'une seconde et calés sur la pose du pied gauche (`gait_left_down` : marche 0 s, course 0,901 s, sprint 0,567 s ; mélange synchronisé).
  - **Mesures sur le squelette** :
    - à 3,4 m/s : pas de 1,16 m, 3,3 pas/s, 34 % du temps en l'air (un trot) ;
    - à 5 m/s : pas de 1,54 m, 49 % en l'air.
    - Planches de profil : `test_world3d.gd only=2` → `07_foulees_*.png`.
  - Les vitesses naturelles (`walk_clip_speed`…) ne servent qu'au mode sans foulées. Atterrissage raccourci à 0,65 s.
- **Animateur** :
  - **Mode foulées** (Chloé, PNJ) : voir ci-dessus.
  - **Sans courbe de cadence** (les dinos pour l'instant) : il choisit l'allure la plus proche de la vitesse et la joue plus vite ou plus lentement.
  - **Atterrissage** : il est sauté quand elle retombe en courant.
- **Vitesses de la 3D (décision de Greg, 04/10)** : la 3D a **sa propre vitesse de marche**, `Player3D.WALK` = 1,6 m/s (une enfant qui marche ; ×1,2 avec les bottes). La « marche » du 2,5D (3,44 m/s) n'était qu'un trot une fois vue en 3D.
  - **Course** (Maj / B tenu) : la course du 2,5D, 4,99 m/s, ou 5,85 avec les bottes.
  - **Ce que les dinos considèrent comme courir** : au-delà de 3,44 m/s.
  - **Mesures** : en marchant, pas de 0,74 m, environ 2,2 pas/s, toujours un pied au sol. En courant à 5 m/s, pas de 1,45 m à 3,45 pas/s.
  - **Limite** : le mélange marche + course soulève un peu les pieds en pleine course (60 % du temps sous le seuil « en l'air » de 6 cm). Pour un appui parfait, il faudrait un pied ancré par IK ou un clip de petite course propre à une enfant.

### Phase 3 : le premier dino (Velociraptor)
Une espèce 3D = **un modèle + une fiche `world3d/creatures/species/<id>.tres` (`Species3D`)**, sans code. La fiche contient :
- l'id de l'espèce : le lien vers la fiche 2,5D, qui garde stats, famille, rareté et cris, sans changement ;
- le modèle et son `AnimSet` (sous-ressource) ;
- les tailles réelles (`length_m`, `mass_kg`, d'après `DexFacts`), le régime et les biomes ;
- le tempérament (`shy`, `curious`, `calm`), les vitesses (promenade, fuite) et les distances (perception, fuite, rayon de promenade).

`Dinosaur3D.create(species, level)` assemble le reste :
- **le dino de jeu** : `dino` est le `Dino` du 2,5D (`game/dino.gd` : niveau, stats, attaques), celui que le combat et la capture utiliseront ;
- **la taille** : `ModelSize` mesure le modèle tel qu'il est dessiné, quelles que soient ses unités. Il est mis à sa vraie longueur, compressée au-delà d'un gabarit de 1,5 m comme dans le 2,5D, puis à son âge (`DinoSize.growth` : un jeune de niveau 5 est à 54 %, adulte au niveau 14) ;
- **le corps** : une capsule sur la couche des dinos, la gravité et un `NavigationAgent3D`. Il freine avant d'arriver, et revient chez lui s'il tombe hors du monde ;
- **les animations** : le `CharacterAnimator` de Chloé, inchangé, avec `size_factor` pour qu'un jeune trottine plus vite ;
- **`DinoBrain`** : repos, promenade autour de chez lui, il regarde Chloé (moins de 10 m), puis fuit en courant si elle approche (moins de 4 m, ou si elle court vers lui), vers un sol praticable : acculé, il bifurque. Il se calme quand elle est loin ;
- **l'observation** : « E : observer » à 6 m ouvre le dialogue du jeu avec le nom, le niveau et la fiche du Dinodex (`DexFacts`).

Dans la démo, un maillage de navigation est calculé au lancement à partir des blocs solides (groupe `nav_source`).

Modèle : Quaternius, *Animated Dinosaur Bundle* (poly.pizza) : 1 248 triangles, 29 os, clips Idle, Walk, Run, Attack, Jump, Death. Mesures à l'échelle adulte (2 m) : marche 1,23 m/s, course 3,9 m/s.

**Reste à voir (Phase 3 → 7)** :
- **Style** : le raptor est bien plus simple que Chloé (1 248 triangles contre 19 500) et d'un gris-brun uni. Le recolorer comme Vif (2,5D) et unifier le rendu avec un shader cartoon commun (Phase 4).
- **Animations** : il n'a pas de clips manger, dormir ni crier : à créer pour les états brouter et dormir.
- **Comportement** : le clip « Jump » (bond) est déclaré comme `pounce` pour la chasse, qui viendra plus tard.

### Phase 4 : la Prairie du Grand Crâne en 3D (`world3d/zone3d/`)
**Principe** : une zone 3D est **bâtie au lancement depuis la zone 2,5D**, qui sert de plan. On ne redessine rien : le même tracé (chemins, étang, falaises, bosquets, mer), les mêmes décors aux mêmes endroits, les mêmes habitats.

**Plus grande** (demande de Greg, 04/10 : « les régions plus étendues, la progression sera plus rapide en 3D ») : `zone_scale` = 2 m par case (réglable par zone).
- **Ce qui s'agrandit** : les lieux. La Prairie passe de 120 × 90 à 240 × 180 m, quatre fois plus de surface.
- **Ce qui garde sa taille réelle** : arbres, rochers, personnes, dinos. La hauteur du relief est conservée (un niveau = 1,2 m).

**Les briques** :
- `ZoneSource` (données) : ouvre la zone 2,5D hors de l'arbre (`Region.open_for_preview`, aucun de ses scripts ne tourne) et la lit. Relief `HeightMap` du 2,5D, sols par case, décors (`Prop` : kind, place, collision), habitats, points d'arrivée. Hauteurs et plancher lus une fois (`Region.floor_height` reparcourt la zone à chaque appel : 120 s → 1,6 s).
- `ZoneTerrain` : maillage du relief, découpé en blocs de 32 m. Collision `HeightMapShape3D` à 1 m. L'eau est une nappe au niveau d'eau du 2,5D.
  - Au bord d'une falaise, la hauteur de la case tient (règle `STAND_SNAP` du 2,5D) : la falaise reste une paroi raide et non une pente.
  - `terrain.gdshader` reprend le sol peint du 2,5D : mêmes images, mêmes répétitions au mètre, bords déchirés, taches, sable, sous-bois, vase, roche, berges mouillées, ombres de nuages. Les falaises prennent les strates peintes selon la pente vraie de la face.
    - **Le fond sous l'eau** (refait le 04/10) : il garde son sable et ses galets, l'eau ne fait que lui prêter sa couleur et l'assombrir (`bed_tint`, `bed_shade`, `bed_depth_m`). `ZoneTerrain.bed_look()` les règle **par zone** : la teinte suit l'eau de la zone dans le 2,5D (`WorldView.WATER_TINT` : bleu-vert clair sur la côte, vert trouble au marais), et `ZoneTerrain.BED` permet de donner à une zone sa propre couleur (marais, monts gelés). Avant, le lit était peint presque noir et on ne voyait rien en eau peu profonde.
- `water.gdshader` + `zone_water.gd` (`ZoneWater`, refaits le 04/10) : eau cartoon qui **suit le ciel**. Le shader ne prend aucune lumière du moteur (`unshaded`) ; `ZoneWater` lui donne à chaque changement de lumière la couleur du ciel de l'heure, prise sur le vrai soleil et la vraie lune de `ZoneSky` (hauteur, couleur) : bleu pâle à midi, orange et violet au crépuscule et à l'aube, indigo la nuit. L'eau mélange cette couleur à son corps et la reflète (Fresnel), d'où : elle n'est **jamais noire**.
  - trois bandes franches selon la profondeur du fond (relief du 2,5D), chemin du soleil (ou de la lune) sur l'eau, écume au rivage **et** autour de ce qui perce la surface (lecture du tampon de profondeur, gratuite en Forward+), fond visible en eau peu profonde.
  - trois trains de vagues doux qui se croisent, plus une houle longue qui soulève la nappe au large.
  - **reflets** (`ZoneWater.Reflections`) : **`MIRROR` par défaut** — une caméra miroir sous l'eau dans une `SubViewport` (0,3 × la fenêtre, 55 m de portée, une image sur deux, sans SSAO/SSIL/glow, sans la nappe elle-même, seule sur la couche visuelle 20, éteinte quand la caméra plonge à la verticale). On y voit les arbres, les falaises, Chloé. `SKY` revient au ciel calculé, pour une machine modeste. Essayé le 04/10 à pleine définition et toutes les images : 1,7 ms sur la mer et jusqu'à 12,5 ms au bord de la mare, pour un gain qui ne le valait pas — gardé en 0,3 / une image sur deux.
  - **pas de crêtes pâles** : quelle que soit la manière de les dessiner, elles se lisaient comme des lignes claires en travers de l'eau. Retirées le 04/10 (Greg : « retire juste les lignes »). Le relief des vagues reste lisible par l'ombrage du corps de l'eau et par ce que le reflet en fait.
  - Une version plus savante (houle venant du large d'après une carte du rivage, rides courtes sur les mares) a été écrite puis écartée : Greg a préféré l'eau d'avant. Elle est gardée hors du projet, dans le dossier de travail de l'agent (`water_version_savante_houle_et_mare.gdshader`).
  - la nappe déborde de 260 m autour de la zone pour que la mer aille loin vers l'horizon.
  - coût mesuré sur GTX 1650 Ti : la nappe 0,1 à 0,5 ms par image, tout compris.
- `Blockers3D` reprend les règles du 2,5D, pour que les passages s'ouvrent et se ferment pareil :
  - la forêt arrête Chloé, et l'eau profonde aussi (couche eau) ;
  - une falaise (`Region.cliff_between`) est un mur des deux côtés, plus haut qu'un saut ;
  - les bords de la zone sont fermés ; les sorties viennent en Phase 8 ;
  - les décors solides ont leur taille réelle (`Prop.KINDS["solid"]`).
- `Scatter3D` : les décors du 2,5D à leur place, les bois des cases forêt (même choix d'espèces que le 2,5D, avec des buissons le long des chemins, 1 arbre pour 6 m²) et un semis de fougères et de fleurs (1 pour 14 m²). Rendu par lots (`MultiMesh` par sorte et par carré de 32 m), avec des modèles 3D (`nature_models.gd`, orientés au hasard) ou, à défaut, l'image du 2,5D debout.
- **Modèles de végétation** : 13 sortes, 21 modèles low-poly faits dans Blender aux couleurs des images du jeu (`assets/models3d/nature/`, scripts dans `assets3d_src/nature/scripts`).
- `Zone3D` (`zone_3d.tscn`) : assemble ciel et soleil doré, brume lointaine, maillage de navigation calculé en tâche de fond, Chloé à son point d'arrivée (`DepuisPort`), et les dinos des habitats qui ont une fiche 3D (7 Velociraptors). L'heure du jour viendra en Phase 5 : pour l'instant, tous ceux qu'on voit à découvert sont dehors.

**Rendu cartoon commun** (`world3d/render/`, agent du 04/10) : les modèles de Chloé, des dinos et de la végétation, quelle que soit leur source, reçoivent le même rendu.
- `toon.gdshader` : trois paliers d'ombrage doux, ombres du soleil, reflet chaud dans l'ombre, liseré de lumière côté soleil, sans reflets métalliques, saturation légèrement relevée.
- `outline.gdshader` : contour brun `#2a180c` comme les images du 2,5D, d'environ 2 px à l'écran, plus fin au loin, qui suit les animations.
- `toon_style.gd` : `TOON.apply(modèle, options)` remplace les matériaux importés, mis en cache, et corrige les normales des maillages à facettes pour éviter les trous dans le contour.
- Où il s'applique : Chloé, les dinos et `Scatter3D`. Pas de contour sur les fleurs, les champignons ni les prêles : trop fines, elles devenaient des bâtons sombres au loin.
- Coût : environ +0,03 ms par image ; la Prairie tourne à environ 275 im/s.
- **Correction au passage** : le fondu de Chloé près de la caméra ne s'affichait pas. Le renderer Mobile ignore `GeometryInstance3D.transparency`, et le test ne lisait que la valeur. Les matériaux cartoon font maintenant ce fondu par tramage.

**Lancer** :
- `tools/lancer-3d.cmd` lance la Prairie ; `tools/lancer-3d-essai.cmd` le terrain d'essai.
- **Depuis Godot (F5)** : un écran de choix (`world3d/launcher/`) propose « Version 3D (PC) — Continuer / Nouvelle partie » ou « Version mobile (2,5D) ». La scène principale est surchargée pour les seules versions éditeur, avec `run/main_scene.editor_runtime` dans `project.godot`. L'APK et le web démarrent toujours sur l'écran titre mobile.
- **En ligne de commande** : `-- --3d` va droit dans la 3D, `-- --mobile` dans le 2,5D. Les outils lancés avec `--script` passent comme avant par l'écran titre mobile.
- **Attention** : en GDScript, `ProjectSettings.get_setting` ignore les surcharges ; c'est `get_setting_with_override` qui les applique.

**Reste à faire (Phase 4 → 5)** :
- tracé des falaises plus naturel (aujourd'hui en marches carrées) ;
- heure du jour, météo et nuages du 2,5D ;
- herbes hautes ;
- décors d'histoire (`StoryProp`), PNJ, panneaux, galets, sorties ;
- forêts des bords lointains ;
- rendu cartoon des décors.

### Phase 5 : le jeu dans la Prairie 3D (`world3d/game/`, `world3d/zone3d/zone_sky.gd`)
Les systèmes du 2,5D sont **réutilisés tels quels** (`Game`, `Save`, `BattleScene`, `Dialogue`, l'interface, `DexScreen`, `MapScreen`). On ne réécrit que le pont avec la 3D, qui fait ce que `world.gd` fait pour le 2,5D.

- **`Session3D`** :
  - **Partie** : la 3D a sa propre sauvegarde, `user://save_3d.json`, au format du 2,5D. La sauvegarde du 2,5D n'est jamais écrasée. Si elle n'existe pas, une nouvelle partie démarre avec Vif.
  - **Position** : celle de Chloé est gardée **dans les unités du 2,5D** (pixels de la zone), donc la sauvegarde se lit pareil.
  - **Interface** : bannière de zone, barre d'équipe, horloge, bourse, boutons réglages, carte (M) et Dinodex (X).
  - **Compagnon** : le dino de tête suit Chloé (`Dinosaur3D.companion`), et change avec l'équipe.
  - **Ambiance** : musique et sons de la zone.
  - **Dinos selon l'heure** : ils changent quand le moment de la journée change.
- **`Encounters3D`** : les règles de `world.gd`, transposées.
  - **Contact** : marcher sur un dino sauvage lance le combat du jeu (le monde en pause). Gagné ou capturé, il disparaît ; sinon il se calme 5 s. Perdu : l'équipe est soignée et Chloé revient à l'entrée.
  - **Approche** : en marchant calmement, on peut approcher un dino farouche jusqu'au contact ; en courant vers lui, il détale.
  - **Hautes herbes** : les pas dans les hautes herbes d'un habitat peuvent lancer un dino caché, avec les mêmes taux et les mêmes pas que le 2,5D, rapportés à l'échelle de la carte.
  - **Repos et Dinodex** : l'équipe récupère un peu à chaque pas, et une espèce vue de près entre au Dinodex, avec de l'expérience.
- **`ZoneSky`** : l'horloge du jeu et la lumière du jour du 2,5D (`WorldView.DAYLIGHT`), assombries par la pluie, l'orage et la brume.
- **Les dinos de l'heure** : par habitat, ceux qu'on voit à découvert à ce moment (`Encounter.active`). Le jour, des Parasaurolophus ; la nuit et au crépuscule, des Velociraptors.
- **Nouvelle espèce sans code** : le **Parasaurolophus** (modèle Quaternius, une fiche `species/parasaurolophus.tres`). Herbivore calme, 9,5 m réels, montré à environ 5,2 m une fois adulte (compression du 2,5D).
- **Cris** : les dinos crient tous les 10 à 22 s, en son 3D.

**Reste pour finir la Phase 5** :
- les PNJ (modèles 3D à trouver), les panneaux, les objets à ramasser et les galets d'ambre ;
- les décors d'histoire (`StoryProp`) et les scènes (`Stage` en 3D) ;
- les sorties vers les autres zones ;
- la pluie visible ;
- les hautes herbes en 3D ;
- l'œuf à porter.

### Terrain3D, base du relief (04/10)
Le sol de la Prairie est maintenant fait par le plugin **Terrain3D** (rendu validé visuellement par Greg), pour préparer l'open world. Les règles du jeu continuent de lire les données du 2,5D (`ZoneSource`).
- `ZoneTerrain` choisit le sol : `DEFAULT_KIND = TERRAIN3D` ; retour en arrière : `MESH` (l'ancien maillage, entièrement fonctionnel), ou lancer avec `-- --terrain=mesh`.
- `ZoneGroundTerrain3D` (`terrain3d_ground.gd`) : régions de 64 m, sommets tous les 0,5 m, collision zone entière, navigation des dinos construite avec nos propres triangles (la fonction du plugin ignorait la moitié du sol).
- `TerrainRelief` (`terrain3d_relief.gd`) fabrique le relief par script : les hauteurs du 2,5D, puis des modifications décrites en données dans `terrain3d_relief/<zone>.json` : `hill`, `valley`, `flatten`, `ramp`, `smooth`, `dig_sea`, `paint`. Le garde-fou `protect` annule toute modification à moins de 2 cases d'une falaise ou de l'eau, là où les règles du jeu tiennent. La peinture ne change que l'aspect.
- **Retouche à la main dans l'éditeur** : `terrain3d_bake.gd -- zone=<id>` écrit les régions et une scène `edit_<id>.tscn` dans `terrain3d_data/<id>/`, que le jeu relit ensuite. Une nouvelle cuisson écrase les retouches.
- La peinture du sol est commune aux deux sols (`terrain_paint.gdshaderinc`).
- **Open world** : la position de la zone est un paramètre du sol. Pour relier les zones, il faudra un seul nœud Terrain3D pour tout le monde, des zones sur des multiples de 64 m, le chargement des régions par morceaux, et un paramètre de position pour l'eau, la pluie et la brume, qui supposent encore la zone à l'origine.
- Test : `tools/test_terrain3d.gd` (24 vérifications).

### Phases 6 et 7 : la Prairie peuplée (04/10)
- **Les 6 espèces de la Prairie** ont leur fiche (`world3d/creatures/species/<id>.tres`) et leur modèle (`assets/models3d/dinos/<id>/<id>.glb`). Sources Blender et aperçus : `assets3d_src/dinos/travail/` et `assets3d_src/dinos/apercus/`.
- **Qualité** : comme Chloé. Formes lisses, 11 000 à 17 000 triangles, peau peinte 2048², yeux avec paupières, narines, dents. Plumes pour le velociraptor et le compsognathus, piquants sur la queue du psittacosaurus.
- **Clips aux mêmes noms** : idle, walk, run, attack, death, jump, eat (tête au sol, mâchoire qui mâche), sleep (couché, yeux fermés).
- **Vitesses des clips** mesurées sur le modèle à sa taille adulte du jeu. La foulée est la même pour les 4 nouveaux.

  | Espèce | Taille réelle | Montré adulte | Marche du clip | Course du clip | Marche | Course |
  |---|---|---|---|---|---|---|
  | velociraptor | 2 m | 2,00 m | 0,60 m/s | 2,35 m/s | 1,0 | 6,0 |
  | parasaurolophus | 9,5 m | 5,22 m | 1,76 | 6,89 | 2,2 | 7,0 |
  | compsognathus | 1 m | 1,00 m | 0,29 | 1,14 | 0,6 | 4,0 |
  | psittacosaurus | 2 m | 2,00 m | 0,76 | 2,96 | 0,9 | 3,5 |

  Marche et course (en m/s) gardent l'animation sous environ 2,5 fois sa cadence, sauf la course du compsognathus, rapide et petit.
- Les dinos de la Prairie sont des jeunes (niveaux 4 à 7), donc plus petits que l'adulte, comme dans le 2,5D (`DinoSize.growth`).
- **Défaut connu** : un dino peut apparaître dans un buisson (il en sort en marchant).

### Rendu PC et plugins (04/10)
- **Une seule peau de dino** : peinte pour la 3D, avec le contour cartoon. La peau reprise des dessins 2,5D a été essayée puis abandonnée (Greg : « les rendus sont mieux sans »). Les fichiers sont gardés hors du projet, dans `assets3d_src/dinos_peau_2d_abandonnee/`.
- **Forward+ essayé** (lancé avec `--rendering-method forward_plus`, même vue à 17 h 30, GTX 1650 Ti) :

  | Rendu | Images/s |
  |---|---|
  | Mobile (le projet) | 375 |
  | Forward+ sans effet | 278 |
  | + SSAO, glow, AgX | 264 |
  | + brouillard volumétrique | 252 |
  | + SSIL | 235 |
  | + SDFGI | gel de plus de 4 s |

  Avec le style cartoon, le SSAO se voit à peine. L'AgX et le brouillard volumétrique ternissent les couleurs (ciel gris, herbe terne).
- **Décision révisée le même jour** (Greg : « la technique doit au max être améliorée dans la version PC 3D », et « ne garde pas le 2,5D, utilise ce qui est de meilleure qualité ») : **la 3D PC passe en Forward+.**
  - Réglage du projet : `rendering/renderer/rendering_method.pc="forward_plus"`. Il touche tous les PC, éditeur compris. Android garde Mobile.
  - Le 2,5D lancé sur PC tourne donc aussi en Forward+. Il démarre sans erreur et son écran titre est identique.
  - Réglages appliqués par `ZoneSky` en Forward+ seulement :
    - effets : SSAO, SSIL, glow, et l'exposition automatique, c'est-à-dire l'œil qui s'habitue au noir (plancher de sensibilité 170 ISO ; 100 changeait la nuit en jour, 300 la rendait trop noire) ;
    - image : MSAA ×4, ombres douces en qualité haute, atlas d'ombres 4096, ombres jusqu'à 90 m.
  - Pas d'AgX et pas de brouillard volumétrique, pour les raisons ci-dessus.
- **Ciel Sky3D complet** (`ZoneSky`) : atmosphère, nuages qui défilent, soleil, lune et sa lumière, Voie lactée.
  - L'horloge (`Game.clock`) et la météo du jeu le pilotent. Pluie ou brume : nuages plus épais, lumière plus faible, brouillard gris proche.
  - Lieu et date : 40° N, 4° E, 9 août 2025. Le soleil se lève à 5 h 55 et se couche à 19 h 45, dans l'aube (5 h-7 h) et le crépuscule (18 h-20 h 30) du jeu. La lune est pleine, levée de 20 h à 5 h 45.
  - La nuit doit rester jouable : lune à 0,45, part du ciel dans la lumière ambiante 0,85 le jour et 0,3 la nuit, lumière ambiante renforcée quand le soleil descend.
  - La table `WorldView.DAYLIGHT` du 2,5D ne sert plus qu'en secours, si le plugin manque.

  | Moment (Forward+, tous effets) | Images/s |
  |---|---|
  | aube 6 h 06 | 130 |
  | midi | 228 |
  | coucher 19 h 36 | 192 |
  | nuit 23 h | 216 |
  | pluie 15 h | 222 |

  L'eau a été refaite le 04/10 (`ZoneWater`, voir la phase 4) : elle prend la couleur du ciel de l'heure et ne redevient plus noire au crépuscule. Essai : `tools/test_eau_3d.gd`.
  Reste : sous la ligne d'horizon, au-delà de la nappe, la couleur de sol de Sky3D fait une bande sombre (`SkyDome.ground_color`, à régler dans `ZoneSky`).
- **Plugins** dans `addons/` (sources et zips d'origine : `assets3d_src/plugins/`). Ils sont activés dans l'éditeur seulement : aucun autoload, exclus de l'export Android.

  | Plugin | Version | Rôle | Remarque |
  |---|---|---|---|
  | Terrain3D (GDExtension) | 1.0.2 | terrain du monde ouvert | ne compile pas en Mobile + D3D12, mais marche en Forward+ (le rendu de la 3D PC depuis le 04/10) et en Mobile + Vulkan |
  | Sky3D | 2.1.0 | ciel, nuages, soleil, lune | **utilisé** par `ZoneSky` ; notre ancien `Sky3D` renommé `ZoneSky` (et `Terrain3D` → `ZoneTerrain`) pour éviter le conflit de noms |
  | ProtonScatter | 4.2.0 (main) | semis procédural | dossier `demos/` retiré |
  | Spatial Gardener | 1.4.1 | peinture de végétation | corrigé pour 4.7 : `Logger` → `SgLogger`, retours manquants, styles vides du thème (`theme_adapter.gd`, `_flat()`) |
  | Waterways | 0.3 (`godot4_5_1`) | rivières, courant, écume | corrigé pour 4.7 (retours manquants) |
  | Debug Menu | 1.2.0 | images/s, CPU, GPU (F3) | créé par `Session3D` en 3D seulement |

  Phantom Camera (0.11) est téléchargé mais pas installé : notre caméra suffit, et il exige un autoload, qui serait chargé dans le jeu mobile.
- **Exports** : `addons/`, `world3d/` et `assets/models3d/` sont exclus du preset Android.

### Chloé : reste à améliorer (Greg, 05/10 : modèle figé après la passe du 05/10)

Passe du 05/10 (étape D, `assets3d_src/chloe/scripts/stage_d.py`, ancien modèle gardé en
`assets3d_src/chloe/chloe_avant.glb`) : visage d'enfant au sourire ouvert, 19 482 → 13 838
triangles, 16 → 11 matériaux, 21 → 12 surfaces, barrette retirée (Greg), cheveux et sac animés.
Captures avant/après : `assets3d_src/chloe/captures/`.

1. ~~**Visage**~~ : fait le 05/10. Bas du visage plus court et plus rond (menton relevé de 13 mm), sourire ouvert avec dents (vrai maillage), nez et oreilles plus petits, sourcils refaits en ruban effilé (8,5 mm), trait de cils aminci sans « eye-liner », peau repeinte. Reste : lèvre du bas un peu charnue de profil ; dents en bande unie (pas de dents du bas) ; ressemble aux photos par ses traits, pas comme un portrait.
2. ~~**Cheveux**~~ : fait le 05/10. Calotte refaite par une découpe le long de la ligne d'implantation (plus d'escalier sur la nuque), lisière peinte calée sur son bord, une mèche devant (lisible de face) et une mèche folle à la tempe gauche. Reste : pas d'autres mèches folles sur le sommet.
3. ~~**Queue de cheval et sac**~~ : fait le 05/10. Os dédiés (`hair_pony_01-05`, `hair_lock_01-03`, `pack_hang`) et `SpringBoneSimulator3D` ajouté au modèle par son script d'import (`world3d/player/chloe_hair_import.gd`, réglages dans `world3d/player/chloe_hair.gd`), avec obstacles tête, dos, épaules et sac ; détail et mesures dans `assets3d_src/chloe/cheveux.md`, contrôle `tools/test_chloe_hair.gd`. Les cheveux suivent ses mouvements animés, pas son déplacement : en repère monde, la queue flottait à l'horizontale en course. Reste : lors d'un virage serré, la queue touche l'obstacle du haut du dos (1,1 cm dedans, invisible ; le contrôle le signale).
4. **Animations** : poings serrés dans plusieurs clips ; pieds environ 5 mm sous le sol en idle ; correction de +9,9° sur `Head` dans tous les clips ; pas de `wave` ni de `fall` (la chute réutilise `jump_air`).
5. **Bottes** : longues et plates, sans revers.
6. ~~**Rendu**~~ : contour brun et ombrage cartoon en place (`world3d/render/toon_style.gd`). Peau gardée en 2048 (Greg, 05/10 : pour les gros plans).
7. ~~**Exports**~~ : fait le 04/10, `world3d/`, `assets/models3d/` et `addons/` sont exclus du preset Android.
