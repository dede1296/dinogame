# DÉCISIONS DE GREG (19/10) — valables pour toute la production

1. **Cheveux de Chloé** : non tranché par Greg ; PAR DÉFAUT **auburn**, comme ses planches de jeu et l'écran titre (cohérence avec le Chloé jouable). À reprendre si Greg préfère châtain foncé.  
2. **F-06 (les dinos de Chloé à l'étang)** : **trois peintures**, une par dino de départ (Vif / Bastion avec Maïa assise dessus / Écho qui chante faux).  
3. **Carton « Pour Chloé »** avant « Merci d'avoir joué » : **oui**.  
4. **L'ombre de Carène sous la barque** (intro, la brume) : **on la garde**.  
5. **« Revoir l'intro »** : **oui** dans les Paramètres, **et** « Crédits » au menu ; en Nouvelle partie+, l'intro **se rejoue** (oui).  
6. Pas de vente prévue (mémoire pas-de-vente) ; crédits : « Grégory Cuypers » humain ; contenu des crédits dans docs/credits.md et data/credits_data.gd (déjà écrits).

---

# Textes affichés — version 2 (19/10, agent HISTOIRE)

Retour de Greg : les phrases de la version 1 **décrivaient les images au lieu de raconter**. Elles sont remplacées.
**La seule source des textes est désormais [`cinematiques_textes.md`](cinematiques_textes.md)** : voix de Chloé à
la première personne (l'intro au passé, la fin au présent : ce sont les pages qu'elle écrit dans le journal), au plus
deux phrases courtes et **18 mots** par image, durée réglée par le moteur (0,45 s par mot, plancher 3 s). Les
colonnes « Phrase à l'écran » des deux tableaux ci-dessous ont été mises à jour avec les nouveaux textes ; pour le
fil narratif, le carton « Pour Chloé », les variantes de F-06 et les retouches d'images proposées (F-08, I-05, et
deux images facultatives), voir ce fichier. Le reste du présent document (découpage, caméra, musique, prompts) est
inchangé ; là où ses commentaires citent encore d'anciennes phrases (§ « Ce qu'elle raconte », « Note sur I-09 »,
« Continuité vérifiée », « Autocritique »), c'est `cinematiques_textes.md` qui fait foi.

---

# Les deux cinématiques d'Ambrelune — scénario et découpage

> Écrit le 19/10/2026 par l'agent HISTOIRE/CONCEPTION (Fable), pour validation par Greg. **Rien n'est codé, aucune
> image n'est faite** : ce document est le scénario, le découpage image par image, les prompts d'illustration, la
> mise en scène des crédits et la liste des assets à produire. Sources : `histoire.md` (Prologue, Épilogue, Post-game,
> journal pages 1, 3, 39, 40), `lore.md`, `chapitre-9-scenes.md` (scènes 4 et 5), `direction-artistique.md`,
> `story/prologue.gd`, `story/apex_jetee.gd`, `scenes/boot/boot.gd`, mémoire `scenes-courtes` et `chloe-photos-reference`.
>
> Décisions de Greg déjà prises : intro **aventureuse** (élan, appel du large, humour léger) ; **textes à l'écran
> seulement**, pas de voix ; crédits : **Grégory Cuypers** est l'humain (création, histoire, direction, choix,
> validation), les IA sont des **outils** ; format **livre illustré animé** joué dans le moteur (8 à 10 grandes
> illustrations par cinématique, caméra lente, quelques éléments animés, **une phrase de 8 à 14 mots** par image,
> musique et bruitages, bouton « passer » à tout moment) ; intro 60-80 s, fin 90-120 s hors crédits.

## Décisions à faire valider par Greg

1. **Les cheveux de Chloé dans les illustrations.** La règle du 04/10 (photos de Chloé) dit *châtain foncé* ; les
   planches du jeu et l'écran titre (`assets/art/title/accueil-paysage.webp`) sont *auburn/roux*. Les prompts
   ci-dessous disent **châtain foncé** (la règle). Faut-il, du coup, refaire l'écran titre pour qu'il s'accorde avec
   les cinématiques, ou garder l'auburn partout pour ne pas détonner avec le sprite du jeu ? *(Recommandé : châtain
   foncé, et refaire l'écran titre à partir de l'image I-09.)*
2. **L'image F-06 (les dinos de Chloé) en trois variantes** (Vif / Bastion / Écho au premier plan, même fond, trois
   éditions nano-banana), ou **une seule peinture** sans dino au premier plan, avec le sprite du dino de départ posé
   par le moteur par-dessus (zéro variante, moins beau) ? *(Recommandé : trois variantes, 2 crédits de plus.)*
3. **Une dédicace.** Un carton « Pour Chloé » juste avant « Merci d'avoir joué » ? L'héroïne porte le prénom de la
   vraie Chloé : c'est ta décision, pas la mienne.
4. **Le clin d'œil de Carène** (I-08) : sous la barque, dans la brume, l'ombre d'une très grande tortue qui nage à
   côté (« Carène a l'âge de ma barque », ch. 9). Indice invisible pour un enfant au premier passage, qui prend son
   sens à la fin. Le garder, ou l'enlever pour ne rien suggérer sur Isaure ?
5. **Rejouer.** Un bouton **« Crédits »** dans le menu titre (demandé). Faut-il aussi **« Revoir l'intro »** (dans
   Paramètres plutôt que dans le menu titre, pour ne pas charger l'écran) ? Et en **Nouvelle partie+**, l'intro se
   rejoue-t-elle (elle est courte et se passe) ou se saute-t-elle d'office ? *(Recommandé : « Revoir l'intro » dans
   Paramètres ; NG+ : rejouée.)*

---

## Format commun aux deux cinématiques (le « livre illustré animé »)

- **Images** : illustrations peintes **16:9**, générées en 2K et exportées à **2560 × 1440** (2× la base 1280 × 720, comme
  tout le jeu), avec **8 à 10 % de marge** de dessin pour que les zooms et panoramiques ne montrent jamais un bord.
  Style : celui du jeu (`direction-artistique.md` § Style) : cartoon **peint à la main**, contours brun foncé, ombrage
  doux, **lumière dorée du haut à gauche**, chaleureux, lisible, jamais effrayant ; personnages **chibi ~2,5 têtes**.
  Référence de style n° 1 : `assets/art/title/accueil-paysage.webp` (l'écran titre : même monde, même touche).
- **Caméra** : un seul mouvement lent par image, noté « zoom 1,00 → 1,08 » (sur un point précis) ou « panoramique
  gauche → droite 6 % » ; jamais deux mouvements, jamais de coupe franche au milieu d'une image.
- **Éléments animés** : 2 à 4 par image, réalisés **dans le moteur** (calques PNG séparés détourés sur magenta, comme
  les planches du jeu, ou effets existants : shader de balancement, eau animée, lueur de l'ambre, particules). Ils
  sont listés par image ; la peinture de base est faite **sans** ces éléments (ou avec, si l'élément reste statique
  derrière : voir chaque ligne).
- **Texte** *(version 2, voir `cinematiques_textes.md`)* : **au plus deux phrases très courtes** par image,
  **18 mots maximum**, dans la voix de Chloé (première personne), en bas, centrées, sur une ou deux lignes, police
  et couleur des cartons du jeu (`Epilogue.card` : crème `(0.98, 0.9, 0.72)` avec contour sombre) ; apparaît 0,4 s
  après l'image, s'efface 0,4 s avant le fondu suivant ; la durée d'affichage suit le nombre de mots (0,45 s par
  mot, plancher 3 s), la durée d'image prévue dans le découpage restant un plancher. **Pas de voix** (décision).
  Jamais de bloc de texte (règle « scènes courtes »).
- **Transitions** : fondu enchaîné de 0,8 s entre deux images (1,2 s quand on change de lieu ou de temps) ; fondu au
  noir de 1,5 s au début et à la fin.
- **Passer** : un bouton **« Passer »** en bas à droite, avec la touche sous le bouton (règle PC : « Échap / B »).
  N'importe quelle entrée (clavier, manette, souris, clic) **fait apparaître** le bouton en clair pendant 2 s ; une
  seconde pression (ou un clic sur le bouton) **passe toute la cinématique** immédiatement, fondu compris. Le bouton
  est toujours cliquable à la souris, dès la première image.
- **Où ça s'insère** (pour l'agent CODE, à titre d'indication, je ne touche à rien) :
  - **Intro** : `scenes/boot/boot.gd::_on_new_game` : après `Game.new_game()`, jouer la cinématique d'intro, puis
    `Router.go_to(WORLD)` : on arrive sur le quai de Port-Ambre où `Prologue.arrival()` enchaîne (« Et voilà
    Ambrelune, moussaillon. Regarde les falaises… »). « Continuer » ne la joue pas.
  - **Fin** : `story/apex_jetee.gd::_the_end` : après le fondu au noir de 2 s, **à la place** du carton
    `Epilogue.card("Ambrelune", 3.4)` : la cinématique de fin (elle finit sur le carton « Ambrelune »), puis les
    crédits, puis le carton existant « L'île est à vous. Les géants du cratère se réveillent un à un… », puis le
    retour sur la jetée (post-game), comme aujourd'hui.
  - **Crédits depuis le menu** : `scenes/boot/boot.tscn`, un bouton « Crédits » sous « Paramètres » (même style de
    bouton) : joue la séquence des crédits seule (fond animé C-01), puis revient au titre.

---

## Cinématique 1 — L'INTRO : « Les légendes, ça se trouve » (9 images, ~70 s)

### Ce qu'elle raconte, en trois temps

1. **L'île** (I-01, I-02) : quelque part au large, une île que personne ne trouve, dont les falaises brillent les nuits
   de pleine lune. Le mystère, mais lumineux.
2. **La grand-mère** (I-03 à I-05, *il y a un an*) : au Cabinet, une vieille dame réveillait des dinosaures (« Des
   vrais. ») ; elle est partie en laissant trois œufs, un mot, et son journal ouvert sur une carte de l'île qui
   s'anime, région après région, jusqu'au volcan qui gronde. L'émerveillement, et la question.
3. **Chloé** (I-06 à I-09, *aujourd'hui*) : douze ans, un sac trop plein, une grand-mère à retrouver ; une capitaine
   qui connaît le chemin ; la brume ; l'île qui apparaît. L'élan. Carton « Ambrelune ». Fondu : le quai de Port-Ambre,
   le jeu commence.

Ce qu'elle **ne dit pas** : qui est la capitaine (on ne la nomme pas), ce qu'elle a été pour Hélène, le Masque,
l'Ombre Noire, les Cœurs. Elle ne montre pas la lettre (c'est Roc qui la donne au Cabinet, `Prologue._roc_intro`), ni
Maïa (elle est sur le quai dans le jeu), ni le Souverain. Elle ne dit pas non plus « Ambrelune » avant le carton.

### Découpage

| # | Durée | Ce qu'on voit | Caméra | Éléments animés (moteur) | Phrase à l'écran | Musique / bruitages (humeur) |
|---|---|---|---|---|---|---|
| I-01 | 7 s | **La mer, au large, vers le soir.** Grande houle bleu-vert (`#22607a` → `#54a0a0`), ciel doré et rose. Tout au fond, à moitié dans la brume, la silhouette sombre d'une île en cône : le volcan au centre, un fil de fumée. Trois ptérosaures très loin, en V. Au premier plan, l'écume d'une vague. Aucun personnage. | Zoom lent 1,00 → 1,08 vers l'île | Vagues (shader eau du jeu, calque mer séparé), brume qui dérive (2 calques translucides), fumée du volcan (particules), les trois ptérosaures qui glissent de droite à gauche (`dinos/pteranodon_vol.png`) | **Moi, c'est Chloé, douze ans. Ma grand-mère Hélène vivait là-bas, sur une île que personne ne trouve.** (17) | Musique : cordes graves tenues, harpe lointaine, mystère lumineux, 60 BPM. Bruits : houle lente, vent marin, un cri de ptérosaure très loin. |
| I-02 | 7 s | **Les falaises d'ambre, nuit de pleine lune.** Vue de la mer : une haute falaise de roche grise zébrée de filons d'ambre qui **luisent** doré (`#fac259`), halo de pleine lune en haut à droite, reflets d'or sur l'eau noire-bleue, une petite crique de sable en bas. Pas de personnage. (C'est le nom : l'ambre, la lune.) | Panoramique gauche → droite 6 % le long de la falaise | Lueur des filons qui respire (calque « ambre » avec pulsation lente, comme la lueur d'ambre du jeu), reflets sur l'eau (shader), halo de lune, deux chauves-souris-ptéro minuscules (facultatif) | **Elle m'écrivait que ses falaises brillent les nuits de pleine lune. Je croyais qu'elle inventait.** (15) | Musique : même nappe, un carillon doux sur la pulsation de l'ambre. Bruits : clapotis, un souffle de vent, un « tintement » d'ambre très discret. |
| I-03 | 8 s | **Le Cabinet, la nuit, il y a un an.** Intérieur : le bureau d'Hélène (`props/bureau.png`), une lampe à huile allumée, **le journal ouvert** (carnet à couverture de cuir, une fougère séchée entre les pages, un stylo-plume posé, l'écriture qui s'arrête au milieu d'une ligne, une page **arrachée proprement**), un chapeau de paille à la patère, une chaise repoussée, des bocaux d'ambre sur l'étagère, et au mur un dessin épinglé : un **Protoceratops** bébé. Personne dans la pièce. | Zoom lent 1,00 → 1,10 sur la page ouverte | Flamme de la lampe (calque, scintillement), poussière dans le rayon de lumière (particules), coin de page qui se soulève au courant d'air (calque page, petit balancement), rideau | **Dans sa maison, elle réveillait des dinosaures endormis dans l'ambre. Des vrais.** (12) | Musique : boîte à musique / célesta, chaleureux, un peu malicieux, 72 BPM. Bruits : tic-tac d'une horloge, la lampe, un froissement de page. |
| I-04 | 7 s | **La couveuse d'ambre, de près.** La couveuse du Cabinet (`props/couveuse.png` en référence) : sous une cloche de verre, trois œufs sur de la mousse, éclairés par en dessous d'une lumière ambrée : un **tacheté gris-vert** (Velociraptor), un **rond et épais** (Ankylosaurus), un **long à reflets corail** (Parasaurolophus). Un petit mot plié coincé contre le verre : on ne lit rien, on devine une écriture penchée. Aucune fissure sur les œufs (ils éclosent à l'arrivée de Chloé). | Zoom lent 1,00 → 1,06 sur les œufs | Lueur ambrée qui respire (calque), une bulle de chaleur qui monte, la lumière de la lampe qui bouge sur le verre | **Un jour, elle est partie vers le volcan. Elle m'a laissé trois œufs, et un mot.** (16) | Musique : le célesta ralentit, une note tenue : la tendresse. Bruits : le bourdonnement doux de la couveuse, un tout petit « toc » dans un œuf (un seul, pour sourire). |
| I-05 | 9 s | **La carte de l'île, dessinée par Hélène, qui s'anime.** Plein cadre : une page du journal, papier crème, encre brune : l'île ronde avec ses régions en **spirale** vers le volcan central (`ui/atlas_ile.png` et `atlas_regions.png` en référence : prairie, forêt, marais, désert, côte, monts, cieux dans les nuages, plaine volcanique), une petite fougère dessinée dans un coin, un compas posé sur le bord. Dans chaque région, un **petit dino dessiné à l'encre** (Tricératops, raptor, Spinosaure, Carnotaurus, Mosasaure, Cryolophosaure, Quetzalcoatlus, T-Rex). Au centre, le volcan, et sur lui un gros **point d'interrogation** à l'encre. | Zoom arrière 1,12 → 1,00 : on part de la prairie, on découvre toute la carte | **Les traits s'encrent d'eux-mêmes** région après région dans l'ordre de la spirale (masque de révélation animé sur un calque « encre »), les petits dinos frétillent (2 images chacun), une bouffée de fumée dessinée sort du volcan à la fin, le « ? » apparaît en dernier | **Sous le volcan dormait un secret énorme. Et des gens masqués voulaient ses dinos, pour les faire obéir.** (18) | Musique : la curiosité : pizzicati qui avancent avec le trait, un roulement sourd quand le volcan apparaît. Bruits : plume qui gratte (suit le tracé), petit grondement lointain à la fin. |
| I-06 | 8 s | **La chambre de Chloé, sur le continent, le matin.** Chloé, 12 ans, de trois quarts, en train d'enfiler sa deuxième bottine à cloche-pied, le **sac ambre trop plein** (il en dépasse : un gros livre « DINOSAURES », une épuisette, un pull, une brosse à dents, une peluche de dino dont seule la queue sort). Au mur, une **photo encadrée d'Hélène jeune avec un bébé Protoceratops** dans les bras ; par la fenêtre, un port. Elle sourit, décidée. | Zoom lent 1,00 → 1,08 sur Chloé | Lacet qui se balance (calque), rideau au vent, rayon de soleil avec poussière, la queue de la peluche qui remue (clin d'œil) | **Un an sans nouvelles, puis une lettre du professeur Roc : « Viens vite. » J'ai fait mon sac.** (16) | Musique : ça démarre : guitare rythmée, caisse claire légère, 100 BPM, joyeux. Bruits : lacet, fermeture éclair qui force, un objet qui tombe du sac (« toc »). |
| I-07 | 7 s | **Le ponton du continent, au petit matin.** Une **barque de bois** (`props/barque.png`) au bout d'un ponton gris ; dedans, debout à la barre, **la capitaine** (Isaure : cheveux gris en chignon, long manteau de mer sombre, peau brune, sourire fatigué et chaleureux ; planche `isaure.png`). Chloé **saute** du ponton dans la barque, les deux pieds en avant, le sac sur une épaule ; la barque **tangue**, une gerbe d'eau, une mouette s'envole, vexée. Isaure n'est pas nommée. | Panoramique droite → gauche 5 % (du ponton vers le large) | Gerbe d'eau (particules), la mouette (calque, 3 images), le cordage qui oscille, les rides sur l'eau | **Au port, une seule capitaine connaissait le chemin. « Monte, moussaillon. Les légendes, ça se trouve. »** (15) | Musique : l'élan continue, un accent de cuivres sur le saut. Bruits : saut sur les planches, **gros plouf** avec la barque qui cogne, cri de mouette indignée, rame dans l'eau. |
| I-08 | 8 s | **La traversée dans la brume.** Vue de côté, un peu en plongée : la barque dans une brume blanche et dorée ; Isaure rame, calme ; Chloé à la proue, **penchée en avant**, les mains sur le bord, queue de cheval au vent, les yeux grands ouverts ; le sac à ses pieds. On ne voit presque rien autour. *(Décision 4 :)* sous l'eau, à droite de la barque, **l'ombre d'une carapace immense** qui nage au même rythme ; Chloé ne la voit pas. | Zoom lent 1,00 → 1,06 sur Chloé | Brume qui glisse (3 calques), la barque qui tangue doucement (balancement du calque barque + personnages), gouttes de rame, l'ombre sous l'eau qui ondule très lentement | **Dans la brume, je ne pensais qu'à Hélène. Pas peur du tout. Enfin, presque.** (14) | Musique : la musique se retient : cordes en sourdine, un souffle, le rythme continue tout bas. Bruits : rames, eau, brume (vent feutré), un « glou » sous la coque. |
| I-09 | 9 s | **L'île apparaît.** La brume se déchire : plein cadre, de la barque (on voit la proue et Chloé **debout**, de dos, les bras ouverts, en bas de l'image), l'île en plein jour : falaises grises zébrées d'ambre qui **brillent un peu, même en plein jour**, Port-Ambre au creux de la crique (toits, le phare ruiné `props/phare_ruine.png`, une jetée), le Cabinet couvert de lierre un peu à l'écart (`props/cabinet.png`), des ptérosaures, les collines vertes, et le volcan tout en haut, un fil de fumée. Isaure tient la barre, de dos. | Zoom arrière 1,08 → 1,00 (l'île se révèle) | La brume qui s'ouvre (2 calques qui s'écartent), ptérosaures (`pteranodon_vol.png`), vagues, fumée du volcan, reflets d'ambre | **Et l'île est apparue. Hélène était quelque part là-dedans. Et les gens masqués aussi.** (14) | Musique : **le thème** (celui de `titre.ogg` : harpe, flûte) en plein, large et solaire, puis il se pose. Bruits : la brume qui se déchire (souffle), mouettes, vagues sur la coque, cris de ptérosaures proches. |
| Carton | 4 s | Fond noir, **« Ambrelune »** (le style de `Epilogue.card`, taille titre), puis fondu : le quai de Port-Ambre, `Prologue.arrival()`. | — | — | **Ambrelune** | La dernière note tenue, puis la mer du port (ambiance du jeu). |

Durée : 7 + 7 + 8 + 7 + 9 + 8 + 7 + 8 + 9 = **70 s** + carton 4 s = **74 s**. Fondus compris, 76 s environ.

**Note sur I-09** : la phrase « Les légendes, ça se trouve » est celle qu'Isaure a dite à Hélène il y a trente-deux
ans (page 3 du journal, `dialogue_db.gd` : « Tu vois, Hélène ? Les légendes, ça se trouve. »). Au premier passage,
c'est juste une belle phrase de fin d'intro ; au chapitre 1, en lisant la page 3, le joueur attentif comprend qui
était la capitaine de l'intro, et dans quel sens. Et le jeu enchaîne sans redite : Isaure dit « Et voilà Ambrelune,
moussaillon. Regarde les falaises… » (`prologue.gd`), qui répond à I-09.

### Prompts nano-banana (intro)

Préambule commun, à mettre en tête de chaque prompt (STYLE) :

```
Storybook painted game art, full-frame 16:9 illustration, hand-painted cartoon style with crisp dark-brown outlines,
soft painted shading, warm golden light from the upper left, bright and friendly, never scary, for a children's
dinosaur adventure game. People in chibi proportions (about 2.5 heads tall) with expressive faces. Lush prehistoric
vegetation: tree ferns, araucarias, pink, yellow and purple flowers; warm ochre paths, grey rocks, warm brown wood.
Keep 10% safe margin all around (no important detail touching the edges). No text, no letters, no watermark, no UI.
```

Fiches personnages (CHLOÉ, ISAURE…), à coller quand le personnage est dans l'image :

```
CHLOÉ: a slim 12-year-old girl (1.50 m), dark chestnut-brown hair (not auburn) pulled back in a ponytail with a small
teal hair clip and a few loose strands on her forehead, brown almond-shaped smiling eyes, dark eyebrows, freckles on
her nose and cheeks, light skin; teal t-shirt, khaki explorer vest with pockets, olive shorts, brown ankle boots, an
orange-amber backpack. Reference sheet: assets/art/characters/chloe.png (outfit and style; hair colour: dark chestnut).
ISAURE: a weathered sea captain, a woman of about 50 (1.70 m), warm brown skin, grey hair in a low bun, kind tired
eyes, a long dark sea coat, dark boots; no mask, no jewellery. Reference: assets/art/characters/isaure.png and
isaure_sans_masque.png.
```

- **I-01** — `STYLE + The open sea at golden evening, seen from low above the waves: big slow swell in blue-green
  teal, foam on the nearest wave in the foreground, a sky of gold and pink with soft clouds. Far away on the horizon,
  half hidden in a band of pale mist, the dark cone silhouette of a volcanic island with a thin thread of smoke, and
  three tiny pterosaurs flying in a V. No people, no boat. Wide, quiet, inviting.` Références : `accueil-paysage.webp`
  (ciel, volcan), `assets/art/battle/cote.jpg` (la mer du jeu).
- **I-02** — `STYLE + Night of the full moon, seen from the sea: a tall grey cliff streaked with veins of amber that
  glow warm gold from inside the rock, a big full moon with a soft halo in the upper right, golden reflections on the
  dark blue water, a small sandy cove at the foot of the cliff, a few tree ferns on top. No people. Magical, calm,
  luminous, not spooky.` Références : `assets/art/ground/falaise.png` (la roche), `ui/ambre.png` (la couleur de
  l'ambre), `accueil-paysage.webp`.
- **I-03** — `STYLE + Interior of an old naturalist's study at night, cosy and cluttered: a wooden desk with a lit oil
  lamp, an open leather-bound journal with handwritten pages (unreadable handwriting), a dried fern pressed between the
  pages, a fountain pen, one page cleanly torn out; a straw hat hanging on a peg, a chair pushed back, shelves with
  jars of glowing amber, a pinned pencil drawing of a baby Protoceratops on the wall, ivy at the window. Nobody in the
  room. Warm lamp light, long soft shadows.` Références : `props/bureau.png`, `props/lampe.png`, `props/mur_cabinet.png`,
  `props/cabinet.png` (l'extérieur, pour le lierre), `characters/helene.png` (le chapeau de paille).
- **I-04** — `STYLE + Close-up of an amber incubator in the same study: under a glass bell on a wooden base, three
  dinosaur eggs on moss lit from below by a warm amber glow: one speckled grey-green, one round and thick-shelled, one
  elongated with coral-pink sheen. A small folded note is tucked against the glass (no readable text). No cracks on
  the eggs. Warm, tender, slightly magical.` Références : `props/couveuse.png`, `props/socle.png`, `ui/ambre.png`.
- **I-05** — `STYLE + A full-frame hand-drawn map in brown ink on cream journal paper, drawn by an old naturalist: a
  round island whose regions spiral inward to a central volcano: a green meadow with a giant skull, a tall forest, a
  misty swamp with a sunken temple, a sandy desert with giant bones, a coast with cliffs and a lagoon, snowy mountains,
  rocky peaks above the clouds, a black volcanic plain, and the volcano at the centre with a big inked question mark on
  it. In each region a small cute ink sketch of a dinosaur (Triceratops, Velociraptor, Spinosaurus, Carnotaurus,
  Mosasaurus, Cryolophosaurus, Quetzalcoatlus, T-Rex). A small drawn fern in one corner, a brass compass resting on
  the paper edge. Paper texture, ink only (no painted colours except faint watercolour washes).` Références :
  `ui/atlas_ile.png`, `ui/atlas_regions.png` (la forme et l'ordre des régions), `ui/fougere.png`. **Demander aussi, en
  second, la même image SANS les traits** (le papier vide avec le compas) : le moteur révèle l'encre par-dessus.
- **I-06** — `STYLE + CHLOÉ + A sunny bedroom in a small seaside town on the mainland, morning. Chloé, three-quarter
  view, hopping on one foot while pulling on her second boot, grinning and determined. Her amber backpack on the bed is
  overstuffed: a big book titled only with a dinosaur picture, a fishing net, a sweater, a toothbrush and the tail of a
  plush dinosaur stick out. On the wall a framed photo of a kind elderly woman holding a baby Protoceratops; through the
  window, a harbour with boats. Cheerful, funny, full of energy.` Références : `characters/chloe.png`,
  `characters/helene.png` (la photo), `dinos/protoceratops.png`.
- **I-07** — `STYLE + CHLOÉ + ISAURE + A grey wooden pier at dawn on the mainland; a small wooden rowing boat moored at
  its end. ISAURE stands at the stern holding the tiller, calm and amused. CHLOÉ is caught mid-air, jumping feet-first
  from the pier into the boat with her backpack on one shoulder; the boat tilts, a splash of water, a seagull takes off
  indignantly. Low golden morning light, ripples, ropes. Dynamic and funny.` Références : `props/barque.png`,
  `characters/isaure.png`, `characters/chloe.png`.
- **I-08** — `STYLE + CHLOÉ + ISAURE + A small wooden rowing boat crossing a thick white-and-gold sea mist, seen from
  the side and slightly above. ISAURE rows steadily. CHLOÉ kneels at the bow, leaning forward with both hands on the
  edge, ponytail blown back, eyes wide with wonder, backpack at her feet. Almost nothing visible around the boat except
  soft mist and calm water. [Option: under the water to the right of the boat, the faint shadow of a huge sea turtle
  swimming alongside.] Gentle, mysterious, hopeful.` Références : `props/barque.png`, `dinos/archelon.png` (l'ombre).
- **I-09** — `STYLE + CHLOÉ + ISAURE + Seen from inside the rowing boat: in the lower foreground the bow, CHLOÉ standing
  with her back to us and both arms wide open, ISAURE at the tiller behind her seen from the back. The mist parts to
  reveal a volcanic island in full daylight: grey cliffs streaked with amber veins that still glint gold in the sun, a
  small fishing village of stone houses in a cove with a ruined lighthouse and a wooden jetty, an ivy-covered big house
  slightly apart on the east side, green hills, tree ferns, pterosaurs circling, and the volcano at the top with a thin
  thread of smoke. Sunlight, wide, joyful arrival.` Références : `accueil-paysage.webp`, `props/cabinet.png`,
  `props/phare_ruine.png`, `props/barque.png`, `dinos/pteranodon_vol.png`.

---

## Cinématique 2 — LA FIN : « Ce qui dort n'est pas mort » (10 images, ~97 s, puis les crédits)

### Quand elle se joue, et ce qu'on sait à ce moment

Après la page 40 sur la jetée (`ApexJetee`, 5 e) : Chloé a lu « Tu as grandi, toi aussi. », les drapeaux `epilogue_fini`
et `post_game` sont posés, fondu au noir. Tout ce que la cinématique montre est **déjà arrivé ou annoncé** dans le jeu :
la Réserve (5 a), les barques d'Isaure « tarif unique » (5 a), les forges démontées par Isaure avec Roc à l'échelle
(4 c, et `roc_epilogue_n`), la tasse bleue (4 b-4 c), les gardiennes (5 c), Brac gardien de nuit avec sa lanterne, le
panneau « BARC » (5 b, `brac_jetee_n`), le Souverain couché sur le bord du cratère qui regarde la mer (5 e), la page 40.
Elle ne montre **rien** qui dépende d'un choix du joueur, sauf **le dino de départ** (F-06 : trois variantes, le nom
par `Game.starter_name()` puisque le joueur a pu le renommer). Ce qui varie selon la partie et qu'on ne montre donc
**pas** de façon identifiable : le troisième petit, Fournaise, Flocon, Braise, les moufles d'Hélène (rendues ou pas), la
lettre. Ce qu'on sait sûr : Moustique est à Maïa, le masque en carton est dans la veste d'Isaure, Caillou est un
Tricératops adulte, Isaure a les cheveux attachés et plus de masque, Brac a jeté le sien, Dame Suie n'a plus ni gants ni
lunettes, Hélène a un chapeau de paille et une canne, le volcan s'est tu.

### Ce qu'elle raconte

L'île ouvre (F-01, F-02), chacun tient sa promesse (F-03 les forges, F-04 la tasse bleue), la relève (F-05 les
gardiennes, F-06 les dinos de Chloé), les veilleurs (F-07 Brac, F-08 le Souverain), et le journal continue (F-09).
Carton « Ambrelune » (F-10). Émouvant sans larmoyer : chaque image émue (F-04, F-08, F-09) est encadrée par une
drôlerie (F-03, F-07) ; personne ne pleure, personne ne fait de discours ; la dernière phrase parle de pages blanches.

### Découpage

| # | Durée | Ce qu'on voit | Caméra | Éléments animés (moteur) | Phrase à l'écran | Musique / bruitages (humeur) |
|---|---|---|---|---|---|---|
| F-01 | 10 s | **La jetée de Port-Ambre en fête, le matin.** Vue depuis la mer : la jetée de bois avec des **guirlandes de fanions** (couleurs douces) et des lanternes, un grand **panneau de bois fraîchement peint** à l'entrée (on ne lit rien : une fougère peinte et deux lignes de lettres suggérées), les maisons de pierre du port avec des volets **rouverts** et des filets qui sèchent, enfin pleins. Sur la jetée, le village, petits de loin : Hélène (chapeau de paille) au bras de Roc, Léonce et des pêcheurs, Rosalie, Mémé Pervenche, Joss. Au bout de la jetée, un gros bonhomme assis (Brac) avec trois dinos. Dans le ciel, Hauban, le Ptéranodon au bec rayé, un poisson dans le bec. Le volcan au fond, **sans fumée**. | Zoom arrière 1,08 → 1,00 | Fanions qui claquent (shader balancement), vagues, Hauban qui passe (`pteranodon_vol.png`), fumée d'une cheminée, mouettes | **J'ai retrouvé Hélène. Et l'île est devenue une Réserve : rien ne se vend, tout se montre.** (16) | Musique : le thème de la jetée (`jetee.ogg` : guitare, cordes douces), tendre et chaud, 68 BPM. Bruits : fanions, mouettes, brouhaha léger d'un village content, clapotis. |
| F-02 | 9 s | **La barque d'Isaure amène les premiers visiteurs.** Vue rapprochée : la barque d'Isaure (plus grande que celle de Maïa, un petit mât) entre dans le port ; Isaure à la barre, cheveux attachés, sans masque, **le masque en carton accroché à la proue comme une figure de proue** (clin d'œil au « Bouh »). À bord, les quatre savants : M. Hamon (tout en blanc, chapeau de paille, barbe de neige, canne à pommeau d'œuf d'ambre), Ivan Malcombe (tout en noir, lunettes teintées, l'air d'expliquer quelque chose avec un doigt), le Pr Granit (chapeau de feutre, foulard rouge, pas content d'être en bateau), Élise Sablier (chemise saumon, penchée pour regarder l'eau). Autour de la barque, **Carène**, la tortue géante, nage tranquillement ; Bouline, le Baryonyx, suit. | Panoramique gauche → droite 5 % (la barque avance avec la caméra) | La barque qui tangue, le sillage (shader eau), le masque en carton qui pendouille, Carène qui ondule, le foulard de Granit au vent | **Isaure amène les visiteurs en barque, tarif unique : rien. Son masque en carton, lui, fait « Bouh » aux poissons.** (18) | Musique : même thème, un peu plus allant. Bruits : rame, cordage, eau, le souffle de Carène, un « hmpf » de Granit (bulle sonore facultative : non, on reste sans voix). |
| F-03 | 9 s | **Les forges de l'Ombre Noire, démontées.** La plaine volcanique, cendre et roche noire, le ciel clair : la grande forge (une cheminée de pierre et de fer) **à moitié démontée**, les pierres rangées en tas bien nets, l'enclume renversée. **Isaure sur une échelle**, les manches retroussées, qui dévisse à mains nues une pièce de fer, concentrée. **Roc tient l'échelle** en bas, les deux mains crispées, **les yeux fermés**, blême. Un peu plus loin, **Dame Suie** sans gants ni lunettes, assise sur une caisse, un carnet ouvert : elle refait ses tables, et à côté d'elle une théière (Roc a fait du thé). Sur l'établi, deux gants gris perle oubliés. | Zoom lent 1,00 → 1,08 sur Roc | Poussière de cendre qui vole (particules), la pièce de fer qui tourne, une mèche de Roc qui bouge, la vapeur de la théière, une braise qui s'éteint dans la forge | **Les forges de l'ambre noir, Isaure les démonte avec ses mains. Roc tient l'échelle, les yeux fermés.** (17) | Musique : clin d'œil : pizzicati et basson, comique léger, sur le thème. Bruits : grincement de métal, un boulon qui tombe « cling », le bois de l'échelle qui craque, une page de carnet. |
| F-04 | 11 s | **La tasse bleue, au Cabinet, l'après-midi.** Intérieur chaud : la table du Cabinet ; **Hélène** (chapeau posé sur la table, cheveux gris, cardigan vert, les mains un peu abîmées, une canne contre la chaise) et **Isaure** (manteau ouvert, cheveux attachés) **assises à la même table, face à face**, une théière entre elles ; devant Isaure, **la tasse bleue ébréchée** (`props/tasse_bleue.png`), fumante ; devant Hélène une tasse ordinaire. Elles ne se regardent pas tout à fait : Hélène regarde Isaure, Isaure regarde la tasse, un début de sourire. Au fond, **Roc** debout à la fenêtre, de dos, qui fait semblant de ranger un bocal. La caisse des carnets (`props/caisse_carnets.png`) sur le bureau. Lumière dorée par la fenêtre. | Zoom lent 1,00 → 1,10 sur les deux tasses | Vapeur des tasses (particules), poussière dans la lumière, le rideau, un Compsognathus qui passe la tête à la porte entrouverte puis s'en va (calque, clin d'œil) | **Hélène avait raison : rien ne se réveille de force. Une vieille amie non plus : on s'assoit à côté.** (18) | Musique : le thème se pose : piano seul puis cordes, très doux, sans gonfler. Bruits : porcelaine (`sfx/tasse-porcelaine.ogg`), l'horloge, le thé versé, un bocal reposé. |
| F-05 | 9 s | **Les gardiennes, à la Prairie du Grand Crâne, en fin de matinée.** Le Grand Crâne fossile avec ses cristaux d'ambre (comme sur l'écran titre) au second plan ; au premier plan, **Chloé et Maïa** côte à côte, de trois quarts, **l'insigne de gardienne** (disque d'ambre nu à la fougère, `ui/insigne_gardienne.png`) sur la poitrine de chacune ; Maïa (bandana rouge, débardeur moutarde) les poings sur les hanches, **Moustique** le Dimorphodon sur son épaule ; Chloé une main en visière. Derrière Maïa, **Caillou**, Tricératops adulte, en train d'éternuer (nuage de poussière). Derrière, un groupe de **visiteurs encadrés**, à pied, sur le chemin : M. Hamon assis sur **un banc** face au Crâne, Élise accroupie devant une crotte avec une loupe, deux enfants du Havre. Des Tricératops paissent au loin, un Brachiosaure passe sur la colline. | Panoramique droite → gauche 6 % | Herbes hautes et fleurs (shader), le nuage d'éternuement de Caillou (particules, une fois), le Brachiosaure qui avance très lentement, Moustique qui bat des ailes | **Maïa et moi, gardiennes : pas de cages, les dinos nous connaissent. Et Maïa veut déjà sa revanche.** (17) | Musique : le thème reprend de l'ampleur, cordes et flûte, fier et léger. Bruits : éternuement de Tricératops (gros), pépiement de Moustique, vent dans l'herbe, un brame lointain de Brachiosaure. |
| F-06 | 10 s | **Les dinos de Chloé, à l'étang des Plaines, l'heure dorée.** Au premier plan, de profil, **le dino de départ adulte** qui regarde Chloé ; Chloé assise sur une pierre au bord de l'eau, une main tendue vers lui. Derrière eux, au bord de l'étang, **des dinos de l'île qui boivent, sans espèce reconnaissable de près** (des silhouettes à contre-jour : un long cou, une collerette, une voile dorsale, un crâne à crête). **Trois variantes de la même image**, seul le premier plan change : **(Vif)** un Velociraptor adulte, plumes gris-vert, qui se gratte le menton contre la main de Chloé, les deux « dents de plus » visibles dans un sourire ; **(Bastion)** un Ankylosaurus adulte couvert d'un début de lichen, et **Maïa assise dessus** en train de manger une pomme, Chloé qui rit ; **(Écho)** un Parasaurolophus adulte à crête corail, la tête levée, **des petites notes** qui sortent de sa crête, et un oiseau de l'étang qui se bouche les oreilles avec ses ailes. | Zoom lent 1,00 → 1,08 sur le dino et la main de Chloé | Reflets de l'étang (shader), libellules (`fauna/libellule.png`), le souffle du dino (particules légères), les notes d'Écho qui montent (calque), le pollen | **(Vif)** `%s` **a deux dents de plus. Et bientôt d'autres bébés : Hélène m'apprend à réveiller les derniers œufs.** (17) · **(Bastion)** `%s` **a grandi, on s'assoit encore dessus. Et bientôt d'autres bébés : Hélène m'apprend à réveiller les derniers œufs.** (18) · **(Écho)** `%s` **chante toujours faux, le matin. Et bientôt d'autres bébés : Hélène m'apprend à réveiller les derniers œufs.** (17) — `%s` = `Game.starter_name()` | Musique : variation tendre et un peu drôle du thème, flûte et cordes pincées. Bruits : le cri neutre de l'espèce (`cries/` existants), l'eau, libellules ; Écho : trois notes fausses (générées). |
| F-07 | 9 s | **Brac, gardien de nuit, au bout de la jetée.** Nuit de pleine lune : la jetée vide, la mer argentée, et au loin **les falaises d'ambre qui luisent** (rappel de I-02). Au bout, **Brac** assis sur une caisse, de trois quarts, son chapeau, sa barbe rousse pleine de cendre, **sans masque**, un sandwich à la main, l'air faussement sévère et très content. À côté, **Mastoc** l'Allosaurus, assis comme un gros chien, **tient la lanterne dans sa gueule**, l'œil inquiet vers le noir ; **Cabosse** (Stygimoloch) et **Grognon** (Majungasaurus) dorment en tas, l'un ronfle (petites bulles). Planté au bord : un **panneau de bois** où Roc a peint « BARC » en grosses lettres maladroites (c'est le seul texte autorisé dans une image). Sur le panneau, un Compsognathus perché. | Zoom lent 1,00 → 1,08 sur Brac et Mastoc | La flamme de la lanterne (calque, scintillement + halo), les bulles du ronfleur (calque), reflets de lune, les filons d'ambre qui respirent au loin, la queue de Mastoc | **Brac connaissait les cages ; maintenant, il garde les dinos la nuit. Enfin, « BARC », d'après le panneau.** (16) | Musique : la nuit : contrebasse pizzicato, un xylophone pour le ronflement, tendre et rigolo. Bruits : grillons, ressac, le ronflement de Grognon, un petit gémissement de Mastoc, le papier du sandwich. |
| F-08 | 11 s | **Le Souverain au bord du volcan, au crépuscule.** Très grand plan : le bord du cratère, roche noire veinée d'ambre ; **le Souverain couché** en travers de la crête, immense (planche `souverain_couche.png`, colonne apaisée : brun-gris, veines d'ambre **presque éteintes**, juste un fil d'or ; **yeux ambrés ouverts, calmes**), la tête tournée vers **la mer** : en bas, toute l'île en spirale jusqu'au port minuscule où brillent les lanternes de la jetée ; le ciel rose et or, les premières étoiles. **Le Roi des Cieux** tourne haut, très loin. Aucune fumée. Du souffle du Souverain, un peu de cendre s'envole. | Zoom arrière très lent 1,10 → 1,00 (de l'œil du Souverain à toute l'île) | La cendre soulevée par le souffle (particules, au rythme lent d'une respiration), les veines d'ambre du sol qui respirent, le Roi qui tourne (`quetzalcoatlus_vol.png`), les étoiles qui s'allument, les lanternes du port qui scintillent | **Le Souverain veille, sans peur. Les géants du cratère dorment encore : je les réveillerai un à un, doucement.** (18) | Musique : le plus grand moment : un accord large tenu, cors doux, cordes, sans percussion, « vaste et calme ». Bruits : `cries/souverain-souffle.ogg` (lent, deux fois), le vent des hauteurs, rien d'autre. |
| F-09 | 11 s | **Le journal, page 40 et page 41.** Plein cadre, de dessus : le journal ouvert sur le bureau du Cabinet, à la lumière de la lampe. **À gauche, la page 40**, de l'écriture penchée d'Hélène (suggérée, illisible), signée d'un « — H. » lisible, la fougère séchée posée dessus. **À droite, une page blanche**, et **la main de Chloé** (manche sarcelle, le bracelet d'ambre) qui commence au crayon **un dessin : une fougère, et le museau d'un dino** (un museau générique, de profil, qui va pour les trois espèces). Le stylo-plume d'Hélène posé à côté du crayon. Un coin de la tasse bleue dans le cadre, vide. | Zoom lent 1,00 → 1,10 sur la page blanche et le crayon | **Le trait de crayon qui avance** (masque animé sur un calque « crayon », comme I-05), la flamme de la lampe, la poussière, le coin de la page 40 qui se soulève | **« Ce qui dort n'est pas mort. » Le Cabinet est à moi, et il reste des pages blanches.** (17) | Musique : retour au piano seul, le motif de la boîte à musique de I-03, apaisé. Bruits : crayon sur le papier, la lampe, l'horloge. |
| F-10 | 8 s | **Carton « Ambrelune ».** Fondu depuis F-09 vers **C-01** (voir les crédits : la mer au crépuscule depuis la jetée), et le titre **« Ambrelune »** au centre, grand, couleur ambre. Il reste, puis monte lentement et laisse la place au défilé des crédits sur le même fond. | Zoom lent 1,00 → 1,04 sur la mer | Vagues, étoiles qui s'allument, lanternes (voir C-01) | **Ambrelune** | Musique : la dernière phrase du thème, un point d'orgue ; les crédits enchaînent sur `credits.ogg` (ou `titre.ogg`). |

Durée : 10 + 9 + 9 + 11 + 9 + 10 + 9 + 11 + 11 + 8 = **97 s** hors crédits (fondus compris, ~100 s). Dans la fourchette
90-120 s.

### Prompts nano-banana (fin)

Même `STYLE` qu'à l'intro. Fiches à coller selon l'image :

```
CHLOÉ, ISAURE: see the intro (Isaure here: hair tied, no mask, sleeves rolled up when working).
MAÏA: a 12-year-old girl (1.50 m), warm brown skin, black curly hair in a big puff, red bandana, mustard-yellow tank
top, navy cargo shorts, a coil of rope on her shoulder, a huge grin. Reference: assets/art/characters/maia.png.
HÉLÈNE: a kind elderly woman of about 70 (1.60 m), grey hair in a bun, a wide straw hat, green cardigan over a cream
blouse, brown skirt, brown boots, a wooden cane, a gentle wrinkled smile; her hands are a little scarred (subtle, not
scary). Reference: assets/art/characters/helene.png, helene_assise.png.
ROC: Professor Anselme Roc, about 70, bald with white side hair and a white moustache, round glasses, a cream lab coat
over a brown waistcoat and a green bow tie, grumpy-kind. Reference: assets/art/characters/roc.png.
BRAC: a huge bearded poacher (2 m), brown wide-brimmed hat, bushy dark-red beard dusted with ash, patched brown coat,
a bandolier of small amber vials, no mask, gruff but good-natured. Reference: assets/art/characters/brac.png,
brac_assis_cage.png.
DAME SUIE: a tall slender woman in an ash-grey coat and a hat with a small veil, no gloves, no glasses, pale and
precise, holding a notebook of tables. Reference: assets/art/characters/dame_suie_sans_lunettes.png.
VISITORS: M. HAMON, an old man all in white with a straw hat, a snow-white beard and a cane topped with an amber egg
(hamon.png); IVAN MALCOMBE, a man all in black with a leather jacket and tinted glasses (malcombe.png); PR GRANIT, a
palaeontologist with a felt hat, denim shirt and red scarf (granit.png); ÉLISE SABLIER, a botanist in a knotted
salmon shirt, shorts and boots (elise.png).
SOUVERAIN: a colossal archaic archosaur about 12 m long, a low quadruped with a long theropod-like head, a double row
of back plates, olive-brown hide with faint amber veins (almost extinguished, a thin gold thread), calm amber eyes
wide open, lying down. NOT purple, NOT glowing crystals. Reference: assets/art/dinos/souverain_couche.png (third
column) and souverain.png.
DINOS: Caillou, an adult Triceratops (triceratops.png); Moustique, a small Dimorphodon (dimorphodon.png); Mastoc, an
Allosaurus (allosaurus.png); Cabosse, a Stygimoloch (stygimoloch.png); Grognon, a Majungasaurus (majungasaurus.png);
Hauban, a Pteranodon with a salt-striped beak (pteranodon.png, pteranodon_vol.png); Carène, a giant Archelon sea
turtle (archelon.png); Bouline, a Baryonyx (baryonyx.png); Vif, an adult Velociraptor with grey-green feathers
(velociraptor.png); Bastion, an adult Ankylosaurus (ankylosaurus.png); Écho, an adult Parasaurolophus with a coral
crest (parasaurolophus.png).
```

- **F-01** — `STYLE + A small stone fishing village in a cove seen from the sea on a bright morning, celebrating: a
  long wooden jetty decorated with strings of pastel bunting and lanterns, a freshly painted wooden sign at the
  entrance with a painted fern (no readable letters), houses with shutters open and full fishing nets drying, a ruined
  lighthouse. A small crowd of villagers on the jetty seen from a distance (an old lady with a straw hat on the arm of
  an old professor, fishermen, a boy, two old women); at the far end a big bearded man sitting with three dinosaurs. A
  Pteranodon flies over with a fish in its beak. Green hills, tree ferns, and a quiet volcano with no smoke in the
  background. Joyful, warm.` Références : `accueil-paysage.webp`, `props/phare_ruine.png`, `props/filet.png`,
  `props/lanterne.png`, les planches de Hélène, Roc, Brac, `leonce_port.png`.
- **F-02** — `STYLE + ISAURE + VISITORS + A wooden sailing boat with a small mast entering a harbour on calm morning
  water, close view. ISAURE at the tiller, hair tied, calm and proud; a small cardboard dinosaur mask hangs from the
  bow like a figurehead. On board four visitors: M. HAMON, IVAN MALCOMBE explaining something with one finger, PR
  GRANIT looking unhappy to be on a boat, ÉLISE SABLIER leaning over to look at the water. Beside the boat a giant sea
  turtle (Carène) swims calmly, and a Baryonyx (Bouline) follows behind. Village and jetty softly in the background.`
  Références : `props/barque.png`, `ui/masque_carton.png`, `characters/isaure_masque_carton.png`, `hamon.png`,
  `malcombe.png`, `granit.png`, `elise.png`, `dinos/archelon.png`, `dinos/baryonyx.png`.
- **F-03** — `STYLE + ISAURE + ROC + DAME SUIE + A black volcanic plain under a clear sky: a big stone-and-iron forge
  half dismantled, its stones stacked in tidy piles, an overturned anvil. ISAURE stands on a wooden ladder with her
  sleeves rolled up, unscrewing an iron part with her bare hands, focused. At the bottom ROC holds the ladder with both
  hands, eyes squeezed shut, pale. A little apart DAME SUIE sits on a crate writing in a notebook of tables, a teapot
  beside her; two pearl-grey gloves lie forgotten on a workbench. Gentle, funny, hopeful; no fire burning.`
  Références : `assets/art/battle/volcan.jpg` (la plaine), `characters/isaure_sans_masque.png`, `roc.png`,
  `dame_suie_sans_lunettes.png`, `props/caisses.png`.
- **F-04** — `STYLE + HÉLÈNE + ISAURE + ROC + Cosy interior of the old naturalist's study in warm afternoon light:
  HÉLÈNE (hat on the table, cane against her chair) and ISAURE (coat open, hair tied) sit at the same wooden table
  facing each other with a teapot between them; in front of Isaure a chipped blue china cup steaming, in front of
  Hélène a plain cup. Hélène looks at Isaure; Isaure looks at the cup with the beginning of a smile. In the background
  ROC stands at the window with his back to us pretending to tidy a jar. A wooden crate of notebooks on the desk,
  shelves of amber jars, ivy at the window. Tender, quiet, warm.` Références : `props/tasse_bleue.png`,
  `props/caisse_carnets.png`, `props/bureau.png`, `characters/helene_assise.png`, `isaure_sans_masque_assise.png`,
  `roc.png`.
- **F-05** — `STYLE + CHLOÉ + MAÏA + A sunny prehistoric meadow with a giant fossil dinosaur skull studded with glowing
  amber crystals in the middle ground. In the foreground CHLOÉ and MAÏA stand side by side, three-quarter view, each
  wearing a round amber badge with a fern on her chest; Maïa with fists on her hips and a small Dimorphodon on her
  shoulder, Chloé shading her eyes with one hand. Behind Maïa an adult Triceratops sneezes a puff of dust. On a path
  behind them a small guided group of visitors on foot: an old man in white sitting on a wooden bench facing the skull,
  a botanist crouching with a magnifying glass, two children. Triceratops graze in the distance, a Brachiosaurus walks
  along the hill. Bright, proud, funny.` Références : `accueil-paysage.webp` (le Grand Crâne), `ui/insigne_gardienne.png`,
  `characters/chloe.png`, `maia.png`, `dinos/triceratops.png`, `dinos/dimorphodon.png`, `props/banc.png`, `hamon.png`,
  `elise_accroupie.png`.
- **F-06 (base, puis trois éditions)** — base : `STYLE + CHLOÉ + A calm pond in a prehistoric meadow at golden hour,
  reflections, dragonflies, tall grass and pink flowers. CHLOÉ sits on a flat stone at the water's edge, one hand held
  out to her left towards an empty space in the foreground (to be filled). Along the far shore, backlit silhouettes of
  dinosaurs drinking, not recognisable in detail: a long neck, a frill, a sail back, a crested skull. Peaceful, warm.`
  Puis trois éditions de la même image, en ajoutant au premier plan : **(Vif)** `an adult Velociraptor with grey-green
  feathers, in profile, rubbing its chin against Chloé's hand and grinning (two extra teeth showing)` ; **(Bastion)**
  `an adult Ankylosaurus with patches of orange lichen on its armour, in profile, and MAÏA sitting on its back eating
  an apple, while Chloé laughs` ; **(Écho)** `an adult Parasaurolophus with a coral-pink crest, head raised, little
  musical notes drifting from its crest, and a small pond bird covering its ears with its wings`. Références :
  `dinos/velociraptor.png`, `ankylosaurus.png`, `parasaurolophus.png`, `characters/chloe_assise.png`, `maia_assise.png`,
  `fauna/libellule.png`.
- **F-07** — `STYLE + BRAC + Night of the full moon at the end of an empty wooden jetty, silver sea, and far away
  cliffs with veins of amber glowing gold. BRAC sits on a crate holding a sandwich, hat on, no mask, looking mock-stern
  and very content. Beside him an Allosaurus sits like a big dog holding a lit lantern in its mouth, eyes a little
  worried about the dark; a Stygimoloch and a Majungasaurus sleep in a heap, one snoring with little bubbles. A wooden
  sign planted at the edge reads "BARC" in big clumsy painted letters (this is the only text allowed); a tiny
  Compsognathus perches on the sign. Cosy, funny, safe.` Références : `characters/brac_assis_cage.png`, `brac.png`,
  `dinos/allosaurus.png`, `stygimoloch.png`, `majungasaurus.png`, `props/lanterne.png`, `props/caisses.png`.
- **F-08** — `STYLE + SOUVERAIN + A vast view from the rim of a volcanic crater at dusk: black rock veined with faint
  amber. The SOUVERAIN lies across the ridge, enormous, head turned towards the sea; below, the whole round island
  spirals down through forest, swamp, desert and coast to a tiny harbour where jetty lanterns glow; pink-and-gold sky
  with the first stars; a giant pterosaur circling very high and far. No smoke, no fire. A little ash lifts from the
  creature's breath. Awe, peace, immensity, not scary.` Références : `dinos/souverain_couche.png` (colonne 3),
  `assets/art/battle/apex.jpg`, `ui/atlas_ile.png` (la spirale), `dinos/quetzalcoatlus_vol.png`.
- **F-09** — `STYLE + Top-down close view of an open leather-bound journal on a wooden desk by lamplight. Left page:
  a full page of slanted old handwriting (unreadable) ending with a readable signature "— H.", a dried fern lying on it.
  Right page: blank, where a child's hand (teal sleeve, a small amber bracelet) is drawing in pencil the beginning of a
  fern and the profile of a dinosaur snout (generic, no species). An old fountain pen beside the pencil; the corner of
  a chipped blue cup, empty, at the edge of the frame. Warm, intimate.` Références : I-03 (même journal, même lampe),
  `props/tasse_bleue.png`, `ui/fougere.png`, `characters/chloe_main.png`. **Demander aussi la version SANS le trait de
  crayon** (page de droite vide, la main et le crayon posés) : le moteur dessine le trait.
- **F-10 / C-01** — voir les crédits.

---

## Les CRÉDITS (après F-10 ; aussi depuis le menu titre)

### Mise en scène

- **Fond C-01, une seule illustration animée** : *la mer au crépuscule, vue du bout de la jetée de Port-Ambre*. Au
  premier plan à droite, le bord de la jetée, la lanterne de Brac posée sur sa caisse (sans Brac), le panneau « BARC » de
  dos (sans texte visible) ; à gauche, quelques pieux et un cordage ; devant, la mer rose et or, puis bleue ; à gauche
  au loin, les falaises ; tout au fond, sur la ligne du volcan, **la silhouette couchée du Souverain**, minuscule. Le
  ciel occupe la moitié haute : c'est là que défilent les crédits (le ciel est peint uni et doux, sans détail, pour la
  lisibilité).
- **Animation du fond (moteur)** : le ciel passe lentement du crépuscule à la nuit en 90 s (dégradé interpolé sur un
  calque ciel), **les étoiles s'allument une à une** (particules), la lune monte, les falaises d'ambre se mettent à
  luire quand la nuit tombe (calque ambre), les vagues (shader), la lanterne scintille. **Des dinos passent**, avec les
  sprites existants du jeu, en silhouette ou en couleur selon la lumière : Hauban (`pteranodon_vol.png`) qui plonge
  pêcher et remonte ; la carapace de Carène qui traverse ; un Grand Voyageur (le Brachiosaure du voyage rapide) qui
  passe sur la colline au loin ; deux Compsognathus qui courent sur les planches au premier plan ; vers la fin, Mastoc
  qui vient chercher la lanterne et repart avec (clin d'œil). Jamais plus d'un passage à la fois ; chacun dure 6-10 s.
- **Défilé** : cartons centrés, montée continue (~25 px/s en 1280 × 720, lisible par un enfant), avec des **titres**
  en ambre `#fac259` et des lignes en crème ; 60 à 90 s au total selon la longueur de `docs/credits.md`. **Passer**
  comme pour les cinématiques (une pression affiche, une seconde passe). Depuis le menu titre : mêmes crédits, même
  fond ; à la fin, retour au titre.
- **Musique** : `credits.ogg` (reprise du thème du titre, harpe et flûte, en boucle), ou simplement **`titre.ogg`**,
  qui existe déjà et dont c'est le thème. Bruits : la mer, les grillons, la lanterne, les cris des dinos qui passent.

### Ordre des cartons

1. **Un jeu de Grégory Cuypers**
   *création, histoire, direction artistique, choix et validation*
   *(seul carton en grand, seul au centre pendant 5 s avant que le défilé commence)*
2. **Fait avec des outils**
   - Code et écriture : **Claude** (Anthropic)
   - Images : **nano-banana** (Gemini, Google)
   - Musiques et ambiances : **Stable Audio**
   - Bruitages : **ElevenLabs**
   - Moteur : **Godot Engine**
   *(l'agent des licences peut compléter cette liste depuis `docs/credits.md` : Blender, ComfyUI, etc., si quelque chose
   d'autre a servi à ce qui est dans le jeu)*
3. **Assets et licences** : contenu fourni par `docs/credits.md` (plugins Godot : GdUnit4, LimboAI, Phantom Camera,
   Saltmire, VFX… ; polices ; sons repris ; chaque ligne avec son auteur et sa licence, telle que l'agent des
   licences la rédige). **Je n'écris pas ce contenu ici** : les crédits lisent `docs/credits.md` (ou une liste que
   l'agent CODE en tire), pour qu'il n'y ait qu'une source.
4. *(Décision 3 : « Pour Chloé »)* — texte dans `cinematiques_textes.md` § c : **« Pour Chloé. / Cette île est à
   toi. Elle l'a toujours été. »**
5. **Merci d'avoir joué**
   *(dernier carton, reste 4 s, puis fondu ; à la suite de la fin du jeu : le carton « L'île est à vous. Les géants du
   cratère se réveillent un à un… », puis la jetée.)*

---

## Les ASSETS à produire

### Illustrations (nano-banana, 2560 × 1440, 16:9, marge 10 %)

| Fichier (proposition : `assets/art/cinematiques/`) | Contenu | Calques à part |
|---|---|---|
| `intro_01_large.png` | I-01 la mer, l'île au loin | mer (pour le shader), 2 calques brume, (ptérosaures : sprites existants) |
| `intro_02_falaises.png` | I-02 les falaises d'ambre à la pleine lune | calque « ambre » (filons seuls, pour la pulsation), eau |
| `intro_03_cabinet.png` | I-03 le journal ouvert, la nuit | flamme de la lampe, coin de page |
| `intro_04_oeufs.png` | I-04 la couveuse, trois œufs | lueur ambrée |
| `intro_05_carte.png` + `intro_05_carte_vide.png` | I-05 la carte (encrée / papier vide) | le calque encre = la différence des deux ; les petits dinos en 2 images (facultatif : un seul calque qui tremble) |
| `intro_06_chambre.png` | I-06 Chloé et le sac trop plein | lacet, rideau, queue de peluche |
| `intro_07_ponton.png` | I-07 le saut dans la barque | mouette (3 images), gerbe d'eau (particules moteur) |
| `intro_08_brume.png` | I-08 la traversée (avec ou sans l'ombre de Carène : décision 4) | 3 calques brume, barque + personnages (pour le tangage) |
| `intro_09_arrivee.png` | I-09 l'île apparaît | 2 calques brume qui s'écartent, mer |
| `fin_01_jetee_fete.png` | F-01 la jetée en fête | fanions, mer, fumée de cheminée |
| `fin_02_barque_visiteurs.png` | F-02 la barque d'Isaure, les visiteurs, Carène | barque + passagers (tangage), masque en carton, sillage |
| `fin_03_forges.png` | F-03 Isaure, Roc, Dame Suie aux forges | pièce de fer, vapeur, braise |
| `fin_04_tasse_bleue.png` | F-04 Hélène et Isaure, la tasse bleue | vapeur, rideau, (Compsognathus : sprite existant) |
| `fin_05_gardiennes.png` | F-05 Chloé et Maïa, les visiteurs, Caillou | herbes (shader), nuage d'éternuement (particules) |
| `fin_06_dinos_base.png` + `fin_06_dinos_{vif,bastion,echo}.png` | F-06 l'étang ; trois premiers plans (décision 2) | étang (shader), notes d'Écho, libellules (sprite) |
| `fin_07_brac_nuit.png` | F-07 Brac, Mastoc et la lanterne, « BARC » | flamme + halo, bulles de ronflement, ambre au loin |
| `fin_08_souverain.png` | F-08 le Souverain au bord du volcan | cendre (particules), veines du sol, étoiles (particules), (le Roi : sprite existant) |
| `fin_09_journal.png` + `fin_09_journal_sans_trait.png` | F-09 pages 40 et 41 | le trait de crayon = la différence ; flamme, coin de page |
| `credits_fond.png` | C-01 la mer au crépuscule depuis la jetée (ciel uni en haut) | ciel (dégradé moteur), calque ambre des falaises, lanterne, mer |

Total : **21 peintures** (9 + 10 + 1 fond, dont 2 doubles « avec/sans » et 3 variantes de F-06) ; les calques animés sont
des découpes des peintures (éditions nano-banana « the same image without X » ou détourage) ou des sprites déjà dans
le jeu. Les cartons (« Ambrelune », « Trois jours plus tard »…) restent du texte du moteur, sans image.

### Musiques (Stable Audio ; `assets/audio/music/`, .ogg stéréo, ~-16 LUFS ; prompt négatif commun de `sons-a-generer.md`)

| Fichier | Durée | Boucle | Humeur, structure | Prompt (anglais) |
|---|---|---|---|---|
| `cinematique_intro_a.ogg` | 40 s | non | I-01 → I-05 : mystère lumineux puis émerveillement : cordes graves tenues et harpe (0-14 s), un carillon doux sur la lueur de l'ambre, puis boîte à musique / célesta chaleureux et malicieux (14-30 s), pizzicati curieux qui avancent et un roulement sourd à la fin (30-40 s) | `Gentle fantasy orchestral intro for a children's adventure, 60 to 72 BPM, starts with low sustained strings and distant harp over a misty sea, a soft glockenspiel sparkle, then a warm music-box celesta melody full of wonder and a hint of mischief, then curious pizzicato strings that walk forward and a low soft timpani roll at the very end, cinematic, warm, no vocals, not scary, ends on a suspended note` |
| `cinematique_intro_b.ogg` | 34 s | non | I-06 → carton : l'élan : guitare rythmée et caisse claire légère (100 BPM), accent de cuivres sur le saut, retenue en sourdine dans la brume, puis le **thème du titre** (harpe, flûte, comme `titre.ogg`) en plein, solaire, qui se pose sur une note tenue | `Joyful adventurous fantasy orchestral, 100 BPM, bright rhythmic acoustic guitar and light snare, a short brass accent, then strings held back softly in a mist for a few bars, then a big sunny arrival with soaring flute and harp melody and warm full strings, triumphant but gentle, for a children's game, no vocals, ends on a long held warm chord` |
| `cinematique_fin.ogg` | 100 s | non | F-01 → F-10 : tendre et chaud (guitare, cordes, 68 BPM) ; clin d'œil comique léger (pizzicati, basson) ; piano seul et cordes très douces ; reprise fière et légère (cordes, flûte) ; un accord large tenu, cors doux, sans percussion (le Souverain) ; retour au piano seul et au motif de boîte à musique ; point d'orgue | `Tender nostalgic fantasy theme for the ending of a children's game, 68 BPM, solo acoustic guitar and soft strings on a wooden pier at dusk, a brief playful passage with pizzicato strings and a bassoon, then solo piano very quiet, then proud light strings with a flute melody, then a vast calm held chord with soft french horns and no percussion, then back to solo piano with a small music-box motif, ending on a gentle final cadence, warm and hopeful, no vocals` |
| `credits.ogg` *(facultatif : sinon `titre.ogg`)* | 90 s | oui | Reprise du thème du titre (harpe, flûte), douce, en boucle, sans montée | `Soft fantasy end-credits loop, 72 BPM, harp arpeggios and a gentle flute melody, warm string pad, sea breeze feeling, calm and grateful, seamless loop, no vocals` |

Les deux moitiés de l'intro s'enchaînent par un fondu enchaîné de 2 s pendant I-05 → I-06 (le moteur), ce qui évite
de demander à Stable Audio un changement de tempo au milieu d'une piste. Si Stable Audio sort une piste de 70 s qui
tient les deux humeurs, une seule `cinematique_intro.ogg` suffit.

### Bruitages (ElevenLabs quand le quota revient, sinon existants ; `assets/audio/…`, .ogg)

| Fichier | Durée | Pour | Existe déjà ? |
|---|---|---|---|
| `ambience/houle-large.ogg` | 10 s, boucle | I-01, I-02, I-08, I-09, F-01, C-01 | reprendre l'ambiance mer de Port-Ambre si elle existe (`data/ambience_db.gd`), sinon à générer |
| `ambience/brume-vent-feutre.ogg` | 10 s, boucle | I-08 | à générer |
| `ambience/grillons-nuit.ogg` | 10 s, boucle | F-07, C-01 | reprendre l'ambiance de nuit du jeu si elle existe |
| `sfx/page-froissee.ogg` | 2 s | I-03, F-09 | à générer |
| `sfx/plume-gratte.ogg` | 6 s | I-05 (suit le tracé) | à générer |
| `sfx/crayon-papier.ogg` | 6 s | F-09 | à générer |
| `sfx/horloge-tictac.ogg` | 10 s, boucle | I-03, F-04, F-09 | à générer |
| `sfx/lampe-huile.ogg` | 4 s, boucle | I-03, F-09 | à générer (très discret) |
| `sfx/oeuf-toc.ogg` | 1 s | I-04 (un seul toc) | à générer |
| `sfx/lacet-fermeture-eclair.ogg` | 3 s | I-06 | à générer |
| `sfx/objet-tombe-toc.ogg` | 1 s | I-06 | à générer |
| `sfx/saut-planches-plouf.ogg` | 3 s | I-07 (saut + gros plouf + coque qui cogne) | à générer |
| `sfx/mouette-vexee.ogg` | 2 s | I-07 | à générer |
| `sfx/rames.ogg` | 6 s, boucle | I-07, I-08, F-02 | à générer |
| `sfx/brume-se-dechire.ogg` | 3 s | I-09 (un souffle montant) | à générer |
| `sfx/fanions-vent.ogg` | 6 s, boucle | F-01 | à générer |
| `sfx/brouhaha-village.ogg` | 8 s, boucle | F-01 (léger, content, sans mots reconnaissables) | à générer |
| `sfx/metal-grince-boulon.ogg` | 4 s | F-03 | à générer |
| `sfx/echelle-craque.ogg` | 2 s | F-03 | à générer |
| `sfx/tasse-porcelaine.ogg` | 2 s | F-04 | **existe** (`assets/audio/sfx/`) |
| `sfx/the-verse.ogg` | 3 s | F-04 | à générer |
| `sfx/eternuement-triceratops.ogg` | 2 s | F-05 | à générer (gros, drôle) |
| `sfx/echo-notes-fausses.ogg` | 3 s | F-06 (Écho) | à générer (trois notes de crête, fausses) |
| `sfx/ronflement-dino.ogg` | 6 s, boucle | F-07 | à générer |
| `sfx/gemissement-mastoc.ogg` | 2 s | F-07 | à générer (petit, pas triste) |
| `cries/souverain-souffle.ogg` | 4 s | F-08 (deux fois, lent) | **existe** (`assets/audio/cries/`) |
| `ambience/vent-hauteurs.ogg` | 10 s, boucle | F-08 | **existe** (`assets/audio/ambience/`) |
| cris des dinos (Ptéranodon, Tricératops, Velociraptor, Ankylosaurus, Parasaurolophus, Allosaurus, Brachiosaure, Compsognathus, Dimorphodon) | — | partout | **existent** (`assets/audio/cries/`, par espèce) |

---

## Continuité vérifiée

- **Qui sait quoi à l'intro** : le joueur ne sait rien ; la capitaine n'est pas nommée ; aucune image ne montre la
  lettre (donnée par Roc), ni Maïa, ni un masque d'os, ni le Souverain, ni les Cœurs. Le journal ouvert et la carte
  sont ceux d'il y a un an (le soir de la page 38) : une page arrachée proprement (elle a dispersé ses pages), le « ? »
  sur le volcan (ce qu'elle ne dit pas). Les trois œufs sont des œufs (ils éclosent à l'arrivée : « Ils viennent
  d'éclore », `Prologue._roc_intro`). Le clin d'œil de la page 3 (« Les légendes, ça se trouve ») ne révèle rien.
  Carène sous la barque (I-08) est une décision de Greg (n° 4).
- **Chloé** : 1,50 m, fine, queue de cheval, yeux bruns, taches de rousseur, tenue des planches ; cheveux châtain foncé
  (décision n° 1). Elle est de dos en I-09 pour que l'arrivée soit l'île, pas elle.
- **Enchaînement intro → jeu** : carton « Ambrelune », fondu, le quai de Port-Ambre avec Isaure à côté de Chloé et
  Caillou endormi sur le quai (`Prologue.arrival`) : la première réplique du jeu (« Et voilà Ambrelune, moussaillon.
  Regarde les falaises… ») répond à la dernière image sans la répéter.
- **La fin, le dino en tête** : F-06 suit `Game.starter_dino()` (exigé dans l'équipe depuis l'aube du ch. 9) et
  `Game.starter_name()` (renommable) ; le dino est adulte (niveau 48-50 à la fin ≥ 14). Les autres dinos de Chloé,
  variables, ne sont que des silhouettes. Le troisième petit, Fournaise, Flocon, Braise n'apparaissent pas.
- **Drapeaux de fin** : tout ce que la fin montre est posé avant le fondu : `reserve_annoncee`, `brac_gardien`,
  `gardiennes_nommees`, `masque_carton_porte`, `moustique_rendu`, `masque_carton_pris`, `found_journal_40`,
  `epilogue_fini`, `post_game`. Les forges démontées (F-03) sont annoncées au Cabinet (4 c) et confirmées en post-game
  (`roc_epilogue_n`, `isaure_barque_n`) : la cinématique les montre « en cours », ce qui est juste après la jetée. Les
  moufles n'apparaissent pas (drapeau optionnel). La lettre n'apparaît pas.
- **Apparences de fin** : Isaure cheveux attachés sans masque (`isaure_sans_masque.png`), le masque en carton avec elle
  (F-02, en figure de proue) ; Brac sans masque (jeté dans la cendre), avec Mastoc, Cabosse, Grognon, la lanterne à
  Mastoc, le panneau « BARC » ; Dame Suie sans gants ni lunettes (gants gris perle sur l'établi : F-03) ; Hélène chapeau
  de paille, canne, mains abîmées discrètes ; Maïa avec Moustique et Caillou Tricératops adulte ; insignes de gardienne
  (`ui/insigne_gardienne.png`) ; le Souverain couché **apaisé** (colonne 3 de `souverain_couche.png`, pas de violet),
  yeux ouverts, sans fumée au volcan ; Hauban qui pêche (« Il a repris tout seul. »).
- **Page 40** : la citation est exacte (« Ce qui dort n'est pas mort. ») ; la page 41 blanche et le crayon de Chloé
  illustrent « Le Cabinet est à toi » et ouvrent le post-game (« Les autres, c'est toi. Doucement. »).
- **Règle « scènes courtes »** *(version 2)* : au plus deux phrases courtes par image, 18 mots au plus (comptés dans
  `cinematiques_textes.md`) ; 9 puis 10 images ; tout se passe d'une pression. Aucune voix.

## Autocritique (deux passes)

**Passe 1 : drôle et plein d'élan (intro), émouvant sans larmoyer (fin).** Première version de l'intro : Chloé lisait la
lettre d'Hélène dans sa chambre, et la cinématique s'ouvrait sur le Cabinet. Retiré : la lettre est donnée par Roc
dans le jeu (continuité), et ouvrir sur le Cabinet était « mystérieux-doux », pas aventureux. Remplacé par la mer et
l'île (I-01, I-02), puis trois gags visuels (le « Des vrais. », le sac trop plein avec la queue de peluche, le saut
dans la barque et la mouette vexée) et un « Enfin, presque. » ; la musique démarre à I-06 et pas avant, pour que
l'élan se sente. Première version de la fin : onze images, dont « Bouh » rejoué, Hélène avec les moufles, et une image
de Chloé seule au bout de la jetée qui regardait la mer. Retiré : le « Bouh » est le sommet de la scène jouée, le
rejouer l'affadit (il reste en clin d'œil : le masque en figure de proue) ; les moufles dépendent d'un drapeau ; Chloé
seule face à la mer tirait la larme pour rien. Les trois images émues (la tasse, le Souverain, le journal) sont
chacune suivies ou précédées d'une drôlerie (Roc les yeux fermés, Mastoc et sa lanterne, l'oiseau qui se bouche les
oreilles), et la dernière phrase regarde devant (« Il reste des pages blanches. »).

**Passe 2 : continuité et rythme.** Vérifié ci-dessus (qui sait quoi, dino en tête, drapeaux). Deux corrections faites
pendant cette passe : (1) I-05 disait « Sur sa carte, chaque région a ses dinos… » (14 mots, à la limite) : raccourci à
11 ; (2) F-06 montrait d'abord Braise et Flocon derrière le dino de départ : ce sont des captures optionnelles ;
remplacés par des silhouettes. Durées : intro 70 s + carton (cible 60-80), fin 97 s (cible 90-120). Faiblesses
connues : I-05 et F-09 demandent une révélation progressive d'un trait (un masque animé : simple, mais à coder) ; F-06
coûte trois éditions ; le ciel de C-01 doit rester uni pour la lisibilité des crédits, ce qui bride un peu la peinture.
