# Chapitre 9 — La Terre des Apex, et l'épilogue : les scènes (texte complet)

> Écrit le 19/10/2026 par l'agent HISTOIRE (Fable), d'après `chapitre-9-plan.md` (six questions pour Greg en
> tête), `chapitre-8-scenes.md` § scène 9 (la porte : le chapitre 9 en est la suite directe), `histoire.md`,
> `lore.md`, `mecaniques.md`, `battle_engine.gd` (règles `long_calm`, `starter`, `antidote`). Même format que
> le ch. 8 : didascalies *en italique* (à traduire en `cue` / `Stage.*` comme dans `story/cieux_arche.gd`),
> dialogues par lieu et par état, pensées de Chloé entre parenthèses, les pages 39 et 40, et pour chaque scène
> ses drapeaux, objets, événements, personnages, images et choix. **Rien n'est codé.**
>
> Ton : chaleureux et drôle, jamais effrayant ni cruel. Le 7 était le plus grave, le 8 le plus chaud ; le 9 est
> **le plus grand** : il commence à l'aube devant une porte de bois, finit sur une jetée avec un masque en carton,
> et au milieu une bête trop grande pour l'écran qui a peur. Personne ne meurt, personne ne pleure ; Hélène est
> drôle dans la minute où elle se réveille ; Roc fait du thé.

## Conventions

- Lieux : `porte_cratere` (ch. 8, l'aube), **`terre_apex`** et **`coeur_apex`** (nouvelles), le Cabinet et
  `port_ambre` (l'épilogue). Ordre : l'aube → le duel → la porte → le cratère (page 39) → le fond (le bloc, la
  goutte, le combat, Hélène) → fondu → le Cabinet (trois jours plus tard) → la jetée (le lendemain) → fin.
- Personnages : Chloé, le dino de départ (`Game.starter_dino()` : Vif / Bastion / Écho, **exigé dans l'équipe**),
  Moustique (sur l'épaule), Isaure, Maïa, Caillou, les quatre dinos d'Isaure, le Souverain, Hélène, les cinq
  Alphas gardiens de Cœurs (en combat), le Roi des Cieux ; à l'épilogue : Roc, Léonce, Gustave, Firmin, Rosalie, Mémé Pervenche,
  Joss, M. Hamon, Dame Suie, Brac (et Mastoc, Cabosse, Grognon).
- **Scènes courtes (Greg, 18/10)** : jamais plus d'environ **8 à 12 bulles d'affilée** sans que le joueur fasse
  quelque chose. Chaque scène est découpée en **moments**, séparés par un **temps regardé** (*sans texte*), un
  **CHOIX** (`Dialogue.choose`), un **déplacement** ou un **combat**. Le nombre de bulles est noté à côté de
  chaque bloc. Les choix ne changent ni les faits ni les drapeaux : ils décident qui dit la phrase, ou le ton ;
  **un seul** choix est un vrai dilemme (ouvrir / laisser fermée), et ses deux chemins convergent en trois bulles.
- Garde-fous : le Souverain **a peur** (il tremble, crie, recule, frappe en reculant) ; il ne souffre jamais, il
  n'est jamais « battu » ; Isaure ne ment pas, ne pleure pas, n'est pas humiliée (elle perd un pari et le tient)
  ; Maïa ne pleure pas (elle rit à la fin) ; Hélène ne fait pas de discours (elle le dit : « Anselme en a
  préparé un ; il le gardera ») ; Chloé ne fait pas de discours non plus ; aucun masque d'os n'est remis par
  personne : le seul masque qu'on met, c'est celui en carton, pour rire.
- Ce que Chloé a en arrivant : `coeur_5`, `sceau_volcan` (+ `sceau_foret`, `sceau_marais`, `sceau_desert`,
  `sceau_cote`, `sceau_monts`, `sceau_cieux`, et le drapeau `sceau_plaines`), `antidote_ambre` (une dose),
  `masque_carton` (si `masque_carton_confie`), Moustique dans l'équipe ou la réserve (`moustique_confie`),
  peut-être `lettre_isaure` (si elle a choisi « Pas maintenant » à la porte), peut-être `moufles_helene`,
  peut-être Fournaise (`fournaise_garde`), peut-être le troisième petit (`oeuf_vole_apaise`, dans l'équipe ou au
  Cabinet). Les drapeaux `coeur_1` à `coeur_4` sont vrais ; les objets sont chez Isaure.

## Carte des drapeaux, objets, événements (vue d'ensemble)

| Scène | Drapeaux posés | Objets | Événements / nœuds |
|---|---|---|---|
| L'aube | `apex_aube`, (`lettre_isaure_donnee` si donnée ici), `isaure_pari`, `isaure_aveu_oeuf` | — | Npc `IsaurePorte` (événement `isaure_porte`, déjà en place : un patch de `volcan_porte.gd`), `MaiaPorte`, DinoNpc `CaillouPorte` ; DinoNpc `Hauban`, `Bouline`, `Etrave`, `Carene` (apparaissent au sifflet) |
| Le duel | `isaure_vaincue` | — | `Story.duel("Isaure", …)` ; `lose_spawn` : le camp d'Hélène |
| Décide | `apex_decision` (= le choix fait), `coeurs_rendus`, `apex_ouvert` | `coeur_1` à `coeur_4` reviennent, puis `coeur_1` à `coeur_5` quittent le sac (dans la porte) | StoryProp `PortailApex` (ouvert : nouvelle image ; sortie de zone vers `terre_apex`, `show_flag apex_ouvert`) |
| Le cratère | `apex_arrivee`, `found_journal_39` (= `page_39`), `bloc_geant_vu` | — | scène d'entrée `terre_apex`, Pickup `page_39` (cairn), StoryProp `BlocGeant1..4`, DinoNpc `RoiApex` (perché, haut) |
| Le bloc | `coeur_apex_arrivee`, `helene_vue`, `essai_griffes`, `essai_charge`, `essai_chant`, `essais_finis` | — | scène d'entrée `coeur_apex`, StoryProp `BlocSouverain` (entier / fendu / ouvert) |
| La goutte | `goutte_noire`, `souverain_eveille`, `helene_sortie`, `caillou_rempart`, `starter_lien_5` | — | DinoNpc `Souverain` (corrompu), Npc `HeleneAmbre` → prop `IsaureHelene` |
| Le combat | `souverain_apaise` | `antidote_ambre` consommé | `Story.duel` règles `{"corrupted", "long_calm", "calm_factor": 3, "starter", "sceaux", "caillou", "antidote", "antidote_min_calm": 0.66, "music": ALPHA}` |
| Hélène | `helene_liberee`, `helene_reveillee`, `moustique_rendu`, `masque_carton_rendu`, `masque_carton_pris`, `apex_fini` | `masque_carton` quitte le sac ; Moustique quitte l'équipe / la réserve | Npc `Helene`, `Souverain` (apaisé, couché), `RoiApex` descend |
| Le Cabinet | `epilogue_cabinet`, `moufles_rendues`, `isaure_cabinet`, `tasse_bleue`, `lettre_lue`, `reserve_dite` | `moufles_helene` quitte le sac ; `lettre_isaure` quitte le sac si encore là | Npc `HeleneAssise`, `Roc`, `IsaureCabinet`, StoryProp `TasseBleue`, `CaisseCarnets` |
| La jetée | `epilogue_port`, `reserve_annoncee`, `brac_gardien`, `gardiennes_nommees`, `masque_carton_porte`, `found_journal_40` (= `page_40`), `epilogue_fini`, `post_game` | `insigne_gardienne` | scène d'entrée `port_ambre` (dès `epilogue_cabinet`, de jour) ; Npc `HeleneJetee`, `IsaureJetee`, `MaiaJetee`, `BracJetee`, `SuieJetee`, `HamonJetee`, `JossJetee`, les pêcheurs |
| Autour | `roc_epilogue_n`, `bertille_helene_remontee`, `joss_poche_piaf`, `suie_port_n`, `brac_jetee_n`, `helene_cabinet_n`, `isaure_barque_n`, `maia_gardienne_n`, `anciens_helene_n` | — | Roc, Bertille, Joss, Dame Suie, Brac, Hélène, Isaure (à sa barque), Maïa (au Crâne), les Anciens |

Objets (`data/items_db.gd`) : `insigne_gardienne` « Insigne de gardienne » (un disque d'ambre nu, la fougère
d'Hélène ; « Les Alphas te reconnaîtront. Ils te reconnaissent déjà. ») ; `coeur_1` à `coeur_5` : « posés dans
la porte de la Terre des Apex » (les drapeaux `coeur_n` restent) ; `antidote_ambre` : consommé ; `masque_carton`
: rendu à Maïa ; `moufles_helene` : rendues à Hélène ; `lettre_isaure` : si encore là, donnée au Cabinet.

---

## Scène 1 — L'aube (`porte_cratere`)

### 1 a — « C'est l'aube ? » (Npc `IsaurePorte`, événement `isaure_porte`, dès `marche_refuse` et `apex_bloque`)

*Quand Chloé reparle à Isaure (après les répliques `isaure_porte_n` du ch. 8, ou à leur place une fois qu'elles
sont épuisées), Isaure se retourne à moitié.*

> **Isaure** — Ton équipe est au complet, moussaillon ? Le jour ne va pas tarder.

*Si le dino de départ n'est pas dans l'équipe (il attend au Cabinet) :*

> **Isaure** — Et le petit d'Hélène ? Celui qui a éclos dans ta main. Va le chercher. Ce n'est pas moi qui te le
> demande : c'est elle.
> **Chloé** — (Elle a raison. Pas lui, pas sans lui.)

*(2 bulles, retour au jeu ; objectif : « Le dino de départ dans l'équipe, puis l'aube ».)*

*Sinon, **CHOIX** — « Isaure attend. » : « C'est l'aube. » / « Pas encore. »*

- « Pas encore. » → **Isaure** — Soigne-les, alors. Je ne bouge pas. (1 bulle ; retour au jeu.)
- « C'est l'aube. » → *Sans texte : le ciel pâlit derrière le volcan, les torches perdent leur couleur, la fumée
  du cratère devient rose. Maïa se lève de sa pierre. Caillou aussi, en éternuant.* Drapeau `apex_aube`.

*Si Chloé a encore `lettre_isaure` : le **CHOIX** de la lettre du ch. 8 (9 d) se rejoue ici d'abord (« Lui donner
la lettre » / « Pas maintenant »), avec les mêmes six bulles. Si elle refuse encore, la lettre sera donnée au
Cabinet (scène 4 c).*

### 1 b — La dernière demande (6 bulles)

> L'aube monte. Isaure a sorti les quatre Cœurs de sa sacoche : elle les tient à deux mains, contre elle. Ils
> battent. Dans la sacoche de Chloé, le cinquième répond, plus fort que tous.
> **Isaure** — Je ne redemande qu'une fois. Donne-le-moi, et viens.
> **Chloé** — Non.
> **Isaure** — … Je savais. Je demandais quand même. On demande toujours une fois de trop, dans ma famille.
> **Maïa** — *(de sa pierre)* C'est vrai. Je l'ai demandée trois fois, la barque.
> **Isaure** — Alors je ne vais pas te le prendre, moussaillon. Je vais le gagner. Un pari de marin : si je gagne,
> le Cœur. Si tu gagnes, c'est toi qui décides ce qu'on fait de cette porte. Et je ferai ce que tu décides.

*Sans texte : Isaure range les Cœurs. Elle met deux doigts dans sa bouche et siffle, un sifflet de marin, long.
Derrière les rochers de l'esplanade, quelque chose bouge. Quatre choses.*

Drapeau : `isaure_pari`.

### 1 c — Les miens (8 bulles)

> Quatre dinos sortent de derrière les rochers, où ils dormaient. Un Pteranodon au bec rayé de sel, un Baryonyx,
> un Suchomimus, et une tortue plus grande qu'une barque. Pas une veine violette. Pas une.
> **Isaure** — Hauban. Bouline. Étrave. Et Carène, qui a l'âge de ma barque. Ils suivent mon bateau depuis que
> Maïa est née. Je ne les ai jamais forcés. Je n'ai jamais eu besoin.
> **Chloé** — (Elle l'a. Le Lien. Elle l'a toujours eu. Elle s'est juste servie d'autre chose.)
> **Isaure** — J'en avais un cinquième. Je l'ai pris sur une couveuse, une nuit, avec ma clé, et je l'ai donné à
> Brac. *(selon `oeuf_vole_apaise` et où est le petit)* C'est lui, là, dans ton équipe. Il ne me reconnaît pas.
> Tant mieux. / C'est le petit que tu as ramené au Cabinet. Il ne me reconnaîtrait pas. Tant mieux.
> **Maïa** — … Tu ne me l'avais pas dit.
> **Isaure** — Non. Je te le dis maintenant. Avant, pas après : ta marraine disait qu'on avoue avant.
> **Chloé** — (Avant. Pour qu'il n'y ait plus rien derrière la porte, qu'elle gagne ou qu'elle perde.)
> **Maïa** — *(elle vient se mettre à côté de sa mère, les mains dans les poches du manteau)* Je suis de son côté.
> Je ne me bats pas. Je regarde. … C'est le plus dur, je crois.

Drapeau : `isaure_aveu_oeuf`. Le troisième petit, s'il est en tête, gronde doucement et recule d'un pas (*sans
texte*). → **Combat.**

### 1 d — Le duel (`Story.duel("Isaure", …)`)

Règles : `trainer` « Isaure », `lose_spawn` le camp d'Hélène, musique : **aucune** (le vent, les torches ; le
thème de l'Ombre n'est plus le sien). Ses dinos ne sont pas corrompus : ni Apaiser ni Collier ; on les bat.

| Dino | Espèce, niv., type | `intro` | `before` (Isaure, une bulle) |
|---|---|---|---|
| Hauban | Pteranodon 47, vent | « Isaure envoie Hauban ! Il a du sel sur le bec. » | « Hauban. Il a pêché pour le port les hivers où personne ne pêchait. » |
| Bouline | Baryonyx 47, eau | « Isaure envoie Bouline ! Elle regarde la sacoche de Chloé : ça flotte ? » | « Bouline. Elle fait couler tout ce qui flotte, et le regarde remonter. Elle ne s'en lasse pas. » |
| Étrave | Suchomimus 48, eau | « Isaure envoie Étrave ! Il est déjà en train de courir. » | « Étrave. Il n'a jamais perdu une course. Il n'a jamais compris non plus pourquoi on courait. » |
| Carène | Archelon 49, eau (ou pierre : à l'agent MÉCANIQUES), très résistante, lente | « Isaure envoie Carène. Elle prend son temps. » | voir le **CHOIX** |

**CHOIX** avant Carène — « Carène avance. Isaure la regarde, puis Chloé. Que dit Chloé ? » :
« Maïa regarde. » / « Ils n'ont pas peur de vous. » / Ne rien dire.

> *(« Maïa regarde. »)* **Isaure** — Je sais. C'est bien pour ça que je me bats proprement. … Carène.
> *(« Ils n'ont pas peur de vous. »)* **Isaure** — Non. Ils n'ont jamais eu peur. C'est moi qui… Carène. Vas-y.
> *(rien)* **Isaure** — Tu ne dis rien. Elle non plus ne disait rien, dans ces moments-là. C'est reposant et c'est
> terrible. Carène.
> Carène regarde Isaure, puis Chloé. Et elle prend son temps.

*Effet (à l'agent MÉCANIQUES) : Carène **hésite** : elle perd son premier tour, ou son premier coup est deux fois
plus doux. Aucune des trois phrases n'est « la mauvaise ».*

**Perdu** : > **Isaure** — Soigne-les, moussaillon. Je ne bouge pas. L'aube peut attendre encore un peu : elle a
attendu un an. (On reprend au camp d'Hélène ; l'aube reste.)

**Gagné** : drapeau `isaure_vaincue`.

### 1 e — Les Kerval tiennent parole (regardé, puis 6 bulles, un CHOIX, 3 bulles, regardé, 3 bulles)

*Sans texte : Carène se couche. Les quatre dinos retournent derrière les rochers, sans se presser. Isaure ne
bouge pas. Puis elle ouvre sa sacoche de marin.*

> **Isaure** — J'ai perdu. *(Elle tend les quatre Cœurs, à deux mains.)* Tiens. Ils ont assez voyagé dans un sac
> de marin.
> Les quatre Cœurs passent dans la sacoche de Chloé. Le cinquième les accueille : cinq battements, puis un seul.
> **Isaure** — Décide, moussaillon. Je ferai ce que tu décides. Les Kerval tiennent parole.
> **Maïa** — Même les paris idiots. … Pardon. Surtout maintenant.
> **Chloé** — (Fermer. Et laisser Hélène là-dedans un an de plus. Dix. Toujours. — Ouvrir. Et il se réveille, et il
> a peur, et il a raison.)
> **Chloé** — (« Ne me cherche pas tout de suite. Occupe-toi d'eux d'abord. » … Je me suis occupée d'eux. Tous.
> Ce n'est plus tout de suite.)

Objets : `coeur_1` à `coeur_4` reviennent dans le sac (`coeurs_rendus`).

**CHOIX** — « Cinq Cœurs dans une sacoche d'écolière. Que décide Chloé ? » : « Ouvrir. Ensemble. Sans ambre
noir. » / « Laisser la porte fermée. »

- *« Laisser la porte fermée. »* (3 bulles, puis on rejoint l'autre chemin)
  > **Maïa** — Elle est là-dedans depuis un an, Chloé. Toute seule, avec une bête qui a peur. … Je ne te dis pas
  > quoi faire. Je te dis ce que je ferais.
  > **Isaure** — Je ferai ce que tu décides. Je l'ai dit.
  > *(Le cinquième Cœur bat si fort que la sacoche s'ouvre toute seule. Chloé le rattrape.)* **Chloé** — (Il veut y
  > aller. Elle aussi. … Moi aussi. Bon.)
- *« Ouvrir. Ensemble. Sans ambre noir. »* (puis les 3 bulles communes ci-dessous)

> **Chloé** — On descend. Toutes les trois. Et personne ne le réveille avec une goutte : on la sort sans lui faire
> peur. La fiole, Isaure.
> **Isaure** — … Je ne promets pas ce que je ne sais pas tenir. Je l'ai fait une fois, à Hélène, et tu as vu où ça
> nous a menées.
> **Isaure** — Je ne la toucherai pas tant qu'il y aura un autre moyen. Ça, je peux le tenir.

Drapeau : `apex_decision`.

*Sans texte : Chloé marche jusqu'au portail. Elle pose les Cœurs un à un dans les creux ; chacun s'allume. Au
cinquième, le bois tremble, les deux torches s'éteignent d'un coup, et les battants s'ouvrent vers l'intérieur,
lentement. Un vent chaud. Une lumière d'ambre, de l'autre côté. Caillou éternue.*

> **Chloé** — (J'ai dit que je ne la laisserais pas ouvrir cette porte. C'est vrai : c'est moi qui l'ai ouverte.)
> **Isaure** — … Après toi, moussaillon. Non. Devant toi. Si quelque chose doit arriver en premier, ce sera à moi.
> *(Elle passe la porte.)*
> **Maïa** — Et à moi. *(Elle marche à côté. Caillou derrière. Moustique rentre la tête dans le col de Chloé.)*

Drapeau : `apex_ouvert` (c'est **celui que `dialogue_volcan.gd` attend déjà**). Objets : `coeur_1` à `coeur_5`
quittent le sac (ils restent dans la porte ; les drapeaux `coeur_n` restent vrais). Le `PortailApex` prend son
image ouverte ; la sortie vers `terre_apex` s'ouvre. Isaure, Maïa et Caillou disparaissent de `porte_cratere`
(`hide_flag apex_ouvert`) : on les retrouve en bas.

Personnages/images : Isaure (sans masque, cheveux attachés ; dos, profil, face), Maïa (`maia_arche`), Caillou,
les quatre dinos (espèces existantes `pteranodon`, `baryonyx`, `suchomimus`, `archelon`), `portail_apex_ouvert`,
torches éteintes, le ciel d'aube (teinte du ciel du moteur). Garde-fous : Isaure ne hausse pas la voix ; Maïa
ne se bat pas ; personne ne touche le cinquième Cœur sauf Chloé.

---

## Scène 2 — La Terre des Apex (`terre_apex`)

### 2 a — L'arrivée (scène d'entrée `apex_arrivee`) : 7 bulles

*Le cratère vu du bord : une cuvette de roche noire, sans lave. Dans la roche, des veines d'ambre qui luisent
toutes seules. Un chemin descend en spirale. Ici et là, des blocs d'ambre gros comme des maisons ; dedans, des
formes très grandes, couchées. Tout en bas, au centre, un bloc plus grand que le Cabinet. Isaure et Maïa sont
quelques pas devant, arrêtées. Au-dessus, très haut, une ombre tourne : le Roi.*

> Le cratère. Pas de lave : de la roche noire, et dans la roche, des veines d'ambre qui luisent toutes seules,
> sans lune. Un chemin descend en spirale, comme l'île.
> Ici et là, des blocs d'ambre gros comme des maisons. Dedans, des formes. Des très grandes formes, qui dorment.
> **Chloé** — (Les géants. Elle les a trouvés, et elle les a laissés dormir. « Chacun chez soi. »)
> Tout en bas, au centre, un bloc plus grand que le Cabinet. Quelque chose d'immense dedans, qu'on ne comprend
> pas d'ici. Et contre, une petite forme assise, une main posée.
> **Maïa** — *(tout bas)* C'est elle ?
> **Isaure** — C'est elle. Elle n'a jamais su rester loin de ce qui est trop grand.
> Sur l'épaule de Chloé, Moustique sort la tête du col. Il a cessé de trembler : il n'y a pas de feu, ici.

*Puis Isaure et Maïa descendent devant (sans texte) ; Chloé est libre : la page 39 au cairn, les blocs, le
chemin.*

### 2 b — La page 39 (Pickup `page_39`, le dernier cairn d'Hélène, au bord, à gauche de l'entrée) : 2 bulles, la page, 2 bulles

> Trois pierres noires empilées, et dessous, une pierre plate. Le dernier cairn. Celui-là, elle l'a fait vite :
> les pierres ne sont pas droites.
> Sous la pierre plate, une boîte en fer. Dedans, une page, pliée en deux. L'écriture penche.

**Page 39 — Il a peur** (−1 an ; `letter`, « — H. ») :

> Je suis au bord. D'ici, je le vois à travers l'ambre, et je viens de comprendre quelque chose que j'aurais dû
> comprendre il y a vingt-cinq ans : il a les yeux ouverts. Il ne dort pas. Il n'a jamais dormi. Il a peur, et il
> attend que ça passe, et ça ne passe pas, parce qu'il est tout seul.
> Je descends lui tenir compagnie. Ce n'est pas un sacrifice, Anselme, si tu lis ceci : c'est une position
> confortable, j'ai laissé la couverture en haut, il fait chaud en bas.
> Il a peur. Moi aussi. J'y vais.

> **Chloé** — (Trois mots pour finir. Elle avait écrit « j'ai peur » une fois, à la porte. Elle l'écrit deux.)
> **Chloé** — (Il a les yeux ouverts. … Alors il nous voit arriver.)

Drapeaux : `found_journal_39`, `page_39`.

### 2 c — Les blocs des géants (StoryProp `BlocGeant1` à `4`, examinables ; post-game : ils se réveillent)

> *(1)* Dans l'ambre, une patte plus grande que Chloé, et des griffes comme des faux. Celui-là dort pour de bon.
> Pour l'instant.
> *(2)* Un cou qui fait le tour du bloc deux fois. On ne voit pas la tête : elle est de l'autre côté. Il a l'air
> de sourire. Les grands herbivores ont toujours l'air de sourire.
> *(3)* Des plaques, des pointes, et une queue qu'on ne voudrait pas croiser en rêve. Il ronfle. Dans l'ambre.
> C'est possible, apparemment.
> *(4)* Celui-là est petit, pour un géant : à peine la taille d'une maison. Il a une plume d'Hélène coincée
> dans une fissure, comme un marque-page.

Drapeau : `bloc_geant_vu` (le premier regardé). Post-game (`post_game`) : chaque bloc a une courte scène de
**réveil doux** (à l'agent MÉCANIQUES / une suite ; voir `histoire.md` § Post-game).

*Sans texte : la descente. Le chemin en spirale, les blocs qui passent, les veines d'ambre qui luisent plus fort
à mesure qu'on approche du fond. En bas, Isaure et Maïa attendent devant le bloc, sans y toucher. La sortie de
zone, au fond, mène à `coeur_apex`.*

Personnages/images : sols `roche_apex`, `veines_ambre` (animées si possible), `bloc_geant_1..4` (formes
indistinctes dedans : griffes, cou, plaques, petit), `cairn_helene` (trois pierres), le Roi (`quetzalcoatlus`)
perché très haut sur le bord. Ambiance : un souffle grave et lent, comme une respiration (c'est lui).

---

## Scène 3 — Le Cœur des Apex (`coeur_apex`)

### 3 a — Le bloc (scène d'entrée `coeur_apex_arrivee`, `helene_vue`) : 10 bulles

*Le fond du cratère : une salle ronde à ciel ouvert, les parois veinées d'ambre. Au centre, le bloc. Il bat,
lentement. Dedans : le Souverain, couché, immense, la peau veinée d'ambre comme la roche ; **ses yeux sont
ouverts**. Et contre son flanc, une femme assise, dans l'ambre jusqu'au cou, les cheveux gris, les yeux fermés,
une main à plat sur lui. Isaure est devant, Maïa à côté d'elle, Caillou derrière.*

> Le bloc. De près, il est trop grand pour le regarder d'un coup : il faut lever la tête, puis la tourner.
> Dedans, l'ambre est doré, presque clair. Et il bat. Lentement.
> Le Souverain. Couché, immense, la peau veinée d'ambre comme la roche du cratère. Et ses yeux sont ouverts. Il
> ne dort pas. Il regarde dehors, et il attend.
> Contre son flanc, une femme assise, dans l'ambre jusqu'au cou. Les cheveux gris. Les yeux fermés, elle. Une
> main à plat sur lui, comme on calme un cheval. Les mains sont abîmées.
> **Chloé** — (Hélène.)
> **Chloé** — (Elle a l'air de lui dire quelque chose. Depuis un an.)
> Isaure s'approche. Elle pose sa main sur l'ambre, exactement sur la main d'Hélène, de l'autre côté.
> **Isaure** — Elle n'a jamais eu l'air de dormir. Même quand elle dormait. … Là non plus.
> **Maïa** — Et lui, il nous regarde. *(Le grand œil ambré bouge. Un peu. Vers Chloé.)*
> **Chloé** — Il a peur. Il a toujours eu peur. Elle est là pour ça.

*Sans texte : Moustique s'envole, se pose sur le bloc, tape l'ambre du bec, deux fois, et revient sur l'épaule
de Chloé, vexé.*

### 3 b — Les trois essais (CHOIX, puis regardé, puis une bulle ; trois fois)

**CHOIX** — « Comment la sortir de là ? » : les options dépendent de l'équipe (un dino à **Tranche**, un à
**Charge**, un à **Résonance** ; grisées sinon, avec « personne ne sait faire ça ici »), plus « Je ne sais pas ».
Chaque essai se **regarde** (le dino s'y met, à sa façon), puis une bulle. Après trois essais, ou « Je ne sais
pas », on passe à 3 c. (Si l'équipe n'a aucune capacité : « Je ne sais pas » suffit.)

> *(griffes)* L'ambre ne prend pas une rayure. Pas une. Hélène l'a voulu solide.
> *(charge)* Le bloc ne bouge pas. C'est le dino qui recule, et il s'assoit, et il se demande ce qui s'est passé.
> *(chant)* L'ambre chante avec lui, tout le bloc, longtemps… et c'est tout. Hélène n'a pas fait une porte :
> elle a fait un abri.
> *(« Je ne sais pas », ou après le troisième)* **Chloé** — (Il doit y avoir un autre moyen. Il y en a toujours un.
> Elle l'écrivait à chaque page.)

Drapeaux : `essai_griffes`, `essai_charge`, `essai_chant`, `essais_finis`.

### 3 c — La goutte (`goutte_noire`) : 6 bulles, un CHOIX, 2 bulles

> **Isaure** — Il n'y a pas d'autre moyen, moussaillon. J'ai regardé pendant que tu essayais. J'ai regardé très
> fort.
> Elle sort la fiole. Noire, petite, bouchée de cire. Dans l'ambre, le Souverain la suit des yeux.
> **Isaure** — Une goutte sur l'ambre. Pas sur lui. L'ambre noir mange l'ambre : la dame en gris l'a dit. Il se
> fend, elle sort, et lui ne sentira rien.
> **Chloé** — Il la regarde. La fiole. Il sait ce que c'est.
> **Maïa** — Maman. Tu as dit « tant qu'il y aura un autre moyen ».
> **Isaure** — J'ai tenu parole aussi longtemps que j'ai pu, ma tornade. Il y a un an que je la regarde là-dedans.
> Un an, c'est ce que j'avais.

**CHOIX** — « La fiole est débouchée. » : « Attendez. » / « Pas comme ça. »

> *(« Attendez. »)* **Isaure** — J'ai attendu vingt ans, moussaillon. J'ai arrêté d'être douée pour ça.
> *(« Pas comme ça. »)* **Isaure** — Je ne connais pas d'autre « comme ». Elle les connaissait tous. C'est bien pour
> ça qu'elle est là-dedans, et moi dehors.
> **Chloé** — (La même erreur qu'elle. Il y a vingt-cinq ans, Hélène a voulu le réveiller. « Ne fais pas les mêmes
> erreurs qu'elle » : c'est Isaure qui me l'a dit, sur la passerelle.)

### 3 d — L'éveil (sans texte, environ quinze secondes)

*La goutte tombe sur l'ambre, juste au-dessus de la main d'Hélène. Une veine noire court dans l'or, comme de
l'encre dans l'eau. L'ambre craque en étoile, comme l'autel de Cheminée. Un pan glisse ; Hélène glisse avec,
et Isaure la reçoit, sans trembler, et la pose contre elle. Mais la veine noire continue : le long du bras
d'Hélène, dans le flanc du Souverain. Ses veines d'ambre deviennent violettes, une à une, jusqu'aux yeux. Il
cligne. Puis le bloc éclate. Il se lève : la tête sort de l'écran. Il **crie** : pas un rugissement, un cri de
bête qui ne sait pas où elle est. Le sol tremble, les veines d'ambre du cratère clignotent. Sa queue balaie en
arrière, vers le rocher où sont Isaure et Hélène : **Caillou** charge, se plante, cornes contre queue, glisse
d'un mètre, et tient. **Maïa** attrape sa mère par le col et tire les deux, sa mère et Hélène, derrière le
rocher. Moustique crie dans le col de Chloé. Le Souverain recule contre la paroi, et tremble, et nous regarde.*

Drapeaux : `goutte_noire`, `souverain_eveille`, `helene_sortie` (hors de l'ambre, inconsciente, contre
Isaure), `caillou_rempart`.

### 3 e — « Je te tiens » : 5 bulles

> **Maïa** — Je te tiens. Je t'ai dit que je te tiendrais. *(Elle a sa mère par le col, et Hélène dans les bras
> de sa mère. Elle ne lâche ni l'une ni l'autre.)*
> **Isaure** — … Va, moussaillon. Je ne peux pas. Je n'ai jamais pu : je faisais semblant, avec une fiole.
> **Maïa** — Caillou tient la ligne. Il a dit qu'il tiendrait. Enfin, il a éternué. C'est pareil.
> *(Le dino de départ s'avance et se met entre Chloé et le Souverain. Il ne gronde pas. « +♥ » : Lien à 5, si ce
> n'était pas déjà fait.)* **Chloé** — Tu étais le plus petit, dans la couveuse. Tu te souviens ? … Moi non plus.
> On y va.
> **Chloé** — (Il a peur. Moi aussi. J'y vais.)

Drapeau : `starter_lien_5` (`Game.add_bond` jusqu'à 5). → **Combat.**

### 3 f — Le combat : apaiser le Souverain (`souverain_apaise`)

Règles proposées (`Story.duel("", [[souverain, 50, "le Souverain", {...}]], rules)`) : `corrupted`,
`long_calm`, **`calm_factor: 3`** (jauge 300 : nouvelle règle, ou constante à côté de `LONG_CALM_FACTOR`),
`starter`, `trainer` « » (il est appelé « le Souverain »), **`sceaux`**, **`caillou`**, `antidote` **+
`antidote_min_calm: 0.66`**, musique : celle des Alphas, `lose_spawn` : nulle part (on reprend sur place).

> *intro* — Le Souverain. Il est trop grand pour l'écran, et il tremble de tout son corps. Ses veines sont
> violettes jusqu'aux yeux. Il ne sait pas où il est.
> *lesson* — Les Sceaux. Cinq Alphas ont promis quelque chose à Hélène : ceux qui gardaient un Cœur. Appelle-les, un par un. Et parle-lui :
> il n'a jamais eu que ça, les mots d'Hélène.

Ses attaques (il **frappe en reculant**, jamais en avançant) : *Coup de queue* (fort), *Tremblement* (le sol :
toute l'équipe, faible), *Cri* (peur), et souvent *Il ne bouge pas* (il recule contre la paroi et regarde). Il
ne tombe jamais sous 1 PV. Plus il est calme, moins il frappe (règle existante).

**La commande « Sceaux »** (à la place de Fuite ; on ne fuit pas) : la liste des Sceaux de Chloé ; chacun **une
fois** par combat. L'Alpha apparaît à côté du dino de Chloé (image, cri), une bulle, l'effet, il s'efface.

| Sceau | Alpha | Ce qu'il fait (un tour) | Bulle |
|---|---|---|---|
| Marais | le Spinosaure Ancestral | **L'eau du bassin** : toute l'équipe soignée | « Il n'y a pas d'eau ici. Il en apporte dans sa gueule, sans en perdre une goutte, et chacun boit. » |
| Désert | le Carnotaurus Rouge | **Le vrai rugissement** : +40 de calme (il rugit à côté de lui, sans peur) | « Piment rugit. Pas contre lui : à côté de lui. Un rugissement sans peur. Le Souverain tremble moins. » |
| Côte | le Mosasaure Abyssal | **Il écoute les cœurs** : le prochain coup du Souverain est deux fois plus doux (il n'entre pas : il n'a rien à faire sur la terre ; sa voix monte par les veines d'ambre) | « Très loin, sous l'île, Minuit chante. Le chant monte par les veines d'ambre. Le Souverain baisse la queue. » |
| Monts | le Cryolophosaure Titan | **Le souffle de givre** : le calme ne redescend plus pendant trois tours | « Toupet souffle, et la cendre devient givre. La colère gèle. Pas lui. » |
| Volcan | le T-Rex de Magma | **Il se couche à côté de lui** : +60 de calme ; le Souverain s'arrête de trembler un instant | « Cheminée entre, et se couche à côté de lui, et fume. Le sol tremble. Le Souverain le regarde, et s'arrête. » |

**Caillou** (règle `caillou`, une fois) : le coup qui mettrait le dino de Chloé au sol est pris par Caillou.

> Caillou se met devant ! Le coup glisse sur sa collerette.
> **Maïa** — Caillou ! … Bien. C'est bien. Reste là.

**L'Ambre clair** (règle `antidote`, cadrée par `antidote_min_calm`) : tant que le calme est sous les deux tiers :

> Chloé sort la fiole d'ambre clair… et la range. Il est trop grand pour une goutte. Il faut d'abord qu'il
> l'écoute.

Dès les deux tiers, l'action « Ambre clair » s'allume, et c'est **le dernier geste** : le dino de départ doit
être en combat (s'il est au sol, « Vif se relève. Pour Chloé. » : Lien 5 ; s'il n'est pas le dino actif, le jeu
le fait entrer : « C'est à lui. »). Trois variantes :

> *(Vif)* Vif bondit. De rocher en rocher, de l'épaule au cou, jusqu'au front du Souverain. Et là, il fait ce que
> Griffe-Grise a appris à Chloé : il le gratte sous le menton. Le Souverain s'arrête. Tout s'arrête. Chloé grimpe
> derrière, et verse une goutte. Une seule.
> *(Bastion)* Le coup de queue arrive. Bastion se plante devant Chloé et ne recule pas d'un pas : la queue s'arrête
> contre lui, comme contre un mur de canyon. Il souffle un petit nuage de cendre, pour dire bonjour. Chloé passe
> sous la queue, et verse une goutte. Une seule.
> *(Écho)* Écho chante. La petite note tremblante de la Voix, celle d'une berceuse. L'ambre du sol répond. Puis le
> bloc. Puis les veines du Souverain, une à une. Il baisse la tête jusqu'à Chloé, et elle verse une goutte. Une
> seule.
> L'ambre clair coule le long des veines violettes… et les éteint, une à une. *(texte existant)*
> Les veines violettes s'effacent. Le Souverain est apaisé !

**Perdu** (toute l'équipe au sol) :

> Le Souverain recule contre la paroi, et tremble, et attend. Caillou tient toujours. Les veines d'ambre du sol
> luisent, chaudes, et l'équipe de Chloé se relève.
> **Maïa** — Encore. Il ne part pas, et nous non plus.

(On reprend sur place, l'équipe remise d'aplomb, les Sceaux déjà utilisés **de nouveau disponibles** ; pas de
rechargement de zone.)

Drapeau : `souverain_apaise`. Objet : `antidote_ambre` consommé.

### 3 g — L'ambre se fend (sans texte)

*Les veines s'éteignent des yeux vers la queue. Le Souverain se baisse, lentement, et se couche. Un souffle
long, qui déplace la cendre. Le cratère cesse de trembler ; au loin, le grondement du volcan s'éteint. Les
veines d'ambre du sol passent du blanc à l'or. Il tourne la tête vers le rocher où Maïa tient Isaure, et Isaure
tient Hélène. Il souffle sur elles : un vent chaud. Ce qui reste d'ambre autour d'Hélène, aux poignets, aux
épaules, se fend « comme une noix », et tombe en morceaux dorés. La main d'Hélène bouge.*

Drapeau : `helene_liberee`. Musique : **aucune**, jusqu'à la fin de la scène 3.

### 3 h — Hélène (`helene_reveillee`) : 10 bulles

> Hélène ouvre les yeux. Elle regarde le Souverain, d'abord. Longtemps. Puis Chloé. Puis, à côté de Chloé, le
> dino.
> **Hélène** — *(Vif)* … Le petit de Griffe-Grise. Il a ses yeux. Et deux dents de plus. / *(Bastion)* … Le petit du
> Vieux Rempart. On s'est assis dessus, je parie. Tout le monde s'assoit dessus. / *(Écho)* … Le petit de la Voix.
> Il a chanté ; j'ai entendu, de là-dedans. Il chante faux. Ça ne fait rien.
> **Hélène** — Tu as grandi.
> **Chloé** — (Elle parle au dino. … Non. Elle me regarde.)
> **Hélène** — Tu ne m'as pas cherchée tout de suite.
> **Chloé** — Non. Je les ai trouvés d'abord. Les trois. Maïa en a un, et l'autre est avec moi.
> **Hélène** — Bien. … Alors c'est tout de suite. *(Elle essaie de lever une main ; Isaure la lui tient.)* Isaure.
> **Isaure** — Je t'ai sortie de là. Mal.
> **Hélène** — Tu m'as toujours sortie de partout. Mal. Et je suis toujours sortie. *(un temps)* Tu as attaché tes
> cheveux.
> **Isaure** — … Tu as un an de retard pour le remarquer.

*Sans texte : le Souverain baisse la tête jusqu'à Hélène. Elle pose sa main abîmée sur son museau. Il souffle :
chaud, pas brûlant. Maïa, qui tient toujours sa mère par le col, lâche enfin.*

### 3 i — Moustique, le masque, et lui : 10 bulles

> **Hélène** — Il n'a plus peur. … Vingt-six ans que je le connais, et c'est la première fois que je le vois sans
> peur. *(à Chloé)* C'est toi qui as fait ça. Avec lui. *(le dino)* Je n'aurais pas su.
> **Chloé** — Tu avais écrit comment. Page 10.
> **Hélène** — J'écris mieux que je fais. Tout le monde le sait. Anselme le dit à tout le monde.
> **Chloé** — (Il y avait un autre moyen. C'était lui. Il suffisait qu'il n'ait plus peur. … Personne ne pouvait
> le savoir. Elle, peut-être.)
> Moustique sort du col de Chloé, regarde Maïa, et ne bouge pas. Chloé le prend dans ses deux mains et le pose
> sur l'épaule de Maïa. Puis elle sort le masque en carton.
> **Chloé** — Tiens. Je suis revenue. Tu peux les reprendre.
> **Maïa** — Je savais que tu reviendrais. C'était juste pour être sûre. *(Moustique lui mord l'oreille.)* Aïe.
> Oui. Moi aussi.
> Maïa tend le masque en carton à sa mère. La deuxième fois.
> **Isaure** — … *(Elle le prend. Elle ne le met pas. Elle le glisse dans sa veste, là où était la fiole.)* Je le
> prends. Je ne le mets pas. Pas encore.
> **Maïa** — « Pas encore », c'est mieux que « pas aujourd'hui ». On avance.

Objets : `masque_carton` quitte le sac (`masque_carton_rendu`, `masque_carton_pris`) ; Moustique quitte
l'équipe (ou la réserve) de Chloé (`moustique_rendu` ; il est à Maïa). Si Chloé n'avait pas le masque en carton
(`masque_rendu` faux au ch. 6), les trois bulles du masque sautent (et « Tu peux les reprendre » devient « Tu peux le reprendre ») et Isaure n'a rien dans sa veste jusqu'à la
jetée (elle le sortira de la poche du manteau de Maïa : « Tu l'avais gardé ? — Depuis la Forêt. »).

### 3 j — Le Roi (`apex_fini`) : 3 bulles, puis fondu

*Sans texte : un cri, là-haut. Le Roi des Cieux descend en tournant, se pose au bord de la salle, et baisse le
cou jusqu'à Hélène. Il n'était jamais reparti.*

> **Hélène** — Le Roi. … Il n'est jamais reparti ? *(à Chloé)* « On se penche. On ne ferme pas les yeux. » Je me
> souviens de l'avoir écrit.
> **Hélène** — Je vais les fermer, Chloé. Juste cette fois. Ne le dis pas à Anselme.
> **Maïa** — Nous, on remonte à pied. Je n'ai pas d'ailes, moi, et c'est très bien comme ça. *(à sa mère)* Tu
> viens ? Tu ne cours jamais. Moi non plus.

*Fondu au noir. Le Souverain reste couché au centre du cratère, les yeux ouverts, sans peur. Carton : « Trois
jours plus tard ».*

Drapeau : `apex_fini`. Le Souverain devient un DinoNpc permanent de `coeur_apex` (apaisé, couché : une réplique
d'examen : « Il dort les yeux ouverts. Il n'a plus peur. Il respire, et la cendre bouge. »).

Personnages/images de la scène 3 : `bloc_souverain` (entier avec les deux formes dedans ; fendu ; éclaté) ; le
**Souverain** (espèce `souverain`, profil/face/dos, `_corrompu`, couché ; voir la question 6 du plan) ;
`helene_ambre` (dans le bloc : fait partie du prop) ; `isaure_helene` (Isaure assise, Hélène contre elle :
prop) ; `helene` (assise au sol, puis debout soutenue) ; Caillou cornes baissées ; les cinq Alphas gardiens de Cœurs en combat
(planches existantes) ; le Roi ; fond de combat `apex.jpg` (la salle ronde, les veines d'ambre). Sons : le cri
du Souverain (un cri, pas un rugissement : grave et court), le souffle, le craquement de l'ambre.

---

## Scène 4 — Épilogue : le Cabinet (trois jours plus tard)

### 4 a — Le thé (scène d'entrée du Cabinet, dès `apex_fini` : `epilogue_cabinet`) : 11 bulles (9 sans les moufles)

*Le Cabinet, de jour. Hélène dans le fauteuil de Roc, une couverture sur les genoux, le chapeau d'Hélène
toujours à sa patère. La caisse des carnets sur le bureau. Roc, debout, une théière à la main. Le dino de
départ va droit à la couveuse et s'y couche.*

> Le Cabinet. Hélène dans le fauteuil de Roc, une couverture sur les genoux. Roc ne dit rien. Il fait du thé. Il
> en fait depuis trois jours.
> **Chloé** — (Elle a fermé les yeux pendant tout le vol. Je ne l'ai dit à personne.)
> **Hélène** — Anselme. Tu as surveillé le sceau. Chaque nuit, pendant un an.
> **Roc** — Vous aviez dit « pas même à Chloé ».
> **Hélène** — J'avais tort. Elle a tout trouvé toute seule.
> **Roc** — Elle trouve tout toute seule. C'est très agaçant. *(Il pose la tasse.)* Comme vous.
> **Hélène** — *(à Chloé)* La dernière fois, il m'a boudée jusqu'à la vallée. Là, il me boude jusqu'au thé. Il
> progresse.
> *(si `moufles_helene`)* Chloé sort les moufles rouges. **Chloé** — Bertille a dit que tu les avais laissées pour
> quelqu'un.
> **Hélène** — Pour moi. Elle m'en tricotait chaque hiver ; je les perdais chaque printemps. *(Elle les met. Elles
> sont trop grandes pour elle aussi.)* Parfaites.
> **Roc** — La dame en gris a rapporté vos carnets. Tous. Elle a dit qu'elle refaisait ses tables. J'ai fait du
> thé.
> **Hélène** — « Presque », c'est un mot merveilleux. Je les ai presque tous brûlés. *(Elle regarde la caisse.)*
> On brûlera le reste ensemble, elle et moi. Les bons, on les garde.

Objet : `moufles_helene` quitte le sac (`moufles_rendues`). *Sans texte : on frappe. Roc regarde la porte, puis
Hélène, puis la porte. Il y va.*

### 4 b — La porte (`isaure_cabinet`) : 7 bulles

> Roc ouvre. Isaure, sur le seuil. Les cheveux attachés. Elle n'entre pas.
> **Roc** — … Tu venais prendre le thé, au début. Puis tu venais à la porte. Puis plus du tout.
> **Isaure** — Je suis à la porte, Anselme.
> **Roc** — Je vois ça. *(Il ne bouge pas. Puis il s'écarte.)* Il y a du thé.
> **Hélène** — Anselme. La tasse bleue.
> **Roc** — Laquelle ? … *(Il s'arrête.)* Vous l'avez gardée.
> **Hélène** — Je garde tout. C'est écrit quelque part.

*Sans texte : Roc monte sur une chaise, prend sur la plus haute étagère une tasse bleue, ébréchée, souffle la
poussière, la remplit. Hélène la pousse vers le bord de la table, avec sa moufle. Isaure la regarde longtemps.
Elle s'assoit. Elle ne boit pas.*

### 4 c — La tasse bleue (`tasse_bleue`, `reserve_dite`) : 10 bulles

*(Si Chloé a encore `lettre_isaure` : avant, 3 bulles : **Chloé** — « Elle est pour vous. Je l'ai gardée jusqu'à
ce qu'on soit tous dans la même pièce. » Isaure lit. Hélène regarde ailleurs. Personne ne dit rien pendant une
page. **Isaure** — « … Tu écris tout. » **Hélène** — « Tu ne lis rien. On se complète. » Drapeau `lettre_lue`,
objet retiré. Si la lettre a été donnée à la porte : **Isaure** — « Je l'ai lue. Au bord du cratère, pendant
qu'elles te descendaient. Tu écris tout. » : une bulle. Dans les deux cas, **sans texte** ensuite : Isaure replie
la lettre, la glisse dans sa veste, à côté du masque en carton ; Hélène attend qu'elle ait fini. Puis les dix
bulles ci-dessous.)*

> **Hélène** — Tu as fait peur à des bêtes qui dormaient. Pendant douze ans. Et tu m'as pris mes carnets, et un
> œuf, et vingt ans.
> **Isaure** — Oui.
> **Hélène** — Je ne te pardonne pas aujourd'hui. Je ne sais pas quel jour. Mais je sais ce que tu vas faire d'ici
> là.
> **Isaure** — Dis.
> **Hélène** — Tu démontes les forges. Toi, avec tes mains, pas avec des gens payés. Anselme tient l'échelle : il
> a le vertige.
> **Roc** — Je n'ai pas… Si. J'ai le vertige.
> **Hélène** — Et après, tu me ramènes des gens. En barque. Des gens qui viennent voir, et qui repartent le soir.
> Vivants, et avec rien dans les poches qui brille. Ton port vivra de ça. Pas de ce qu'il vend : de ce qu'il
> montre.
> **Isaure** — … Une réserve.
> **Hélène** — La Réserve d'Ambrelune. J'y pense depuis vingt ans. Il fallait quelqu'un qui connaisse la mer. Je
> n'avais que toi. Je n'ai toujours que toi.
> Isaure prend la tasse bleue. Elle boit. C'est tout. C'est beaucoup.

**CHOIX** — « Elles se regardent. Chloé… » : « Reste. » / « Les laisse. »

> *(« Reste. »)* **Hélène** — Reste, oui. … Non. Va voir Maïa. Elle est sur la marche depuis une heure, elle
> compte les Compsognathus. *(1 bulle)*
> *(« Les laisse. »)* **Chloé** — (Vingt ans à rattraper. Dont la moitié est de la faute d'Hélène : c'est écrit,
> page 37.) *(1 bulle)*

### 4 d — La marche (4 bulles)

*Dehors : Maïa sur la marche du Cabinet, Moustique sur l'épaule, Caillou couché en travers de la ruelle.*

> **Maïa** — Elles vont parler jusqu'à la nuit. Maman ne parle jamais autant. … Enfin, je crois. Je ne l'ai jamais
> vue avec quelqu'un qui dit non.
> **Chloé** — Hélène dit non pas fort.
> **Maïa** — C'est pire. *(Caillou éternue.)* Il éternue toujours quand c'est toi. On ne saura jamais pourquoi.
> C'est stylé, je trouve.
> **Chloé** — (Roc fait du thé. Isaure boit dans la tasse bleue. Le Souverain dort les yeux ouverts, sans peur. …
> Il reste une page. Elle a toujours laissé une page. Celle-là, elle va l'écrire.)

Drapeau : `epilogue_cabinet`. Objectif : « Demain, sur la jetée de Port-Ambre ». La scène 5 se joue à la
prochaine entrée dans `port_ambre` de jour (le temps passe à « le lendemain »).

Personnages/images : `helene_assise` (fauteuil, couverture, moufles rouges), `isaure` assise (une pose assise
existe-t-elle ? sinon debout près de la table), Roc (debout ; sur une chaise : simple décalage), `tasse_bleue`
(prop, ébréchée), `caisse_carnets`, Maïa assise sur la marche (pose assise du ch. 8), Caillou couché.

---

## Scène 5 — Épilogue : la jetée (`port_ambre`, le lendemain, dès `epilogue_cabinet`)

### 5 a — La Réserve (`epilogue_port`, `reserve_annoncee`) : 10 bulles

*Sans texte : la jetée de Port-Ambre, de jour. Tout le village : Léonce, Gustave et Firmin (sans masques),
Rosalie, Mémé Pervenche, Joss (arrivé par la barque de Maïa), M. Hamon et son chapeau de paille, et au fond,
sans gants, Dame Suie. Au bout de la jetée, Brac, assis, avec Mastoc, Cabosse, Grognon, et un sandwich. Isaure à
sa barque. Hélène arrive au bras de Roc, un chapeau neuf. Maïa court rejoindre Chloé.*

> Port-Ambre. Tout le village sur la jetée, ce qui ne fait pas beaucoup de monde, et c'est déjà plus qu'avant.
> Hélène au bras de Roc, un chapeau neuf. En paille : pas de feutre, Cheminée aime le feutre.
> **Hélène** — Je ne ferai pas de discours. Anselme en a préparé un ; il le gardera.
> **Hélène** — Cette île est à ceux qui y dorment. Elle ne se vend pas, pas un galet. Mais elle se montre. À partir
> de demain, Ambrelune est une Réserve. Des gens viendront la voir, encadrés, à pied, et ils repartiront le soir
> avec rien dans les poches qui brille.
> **Hélène** — Les barques de la capitaine Kerval les amèneront. Tarif unique. Le port vivra de ça.
> **Isaure** — Et on ne vend rien qui brille. Elle l'a dit ; je le redis, parce que c'est moi qui tiens la barre.
> **Léonce** — Et le poisson ?
> **Hélène** — Il reviendra, Léonce. Il revient toujours quand on arrête de le regarder.
> **M. Hamon** — Un parc ! Enfin ! Je n'ai lésiné sur rien !
> **Hélène** — Une réserve, monsieur Hamon. … Non, ce n'est pas pareil. Chacun chez soi. Vous aurez un banc.

*Sans texte : au bout de la jetée, une grande main se lève. Tout le monde se retourne.*

### 5 b — Brac (`brac_gardien`) : 9 bulles

> **Brac** — ET MOI ? *(Il baisse la voix. Un peu.)* … Et moi, madame Varenne ? Je connais les cages. Dans l'autre
> sens, ça doit se faire.
> **Hélène** — Vous êtes Brac.
> **Brac** — *(Il tend une carte. Il y a de la cendre dessus.)* Brac. Braconnier. C'est écrit.
> **Hélène** — Il y a une adresse ?
> **Brac** — Le bout de la jetée.
> **Hélène** — C'est une adresse. *(Elle garde la carte.)* Gardien de nuit. Les visiteurs auront peur de vous :
> c'est parfait, ils resteront sur le chemin.
> **Brac** — … Crotte de Stégosaure. *(Mastoc pose sa tête sur son genou.)* C'est oui. C'est oui, moucheron, arrête
> de sourire.
> **Maïa** — Il lui reste deux cent quatre-vingt-dix-huit cartes. Il va falloir les distribuer.
> **Brac** — *(si `fournaise_garde`)* Et tu as gardé Fournaise, moucheron ? Il mange à la pelle. Je te préviens.
> / *(sinon)* Fournaise est aux coulées. Il dort au chaud. Il m'a jamais écrit.

*Sans texte : Hélène fait signe à Chloé et à Maïa de venir. Isaure quitte sa barque et s'approche.*

### 5 c — Les gardiennes (`gardiennes_nommees`) : 8 bulles

> **Hélène** — Une réserve, ça se garde. Pas avec des cages : avec des gens que les bêtes connaissent. *(Elle sort
> deux disques d'ambre, nus, avec une fougère.)* Les Alphas vous reconnaîtront. Ils vous reconnaissent déjà.
> **Hélène** — Chloé Varenne. Maïa Kerval. Premières gardiennes de la Réserve d'Ambrelune. Ce n'est pas un cadeau
> : c'est du travail. Vous avez l'habitude.
> **Maïa** — Moi ? Je… j'étais de l'autre côté de la porte.
> **Hélène** — Tu étais du côté de ta mère. C'est le plus difficile des deux. Et tu as tenu : la ligne, et elle.
> Les gardiens, c'est ça.
> **Isaure** — *(tout bas)* Elle a mon courage. Je l'ai dit.
> **Maïa** — Et pas assez de prudence. Tu l'as dit aussi. *(à Chloé)* Gardiennes. C'est stylé. Hein ? C'est stylé.
> **Chloé** — C'est stylé.
> **Roc** — *(il se mouche)* C'est le vent. Il y a du vent.

Objet : `insigne_gardienne` (Chloé ; celui de Maïa reste à Maïa). Drapeau : `gardiennes_nommees`.

### 5 d — « Bouh » (`masque_carton_porte`) : 3 bulles

*Sans texte : Isaure sort de sa veste le masque en carton. Elle regarde Maïa. Elle le met : l'élastique est cassé,
elle le tient d'une main.*

> **Isaure** — *(derrière le masque)* Bouh.
> **Maïa** — … C'est nul. C'est le meilleur « bouh » du monde. *(Elle ne pleure pas. Elle rit. Isaure aussi. C'est
> la première fois qu'on les entend rire toutes les deux.)*
> **Chloé** — (Un masque en carton, tenu à la main parce que l'élastique est cassé. Le premier masque de l'Ombre
> Noire que quelqu'un met pour rire. Et le dernier.)

*Sans texte : Brac éclate de rire, un rire à faire trembler les casseroles. Caillou éternue sur Brac.*

### 5 e — La page 40 (`found_journal_40`, `epilogue_fini`, `post_game`) : 1 bulle, la page, 3 bulles

*Sans texte : Hélène emmène Chloé au bout de la jetée, à l'endroit où elle a débarqué, le premier jour, de la
barque d'Isaure. Le dino de départ les suit.*

> **Hélène** — Il te manque une page. Je l'ai écrite ce matin ; l'encre a séché sur la barque. Je n'écris pas « je
> t'aime » aux enfants que j'ai trop peu vues. Alors lis entre les lignes. Tu sais faire : tu as mes yeux.

**Page 40 — Ce qui dort n'est pas mort** (aujourd'hui ; `letter`, « — H. ») :

> J'ai passé trente ans à réveiller ce qui dormait, et un an à dormir à côté de ce qui avait peur. J'ai appris la
> deuxième chose trop tard : on ne réveille rien de force, ni un dino, ni une amie, ni un port. On s'assoit à
> côté, et on attend qu'il n'ait plus peur.
> Je t'ai écrit « ne fais confiance qu'aux dinos ». J'avais tort d'un mot. Fais confiance comme les dinos : à qui
> reste.
> Ce qui dort n'est pas mort. Ni l'ambre, ni l'île, ni ce qu'il y avait entre Isaure et moi. Il fallait quelqu'un
> pour s'asseoir à côté. C'était toi. Tu as grandi, et je l'ai vu : c'est la seule chose que je ne voulais pas
> rater, et je ne l'ai pas ratée.
> Le Cabinet est à toi. Il l'a toujours été. Je reprends juste mon fauteuil.

> **Chloé** — (Quarante pages. Sur la première, elle pleurait de joie à côté d'Anselme. Sur la dernière, elle est
> à côté de moi.)
> Le dino de départ pose sa tête contre la jambe de Chloé. Au loin, sur le bord du cratère, une forme immense
> s'est couchée, et regarde la mer.
> **Chloé** — *(au dino)* Tu as grandi, toi aussi.

*Fondu. Carton : « Ambrelune ». Puis : « L'île est à vous. Les géants du cratère se réveillent un à un… » Retour
au jeu sur la jetée : le post-game est ouvert (`post_game`).*

Personnages/images : `helene` debout (chapeau de paille, au bras de Roc puis seule au bout de la jetée),
`isaure_masque_carton` (variante : le masque tenu à la main), Maïa, Caillou, Moustique, Brac assis (ch. 8) et ses
trois dinos, Dame Suie sans gants, M. Hamon, Joss, les pêcheurs sans masques, Rosalie, Mémé Pervenche ;
`insigne_gardienne.png` (UI) ; au loin, la silhouette du Souverain couché sur le bord du volcan (un prop
lointain, ou rien : la phrase suffit). Musique : le thème du prologue (la barque), s'il existe, repris doucement ;
sinon la mer.

---

## Autour : Roc, Hélène, Isaure, Maïa, Bertille, Joss, Dame Suie, Brac, Léonce, les Anciens (post-game)

**Roc au Cabinet** (`roc_epilogue_n`, dès `epilogue_fini`) : « Elle a repris son fauteuil. J'ai repris la cuisine.
On se croise au thé. » / « Elle veut que j'aille démonter les forges avec Isaure. Tenir l'échelle. J'ai dit oui.
J'ai le vertige depuis. » / « Cheminée a demandé après vous. Enfin, il a fumé dans ma direction. Chez lui, c'est
pareil. » / *(si Fournaise est dans l'équipe)* « Le gros de Brac dort devant la couveuse. Il fume aussi. Je vais
finir par m'habituer. »

**Hélène au Cabinet** (`helene_cabinet_n`, dans son fauteuil ; post-game) : « Les géants du cratère vont se
réveiller un par un. Pas de force : à leur heure. Quand l'un d'eux ouvre l'œil, viens me le dire ; j'ai des
choses à t'apprendre sur chacun. » / « Griffe-Grise ? Il va bien ? … Il grogne ? Alors il va bien. » (ou le
Vieux Rempart : « On s'est assis dessus ? », la Voix : « Elle chante faux le matin. C'est très bien.) /
« Isaure a démonté la première forge. Elle a mis trois jours. Anselme a tenu l'échelle deux heures, puis il a
tenu la théière. » / « Les œufs rares, dans la couveuse : ce sont les derniers de l'Ambre-Mère que je réveillerai.
Les autres, c'est toi. Doucement. » / « Tu veux ma recette pour un Alpha qui boude ? Trois semaines sur une
pierre chaude. Prévois deux chapeaux. »

**Isaure à sa barque** (`isaure_barque_n`, Port-Ambre, post-game ; sa barque remplace / complète celle de Maïa
pour le voyage rapide : « Où met-on le cap, moussaillon ? Tarif unique : rien. ») : « Les forges, c'est fait.
Il reste les cendres. Les cendres, ça se balaye. » / « J'ai remis le masque en carton pour les enfants du Havre.
Ils ont ri. Un seul a eu peur : le fils de Ferréol. Il a de quoi. » / « Hauban pêche pour le port. Il a repris
tout seul. Il n'a jamais eu besoin qu'on lui dise. »

**Maïa au Grand Crâne** (`maia_gardienne_n`, post-game ; défi n° 6, niveau 50, « pour voir », une fois par jour)
: « Gardienne, ça veut dire qu'on garde. Alors je garde le Crâne. Et toi ? … Tout le reste ? C'est injuste. On
échange demain. » / « Caillou a éternué sur Brac. Il a dit que c'était un signe. Brac. Pas Caillou. » / « Je l'ai
battue aux nœuds, hier. Maman. Pour la première fois. Elle a dit « enfin ». »

**Bertille aux Monts** (`bertille_helene_remontee`, dès `apex_fini`) : « La dame aux mains abîmées est
descendue… et remontée. Zéro feu, et une de plus. Je recompte : ça fait juste. … Je vais tricoter. Elle va
encore les perdre. »

**Joss** (`joss_poche_piaf`, sur la jetée à l'épilogue puis au Havre) : « Maïa ! Le manteau. À ta taille. Avec
une poche pour le piaf. *(Moustique entre dans la poche, et n'en ressort plus.)* … Regarde ces coutures. Non,
vraiment : regarde-les. »

**Dame Suie au port** (`suie_port_n`, sur le quai, sans gants, post-game) : « Je refais mes tables, mademoiselle
Varenne. Il y a une colonne pour vous, maintenant. Et une pour le Souverain : « sans une goutte ». … Une
goutte, en fait. La bonne. » / *(avec Hélène, une fois)* **Hélène** — « Vous avez brûlé mes notes. » **Suie** —
« Presque toutes, madame. » **Hélène** — « … C'est un mot merveilleux, « presque ». » **Suie** — « C'est ce que
j'ai dit à votre petite-fille. Elle n'a pas souri non plus. » / « Si un dino de la Réserve a des veines, un
jour, venez me voir. Je sais défaire. C'est la première règle ; je l'ai apprise en dernier. »

**Brac au bout de la jetée** (`brac_jetee_n`, post-game, de nuit en tenue de gardien : une lanterne, le même
sandwich) : « Gardien de nuit. Je surveille la mer. De loin. Rien ne bouge. C'est le meilleur boulot du
monde. » / « Mastoc a peur du noir. Je lui laisse la lanterne. Moi, j'ai pas peur. J'ai l'habitude d'avoir
peur, c'est pas pareil. » / « Il m'a fait un panneau, le vieux : « Gardien : BRAC ». Avec les lunettes, il a
écrit « BARC ». Je garde. »

**Léonce** : « Le poisson est revenu. Pas beaucoup. Assez. » / « La capitaine a mis un masque en carton. On a
tous fait semblant d'avoir peur. Elle a dit merci. »

**Les Anciens** (`anciens_helene_n`, une réplique d'examen chacun, post-game) : Griffe-Grise « a grogné vers le
port, longuement, puis s'est roulé en boule. Il sait. » ; le Vieux Rempart « souffle un nuage de sable deux fois
: une pour Chloé, une pour quelqu'un d'autre » ; la Voix « chante une note qu'elle n'a pas chantée depuis un an.
Elle la tient longtemps. »

**Objectifs** (`story/apex_objectives.gd`) : l'aube (le dino de départ dans l'équipe ; soigner) → Isaure → la
porte → la Terre des Apex (la page 39, en secondaire) → le fond : Hélène → le Souverain (astuce : « Les Sceaux
appellent les Alphas. L'Ambre clair quand il écoute. ») → le Cabinet (trois jours plus tard) → la jetée (le
lendemain) → fin. Post-game : « Les géants du cratère », « Le Dinodex », « Les fossiles », « Les revanches »,
« Hélène au Cabinet », « Nouvelle partie+ ».

**Équilibrage** (agent MÉCANIQUES ; équipe 48-50) : Isaure 47/47/48/49 (Carène hésite un tour) : 85-95 % avec
une équipe de fin de Volcan, jamais un mur ; le Souverain 50, jauge 300 : sans Sceaux 15-25 tours, avec cinq à
les cinq Sceaux 8-12 tours ; la défaite ne coûte rien (on reprend sur place) ; l'Ambre clair à deux tiers de calme.

---

## Personnages, doublures, images nécessaires (récapitulatif pour les agents CARTE, IMAGES, MÉCANIQUES)

| Quoi | Détail |
|---|---|
| Chloé | planches existantes ; pose « grimpe » pour la variante Vif du dernier geste (facultatif : un déplacement suffit) |
| Le dino de départ | planches existantes ; Vif bondit (sauts `Stage.hop`), Bastion se plante (recul nul), Écho chante (émote) |
| Moustique | sur l'épaule (ch. 7-8) ; passe sur l'épaule de Maïa ; dans la poche du manteau de Joss (émote) |
| Isaure | `isaure_sans_masque` (cheveux attachés si variante) ; **`isaure_masque_carton`** (le masque tenu à la main, face) ; assise au Cabinet (plus) |
| Maïa | `maia_arche` (manteau de Joss) ; assise sur la marche ; le nouveau manteau de Joss (facultatif, ou le même) |
| Caillou | Tricératops : cornes baissées (charge), couché |
| Les dinos d'Isaure | `pteranodon`, `baryonyx`, `suchomimus`, `archelon` (existants) ; aucune planche nouvelle |
| **Hélène** | **nouveau personnage** : `helene` (debout, chapeau de paille, canne ou au bras de Roc), `helene_assise` (fauteuil), `helene_sol` (assise au sol, soutenue), plus les props `helene_ambre` (dans le bloc) et `isaure_helene` (Isaure assise, Hélène contre elle) ; cheveux gris, mains abîmées (visibles de près : bandes ou rougeurs, rien d'effrayant), 1,60 m |
| **Le Souverain** | **nouvelle espèce** `souverain` : profil, face, dos, `_corrompu`, couché ; environ 12 m (×1,5 en scène, « trop grand pour l'écran ») ; peau veinée d'ambre, yeux ambrés ; voir la question 6 du plan pour l'allure |
| Les cinq Alphas gardiens de Cœurs (Marais, Désert, Côte, Monts, Volcan) | planches existantes (`triceratops`, `utahraptor`, `spinosaurus`, `carnotaurus`, `mosasaure_abyssal` : seulement sa voix, pas d'image, ou une onde sur le sol, `cryolophosaure_titan`, `quetzalcoatlus`, `trex_magma`) ; apparition en combat : fondu, cri, effet |
| Props | `bloc_souverain` (entier / fendu / éclaté, avec les deux formes dedans), `bloc_geant_1..4`, `cairn_helene`, `portail_apex_ouvert`, torches éteintes, `tasse_bleue`, `caisse_carnets`, `insigne_gardienne` (UI) |
| Sols | `roche_apex`, `veines_ambre` (animées : blanches pendant l'éveil, or après) |
| Fond de combat | `assets/art/battle/apex.jpg` (la salle ronde, les veines d'ambre) ; le fond de la porte pour Isaure : `volcan.jpg` existant, ou un `porte.jpg` à l'aube |
| Sons | le cri du Souverain (grave, court, pas un rugissement), le craquement de l'ambre, le sifflet de marin d'Isaure, le « Bouh » (rien : la bulle), le rire de Brac (existant ?) |
| Musiques | **aucune** à l'aube ni au réveil d'Hélène ; celle des Alphas pour le Souverain ; le thème de la barque du prologue à la jetée (ou la mer) |

---

## Autocritique (trois passes)

**Passe 1 (surprendre).** Les rebonds : (1) le Souverain **a les yeux ouverts** : il n'a jamais dormi, il a peur
depuis vingt-cinq ans, et la page 39 le dit avant qu'on le voie ; (2) Isaure se bat avec **des dinos qu'elle n'a
jamais forcés** : elle avait le Lien ; (3) elle **avoue l'œuf** avant le combat, « parce qu'on avoue avant » ;
(4) le **pari** tenu, les Cœurs rendus, et **c'est Chloé qui ouvre** ; (5) la goutte **sur l'ambre d'Hélène**, pas
sur lui, et la veine noire qui court quand même : la même erreur qu'Hélène ; (6) **Caillou** cornes contre queue ;
(7) **l'autre moyen, c'était lui** ; (8) Hélène drôle dès la première minute (« Tu as attaché tes cheveux. — Tu as
un an de retard pour le remarquer. ») ; (9) la **tasse bleue** ; (10) « Je n'avais que toi. Je n'ai toujours que
toi. » ; (11) la carte de Brac qui a enfin une adresse ; (12) « Bouh. »

**Passe 2 (émouvoir sans cruauté).** Vérifié : le Souverain a peur, tremble, crie, recule ; il ne saigne pas,
n'est pas « vaincu », et c'est lui qui ouvre l'ambre d'Hélène à la fin ; Isaure n'est jamais humiliée (elle perd
un pari qu'elle a proposé, le tient, et c'est elle qui reçoit Hélène « sans trembler ») ; elle ne ment pas (elle a
refusé de promettre) ; Maïa tient d'une main sa mère et de l'autre rien du tout, ne pleure pas, et rit à la fin ;
Hélène ne pardonne pas « aujourd'hui » et dit ce qu'Isaure fera : c'est une peine, et une place ; Roc se mouche
(« c'est le vent »). Les moments émus tiennent en moins de cinq bulles et sont suivis d'une drôlerie (le dino qui
s'assoit après la charge, « Il progresse », le vertige de Roc, Caillou qui éternue sur Brac).

**Passe 3 (continuité et rythme).** `apex_ouvert` est le drapeau que `dialogue_volcan.gd` attend ; la lettre
peut encore être dans le sac (deux rattrapages : l'aube, le Cabinet) ; le troisième petit peut être au Cabinet
(l'aveu s'adapte) ; le dino de départ est exigé dans l'équipe avant l'aube (sinon le dernier geste n'a pas de
sens) et monté à Lien 5 par l'histoire ; les Cœurs 1 à 4 reviennent puis les cinq restent dans la porte (les
drapeaux restent) ; Moustique et le masque en carton repartent avec Maïa (si Chloé n'avait pas le masque, les
bulles sautent) ; les moufles de Bertille reviennent à Hélène ; Fournaise a sa ligne chez Brac ; la fiole
d'Isaure est bien celle que Dame Suie lui a donnée à l'aube du ch. 8 ; le Roi des Cieux redescend Hélène (il
regardait « longtemps en bas » depuis le ch. 7). Rythme : aucun bloc ne dépasse **11 bulles** (le plus long : le
thé, 11 avec les moufles ; la tasse bleue, 10 ; Hélène, 10 ; Moustique et le masque, 10) ; entre deux blocs, le joueur choisit (sept choix en tout, un seul
vrai dilemme), regarde (l'éveil, la porte, les essais, « Bouh »), marche (le cratère) ou combat (deux fois).
Faiblesses connues : la commande « Sceaux » est du code nouveau (cinq effets, décidé par Greg le 19/10 ; ancienne note : « à simplifier en cinq si Greg le
veut) ; le « réveil doux » des géants du post-game n'est qu'esquissé ; l'allure du Souverain reste à choisir.
