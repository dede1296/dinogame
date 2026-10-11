# Ambrelune 2,5D — la version PC

> Chantier ouvert le 11/10/2026 : le développement 3D (`world3d/`, `Unreal/`) est en pause, et le
> jeu 2,5D — celui qui est jouable et avancé — vise maintenant **l'ordinateur** plutôt que le
> téléphone. Rien n'est retiré du côté téléphone : l'APK continue de se construire, les contrôles
> tactiles restent là pour lui. Voir [migration-3d.md](migration-3d.md) pour le chantier en pause.

## Ce qui change quand on joue sur un ordinateur

Le jeu reconnaît un ordinateur par l'étiquette `pc` de Godot (`Screen.on_computer()`, autoload
`core/screen_mode.gd`).

| | Téléphone | Ordinateur |
|---|---|---|
| Manette à l'écran | joystick au pouce gauche, boutons A / B | **rien** (même si Windows annonce un écran tactile) |
| Courir | garder B appuyé | **Maj**, ou B de la manette |
| Le menu du jeu | le bouton ☰ | **Échap** (ou Start), et toujours le bouton ☰ |
| Plein écran | — | **F11** ou **Alt + Entrée**, retenu d'une fois sur l'autre |
| Quitter | le bouton Accueil du téléphone | bouton **Quitter le jeu** sur l'écran titre |
| Vue de base | 1280 × 720 | **1600 × 900** : l'interface prend moins de place et l'image est plus nette |
| Zoom | pincer à deux doigts | la molette de la souris (et le réglage Affichage) |
| Paramètres | « Sur le téléphone » / « Sur l'ordinateur » | une seule colonne, clavier et manette ; la page Affichage ajoute **Fenêtre → Plein écran** |

Détail utile : Échap reste l'action « revenir, fermer, refuser » dans les menus et les dialogues.
C'est pour ça que `Player.running()` ne lit plus `cancel` sur ordinateur — sinon ouvrir le menu
faisait partir Chloé en courant. La manette garde les deux usages (B revient **et** fait courir,
car B est maintenant aussi dans l'action `run`).

## Les icônes de touches (11/10)

`Prompts` (autoload, `core/prompts.gd`) donne l'image de ce qui déclenche une action :
`Prompts.texture(&"interact")` → la touche du clavier, ou le bouton de la manette de la famille
branchée (Xbox, PlayStation, Switch, reconnue par son nom), selon ce que le joueur a touché en dernier.
Elle lit l'InputMap, donc elle suit les touches redéfinies, et la disposition du clavier (un AZERTY
voit « Z » là où un QWERTY voit « W »). Quand plusieurs touches font la même chose, elle montre une
lettre (« E » plutôt qu'« Espace »). Images : Kenney « Input Prompts », CC0, dans
`assets/art/ui/prompts/` (copiées depuis Controller Icons, qui est en C# et donc inutilisable ici).

- **Invite d'interaction** (`ui/interact_prompt.gd`) : une bulle avec la touche flotte au-dessus de
  ce que Chloé peut utiliser (parler, ramasser, fouiller, lire) — le même objet que celui qu'atteindrait
  la touche (`Player.nearest_interactable`). Sur ordinateur seulement ; le bouton A joue ce rôle au téléphone.
- **Page Commandes** : la touche ET le bouton de manette réels de chaque action, à la place du texte.
- Test : `tools/test_prompts.gd` (13 vérifications).

## La manette seule (11/10)

Tout se joue à la manette, vérifié par `tools/test_manette.gd` (envoie de vrais événements de
manette). Ce que l'audit a trouvé et corrigé :
- **`ui_accept` et `ui_cancel` n'avaient aucun bouton de manette** : la croix navigue, mais A ne
  validait pas et B ne fermait pas. Ajoutés au démarrage (`Prompts.ensure_pad_for_menus`).
- **Équipe** : action `team` (◀ de la croix, ou T). Le jeu attend, ◀ ▶ choisissent un portrait,
  A ouvre son menu (« Dino actif », baies, fiche), B revient. Impossible à la manette avant.
- **Dinodex** : LB / RB changent de page (en sautant les régions inconnues) ; la fiche d'un dino de
  l'équipe a « En tête / En réserve ».
- **Boutique** : boutons focusables, le focus revient au même endroit après un achat.
- `PadFocus` (`ui/pad_focus.gd`) : rend un écran fait pour la souris pilotable à la croix sans le
  réécrire (contour doré, premier focus) — et rien ne change tant qu'on est à la souris.
- Déjà bons, désormais testés : carte (stick, gâchettes, A), menu (Start), Grand Voyageur, combat
  entier avec A seulement.
- La barque de Maïa (11/10) reprend l'écran du Grand Voyageur : focus d'emblée sur la première
  destination, croix, A, B ; à la souris, un clic sur la barque y mène Chloé, un clic sur une ligne
  choisit (`tools/test_barque.gd`).

Croix de la manette : ↑ Dinodex, ◀ équipe ; Retour (Select) la carte ; Start le menu ; Y monter.

## Le tutoriel des commandes (11/10)

`ui/controls_tutorial.gd` : trois pages (se déplacer et agir ; ton équipe et l'île ; menus et
combat) avec les vraies images du clavier **ou** de la manette, qui changent sous les yeux du joueur
dès qu'il passe de l'un à l'autre. S'ouvre tout seul, **une fois par partie** (drapeau
`tuto_commandes`), quand Chloé est libre depuis 1,5 s (donc après les premières scènes). Souris :
Suivant / Précédent / Passer ; manette : ◀ ▶ ou LB / RB, A, B ; clavier : ← →, Entrée, Échap. Se
rouvre depuis Paramètres → Commandes → « Revoir le tutoriel des commandes ». Test : `test_tuto.gd`.

## Le clic dans le monde (11/10, accord de Greg : « clic peut interagir »)

Un clic gauche sur quelque chose d'utilisable — une personne, un panneau, un objet à ramasser — envoie
Chloé l'utiliser : tout de suite si elle est à portée, sinon elle y marche en ligne droite puis
l'utilise. Une touche ou le stick l'arrête ; elle renonce après 1,2 s sans avancer (un mur, l'eau).
Une main remplace la flèche au-dessus de ce qui est cliquable. On vise ce qu'on voit : le point de
l'écran où la cible est dessinée (son corps, pas ses pieds) à 64 px près. Les clics sur le HUD et les
menus restent au HUD. Écrit dans `world/click_interact.gd` et `Player.go_and_interact`. Test : `test_clic.gd`.

## Les ombres aplaties (11/10)

Chaque image debout du monde — arbres, buissons, rochers, clôtures et piquets, herbes, fleurs,
barques, filets, séchoirs, Chloé, les dinos, les PNJ — jette au sol **sa propre silhouette**, couchée
à l'opposé du soleil (la technique des jeux 2,5D). Elle remplace, pour les images, l'ombre-carte du
soleil, qui vibrait, était en escalier et, le soleil étant toujours derrière la caméra, ne laissait
qu'un trait sous une image fine (et rien sous les 73 genres sans ombre de contact).

- **Elle part du pied** : de la dernière ligne opaque de l'image (mesurée une fois par image,
  `FlatShadows.picture_bottom` ; pour les planches de personnages, `SheetFrames.drawn_in`), au droit
  de son point au sol, là où la caméra la voit toucher le sol. Le test mesure l'écart pied → début
  de l'ombre à l'écran.
- **Elle suit l'heure** : direction et longueur selon le soleil de `WorldView.DAYLIGHT` (longue le
  matin et le soir, courte à midi), plafonnée (2 m d'ombre par m de hauteur au plus, 9 m en tout) et
  plus pâle au bout. La nuit, un léger halo sous la lune. Pluie, brume, sable, neige, orage : plus
  pâle et plus douce. Dedans : plus pâle. Sous la mer : très pâle ; les personnages n'en ont pas
  quand ils nagent ou plongent.
- **Elle suit l'image** : le vent et Chloé qui écarte les herbes (le même balancement que l'image),
  un arbre fouillé, une pierre soulevée ; l'image **courante** d'une animation (un dino qui marche),
  son retournement, sa taille, le saut de pas. En l'air (le Vol), l'ombre reste au sol, décalée par
  le soleil, pâlit et se floute avec l'altitude. Chloé en selle et sa monture : **une seule** ombre
  (gabarit : là où une ombre de personnage est posée, une autre ne la fonce pas).
- **Elle assombrit, sans jamais éclaircir** (multiplication, teinte brun-bleu) et ne reçoit pas le
  brouillard (sinon l'aube l'effaçait) ; elle s'efface au loin (26 → 46 m de la caméra).
- **Sur le relief** elle suit le sol de près ; au bord d'une falaise ou d'un trou, elle s'efface là
  où elle flotterait. Dans les hautes herbes, celle d'un arbre assombrit le bas des touffes.
- **Chaque genre** a sa force, sa longueur, son flou et sa façon (ronde : l'image se tourne face au
  soleil ; planche : une clôture reste de face) dans `world/view3d/shadow_kinds.gd`. « Aucune » : ce
  qui est couché au sol (nénuphars, os à plat, flaques), accroché à un mur, posé contre une falaise
  (portes, fresques), les barreaux d'une cage. Un genre absent de la table (un nouveau, des Cieux)
  reçoit une ombre déduite de `Prop.KINDS` (une plante souple sans collision : courte et légère ;
  accrochée, foot négatif : aucune).
- **Qualité** (`Quality` « projected_shadows ») : Haute et Moyenne ; **Basse** n'a que l'ombre de
  contact (comme avant : pas d'ombre du soleil à Basse). Les **maisons** (modèles 3D), le relief et
  les décors sans image gardent l'ombre-carte du soleil.
- Les images par seconde, sans vsync, Haute, GTX 1650 Ti, en alternance au même endroit
  (`tools/perf_ombres.gd`) : Prairie 112,5 → 109,5 (−2,7 %), Forêt 95,0 → 103,8 (+9 %), Port
  105,4 → 119,7 (+13,5 %). Appels de dessin : 234 → 367, 282 → 376, 296 → 320 (une instance d'ombre par
  paquet de décors, plus une par personnage ; l'ombre-carte n'a plus à redessiner les images).

Limites connues : un personnage qui passe dans l'ombre d'un arbre n'est pas assombri (seul le sol
l'est) ; une ombre peut passer sous une maison 3D ou sur le pied d'une falaise qui monte (elle s'y
enfonce, sans grimper la paroi) ; deux ombres de décors qui se croisent foncent un peu plus ; les
rayons de lumière du brouillard volumétrique sous les arbres (PC, Haute) ne sont plus découpés par les
arbres (ils n'ont plus d'ombre-carte).

Écrit dans `world/view3d/ombre_aplatie.gd` (`FlatShadows`), `ombre_aplatie.gdshader` (décors),
`ombre_aplatie_sprite.gdshader` (personnages, en `material_overlay`), `ombre_aplatie.gdshaderinc`,
`shadow_kinds.gd` ; branché dans `world_view.gd` (`flat_shadows`). Test :
`godot --path Godot --script res://tools/test_ombres.gd --resolution 1600x900 -- out=<dossier>`.

## Où c'est écrit

- `core/screen_mode.gd` (autoload `Screen`) : plein écran, taille minimale de la fenêtre, F11.
- `ui/touch_controls.gd` : `_enabled`, faux sur ordinateur — ni dessin ni lecture des touchers.
- `actors/player.gd` `running()` ; `world/world.gd` `_unhandled_input` (action `menu`).
- `ui/settings_menu.gd` : pages Commandes et Affichage, `CONTROLS`, `HINTS_PC`.
- `scenes/boot/boot.gd` : le bouton « Quitter le jeu ».
- `project.godot` : `window/size/viewport_*.pc`, actions `menu` et `run` (B de la manette).

## Test

`godot --path Godot --script res://tools/test_pc_controls.gd -- out=<dossier>` : 9 vérifications
(pas de boutons tactiles, Échap ne fait pas courir, Maj si, Échap ouvre le menu, la page Affichage
offre le plein écran, Commandes parle clavier, F11 aller-retour) et 5 captures. Comme tous les
tests, il affiche en haut à gauche ce qu'il vérifie (`ShotCaption`) ; l'outil de captures
`tools/capture.gd` accepte la même chose avec `titre=…`.

## Reste à faire (par ordre d'intérêt)

1. **Le HUD à la souris** : les boutons ronds (☰, carte, Dinodex, selle) et la barre d'équipe sont
   dessinés pour des pouces. Sur un écran d'ordinateur ils peuvent être plus petits, et gagneraient
   un survol et une info-bulle.
2. ~~Clic de souris dans le monde~~ — FAIT (voir ci-dessous). Reste : un clic dans le vide ne fait
   pas marcher Chloé (voulu : le clavier et la manette marchent) ; à rediscuter si Greg le veut.
3. **Alléger l'export Windows** : le preset embarque encore `addons/*` (350 Mo) et
   `assets/models3d/*` (114 Mo), qui ne servent qu'à la 3D en pause. À faire le jour où on
   reconstruit l'exe (voir la règle « exe sur demande »).
4. **Raccourcis clavier** des écrans (Dinodex, carte, boutique) : flèches et Entrée partout.
5. La fenêtre ne retient pas sa taille ni sa position entre deux parties (seul le plein écran l'est).
