# Chapitre 7 — Les Cieux Éternels : plan partagé des quatre agents

> Écrit le 11/10/2026. Contrat commun : chaque agent lit ce fichier d'abord, reste dans SES fichiers,
> et n'invente pas de noms en dehors de la table des contrats. Le chef d'équipe (moi) intègre, applique
> les `patch_*.md`, commite et teste en jeu. Source de l'histoire : `docs/histoire.md` § Chapitre 7
> (à étoffer par l'agent histoire), `docs/bestiaire.md` § Cieux, `docs/mecaniques.md` (Vol), `docs/lore.md`.

## Décisions de Greg (11/10)
1. **La scène du masque** (Isaure retire son masque, Maïa « Maman. Arrête. ») est écrite par l'agent
   histoire (modèle Fable), avec plusieurs passes et autocritique ; Greg la relira.
2. **Le Vol = un voyage où elle veut** : Chloé, sur un grand ptérosaure muni du harnais de vol, choisit
   sa destination **n'importe où sur la carte des régions déjà visitées** (pas seulement des escales
   fixes) ; elle s'y rend par une courte scène de vol, et atterrit au point praticable le plus proche.
   Ce n'est PAS un déplacement libre (pas de contrôle manuel en vol). Même famille que le Grand Voyageur
   (`story/voyage.gd`) et la barque (`story/barque.gd`) mais avec une carte pour choisir le point.
3. **Les sprites suivent la règle des mouvements** (`docs/sprites-mouvements.md`) : tout ce qui vole
   a profil + face + dos ; Chloé en vol aussi. Images par nano-banana : **si les crédits sont épuisés,
   s'arrêter sur la tâche d'image, finir tout le reste, et le dire clairement dans le rapport** (pas de repli
   silencieux ; un repli ComfyUI n'est permis que s'il est noté dans `docs/direction-artistique.md
   § À refaire avec nano-banana`).
4. **Le vêtement chaud** : même règle que les Monts (`Region.cold`, manteau de duvet, Roc « Où trouver un
   vêtement chaud ? » — voir la mécanique de `docs/mecaniques.md` l. ~216 et ~235).

## Contrats de noms (ne pas en sortir)

| Quoi | Identifiant |
|---|---|
| Zones | `cieux` (pitons, ponts de lianes, mer de nuages), `nids_geants` (le sanctuaire du Quetzalcoatlus Roi), `arche_du_vent` (le sommet, la scène du masque) |
| Dossier des scènes | `Godot/regions/cieux/` (`cieux.tscn`, `nids_geants.tscn`, `arche_du_vent.tscn`), générées par `tools/zones/cieux.gd`, `nids_geants.gd`, `arche_du_vent.gd` |
| Espèces (`data/species/<id>.tres`) | `rhamphorhynchus`, `tapejara`, `tupandactylus`, `hatzegopteryx`, `quetzalcoatlus` (l'Alpha « Quetzalcoatlus Roi » est cette espèce, rencontre Alpha) |
| Objets | `sceau_cieux` (le Sceau), `harnais_vol` (le harnais de vol, fabriqué par Joss) |
| Drapeaux | `cieux_ouverts`, `quetzal_roi_confiance`, `sceau_cieux`, `vol_obtenu`, `arche_piege`, `coeurs_voles`, `masque_tombe`, `page_34`, plus `vol_<zone>` (point de départ connu) si besoin |
| Capacité | `Vol` (déjà dans `data/abilities.gd` ? sinon à ajouter), famille `ptérosaure` |
| Fichiers d'histoire | `story/cieux.gd` (arrivée, ascension), `story/cieux_nids.gd` (le Roi, le Sceau, le Vol), `story/cieux_arche.gd` (le piège, le masque), `story/cieux_places.gd` (positions), `story/cieux_objectives.gd`, `data/dialogue_cieux.gd` |
| Voyage en vol | `story/vol.gd` (classe `Vol`), écran `ui/vol_screen.gd` (carte de choix) |
| Ambiances/musiques | `cieux`, `nids_geants`, `arche_du_vent` dans `data/ambience_db.gd` ; musiques `assets/audio/music/cieux.ogg` (si possible ; les crédits ElevenLabs sont épuisés : réutiliser/mixer les pistes existantes) |
| Images | `assets/art/dinos/<id>.png` (+ `<id>_face_dos.png` selon la convention existante des autres espèces : la lire sur `pteranodon` et `dimorphodon`), `assets/art/ground/` (`nuages`, `pierre_cieux`, `nid`, `pont_lianes`), `assets/art/props/` (nids géants, pitons, ponts de lianes, harnais), `assets/art/ui/` (`sceau_cieux.png`, `harnais_vol.png`, `meteo_vent.png`), `assets/art/battle/cieux.jpg`, personnages `isaure_sans_masque.png` (4 directions + assise) et `maia_arche.png` si nécessaire, `chloe_vol.png` (en selle sur un ptérosaure, profil/face/dos) |

## Propriété des fichiers (JAMAIS deux agents sur le même fichier)

| Agent (modèle) | Possède | Peut seulement signaler (patch) |
|---|---|---|
| **CARTE** (opus) | `tools/zones/cieux*.gd`, `tools/zones/nids_geants.gd`, `tools/zones/arche_du_vent.gd`, `regions/cieux/*`, `story/cieux_places.gd`, le raccord côté Monts (sortie vers les Cieux, **un seul ajout** dans `tools/zones/monts.gd` + régénération de `regions/monts/monts.tscn` en vérifiant par `git diff` qu'il n'y a que ce nœud) | `world/world.gd` (ZONES), `ui/zone_map.gd` (ZONE_NAMES), `data/atlas_db.gd`, `data/dex_places.gd`, `data/habitat…` : `patch_carte.md` |
| **HISTOIRE** (fable) | `docs/histoire.md` (§ Ch. 7 + journal p. 34), `story/cieux.gd`, `cieux_nids.gd`, `cieux_arche.gd`, `cieux_objectives.gd`, `data/dialogue_cieux.gd`, tests de scène | `story/story.gd` (événements), `story/objectives.gd`, `story/ask.gd`, `data/dialogue_db.gd`, `data/dialogue_monts.gd` (Maïa/Roc après le ch. 6 → renvoi aux Cieux) : `patch_histoire.md` |
| **MÉCANIQUES** (opus) | `data/species/` (les 5 nouvelles fiches), `data/moves_db.gd`/`abilities.gd` (Vol), `data/items_db.gd` (Sceau, harnais, boutique de Joss), `story/vol.gd`, `ui/vol_screen.gd`, `actors/` (Chloé en vol : la monture ptérosaure, pose), `data/ambience_db.gd`, équilibrage 38-44, `battle/` (fond, vent), tests | `world/world.gd`, `ui/*` communs : `patch_mecaniques.md` |
| **IMAGES** (sonnet) | `tools/art-jobs/cieux*.mjs`, `assets/art/**` (nouveaux fichiers seulement), `docs/direction-artistique.md` (§ Cieux, § À refaire) | — |

Les agents NE modifient PAS les fichiers communs (`world.gd`, `story.gd`, `objectives.gd`, `ask.gd`, `dialogue_db.gd`,
`zone_map.gd`, `atlas_db.gd`) : ils écrivent un fichier `scratchpad/ch7/patch_<agent>.md` listant, pour chaque
changement, le fichier, le texte à CHERCHER et le texte de REMPLACEMENT (je les applique par script et teste).

## Règles communes
- **Pas de commit, pas de push.** Français partout (textes du jeu, commentaires côté joueur, rapports) ; « crique » jamais
  « anse » ; ton chaleureux et drôle, rien d'effrayant (le ch. 7 est le plus grave du jeu : la scène du masque est calme, triste, jamais cruelle).
- **Tests ciblés** : ne tester que ce que le changement touche ; tout test affiche en petit, pendant tout son déroulement, ce qu'il
  vérifie (`ShotCaption`, voir `tools/shot_caption.gd`) ; poser les drapeaux `prologue_done` et `tuto_commandes` dans un test (sinon le tutoriel
  couvre l'écran) ; un script de test est compilé avant les autoloads (appels dynamiques pour tout ce qui lit Game/Quality/Prompts/Screen) ;
  **jamais `auto`** dans un scénario qui passe près d'un PNJ ; les captures utilisent leur propre sauvegarde (jamais celle de Greg).
- **Godot est partagé** : jeu, captures, scénarios se lancent librement ; seul `--import` est exclusif (verrou : `mkdir <scratchpad>/godot_import.lock`
  avant, `rmdir` après, attendre si le dossier existe). Ne jamais tuer tous les processus Godot (`taskkill /IM`) : l'éditeur de Greg est ouvert. Une erreur
  dans un fichier qu'on n'a pas touché = un autre agent l'édite : attendre et relancer.
- **Sprites** : la règle des mouvements (`docs/sprites-mouvements.md`) s'applique à tout ce qui est nouveau. Une nouvelle vue part de la vue existante
  (édition nano-banana), jamais d'une page blanche. Jamais `tools/process-art.mjs` sans nom de sortie.
- **Manette, clavier, souris** : tout écran nouveau est jouable aux trois (`PadFocus.prepare`, `Prompts` pour les icônes — jamais « appuie sur A » en dur) et testé
  dans le style de `tools/test_manette.gd`. Le clic de souris interagit déjà avec ce qui est utilisable.
- **Style** : petites fonctions, constantes nommées, pas de print laissé, pas de dépendance à `addons/`, fichiers < 800 lignes (découper `cieux*.gd` en plusieurs).
- **Rapport final** (court, en français) : fichiers créés/modifiés, contrats respectés ou écartés (pourquoi), résultats de test cités tels quels, ce qui reste,
  le contenu du `patch_<agent>.md`, et tout ce qu'il faut que Greg valide.

## Ordre d'intégration (moi)
1. Les quatre agents travaillent en parallèle. 2. J'applique les patches communs, je `--import` une fois, je régénère, je lance un parcours ciblé du chapitre.
3. Je corrige les raccords (positions, noms, drapeaux), je relis la scène du masque, je commite par lots (carte / histoire / mécaniques / images).
