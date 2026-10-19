# Sons à générer — chapitres 7, 8 et 9

> **RÈGLE DE NIVEAU (Greg)** : tout son produit se normalise sur les éléments de **même catégorie** déjà présents dans le jeu.
> Référence mesurée : `tools/audio-jobs/levels_reference.json` (`python tools/audio-jobs/levels_reference.py`), RMS actif
> (fenêtres de 50 ms > -50 dBFS) et pic par catégorie (ambience-bed, ambience-call, music, cries, sfx, footsteps/<famille>).
> Outil réutilisable : `tools/audio-jobs/normalize_to_category.mjs` (RMS actif = médiane de la catégorie, pic limité à
> min(médiane des pics + 1 dB ; -0,5 dBFS) par soft-clip ; son trop court = calé sur le pic médian). Boucles : fondu enchaîné
> **avant** la normalisation.

État au 19/10 : le quota ElevenLabs gratuit est épuisé (**6 crédits restants sur 10 000**, remise à zéro vers le 26 du mois).
Les bruitages ci-dessous sont prêts à lancer par `tools/audio-jobs/chapitres_7_9.mjs` (voir plus bas) ; aucun n'est encore généré.

## 1. Musique

**Composées avec le synthétiseur d'origine du jeu, 19/10 ; Stable Audio écarté** (essayé le 19/10 : « on dirait un orgue
sur lequel on fait 3 accords » ; ses pistes sont rangées dans `tools/sounds/musique_sa_ecartee/`, ignoré par Godot). Les
musiques sont écrites note par note et rendues par le synthétiseur Web Audio de la version Phaser (celui des 15 musiques
existantes), retrouvé dans l'historique git : **`tools/music-synth/`** (à la racine du dépôt ; `README.md` : rendre une
piste). Partitions, mesures et ce qui reste incertain à l'oreille : **[`musiques-composees.md`](musiques-composees.md)**.

Dossier : `assets/audio/music/`, .ogg stéréo 48 kHz. Niveau : RMS actif réglé sur la médiane des musiques du jeu (-14,5 dB),
pic ≤ -0,5 dBFS ; boucles sans couture (vérifiées). Les zones cherchent ces noms dans l'ordre de `MUSIC` des générateurs
`tools/zones/*.gd` ; tant qu'un fichier manque, elles prennent le suivant de la liste.

| Fichier exact | État | Lieu / scène | Avant (repli) |
|---|---|---|---|
| `cinematique_intro_a.ogg` | **fait** (46 s) | intro, I-01 → I-05 | `titre.ogg` |
| `cinematique_intro_b.ogg` | **fait** (40 s) | intro, I-06 → carton | `titre.ogg` |
| `cinematique_fin.ogg` | **fait** (98 s) | fin, F-01 → F-09 | `titre.ogg` |
| `credits.ogg` | **fait** (boucle 92 s) | crédits | `titre.ogg` |
| `cieux.ogg` | **fait** (boucle 72 s) | Cieux Éternels (ch. 7) ; aussi Nids géants et Arche du Vent | `monts.ogg` |
| `volcan.ogg` | **fait** (boucle 78 s) | Champs de cendres et coulées (ch. 8) | `desert.ogg` |
| `terre_apex.ogg` | **fait** (boucle 69 s) | Terre des Apex, spirale du cratère (ch. 9) | aucune musique |
| `coeur_apex.ogg` | **fait** (boucle 72 s) | Cœur des Apex, salle ronde (ch. 9) | aucune musique |
| `nids_geants.ogg` | **fait** (boucle 70 s) | Nids géants (ch. 7) : majestueux et chaleureux, choral de cors, le vent | `cieux.ogg` |
| `arche_du_vent.ogg` | **fait** (boucle 72 s) | Arche du Vent (ch. 7) : suspendu, venteux ; Maïa et l'Ombre en filigrane | `cieux.ogg` |
| `forges_ombre.ogg` | **fait** (boucle 71 s) | Forges de l'Ombre Noire (ch. 8) : marche lourde et un peu comique, puis l'éclaircie | `ombre.ogg` |
| `souverain.ogg` | **fait** (boucle 94 s), **branché** | combat du Souverain (ch. 9) : choral des Alphas, Hélène au milieu | `alpha.ogg` |
| `jetee.ogg` | **fait** (boucle 80 s), **branché** | jetée de Port-Ambre, épilogue : valse musette, le thème de Chloé, « BARC » | musique de la zone |

Les cinématiques, le combat du Souverain et la jetée prennent leurs pistes tout de suite ; **les zones seulement à leur
prochaine génération** (liste dans `musiques-composees.md` § Ce qui change dans le jeu). `porte_cratere.ogg` et `sanctuaire_magma.ogg` sont cités dans `MUSIC`
mais le silence est voulu (torches et vent ; « trop calme ») : ne pas les faire.

Fabriquer une piste : écrire `tools/music-synth/scores/<nom>.js` (dans la palette et avec les leitmotivs du jeu, voir
`musiques-composees.md`), `node render.mjs <nom>` (niveau et boucle réglés tout seuls), `python analyze.py seam/levels`,
puis `--import` sous verrou.

## 2. Bruitages, ambiances et cris : FAITS en local (Stable Audio Open 1.0 via ComfyUI, gratuit)

Script : `tools/audio-jobs/stable_audio_local.mjs` (ComfyUI sur 127.0.0.1:8188, un job à la fois ; 2 prises par son, graine
suivante si quasi muet, journal dans `tools/audio-jobs/stable_audio_log.json`, MP3 bruts dans `tools/sounds/sa/` ; reprend sans
refaire ; `REDO=1` refait les .ogg depuis les MP3 sans Stable Audio). `chapitres_7_9.mjs` (ElevenLabs) n'est plus nécessaire.
Commande : `AUDIO_MODULES=<node_modules> SA_WORKFLOW=<api_prompt.json> node tools/audio-jobs/stable_audio_local.mjs sfx`
(la musique n'est jamais lancée par défaut).

| Fichier | Boucle | Branchement |
|---|---|---|
| `ambience/lave-bouillonne.ogg` | oui | `coulees_lave` (remplace le lit « feu » 0.3), dans `data/ambience_db.gd` |
| `ambience/volcan-grondement.ogg` | oui | `sanctuaire_magma`, `champs_cendres`, `terre_apex` (lit ajouté) |
| `ambience/forge-ronfle.ogg` | oui | `forges_ombre` (remplace le lit « feu » 0.45) |
| `ambience/vent-hauteurs.ogg` | oui | `cieux` (lit principal, `monts` en soutien) |
| `ambience/forge-eteinte.ogg` | non | scène de la forge qui s'éteint : **aucune constante encore** |
| `cries/souverain-grondement.ogg`, `cries/souverain-souffle.ogg`, `cries/tyran-magma-rugissement.ogg` | non | **aucune constante encore** (scène du Souverain, T-Rex de Magma) |
| `sfx/ambre-craque.ogg`, `sfx/portail-pierre.ogg`, `sfx/coeur-ambre-pose.ogg`, `sfx/tasse-porcelaine.ogg` | non | **aucune constante encore** : à appeler depuis les scènes |
| `footsteps/cendre00..05.ogg` | non | pas sur la cendre (0,3 s, découpés de prises Stable Audio) : à brancher dans `actors/player.gd` (`step_kind` + `_play_step`, comme `neige`) ; non branchés |

Limites : sons non écoutés par l'auteur du script (mesures seulement) ; `coeur-ambre-pose` reste un peu plus faible que la
médiane des sfx (carillon très épars, pic déjà à -0,4 dBFS).
