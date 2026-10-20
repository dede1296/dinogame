# Audit des licences d'Ambrelune

Fait le 19/10/2026, à partir du dépôt (fichiers LICENSE, README, SOURCES, docs, historique git) et, pour les outils d'IA,
des conditions en ligne lues le même jour. Rien n'est inventé : quand le dépôt ne dit pas, c'est écrit « source inconnue : à retrouver ».
Crédits affichables : [credits.md](credits.md). Données pour l'écran : `data/credits_data.gd`.

Périmètre livré : export Windows et Android (`export_presets.cfg`) avec `export_filter="all_resources"` et
`exclude_filter = tools/*, docs/*, addons/*, world3d/*, assets/models3d/*` (+ `.mcp.json` sous Windows).
Donc **livré** : tout le reste de `Godot/`, dont `assets/art`, `assets/audio`, `assets/fonts`, `assets/models` (volumes et maison 3D),
`demo/`, `gddraw/`, et tout ce qui n'est pas dans la liste. **Pas livré** : `addons/`, `world3d/`, `assets/models3d/`, `tools/`, `docs/`,
et tout ce qui est hors de `Godot/` (`assets3d_src/`, `Unreal/`, `generated_imgs/`).

## 1. À vérifier par Greg (en tête)

| # | Point | Pourquoi | Action |
|---|---|---|---|
| V1 | **ElevenLabs, plan gratuit** : voix du prologue (`audio/voices/*`), cris (`audio/cries/*` mp3), ambiances et bruitages `.mp3` d'origine | Conditions d'utilisation (elevenlabs.io/terms-of-use, §1(c)) : le plan gratuit est « non commercial ». Rien sur l'attribution dans ces conditions (la page tarifs peut en exiger une : non lue). | Si le jeu est gratuit et non monétisé : sans doute acceptable ; s'il est vendu : plan payant, ou remplacer. Relire la page de tarifs. |
| V2 | **Stable Audio Open 1.0** (sons des chapitres 7-9, générés en local via ComfyUI) | Stability AI Community License : « Powered by Stability AI » à afficher, licence + NOTICE fournis, inscription pour l'usage commercial, plafond 1 M$ de revenu annuel. Le texte lu est le contrat général ; la fiche du modèle (Hugging Face) peut ajouter des conditions. | Relire la fiche du modèle ; s'inscrire si vente ; garder « Powered by Stability AI » dans les crédits. |
| V3 | **nano-banana (Gemini d'image, Google)** : toutes les images | Conditions de l'API Gemini et usage commercial des sorties non lus ici ; filigrane invisible SynthID. | Lire les conditions Google AI Studio/Gemini API. |
| V4 | **Export : `demo/` (LimboAI, CC BY 4.0) est livré** (non exclu, 4,5 Mo, aucun script du jeu ne s'y réfère) | Crédit obligatoire à Aleksandra Snitsaruk si livré. | Ajouter `demo/*` (et `gddraw/*`) à `exclude_filter`, ou garder le crédit. |
| V5 | **Autoloads vers `addons/`** (`MCPRuntimeServer`, `PhantomCameraManager`) alors que l'export exclut `addons/*` | Ce n'est pas une licence mais l'exe risque d'échouer ou de journaliser des erreurs au démarrage. | Tester l'exe ; retirer les autoloads de dev de l'export. (Note : `docs/plugins-installes.md` dit que l'export embarque `addons/` : c'est périmé.) |
| V6 | **Pack Kenney des bruitages `.wav`** (`audio/sfx/bump, chop, coins, door_open, glass, hit_0, hit_1, item, latch, page, rock_heavy, slice`) | L'historique git (« sons Kenney », « Kenney.nl, CC0 ») le dit, mais aucun fichier de licence ni nom de pack n'est dans le dépôt. | Retrouver le pack (Impact Sounds, RPG Audio, Interface Sounds ?) et ajouter son `License.txt`. |
| V7 | **Origine des `.mp3` de `audio/sfx/`** : `colonne_bulles, courant, creuser, feuillage, galet, pierre, plongee, remontee` | Aucune trace écrite ; format et chaîne d'outils (`gen-sound.mjs`) indiquent ElevenLabs. | Confirmer ; même régime que V1. |
| V8 | **Musiques** (`audio/music/*.ogg`, 15 pistes) | Enregistrées depuis le synthétiseur de la version Phaser (`render-phaser-music.mjs`, code `nouveau/src/audio/music.js`, écrit avec Claude). Aucun échantillon tiers vu, mais le code supprimé n'est plus relu ici. | Confirmer qu'aucune mélodie n'est reprise d'une œuvre existante. |
| V8b | **Rendu des 13 musiques composées** : GeneralUser GS v2.0.3 (SoundFont) + FluidSynth (LGPL) | Licence de la SoundFont : usage libre, y compris commercial ; l’auteur ne peut garantir l’origine de chaque échantillon (comme toute banque libre). | Rien à faire sans monétisation ; sinon relire la licence. |
| V9 | **ComfyUI / modèles** : SD 1.5 + LoRA + IPAdapter (repli, `maison_3d`), Depth Anything 3 (cartes de profondeur des reliefs) | Licences des modèles non vérifiées (SD 1.5 : CreativeML OpenRAIL-M ; certains modèles Depth Anything sont non commerciaux). | Vérifier ce qui est réellement dans le jeu (liste « À refaire » de `direction-artistique.md`) et la licence de chaque modèle. |
| V10 | **Plugins `controller_icons`, `guideCS`, `reactive_signal`, `waterways`, `dreadpon.spatial_gardener`** : pas de fichier de licence dans `addons/` | Non livrés, donc sans effet pour la sortie. | Aucune action tant qu'ils ne sont pas livrés. |
| V11 | Le dépôt contient `dinogame-release.keystore` à la racine | Hors licences, mais à ne jamais publier ni embarquer. | Vérifier qu'il est ignoré par git. |

## 2. Éléments livrés avec le jeu

| Élément | Auteur | Licence | Source | Attribution obligatoire ? | Statut | Utilisation |
|---|---|---|---|---|---|---|
| Godot Engine 4.7.2 | Godot Engine contributors ; Juan Linietsky, Ariel Manzur | MIT | godotengine.org | **Oui** : licence + copyright fournis (voir §4) | Certain | Moteur |
| Bibliothèques tierces de Godot (FreeType, HarfBuzz, libvorbis, libogg, zlib, mbedTLS, etc.) | divers | divers (FTL/MIT/BSD/zlib/Apache…) | `Engine.get_copyright_info()` | **Oui** : textes fournis | Certain | Moteur |
| Caveat.ttf | The Caveat Project Authors (github.com/googlefonts/caveat) | SIL OFL 1.1 | `assets/fonts/Caveat-OFL.txt` | Garder le fichier OFL ; crédit conseillé | Certain | Police manuscrite (lettres, carnets) |
| Pas `footstep00…09.ogg` | Kenney Vleugels, « RPG Audio » | CC0 | `assets/audio/footsteps/LICENSE-kenney.txt` ; kenney.nl | Non (courtoisie) | Certain | Pas de Chloé |
| Bruitages `.wav` (12 fichiers, voir V6) | Kenney (kenney.nl) | CC0 | historique git ; pack à retrouver | Non (courtoisie) | Pack à vérifier | Portes, coups, pièces, pages, pierre |
| Icônes `assets/art/ui/prompts/` | Kenney, « Input Prompts » | CC0 | `LISEZ-MOI.md` ; kenney.nl/assets/input-prompts | Non (courtoisie) | Certain | Invites de touches et de manette |
| Assets graphiques de la démo LimboAI (`demo/assets/*.png, svg`) | Aleksandra Snitsaruk © 2024 | CC BY 4.0 | `demo/LICENSE_ASSETS.md` | **Oui** si livré | Livré par défaut : voir V4 | Aucun (non utilisé par le jeu) |
| Code du dossier `demo/` (LimboAI) | LimboAI contributors | MIT (licence du plugin) | `addons/limboai/LICENSE.md` | Oui si livré | Voir V4 | Aucun |
| Polices `demo/assets/fonts/junction_bold.otf`, `knewave_regular.ttf` | Junction (The League of Moveable Type), Knewave (Tyler Finck) | OFL probable, texte absent du dépôt | source inconnue : à retrouver | Joindre OFL si livrées | À vérifier | Aucune (démo) |
| Musiques `audio/music/*.ogg` (15) | Greg + Claude (synthé du jeu) | Propres à Ambrelune | `tools/render-phaser-music.mjs` | Non | Voir V8 | Musiques de zones et de scènes |
| Ambiances `.mp3/.ogg` d'origine, cris `.mp3`, pas de neige/glace, voix | ElevenLabs (génération) | Conditions ElevenLabs (plan gratuit) | `tools/gen-sound.mjs`, `scripts/gen-voices.mjs` (supprimé du dépôt, voir git) | Aucune trouvée ; usage non commercial | À vérifier V1 | Ambiances, cris des dinos, voix du prologue |
| Sons ch. 7-9 (`forge-*`, `lave-bouillonne`, `vent-hauteurs`, `volcan-grondement`, 3 cris, `cendre00-05`, 4 sfx) | Stable Audio Open 1.0 (Stability AI), via ComfyUI | Stability AI Community License | `tools/audio-jobs/stable_audio_local.mjs`, `stable_audio_log.json` | **Oui** : « Powered by Stability AI » + licence + NOTICE | Certain (conditions à relire V2) | Zones volcan, forges, Apex ; non encore tous branchés |
| `rafale-grave.ogg` | dérivé de `rafale.ogg` (ElevenLabs) | idem | `docs` / `progress.md` | idem | V1 | Vent, désert |
| Images (`assets/art/**`, `generated_imgs/` hors export) | nano-banana (Gemini, Google) sous la direction de Greg | Conditions Google | `docs/direction-artistique.md` | À vérifier | V3 | Tous les décors, personnages, dinos |
| `assets/models/*.glb` (volumes de maisons, maison 3D) | Greg/Claude, textures nano-banana ; maison 3D : ComfyUI SD 1.5 | Propres + V3 + V9 | `direction-artistique.md` | À vérifier | V3, V9 | Reliefs des bâtiments 2,5D |

## 3. Éléments NON livrés (information)

### Plugins Godot (`addons/*`, exclus de l'export)
Aucun n'est livré. Utiles pour l'inventaire :

| Plugin | Auteur | Licence |
|---|---|---|
| gdUnit4 | Mike Schulze | MIT |
| limboai | Serhii Snitsaruk et contributeurs | MIT |
| phantom_camera | Marcus Skov | MIT |
| godot_mcp_toolkit | NPGameDev | MIT |
| godot_ai | Godot AI contributors | MIT |
| GDDraw | ArdonyxApps | MIT |
| GDQuest_GDScript_formatter | GDQuest | MIT |
| PlantGenerator | Vilém Janota | MIT |
| curved_lines_2d | René van der Ark, Mark Hedberg | MIT |
| debug_menu | Hugo Locurcio | MIT |
| fightengine | Fxll3n | MIT |
| gaussian-blur | vilmt | MIT |
| lens_effects | ARez | MIT |
| lit | Shawn Deprey | MIT |
| nodecam | Xavier Alvarez | MIT |
| noise4d | Juan Ignacio Fulponi | MIT |
| proton_scatter | HungryProton | MIT |
| ragdoll_generator | Manik Sharma | MIT |
| saltmire_fx / hitbox / spark / trail | Saltmire | MIT |
| simplegrasstextured | IcterusGames | MIT |
| sky_3d | Cory Petkovsek et contributeurs | MIT |
| terrain_3d | Cory Petkovsek, Roope Palmroos | MIT |
| tressfx | Ismail Ivanov | MIT |
| vision2d | Peter Kiš | MIT |
| ya3 | LiteralSoofa | MIT |
| softbody2d | Dragos Daian | MIT |
| RoxyVector2D, compositespritesheetgenerator | (voir fichier) | Apache 2.0 |
| better-terrain, rope2d | (voir fichier) | Unlicense |
| modular_builder_en | Michel Savadim | CC0 |
| rig_eye_2d | (voir fichier) | CC0 |
| procedurallyphysicalecologicalplanet | chlingzool | Clear BSD |
| **vfx_2d** | heyheythere (itch.io) | **CC BY 4.0** : crédit exigé SI livré |
| **blendkit** | (voir fichier) | **GPL v2** : à ne jamais embarquer |
| **popcornfx** | Persistant Studios | PopcornFX Community License (conditions propres) |
| controller_icons, guideCS, reactive_signal, waterways, dreadpon.spatial_gardener | — | pas de fichier de licence (V10) |

Attention : si un plugin devient livré (ex. Phantom Camera, LimboAI), ajouter sa licence MIT (copyright + permission) aux crédits.

### Assets 3D sources (hors export : `assets3d_src/`, `world3d/`, `assets/models3d/`)
| Élément | Auteur | Licence | Source |
|---|---|---|---|
| Nature Kit 2.1 | Kenney | CC0 | `assets3d_src/nature/kenney/License.txt` |
| Furniture Kit, Food Kit | Kenney | CC0 | `assets3d_src/props_pending/SOURCES.md` (kenney.nl) |
| Universal Animation Library, Universal Base Characters, Stylized Nature MegaKit (versions gratuites) | Quaternius | CC0 | `License_Standard.txt` (quaternius.com) |
| Dinos Quaternius (6 GLB) | Quaternius | CC0 présumé, fichier de licence absent à cet endroit | `assets3d_src/dinos/quaternius` |
| Gobkit Free Dinosaur Pack, Free Animal Pack | Gobkit (Alsomind Tech) | CC0 | `assets3d_src/dinos/gobkit/*/LICENSE.txt` |
| Frosted Glass (shader) | Binbun3D | CC0 (nom suggéré) | `assets3d_src/packs-deverses/shader/license.txt` |
| mesh2motion (dragon, kaiju, t-rex .blend) | source inconnue : à retrouver | inconnue | `assets3d_src/dinos/mesh2motion` |
| Packs 2DPIXX | 2DPIXX | arrivés vides | non utilisés |

Si la version 3D reprend et est livrée, la 3D utilise surtout de la CC0 : aucune attribution obligatoire, mais citer Kenney, Quaternius et Gobkit par courtoisie.
`Unreal/` : registre `Unreal/docs/licences.csv` (mis de côté, non livré, non audité ici).

## 4. Moteur Godot : mentions obligatoires

- Godot est sous licence MIT ; l'export contient du code Godot et de ses bibliothèques tierces. Le texte MIT + le copyright
  « © 2014-présent Godot Engine contributors, © 2007-2014 Juan Linietsky, Ariel Manzur » doivent être fournis avec le jeu.
- À l'exécution : `Engine.get_license_text()` (MIT de Godot), `Engine.get_license_info()` (dictionnaire nom de licence → texte),
  `Engine.get_copyright_info()` (tableau de composants : `name`, `parts[]` avec `files`, `copyright`, `license`),
  `Engine.get_author_info()` et `Engine.get_donor_info()` (facultatifs). C'est la voie la plus simple pour un écran « Licences ».
- À fournir aussi en fichier à côté de l'exe (`LICENSES-GODOT.txt`) : copie de `LICENSE.txt` et `COPYRIGHT.txt` du dépôt Godot 4.7.

## 5. Outils d'IA (conditions lues le 19/10/2026)

| Outil | Usage | Conditions | Obligation |
|---|---|---|---|
| Claude (Anthropic) | code, écriture, scripts | Greg reste l'auteur de la direction ; les sorties appartiennent à l'utilisateur selon les conditions d'Anthropic | Aucune d'attribution ; la mention « Outils » est volontaire |
| nano-banana (Gemini, Google) | toutes les images | non lues ici | V3 |
| Stable Audio Open 1.0 (Stability AI) | sons ch. 7-9 | Community License : sorties appartenant à l'utilisateur ; sous 1 M$ de revenu annuel ; « Powered by Stability AI » ; licence et NOTICE ; ne pas entraîner de modèle avec les sorties ; politique d'usage acceptable | Voir V2 |
| ElevenLabs (plan gratuit) | bruitages, cris, voix | §1(c) : plan gratuit = usage non commercial ; §4 : l'utilisateur garde ses droits sur la sortie, sous réserve des conditions ; sorties pouvant ne pas être uniques | V1 |
| ComfyUI | exécute Stable Audio et les retouches d'images | logiciel libre (GPL-3.0) : n'impose rien sur les sorties | Modèles : V9 |
