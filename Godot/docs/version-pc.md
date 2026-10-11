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

Croix de la manette : ↑ Dinodex, ◀ équipe ; Retour (Select) la carte ; Start le menu ; Y monter.

## Le tutoriel des commandes (11/10)

`ui/controls_tutorial.gd` : trois pages (se déplacer et agir ; ton équipe et l'île ; menus et
combat) avec les vraies images du clavier **ou** de la manette, qui changent sous les yeux du joueur
dès qu'il passe de l'un à l'autre. S'ouvre tout seul, **une fois par partie** (drapeau
`tuto_commandes`), quand Chloé est libre depuis 1,5 s (donc après les premières scènes). Souris :
Suivant / Précédent / Passer ; manette : ◀ ▶ ou LB / RB, A, B ; clavier : ← →, Entrée, Échap. Se
rouvre depuis Paramètres → Commandes → « Revoir le tutoriel des commandes ». Test : `test_tuto.gd`.

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
2. **Clic de souris dans le monde** : aujourd'hui la souris ne sert qu'aux menus et au zoom.
   À décider avec Greg : cliquer pour aller quelque part / pour examiner ?
3. **Alléger l'export Windows** : le preset embarque encore `addons/*` (350 Mo) et
   `assets/models3d/*` (114 Mo), qui ne servent qu'à la 3D en pause. À faire le jour où on
   reconstruit l'exe (voir la règle « exe sur demande »).
4. **Raccourcis clavier** des écrans (Dinodex, carte, boutique) : flèches et Entrée partout.
5. La fenêtre ne retient pas sa taille ni sa position entre deux parties (seul le plein écran l'est).
