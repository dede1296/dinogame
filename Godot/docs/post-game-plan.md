# Post-game — plan proposé (20/10/2026, agent HISTOIRE, Fable)

> Écrit d'après `.claude/progress.md`, `chapitre-9-plan.md`, `chapitre-9-scenes.md` (§ Autour, § Objectifs,
> § Autocritique), `chapitre-8-plan.md`, `cinematiques_textes.md` (la fin annonce le post-game : F-05 la revanche
> de Maïa, F-06 les derniers œufs, F-08 les géants « que je réveillerai un à un, doucement »), `histoire.md`
> § Post-game et § Le journal (page 17 : « ceux-là dorment pour de bon… pour l'instant »), `bestiaire.md` § Terre
> des Apex, `mecaniques.md` (Nouvelle partie+, fossiles, Dinodex, le Relais), et le code qui existe déjà :
> `story/epilogue.gd`, `story/apex*.gd` (`ApexAutour.maia` attend `ApexBattles.maia_team` ; `A.bloc` ; les
> résidents ; `brac_jetee`), `data/dialogue_apex.gd` (les répliques du post-game déjà écrites : Hélène, Isaure,
> Maïa, Brac, Suie, Léonce, les Anciens), `battle/apex_battles.gd` et `apex_engine.gd` (la commande « Sceaux »),
> `story/havre.gd` (la revanche par jour du Relais), `story/plaines_annexes.gd` (fragment → œuf),
> `story/desert_places.gd` (les six fossiles enfouis), `core/game_state.gd` (`new_game`, `egg`, `day`),
> `core/save_system.gd` (trois emplacements, `finished`), `ui/save_slots.gd`. **Rien n'est codé** : ce plan et
> `post-game-scenes.md` (texte complet) attendent Greg. Aucun autre fichier n'est modifié.

## Ce qui est déjà là (à ne pas refaire)

- Le drapeau `post_game` et les six objectifs du post-game (`ApexObjectives.side` : géants, Dinodex, fossiles,
  revanches, Hélène au Cabinet, Nouvelle partie+), testés dans `tests/apex/histoire/test_epilogue.gd`.
- Les résidents : Hélène au fauteuil (`helene_cabinet`, cinq répliques dont « Quand l'un d'eux ouvre l'œil, viens
  me le dire »), Isaure à sa barque (voyage rapide « Tarif unique : rien »), Maïa au Grand Crâne (le défi n° 6 est
  **branché** : `ApexAutour.maia` lance `ApexBattles.maia_team` / `MAIA_RULES` s'ils existent ; ils n'existent
  pas), Brac au bout de la jetée (trois répliques de gardien de nuit), Dame Suie, Léonce, Joss, Bertille, les
  Anciens, Roc.
- Les quatre blocs des géants (`BlocGeant1..4`, `A.bloc`, quatre textes d'examen, `bloc_geant_vu`, images
  `bloc_geant_1..4.png`), le Souverain couché (`SouverainCouche`), le cratère (`terre_apex` 80 × 70, lieux
  `BLOCS_GEANTS` : (17,30) (27,9.6) (68,20.5) (56.5,47)).
- La commande « Sceaux » (`ApexEngine` : cinq effets, un appel chacun par combat), la règle `hesitates`.
- Les fossiles **ordinaires** : objet `fossile`, `DigSpot` + Flair, six enfouis au Cimetière des Géants pour
  Sirocco (`fossiles_rendus`). Rien pour les « squelettes complets » ni le Titanosaure d'Or.
- Les œufs : `Game.egg` (**un seul œuf porté à la fois**), le réveil d'un fragment par la couveuse (Pépite).
- Trois emplacements de sauvegarde ; `slot_summary` sait si la fin a été vue (`finished` = `fin_vue`).
- Le Relais : une revanche par jour (`revanche_<id>` = `Game.day`), le tiers de la prime.

## Décisions (validées par Greg le 20/10, « pour un mieux »)

1. **Les quatre géants.** Les textes d'examen des blocs sont **déjà dans le jeu** (`DialogueApex.bloc_geant`) et
   **on les garde** : (1) « des griffes comme des faux », (2) « un cou qui fait le tour du bloc deux fois »,
   (3) « des plaques, des pointes, et une queue qu'on ne voudrait pas croiser… Il ronfle », (4) « petit, pour un
   géant, la plume d'Hélène en marque-page ». **Décidé : 1 = Therizinosaurus géant, 2 = Argentinosaurus, 3 =
   Dacentrurus** (grand stégosaure à pointes, 8-9 m : la ligne du jeu lui va mot pour mot), **4 = Deinocheirus**
   (11 m, « petit » à côté des autres, des bras énormes et un bec de canard : il n'a jamais fait peur à
   personne). **Le Giganotosaurus disparaît des docs** (`histoire.md` § Post-game, `bestiaire.md` § Terre des
   Apex : patch du lot A). Anatomies réelles : § Les géants.
2. **Le réveil doux = s'asseoir à côté** (validé). C'est la leçon de la page 40 qui devient une mécanique : quand un bloc
   « ouvre l'œil » (à son heure : aube, crépuscule, pleine lune, nuit), Chloé va le dire à Hélène, qui lui dit
   **avec quel dino s'asseoir** (un pêcheur, un herbivore, des griffes qui ne font pas mal, un chasseur qui ne
   chasse pas) ; au bloc, une action « S'asseoir à côté » (pose assise de Chloé, le dino en tête se couche),
   un temps regardé (l'ambre se fend « comme une noix »), et le géant se lève. **Pas de combat, pas de
   capture** : les géants restent dans le cratère (« chacun chez soi »), Uniques du Dinodex (région `apex`), le
   Lien du dino en tête monte d'un cœur, et le quatrième réveil complète la région `apex` (récompense de Roc,
   mécanisme existant).
3. **Trois squelettes légendaires, cinq os chacun** (validé, 20 larmes) (crâne, colonne, côtes, pattes, queue : `mecaniques.md`),
   quinze os répartis dans **neuf zones existantes** (jamais dans les deux zones de l'Apex seules), déterrés au
   Flair comme les fossiles de Sirocco, plus deux os « trouvés » sans creuser. Les indices : **le carnet des os**
   de Tante Sirocco (une page par squelette, cinq devinettes), et **Isaure** pour la mer. Espèces réelles :
   **le Titanosaure d'Or** (Saltasaurus, le titanosaure à armure : ses plaques dorées), **Kronosaurus** (le
   pliosaure, pour nager), **Gigantoraptor** (le cousin géant d'Oviraptor, à plumes). Ressuscités au Cabinet
   **avec Hélène et la couveuse**, contre vingt larmes d'ambre (le prix de Pépite), un œuf à la fois (limite de
   `Game.egg`), niveau 45 à l'éclosion, capturés (ils rejoignent l'équipe ou la réserve).
4. **Revanches des Alphas : « pour voir », une fois par jour ; récompense = leur Sceau** (décidé : **pas de
   « rejoindre Chloé »**). Chaque Alpha chez lui (niv. 50 à 53), ni capture ni fuite, pas corrompu, pas de musique
   de l'Ombre : la musique des Alphas. La première victoire « réveille » son Sceau, et la commande **« Sceaux »
   devient disponible dans tous les combats** (un appel par Alpha et par jour : « ils ont une région à garder »),
   en réutilisant `ApexEngine` ; deux effets à écrire pour le Tricératops et l'Utahraptor (qui n'en ont pas).
   `histoire.md` § Post-game dit encore « peuvent rejoindre Chloé » : **à remplacer par « leur Sceau »** (patch
   du lot C). **Le Roi des Cieux ne combat pas** (décision du 19/10 ; « il ne se pose jamais pour combattre ») :
   pas de revanche, ou une **course en vol** en option (lot facultatif). **Le Souverain : aucune revanche** (il
   n'a jamais été battu, il ne le sera pas).
5. **Le pari d'Isaure** (validé) : à sa barque, une fois par jour, niv. 50-52, Carène n'hésite plus ; si Chloé
   gagne la première fois, Isaure lui donne **les indices de la mer** (les cinq os du Kronosaurus : « Sirocco
   connaît la terre. La mer, c'est moi. ») ; ensuite des pièces. Si Chloé perd : « tu laves la barque » (une
   bulle, rien d'autre).
6. **Nouvelle partie+** (validé ; **on ne force pas un autre œuf**). Depuis l'écran des emplacements, sur une partie **finie** (`finished`) : bouton
   « Nouvelle partie+ » → on choisit l'emplacement où recommencer. **Gardé** : le Dinodex (vus / possédés / où),
   les os et les espèces ressuscitées (connues, à refaire éclore : les os restent), le mur du journal (les 40 pages
   et les trois des Anciens marquées « déjà lue », à retrouver quand même), la fin vue (l'intro se passe),
   les réglages. **Remis à zéro** : tout le reste (équipe, Liens, objets, drapeaux, horloge, jour, géants,
   revanches, insigne). **Ce qui change** : l'œuf déjà joué est marqué « Celui-là, tu le connais » (choisissable
   quand même : je recommande de ne pas forcer) ; les dresseurs, Brac, Suie, Isaure et les Alphas ont **+2
   niveaux**, les sauvages **+1** ; le dernier geste et la phrase d'Hélène suivent l'œuf (déjà codés). Rien dans
   l'histoire ne « sait » que c'est une seconde partie.
7. **Brac et le sandwich** (validé, avec la réplique de correction). Le sandwich est **toujours le même** depuis les forges : il n'arrive pas à le manger
   parce que, dès qu'il le lève, ses trois bêtes le regardent (« ils regardent mon sandwich, mais ils me
   regardent », ch. 8). Roc a dit au ch. 8 « il a mangé un sandwich » : Brac corrige (« Léonce est loin. J'ai levé
   le sandwich. Ils ont regardé. Je l'ai reposé. »). Le gag se paie en post-game : il le coupe en quatre. Il
   **présente ses bêtes** (Mastoc, Cabosse, Grognon : trois répliques de braconnier repenti, exactes sur les
   espèces). Et **avant** l'épilogue, entre le ch. 8 et l'aube, il a enfin une scène sur la jetée (aujourd'hui il
   n'a aucune réplique).
8. **Logistique** (validé). Six lots parallèles (tableau en bas) ; une seule régénération de zones (lot FOSSILES,
   ids gardés) ; les géants réveillés, le panneau « BARC » et le sandwich sont posés **par le code** (résidents /
   `Stage.show_thing`), pas par les générateurs : aucun autre lot ne touche un `.tscn`. Les images par
   nano-banana (Sonnet). Tests GdUnit4 sans fenêtre pour toute la logique.

---

## 1. Les géants du cratère

### Les quatre espèces (anatomie réelle, à donner telle quelle aux prompts d'images)

| Bloc (lieu) | Espèce (`id`) | Anatomie réelle (compte des membres) | Taille réelle → gabarit vu | « Son heure » | Avec qui s'asseoir |
|---|---|---|---|---|---|
| 4 (56.5, 47) « petit, la plume en marque-page » | **Deinocheirus** (`deinocheirus`) | bipède ; 2 pattes arrière longues à 3 doigts au sol ; 2 bras de 2,4 m à 3 doigts aux griffes émoussées ; bec plat « de canard » sans dents ; cou assez long ; une **bosse** sur le dos (épines des vertèbres) ; queue à éventail de plumes ; duvet. Mangeait des poissons et des plantes | 11 m, 6 t → 4,4 m (×1,3 en scène) | **l'aube** (le premier matin du post-game : tout de suite) | un dino qui **nage** (Nage) : « un pêcheur, comme lui » |
| 2 (27, 9.6) « le cou fait deux fois le tour » | **Argentinosaurus** (`argentinosaurus`) | quadrupède ; 4 pattes en colonnes (5 doigts, griffe au pouce avant) ; cou très long porté en avant et en haut ; toute petite tête, bec aux dents en crayons ; queue très longue qui s'affine en fouet ; pas de plaques | 33-35 m, 70 t → 5,2 m (le plus grand jamais vu dans le jeu, ×1,5 en scène) | **la pleine lune** (l'ambre luit) | un **herbivore** (régime) : « les grands herbivores ont toujours l'air de sourire » |
| 1 (17, 30) « des griffes comme des faux » | **Therizinosaurus géant** (`therizinosaurus_geant`) | bipède ; 2 pattes arrière courtes et fortes à 4 doigts au sol ; 2 bras longs à **3 griffes droites de 50 cm à 1 m** (les plus longues connues) ; petite tête à bec, cou long, gros ventre d'herbivore ; queue courte ; duvet | 10 m, 5 t → 4,4 m (×1,3) ; plus massif que le `therizinosaurus` du Marais | **le crépuscule** | un dino à **Tranche** : « des griffes qui ne servent pas à faire mal » |
| 3 (68, 20.5) « des plaques, des pointes, une queue… il ronfle » | **Dacentrurus** (`dacentrurus`) | quadrupède ; 4 pattes (les avant plus courtes : le dos monte vers l'arrière) ; **double rangée** le long du dos : petites plaques sur le cou, puis pointes de plus en plus longues vers la queue ; **deux paires de longues pointes au bout de la queue** ; toute petite tête basse à bec corné, dents de feuille ; herbivore qui broute bas. Le premier stégosaure jamais décrit (1875) | 8-9 m, 5 t → 3,2 m au garrot, pointes comprises ~4 m (×1,4 en scène) | **la nuit** (« quand il ronfle le plus fort ») | un dino qui **chante** (Résonance) : « on ne réveille pas un ronfleur en criant : on chante » |

Règle de repos : debout (mémoire « dinos debout ») ; le seul couché est le Souverain (il dort les yeux ouverts).
« Son heure » utilise `Game.phase()` et la pleine lune du moteur (`Game.full_moon` ou l'équivalent du Marais).
Le gabarit « vu » suit la compression des échelles (1,5 × (T/1,5)^0,6), Chloé 1,50 m ; ×1,3-1,5 en scène seulement.

### La boucle (par géant, quatre fois)

1. **L'œil s'ouvre** (`terre_apex`, à son heure) : le bloc pulse (`CS.pulse`), image `bloc_geant_<n>_oeil.png` ;
   examiner le bloc : 2 bulles, drapeau `geant_<n>_oeil`. L'objectif « Les géants du cratère » dit lequel.
2. **Hélène** (Cabinet, `helene_cabinet`, dès `geant_<n>_oeil`) : 6 à 8 bulles, elle dit avec qui s'asseoir ;
   drapeau `geant_<n>_conseil`. Sans ce conseil, s'asseoir au bloc donne une pensée (« Elle m'a dit de venir
   lui dire. ») et rien d'autre.
3. **S'asseoir à côté** (le bloc, action dans la bulle d'interaction ; si le dino en tête n'est pas le bon : 1
   bulle, on ressort) : temps regardé ~25 s sans texte, puis 4-5 bulles ; drapeaux `geant_<n>_reveille`,
   `+♥` du dino en tête (`Game.add_bond`), `Game.mark_seen(<id>)` (Unique « rencontré »), XP ; le bloc devient
   `bloc_geant_<n>_vide.png` et le géant un DinoNpc résident du cratère (une ligne d'examen, un cri).
4. **Hélène après** (une réplique par géant, dans son pool) ; après le quatrième : `geants_reveilles`, une courte
   scène (6 bulles), la région `apex` complète dans le Dinodex (Roc).

Ordre libre ; le quatrième bloc (Deinocheirus) ouvre l'œil le premier (aube, tout de suite) et Hélène conseille
de commencer par lui (« c'est celui que j'avais marqué »). Les autres ouvrent l'œil **une fois le précédent
réveillé** (un à un : F-08) et à leur heure.

### Zones, props, sprites, sons, tests

- Zones : rien à régénérer ; `terre_apex` reçoit les géants par le code (`A.resident`-like, `DinoNpc`), un
  enclos naturel par bloc (ils marchent lentement autour de leur bloc : `Wander` court).
- Props (nano-banana, Sonnet) : `bloc_geant_{1..4}_oeil.png` (même dessin, un œil ambré ouvert dedans),
  `bloc_geant_{1..4}_vide.png` (le bloc fendu en deux, vide, des éclats dorés), tailles identiques aux blocs ;
  `fougere_ambre.png` (une fougère dorée sur les veines d'ambre, posée par le code dès `post_game` : Nuage et
  Râteau la cueillent) ; icône `ui/plume_helene.png` (l'objet `plume_helene`, « marque-page » du bloc 4, que
  Hélène laisse à Chloé : objet clé, jamais vendu).
- Sprites espèces (Sonnet) : `dinos/{deinocheirus,argentinosaurus,therizinosaurus_geant,dacentrurus}.png`
  (profil 3×2) + `_face_dos.png` (4×2), cellule du Souverain (475×228) pour les géants, marche lente ; **jamais
  une recoloration** (le `therizinosaurus` du Marais et le `stegosaurus` de la Forêt servent de référence de
  forme, pas de planche : le Dacentrurus a des **pointes** là où le Stegosaurus a des plaques larges, et une tête
  encore plus petite ; vue de face : le museau bas, les deux rangées de pointes qui s'ouvrent en V ; vue de dos : la
  queue et ses quatre pointes, jamais confondue avec la tête).
- Chloé : pose assise existante (`assis`) ; dino en tête couché : `CS.crouch`.
- Sons (Stable Audio local, normalisés à la médiane de leur catégorie) : `geant-baillement.ogg` (grave, long),
  `geant-pas.ogg` (un pas sourd, à jouer en boucle lente ; `rock_heavy.wav` en repli), le craquement existant
  `ambre-craque.ogg`. Cris : `cry_prefix` existants (`sauropode` pour Argentinosaurus, Therizinosaurus géant et
  Dacentrurus : graves ; `raptor` pour Deinocheirus) ; un ronflement pour le bloc 3 avant le réveil
  (`geant-ronfle.ogg`, boucle douce, la nuit seulement).
- Tests GdUnit4 (`tests/apex/geants/`) : `test_especes_geants.gd` (les 4 `.tres` chargent, famille/type/rareté,
  planches présentes, gabarit ≤ 5,2 m ; chaque Unique du Dinodex a `role`, `rumour`, `where`) ;
  `test_reveil_doux.gd` (ordre : le 4 d'abord, puis un à un ; « son heure » par phase ; le bon dino en tête
  (nage / herbivore / Tranche / Résonance) ; conseil obligatoire ; +1 cœur ; `mark_seen` ;
  `geants_reveilles` au quatrième ; région `apex` complète) ; `test_table_post_game.gd` (la table des drapeaux de
  `post-game-scenes.md` confrontée au code, comme `test_table_ch9.gd`).

## 2. Les fossiles légendaires

### Les trois espèces (anatomie réelle)

| Espèce (`id`) | Anatomie (compte des membres) | Taille → gabarit | Type / famille | Où elle vivait (ses os) |
|---|---|---|---|---|
| **Titanosaure d'Or** (`saltasaurus`, nom affiché « Titanosaure d'Or ») | quadrupède ; 4 pattes en colonnes ; cou moyen, petite tête ; dos couvert de **plaques osseuses rondes** (ostéodermes) et de petits boutons d'os : ici couleur d'ambre, « des pièces d'or cousues dans la peau » ; queue longue | 12 m, 7 t → 3,6 m | Pierre / sauropode | la terre sèche : Désert, Plaines, Volcan, Monts, Apex |
| **Kronosaurus** (`kronosaurus`) | marin ; **4 nageoires**, pas de pattes ; tête énorme (2,3 m, un quart du corps), cou très court ; dents coniques ; queue courte ; nage « comme une tortue », à quatre nageoires | 10 m, 11 t → 3,5 m | Eau / marin (nage, Chloé sur son dos sous l'eau, jamais à pied) | la mer et les eaux : Côte, lagon, grottes marines, Marais, Havre |
| **Gigantoraptor** (`gigantoraptor`) | bipède ; 2 pattes longues à 3 doigts au sol ; 2 bras à 3 doigts griffus ; bec sans dents, tête courte à petite crête ; queue courte en éventail de plumes ; plumes aux bras | 8 m, 1,5 t → 3,1 m | Vent / raptor (famille d'Oviraptor : Flair) | les hauteurs et les bois : Forêt, Cieux, Monts, Grotte des Échos |

### Les quinze os et leurs lieux (zones existantes ; `ZoneBuilder.buried_item(root, x, y, "<objet>", <drapeau>)`)

| Squelette | Crâne | Colonne | Côtes | Pattes | Queue |
|---|---|---|---|---|---|
| Titanosaure d'Or (objet `os_titanosaure`, drapeaux `os_titanosaure_1..5`) | **Terre des Apex**, dans la paroi près du bloc 3, pas enfoui : examiné (page 17 : « sans une goutte d'ambre… pour l'instant ») | **Désert**, Cimetière, à côté de la « vertèbre-baignoire » de la page 17 | **Plaines**, les falaises (au pied, à l'est) | **Monts**, le glacier (entre les blocs bleus de la page 29) | **Volcan**, champs de cendres (la cendre garde tout) |
| Kronosaurus (`os_kronosaurus`) | **Récif du Sanctuaire**, au fond (Plongée : le dino creuse-t-il sous l'eau ? non : os posé sur le sable, examiné à la nage) | **Côte**, la plage, la cale des anciens | **Grottes marines**, la cache | **Marais**, les chenaux (un banc de vase) | **Havre-Doré**, sous le ponton, à marée basse (enfoui, sur la grève) |
| Gigantoraptor (`os_gigantoraptor`) | **Grotte des Échos** (le fond) | **Forêt**, la haute futaie | **Cieux**, les Pitons (au pied d'un poteau de pont) | **Monts**, la vallée (près de l'abri de Bertille) | **Forêt**, le ravin de Griffe-Grise |

Deux os se **trouvent** sans creuser (le crâne du Titanosaure dans la paroi, le crâne du Kronosaurus au fond du
récif : sous l'eau, Chloé nage sur son dino ; pas de creusage sous l'eau). Les treize autres : `DigSpot` au
Flair. Chaque os : un objet par squelette (`item_count` 0-5), un drapeau par os. Toast : « Un os du Titanosaure
d'Or ! Il en reste 3. »

### Les indices

- **Le carnet des os** (Tante Sirocco, Désert, dès `post_game` et `fossiles_rendus`) : trois pages (`letter`,
  signées « — S. »), cinq devinettes chacune, lisibles au mur du journal (section « Carnet des os », hors des 40).
  Sirocco donne la terre (Titanosaure, Gigantoraptor) tout de suite ; pour la mer : « Je ne mets pas les pieds
  dans l'eau. Demande à quelqu'un qui y met sa barque. »
- **Isaure** (le pari, question 5) : la page de la mer (Kronosaurus) à la première victoire.
- **Hélène** : une phrase par squelette quand on lui apporte un premier os (« Celui-là, je l'ai cherché vingt ans.
  Tu as trouvé une côte. Ce n'est pas rien, une côte. »).

### La résurrection (Cabinet, Hélène + couveuse)

Conditions : 5/5 os, 20 larmes d'ambre (`Game.tears() >= 20`, consommées), `Game.egg` vide. Scène (8 bulles +
un temps regardé : la couveuse s'illumine, les os « fondent dans l'ambre comme du sucre », un œuf), puis
`Game.egg = {species, name, steps}` (nom proposé : « Doré », « Cronos », « Plume » ; renommable à l'éclosion
comme les autres). Éclosion : mécanique existante ; le nouveau-né arrive à **niveau 45** (une règle `EGG_LEVELS`
par espèce), rareté `legendaire`, Dinodex possédé. Trois fois.

### Props, sprites, sons, tests

- Zones **régénérées** (neuf : plaines, grotte_echos, foret, marais, desert, cote, grottes_marines, monts,
  champs_cendres, plus havre_dore, cieux, recif_sanctuaire, terre_apex = treize avec les os posés par le code
  quand c'est possible ; **à limiter** : les `DigSpot` exigent le générateur, les deux os examinés et ceux de
  `terre_apex` se posent par le code) ; ids gardés (`keep_ids.mjs`), diff = les seuls nœuds ajoutés.
- Props : `os_<squelette>_<piece>.png` n'est pas nécessaire (un `DigSpot` est la même terre remuée) ; deux props
  visibles : `crane_titanosaure_paroi.png`, `crane_kronosaurus_sable.png`.
- UI : icônes `ui/os_titanosaure.png`, `os_kronosaurus.png`, `os_gigantoraptor.png` (un os doré, un os bleu,
  un os à plume), `ui/carnet_os.png` ; une **planche du squelette** par espèce dans la fiche du Dinodex
  (`ui/squelette_<id>.png`, cinq pièces qui s'allument : crâne, colonne, côtes, pattes, queue).
- Sprites (Sonnet) : `dinos/{saltasaurus,kronosaurus,gigantoraptor}.png` + `_face_dos.png` ; Kronosaurus en
  **cycle de nage** (jamais de marche), Chloé en nage dessus (planche `_nage` comme les marins existants).
- Sons : `creuser.mp3` existe ; `os-trouve.ogg` (un « toc » sec et un petit carillon), la couveuse : `glass.wav`.
- Tests (`tests/apex/fossiles/`) : `test_os.gd` (15 drapeaux uniques, 3 objets, 5 par squelette, jamais vendus,
  deux examinés, aucun `DigSpot` sous l'eau) ; `test_resurrection.gd` (refus à 4/5, refus sans 20 larmes, refus
  si `Game.egg` non vide ; larmes consommées ; `egg` posé ; niveau 45 à l'éclosion ; rareté) ;
  `test_especes_fossiles.gd` (3 `.tres`, Kronosaurus nage et ne marche pas, Gigantoraptor a Flair) ;
  `test_carnet_os.gd` (3 pages, 5 lignes chacune, Isaure donne la mer après une victoire).

## 3. Les revanches

| Qui | Où (chez lui) | Équipe / niveau | Règles | Une fois par | Récompense (1re fois) | Ensuite |
|---|---|---|---|---|---|---|
| Maïa, défi n° 6 (déjà branché) | Grand Crâne | son œuf 50, Pouce (Iguanodon) 50, Moustique (Dimorphodon) 49, Caillou (Tricératops) 51 | `trainer`, `lose_spawn` le Crâne, musique `rivale.ogg` | jour (`maia_defi_6_jour`) | `maia_defi_6`, XP, la ligne à la craie du Relais (« pour l'instant ») ; pas de pièces : ce n'est pas le Relais | XP |
| Tricératops | Grand Crâne (l'antre) | 50 | « alpha » : ni capture ni fuite, pas corrompu, `alpha.ogg`, `lose_spawn` l'entrée | jour | Sceau de la Prairie éveillé : effet **Charge de l'Alpha** (le prochain coup ×2) | 60 pièces |
| Utahraptor | Forêt, la clairière | 50 | idem | jour | Sceau de la Forêt : **La meute** (le dino de Chloé agit deux fois ce tour) | 60 |
| Spinosaure | Temple englouti | 51 | idem, moteur sous l'eau | jour | Sceau du Marais : l'eau du bassin (existant) | 70 |
| Carnotaurus | Sanctuaire des Vents | 51 | idem | jour | Sceau du Désert : le vrai rugissement | 70 |
| Mosasaure | Récif (sous l'eau) | 52 | idem, moteur sous l'eau | jour | Sceau de la Côte : il écoute les cœurs | 80 |
| Cryolophosaure | Sanctuaire de Givre | 52 | idem, neige | jour | Sceau des Monts : le souffle de givre | 80 |
| T-Rex de Magma | Sanctuaire de Magma | 53 | idem, fond volcan | jour | Sceau du Volcan : il se couche à côté | 90 |
| Isaure, le pari | Port-Ambre, sa barque | Hauban 50, Bouline 50, Étrave 51, Carène 52 (n'hésite plus) | `trainer`, pas de musique (le vent), `lose_spawn` le quai | jour | la page de la mer (Kronosaurus) | 100 pièces |
| Le Roi des Cieux | — | — | **ne combat pas** | — | (option : la course du cratère, en vol, lot facultatif) | — |
| Le Souverain | — | — | **jamais** | — | — | — |

- **Sceaux partout** (règle `sceaux_libres` dans `BattleEngine` → `ApexEngine` : la commande « Sceaux » si Chloé
  a `insigne_gardienne` et au moins un Sceau éveillé ; un appel par Alpha et **par jour** (`sceau_<x>_jour` =
  `Game.day`), jamais contre cet Alpha lui-même, jamais en combat de dresseur du Relais ? (si : Gaspard et Lilou
  seraient écrasés : **non** au Relais, oui partout ailleurs).
- Équilibrage : équipe de fin 48-50 ; chaque Alpha seul contre une équipe de six est un combat de 6-10 tours,
  70-85 % de victoire sans Sceaux, pas un mur ; **à simuler** (120 combats par cas, comme `EQUILIBRAGE`).
  Les Alphas ne sont ni corrompus ni « blessés » : le texte de fin est « Il s'arrête. Il a vu. », pas « K.O. ».
- Rien ne change dans le jeu principal : tout est conditionné à `post_game` (ou `insigne_gardienne`).
- Tests (`tests/apex/revanches/`) : `test_revanches.gd` (chaque Alpha une fois par jour ; niveaux ; ni capture ni
  fuite ; `lose_spawn` ; récompenses une fois ; Roi et Souverain absents de la table) ; `test_sceaux_libres.gd`
  (commande absente sans insigne, absente au Relais, absente contre l'Alpha lui-même, un appel par jour, les deux
  nouveaux effets) ; `test_maia_6.gd` (équipe et niveaux, `MAIA_RULES`, une fois par jour) ;
  `test_equilibrage_revanches.gd` (simulation, résultats cités tels quels).

## 4. Nouvelle partie+

| Gardé (copié dans la nouvelle partie) | Remis à zéro | Changé |
|---|---|---|
| `dex_seen`, `dex_caught`, `dex_where` ; `os_*` (objets et drapeaux) et `fossile` ; les espèces ressuscitées (connues : leurs os sont là, l'œuf est à refaire) ; `journal_lu` (= les `found_journal_n` et pages des Anciens de l'ancienne partie, marqués au mur « déjà lue » en gris, à retrouver) ; `fin_vue`, `intro_vue` ; `ng_plus_count` (+1) ; réglages | équipe, réserve, Liens, objets (sauf os), `flags` (sauf la liste ci-contre), `egg`, horloge, jour, météo, position, `explored`, `searched` ; les géants, les revanches, l'insigne | le prologue : l'œuf déjà joué porte « Celui-là, tu le connais. » (gris, choisissable) ; `Story.duel` : +2 niveaux à tout dresseur/Alpha ; `Encounter` : +1 aux sauvages ; les Anciens des autres œufs ont leurs pages (déjà prévu) ; la fin : l'autre dernier geste, l'autre phrase d'Hélène (déjà codés) |

- Entrée : `ui/save_slots.gd`, sur un emplacement `finished` : « Nouvelle partie+ » (clavier, manette, souris) →
  choix de l'emplacement de destination (écraser : confirmation existante) → `Game.new_game_plus(from_slot)`.
- `core/game_state.gd` : `new_game_plus(keep: Dictionary)` = `new_game()` puis réinjection ; `NG_PLUS_KEEP` liste
  les clés ; `ng_plus` (int) sauvegardé ; `level_bonus(kind)` lu par `Story.duel` / `Encounter`.
- Le mur du journal : les pages « déjà lues » en gris avec une petite coche ; relisibles seulement une fois
  retrouvées (sinon on spoile la partie).
- Aucune réplique nouvelle dans l'histoire (personne ne sait) ; une seule nouveauté de texte : le bouton, la
  confirmation, et la fiche du Dinodex qui garde « Possédé à la partie précédente ».
- Tests (`tests/sauvegarde/test_nouvelle_partie_plus.gd`) : ce qui est gardé l'est (Dinodex, os, journal lu,
  fin vue), ce qui est remis à zéro l'est (équipe vide avant le prologue, objets de départ, jour 1, aucun
  `found_journal_n`), `ng_plus` = 1 puis 2 ; +2 / +1 niveaux ; l'emplacement source intact ; refus si la partie
  n'est pas finie ; les pages grises ne sont pas « trouvées ».

## 5. Brac sur la jetée

- **Avant l'épilogue** (dès `brac_parti`, jusqu'à `epilogue_cabinet`) : la scène « Le phare qui boude » (9
  bulles, une fois, `brac_jetee_vu`) ; ensuite une réplique par visite (pool `BRAC_JETEE_AVANT`, trois lignes).
  Le sandwich : prop `sandwich.png` posé par le code à côté de lui ; il le lève à « Léonce est loin », les trois
  bêtes se tournent vers lui (`Stage.turn_to`), il le repose.
- **Après l'épilogue, de jour** : les trois répliques existantes restent ; s'y ajoutent, une fois, « Le partage »
  (6 bulles, `brac_sandwich_partage`) ; et une ligne d'examen par bête (Mastoc, Cabosse, Grognon : `DinoNpc`
  déjà là, événement par nœud).
- **De nuit** : planche `brac_gardien.png` (lanterne à la main, chapeau, pas de masque), le panneau « Gardien :
  BARC » (prop `panneau_barc.png`, posé par le code dès `epilogue_fini`, une ligne d'examen), Mastoc couché près
  de la lanterne (« il a peur du noir »).
- Rien à régénérer dans `port_ambre` (Brac, Mastoc, Cabosse, Grognon existent depuis le ch. 8).
- Sons : rien de neuf (le rire de Brac est une secousse d'écran ; le sandwich, une bulle).
- Tests (`tests/apex/histoire/test_brac_jetee.gd`) : avant l'épilogue la scène joue une fois puis le pool ; après,
  le partage une fois ; les trois lignes de bêtes ; de nuit la planche de gardien et le panneau ; `volcan_autour`
  ne dit plus rien à sa place (le test `test_scenes_aube` qui vérifie « avant l'épilogue, Brac est au ch. 8 » doit
  être **mis à jour**, pas contourné).

## Les lots, les modèles, les dépendances

| Lot | Modèle | Possède (jamais deux lots sur un même fichier) | Signale seulement (`scratchpad/postgame/patch_<lot>.md`) | Dépend de |
|---|---|---|---|---|
| **A. GÉANTS-CODE** | Opus | `story/apex_geants.gd`, `data/dialogue_geants.gd`, `data/species/{deinocheirus,argentinosaurus,therizinosaurus_geant,dacentrurus}.tres`, `data/dex_facts.gd` (+4 Uniques : patch si un autre lot y touche : **B** aussi → B signale, A possède), `tests/apex/geants/*` | `story/apex.gd` (dispatch `bloc_geant_n` → `ApexGeants`), `story/apex_autour.gd` (Hélène : conseil), `story/apex_objectives.gd` (l'objectif dit lequel), `data/dialogue_apex.gd` (le pool d'Hélène ; les quatre lignes des blocs **restent**), `world/prop.gd` (+9 genres), `docs/histoire.md` § Post-game et `docs/bestiaire.md` § Terre des Apex (Dacentrurus à la place de Giganotosaurus) | images de **A'** (stand-in : `STAND_INS` du Souverain en attendant) |
| **A'. GÉANTS-IMAGES** | Sonnet | `tools/art-jobs/geants.mjs`, `assets/art/dinos/<4 espèces>*.png`, `assets/art/props/bloc_geant_*_{oeil,vide}.png`, sons `geant-*.ogg`, `docs/direction-artistique.md` § Post-game | — | — |
| **B. FOSSILES** | Opus | `story/fossiles.gd` (os, carnet, résurrection), `data/dialogue_fossiles.gd`, `data/species/{saltasaurus,kronosaurus,gigantoraptor}.tres`, `tools/zones/*` (les `buried_item` ajoutés) + **régénération** des zones listées (ids gardés, diff vérifié), `ui/dex_entry.gd` (la planche du squelette), `tests/apex/fossiles/*` | `data/items_db.gd` (+4 objets), `data/dex_facts.gd` (+3 fiches), `story/desert.gd` (Sirocco : le carnet), `story/apex_autour.gd` (Hélène : résurrection, Isaure : la page de la mer après le pari → avec **C**), `ui/journal` (section « Carnet des os ») | images de **B'** ; **C** pour le pari d'Isaure (interface : drapeau `isaure_pari_gagne`) |
| **B'. FOSSILES-IMAGES** | Sonnet | `tools/art-jobs/fossiles.mjs`, `assets/art/dinos/<3 espèces>*.png` (+ `kronosaurus` en nage, Chloé dessus), `assets/art/props/crane_*.png`, `assets/art/ui/{os_*,carnet_os,squelette_*}.png`, `os-trouve.ogg` | — | — |
| **C. REVANCHES** | Opus | `battle/revanche_battles.gd` (tables, niveaux, règles, `maia_team`/`MAIA_RULES` **dans `ApexBattles`** : C possède `battle/apex_battles.gd` pour ça), `battle/apex_engine.gd` (`sceaux_libres`, deux effets), `story/revanches.gd` (les Alphas chez eux, le pari d'Isaure), `data/dialogue_revanches.gd`, `tests/apex/revanches/*` | `battle/battle_engine.gd` (le branchement de `sceaux_libres`), les `story/*` des Alphas (un `if post_game` → `Revanches.alpha(id, who)` dans chaque événement d'Alpha : 7 patchs d'une ligne), `story/apex_autour.gd` (Isaure), `docs/histoire.md` § Post-game (« Revanches : … les Alphas, dont le Sceau s'éveille : la commande Sceaux dans tous les combats » à la place de « peuvent rejoindre Chloé ») | — |
| **D. NOUVELLE PARTIE+** | Opus | `core/game_state.gd` (`new_game_plus`, `NG_PLUS_KEEP`, `level_bonus`), `core/save_system.gd` (`start_new_game_plus`), `ui/save_slots.gd` (le bouton), `ui/journal*` (pages grises), `story/prologue*` (l'œuf « tu le connais »), `tests/sauvegarde/test_nouvelle_partie_plus.gd` | `story/story.gd` (`duel` : +2), `data/encounter.gd` (+1), `ui/dex_entry.gd` (« partie précédente ») | **B** pour la liste des clés `os_*` (interface : préfixe `os_` et objets `os_*` : décidé ici, pas besoin d'attendre) |
| **E. BRAC** | Opus (+ 2 images Sonnet, dans **A'**) | `story/brac_jetee.gd`, `data/dialogue_brac.gd`, `tests/apex/histoire/test_brac_jetee.gd` | `story/volcan.gd` (`brac_jetee` → `BracJetee`), `story/apex_autour.gd` (`brac` → `BracJetee`), `story/epilogue.gd` (`port_residents` : le panneau, la planche de nuit), `tests/apex/histoire/test_scenes_aube.gd` (la ligne « Brac est au ch. 8 ») | `brac_gardien.png`, `panneau_barc.png`, `sandwich.png` (A') |

Parallèles : A, A', B, B', C, D, E tous en même temps ; **seul B régénère des zones** (import sous verrou, un
par un) ; A, C, E posent tout par le code. Intégration par le chef d'équipe : patchs, un import, tests, parcours
(`tools/scenarios/postgame_*.gd` : un géant, un os, une revanche, Brac), commit par lot.

Règles communes (celles des ch. 8-9) : français partout ; pas de commit ; tests ciblés avec bandeau
`ShotCaption` ; Godot partagé ; nano-banana, sinon s'arrêter et le dire (repli ComfyUI noté dans la DA) ;
règle des mouvements pour tout nouveau mobile ; tout écran jouable clavier/manette/souris ; fichiers < 800
lignes ; **scènes courtes** (8-12 bulles) ; le dino **en tête** nommé (`lead.nickname`), le dino de départ
seulement quand la scène parle de lui ; « crique », jamais « anse » ; sous l'eau, Chloé nage sur son dino ;
anatomies réelles dans chaque prompt d'image, compte des membres vérifié image par image.

## Estimation (quota, à titre indicatif ; modèle du ch. 7 : « 4 agents, plusieurs heures »)

| Lot | Temps agent | Risque |
|---|---|---|
| A | 2-3 h | faible : tout par le code, modèle `ApexAutour` |
| A' | 2 h (4 espèces × 2 planches, 8 props, 2 sons, + 3 images de E) | moyen : géants à la bonne échelle, pattes comptées |
| B | 4-5 h | **le plus lourd** : 13 zones touchées, diff des `.tscn`, Dinodex (planche du squelette), couveuse |
| B' | 1,5 h | moyen : Kronosaurus en nage avec Chloé |
| C | 2-3 h (dont 1 h de simulation) | moyen : `sceaux_libres` dans le moteur commun ; 7 patchs d'une ligne |
| D | 2 h | moyen : l'écran des emplacements et le mur du journal ; `new_game_plus` à tester à fond |
| E | 1 h | faible |
| Intégration | 2-3 h | — |

Total : 17-22 h d'agents, 4 à 6 lots en parallèle selon le quota de Greg. Ordre conseillé si on fractionne :
**E + A/A'** (le plus visible, le moins risqué), puis **C**, puis **B/B'**, puis **D** (D dépend de B pour
avoir des os à garder, mais son code n'en dépend pas).

## Incohérences et trous relevés en lisant (tranchés le 20/10 ; rien n'est modifié hors de ces deux docs)

1. **Le bloc 3** : « plaques, pointes, queue » (texte dans le jeu) contre « Giganotosaurus » (`histoire.md`,
   `bestiaire.md`). **Tranché : Dacentrurus**, on garde la ligne du jeu ; les deux docs sont à corriger (patch du
   lot A).
2. **Le sandwich** : Roc (ch. 8, `volcan_autour.gd`) : « il a mangé un sandwich » ; `chapitre-9-scenes.md`
   § Autour : « le même sandwich » (donc jamais mangé). **Tranché** : la réplique de correction de Brac (B1 :
   « Roc tient ça de Léonce. Léonce est loin. ») ; rien à changer au ch. 8.
3. **Brac avant l'épilogue** n'a **aucune réplique** (`VolcanAutour.brac_jetee` : « … » et il regarde la mer) alors
   que `progress.md` le note comme un reste ; `test_scenes_aube.gd` fige ce silence (« avant l'épilogue, Brac est
   au ch. 8 ») : **le test change avec la scène B1** (lot E).
4. **« Les géants se réveillent un à un »** (fin, Hélène « à leur heure », F-08 « je les réveillerai ») : les trois
   formulations se concilient par la boucle « l'œil s'ouvre à son heure → Hélène → Chloé s'assoit » ; `histoire.md`
   § Post-game dit déjà « on s'assoit à côté, avec Hélène qui dit comment, et un Lien qui monte » : conforme.
5. **`histoire.md` § Post-game** : « les Alphas peuvent rejoindre Chloé » contre la décision du 19/10 (le Roi ne
   combat pas) et l'esprit de la Réserve (« chacun chez soi »). **Tranché : leur Sceau s'éveille, pas de « rejoindre
   Chloé »** ; `histoire.md` à mettre à jour (patch du lot C, phrase donnée dans le tableau des lots).
6. **Un seul œuf à la fois** (`Game.egg`) : trois résurrections = trois allers-retours au Cabinet ; Hélène le dit
   (« Un à la fois. Tu n'as que deux mains, et il en faut une pour le sac. »).
7. **Le Dinodex dit « #001 à #039 »** dans `mecaniques.md` : périmé (plus de 55 espèces) ; les trois légendaires et
   les quatre géants entrent dans la numérotation de l'île (fin de liste) et les géants dans ★ Uniques.
8. **La page 17** (« ceux-là dorment pour de bon… pour l'instant ») n'avait pas de suite : les os du Titanosaure
   d'Or au Cimetière la paient.
9. **Les « œufs rares de l'Ambre-Mère »** d'Hélène (F-06, sa réplique au Cabinet) ne sont **pas** les fossiles :
   ce sont les fragments d'ambre (mécanique de Pépite). Rien à faire ici, mais ne pas les confondre dans les
   textes : la résurrection parle d'os, jamais d'« œufs rares ».
10. **`maia_defi_6_jour`** compare `Game.flag(...) == Game.day` : si le drapeau n'existe pas, `int(false)` = 0 et
    `Game.day` ≥ 1 : correct. Même patron pour toutes les revanches.
