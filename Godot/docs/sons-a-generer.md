# Sons à générer — chapitres 7, 8 et 9

État au 19/10 : le quota ElevenLabs gratuit est épuisé (**6 crédits restants sur 10 000**, remise à zéro vers le 26 du mois).
Les bruitages ci-dessous sont prêts à lancer par `tools/audio-jobs/chapitres_7_9.mjs` (voir plus bas) ; aucun n'est encore généré.

## 1. Musique (non générable avec ElevenLabs gratuit : Stable Audio ou autre)

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

## 2. Bruitages ElevenLabs en attente (quota)

Script : `tools/audio-jobs/chapitres_7_9.mjs` (génère les MP3 bruts dans `tools/sounds/`, convertit en .ogg dans `assets/audio/…`,
n'écrase rien, plafond 3000 crédits, ~720 crédits pour la liste). Depuis la racine du dépôt, après le 26 :
`AUDIO_MODULES=<dossier node_modules avec mpg123-decoder et wasm-media-encoders> node Godot/tools/audio-jobs/chapitres_7_9.mjs`

| Fichier | Durée | Boucle | Branchement prévu |
|---|---|---|---|
| `ambience/lave-bouillonne.ogg` | 10 s | oui | lit « feu » 0.3 de `coulees_lave` |
| `ambience/volcan-grondement.ogg` | 10 s | oui | `sanctuaire_magma` (appel sourd), `champs_cendres`, `terre_apex` |
| `ambience/forge-ronfle.ogg` | 10 s | oui | lit « feu » 0.45 de `forges_ombre` |
| `ambience/vent-hauteurs.ogg` | 10 s | oui | lit « monts » de `cieux` |
| `ambience/forge-eteinte.ogg` | 4 s | non | scène de la forge qui s'éteint (aucune constante aujourd'hui) |
| `cries/souverain-grondement.ogg`, `cries/souverain-souffle.ogg` | 4 s | non | scène du Souverain (aucune constante aujourd'hui) |
| `cries/tyran-magma-rugissement.ogg` | 4 s | non | T-Rex de Magma (aucune constante aujourd'hui) |
| `sfx/ambre-craque.ogg`, `sfx/portail-pierre.ogg`, `sfx/coeur-ambre-pose.ogg`, `sfx/tasse-porcelaine.ogg`, `sfx/pas-cendre.ogg` | 2-5 s | non | aucune constante aujourd'hui : à appeler depuis les scènes quand Greg le décide |
