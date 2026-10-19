# Synthétiseur de musique d'Ambrelune

Le synthétiseur Web Audio de l'ancienne version Phaser (celui qui a produit les 15 musiques de
`Godot/assets/audio/music/`), récupéré dans l'historique git, et un rendu **hors ligne** des partitions.
Hors du projet Godot (rien ici n'est importé par le moteur).

## Rendre une piste

```sh
cd tools/music-synth
npm install                                   # une fois (playwright-core, wasm-media-encoders)
node render.mjs cieux                         # scores/cieux.js → Godot/assets/audio/music/cieux.ogg
node render.mjs cieux --out out/cieux.ogg     # ailleurs (pour écouter avant de livrer)
node render.mjs cieux --force                 # remplacer un .ogg existant (sinon : refus)
node render.mjs cieux --stats                 # statistiques de la partition seulement (accords, motifs…)
node render.mjs cieux --lint                  # notes tenues hors de l'accord de leur mesure (fautes d'écriture ?)
node render.mjs cieux --seamcheck             # boucle : la jonction comparée à un rendu continu de 3 passages
node render.mjs theme:monts --passes 2 --raw  # un thème d'origine, comme à l'époque → out/theme-monts.ogg
```

Le rendu passe par **Edge sans fenêtre** (`playwright-core`, Edge installé avec Windows ; autre chemin :
variable `EDGE`) : une `OfflineAudioContext` joue les instruments d'origine, exactement le graphe Web
Audio de la version Phaser. Compter 20 à 60 s par piste. Le rapport (durée, niveaux, sections) s'écrit
dans `out/<piste>.json`.

**Niveau** (règle de Greg : se caler sur les sons existants de la même catégorie) : le RMS actif
(fenêtres de 50 ms au-dessus de -50 dBFS, mono) est réglé sur la **médiane des musiques du jeu**
(`Godot/tools/audio-jobs/levels_reference.json`, -14,5 dB), avec un limiteur doux à anticipation
(pic ≤ -1 dBFS avant encodage, ≤ -0,5 une fois encodé). `--raw` : pic à -1 dBFS comme les anciens enregistrements.

**Boucles** (`loop: true`) : la partition est jouée deux fois et le second passage est gardé (il
commence avec les queues de réverbération du premier) ; le hasard (cordes pincées, souffle de la
flûte, vélocités) est tiré à l'identique à chaque passage, les notes tombent sur les mêmes
sous-échantillons, la durée est un multiple de 128 échantillons (les blocs du navigateur ; le tempo
bouge de moins de 0,003 %) et le limiteur travaille en boucle : la jonction est exacte (`--seamcheck`).
Le fichier commence une demi-croche avant le premier temps (une levée), pour que l'encodeur ne
rencontre pas d'attaque à son tout premier échantillon.

## Vérifier

```sh
python analyze.py levels "out/*.ogg"           # durée, pic, RMS actif
python analyze.py encseam x.ogg out/x.wav      # jonction après encodage, comparée au signal d'avant (render --wav)
python analyze.py seam out/cieux.ogg           # jonction brute (attention : une attaque au 1er échantillon y ressemble à un clic)
python analyze.py profile out/cieux.ogg 2      # niveau tranche par tranche
python analyze.py compare a.ogg b.ogg          # deux rendus du même thème (décalage, chroma, spectre)
python analyze.py key out/cieux.ogg            # tonalité estimée
```

## Fichiers

- `synth/` — **récupéré tel quel** de `nouveau/` (git `d935f19f^`) : `audio/instruments.js` (les
  instruments ; seule retouche : les tables `SAMPLED`, `DRUMS`, `LIVE` sont exportées), `audio/mixer.js`
  (réverbération), `audio/music.js` (le séquenceur en temps réel du jeu, pour référence),
  `audio/sounds.js`, `data/musicThemes.js` (les thèmes d'origine), `render-phaser-music.mjs`
  (l'ancien enregistreur en temps réel, pour référence).
- `engine/compile.js` — la notation de `music.js` (inchangée) + les sections ; `engine/offline.js` —
  le rendu dans le navigateur ; `engine/instruments-plus.js` — cors, basson, trémolo, violoncelles,
  timbales, nappe « souffle », puis accordéon, violon (`fiddle`), tuba, vent (`wind`, à jouer avec `ring`) et enclume
  (`anvil`) (mêmes recettes que les instruments d'origine) ; `engine/stats.js`.
- `scores/` — les partitions composées (description dans `Godot/docs/musiques-composees.md`).

## Partition

Une partition est une suite de **sections** ; chacune a son tempo (`bpm`, `rit` : facteur de tempo
atteint à la fin, 0,8 = ralentit), sa mesure (`beats`, `sub` pas par temps), ses accords (un par
mesure, notation de `music.js` + `m7b5`, `maj9`, `7sus4`, `dim7`, `add9`… et la basse « D/F# ») et
ses pistes : celles de `music.js` (`chords`, `pattern` avec les degrés 1 3 5 7 8 10 12 et `B` = la
basse de l'accord, `notes`, `drums` avec `r` = roulement) et :

- `line` : une mélodie par durées, mesure par mesure : `"F#5:4 E5:2 D5:2 | E5:2 F#5:2 B4:4"`
  (`r` silence, `-:4` lie, `C5+E5` accord, suffixes `!` accent, `_` doux, `'` piqué) ;
- `strum` : un accord gratté (`d` vers le haut, `u` vers le bas) ;
- options : `vol`, `pan`, `ring`, `legato`, `send` (réverbération), `dyn: [début, fin]` (nuance
  progressive), `transpose`, `lead: true` (mélodie principale, pour les statistiques).

Partition : `loop`, `reverb`, `reverbSeconds`, `reverbDamp`, `tail` (s de queue gardées si ce n'est
pas une boucle). Les mesures sont vérifiées : une mesure trop longue ou trop courte arrête le rendu.
