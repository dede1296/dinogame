# Post-game — les scènes (texte complet)

> Écrit le 20/10/2026 par l'agent HISTOIRE (Fable), d'après `post-game-plan.md` (huit questions pour Greg en
> tête). Même format que les ch. 8-9 : didascalies *en italique* (à traduire en `cue` / `Stage.*`), dialogues par
> lieu et par état, pensées de Chloé entre parenthèses, les pages hors journal (le carnet des os), et pour chaque
> scène ses drapeaux, objets, événements. **Rien n'est codé.** Entre deux scènes, une ligne « ▶ Le joueur… » dit
> ce qu'il fait.
>
> Ton : le jeu est fini, personne n'est pressé. Hélène est drôle et sèche, Sirocco crie, Isaure ne sourit qu'après,
> Brac ne demande rien, Maïa veut sa revanche « de peu ». Rien d'effrayant : les géants ont peur, bâillent, posent
> un doigt. Règle des scènes courtes : **jamais plus de 10 bulles d'affilée** ici (le plus long : Brac, 10 ; la
> résurrection, 9). Le dino **en tête** est `%s` = `lead.nickname` ; le dino de départ n'est nommé que si la
> scène parle de lui (jamais ici).

## Conventions

- Lieux : `terre_apex` (les blocs), `cabinet` (Hélène au fauteuil, la couveuse), `port_ambre` (la jetée, la barque),
  `desert` (la tente de Sirocco), et chez chaque Alpha. Tout est conditionné à `post_game` (ou `insigne_gardienne`),
  sauf la scène B1 de Brac (entre le ch. 8 et l'épilogue).
- Hélène parle depuis son fauteuil (`helene_cabinet`) : ses scènes du post-game passent **avant** son pool de
  répliques, une fois chacune ; ensuite le pool reprend, enrichi d'une ligne par géant réveillé.
- « Son heure » (géants) : `aube` / `crépuscule` / `pleine lune` / `nuit` de l'horloge du jeu ; l'objectif « Les
  géants du cratère » dit lequel ouvre l'œil et quand.

## Carte des drapeaux, objets, événements

| Scène | Drapeaux posés | Objets | Événements / nœuds |
|---|---|---|---|
| G1 l'œil (×4) | `geant_4_oeil`, puis `geant_2_oeil`, `geant_1_oeil`, `geant_3_oeil` (un à un, à son heure) | — | StoryProp `BlocGeant<n>` (image `bloc_geant_<n>_oeil`) |
| G2 Hélène conseille (×4) | `geant_<n>_conseil` | — | Npc `HeleneAssise`, événement `helene_cabinet` |
| G3 s'asseoir (×4) | `geant_<n>_reveille`, `geant_<n>_lien` | — | action « S'asseoir à côté » sur `BlocGeant<n>` ; `Game.add_bond(lead)` ; `Game.mark_seen(<id>)` ; DinoNpc `Geant<n>` résident ; image `bloc_geant_<n>_vide` |
| G4 la plume | `plume_rendue` | `plume_helene` (ramassée en G3-4, gardée : « Garde-la ») | — |
| G5 quatre | `geants_reveilles` | — | région `apex` complète (`DexDB.pending_rewards`, Roc) |
| F1 Sirocco | `carnet_os`, `carnet_terre` | `carnet_os` | Npc `Sirocco` (Désert) ; mur du journal, section « Carnet des os » |
| F2 un os (×15) | `os_titanosaure_1..5`, `os_kronosaurus_1..5`, `os_gigantoraptor_1..5` | `os_titanosaure`, `os_kronosaurus`, `os_gigantoraptor` (compte 0-5) | 13 `DigSpot`, 2 StoryProp examinés (`CraneTitanosaure`, `CraneKronosaurus`) |
| F3 Hélène, un premier os (×3) | `helene_os_<squelette>` | — | `helene_cabinet` |
| F4 résurrection (×3) | `ressuscite_<id>` | 20 larmes consommées ; `Game.egg` posé | la couveuse ; `EGG_LEVELS[id] = 45` |
| F5 éclosion | — (mécanique existante) | le dino rejoint l'équipe / la réserve | — |
| R1 Maïa n° 6 | `maia_defi_6_jour` (= jour), `maia_defi_6` | — | `maia_gardienne` (existant) ; `ApexBattles.maia_team`, `MAIA_RULES` |
| R2 Alpha (×7) | `alpha_<id>_jour`, `alpha_<id>_reconnu` ; `sceau_<region>_eveille` | pièces | l'événement d'Alpha de chaque chapitre → `Revanches.alpha` |
| R3 Isaure, le pari | `isaure_pari_jour`, `isaure_pari_gagne`, `carnet_mer` | pièces ; la page de la mer au carnet | `isaure_barque` (existant) |
| R4 Hélène, les Sceaux | `helene_sceaux` | — | `helene_cabinet` |
| N1-N3 Nouvelle partie+ | `ng_plus` (int), `journal_lu` (liste) | — | `ui/save_slots.gd`, le prologue (l'œuf), le mur du journal |
| B1 le phare qui boude | `brac_jetee_vu`, `brac_jetee_avant_n` | — | Npc `BracJetee` (dès `brac_parti`, avant `epilogue_cabinet`) ; prop `Sandwich` (code) |
| B2 le partage | `brac_sandwich_partage` | — | `brac_jetee` (après `epilogue_fini`, de jour) |
| B3 les bêtes, la nuit | — | — | DinoNpc `MastocJetee`, `CabosseJetee`, `GrognonJetee` (examen) ; prop `PanneauBarc` (code, dès `epilogue_fini`) ; planche `brac_gardien` la nuit |

---

## G — Les géants du cratère

### G1 — L'œil (`terre_apex`, le bloc 4 à l'aube ; puis 2 à la pleine lune, 1 au crépuscule, 3 la nuit) : 2 bulles

*Le bloc pulse doucement (`CS.pulse`), image « œil ». Examiner le bloc :*

> Le petit bloc. Dans l'ambre, quelque chose a bougé. Un œil. Ouvert, rond, de la couleur d'un œuf au plat. Il
> regarde Chloé, puis la plume coincée dans la fissure, puis Chloé.
> **Chloé** — (Il a ouvert l'œil. Elle a dit : « quand l'un d'eux ouvre l'œil, viens me le dire ». … Je vais le dire.)

Pour les trois autres, la première bulle change ; la seconde est la même :

> *(2, pleine lune)* Le grand bloc luit comme la lune. Tout en haut, là où le cou disparaît, un œil s'est ouvert.
> Il ne regarde pas Chloé : il est trop haut. Il regarde la lune.
> *(1, crépuscule)* Le bloc aux griffes. Entre deux lames, un œil. Il regarde les griffes, puis Chloé, puis les
> griffes. Il a l'air de s'excuser.
> *(3, nuit)* Le bloc qui ronfle ne ronfle plus. Tout en bas, entre deux pointes, un petit œil s'est ouvert. Il ne
> voit pas Chloé : elle est du côté de la queue. Elle fait le tour.

Drapeau `geant_<n>_oeil`. ▶ **Le joueur** retourne au Cabinet (à pied, Grand Voyageur ou barque) et parle à Hélène.

### G2 — Hélène conseille (`cabinet`, `helene_cabinet`, dès `geant_<n>_oeil` sans `geant_<n>_conseil`)

**Le petit (bloc 4, Deinocheirus) : 8 bulles**

> **Chloé** — Le petit bloc. Celui avec ta plume. Il a ouvert un œil.
> **Hélène** — Un seul ? … C'est lui. Il fait toujours les choses à moitié, et c'est pour ça que je l'avais marqué :
> on commence par lui.
> **Hélène** — Un Deinocheirus. Des bras longs comme la barque de Maïa, un bec de canard, pas une dent. Il pêchait.
> Il n'a jamais fait de mal à personne, et il ne le sait pas : il a peur de ses propres mains.
> **Chloé** — Qu'est-ce que je fais ?
> **Hélène** — Rien. C'est le plus dur. Tu t'assois à côté du bloc, et tu attends qu'il n'ait plus peur. Page 40.
> **Chloé** — Toute seule ?
> **Hélène** — Avec un pêcheur. Un de tes dinos qui nage. Qu'il voie que des pattes, ça sert à nager, pas qu'à
> attraper. Il comprendra avant toi.
> **Hélène** — Et ne le réveille pas de force. Je l'ai fait une fois dans ma vie. Tu as vu ce que ça a donné.

**Le grand (bloc 2, Argentinosaurus) : 7 bulles**

> **Chloé** — Le grand bloc, celui où le cou fait deux fois le tour. Il a ouvert un œil. À la pleine lune.
> **Hélène** — Forcément. L'ambre luit, il a cru que c'était le matin. Un Argentinosaurus. Le plus grand animal qui
> ait jamais marché : trente-cinq mètres. Sa tête ne t'a jamais vue, elle est trop haut.
> **Chloé** — Alors comment il saura que je suis là ?
> **Hélène** — Par ses pieds. Un sauropode écoute par terre. Assieds-toi contre le bloc avec un herbivore, n'importe
> lequel : un qui mâche. Il entendra mâcher, et il saura qu'il n'y a pas de dents pour lui ici.
> **Chloé** — Il mange quoi, un géant comme ça ?
> **Hélène** — Une forêt par jour. Le cratère n'en a pas… mais il y a des fougères qui poussent sur les veines
> d'ambre, en bas. Tu ne les as pas vues ? Tu les verras : il te les montrera.
> **Hélène** — Il prendra son temps. Les grands herbivores en prennent toujours. Ne compte pas.

**Les griffes (bloc 1, Therizinosaurus) : 7 bulles**

> **Chloé** — Le bloc aux griffes. Il a ouvert un œil au coucher du soleil.
> **Hélène** — Lui, il fait tout à l'envers : il dort le jour. Un Therizinosaurus. Des griffes d'un mètre, les plus
> longues qu'on ait jamais trouvées, et pas une faite pour mordre : il s'en servait pour tirer les branches. Un
> herbivore avec des sabres.
> **Chloé** — Il a peur de ses griffes, lui aussi ?
> **Hélène** — Non. Il a peur qu'on ait peur de lui. Tout le monde a peur de lui, depuis toujours. Moi aussi, le
> premier jour.
> **Hélène** — Assieds-toi avec un dino qui a des griffes et qui s'en sert pour autre chose que faire mal. Un qui
> tranche les lianes. Qu'il voie des griffes au repos.
> **Chloé** — Et s'il bouge les siennes ?
> **Hélène** — Il les bougera. Pour tirer une branche. Ne recule pas. … Recule un peu. Un mètre. Elles font un mètre.

**Le ronfleur (bloc 3, Dacentrurus) : 8 bulles**

> **Chloé** — Le bloc qui ronfle. Il a ouvert un œil, cette nuit. Un tout petit. Et il a arrêté de ronfler.
> **Hélène** — Un petit œil, une petite tête : c'est lui. Un Dacentrurus. Un stégosaure, mais vieux comme le
> monde, le premier qu'on ait jamais trouvé. Deux rangées de pointes sur le dos, quatre au bout de la queue, et
> une tête grosse comme ta sacoche.
> **Chloé** — Il ronflait depuis vingt-cinq ans ?
> **Hélène** — Il dort profond. C'est sa façon d'avoir peur : il ferme tout, et sa queue veille à sa place. Elle
> frappe toute seule ce qui arrive derrière. Lui ne le sait même pas.
> **Chloé** — Alors je m'assois devant.
> **Hélène** — Devant, oui : là où sa petite tête te voit. Et avec un dino qui chante. On ne réveille pas un
> ronfleur en criant : on chante. Il se réveille en croyant qu'il a rêvé, et il n'a pas peur.
> **Chloé** — Et la queue ?
> **Hélène** — Elle écoutera aussi. Les queues écoutent, chez eux. … Vas-y la nuit, quand il ronfle le plus fort :
> c'est là qu'il est le plus loin de sa queue.

Drapeau `geant_<n>_conseil`. ▶ **Le joueur** met le bon dino en tête (Nage / herbivore / Tranche / Résonance) et
retourne au bloc, à son heure.

### G3 — S'asseoir à côté (`terre_apex`, action sur `BlocGeant<n>` quand `geant_<n>_conseil`)

*Sans conseil (l'œil est ouvert, Hélène n'a pas été vue) : une bulle, rien d'autre :*

> **Chloé** — (Elle a dit de venir lui dire. Je vais lui dire d'abord. Elle le saurait, de toute façon.)

*Mauvais dino en tête (une bulle, on ressort) :*

> **Chloé** — (Hélène a dit : un pêcheur / un herbivore / des griffes / un dino qui chante. %s ne l'est pas. Ce
> n'est pas lui qu'il faut, pas aujourd'hui.)

*Pas son heure (l'œil est ouvert, mais Hélène a dit « la nuit », etc.) : « (Il ferme l'œil. Ce n'est pas son
heure. Je reviens.) »*

*Le bon dino, à l'heure : **temps regardé, environ 25 s, sans texte.** Chloé s'assoit dos au bloc (pose
`assis`), %s se couche contre elle (`CS.crouch`). Les veines d'ambre pulsent de plus en plus lentement, au rythme
d'une respiration. L'œil, dans l'ambre, regarde le dino, pas Chloé. Au bout de dix secondes, un craquement
(`ambre-craque.ogg`) ; l'ambre se fend en étoile, puis « comme une noix », et tombe en morceaux dorés. Ce qui
sort dépend du géant (ci-dessous). Musique : aucune ; un souffle grave et lent (`geant-baillement.ogg`).*

**Le petit (Deinocheirus) : 5 bulles**

> *Un bras immense sort du bloc et se pose à plat sur la roche, doucement, à côté de Chloé. Puis l'autre. Puis le
> géant se lève, et sa tête sort de l'écran.* Il est debout. Il est petit, pour un géant, et il est quand même
> trop grand pour l'écran. Ses deux bras pendent, et il ne sait pas où les mettre.
> Il regarde %s. Longtemps. Puis il pose un doigt, un seul, sur le sol, à côté de lui. Il ne gronde pas. Il n'a plus
> peur.
> **Chloé** — (On s'assoit à côté. C'est tout. C'est ce qu'elle a mis trente ans à apprendre, et moi une page.)
> *(%s se lève, s'étire, et vient se frotter à la jambe de Chloé. « +♥ ».)* La plume d'Hélène est tombée de la
> fissure. Chloé la ramasse.
> **Chloé** — Un. Il en reste trois. Et une plume à rendre.

Objet `plume_helene`. Drapeaux `geant_4_reveille`, `geant_4_lien`.

**Le grand (Argentinosaurus) : 5 bulles**

> *Le bloc se fend d'en bas, parce que c'est de là qu'il écoute. Une patte sort, grosse comme le Cabinet, et se pose
> sans bruit. Puis le cou monte, monte, et sort de l'écran avant la tête.* Tout en haut, quelque part, on entend
> mâcher.
> %s arrête de mâcher. Là-haut, le géant aussi. Puis ils reprennent, tous les deux, en même temps.
> *Le cou redescend lentement, et une tête pas plus grosse que Caillou arrive au niveau de Chloé, une fougère
> d'ambre dans le bec.* Il la pose devant %s. Il en a une autre pour lui.
> **Chloé** — (Je ne verrai presque jamais sa tête. Ça ne fait rien. Il sait que je suis là : il l'a entendu par
> les pieds.)
> *(« +♥ ».)* Deux. Il faut lever la tête pour les compter, maintenant.

**Les griffes (Therizinosaurus) : 5 bulles**

> *L'ambre se fend le long des griffes, comme si elles l'avaient coupé de l'intérieur. Trois lames sortent, puis la
> main, puis le géant, et les lames se replient contre son ventre, comme on range des ciseaux.*
> Il regarde %s. %s regarde les griffes. Personne ne bouge.
> *Puis le géant tend un bras, très lentement, attrape une fougère d'ambre sur la paroi, et la tire jusqu'à Chloé.
> Il la pose devant elle. Chloé a reculé d'un mètre. Pas plus.*
> **Chloé** — (Des sabres pour cueillir des fougères. Elle avait raison : on a tous eu peur pour rien. Même elle.)
> *(« +♥ ».)* Trois. Le cratère commence à être habité.

**Le ronfleur (Dacentrurus) : 5 bulles**

*(Ici, pas de craquement d'abord : Chloé est assise devant, %s chante (émote de Résonance), et le ronflement dans
l'ambre ralentit, puis s'arrête.)*

> *L'ambre craque le long des pointes, de la tête à la queue. La queue sort la première, et ses quatre pointes
> s'abaissent lentement jusqu'au sol, dans la cendre. Puis le dos, deux rangées qui se déplient comme une crête.
> Puis la tête, petite, basse, qui cherche d'où vient le chant.* Elle trouve %s.
> Il bâille. Un bâillement de stégosaure : pas très grand, très long. Il a l'air de se demander s'il a rêvé.
> *%s chante encore une note. Le géant pose sa tête au sol, à côté de lui. Sa queue reste là où elle est : par
> terre, les pointes dans la cendre.*
> **Chloé** — (Il s'est réveillé en croyant qu'il rêvait. Elle avait raison. … Et il ne ronfle plus.)
> *(« +♥ ».)* Quatre. Il n'y a plus personne dans l'ambre.

Après chaque réveil : `Game.mark_seen(<id>)` (« Nouveau dans le Dinodex »), XP d'équipe, le bloc devient
`bloc_geant_<n>_vide`, le géant est un DinoNpc résident qui marche lentement autour de son bloc (jamais couché :
règle des dinos debout). ▶ **Le joueur** retourne voir Hélène (G4), ou pas tout de suite : le géant suivant
ouvrira l'œil quand même, à son heure.

### G4 — Hélène après (`cabinet`, une fois par géant, avant son pool)

**Le petit : 4 bulles**

> **Chloé** — Il est debout. Il a posé un doigt à côté de %s. … Et j'ai ta plume.
> **Hélène** — Garde-la. Il reste des pages blanches dans ce journal, et ce n'est plus moi qui les écris.
> **Hélène** — Anselme l'a appelé Moufle. À cause des mains. Je n'ai rien dit : Moufle, c'est très bien.
> **Hélène** — Le suivant ouvrira l'œil à son heure. Pas à la tienne. Va voir ailleurs, et reviens me le dire.

Drapeau `plume_rendue` (l'objet `plume_helene` reste à Chloé : « Garde-la »).

**Le grand : 2 bulles**

> **Chloé** — Il m'a donné une fougère. Enfin, à %s. Par le bec. Sa tête est descendue jusqu'à nous.
> **Hélène** — Alors tu l'as vue. Anselme, non : il n'a vu que les pattes, et il a décidé que le reste était un
> nuage. Il l'a appelé Nuage. Il a raison, en un sens.

**Les griffes : 2 bulles**

> **Chloé** — Il a cueilli une fougère avec ses griffes. Pour moi. J'ai reculé d'un mètre.
> **Hélène** — Un mètre, c'est bien. Anselme l'a appelé Râteau, et il m'a demandé si c'était méchant. Un râteau ne
> fait de mal à personne, sauf quand on marche dessus.

**Le ronfleur : 2 bulles, puis G5**

> **Chloé** — %s a chanté. Il a bâillé, et il a posé sa tête à côté de lui. Sa queue n'a pas bougé.
> **Hélène** — Les queues écoutent. Anselme l'a appelé Ronfleur ; il n'a pas voulu m'écouter. Il ronfle encore ?
> … Non ? Alors Anselme a tort, et on le garde quand même.

### G5 — Quatre (`cabinet`, dès les quatre `geant_<n>_reveille`, à la suite de G4) : 6 bulles

> **Hélène** — Quatre. Il n'y a plus personne dans l'ambre, en bas.
> **Chloé** — Si. Lui.
> **Hélène** — Lui, il n'a jamais dormi. On ne le réveille pas : on le laisse regarder la mer. … Trente ans de mon
> travail. Tu as mis combien de temps ?
> **Chloé** — Je n'ai pas compté.
> **Hélène** — Elle ne compte pas. C'est agaçant. Comme moi. Va voir Anselme : il compte les espèces, et il a une
> récompense qu'il n'arrive pas à cacher. Il n'y arrive jamais.
> **Chloé** — (Quatre géants debout, un Souverain couché, et des fougères d'ambre sur les veines. Plus personne ne
> dort dans le cratère.)

Drapeau `geants_reveilles` ; la région `apex` est complète (Roc : récompense existante, `DexDB.pending_rewards`).
Hélène ajoute à son pool : « Les quatre font du bruit la nuit. Le Souverain n'a pas l'air de les entendre. Il a
l'air content. »

### Examens dans le cratère (après réveil ; une ligne chacun)

> **Moufle** — Moufle pêche dans une flaque d'ambre où il n'y a pas de poisson. Il pêche quand même. Il a l'air
> content.
> **Nuage** — On ne voit que les pattes, et une fougère qui tombe de temps en temps de là-haut. Il mange.
> **Râteau** — Râteau range ses griffes contre son ventre, comme des ciseaux. Il les sort pour une fougère, et il
> les range.
> **Ronfleur** — Ronfleur broute les fougères d'ambre, la tête au ras du sol, les pointes vers le ciel. Il ne ronfle
> plus : il chantonne, un peu faux. Quelqu'un lui a appris.
> **Le Souverain** (dès `geants_reveilles`) — Il regarde la mer. Derrière lui, quatre géants font du bruit. Il n'a
> pas l'air de les entendre. Il a l'air content.

Props : `fougere_ambre.png` (une fougère dorée, posée par le code sur quelques veines d'ambre dès `post_game` :
détail vivant).

---

## F — Les fossiles légendaires

### F1 — Le carnet des os (`desert`, Tante Sirocco, dès `post_game` et `fossiles_rendus`) : 9 bulles

*(Si `fossiles_rendus` n'est pas posé : sa demande du ch. 4 d'abord, inchangée.)*

> **Sirocco** — Chloé ! On me dit « gardienne ». On me dit « Réserve ». On me dit que la petite Varenne a réveillé
> le gros du cratère. Et personne ne me dit rien sur les os !
> **Chloé** — Quels os ?
> **Sirocco** — *(Elle tape la natte.)* Ceux-là. Hélène et moi, on a passé vingt ans à les chercher, par morceaux.
> Trois bêtes de l'île d'avant l'ambre. Jamais une entière. Elle disait : « ceux-là dorment pour de bon ». Et puis
> elle ajoutait : « pour l'instant ».
> **Chloé** — Page 17. Je l'ai.
> **Sirocco** — Alors tu as la moitié. L'autre moitié, c'est mon carnet. *(Trois feuilles pliées.)* Cinq os par
> bête : la tête, le dos, les côtes, les pattes, la queue. Où ils sont, à ma façon. Mes genoux ne creusent plus.
> Les tiens, si.
> **Chloé** — Et une fois que j'ai les cinq ?
> **Sirocco** — Tu les portes à Hélène. Elle a une couveuse et une idée. Elle a toujours une idée, c'est reposant
> pour les autres.
> **Sirocco** — Deux feuilles pour la terre. La troisième est vide : la mer, je n'y mets pas les pieds. Demande à
> quelqu'un qui y met sa barque.
> **Chloé** — (Isaure. « Tarif unique : rien. » On verra ce que coûte une feuille.)

Objet `carnet_os` ; drapeaux `carnet_os`, `carnet_terre`. Les deux pages de la terre s'ouvrent (`letter`, « — S. »)
et vont au mur du journal, section « Carnet des os ».

**Page « Le doré »** (Titanosaure d'Or, `os_titanosaure_1..5`) :

> La tête : dans le noir, dans une paroi, tout en bas de l'île, sans une goutte d'ambre autour. Hélène l'a vue la
> dernière. *(Terre des Apex, près du bloc 3 : StoryProp examiné)*
> Le dos : mon cimetière, à côté de la vertèbre où Hélène s'est assise pour écrire. Une plus petite. Dorée. Gérard
> la surveille. *(Désert, Cimetière des Géants)*
> Les côtes : au pied des falaises de la Prairie, côté levant. Le vent a mis vingt ans à les découvrir, et une nuit
> à les recouvrir. *(Plaines, falaises est)*
> Les pattes : dans la glace du glacier, entre deux blocs bleus. Elle y a mis ses mains brûlées ; lui y a laissé ses
> pieds. *(Monts, glacier : la page 29)*
> La queue : sous la cendre des champs, au pied du volcan. La cendre garde tout : les bottes, les os, les secrets.
> *(Champs de cendres)*

**Page « Le plumeux »** (Gigantoraptor, `os_gigantoraptor_1..5`) :

> La tête : au fond de la grotte qui répète tout. Elle a entendu son nom mille fois. *(Grotte des Échos)*
> Le dos : sous les grands arbres de la Forêt, là où Hélène écrivait sur Anselme. Il y a des racines dessus.
> *(Forêt, haute futaie : la page 8)*
> Les côtes : là-haut, aux Pitons, au pied d'un poteau de pont. Le vent les a nettoyées. *(Cieux)*
> Les pattes : dans la vallée de la tricoteuse, près de son abri. Elle croit que c'est un banc. *(Monts, vallée)*
> La queue : dans le ravin du vieux raptor gris. Il dort dessus. Demande-lui gentiment. *(Forêt, ravin de
> Griffe-Grise)*

**Page de la mer** (Kronosaurus, `os_kronosaurus_1..5` ; donnée par Isaure en R3) :

> La tête : au fond du récif, là où Minuit écoute. Posée sur le sable, grande comme ma barque. On n'y va qu'en
> nageant. *(Récif du Sanctuaire : StoryProp examiné à la nage, sur le dos du dino)*
> Le dos : la plage, la cale des anciens, dans le sable de la troisième marche. *(Côte)*
> Les côtes : la cache des grottes marines, sous « H. + I. ». Je le savais. Je n'ai jamais creusé. *(Grottes
> marines)*
> Les pattes : il n'en avait pas, des nageoires. Les chenaux du Marais, un banc de vase. *(Marais)*
> La queue : sous le ponton du Havre, dans la grève. Les enfants jouent dessus depuis vingt ans. *(Havre-Doré)*

▶ **Le joueur** cherche les os avec un dino au Flair ; la page de la mer demande d'abord de gagner le pari (R3).

### F2 — Un os (×15) : toast + 1 bulle au premier os de chaque squelette

Toast : « Un os du Titanosaure d'Or ! Il en reste 4. » (le compte : `5 - item_count`).

> *(Titanosaure, premier os)* **Chloé** — (Un os doré. Léger, comme s'il attendait qu'on le porte.)
> *(Kronosaurus)* **Chloé** — (Un os bleu de sel, et plus lourd que moi. %s le porte. Il a l'air fier.)
> *(Gigantoraptor)* **Chloé** — (Un os creux, comme un os d'oiseau. Il tient dans la main. Il vient d'une bête de
> huit mètres.)

Les deux crânes examinés : « Dans la paroi, un crâne doré, sans une goutte d'ambre autour. Il sort tout seul :
il n'attendait que ça. » / *(sous l'eau, à la nage)* « Sur le sable, un crâne grand comme une barque. %s le
pousse du museau jusqu'à la surface. »

### F3 — Hélène, un premier os (`cabinet`, une fois par squelette, avant son pool) : 1 bulle chacune

> *(Titanosaure)* **Hélène** — Un os doré ? … Celui-là, Sirocco et moi, on l'a cherché vingt ans. Tu as trouvé une
> côte. Ce n'est pas rien, une côte : ça dit où est le reste.
> *(Kronosaurus)* **Hélène** — Du Kronosaurus ? Alors tu as battu Isaure à son pari. Elle ne l'a pas dit. Elle ne dit
> jamais quand elle perd ; elle le fait, c'est tout.
> *(Gigantoraptor)* **Hélène** — Le plumeux. Sirocco l'appelle comme ça parce qu'elle ne sait pas dire
> « Gigantoraptor ». Moi non plus, le matin.

### F4 — La résurrection (`cabinet`, Hélène, 5/5 os, 20 larmes, `Game.egg` vide) : 9 bulles + regardé

*Refus (une bulle, selon ce qui manque) :* « Il en manque un. Je sais lequel : ça se voit, une bête sans
queue. » / « Vingt larmes d'ambre. Tu en as %d. La Prairie en a encore, et les autres aussi. » / « Un à la fois.
Celui que tu portes d'abord. Tu n'as que deux mains, et il en faut une pour le sac. »

> *Chloé pose les cinq os sur la table, dans l'ordre : la tête, le dos, les côtes, les pattes, la queue.* Ça fait
> une bête, à plat.
> **Hélène** — … Vingt ans. Sirocco va être insupportable.
> **Hélène** — Donne-moi tes larmes d'ambre. Vingt. Un os, ce n'est pas un fragment : il n'y a plus personne dedans.
> Il faut lui prêter de quoi recommencer.
> **Chloé** — Et ça marche ?
> **Hélène** — Je n'en sais rien. Je ne l'ai jamais fait. C'est bien pour ça que je ne l'ai pas fait sans toi.
> *Sans texte : Roc porte les os dans la couveuse, un par un ; Hélène verse les larmes dessus. La couveuse
> s'illumine (`glass.wav`, `Stage.flash`). Les os fondent dans l'ambre comme du sucre dans le thé. Quand la lumière
> baisse, il reste un œuf : doré (Titanosaure) / bleu de sel (Kronosaurus) / tacheté comme une plume
> (Gigantoraptor).*
> **Hélène** — Un œuf. *(Elle s'assoit. Elle ne s'était pas rendu compte qu'elle était debout.)* Anselme, tu as vu ?
> … Il fait du thé. Évidemment.
> **Hélène** — Garde-le contre toi. Marche, parle-lui. Et pas d'autre œuf tant que celui-là n'a pas éclos.
> **Chloé** — (Un œuf d'une bête que plus personne n'a vue. … Elle a dit « je n'en sais rien ». Elle a dit « sans
> toi ». C'est la première fois pour les deux.)

`Game.egg = {species, name, steps}` (noms proposés : Doré, Cronos, Plume ; renommables à l'éclosion) ; 20 larmes
consommées ; les os restent dans le sac (le Dinodex les montre : « squelette complet ») ; drapeau
`ressuscite_<id>`. ▶ **Le joueur** marche : l'éclosion est la mécanique existante ; le nouveau-né arrive à
**niveau 45**.

### F5 — Après l'éclosion (`cabinet`, Hélène, une fois par espèce) : 1 bulle

> *(Titanosaure d'Or)* **Hélène** — Il a des pièces d'or cousues dans la peau. Ne le dis pas à Ferréol.
> *(Kronosaurus)* **Hélène** — Quatre nageoires et une tête d'un quart de lui. Il ne marchera jamais : ne lui
> demande pas. Nage dessus.
> *(Gigantoraptor)* **Hélène** — Des plumes, un bec, et huit mètres. Oviraptor va être jaloux. Il a le droit.

---

## R — Les revanches

### R1 — Le défi n° 6 de Maïa (`plaines`, Grand Crâne, après sa réplique ; le choix existe déjà)

*Avant (3 bulles) :*

> **Maïa** — Niveau cinquante, tous les quatre. Caillou, cinquante et un : il a triché, il a mangé pendant que je
> dormais.
> **Maïa** — Pas pour gagner. Pour voir. … Bon. Un peu pour gagner.
> **Chloé** — (Six. Elle a toujours l'œuf fort contre le mien, et elle a toujours perdu de peu. « De peu », c'est
> ce qui l'énerve.)

Équipe (`ApexBattles.maia_team`) : son œuf 50 (`maia_starter`), Pouce (Iguanodon) 50, Moustique (Dimorphodon) 49,
Caillou (Tricératops) 51 ; `MAIA_RULES` : `trainer` Maïa, `lose_spawn` le Crâne, musique `rivale.ogg`.

*Gagné (3 bulles) :*

> **Maïa** — … De peu. ENCORE de peu. Tu fais exprès ?
> **Chloé** — Non.
> **Maïa** — C'est pire. Demain, même heure. Je vais écrire sur le tableau du Relais : « Chloé V., rang Argent,
> pour l'instant ». Je garde « pour l'instant ».

*Perdu (2 bulles) :*

> **Maïa** — J'AI GAGNÉ. Caillou ! On a gagné ! … Ne le dis pas à maman. Elle dirait « enfin ».
> **Chloé** — (Elle le dira elle-même avant ce soir.)

Récompense : XP seulement (ce n'est pas le Relais) ; `maia_defi_6` à la première victoire ; au Relais, la ligne
à la craie devient « Chloé V., rang Argent, pour l'instant (Maïa) ». ▶ **Le joueur** revient demain, ou pas.

### R2 — Les Alphas, « pour voir » (chez chacun, dès `post_game` ; une fois par jour)

*Commun (2 bulles, puis CHOIX) :*

> *(la ligne d'arrivée de l'Alpha, ci-dessous)*
> **Chloé** — (Il a vu l'insigne. Hélène a dit : « ce n'est pas un cadeau, c'est du travail ». … Il veut voir si
> c'est vrai.)

**CHOIX** — « L'Alpha attend. » : « Pour voir. » / « Pas aujourd'hui. » *(déjà fait aujourd'hui : « Il a vu. Il se
recouche. Demain. », une bulle.)*

Règles : un seul dino, niveau 50-53, pas corrompu, ni capture ni fuite, musique des Alphas (`alpha.ogg`),
`lose_spawn` l'entrée du lieu, moteur sous l'eau pour le Spinosaure et Minuit, neige pour Toupet, fond volcan pour
Cheminée. Texte de fin : jamais « K.O. » : **« Il s'arrête. Il a vu. »**

*Gagné, la première fois (2 bulles + toast) :*

> *(sa ligne d'après, ci-dessous)*
> **Chloé** — (Le Sceau est chaud dans la sacoche. … Il a dit oui. À sa façon.)

Toast : « Le Sceau de la Prairie s'éveille : l'Alpha répond à ton appel, une fois par jour, dans tous les
combats. » Pièces (60 à 90) à chaque victoire. *Perdu :* « Il s'arrête aussi. Il a vu autre chose. Il attendra
demain. »

| Alpha (lieu, niv.) | Ligne d'arrivée | Ligne d'après |
|---|---|---|
| Le Tricératops (l'antre du Grand Crâne, 50) | Le Tricératops Alpha baisse ses cornes jusqu'au sol, comme on salue. Puis il regarde l'insigne. | Il souffle par les naseaux, deux fois, et retourne au Crâne. De loin, Caillou souffle aussi : il copie. |
| L'Utahraptor, Chef de Meute (Forêt, la clairière, 50) | Le Chef de Meute siffle. Trois raptors sortent des fougères, s'assoient, et regardent : eux ne joueront pas. Lui, si. | Il incline la tête. Les trois autres aussi. Toute la meute, en même temps. |
| Le Spinosaure Ancestral (Temple englouti, 51, sous l'eau) | Le Spinosaure déploie sa voile, lentement, comme on ouvre un livre. | Il replie la voile. Il apporte de l'eau dans sa gueule et la verse sur les pattes de %s, sans en perdre une goutte. |
| Piment, le Carnotaurus Rouge (Sanctuaire des Vents, 51) | Piment rugit. Pas contre Chloé : pour dire qu'il est là. Le vrai rugissement. | Il se gratte le museau contre la porte du sanctuaire, et grogne doucement : c'est son « à demain ». |
| Minuit, le Mosasaure Abyssal (Récif, 52, sous l'eau) | Minuit monte des profondeurs, les yeux presque fermés. Il écoute. Il entend le cœur de %s battre vite. | Il écoute encore. Le cœur bat moins vite. Il redescend dans le noir, satisfait. |
| Toupet, le Cryolophosaure Titan (Sanctuaire de Givre, 52) | Toupet descend de sa paroi de glace. Sa crête a du givre dessus. Il attend que Chloé ait fini de la regarder. | Il souffle sur l'autel. Le givre s'y pose, puis fond : un oui, en givre. |
| Cheminée, le T-Rex de Magma (Sanctuaire de Magma, 53) | Cheminée sort de la faille, et fume. Il regarde le chapeau de Chloé. Chloé n'a pas de chapeau. Il a l'air déçu. | Il se couche à côté de %s. Il fume. Le sol tremble un peu. C'est sa façon d'être d'accord. |

Le Roi des Cieux : rien (il ne se pose jamais pour combattre ; en option, une course en vol : hors de ce texte).
Le Souverain : rien, jamais.

**Les deux effets nouveaux** (commande « Sceaux », `ApexEngine`) : la Prairie, **Charge de l'Alpha** (« Le
Tricératops passe en trombe : le prochain coup de %s compte double. ») ; la Forêt, **La meute** (« Le Chef de
Meute siffle : %s agit deux fois ce tour. »). Les cinq autres : effets existants. Jamais contre l'Alpha
lui-même (« Il ne viendra pas contre lui-même. »), jamais au Relais.

### R3 — Le pari d'Isaure (`port_ambre`, sa barque, après sa réplique ; une fois par jour)

> **Isaure** — Un pari, moussaillon ? Les miens s'ennuient : Hauban pêche, les trois autres regardent la mer.
> Carène a arrêté d'hésiter. Je l'ai prévenue.
> **Isaure** — Si je gagne, tu laves la barque. Si tu gagnes… tu verras. Je ne dis pas mes paris avant.

**CHOIX** — « Un pari de marin. » : « Je parie. » / « Pas aujourd'hui. » *(déjà fait : « Un pari par jour. Les
marins aussi dorment. »)*

Équipe : Hauban (Pteranodon) 50, Bouline (Baryonyx) 50, Étrave (Suchomimus) 51, Carène (Archelon) 52, **sans**
`hesitates` ; pas de musique (le vent, la mer) ; `lose_spawn` le quai.

*Gagné, la première fois (4 bulles) :*

> **Isaure** — Perdu. *(Elle ne sourit pas. Puis si.)* Tiens. Sirocco t'a donné la terre : je le sais, elle me l'a
> crié depuis sa tente, elle crie toujours. La mer, c'est moi.
> Une feuille pliée. L'écriture penche à gauche : une écriture de marin. Cinq os, cinq endroits.
> **Isaure** — Le dernier, sous le ponton du Havre, je le sais depuis vingt ans. Les enfants jouaient dessus. Je n'ai
> jamais creusé : ce n'était pas à moi.
> **Chloé** — (« Ce n'était pas à moi. » Elle a mis vingt ans à le dire d'un os. Elle le dit.)

Drapeaux `isaure_pari_gagne`, `carnet_mer` ; la page de la mer au carnet. *Gagné ensuite (1 bulle) :* « Encore
perdu. Je garde une pièce sur deux pour la barque. Tiens, l'autre moitié. » (100 pièces.) *Perdu (1 bulle, puis
regardé) :* « Gagné. La barque. Avec l'eau de mer, pas celle du puits : Carène n'aime pas l'eau douce. » *(Chloé
frotte le pont, trois secondes ; Carène regarde.)* « Demain, moussaillon. »

### R4 — Hélène, les Sceaux (`cabinet`, dès le premier `sceau_*_eveille`, une fois) : 1 bulle

> **Hélène** — Un Sceau s'est réveillé ? Alors ils t'ont reconnue. Appelle-les quand tu veux : une fois par jour.
> Ils ont une région à garder, et toi, tu as le reste.

---

## N — Nouvelle partie+

### N1 — L'écran des emplacements (`ui/save_slots.gd`, sur un emplacement fini)

Bouton **« Nouvelle partie+ »** (clavier, manette, souris). Sous-titre : « Recommencer l'île avec un autre œuf. Le
Dinodex, les os et les pages déjà lues restent. Les adversaires sont un peu plus forts. » Puis le choix de
l'emplacement : « Recommencer dans l'emplacement 2 ? La partie finie de l'emplacement 1 n'est pas touchée. »
(« Écraser » : la confirmation existante.) ▶ **Le joueur** rejoue le prologue.

### N2 — Le prologue, l'œuf (la couveuse)

L'œuf déjà joué porte « Celui-là, tu le connais. » (gris, choisissable). S'il le choisit quand même, une bulle :

> **Chloé** — (Encore lui. … Oui. Encore lui.)

Rien d'autre ne change dans le texte du prologue : personne ne sait.

### N3 — Le mur du journal

Les pages de la partie d'avant sont **grises avec une coche** (« déjà lue ») ; elles ne se relisent qu'une fois
retrouvées. Pas de texte nouveau.

---

## B — Brac sur la jetée

### B1 — Le phare qui boude (`port_ambre`, `BracJetee`, dès `brac_parti`, avant `epilogue_cabinet`, une fois) : 10 bulles

*Brac, assis au bout de la jetée, un sandwich à la main (prop `sandwich`, posé par le code). Mastoc est couché
contre lui ; Cabosse et Grognon regardent la mer. Ils regardent surtout le sandwich.*

> **Brac** — Moucheron. Tu viens voir la mer aussi ? Elle est grande. On me l'avait dit. Je ne pensais pas à ce
> point.
> **Chloé** — Roc a dit que vous aviez mangé un sandwich.
> **Brac** — Roc tient ça de Léonce. Léonce est loin. *(Il lève le sandwich. Les trois se tournent vers lui, en
> même temps.)* … J'ai levé le sandwich. Ils ont regardé. J'ai reposé le sandwich.
> **Brac** — C'est le même depuis les forges. Il est un peu dur. Je m'y suis attaché.
> **Chloé** — (Il ne mange pas parce qu'ils le regardent. Il croit que c'est le sandwich qu'ils regardent.)
> **Brac** — Tu veux les connaître ? Ils ne mordent plus. Enfin, Grognon, si, mais il mord tout : c'est pas
> contre toi.
> **Brac** — Mastoc. Allosaure. Le plus vieux chasseur de la Forêt, et il a peur du noir. *(Mastoc lève la tête.)*
> **Brac** — Cabosse, le Stygimoloch. Il fonce avec sa tête : c'est pour ça qu'elle est bosselée. *(Cabosse baisse
> la tête, prêt.)* Non. Pas maintenant.
> **Brac** — Grognon, le Majungasaurus. Une petite corne sur le front, et pas un ami au monde. À part moi.
> *(Grognon grogne.)*
> **Brac** — Et moi, je regarde la mer. De loin. … Et j'attends que quelqu'un me demande quelque chose. Personne ne
> demande jamais rien à Brac. Ça viendra peut-être.

Drapeau `brac_jetee_vu`. Ensuite, une réplique par visite (pool `brac_jetee_avant_n`) :

> « Elle est toujours grande. Je vérifie tous les matins. »
> « Léonce m'a prêté une ligne. Je ne sais pas pêcher. Un Ptéranodon avec du sel sur le bec, lui, il sait. Il m'a
> regardé comme on regarde un sandwich. »
> « Quand tu auras fini là-bas, moucheron… reviens me dire. Je ne demande rien. Je dis juste : reviens me dire. »

*(Fournaise : sa ligne existe à l'épilogue, « Il m'a jamais écrit » ; rien ici.)* ▶ **Le joueur** finit le ch. 9 ;
à la jetée de l'épilogue, Brac crie « ET MOI ? » : c'est ce qu'il attendait.

### B2 — Le partage (`port_ambre`, `brac_jetee`, après `epilogue_fini`, de jour, une fois) : 6 bulles

*Brac, gardien de nuit le jour : il dort assis. Le sandwich est sur son genou. Mastoc le regarde. Brac ouvre un
œil.*

> **Brac** — Moucheron. … Tu sais ce que madame Varenne m'a dit, hier ? « On ne garde pas un sandwich. On le partage,
> ou on le mange. » Elle a dit ça comme si c'était grave.
> **Chloé** — C'est peut-être grave.
> **Brac** — *(Il regarde le sandwich. Puis Mastoc. Puis Cabosse et Grognon, qui ne regardent pas la mer du tout.)*
> … Ils me regardent. Pas le sandwich. Moi.
> *Il coupe le sandwich en quatre avec son couteau à cordes. Trois parts pour trois gueules, une pour lui.* Ça fait
> dix secondes. Ça faisait longtemps.
> **Brac** — Il était dur. C'était le meilleur sandwich du monde. Ne le dis à personne.
> **Chloé** — (Il a fallu une Réserve, une grand-mère et un panneau mal écrit pour qu'il mange un sandwich. … Ça
> valait le coup.)

Drapeau `brac_sandwich_partage` ; le prop `sandwich` disparaît. Ensuite, ses trois répliques de gardien de nuit
(existantes). ▶ **Le joueur** revient la nuit s'il veut.

### B3 — Les bêtes et la nuit (`port_ambre`, après `epilogue_fini` ; examens, une ligne chacun)

> **Mastoc** — Mastoc dort, la tête sur la lanterne éteinte. Un Allosaure de huit mètres qui a peur du noir. Il tient
> la lanterne même le jour, au cas où.
> **Cabosse** — Cabosse regarde la mer en penchant la tête. Il a essayé de foncer dedans, une fois. Il recommencera.
> **Grognon** — Grognon grogne. C'est son nom, et c'est son travail. Il grogne un peu moins quand Brac est réveillé.
> **Le panneau** (prop `panneau_barc`, posé par le code dès `epilogue_fini`) — Un panneau planté dans la jetée,
> écrit à la main : « Gardien : BARC ». Quelqu'un a ajouté dessous, au charbon, un « R » à la bonne place, puis
> l'a effacé. Le panneau est de Roc : on ne corrige pas le vieux.

La nuit : planche `brac_gardien` (lanterne à la main, chapeau, pas de masque), Mastoc couché contre la lanterne
posée (« Je lui laisse la lanterne » : sa réplique existante). Le jour : `brac_assis_cage`, comme maintenant.

---

## Personnages, images, sons (récapitulatif pour les lots A', B', E)

| Quoi | Détail |
|---|---|
| Les quatre géants | `deinocheirus`, `argentinosaurus`, `therizinosaurus_geant`, `dacentrurus` : profil 3×2 et face/dos 4×2, cellule du Souverain ; anatomies dans `post-game-plan.md` § 1 (compte des membres : 2 pattes + 2 bras, 4 pattes, 2 + 2, 4 pattes) ; le Dacentrurus : double rangée de plaques-pointes dorsales, deux paires de pointes au bout de la queue, petite tête basse (la queue et la tête jamais confondues de face ni de dos) ; debout au repos ; jamais une recoloration |
| Sons des géants | `geant-baillement.ogg`, `geant-pas.ogg`, `geant-ronfle.ogg` (le bloc 3 la nuit, avant le réveil) |
| Les blocs | `bloc_geant_{1..4}_oeil.png` (un œil ouvert dans l'ambre), `bloc_geant_{1..4}_vide.png` (fendu, vide, éclats dorés) ; `fougere_ambre.png` |
| Les trois légendaires | `saltasaurus` (plaques dorées sur le dos, 4 pattes), `kronosaurus` (4 nageoires, tête d'un quart du corps, **cycle de nage**, Chloé en nage dessus : jamais à pied sous l'eau), `gigantoraptor` (plumes, bec, 2 pattes + 2 bras) |
| Les os | icônes `os_titanosaure`, `os_kronosaurus`, `os_gigantoraptor`, `carnet_os` ; `squelette_<id>.png` (fiche du Dinodex, cinq pièces qui s'allument) ; props `crane_titanosaure_paroi`, `crane_kronosaurus_sable` ; `plume_helene` (icône) |
| Chloé | pose assise (existante) ; en nage sur le Kronosaurus (`chloe_nage` existante si la selle marine s'y adapte) |
| Brac | `brac_gardien.png` (lanterne, chapeau, pas de masque ; 4×4 comme `brac`) ; props `sandwich.png` (petit), `panneau_barc.png` |
| Sons | `geant-baillement.ogg`, `geant-pas.ogg`, `os-trouve.ogg` ; existants : `ambre-craque.ogg`, `creuser.mp3`, `glass.wav`, `alpha.ogg`, `rivale.ogg` |
| Musiques | aucune nouvelle (géants : silence et souffle ; Alphas : `alpha.ogg` ; Maïa : `rivale.ogg` ; Isaure : le vent) |

---

## Autocritique (trois passes)

**Passe 1 — un enfant comprend-il pourquoi ce personnage dit ça, maintenant ?** Chaque scène part d'un fait que
Chloé vient de voir (un œil ouvert, un os, un insigne regardé) et la réplique suivante y répond ; Hélène ne fait
pas de discours (le plus long : « une forêt par jour »), elle donne une consigne concrète (s'asseoir, avec qui,
à quelle heure), et chaque consigne a sa raison dite (le pêcheur / les pieds qui écoutent / des griffes au repos
/ on ne réveille pas un ronfleur en criant, on chante). Sirocco explique les os par la page 17 que Chloé a déjà. Isaure ne donne la
mer qu'en perdant un pari : c'est sa façon depuis le ch. 9. Brac ne demande rien jusqu'à « ET MOI ? », qui vient
déjà dans le jeu : B1 le prépare au lieu de le contredire. Maïa veut perdre « de peu » comme à chaque défi.

**Passe 2 — continuité.** Le réveil doux est celui de `histoire.md` (« on s'assoit à côté, avec Hélène qui dit
comment, et un Lien qui monte ») et de la page 40 ; Hélène a bien « voulu réveiller » le Souverain il y a
vingt-cinq ans (« Je l'ai fait une fois ») ; Anselme nomme les bêtes (Toupet, Cheminée : Moufle, Nuage, Râteau,
Ronfleur) ; la plume « en marque-page » du bloc 4 revient et Hélène la laisse à Chloé (« des pages blanches »,
F-09) ; la vertèbre-baignoire de la page 17, « H. + I. » des grottes marines, la page 29 du glacier, l'abri de
Bertille, le ravin de Griffe-Grise, le ponton du Havre : tous des lieux joués ; « Il m'a jamais écrit »
(Fournaise) et le panneau « BARC » existent ; le sandwich répond à Roc (ch. 8) et au ch. 8 lui-même (« ils
regardent mon sandwich, mais ils me regardent » devient « Ils me regardent. Pas le sandwich. ») ; Cheminée et le
chapeau (il en a mangé deux) ; Caillou copie le Tricératops (Caillou est au Crâne avec Maïa) ; le Roi ne combat
pas ; le Souverain n'est jamais « battu ». Rien de nouveau n'est dit sur le passé des personnages.

**Passe 3 — rythme et règles.** Aucun bloc ne dépasse 10 bulles ; entre deux blocs : un trajet, une heure à
attendre, un choix, un combat, un creusage, un temps regardé (le réveil, la couveuse, la barque lavée). Mots
courants (« crique » n'apparaît pas, « anse » non plus) ; le dino en tête nommé par `%s` ; sous l'eau, Chloé
nage sur son dino (le crâne du Kronosaurus « poussé du museau jusqu'à la surface », pas de creusage sous l'eau).
Faiblesses connues : les devinettes du carnet supposent que le joueur connaît les lieux (c'est le post-game :
oui) ; « Son heure » demande d'attendre l'horloge (le Grand Voyageur fait passer 1 h 30, c'est voulu) ; les deux
effets de Sceaux nouveaux (Charge, Meute) sont à équilibrer avec les cinq existants ; la planche du squelette dans
la fiche du Dinodex est de l'interface nouvelle (petite).
