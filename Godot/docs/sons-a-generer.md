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

**Stable Audio Open 1.0 essayé le 19/10 : résultat jugé insuffisant par Greg (timbre d'orgue, 3 accords) ; musiques écartées
(rangées dans `tools/sounds/musique_sa_ecartee/`, ignoré par Godot) ; repli : pistes existantes du jeu.** Aucune musique ne
reste à brancher : les zones prennent le premier fichier existant de leur liste `MUSIC` (monts, desert, ombre…). Le tableau
et les prompts ci-dessous restent comme cahier des charges si une autre source de musique est trouvée.

Dossier : `assets/audio/music/`, format **.ogg**, stéréo. Le jeu cherche ces noms dans l'ordre de `MUSIC` des générateurs
`tools/zones/*.gd` ; tant qu'un fichier manque, il prend le suivant de la liste (repli ci-dessous). Style des pistes existantes
(`monts`, `desert`, `ombre`, `alpha`, `repos`…) : fantasy orchestral doux / chiptune orchestral, mélodique, sans voix.

| Fichier exact | Durée | Boucle | Lieu / scène | Repli actuel |
|---|---|---|---|---|
| `cieux.ogg` | 90-120 s | oui | Cieux Éternels (ch. 7) | `monts.ogg` |
| `nids_geants.ogg` | 60-90 s | oui | Nids géants (ch. 7) | `cieux.ogg` puis `monts.ogg` |
| `arche_du_vent.ogg` | 60-90 s | oui | Arche du Vent (ch. 7) | `cieux.ogg` puis `monts.ogg` |
| `volcan.ogg` | 90-120 s | oui | Champs de cendres et coulées (ch. 8) | `desert.ogg` |
| `forges_ombre.ogg` | 60-90 s | oui | Forges de l'Ombre Noire (ch. 8) | `ombre.ogg` |
| `terre_apex.ogg` | 90-120 s | oui | Terre des Apex, spirale du cratère (ch. 9) | aucune musique (zone muette) |
| `coeur_apex.ogg` | 60-90 s | oui | Cœur des Apex, salle ronde (ch. 9) | aucune musique (zone muette) |
| `souverain.ogg` (optionnel, à brancher ensuite) | 60-90 s | oui | combat du Souverain (ch. 9) | `alpha.ogg` |
| `jetee.ogg` (optionnel, à brancher ensuite) | 45-60 s | oui | jetée de Port-Ambre, épilogue | thème de la barque du prologue (`titre.ogg`) s'il existe, sinon silence |

`porte_cratere.ogg` et `sanctuaire_magma.ogg` sont cités dans `MUSIC` mais le silence est voulu (torches et vent ; « trop calme ») : ne pas les générer.

Prompt négatif commun (Stable Audio) : `vocals, singing, choir lyrics, spoken words, drums loud, heavy metal, distortion, horror, scary, sudden loud hits, sound effects, noise, clipping`

Prompts (anglais, à coller tels quels) :

- **cieux** : `Gentle fantasy orchestral, soaring and airy, 80 BPM, harp arpeggios, soft strings pad, light flute melody, glockenspiel sparkles, sense of flying high above the clouds, wonder and calm, warm, seamless loop, no vocals`
- **nids_geants** : `Soft fantasy orchestral, tender and curious, 72 BPM, celesta and pizzicato strings, warm low woodwinds, a hint of protective lullaby, giant bird nests high on cliffs, gentle wind feel, seamless loop, no vocals`
- **arche_du_vent** : `Slow majestic fantasy orchestral, 66 BPM, solemn french horn and deep warm strings, airy choir-free pads, ancient stone arch singing in the wind, awe and quiet tension but not scary, seamless loop, no vocals`
- **volcan** : `Warm low fantasy orchestral, 70 BPM, slow pulse of low cellos and soft taiko-like drum, distant brass swells, ash and heat, mystery and quiet danger softened for a family game, seamless loop, no vocals`
- **forges_ombre** : `Dark but gentle fantasy, 76 BPM, rhythmic soft anvil-like percussion, low brass drones, muted strings, glowing embers, a stern hidden camp of blacksmiths, tension without horror, seamless loop, no vocals`
- **terre_apex** : `Sparse mysterious fantasy ambience with melody, 60 BPM, deep sustained cello and low piano notes, black volcanic rock, slow breathing rhythm, vast and solemn, quiet wonder, seamless loop, no vocals`
- **coeur_apex** : `Slow emotional fantasy orchestral, 56 BPM, round open-sky amber chamber, glassy bell tones, warm strings swelling gently, hopeful and sacred, seamless loop, no vocals`
- **souverain** : `Epic but family-friendly fantasy boss theme, 100 BPM, powerful low strings and brass, steady war drums, noble and sorrowful rather than evil, a huge frightened creature, seamless loop, no vocals`
- **jetee** : `Tender nostalgic fantasy theme, 68 BPM, solo acoustic guitar and soft strings, sea breeze, reunion and farewell on a wooden pier at dusk, warm and hopeful, seamless loop, no vocals`

Consignes de fabrication : générer **2 à 3 variantes** par piste et garder la meilleure ; normaliser autour de **-16 LUFS** ;
convertir en .ogg (ffmpeg n'est **pas** installé sur ce PC : `ffmpeg -version` échoue ; sinon `wasm-media-encoders` comme dans
`tools/prepare-ambience.mjs`) ; nommer **exactement** comme ci-dessus ; déposer dans `assets/audio/music/` ; le jeu les prend au
prochain lancement (lancer un `--import` pour les `.import`). Vérifier que la boucle ne claque pas à la couture.

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
