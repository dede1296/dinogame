# Musiques composées (19/10) — synthétiseur d'origine du jeu

Stable Audio Open a été écarté par Greg (« on dirait un orgue sur lequel on fait 3 accords »). Les huit pistes
ci-dessous sont **composées note par note** et jouées par le **synthétiseur Web Audio de la version Phaser**, celui qui
a produit les 15 musiques du jeu (`titre`, `plaines`, `monts`…), retrouvé dans l'historique git. Aucune mélodie n'est
reprise d'une œuvre existante : seulement les thèmes du jeu lui-même, comme leitmotivs.

Outil : `tools/music-synth/` (à la racine du dépôt, hors Godot) — `README.md` pour rendre une piste, partitions dans
`tools/music-synth/scores/<piste>.js`. **Pour corriger ce qui ne va pas à l'oreille** : modifier la partition, puis
`node render.mjs <piste> --force` et `--import` (sous verrou). Chaque partition commence par un commentaire qui la résume.

## Le synthétiseur retrouvé

- Sources : `nouveau/src/audio/{music,instruments,mixer,sounds}.js` et `nouveau/src/data/musicThemes.js` (git `d935f19f^`),
  plus l'ancien enregistreur `Godot/tools/render-phaser-music.mjs` (Edge en temps réel, Vite, encodage Vorbis q5). Recopiés
  tels quels dans `tools/music-synth/synth/` (seule retouche : trois tables exportées).
- Nouveau rendu : **hors ligne** (`OfflineAudioContext` dans Edge sans fenêtre) au lieu du temps réel ; le hasard des
  instruments est tiré à l'identique à chaque passage d'une boucle.
- **Vérification de fidélité** (le thème d'origine re-rendu, comparé au .ogg du jeu) :

| Thème | Durée jeu / rendu | Similarité des notes (chroma, médiane) | Spectre (tiers d'octave, écart moyen) | Centre spectral | Largeur stéréo (côté/milieu) |
|---|---|---|---|---|---|
| `monts` | 54,857 / 54,857 s | 0,985 (deux rendus à moi entre eux : 0,985) | 0,8 dB | 896 / 946 Hz | -9,7 / -7,4 dB (réverb tirée au hasard) |
| `titre` | 45,714 / 45,714 s | 0,997 | 1,1 dB | 1797 / 1788 Hz | -13,1 / -13,0 dB |

  Mêmes notes, même timbre, même durée. Les .ogg d'origine commencent 0,171 s après le premier temps (la latence de
  l'ancien enregistreur, 2 × 4096 échantillons) ; les nouvelles boucles commencent une demi-croche avant le premier temps.

## La palette des musiques existantes (étudiée sur les partitions et à l'analyse)

Boucles courtes de **8 à 16 mesures**, une tonalité, **3 à 6 accords** diatoniques (I-vi-IV-V, i-♭VI-♭VII-V), une mélodie
(flûte, anche, lead carré, cuivres, boîte à musique), un arpège (harpe, guitare, marimba), une basse (tonique-quinte), une
nappe (cordes, pad, chœur) et des percussions légères (shaker, taiko, triangle). Tonalités : `titre` ré majeur 84 BPM,
`plaines` sol majeur 108, `village` fa majeur 3/4 104, `monts` si mineur 70, `ombre` mi phrygien 132, `rivale` ré majeur 150,
`alpha` ré mineur 112, `repos` fa majeur 100… Les thèmes de zones des chapitres 4 à 6 étaient des **mélodies générées**
au hasard sur les accords (« recettes ») : c'est ce que les nouvelles pistes remplacent par de vraies mélodies.

**Leitmotivs repris** (dans `tools/music-synth/scores/_lib.js`) : **Chloé** = le thème de `titre` (tête fa#–mi–ré, puis
mi–fa#–si) ; **l'Ombre Noire** = la tête de `ombre` (mi–si–mi–fa, phrygien) ; **Maïa** = la tête de `rivale` ; **les Alphas
et les géants** = la tête de `alpha` (ré–la, si♭–do–ré) ; **le repos** = `repos` (la boîte à musique du feu de camp) ;
**Hélène** = le motif de boîte à musique du Cabinet de la version Phaser (mi–ré–si, la–fa#, lydien).

## Les partitions

Instruments : ceux d'origine (harpe, guitare, pizzicati, kalimba, piano, marimba, boîte à musique, cloches, nappe, cordes,
chœur, flûte, anche, cuivres, basse, taiko, shaker, triangle, caisse claire…) + cinq faits avec les mêmes recettes :
**cors** doux, **basson**, **cordes en trémolo**, **violoncelles**, **timbales** accordées, et une nappe « **souffle** »
(cratère). Repères de temps : début de chaque plan, d'après `story/cinematiques.gd` (durées réelles avec le temps de lecture).

### `cinematique_intro_a.ogg` — 46,3 s (42,8 s de musique + queue), une fois

Ré majeur → sol (Cabinet) → ré ; la musique de I-01 à I-05, puis fondu de 2 s dans `_b`.

| s | Plan | Musique |
|---|---|---|
| 0 | I-01 le large | 6/8 à 90 (barcarolle) : le **cor appelle le thème de Chloé** (fa#–mi–ré, puis il monte : mi–fa#–**si** aigu, ré–mi–ré–si, do#–la) sur une harpe qui roule comme la houle, violoncelles et basse tenus |
| 8 | I-02 falaises d'ambre | la **flûte répond** (la seconde phrase du thème, avec l'élan do#–ré–la aigu), les cordes entrent, un carillon à chaque mesure sur la lueur de l'ambre, le cor en contre-chant |
| 16 | I-03 le Cabinet | même 6/8 : **boîte à musique du Cabinet** (motif d'Hélène, Cmaj7–D), pizzicati malicieux, petites réponses du kalimba |
| 24 | I-04 les œufs | la boîte à musique **ralentit** (81 → 60), Am7–Em7–Dsus4, les violons tiennent un la : la tendresse |
| 31,7 | I-05 la carte | 4/4 à 106 : les **pizzicati marchent**, la tête du thème monte d'un ton à chaque mesure (ré, mi, fa#), crescendo |
| 38,5 | (le volcan) | **si♭ majeur** (♭VI) : roulement de timbales, cors graves, chœur — sourd, pas effrayant |
| 40,8 | → I-06 | **la sus4**, laissé ouvert : `_b` le résout sur ré |

### `cinematique_intro_b.ogg` — 40,2 s, une fois

Ré majeur, de I-06 au carton « Ambrelune » (≈ 38 s avec le fondu de fin).

| s | Plan | Musique |
|---|---|---|
| 0 | I-06 la chambre | 100 BPM : **guitare grattée**, basse, shaker, caisse claire légère dès la 2e mesure ; la flûte sautille sur la tête du thème |
| 7,2 | (l'élan) | une mesure à 2 temps : la flûte monte (la–si–do#–mi), roulement de caisse claire |
| 8,4 | I-07 le ponton | **coup de cuivres au 3e temps (≈ 9,6 s, le saut)** avec le taiko ; puis flûte et cor (à l'octave) montent en arpèges sur IV et V (ré–sol–si, la–do#–mi aigu) : l'appel héroïque qui monte avec la barque |
| 15,6 | I-08 la brume | V → vi (si mineur) : **la musique se retient** — cordes en trémolo très douces, flûte grave (la tête du thème en si mineur), violoncelle lent (l'ombre sous la barque), pizzicato et shaker tout bas |
| 20,9 | (la brume se déchire) | trémolo qui enfle, roulement de timbales, **glissando de harpe** |
| 23,6 | I-09 l'île | **le thème de Chloé en plein** (`titre` : harpe, cordes, flûte et cor à l'octave), plus large (80), le si qui saute vers l'aigu au lieu de descendre |
| 32,6 | carton « Ambrelune » | le thème **se pose** : fa#–mi–ré, accord de ré en harpe arpégée, tenu (ralenti) |

### `cinematique_fin.ogg` — 98,1 s, une fois

F-01 → F-09 (89 s) ; à F-10, `credits.ogg` prend le relais par un fondu de 2,5 s pendant que celle-ci tient son accord.

| s | Plan | Musique |
|---|---|---|
| 0 | F-01 la jetée | ré majeur à 72 : **le thème de Chloé, apaisé**, aux violons, guitare arpégée, violoncelle en contre-chant — la réponse à l'appel de l'intro |
| 10 | F-02 la barque | la flûte continue le thème, un peu plus allant (80), guitare grattée légère, kalimba |
| 19 | F-03 les forges | mi mineur, 107 : **le basson joue le motif de l'Ombre Noire piqué** sur des pizzicati « poum-tchak », la flûte lui répond par la tête du thème, les cordes tremblent (Roc), le basson dégringole l'échelle |
| 28 | F-04 la tasse bleue | sol majeur : **piano seul, l'air du repos** (`repos`) — puis les cordes, très doucement |
| 39 | F-05 les gardiennes | ré majeur : le thème reprend de l'ampleur (flûte, cordes, harpe), **le motif de Maïa** lui répond au kalimba |
| 48 | F-06 les dinos | variation tendre et drôle (la flûte « hoquette » d'une octave, pizzicati) ; **trou laissé de 1,7 à 3,3 s** pour le cri du dino et les notes fausses d'Écho |
| 58 | F-07 Brac | mi mineur : contrebasse pizzicato, **le marimba ronfle**, le basson chante le motif de l'Ombre **en berceuse : son fa♮ est devenu fa#** |
| 67 | F-08 le Souverain | si7 → **do majeur** (cadence rompue) : grand accord tenu, **les cors jouent le motif des Alphas en majeur**, en choral, chœur et cordes, aucune percussion |
| 78 | F-09 le journal | piano seul : **le motif d'Hélène** de l'intro (I-03), la boîte à musique s'y joint |
| 85,5 | → F-10 | le motif d'Hélène **se fond dans la tête du thème de Chloé** (fa#–mi–ré), accord de ré plein (cordes, cor, harpe), point d'orgue sous le fondu des crédits |

### `credits.ogg` — 91,8 s, boucle

Ré majeur à 68, 26 mesures, sans montée : intro (harpe seule, 2) — A (flûte : le thème de `titre`, phrases A1-A2 ; les
violoncelles répondent, 8) — B (piano : la phrase B à l'octave grave, contre-chant lent de la flûte, 8) — H (le motif
d'Hélène à la boîte à musique, pizzicati, 4) — A' (le cor, doucement, la tête du thème, 4) ; son la mène au ré de la harpe.
Défilé de 96 s : la boucle repasse ses premières secondes (la harpe seule) à la fin.

### `cieux.ogg` — 72 s, boucle (chapitre 7)

**Fa lydien** (le si♮ du ciel), 3/4 à 80, 32 mesures. A (8) : la flûte, la tête du thème de Chloé en fa (la–sol–fa) et un
saut lydien vers l'aigu, harpe aiguë, nappe légère et cordes. B (8) : **le cor, majestueux** (B♭–F/A–Gm7–C, le Roi des
Cieux), les violons au-dessus, taiko doux. A' (8) : flûte et violons à l'octave, fin plus haute (fa aigu). C (8) : le vent —
échos de la tête, cloches, violoncelle ; do sus4 → do ramène le fa.

### `volcan.ogg` — 78,3 s, boucle (chapitre 8, Champs de cendres et Coulées de lave)

Do mineur avec le la♮ dorien (et des accords majeurs : fa, si♭, mi♭, la♭), 92 BPM, 30 mesures. Intro (2) : **la forge**
(marimba grave en 3+3+2, taiko, enclume au triangle). A (8) : l'**anche** chante une chanson de travail. B (8) : mi♭ majeur,
plus chaud, **le cor** la reprend, l'anche en contre-chant, chœur. C (4) : souvenir des forges de l'Ombre — **son motif aux
cors graves**, doux, do phrygien (ré♭). A' (8) : anche et flûte à l'octave ; sol (V) ramène le do mineur.

### `terre_apex.ogg` — 68,6 s, boucle (chapitre 9, le cratère)

Ré mineur à 56, 16 mesures, **minimal** : une nappe qui **respire** (2 s pour enfler, 2,5 s pour s'éteindre, un souffle
toutes les deux mesures) sur un ré grave, chœur, une cloche, une timbale très douce. Souffle (4) — choral (4) : **les cors,
le motif des Alphas très lent** (ré–la–si♭ do–ré) — lumière (4) : si♭ et fa/la, les violons — retour (4) : les cors ;
la sus4 → la ramène le ré mineur.

### `coeur_apex.ogg` — 72 s, boucle (chapitre 9, le Souverain)

Ré mineur à 60, 18 mesures, sous des **cordes en trémolo** (11 coups d'archet par seconde) et **un cœur** (deux coups de
timbale par mesure). A (6), grave : **les violoncelles chantent le motif des Alphas**. B (6), tendre : ré **majeur**, la
flûte chante la tête du thème de Chloé sur une harpe lente, le cœur s'arrête. C (6), tremblant : cor et violoncelles à
l'octave, le motif avec un **mi♭ napolitain**, le trémolo enfle ; la (V) ramène le début.

## Mesures (fichiers livrés)

Niveau : règle de Greg (catégorie « music » : RMS actif = médiane des 15 musiques du jeu, **-14,5 dB** ; existantes :
-17,0 à -12,8 ; pics -0,5 à -2,0 dBFS). Pic : échantillon le plus fort après décodage du .ogg. Couture PCM : la fin suivie
du début, comparée à un rendu continu de trois passages (écart maximal, en dB sous le niveau du passage). Couture encodée :
erreur de l'encodeur Vorbis autour de la jonction ÷ son erreur habituelle (1 = jonction aussi propre que le reste).

| Piste | Durée | Boucle | Pic | RMS actif | Limiteur (max, durée > 1 dB) | Couture PCM | Couture encodée |
|---|---|---|---|---|---|---|---|
| `cinematique_intro_a` | 46,3 s | non | -0,8 dBFS | -14,5 dB | -1,7 dB, 0,6 s | — | — |
| `cinematique_intro_b` | 40,2 s | non | -0,8 | -14,5 | -1,8 dB, 0,1 s | — | — |
| `cinematique_fin` | 98,1 s | non | -0,8 | -14,5 | -2,6 dB, 0,2 s | — | — |
| `credits` | 91,8 s | oui | -0,8 | -14,5 | -0,1 dB | -118 dB | 1,1 |
| `cieux` | 72,0 s | oui | -1,5 | -14,5 | aucun | -125 dB | 2,3 |
| `volcan` | 78,3 s | oui | -0,8 | -14,5 | -2,2 dB, 0,2 s | -128 dB | 1,1 |
| `terre_apex` | 68,6 s | oui | -0,8 | -14,5 | -0,6 dB | -118 dB | 0,9 |
| `coeur_apex` | 72,0 s | oui | -1,5 | -14,5 | aucun | -117 dB | 1,0 |

Le limiteur n'agit que sur quelques coups (timbales, taiko, coup de cuivres) : jamais plus de 0,6 s au-delà de 1 dB.
Équilibre spectral (grave / médium / aigu) dans la fourchette des musiques existantes (proche de `titre` et `plaines` ;
`terre_apex` et `volcan` plus sombres, comme `monts` et `foret`).

**Diversité** (d'après les notes ; « motifs » = mesures de mélodie de rythme et d'intervalles différents / mesures mélodiques ;
étendue de la mélodie principale en demi-tons) :

| Piste | Sections | Mesures | Accords différents | Changements d'accord | Degrés | Motifs | Étendue | Instruments |
|---|---|---|---|---|---|---|---|---|
| *existantes : `titre`* | 1 | 16 | 6 | 16 | 5 | 13/14 | 14 | 6 |
| *`plaines`* | 1 | 16 | 5 | 16 | 5 | 38/86 | 20 | 6 |
| *`monts`* | 1 | 8 | 6 | 8 | 6 | 11/12 | 11 | 4 |
| *`ombre`* / *`alpha`* | 1 | 8 | 4 / 5 | 8 / 7 | 4 / 5 | 8/8 | 12 / 13 | 6 |
| *`marais`* / *`desert`* | 1 | 8 | 4 / 3 | 4 / 5 | 4 / 3 | 5/5 · 7/7 | 9 / 12 | 4 / 5 |
| `cinematique_intro_a` | 7 | 20 | 12 | 20 | 7 | 13/16 | 28 | 15 |
| `cinematique_intro_b` | 7 | 14 | 6 | 13 | 6 | 13/13 | 22 | 17 |
| `cinematique_fin` | 10 | 31 | 14 | 29 | 9 | 27/30 | 51 | 20 |
| `credits` | 5 | 26 | 8 | 25 | 5 | 16/21 | 33 | 12 |
| `cieux` | 4 | 32 | 13 | 32 | 7 | 17/26 | 29 | 10 |
| `volcan` | 5 | 30 | 9 | 28 | 10 | 18/27 | 37 | 10 |
| `terre_apex` | 4 | 16 | 8 | 10 | 5 | 3/3 | 20 | 9 |
| `coeur_apex` | 3 | 18 | 10 | 18 | 8 | 10/13 | 34 | 8 |

(`terre_apex` : 3 motifs seulement, voulu — un choral en notes longues ; « minimal ».)

## Ce qui change dans le jeu

- **Cinématiques et crédits** : tout de suite (le moteur prend la piste si elle existe, sinon `titre.ogg`).
- **Zones** : rien tant qu'on ne les régénère pas (une zone garde la musique écrite dans sa scène). À la prochaine
  génération, prendraient la nouvelle piste : `tools/zones/cieux.gd` (**cieux** au lieu de `monts`), `arche_du_vent.gd` et
  `nids_geants.gd` (**cieux** au lieu de `monts`, faute de leur propre piste), `volcan_champs.gd` et `volcan_coulees.gd`
  (**volcan** au lieu de `desert`), `apex_terre.gd` (**terre_apex**, au lieu du silence), `apex_coeur.gd` (**coeur_apex**,
  au lieu du silence). Inchangées : `volcan_forges.gd` (`ombre`), `volcan_porte.gd` et `volcan_sanctuaire.gd` (silence voulu).

## Incertain à l'oreille (à juger par Greg)

- **Les cinq nouveaux timbres** (cors, basson, trémolo, violoncelles, timbales) : faits avec les recettes d'origine, jamais
  entendus ; le cor grave (si♭2, do3) et le basson piqué sont les plus incertains.
- **Le coup de cuivres du saut** (I-07, 9,6 s) et les timbales de l'arrivée : le limiteur les tasse de 2 dB.
- **L'équilibre des plans** de la fin : les forges (F-03) et Brac (F-07) sont volontairement plus légers ; le Souverain (F-08)
  devrait être le grand moment sans écraser.
- **Le fondu intro_a → intro_b** : le la sus4 de `_a` doit se résoudre sur le ré de la guitare de `_b` ; si un plan est
  passé (bouton A), la musique ne suit plus l'image.
- **La fin sous le fondu des crédits** : l'accord final de `cinematique_fin` (≈ 89 s) est en partie couvert par l'entrée de
  `credits.ogg` ; si le point d'orgue doit s'entendre entier, faire démarrer les crédits après le carton.
- **La nappe de `cieux`** (allégée et doublée de cordes pour éviter l'« orgue ») et le **souffle** de `terre_apex`.
- **Les basses** (la basse d'origine double à l'octave grave) sur de petits haut-parleurs.
