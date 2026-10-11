# Les plugins installés — ce qui sert au 2,5D PC, et comment

> Inventaire fait le 11/10/2026, après l'installation d'une quarantaine de plugins.
> Le jeu visé est le **2,5D sur PC** (voir [version-pc.md](version-pc.md)) ; la 3D est en pause.
> `addons/` pèse aujourd'hui **1,4 Go** et n'est pas dans le dépôt (liste dans le README).

## Ce qu'il faut savoir avant de choisir

1. **Le monde du 2,5D est dessiné en 3D.** Les décors et les dinos sont des images posées dans une
   scène 3D (`world/view3d/`, caméra 3D, soleil `DirectionalLight3D`, `WorldEnvironment`). Donc
   tout plugin **2D** (`shader_type canvas_item`, nœuds `Node2D`, lumières 2D) ne s'applique PAS au
   monde — mais s'applique **au combat et à l'interface**, qui sont, eux, de vraies scènes 2D
   (`AnimatedSprite2D`, `TextureRect`, `CanvasLayer`).
2. **Le PC tourne en Forward+** (`rendering_method.pc`), donc les *compositor effects* marchent.
   Android reste en Mobile : ce qui passe par le compositeur doit être conditionné à la qualité.
3. **Pas de C#.** Le Godot installé est la version standard (`Godot_v4.7.2-stable_win64.exe`), pas
   la version .NET : `controller_icons` et `guideCS`, écrits en C#, **ne peuvent pas fonctionner**.
   Les deux existent aussi en GDScript — c'est cette version-là qu'il faut.
4. **Attention aux plugins « drop-in autoload ».** Activer saltmire, vfx_2d, lit… ajoute un autoload
   dans `addons/` : le jeu ne démarre alors plus sans le plugin, et l'export doit l'embarquer
   (c'est déjà le cas de SimpleGrassTextured, voir le README). N'activer que ce qu'on utilise.
5. Aujourd'hui **11 plugins sont activés** (les 3D), les autres sont installés mais dormants.

## Tri

### À utiliser maintenant, pour le 2,5D PC

| Plugin | Ce que ça apporte | Où | Effort |
|---|---|---|---|
| **Saltmire FX** | 5 shaders de sprite : *hit flash*, *freeze*, *dissolve*, *hologram*, contour | combat : coup reçu (aujourd'hui un bête `modulate` blanc), attaques de glace des Monts, K.O. et capture qui se dissolvent, dinos corrompus à l'ambre noir | petit |
| **Saltmire Spark** | gerbes de particules en une ligne, sans texture | impacts, ramassage d'un objet, poussière | petit |
| **Saltmire Trail** | images fantômes derrière un sprite | attaque rapide, course, Grand Voyageur | petit |
| **VFX 2D** | 4 effets shader (16 dans la version payante) : onde de choc, estafilade, étincelle, flash | une signature visuelle par type d'attaque | moyen |
| **Lens Effects** | rayons de soleil (god rays) et halo d'objectif, par *compositor effect* | la lumière qui traverse la canopée, l'entrée des grottes, le crépuscule sur la mer — qualité Haute seulement | moyen |
| **Gaussian Blur** (compositor) | flou propre, piloté par la profondeur | les gros plans de scène (`Stage.close_up`) et le fond pendant les dialogues ; remplacerait le réglage `dof` actuel | moyen |
| **Controller Icons** (version GDScript à installer) | les vraies icônes de manette / clavier, qui suivent le remapping | pages Commandes et Touches, et les invites en jeu (« appuie sur A ») ; aujourd'hui la manette est **dessinée à la main** (`ui/gamepad_view.gd`) | moyen |
| **Godot AI** *ou* **Godot MCP Toolkit** | un pont MCP : je peux inspecter la scène, lire la console et piloter l'éditeur pendant qu'on travaille | gain de temps sur les vérifications (aujourd'hui je relance Godot en ligne de commande pour chaque test) | petit, mais à configurer à deux |

### Pour la 3D, quand elle reprendra (ne rien activer d'ici là)

Terrain3D, Sky3D, Waterways, Proton Scatter, Spatial Gardener, SimpleGrassTextured, PlantGenerator,
Modular Builder, Ragdoll Generator, BlenderKit, GDDraw, TressFX (cheveux 3D), noise4d.

### À écarter pour ce jeu

| Plugin | Pourquoi |
|---|---|
| **PopcornFX** | 948 Mo à lui seul, moteur de VFX 3D complet : hors de proportion pour des sprites |
| **Fight Engine 2** | moteur de jeu de combat en versus ; nos combats sont au tour par tour |
| **BetterTerrain** | autotuilage de TileMap : nos zones sont **générées** par script, pas peintes |
| **Lit** | éclairage 2D : notre monde est éclairé en 3D (et Lit exige Forward+, donc pas sur Android) |
| **Vision2D, SoftBody2D, Rope2D, Scalable Vector Shapes, RoxyVector2D, PPEP, ya3, Reactive Signal** | outils 2D sans usage ici |
| **Composite Spritesheet Generator** | nos planches sont déjà assemblées par `tools/art-jobs/*.mjs`, reproductible et versionné |
| **guideCS, Controller Icons (C#)** | C# : impossible sans la version .NET de Godot |
| **RigEye2D** | petit : des yeux qui suivent, utile seulement si on met des portraits animés en dialogue |

## Les quatre chantiers que je propose, dans l'ordre

1. **Du jus dans le combat** (Saltmire FX + Spark + Trail, 1 séance) : coup reçu, gel, K.O. qui se
   dissout, capture, corruption. C'est là que le joueur passe le plus de temps et c'est ce qui se
   voit le plus, sans toucher au reste du jeu.
2. **La lumière du PC** (Lens Effects, puis Gaussian Blur, 1 séance) : rayons de soleil dans les
   forêts et aux bouches de grottes, flou de gros plan propre. À brancher sur la qualité Haute et
   vérifié en images/s avant/après.
3. **Les icônes de manette** (Controller Icons GDScript) : les pages Commandes et Touches
   affichent la vraie touche, et les invites en jeu suivent la manette branchée.
4. **Le pont MCP** (Godot AI ou MCP Toolkit, à choisir) : je vois la scène et la console en direct.

## Process — ce qui change dès aujourd'hui

- **Ne plus dézipper un pack dans `Godot/`.** Dézipper dans `assets3d_src/`, puis copier dans le
  projet seulement ce qu'on utilise, dans un sous-dossier clair.
- `node tools/ranger-packs.mjs` liste ce qui traîne dans le projet et n'en fait pas partie ;
  `--ranger` le déplace dans `assets3d_src/packs-deverses/`. Rien n'est supprimé (sauf un dossier vide).
- **L'export Windows embarque `addons/` (1,4 Go)** : à restreindre aux plugins vraiment utilisés le
  jour où on reconstruit l'exe, sinon l'exe est injouable à télécharger.
- Les packs **2DPIXX** (archer, guerrier, magicien, tuilesets) sont arrivés **vides** : leur
  décompression a échoué sur les parenthèses du nom (`(Size 32x32)`). De toute façon, du pixel art
  de tuiles ne correspond pas à la direction artistique d'Ambrelune (peinture, dessin à la main).

## Fait le 11/10 — chantier 1 : du jus dans le combat

Plutôt que d'activer les plugins Saltmire (autoloads, donc `addons/` obligatoire dans l'export),
leurs idées sont reprises **dans un seul shader maison**, `battle/fighter.gdshader`, qui remplace
`breathe.gdshader` : respiration, **mollesse** (écrasement/étirement amorti en ressort + balancement
du haut du corps), **éclat blanc** du coup encaissé, **disparition qui se consume** (K.O., rappel,
capture, et apparition du remplaçant), **veines d'ambre noir** pour les ~90 espèces qui n'ont pas de
planche corrompue dessinée. Plus des **images fantômes** derrière les bonds. Test :
`tools/test_combat_jus.gd` (11 vérifications) ; scénario `tools/scenarios/vis_combat_jus.gd`.

**SoftBody2D n'est pas le bon outil pour les sprites** : c'est une simulation physique (maillage de
corps rigides, pour de la gelée ou des objets qui se brisent), non déterministe, coûteuse, et qui
casserait nos planches de 3 images et nos tweens. Le même effet « mou » s'obtient mieux — gratuit et
contrôlable — par déformation de sommets dans le shader.
