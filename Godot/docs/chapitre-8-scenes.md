# Chapitre 8 — La Plaine Volcanique : les scènes (texte complet)

> Écrit le 17/10/2026 par l'agent HISTOIRE (Fable), d'après `chapitre-8-plan.md` (décisions de Greg du
> 17/10), `histoire.md` § Ch. 7 et 8, `lore.md`, `bestiaire.md`, `mecaniques.md`. Le déroulé résumé
> est dans `histoire.md` § Chapitre 8 ; ici, le **texte** de chaque scène, avec ses didascalies (en
> italique : ce que la mise en scène montre, à traduire en `cue` / `Stage.*` comme dans
> `story/cieux_arche.gd`), les dialogues des PNJ par lieu et par état, les pensées de Chloé (entre
> parenthèses, `who: Chloé`), les pages 35 à 38, les textes d'examen, et pour chaque scène ses
> drapeaux, objets, événements, personnages et images. Rien de tout cela n'est codé : ce document est
> le contrat de l'agent qui écrira `story/volcan*.gd` et `data/dialogue_volcan.gd`.
>
> Ton : chaleureux et drôle, jamais effrayant ni cruel. Le chapitre 7 était le plus grave ; le 8 est
> **le plus chaud** : il commence seul dans la cendre et finit à trois devant une porte, à la lueur de
> deux torches. Brac fait rire (et une fois, pas tout à fait) ; Dame Suie ne hausse jamais le ton ; le
> T-Rex de Magma est le combat le plus dur, pas le plus effrayant ; Isaure attend.

## Conventions

- Noms des zones : `champs_cendres`, `forges_ombre`, `coulees_lave`, `sanctuaire_magma`, `porte_cratere`.
- Ordre : Descente de Cendre → champs → forges → coulées → sanctuaire → (la lave se retire) → porte.
  La porte n'est atteignable **qu'après le 5e Cœur** (le volcan gronde, la lave recule du chemin du
  cratère « comme une marée »).
- Les personnages : Chloé, Moustique (sur l'épaule, Dimorphodon niv. 36, dans l'équipe depuis le ch. 7),
  le dino de tête, Brac, Dame Suie, Léonce (un sbire), Isaure, Maïa, Caillou, le T-Rex de Magma, Roc
  (au Cabinet), Bertille (aux Monts, une réplique).
- Garde-fous du chapitre : Maïa n'est **jamais** avec Chloé avant la porte ; Isaure ne confirme pas
  qu'elle va chercher Hélène (elle « lira en bas ») ; personne ne frappe Brac ni ne se moque de lui
  quand il est amer ; Dame Suie ne demande pas pardon (elle refait ses tables) ; aucune image de dino
  qui souffre : les corrompus « grondent », « tremblent », « ont peur », c'est tout.
- Cœurs : Chloé n'en a plus (volés au ch. 7 : `coeurs_voles`). Le 5e est le seul qu'elle tiendra. Les
  drapeaux `coeur_1` à `coeur_4` restent vrais (elle les a eus).

## Carte des drapeaux, objets, événements (vue d'ensemble)

| Scène | Drapeaux posés | Objets | Événements / nœuds |
|---|---|---|---|
| Descente de Cendre | `volcan_ouvert` (posé dès que `masque_tombe` : le ch. 8 existe) | — | dialogue `volcan_bloque` → `descente_cendre` |
| Arrivée aux champs | `cendres_arrivee`, `traces_vues` | — | scène d'entrée `champs_cendres`, StoryTrigger `Traces` |
| Premier corrompu | `premier_corrompu_volcan` | — | DinoNpc corrompu `Numero3` (Styracosaurus) |
| Arrivée aux forges | `forges_arrivee`, `leonce_vu` | — | scène d'entrée `forges_ombre`, Npc `Leonce` |
| Les trois petites forges | `forge_1_eteinte`, `forge_2_eteinte`, `forge_3_eteinte`, `petites_forges_eteintes`, `barricade_tombee` | — | DinoNpc `Numero7` (Saichania), `Numero11` (Allosaurus), `Numero12` (Majungasaurus) ; StoryProp `Forge1..3`, `Barricade` |
| Brac | `brac_volcan_vu`, `brac_vaincu`, `brac_parti`, `masque_brac_vu` | — | Npc `BracVolcan`, événement `brac_volcan`, StoryProp `MasqueBrac` |
| Dame Suie | `suie_volcan_vue`, `suie_alliee`, `grande_forge_eteinte`, `antidote_ambre`, `found_journal_37` (= `page_37`), `suie_partie` | `antidote_ambre`, `lettre_isaure` | Npc `SuieVolcan`, événement `suie_volcan`, StoryProp `GrandeForge`, `Etabli` |
| Coulées | `coulees_arrivee`, `lave_franchie`, `found_journal_36` | — | scène d'entrée `coulees_lave`, StoryTrigger `PremiereCoulee`, Pickup `page_36` sur le rocher |
| Sanctuaire | `sanctuaire_magma_arrivee`, `flaque_tremble`, `trex_magma_parle`, `trex_magma_battu`, `sceau_volcan`, `coeur_5`, `found_journal_35`, `lave_retiree` | `sceau_volcan`, `coeur_5` | scène d'entrée, DinoNpc `TrexMagma`, événement `trex_magma`, StoryProp `AutelMagma` |
| Porte | `porte_arrivee`, `found_journal_38`, `isaure_porte_vue`, `marche_refuse`, `lettre_isaure_donnee`, `maia_porte_vue`, `apex_bloque` | (`lettre_isaure` quitte le sac) | scène d'entrée `porte_cratere`, Npc `IsaurePorte`, `MaiaPorte`, DinoNpc `CaillouPorte`, StoryProp `CampHelene`, `PortailApex` |
| Autour | `roc_sceau_volcan`, `roc_suie_carnets`, `carnets_rendus`, `bertille_forges_eteintes`, `joss_volcan`, et `brac_n`, `suie_volcan_n`, `leonce_n`, `isaure_porte_n`, `maia_porte_n` pour les répliques | — | Roc (`roc`), Bertille (`bertille`), Joss (`joss`) |

Objets (`data/items_db.gd`) : `antidote_ambre` « Ambre clair » (objet clé, une seule dose : versé sur un
dino corrompu, il efface les veines d'un coup ; gardé pour le dernier combat), `sceau_volcan` « Sceau du
Volcan » (ambre rouge sombre, une flamme, la fougère), `coeur_5` « Cinquième Cœur d'ambre » (icône
`coeur_ambre`), `lettre_isaure` « Lettre pour Isaure » (la page 37, pliée, pas scellée ; donnée à la
porte : elle quitte le sac, le drapeau `found_journal_37` reste).

---

## Scène 1 — La Descente de Cendre (fin de `arche_du_vent`, dialogue `descente_cendre`)

*Remplace `volcan_bloque` dès que `masque_tombe` est vrai. Chloé est au bord de la terrasse, Moustique
sur l'épaule. Le sentier gris descend en lacets dans un vent chaud qui sent le soufre.*

> La Descente de Cendre. Un sentier gris qui descend vers le volcan, en lacets, dans un vent chaud qui
> sent le soufre. À chaque lacet, la cendre est marquée de pas : deux paires de bottes, une grande, une
> petite. Et, par-dessus, trois gros orteils qui traînent.
> **Chloé** — (Caillou. Il les a rattrapées. Évidemment.)
> **Chloé** — (Pas de « c'est stylé ». Pas de Maïa qui râle parce que ça monte. … Ça descend, en plus.
> Elle aurait râlé quand même.)

*Moustique se serre contre son cou, les ailes repliées.*

> Moustique s'aplatit sur l'épaule de Chloé. En bas, ça brille rouge, et il a peur du feu.
> **Chloé** — Moi aussi, un peu. On y va quand même. Elle m'a dit de te garder, pas de te laisser.

*Transition vers `champs_cendres`.* Drapeau : `volcan_ouvert` (posé par le jeu dès `masque_tombe`,
avant la première lecture de ce dialogue).

---

## Scène 2 — L'arrivée aux Champs de Cendre (`champs_cendres`, scène d'entrée `cendres_arrivee`)

*Fondu depuis le gris. Tout est gris : le sol, le ciel, les pierres. Au loin, le cône du volcan, et
à son pied, des feux rouges alignés. Le vent soulève la cendre en petites vagues. Le dino de tête
s'arrête net : ça sent le brûlé.*

> Le vert a disparu il y a longtemps, le blanc aussi. Ici, tout est gris : la cendre monte jusqu'aux
> chevilles et se soulève à chaque pas, comme de la farine qu'on aurait laissée refroidir.
> Le volcan n'est plus « au loin ». Il est là, devant, et il fume. À son pied, des feux rouges, en
> ligne. Sept. Comme sur la page de Bertille.

*Selon le dino de tête (une réplique) :*

> *(raptor)* Vif éternue. Une fois, deux fois, et il regarde la cendre comme si elle l'avait fait exprès.
> *(cuirassé)* Bastion avance, et la cendre le recouvre peu à peu. Il devient gris. Il devient un
> rocher gris. « Je sais. Je ne m'assois pas dessus. »
> *(hadrosaure)* Écho souffle un petit « tuut » plein de cendre, et tousse. Elle réessaie. Ça fait « puff ».

> Le vent est chaud. Pas chaud comme le Désert : chaud comme la porte d'un four quand on passe devant.
> **Chloé** — (Elle est passée par là. Avec les Cœurs contre elle, sans courir. Et Maïa à côté. Pas
> derrière : à côté.)
> **Chloé** — (Il reste un Cœur. Et il est là-dessous, quelque part, à battre tout seul. Comme moi.)

*Moustique sort la tête du col de Chloé, regarde les feux, et la rentre.*

> **Chloé** — Ça va. Ils sont loin. … Bon. Ils ne sont pas si loin.

Drapeau : `cendres_arrivee`. XP d'arrivée (comme `XP_ARRIVEE` des Cieux). Images : sol `cendre`,
`roche_noire` ; fond lointain : le volcan qui fume (déjà dessiné pour l'Arche ? sinon à faire).

### 2 bis — Les traces (StoryTrigger `Traces`, au milieu des champs, non bloquant)

> Dans la cendre, les traces continuent. Elles tournent une fois autour d'une grosse pierre plate, puis
> repartent droit vers les feux. Sur la pierre, quelqu'un s'est assis : il y a deux creux, côte à côte.
> **Chloé** — (Elles se sont arrêtées ici. Pas longtemps. … Deux creux. Côte à côte.)
> Un peu plus loin, un troisième creux, énorme, et des roseaux à moitié mâchés. Caillou n'attend
> jamais, mais il mange toujours.

Drapeau : `traces_vues`. Prop examinable `PierrePlate` : « Deux creux dans la cendre, côte à côte. Et
un énorme, un peu plus loin. »

### 2 ter — Le premier corrompu (DinoNpc `Numero3`, Styracosaurus corrompu niv. 42)

*Un Styracosaurus aux veines violettes gratte la cendre au pied d'une cage ouverte, abandonnée. Il
porte au cou une plaque de fer gravée au clou : « 3 ».*

> Un Styracosaurus. Des veines violettes sous la cendre, des yeux troubles, et une plaque de fer au cou,
> gravée au clou : « 3 ».
> **Chloé** — (Pas de nom. Un numéro. … Même Brac donnait des noms.)
> *Il charge.*

*Combat : corrompu, on l'apaise (règle normale). Apaisé :*

> Les veines s'éteignent. Le Styracosaurus secoue la tête, et la plaque « 3 » tinte contre ses cornes.
> Il regarde Chloé, puis la cage ouverte, puis les feux au loin. Et il part. Pas vers les champs :
> **vers les forges**, au trot, la tête baissée.
> **Chloé** — (Il n'a pas peur. Il est en colère. … Et il sait où aller.)

Drapeau : `premier_corrompu_volcan`. Leçon de combat (dite une fois) : « Les corrompus des forges ne
rejoignent pas l'équipe : une fois apaisés, ils ont une chose à régler là-bas. » (Numéro 3 réapparaît
aux forges : voir la scène 4.)

### Panneaux et props des champs

- Panneau d'entrée : « Plaine Volcanique. Ne pas marcher sur ce qui est rouge. Ni sur ce qui est noir et
  encore chaud. En fait : regarder où on marche. — H. »
- Cage ouverte (examen) : « Une cage de l'Ombre Noire, ouverte, à moitié enterrée dans la cendre. Les
  barreaux sont tordus vers l'extérieur. Quelqu'un est sorti sans demander. »
- Fût renversé : « Un fût marqué d'un masque d'os. Vide. Il sent le brûlé et un peu la réglisse. »
- Pierre plate : voir 2 bis.

### Dialogues des champs

- `cendres_bloquees` (si l'on revient à la Descente) : « La Descente de Cendre remonte vers l'Arche. En
  haut, le masque est toujours dans l'herbe, sans doute. »
- Habitants : Styracosaurus (jour, Charge), Saichania plus loin vers les coulées (jour, Charge). Pas de
  PNJ : les champs sont vides. Une pensée au premier Saichania vu : « (Un cuirassé. De pierre, celui-là.
  Hélène a écrit qu'il ne faut pas marcher sur ce qui est rouge… sauf avec le cuir pour.) »

---

## Scène 3 — L'arrivée aux Forges (`forges_ombre`, scène d'entrée `forges_arrivee`)

*Un camp de l'Ombre Noire au pied du volcan : palissade de planches brûlées, cages (la plupart vides),
fûts d'ambre noir, enclumes, et trois petites forges qui rougissent, chacune sous son auvent. Au
fond, sur une plateforme de roche, la **grande forge** : une tour de brique noire, haute comme deux
maisons, qui crache une fumée violette. Une barricade de cages empilées ferme le passage vers elle.
Deux ou trois masques d'os traînent près des fûts, assis, sans rien faire. La musique de l'Ombre
(`OMBRE_MUSIC`), mais fatiguée, plus lente si possible.*

> Les forges. Trois petites, qui rougissent sous des auvents, et au fond, sur la roche, une grande : une
> tour noire qui crache une fumée violette. Des cages. Des fûts. Des enclumes. Et presque personne.
> Les masques d'os qui restent sont assis par terre. Ils ne font rien. L'un d'eux dort.
> **Chloé** — (Ça devrait grouiller. Ça ne grouille pas. … Ils attendent quelque chose. Ou quelqu'un
> qui ne reviendra pas.)

*Moustique crie, une fois, vers la grande forge. Une voix tonne, derrière la barricade :*

> **Brac** *(au loin)* — QUI A LAISSÉ SORTIR LE TROIS ?!
> **Chloé** — (Brac. … Lui au moins, il est là.)

Drapeau : `forges_arrivee`. Images : props `forge_allumee` / `forge_eteinte`, `grande_forge_allumee` /
`grande_forge_eteinte`, `cage`, `cage_ouverte`, `fut_ambre_noir`, `enclume`, `barricade`, `auvent`.

### 3 bis — Léonce (Npc `Leonce`, un masque d'os assis sur un fût, le masque sur le genou)

*Un vieux pêcheur, le masque d'os posé sur son genou comme un chapeau qu'on n'a plus envie de mettre.*

> **Léonce** — Tu cherches la sortie, petite ? Moi aussi. Ça fait douze ans.
> **Léonce** — Léonce. Du port. Je raccommodais les filets, avant. Puis il n'y a plus eu de poisson, et
> il y a eu ça. Il paie. Enfin, il payait.
> **Chloé** — Qui ?
> **Léonce** — Le grand rouquin, là-bas, derrière les cages. Il crie beaucoup pour un homme qu'on ne paie
> plus. La capitaine est passée ce matin, avec la petite. Elle m'a dit : « Rentre, Léonce. »
> **Léonce** — Vingt ans qu'elle me dit quoi faire, alors je rentre. Dès que mes jambes auront compris.

*Répliques suivantes (`leonce_n`) :*

1. « La petite Kerval m'a dit bonjour. Avec mon masque sur la figure. Elle m'a reconnu aux chaussettes. »
2. « Le rouquin, il est pas méchant. Il est bruyant. C'est pas pareil. Enfin, c'est un peu pareil, quand on dort à côté. »
3. *(après `grande_forge_eteinte`)* « La grande s'est éteinte ? Alors j'y vais. Si tu passes au port : je raccommode les filets, et je ne pose pas de questions. Les deux, c'est gratuit. »

Après `grande_forge_eteinte`, Léonce et les autres masques d'os disparaissent du camp (`hide_flag`) ; on
retrouve Léonce à Port-Ambre, sur le ponton, sans masque (optionnel : Npc `Leonce` à Port-Ambre, « Le
poisson revient pas plus vite quand on le regarde. Mais on le regarde quand même. »).

---

## Scène 4 — Les corrompus qui se retournent (les trois petites forges)

*Trois petites forges, chacune gardée par un dino corrompu à plaque de fer numérotée. On les apaise
l'un après l'autre (dans l'ordre qu'on veut). Chacun, apaisé, s'en prend **à sa forge** : c'est la
scène à montrer, pas à raconter.*

### Forge 1 — Numéro 7 (Saichania corrompu niv. 43)

> Un Saichania aux veines violettes tourne autour de la première forge, sans s'arrêter, comme s'il
> cherchait la porte. Plaque au cou : « 7 ».

*Apaisé :*

> Numéro 7 s'arrête. Il regarde la forge. Il recule de trois pas, lentement, comme Grelot devant un mur
> de glace…
> **Chloé** — Oh non. Oh si.
> *Il prend son élan. BONG. La forge penche. Il recommence. BONG. La forge bascule, et les braises
> s'éparpillent dans la cendre, où elles s'éteignent une à une, en sifflant.*
> Numéro 7 s'assoit dans la cendre, très content de lui. Puis il part, au trot, vers les champs.
> **Chloé** — (C'est pour ça qu'il tournait autour. Il cherchait par où la pousser.)

### Forge 2 — Numéro 11 (Allosaurus corrompu niv. 43)

> Un Allosaurus, veines violettes, grogne devant la deuxième forge et claque des dents dans le vide.
> Plaque : « 11 ».

*Apaisé :*

> Numéro 11 se tait. Il regarde la forge longtemps. Puis il attrape le soufflet dans sa gueule, l'arrache
> d'un coup de cou, et le secoue comme un chiffon jusqu'à ce qu'il n'en reste que du cuir. Sans air, la
> forge rougit, pâlit, et s'éteint.
> Il laisse tomber le cuir aux pieds de Chloé. Comme un cadeau.
> **Chloé** — … Merci. Je crois.

### Forge 3 — Numéro 12 (Majungasaurus corrompu niv. 44)

> Un Majungasaurus, veines violettes, gratte le sol devant la troisième forge, et regarde ailleurs.
> Plaque : « 12 ».

*Apaisé :*

> Numéro 12 regarde la forge, puis le gros fût d'ambre noir à côté, puis Chloé. Il réfléchit. On le voit
> réfléchir. Il pousse le fût du museau, doucement, jusqu'à ce qu'il tombe dans la forge.
> La fumée devient violette, puis blanche, puis plus rien. L'ambre noir brûle très mal, en fin de compte.
> **Chloé** — (Dame Suie dirait : « Un problème de dosage. »)

### Quand les trois sont éteintes (`petites_forges_eteintes`, scène courte)

*Numéro 3, le Styracosaurus des champs, surgit au trot entre les cages. Il va droit à la barricade de
cages qui ferme le passage vers la grande forge, baisse la tête, et pousse. Numéro 7, revenu on ne
sait d'où, pousse à côté. La barricade grince, penche, et s'écroule dans un grand bruit de ferraille
qui roule.*

> **Chloé** — (Ils se sont donné rendez-vous. Je ne sais pas comment. Ils se sont donné rendez-vous.)
> Derrière la barricade, un homme très grand, très roux, assis sur une cage retournée, se lève d'un
> bond.
> **Brac** — MA BARRICADE !

Drapeaux : `forge_1_eteinte`, `forge_2_eteinte`, `forge_3_eteinte`, `petites_forges_eteintes`,
`barricade_tombee`. Les trois dinos repartent vers les champs (ils y deviennent capturables comme
sauvages, sans plaque : « Un Saichania sauvage. Il a une marque claire au cou, comme un collier qu'on
aurait retiré. »). Images : planches `styracosaurus_corrompu`, `saichania_corrompu`,
`allosaurus_corrompu` (existe peut-être, Forêt), `majungasaurus_corrompu` (existe, Désert ?), état
`forge_eteinte`, `barricade_tombee`, prop `soufflet`.

---

## Scène 5 — Brac (Npc `BracVolcan`, événement `brac_volcan`)

*Derrière la barricade tombée, le camp personnel de Brac : une cage retournée en guise de chaise, un
petit feu, une marmite, trois dinos couchés en rond autour de lui (Mastoc, Cabosse, Grognon : les
siens, sans veines), et, dans une grande cage encore fermée, une ombre qui gronde. Brac se lève, le
masque d'os relevé sur le front comme une casquette, la barbe pleine de cendre.*

### 5 a — Avant le combat (`brac_volcan_vu`)

> **Brac** — Le moucheron. ÉVIDEMMENT, le moucheron. La Forêt, le Désert, et maintenant MON volcan.
> **Chloé** — Ce n'est pas votre volcan.
> **Brac** — C'est le volcan où je suis. Donc c'est mon volcan. C'est comme ça que ça marche, les volcans.
> *Il regarde ses forges éteintes, la barricade par terre, Numéro 3 qui s'éloigne au trot.*
> **Brac** — Trois forges. Douze ans de forges. Et le Trois qui me regarde comme si c'était MOI qui
> l'avais mis dans une cage.
> **Chloé** — C'est vous qui l'avez mis dans une cage.
> **Brac** — … Techniquement.

*Il se rassoit sur sa cage, lourdement. Mastoc lève la tête ; Brac lui gratte le museau sans regarder.*

> **Brac** — Tu veux savoir quoi, moucheron ? Je n'ai plus d'ordres. J'attends depuis ce matin, et rien.
> Pas un mot, pas une lettre argentée, pas un « Brac, fais ceci ». Rien.
> **Brac** — Elle est passée là, juste là, avec les quatre Cœurs sous le bras. Et la petite Kerval qui la
> suit comme un Compsognathus. Et un Tricératops qui a éternué sur ma marmite.
> **Chloé** — (Caillou.)
> **Brac** — Et tu sais ce qu'elle m'a dit, après douze ans ? « Tu peux rentrer, Brac. »
> **Brac** — RENTRER. Comme on dit à un chien.

*Un silence. Il regarde le feu. Puis il se lève d'un bond, et redevient Brac.*

> **Brac** — Bon ! Ça ne change rien ! Je suis Brac, chasseur d'Alphas, et c'est écrit sur mes cartes de
> visite ! J'en ai, maintenant ! Trois cents ! Regarde !
> *Il sort une carte sale de sa poche et la brandit. On ne lit rien : il y a de la cendre dessus.*
> **Brac** — J'en ai donné une. Une seule. À la petite Kerval, ce matin. Elle a dit « merci ». MERCI. Tu
> sais depuis combien de temps personne ne m'avait dit merci ?
> **Chloé** — … Vous voulez qu'on arrête ?
> **Brac** — ARRÊTER ?! Tu as éteint mes forges, renversé ma barricade, et tu me demandes si je veux
> ARRÊTER ?! Non, moucheron. Il me reste une chose à faire ici, et c'est de gagner UNE fois.
> **Brac** — Mastoc ! Cabosse ! Grognon ! Et toi, là-dedans : réveille-toi. On a de la visite.

*La grande cage s'ouvre : un Daspletosaurus corrompu, énorme, les veines violettes jusqu'au bout de la
queue. Plaque : « FOURNAISE ». Un nom, pas un numéro.*

> **Brac** — Fournaise. Mon chef-d'œuvre. Enfin, le chef-d'œuvre de la Suie : mais c'est MOI qui l'ai
> nourri. À la pelle.
> **Chloé** — (Un nom. Il lui a donné un nom. … Il l'aime bien, celui-là.)
> **Chloé** — (Apaiser. Pas Mastoc, pas les autres : eux, ils sont à lui pour de vrai. Fournaise.)

### 5 b — Le combat

Équipe de Brac (niveaux 44 à 46, à simuler par l'agent MÉCANIQUES) : **Cabosse** (Stygimoloch 44,
« Cabosse, cette fois tu te relèves ! »), **Grognon** (Majungasaurus 44, « Grognon ! Et ne boude pas :
c'est la dernière fois que je te le demande. »), **Mastoc** (Allosaurus 45, « Mastoc ! Il a encore du
sable entre les dents. Depuis le Désert. Il ne veut pas qu'on le brosse. »), puis **Fournaise**
(Daspletosaurus 46, **corrompu**, `long_calm`, `before` : « Fournaise. Vas-y doucement, il est tout
neuf. … Non, vas-y fort, qu'est-ce que je raconte. » ; `intro` : « Brac envoie Fournaise, et la cendre
tremble ! » ; `lesson` : « Fournaise ne tombe pas : il s'apaise. Les trois autres, oui. »). Pas de soin
entre ses dinos. Défaite : retour à l'entrée des forges (`lose_spawn`), équipe soignée ; Brac : « Reviens
quand tu voudras, moucheron ! Je ne vais nulle part. C'est bien le problème. »

### 5 c — Après le combat : le moment amer, puis le départ (`brac_vaincu`, `brac_parti`)

*Fournaise, apaisé, se couche dans la cendre et ferme les yeux ; ses veines s'éteignent. Mastoc,
Cabosse et Grognon se relèvent, penauds, et vont se coucher autour de Brac. Brac reste debout, les bras
ballants. Il ne jure pas. Pas tout de suite.*

> **Brac** — … Quatre fois.
> **Brac** — La Forêt. Le Désert. Et deux fois ici, si on compte la barricade. Je compte la barricade.

*Il s'assoit sur sa cage retournée. Il regarde Fournaise qui dort, les veines éteintes.*

> **Brac** — Il dort. Je ne l'avais jamais vu dormir. Trois mois, et je ne l'avais jamais vu dormir.
> **Brac** — Douze ans, moucheron. Douze ans que je lui ramène des bêtes, des cages pleines, des Cœurs
> presque. Que je dors dans la cendre. Que je crie pour que ça avance. Et ce matin elle passe devant
> moi, sans s'arrêter, et elle dit « Tu peux rentrer ».
> **Brac** — Rentrer où ? J'ai deux cent quatre-vingt-dix-neuf cartes de visite, et pas d'adresse dessus.

*Un long silence. Mastoc pose sa grosse tête sur le genou de Brac. Brac la regarde. Chloé ne dit rien.
Moustique non plus. Le dino de tête s'assoit.*

> **Chloé** — (Il n'a pas peur du Masque. Il n'a plus de Masque. C'est pire, pour lui.)
> **Chloé** — Elle n'est pas rentrée non plus, vous savez. Elle est montée. Et Maïa aussi.
> **Brac** — … Je sais. Je les ai regardées partir. La petite m'a dit bonjour en passant. Bonjour, merci,
> et une carte dans la poche. C'est la plus polie de toute l'Ombre Noire, et elle n'en fait même pas
> partie.

*Il se lève. Il remet son masque sur le front, puis se ravise, le retire tout à fait et le regarde.*

> **Brac** — Il me serrait, de toute façon.
> *Il le jette dans la cendre, à ses pieds. Le masque d'os ne fait pas de bruit.*
> **Brac** — Bon. CROTTE DE STÉGOSAURE. Nom d'un fossile moisi. Par les écailles de ma grand-mère, et par
> celles de son Stégosaure.
> **Brac** — Je garde Mastoc, Cabosse et Grognon. Eux, quand je parle, ils me regardent. Ils regardent
> mon sandwich, mais ils me regardent.
> **Chloé** — Et Fournaise ?
> **Brac** — Fournaise dort. On ne réveille pas un dino qui dort ; c'est écrit sur un panneau quelque part,
> ta grand-mère en a mis partout. Il est à toi, moucheron. Ou aux coulées. Ou à personne. Il choisira.
> Ça fera un dino qui choisit, dans ce camp.
> **Chloé** — Où est-ce que vous allez ?
> **Brac** — Quelque part où il n'y a pas de volcan. … Il y a des endroits sans volcan ?
> **Chloé** — La mer.
> **Brac** — La mer. Je vais aller voir la mer. De LOIN. Pas en barque. Je ne monte plus dans la barque
> de personne.

*Il tourne les talons, ses trois dinos derrière lui. Il s'arrête, sans se retourner.*

> **Brac** — Moucheron. Si tu la revois… la petite… Dis-lui que la carte, c'est gratuit. Elle a voulu me
> payer. Avec un biscuit.
> **Brac** — … C'était un bon biscuit.

*Il part vers les champs, vexé, grand, pas détruit, en marmonnant des jurons de plus en plus inventifs
(« Par la crotte moisie d'un fossile de grand-mère ! ») jusqu'à ce qu'on ne l'entende plus. Mastoc
trotte derrière, en regardant la marmite.*

> **Chloé** — (Il va voir la mer. De loin. … Il n'a jamais fait peur à personne, en fait. Il a surtout eu
> peur.)
> *Elle regarde le masque d'os dans la cendre.*
> **Chloé** — (Deux masques par terre. Un dans l'herbe, un dans la cendre. Personne ne les ramassera.)

Fournaise : à la fin de la scène, il se lève, regarde Chloé, et choisit (le jeu : s'il y a de la place
dans l'équipe, il la rejoint sous le nom **Fournaise**, Daspletosaurus 46, type feu : le dino qui
franchira la lave si l'on n'en a pas d'autre ; sinon il part « vers les coulées », où on le retrouve,
capturable, la nuit : « Un Daspletosaurus. Il a une marque claire au cou. Il vous a reconnue. »). Le
drapeau `fournaise_garde` dit lequel.

Prop `MasqueBrac` (examen) : « Le masque d'os de Brac, dans la cendre. Il est fendu sur le côté : il le
serrait vraiment. » Pensée (une fois) : « (Il ne reviendra pas le chercher. Il a dit : la mer.) »

Drapeaux : `brac_volcan_vu`, `brac_vaincu`, `brac_parti`, `fournaise_garde`, `masque_brac_vu`. Images :
Brac (planche existante ; une pose assise serait un plus : « sur une cage »), `masque_os_sol`,
`daspletosaurus_corrompu`, `daspletosaurus`, `cage_grande`, `marmite`.

Garde-fous : Brac ne pleure pas, ne s'excuse pas, ne devient pas gentil ; il est vexé, et il fait un
choix (la mer). Chloé ne le console pas et ne lui fait pas de leçon : une phrase (« Elle n'est pas rentrée
non plus »), c'est tout. Le moment amer tient en quatre répliques ; après, on rit de nouveau.

---

## Scène 6 — Dame Suie (Npc `SuieVolcan`, événement `suie_volcan`, au pied de la grande forge)

*La plateforme de roche au pied de la grande forge. Un établi impeccable : fioles étiquetées en rang,
une balance, un carnet ouvert, une plume. Son traîneau des Monts, monté sur roues. Mandragore
(Therizinosaurus) couché à côté, sans veines : il n'a jamais été corrompu. Dame Suie, manteau couleur
de cendre, gants gris perle, voilette, lunettes fumées contre la lueur de la forge, écrit. Elle a tout
vu. Elle n'a pas bougé.*

### 6 a — « Vous avez pris votre temps » (`suie_volcan_vue`)

> **Dame Suie** — Mademoiselle Varenne. Vous avez pris votre temps.
> **Dame Suie** — Trois forges, une barricade, et Brac. Je vous ai regardée depuis le début. J'ai pris des
> notes. Vous permettez que je finisse ma ligne ?
> *Elle finit sa ligne. Elle pose la plume.*
> **Dame Suie** — Voilà. « Le sujet 7 a renversé sa propre forge. Le sujet 11 a arraché le soufflet. Le
> sujet 12 a… » Je ne sais pas comment écrire ce qu'a fait le 12. « A réfléchi », je crois. Ce n'est pas
> un mot de mes tables.
> **Chloé** — Vous n'avez rien fait pour les empêcher.
> **Dame Suie** — Non. J'observais. C'est mon métier, mademoiselle : Brac chasse, le Masque veut, et moi
> j'observe. Et depuis ce matin, j'observe surtout que je n'ai plus de Masque.

*Elle tourne la tête vers la grande forge, qui crache sa fumée violette.*

> **Dame Suie** — Elle est passée à l'aube. La capitaine. Elle m'a pris une fiole : une seule, la plus
> pure, celle que je gardais pour… pour rien. Pour savoir si je pouvais. Elle a dit : « Vous pouvez
> éteindre, Dame Suie. Je n'ai plus besoin que d'une goutte. »
> **Dame Suie** — Je n'ai pas éteint. Je voulais voir si elle reviendrait la chercher. Ce n'est pas la
> fiole que je regardais partir, mademoiselle. C'est la petite.
> **Chloé** — Maïa.
> **Dame Suie** — La fille du Masque. À côté de sa mère. Pas derrière : à côté. Elle avait des cendres
> jusqu'aux genoux, un manteau trop grand, et elle disait bonjour aux sbires. Un par un. Elle a dit
> bonjour à Brac.
> **Dame Suie** — J'ai regardé ses yeux quand elle est passée devant la forge. Je regarde toujours les
> yeux : c'est là que l'ambre noir se voit en premier. Pas une goutte. Et pas peur.
> **Dame Suie** — J'ai cherché dans mes tables à quoi ça correspondait. Une enfant qui marche vers un
> volcan, à côté de quelqu'un qui lui a menti pendant un an, sans une goutte, et sans peur.
> **Dame Suie** — Il n'y a pas de ligne pour ça. J'ai regardé deux fois.

### 6 b — Belladone, les dormeurs, et Maïa : trois fois

*Elle retire ses gants, un doigt après l'autre, et les pose sur l'établi. (Aux Monts, elle avait retiré
ses lunettes. Ici, les gants : elle va toucher à quelque chose.)*

> **Dame Suie** — Je vais vous dire où j'en suis, mademoiselle Varenne, parce que vous êtes la seule
> personne de cette île à qui ça puisse servir.
> **Dame Suie** — Au Marais, vous avez calmé Belladone sans une goutte. J'ai noté : « exception ». Aux
> Monts, les dormeurs de votre grand-mère étaient parfaits sans une goutte. J'ai noté : « à vérifier ».
> Ce matin, la fille du Masque. Je n'ai rien noté. Je n'avais plus de colonne.
> **Dame Suie** — Une exception, c'est une exception. Deux, c'est une erreur de mesure. Trois…
> **Chloé** — Trois, c'est que les tables sont fausses.
> **Dame Suie** — … Vous avez les yeux de votre grand-mère. Ils finissent mes phrases avant moi.
> **Dame Suie** — Trois, c'est que le dosage n'a jamais été la question. « La peur n'est qu'un problème de
> dosage. » Je l'ai écrit en tête de chaque carnet pendant douze ans. Il manquait un mot. La peur n'est
> pas un problème de dosage : c'est un problème. Point.

*Elle se lève. Elle va jusqu'à la grande forge, à une roue de fer qui commande le tirage.*

> **Dame Suie** — Brac donnait l'ambre noir à la pelle. Je le lui ai assez reproché. Mais une pelle ou une
> pipette, mademoiselle, ça reste de l'ambre noir, et j'ai mis douze ans à le mesurer.

### 6 c — La grande forge s'éteint (`grande_forge_eteinte`)

*Elle tourne la roue. Ça grince. Le rouge de la forge baisse, comme une lampe qu'on souffle lentement ;
la fumée violette blanchit, puis s'arrête. Le camp devient silencieux : plus de ronflement de feu, pour
la première fois depuis douze ans. Le volcan, derrière, continue de fumer, lui. Mandragore lève la
tête, surpris du silence, et la repose.*

> La grande forge s'éteint. Pas d'un coup : comme une lampe qu'on baisse. Le rouge devient rose, puis
> gris. La fumée blanchit. Et puis, plus rien. Le silence. Le vrai : on entend le vent, et Moustique qui
> respire.
> **Dame Suie** — Voilà. Douze ans. Ça fait moins de bruit que je pensais.

*Elle retire ses lunettes fumées et les met dans sa poche. Pas comme aux Monts, pour regarder quelque
chose : pour de bon.*

> **Dame Suie** — Elles étaient contre la lueur. Il n'y a plus de lueur.
> **Chloé** — (Elle a des yeux gris. Je ne les avais jamais vus. Ils ont l'air… fatigués. Et curieux.)

### 6 d — L'antidote (`antidote_ambre`)

*Elle revient à l'établi, ouvre un petit coffret de bois, et en sort une fiole : de l'ambre liquide,
clair, presque doré, qui luit un peu dans le gris. Étiquette fine : « Ambre clair. Une goutte. Pas une
de plus. — S. »*

> **Dame Suie** — On ne fabrique pas un poison sans fabriquer son contraire. C'est la première règle. Brac
> ne l'a jamais apprise ; je l'ai apprise avant d'avoir des gants.
> **Dame Suie** — Je l'ai mis au point la nuit, aux Monts, après Aconit. Je me disais : par prudence. Je
> me mentais : c'était par curiosité. Je voulais savoir si ça se défaisait.
> **Chloé** — Et ça se défait ?
> **Dame Suie** — Une goutte sur un dino corrompu, et les veines s'effacent. D'un coup. Sans parler,
> sans Lien, sans rien : de la chimie. Vous n'en aurez pas besoin pour les corrompus d'ici : vous faites
> mieux que moi, et plus lentement.
> **Dame Suie** — Mais la capitaine a une fiole. La plus pure. Et elle va s'en servir sur quelque chose de
> très grand, qui dort. Ce jour-là, mademoiselle, vous n'aurez pas le temps de parler.
> *Elle tend la fiole. Chloé la prend. Elle est tiède.*
> **Dame Suie** — Une dose. Je n'ai pas eu le temps d'en faire deux : la nuit est courte, au pied d'une
> forge. Choisissez votre moment.
> **Chloé** — Pourquoi vous me la donnez ?
> **Dame Suie** — Parce que je refais mes tables, et que la première ligne de la nouvelle, c'est vous.

Objet `antidote_ambre` (« Ambre clair », objet clé, une dose, pour le dernier combat). Drapeaux :
`suie_alliee`, `antidote_ambre`.

### 6 e — La lettre (`found_journal_37`, objet `lettre_isaure`)

*Elle hésite. C'est rare. Puis elle ouvre le tiroir de l'établi et en sort une enveloppe de papier
épais, pliée en deux, jaunie par la chaleur. Dessus, une écriture qu'on connaît : « Pour Isaure ».*

> **Dame Suie** — Il y a autre chose. Ce n'est pas à moi, et je l'ai gardée un an. Ça fait deux fautes.
> **Dame Suie** — Votre grand-mère est venue ici. Il y a un an. Une nuit. Personne ne l'a vue ; moi, je
> l'ai vue, parce que je ne dors pas beaucoup. Elle a traversé le camp comme on traverse sa cuisine,
> elle a posé ça sur mon établi, à côté de mes fioles, elle m'a regardée, et elle est repartie vers les
> coulées.
> **Chloé** — Elle vous a regardée ?
> **Dame Suie** — Comme on regarde une élève qui a bien travaillé sur un mauvais sujet. … Je n'ai pas
> aimé. J'y repense souvent.
> **Dame Suie** — Je ne lis pas le courrier des autres, mademoiselle. J'ai des défauts ; pas celui-là. Je
> l'ai gardée pour la lui donner. Elle est passée ce matin, et je ne l'ai pas fait.
> **Chloé** — Pourquoi ?
> **Dame Suie** — Parce que si elle l'avait lue, elle ne serait peut-être pas montée. Et je voulais voir
> ce qui se passe quand on monte. … Troisième faute. Je vous la laisse corriger : vous allez là où elle
> va.

*Chloé prend l'enveloppe. Elle n'est pas scellée : juste pliée. Hélène écrivait tout, et ne cachetait
rien.*

> **Chloé** — (Pliée, pas fermée. Elle voulait qu'on la lise. Elle voulait que quelqu'un la lise, si
> Isaure ne venait pas.)
> **Chloé** — (… Je la lis. Et je la lui porte.)

**Page 37 — Pour Isaure** (−1 an ; `letter`, signée « — H. ») :

> Isaure,
> Je suis descendue voir tes forges. Elles sont sept, j'ai compté : je n'ai pas pleuré, j'ai compté,
> c'est ce que je sais faire. Je sais que c'est toi. Je l'ai su avant mes carnets, je crois, et je n'ai
> rien dit, parce que je préférais te perdre doucement que d'un coup. C'était lâche. Je te le dis une
> fois : c'était lâche.
> Tu n'as pas tort pour le port. Tu as tort sur le moyen. Je te l'ai déjà écrit, et j'ai jeté la lettre à
> la mer ; tu vois que je progresse : celle-ci, je la pose là où tu passeras.
> Je ne te hais pas. Je ne t'ai jamais haïe. J'ai eu peur pour toi, ce qui est autre chose et dure plus
> longtemps.
> Reviens. Pas au Cabinet : reviens tout court. Il y a ta tasse, et il y a du thé, et il y a vingt ans à
> rattraper, dont la moitié est de ma faute.
> — H.

> **Chloé** — (« La moitié est de ma faute. » … Elle ne disait jamais rien fort. Mais elle le disait.)
> **Chloé** — (Isaure est là-haut, devant une porte, avec les Cœurs. Et cette lettre a un an de retard.)

Drapeaux : `found_journal_37`, `page_37` ; objet `lettre_isaure` (quitte le sac à la porte, scène 9 ;
la page reste au mur du journal). Si Chloé a lu la page 25 : une pensée de plus : « (Elle a gardé la
tasse. Et elle a réécrit la lettre. Deux fois, c'est une habitude.) »

### 6 f — Elle s'en va (`suie_partie`)

*Elle range son carnet, pas ses gants (elle les laisse sur l'établi). Elle attelle Mandragore au
traîneau sur roues. Dedans : des caisses, pas de fioles. Des carnets. Beaucoup de carnets, à
couverture de toile, usés.*

> **Dame Suie** — Les carnets de votre grand-mère. Ceux de l'ambre forcé, ceux qu'on m'a donnés il y a
> douze ans « pour travailler ». J'ai travaillé. Je les rends.
> **Chloé** — À qui ?
> **Dame Suie** — Au Cabinet. À votre professeur Roc, qui a une clé, du thé, et une couveuse qu'il regarde
> comme si elle allait lui répondre. Je lui dirai que je refais mes tables. Il ne comprendra pas. Il
> fera du thé.
> **Dame Suie** — Les coulées sont par là, mademoiselle. Pour les franchir, il vous faut un dino qui a le
> cuir pour : de la pierre, ou du feu. Brac en avait un. Il l'a laissé choisir. C'est la première chose
> intelligente qu'il ait faite depuis que je le connais, et il ne le sait pas.
> **Chloé** — Dame Suie.
> **Dame Suie** — Mademoiselle ?
> **Chloé** — Merci.
> **Dame Suie** — … C'est la deuxième fois aujourd'hui qu'on me dit ça dans ce camp. La première, c'était
> la petite Kerval, pour un sbire qui lui avait tenu une cage ouverte. Je commence à croire que c'est
> contagieux.
> *Elle fait un pas, et s'arrête.*
> **Dame Suie** — Nous nous reverrons. Là où il fait bon, cette fois. J'aimerais bien.

*Le traîneau s'éloigne vers les champs, Mandragore au trot. Elle ne se retourne pas. Sur l'établi, ses
gants gris perle, côte à côte.*

> **Chloé** — (Froide, curieuse, pas cruelle. Elle n'a pas changé. Elle a seulement compté jusqu'à trois.)

Props après son départ : `Etabli` (examen) : « L'établi de Dame Suie. Des fioles en rang, une balance,
et une paire de gants gris perle, posés côte à côte. Elle ne les a pas oubliés. » ; `GrandeForge`
(examen, éteinte) : « La grande forge, froide. La brique noire craque encore un peu en refroidissant.
Douze ans, et ça fait ce bruit-là : tic, tic. » ; avant : « La grande forge. On ne peut pas s'en
approcher : la chaleur repousse. »

Répliques de Dame Suie si on lui parle avant d'avoir battu Brac (elle ne bouge pas de sa plateforme ; la
barricade la protège : on ne peut en fait lui parler qu'après `barricade_tombee`, mais si l'ordre
change) : « Finissez d'abord avec Brac, mademoiselle. Il a besoin de perdre une dernière fois : ça lui
fera du bien, et j'ai besoin de le noter. » Après `suie_partie`, elle n'est plus là (`hide_flag`).

Garde-fous : elle ne s'excuse pas, ne pleure pas, ne dit pas « j'avais tort » : elle dit « je refais mes
tables ». Pas de combat contre elle (le chapitre en a deux grands). La bascule tient à trois choses
qu'elle a vues, pas à un discours de Chloé (Chloé dit cinq phrases). Le mot « Maïa » est dit par
Chloé, jamais par elle (« la fille du Masque », « la petite Kerval », « la petite »).

Images : Dame Suie (planche existante ; une variante `suie_sans_lunettes` serait un plus, face), prop
`etabli_suie`, `gants_gris`, `traineau_roues`, `grande_forge_eteinte`, icône `antidote_ambre.png`
(fiole d'ambre clair, étiquette), `lettre_isaure.png` (enveloppe jaunie, « Pour Isaure »).

---

## Scène 7 — Les Coulées de Lave (`coulees_lave`)

### 7 a — L'arrivée (scène d'entrée `coulees_arrivee`)

*La roche noire, fendue de rivières rouges qui bougent à peine. L'air tremble au-dessus. Des plaques
de croûte grise flottent sur le rouge. Plus loin, un rocher noir au milieu des coulées, inaccessible à
pied. Au fond, une faille dans le flanc du volcan : le sanctuaire.*

> Les coulées. La roche est noire, et fendue de rivières rouges qui bougent lentement, comme du miel
> trop chaud. L'air tremble au-dessus. Ça sent le feu, et l'odeur fait tousser.
> Il fait chaud. Pas chaud comme un four : chaud comme un four **ouvert**. Chloé s'essuie le front du
> revers de la main : elle se barbouille de cendre. Évidemment.

*Selon le dino de tête :*

> *(raptor)* Vif avance une patte vers le rouge, la retire, et regarde Chloé : « Pas question. »
> *(cuirassé)* Bastion avance jusqu'au bord de la coulée, s'y arrête, et renifle. Il ne recule pas. Il a
> le cuir pour.
> *(hadrosaure)* Écho recule de deux pas et lance un « tuut » long et bas, qui ne revient pas. Rien ne
> revient, ici : la chaleur mange les sons.

> Moustique se cache dans le col de Chloé, tout entier. Il n'en sort plus que le bout du bec.
> **Chloé** — Je sais. Tu as peur du feu. Elle me l'a dit. Reste là.
> **Chloé** — (Pour passer, il faut quelqu'un qui n'a pas peur du feu. Ou qui est fait en pierre.
> « Le cuir pour », a dit Dame Suie. … Pas moi, en tout cas.)

Drapeau : `coulees_arrivee`. Images : sols `lave`, `croute_refroidie`, `roche_noire` ; particules de
chaleur (l'air qui tremble) ; fond de combat `volcan`.

### 7 b — La première coulée (StoryTrigger `PremiereCoulee`, dialogue `lave_bloquee` / `lave_franchie`)

*Mécanique B (contrat pour l'agent MÉCANIQUES) : les coulées sont des cases « lave » infranchissables à
pied ; elles se franchissent **si le dino de tête est de type pierre ou feu** (le joueur monte sur son
dos, comme la nage sur un Baryonyx : compétence de traversée « Braise »/« Cuir de feu », à nommer). Les
dinos qui l'ont : Bastion (pierre), tout cuirassé (Saichania des coulées refroidies, Pinacosaurus,
Minmi, Ankylosaurus…), Fournaise (Daspletosaurus, feu), tout grand théropode de type feu que l'équipe
aurait, Braise (le Dilophosaurus du Marais, s'il est resté et si son type est feu). Une touche de
mécanique A : **près des coulées**, une petite jauge de chaleur monte (à pied seulement) ; pleine, Chloé
s'éloigne d'elle-même à l'ombre (« Trop chaud. Chloé recule. ») sans jamais perdre de PV ; sur le dos
d'un dino de pierre ou de feu, la jauge ne monte pas.*

Sans dino qui convient (`lave_bloquee`) :

> La coulée barre tout le passage. Rouge, lente, et bien trop chaude pour qu'on l'approche.
> **Chloé** — (Il me faut un dino de **pierre** ou de **feu** en tête : un cuirassé, ou un grand théropode
> qui n'a pas peur du feu.)
> *Le texte dit qui, dans l'équipe ou la réserve, pourrait (nom et type) ; sinon : « Les Saichania des
> coulées refroidies, de jour, ont le cuir pour. Et Fournaise, si on le retrouve. »*

Avec (`lave_franchie`, une fois) :

> Chloé monte sur le dos de %s. Il avance vers le rouge sans ralentir, et pose une patte dessus : la
> croûte craque, siffle, et tient. Puis l'autre patte.
> **Chloé** — (Ne regarde pas en bas. Ne regarde pas en bas. … J'ai regardé en bas.)
> La chaleur monte autour d'eux, mais %s ne la sent pas : il a le cuir pour. Chloé serre les genoux, et
> ils passent. De l'autre côté, la roche est noire et froide, et elle a envie de l'embrasser.
> **Chloé** — Merci. Non, vraiment : merci.

Drapeau : `lave_franchie`. Panneau près de la première coulée : « La lave, ça se regarde de loin. Ou du
dos d'un dino qui a le cuir pour. Pas des deux à la fois. — H. »

### 7 c — Le rocher au milieu des coulées : la page 36 (Pickup, atteint seulement sur un dino de pierre/feu)

> Sur le rocher noir, au milieu du rouge, une boîte en fer calée sous une pierre. Le fer est tiède. Le
> papier, à l'intérieur, a jauni comme du pain trop cuit.

**Page 36 — Si le sceau cède** (−1 an ; `letter`, « — H. ») :

> Le sceau s'use. Je l'entends d'ici : la lave bat comme un cœur qui a couru. Si quelqu'un l'ouvre, il
> ne suffira pas de refermer : il faudra quelqu'un dedans, pour le calmer de l'intérieur. Pas une clé.
> Pas un Cœur. Quelqu'un.
> Je connais une personne qui l'a déjà fait une fois, avec ses deux mains, et qui a encore les
> cicatrices pour le prouver. L'ambre se referme sur ce qui ne bouge plus. Je ne bougerai plus. Il
> m'écoutera dormir, et il dormira.
> Ce n'est pas un sacrifice, Anselme, si tu lis ceci : c'est une position confortable, et j'ai toujours
> aimé les positions confortables. Garde le thé au chaud.

> **Chloé** — (Se sceller avec lui. De l'intérieur. … Elle n'a pas disparu. Elle est entrée.)
> **Chloé** — (« Il faut les cinq pour ouvrir, et quelqu'un pour le tenir. » Isaure a lu ça. Isaure l'a
> écrit avec les mêmes mots. … Elle ne veut pas le tenir. Elle veut la sortir de là.)

Drapeaux : `found_journal_36`, `page_36`. (La page 36 est la première fois qu'on apprend **comment**
Hélène a disparu ; la page 32 disait seulement « je vais faire une bêtise ». La pensée de Chloé relie
les mots d'Isaure à l'Arche à ceux d'Hélène ici, sans conclure à sa place.)

### 7 d — Le Daspletosaurus de nuit (habitat, `coulees_lave`, nuit)

> *(première rencontre, pensée)* Un Daspletosaurus. La nuit, les coulées l'éclairent par en dessous : il a
> l'air d'un dino en braise. Il ne charge pas tout de suite : il regarde.

Si Fournaise n'a pas été gardé (`fournaise_garde` faux), l'un d'eux porte une marque claire au cou et
« vous a reconnue » (capturable, niv. 46).

### 7 e — La faille du sanctuaire (sortie vers `sanctuaire_magma`)

> Une faille dans le flanc du volcan, haute et étroite, d'où sort un souffle chaud et régulier. Comme une
> respiration. Au-dessus, gravé dans la roche : « On n'entre pas sans frapper. Ici, c'est lui qui frappe.
> — H. »
> **Chloé** — (Le sanctuaire de Magma. Le cinquième Cœur. Et le gardien « le plus difficile à
> convaincre ». … Roc a dit : une légende. Cours. Je ne vais pas courir.)

(La réplique de Roc, « Une légende. Cours. », est donnée par la question « Un T-Rex ne voit pas ce qui
ne bouge pas, c'est vrai ? » au Cabinet : voir « Autour ». Si Chloé ne l'a pas posée, la pensée devient :
« (Le cinquième Cœur. Et le gardien « le plus difficile à convaincre ».) »)

---

## Scène 8 — Le Sanctuaire de Magma (`sanctuaire_magma`)

### 8 a — L'arrivée (scène d'entrée `sanctuaire_magma_arrivee`)

*Une salle ronde taillée dans du verre noir : les murs sont d'obsidienne, et la lave, dessous, les
éclaire par en dessous en rouge sombre. Au centre, un autel de roche noire. Au fond, une paroi de
verre où la lave coule à l'intérieur, comme dans un sablier. À l'entrée, une vasque de pierre pleine
d'eau fumante : une source chaude.*

> La faille s'ouvre sur une salle ronde. Les murs sont noirs et brillants : du verre. De l'obsidienne.
> Dessous, la lave les éclaire en rouge, et on se voit dedans, en rouge, partout.
> **Chloé** — (Le masque. Le masque d'obsidienne était fait de ça. De cette pierre-là.)
> Au centre, un autel de roche noire, vide. Au fond, une paroi de verre où la lave coule, à l'intérieur,
> lentement, comme du sable dans un sablier.
> Il fait chaud, et c'est calme. Trop calme. Le dino de tête se colle contre la jambe de Chloé.

*La vasque d'eau fumante, à l'entrée. Des cercles à sa surface. Un « boum » sourd, très loin dessous. La
caméra tressaille. Les cercles, encore. (Le clin d'œil : « l'eau qui tremble ».)*

> La vasque. Des cercles à la surface de l'eau. Un « boum », tout bas, qui monte par les pieds. Encore
> des cercles.
> **Chloé** — (Il arrive.)
> **Chloé** — (« Un T-Rex ne voit pas ce qui ne bouge pas. » Roc a dit : une légende. Cours.)
> *Chloé ne bouge pas. Le dino de tête ne bouge pas. Moustique, dans le col, ne respire plus.*

*Dans la paroi de verre, derrière la lave qui coule, une ombre se lève. Immense. Elle s'approche de la
paroi, et la paroi s'ouvre comme un rideau de lave : le **T-Rex de Magma** entre dans la salle. Rouge
sombre, des fissures oranges qui luisent sur son dos comme des braises sous la cendre, de la fumée
qui sort de ses naseaux quand il souffle. Il pose un pied : le sol tremble. L'autre. Il baisse la tête
jusqu'à Chloé, et il la regarde. Droit dans les yeux.*

> Le T-Rex de Magma la regarde. Droit dans les yeux. Il la voit très bien.
> **Chloé** — (Une légende. … Roc avait raison. Et je ne cours pas.)

Drapeaux : `sanctuaire_magma_arrivee`, `flaque_tremble`. Images : sol `obsidienne`, `lave_paroi`
(animée si possible), prop `vasque_source`, `autel_magma` ; le T-Rex de Magma (Alpha, profil, face,
dos, 3 vues ; ~1,4 fois la taille d'un Daspletosaurus ; jamais effrayant : la bouche fermée au repos,
les braises du dos qui pulsent doucement).

### 8 b — Le gardien (DinoNpc `TrexMagma`, événement `trex_magma`, `trex_magma_parle`)

*Il renifle. Les Sceaux, un par un : la Forêt, le Marais, le Désert (il souffle : un vieux voisin), la
Côte (il fronce les naseaux : le poisson, encore), les Monts (il recule la tête : trop froid), les
Cieux (il lève les yeux vers la voûte). Puis la sacoche. Vide. Il renifle encore. Il cherche les Cœurs.
Il ne les trouve pas.*

> Il renifle les Sceaux, un par un. La Forêt, le Marais. Le Désert : il souffle un grand souffle chaud,
> comme on salue un vieux voisin. La Côte : il fronce les naseaux. Les Monts : il recule la tête. Les
> Cieux : il lève les yeux vers la voûte, longtemps.
> Puis la sacoche. Il renifle, cherche, renifle encore. Il gronde, tout bas.
> **Chloé** — Je les avais. Les quatre. On me les a pris, là-haut. Ils sont là-bas, devant la porte, et
> ils vont servir à ouvrir ce qu'elle a fermé.
> **Chloé** — Je sais que vous ne comprenez pas les mots. Elle disait que vous compreniez les mains.

*Elle tend les deux mains, paumes ouvertes, comme Hélène sur la page 10. Il les renifle. Il souffle
dessus : c'est chaud, pas brûlant. Puis il relève la tête, recule jusqu'à l'autel, et rugit : les murs
de verre vibrent, la lave dans la paroi saute, et la vasque déborde.*

> Il souffle sur ses mains. Chaud. Pas brûlant. Puis il recule jusqu'à l'autel, et il rugit, et toute la
> salle de verre chante avec lui.
> **Chloé** — (Un combat d'honneur. Le dernier. Le plus dur. Il veut savoir si je peux tenir.)

### 8 c — Le combat (`trex_magma_battu`)

Combat d'honneur (niveau 48, pas de collier, pas de fuite, musique des Alphas), type **feu** (à
confirmer par MÉCANIQUES : la leçon dit ce qui le touche fort, l'Eau et la Pierre ; les dinos de feu et
de vent souffrent) ; il ne se couche jamais ; avant chaque essai, l'équipe boit l'eau de la source
chaude (« elle a un goût d'œuf, et elle remet d'aplomb ») ; défaite : retour à la faille, équipe
soignée, une ligne (« Il attend. Il a attendu vingt-cinq ans ; il ne compte plus les jours. »). C'est le
combat le plus dur du jeu avant la fin : l'équipe doit être vers 45-46, reposée, avec un dino d'Eau ou
de Pierre (Nessie, Bouée, Bastion, un Saichania…). La leçon de combat le dit sans tricher : « L'Eau et la
Pierre le touchent fort ; le Feu et le Vent, lui, les traverse. »

### 8 d — Le Sceau et le Cœur (`sceau_volcan`, `coeur_5`)

*Gagné, il ne s'incline pas comme le Roi ni ne souffle comme le Titan : il frappe l'autel du pied. Une
fois. Le sol de verre se fend en étoile, et sous l'autel, dans un creux, de la lave rouge monte, puis
se fige en se refroidissant, et au milieu, quelque chose luit : le **Cinquième Cœur**, dans une coque
de lave noire qui s'ouvre comme une noix.*

> Il frappe l'autel du pied. Une fois. Le verre se fend en étoile, et sous l'autel, de la lave monte,
> rouge, et se fige, noire, et craque : au milieu, dans une coque de lave ouverte comme une noix, le
> **Cinquième Cœur**.
> Il est chaud comme du pain qui sort du four. Il bat fort, vite, comme s'il avait couru. Comme s'il
> savait qu'il est le dernier.
> Dans la coque, à côté, un disque d'ambre rouge sombre : une flamme, et la fougère d'Hélène. Le **Sceau
> du Volcan**.

> **Chloé** — (Un Cœur. Un seul. Elle en a quatre, et moi un, et il faut les cinq.)
> **Chloé** — (Alors elle a besoin de moi. Et moi d'elle. … C'est bête, mais ça me rassure.)

*Le T-Rex se couche enfin, de tout son long, les braises du dos qui ralentissent. Il fume quand il
dort. Chloé s'approche, et pose la main sur son museau : chaud comme une pierre au soleil.*

> Il se couche, et il fume, doucement, par les naseaux. Chloé pose la main sur son museau : chaud comme
> une pierre au soleil.
> **Chloé** — Elle vous appelait comment ? … Elle vous appelait sûrement quelque chose.

(La réponse est dans la page 35, juste à côté : voir 8 e.)

*Le volcan gronde : fort, long, et la salle de verre tremble ; mais le T-Rex ne bouge pas, et quand ça
s'arrête, on entend dehors un grand bruit de pierre qui coule : la lave se retire du chemin du cratère,
« comme une marée ». (`lave_retiree` : la sortie vers `porte_cratere` s'ouvre, depuis les coulées.)*

> Dehors, le volcan gronde, long, fort ; la salle tremble ; puis un grand bruit de pierre qui coule, et
> plus rien. Le Cœur, contre Chloé, bat plus calme.
> **Chloé** — (Quelque chose a bougé, dehors. Un chemin, peut-être.)

Objets `coeur_5`, `sceau_volcan` ; drapeaux `sceau_volcan`, `coeur_5`, `lave_retiree`. Le T-Rex reste
couché près de l'autel ensuite (examen : « Le T-Rex de Magma dort, et il fume. Hélène l'avait écrit.
Chloé ne le réveille pas. »).

### 8 e — La page 35 (Pickup, dans une fente du mur de verre, derrière l'autel)

> Dans une fente du mur de verre, derrière l'autel, une boîte en fer noircie. Elle est tiède depuis
> vingt-cinq ans. Dedans, une page du journal, et une plume de chapeau à moitié brûlée.

**Page 35 — Le cinquième Cœur** (−25 ans ; `letter`, « — H. ») :

> Le T-Rex de Magma ne m'a pas chargée : c'est pire, il ne m'a pas regardée. Trois semaines. Je venais
> chaque jour m'asseoir sur la pierre chaude, et je lui parlais, et il regardait la lave. Le
> vingt-deuxième jour, il a mangé mon chapeau. Le vingt-troisième, il s'est couché à côté de moi, et le
> sol a tremblé, et je crois que c'était sa façon de dire oui.
> Je lui ai confié le dernier Cœur, le plus chaud : il l'a couvert de lave comme on couvre une braise
> pour la nuit. Il fume quand il dort. Anselme l'a appelé Cheminée. Anselme n'a aucun respect, et il
> avait raison.
> I. a ramassé un éclat de verre noir grand comme une assiette, « pour en faire quelque chose ». Je lui
> ai dit de ne pas se couper. Nous avons ri. Je crois que c'est le dernier endroit où nous avons ri
> toutes les deux ; je ne le savais pas encore.

> **Chloé** — Cheminée. … Ça vous va.
> **Chloé** — (« Un éclat de verre noir grand comme une assiette. » … Le masque. Elle l'a taillé dans un
> souvenir. Dans le dernier endroit où elles ont ri.)
> **Chloé** — (Je ne le dirai pas à Maïa. Pas comme ça. … Peut-être un jour.)

Drapeaux : `found_journal_35`, `page_35`. (La page 35 est la seule des quatre à être vieille : les
trois autres ont un an. Le ton : Hélène heureuse, à la fin de ses cinq Cœurs, et une amie à côté.)

Garde-fous : le T-Rex ne mange rien, ne mord rien, n'a jamais la gueule ouverte sur quelqu'un ; son
rugissement « chante » ; le clin d'œil s'arrête à « il la voit très bien » et « je ne cours pas ». La
révélation du masque taillé dans l'obsidienne du sanctuaire reste une pensée de Chloé, jamais dite à
Isaure dans ce chapitre (question pour Greg).

---

## Scène 9 — La Porte du Cratère (`porte_cratere`)

### 9 a — L'arrivée (scène d'entrée `porte_arrivee`)

*Un chemin de roche noire monte en lacets jusqu'au bord du cratère ; la lave vient de s'en retirer et il
fume encore. En haut, une esplanade, et dans la paroi, un grand **portail de bois** à deux battants,
noirci, cerclé de fer, haut comme trois maisons, entre **deux torches** plantées dans la roche. Devant,
un petit camp : une lanterne éteinte, un cairn, une couverture pliée. Et, debout face au portail, le
dos à Chloé, Isaure. Assise sur une pierre à côté, Maïa. Couché derrière, énorme, Caillou.*

> Le chemin monte en lacets, et la roche fume encore là où la lave coulait tout à l'heure. En haut, le
> bord du cratère. Et dans la paroi, un portail de bois à deux battants, noirci, cerclé de fer, haut
> comme trois maisons. Deux torches, plantées dans la roche, brûlent de chaque côté.
> **Chloé** — (La Terre des Apex. C'est derrière. Et elle est devant.)
> Devant le portail, le dos à Chloé, une femme debout, qui ne bouge pas. Sur une pierre à côté, une
> fille dans un manteau trop grand. Et derrière, couché, un Tricératops qui ronfle.
> *Caillou lève la tête, renifle, et éternue dans la cendre.*
> **Maïa** — Il éternue toujours quand c'est toi. Je ne sais pas pourquoi.

Drapeau : `porte_arrivee`. Images : `portail_apex` (bois, fer, deux battants), `torche`, `camp_helene`
(lanterne, cairn, couverture), `isaure_sans_masque` (dos, profil, face), Maïa (`maia_arche` : son
manteau de Joss), `caillou` (Tricératops, couché).

### 9 b — Le camp d'Hélène et la page 38 (StoryProp `CampHelene`, Pickup `page_38`)

*(Avant ou après Isaure, selon où le joueur va : la page est au cairn, à trois pas d'elle.)*

> Un petit camp, contre la paroi : une lanterne d'ambre éteinte, une couverture pliée au carré, un cairn
> de pierres noires. Quelqu'un a dormi ici, une nuit, il y a un an, et a rangé avant de partir.
> Sous les pierres du cairn, une boîte en fer. Dedans, une page du journal. La dernière qu'elle a écrite
> de ce côté-ci.

**Page 38 — La veille** (−1 an ; `letter`, « — H. ») :

> Dernière nuit dehors. J'ai laissé trois œufs au Cabinet, dans la couveuse, avec une lettre pour Chloé
> qui dit beaucoup moins que je voudrais : on n'écrit pas « je t'aime » à une enfant qu'on a vue trop
> peu, on écrit « trouve les Cœurs ». J'espère qu'elle lira entre les lignes. Elle a mes yeux : ils
> lisent entre les lignes, et ils disent non avant la bouche.
> J'ai peur. Je l'écris une fois, ici, pour que ce soit dit, et je ne l'écrirai plus. Anselme a ma clé,
> I. a mes carnets, Chloé aura mes dinos. Il ne me reste que mes mains, et elles savent quoi faire :
> elles l'ont déjà fait.
> Demain, je descends. Si quelqu'un lit ceci avant moi : ne me cherche pas tout de suite. Occupe-toi
> d'eux d'abord. Ils sont plus petits.

> **Chloé** — (« Ne me cherche pas tout de suite. » … Je ne t'ai pas cherchée. Je les ai trouvés, eux,
> un par un. Et maintenant je suis là quand même.)
> **Chloé** — (Elle a eu peur. Elle l'a écrit une fois. Et elle est descendue.)

Drapeaux : `found_journal_38`, `page_38`. Examen du camp après : « La couverture d'Hélène, pliée au
carré. Chloé ne la déplie pas. »

### 9 c — Isaure (Npc `IsaurePorte`, événement `isaure_porte` ; `isaure_porte_vue`, `marche_refuse`)

*Isaure se retourne quand Chloé approche. Sans masque. Les cheveux attachés, cette fois. Les quatre
Cœurs dans une sacoche de marin contre sa hanche : ils se mettent à battre quand Chloé approche, et le
cinquième, contre Chloé, répond. Les torches vacillent.*

> Isaure se retourne. Pas de masque. Les cheveux attachés, cette fois : la capitaine du port. Contre sa
> hanche, une sacoche de marin, et dedans quelque chose qui bat.
> Le Cœur de Chloé répond. Cinq cœurs qui battent ensemble, de part et d'autre de dix pas de cendre. Les
> torches vacillent.
> **Isaure** — Je l'ai entendu arriver avant toi, moussaillon. Il bat fort, le dernier. Il a toujours été
> le plus bruyant.
> **Isaure** — Tu as traversé les forges.
> **Chloé** — Elles sont éteintes.
> **Isaure** — … Je sais. On l'a vu d'ici. Les feux, un par un, et puis le grand. Maïa a compté.
> **Maïa** — Sept. Comme Bertille.
> **Isaure** — Brac ?
> **Chloé** — Il est parti voir la mer. De loin.
> **Isaure** — *(un temps)* Il n'a jamais su nager. Douze ans, et je ne lui ai jamais appris. … Je ne lui
> ai jamais rien appris.

*Elle regarde le portail, puis Chloé.*

> **Isaure** — Alors voilà. Il y a cinq Cœurs sur cette île : j'en ai quatre, et tu as le dernier contre
> ta poitrine. Il faut les cinq. Elle a fait ça exprès, et elle a bien fait.
> **Isaure** — Je ne vais pas te le prendre, Chloé. Je l'ai fait une fois, là-haut, et je ne le referai
> pas devant ma fille. Je vais te le demander.
> **Isaure** — Donne-le-moi. Et viens. Ouvre cette porte avec moi, et ce qui dort là-dessous, on le
> tiendra à deux : toi avec ton Lien, moi avec le reste. Plus personne ne mourra de faim au port. Plus
> jamais. Ni au port, ni ailleurs : on aura de quoi exiger. Tu seras la petite-fille qui a fini ce que
> sa grand-mère n'a pas osé finir.
> **Isaure** — Et on la sortira de là. Toutes les deux. Ça, je ne te l'ai pas dit là-haut. Je te le dis
> ici.

*Maïa ne dit rien. Elle regarde Chloé. Caillou s'est levé ; le dino de tête de Chloé et lui se
regardent, museau contre museau, comme aux Monts.*

> **Chloé** — (Elle vient de le dire. Pour Hélène. Pas « je vais la chercher » : « on la sortira ». C'est
> presque pareil. Ce n'est pas pareil.)
> **Chloé** — (Il a peur. Il a peur quand on le réveille de force. Elle veut le réveiller avec une goutte
> d'ambre noir et le « tenir ». Hélène a mis vingt-cinq ans et ses deux mains à ne pas faire ça.)
> **Chloé** — Non.

*Pas fort. Isaure ferme les yeux une seconde.*

> **Isaure** — … Pas fort. Elle non plus ne disait jamais rien fort.
> **Maïa** — Tu vois. Elle a dit non. Comme Hélène.
> **Isaure** — Je vois.
> **Chloé** — Je ne vous laisserai pas ouvrir cette porte, Isaure. Mais je ne vous laisserai pas non plus
> là-dedans toute seule. Ni Maïa. Je ne sais pas encore comment je fais les deux.
> **Isaure** — Tu as les yeux de ta grand-mère, moussaillon. Elle non plus ne savait pas, et elle le
> faisait quand même.

*Elle se tourne vers le portail.*

> **Isaure** — Je n'ouvre pas avant l'aube. Il faut du jour pour descendre là-dedans, et je ne descends
> pas ma fille dans le noir. Tu as jusqu'à l'aube pour changer d'avis.
> **Chloé** — Vous aussi.
> **Isaure** — … Oui. Moi aussi, je suppose.

### 9 d — La lettre (`lettre_isaure_donnee`, si Chloé a `lettre_isaure`)

*Chloé sort l'enveloppe jaunie. « Pour Isaure. » Isaure la reconnaît à l'écriture avant de la
toucher : elle recule d'un demi-pas, puis elle la prend.*

> **Chloé** — Dame Suie l'a gardée un an. Hélène l'a posée sur son établi, la nuit, avant de descendre.
> Elle est pour vous.
> *Isaure prend l'enveloppe. Elle ne l'ouvre pas. Elle la tient contre les Cœurs, dans la sacoche.*
> **Maïa** — Lis-la.
> **Isaure** — En bas.
> **Maïa** — Maman. Lis-la maintenant.
> **Isaure** — Si je la lis maintenant, ma tornade, je ne descends plus. Et il faut bien que quelqu'un
> descende.
> *Elle la glisse dans la sacoche, contre les Cœurs. Elle ne la lâche pas tout de suite.*
> **Isaure** — … Elle écrivait tout. Même ce que je n'ai pas lu.

> **Chloé** — (Elle ne l'a pas lue. Mais elle ne l'a pas rendue non plus. … Jusqu'à l'aube.)

Objet `lettre_isaure` : quitte le sac. Drapeau `lettre_isaure_donnee`. Si Chloé n'a pas la lettre (elle
l'aurait forcément : Dame Suie la donne avec l'antidote), rien.

### 9 e — Maïa (Npc `MaiaPorte`, événement `maia_porte` ; répliques `maia_porte_n`)

*Isaure s'est retournée vers le portail. Maïa se lève de sa pierre et vient jusqu'à Chloé, le manteau
de Joss jusqu'aux chevilles, de la cendre jusqu'aux genoux. Moustique sort du col de Chloé, crie, et
s'envole sur l'épaule de Maïa. Il la mordille. Elle rit.*

> **Maïa** — Aïe. Oui. Moi aussi. … Aïe.
> **Maïa** — Il a maigri ? Il a maigri. Tu ne lui as pas donné de l'encrier, au moins ?
> **Chloé** — Il a mangé celui de Roc.
> **Maïa** — *(elle rit, un vrai rire, le premier du chapitre)* Il fait ça quand il s'inquiète. Roc mange
> des biscuits.
> **Chloé** — C'est ce qu'il a dit.

*Elle redevient sérieuse. Elle regarde sa mère, de dos, devant la porte.*

> **Maïa** — Elle n'a pas dormi. Elle regarde la porte depuis hier soir. Elle a les Cœurs, elle a la
> fiole de la dame en gris, elle a tout. Et elle n'a pas ouvert.
> **Chloé** — Elle attend l'aube.
> **Maïa** — Elle attend. C'est tout ce que je sais. Je suis à côté, et j'attends avec elle. C'est ce que
> j'ai dit que je ferais.
> **Maïa** — Je ne t'ai pas dit que je te rattraperais en marchant ? C'est toi qui m'as rattrapée. En
> marchant aussi. On est nulles, toutes les deux.
> **Chloé** — Tu veux Moustique ?
> **Maïa** — … Non. Garde-le encore. Il a peur du feu, et ici, il n'y a que ça. Et puis s'il est avec
> toi, tu es obligée de revenir.
> **Chloé** — J'allais revenir.
> **Maïa** — Je sais. Mais là, tu es obligée. C'est mieux.

*Elle prend Moustique dans ses deux mains, l'embrasse sur la tête, et le repose sur l'épaule de Chloé.
Il ne crie pas.*

> **Maïa** — Le masque en carton ?
> **Chloé** — Dans la sacoche.
> **Maïa** — Garde-le aussi. Elle a enlevé le sien, mais elle ne l'a pas encore… Elle n'est pas encore
> prête à en mettre un pour rire. Demain, peut-être.
> **Maïa** — Chloé. Demain, à l'aube. Quoi qu'il arrive… je serai de son côté de la porte. Pas contre
> toi. De son côté. Tu comprends la différence ?
> **Chloé** — Oui.
> **Maïa** — Bien. Parce que moi, j'ai mis une nuit entière.

*Caillou pousse Chloé de la corne, doucement. Elle vacille.*

> **Maïa** — Et lui, il dit : « soigne tes dinos, mange quelque chose, et reviens avec ton équipe au
> complet ». Il dit beaucoup de choses, Caillou, quand on l'écoute.
> **Chloé** — (Elle a les yeux de sa mère. Et elle garde la porte avec elle. … Je les ramènerai. Toutes
> les deux. Je l'ai dit en haut ; je le redis en bas.)

Répliques suivantes de Maïa (`maia_porte_n`, si on lui reparle) :

1. « Brac m'a donné une carte de visite. Il y a de la cendre dessus. Je l'ai gardée : c'est la seule
   personne de l'Ombre Noire qui m'ait donné quelque chose au lieu de me le prendre. »
2. « La dame en gris m'a regardée passer. Elle ne m'a rien dit. Elle a juste écrit quelque chose, et
   puis elle a arrêté d'écrire. C'était bizarre. C'était… gentil, je crois ? »
3. « Si tu vas au Havre, dis à Joss que son manteau sent toujours la colle à cuir. Et que c'est le
   meilleur manteau du monde. Dans cet ordre. »
4. *(si `fournaise_garde`)* « Tu as le gros de Brac ? Fournaise ? Il dort, lui aussi ? … Tout le monde dort
   dans ton équipe. C'est reposant. »

Répliques suivantes d'Isaure (`isaure_porte_n`, dos à la porte, elle se retourne à moitié) :

1. « Soigne ton équipe, moussaillon. Je ne veux pas gagner contre des dinos fatigués. Je veux gagner. »
2. « Le cinquième bat trop fort. Ta grand-mère disait que c'était le plus bruyant. Je ne l'ai jamais
   entendu de près. Je ne l'ai jamais vu, non plus : ce jour-là, je regardais ailleurs. »
3. *(si `lettre_isaure_donnee`)* « Je ne l'ai pas lue. Je la sens contre les Cœurs. C'est déjà beaucoup. »
4. « Dis à Anselme… Non. Ne lui dis rien. Je lui dirai moi-même, ou je ne lui dirai pas. »

### 9 f — Le portail (StoryProp `PortailApex`, dialogue `apex_bloque`)

> Le portail de bois, à deux battants. Cerclé de fer, noirci par vingt-cinq ans de fumée. Cinq creux
> ronds dans le bois, à hauteur de main, en étoile. Quatre sont vides, pour l'instant. Le cinquième
> aussi.
> **Chloé** — (Cinq creux. Elle a quatre Cœurs, j'en ai un. Et une fiole d'ambre noir pour « tenir ».)
> **Chloé** — (Demain, à l'aube.)
> *(À suivre… La Terre des Apex.)*

Drapeau : `apex_bloque` (le chapitre 9 ouvrira : `apex_ouvert`). Fin du chapitre 8 : « La suite de
l'aventure arrive bientôt ! » si le ch. 9 n'existe pas encore.

Garde-fous de la scène : Isaure ne dit **jamais** « je vais chercher Hélène » ; elle dit « on la sortira
de là », au futur, dans son marché (c'est un marché, pas une confidence). Pas de combat. Maïa ne choisit
pas entre les deux : elle est « du côté de sa mère de la porte, pas contre Chloé ». Personne ne pleure.
Caillou éternue. La porte ne s'ouvre pas.

---

## Autour : Roc, Bertille, Joss, Léonce (dialogues par état)

**Roc au Cabinet** (`roc`, dans `CieuxArche.roc()` ou un `VolcanRoc.roc()`), dans l'ordre :

- `roc_trex_legende` (question, dès `masque_tombe` ; voir TOPICS) : **Chloé** — « Un T-Rex ne voit pas
  ce qui ne bouge pas, c'est vrai ? » **Roc** — « Une légende. Cours. » *(il tourne une page)* « … Hélène
  l'a testée. Elle n'a pas couru. Il l'a regardée pendant trois semaines. Ne teste pas, Chloé. Cours.
  Ou ne cours pas. Fais comme elle. Non : cours. »
- `roc_suie_carnets` (dès `suie_partie`) : « La dame en gris est venue. Ici. Elle a posé une caisse sur
  le bureau : les carnets d'Hélène. Tous. Ceux de l'ambre forcé, ceux qu'on avait pris il y a douze ans.
  Elle a dit « Je refais mes tables », elle a regardé la couveuse, et elle est repartie. … Je n'ai rien
  compris. J'ai fait du thé. Elle n'en a pas voulu. » Puis : « Elle a laissé un mot sur la caisse :
  « Pour le professeur Roc, qui a une clé. » Je ne sais pas si c'est un compliment. » (`carnets_rendus`.)
- `roc_brac_parti` (dès `brac_parti`) : « Brac est parti ? Voir la mer ? … Il est passé par le port. Il
  a demandé à Léonce où on voit la mer « de loin ». Léonce lui a montré la jetée. Il s'est assis au bout
  avec ses trois bêtes, et il a mangé un sandwich. Il y est peut-être encore. »
- `roc_sceau_volcan` (dès `sceau_volcan`) : « Le Sceau du Volcan. Le dernier. … Cheminée t'a laissée
  passer ? Il m'a mangé deux chapeaux, à moi. Hélène disait qu'il aimait le feutre. » Puis, le Cœur :
  « Le cinquième. Le plus bruyant, elle disait. Et elle en a quatre, là-haut, devant la porte. Avec ma
  Maïa. … Ne la laisse pas ouvrir, Chloé. Et ne la laisse pas toute seule non plus. Je sais : c'est
  deux choses. Hélène aussi faisait toujours deux choses. »

**Bertille aux Monts** (`bertille_forges_eteintes`, dès `grande_forge_eteinte`) : « Les feux se sont
éteints, au pied du volcan. Un par un, et puis le grand. J'ai recompté deux fois : zéro. Ça ne m'était
pas arrivé depuis l'hiver où elle est descendue voir. … Tiens. Une soupe. Tu as une tête à soupe. »

**Joss au Havre** (`joss_volcan`, dès `porte_arrivee`) : « Tu l'as vue ? Maïa ? Elle a toujours mon
manteau ? … Il sent la colle à cuir, je sais. Dis-lui que j'en ai cousu un autre. À sa taille. Avec une
poche pour le piaf. »

**Léonce à Port-Ambre** (sur le ponton, dès `grande_forge_eteinte`) : « Le poisson ne revient pas plus
vite quand on le regarde. Mais on le regarde quand même. » / « Le rouquin est assis au bout de la jetée.
Il regarde la mer. De loin. Il ne dérange personne : il a l'air d'un phare qui boude. »

**Questions** (`TOPICS` du chapitre, pour Roc ; Maïa à la porte) : `trex` « Un T-Rex ne voit pas ce qui
ne bouge pas, c'est vrai ? » (dès `masque_tombe`, jusqu'à `trex_magma_battu`) ; `lave` « Comment on
traverse la lave ? » (dès `coulees_arrivee`, jusqu'à `lave_franchie` : Roc : « Avec un dino qui a le cuir
pour : de la pierre, ou du feu. Bastion, un cuirassé, un grand théropode qui ne craint pas le feu. Pas
toi. Surtout pas toi. » + le texte dit qui dans l'équipe) ; `forges` « Qu'est-ce qu'on fait des
forges ? » (dès `forges_arrivee`, jusqu'à `grande_forge_eteinte` : Roc : « On les éteint. Hélène les a
comptées ; toi, éteins-les. Les dinos sauront comment : ils ont vu comment ça s'allume. ») ;
`antidote` « À quoi sert l'ambre clair ? » (dès `antidote_ambre` : Roc : « Une goutte, et les veines
s'effacent. D'un coup. La dame en gris a fait ça ? … Garde-la pour quand tu n'auras pas le temps de
parler. Elle a dit ça ? Elle a raison. C'est agaçant. »).

**Objectifs** (`story/volcan_objectives.gd`) : la Descente de Cendre → les champs de cendres (le
premier corrompu) → les forges (éteindre les trois petites : « les dinos savent comment ») → Brac → Dame
Suie et la grande forge → les coulées (un dino de pierre ou de feu en tête : qui, où) → le sanctuaire de
Magma (astuce : l'Eau et la Pierre) → le 5e Cœur → la porte du cratère (Isaure) → « Vers la Terre des Apex
(bientôt) » ; en secondaire : les pages 35 à 38 (une direction chacune ; la 36 « sur le dos d'un dino de
pierre ou de feu »), Roc au Cabinet (les carnets, le Sceau), Bertille, Léonce au port.

**Équilibrage** (pour l'agent MÉCANIQUES, niveaux 42-48 du bestiaire ; équipe vers 42 à l'arrivée,
44-45 chez Brac, 45-46 au T-Rex) : les trois corrompus des forges à 43/43/44 (règle normale, un par un,
on peut soigner entre) ; Brac à 44/44/45/46 (Fournaise `long_calm`, sans soin entre ses dinos : un vrai
test) ; le T-Rex de Magma à 48 (combat d'honneur, équipe reposée, type Feu : l'Eau et la Pierre le
touchent fort ; l'équipe doit avoir un dino d'Eau ou de Pierre pour que ce soit jouable sans mur) ;
Fournaise 46 s'il reste ; Numéro 7 (Saichania) 43 s'il est capturé ensuite.

---

## Personnages, doublures, images nécessaires (récapitulatif pour les agents CARTE et IMAGES)

| Quoi | Détail |
|---|---|
| Chloé | planches existantes ; **à cheval sur un dino de pierre/feu pour la lave** : réutiliser la pose « montée » de la nage (`chloe_nage` ?) si le format le permet, sinon `chloe_lave` (profil, face, dos) |
| Moustique | sur l'épaule (existant, ch. 7) ; « caché dans le col » = seulement le bec (petite variante ou simple décalage) |
| Brac | planche existante ; pose assise « sur une cage » (plus) ; marche en s'éloignant |
| Dame Suie | planche existante ; variante **sans lunettes** (face) ; ses gants sur l'établi (prop) |
| Mandragore | Therizinosaurus (existant), attelé au traîneau sur roues |
| Léonce | masque d'os sur le genou : planche de sbire existante + pose assise ; à Port-Ambre sans masque (pêcheur existant ?) |
| Isaure | `isaure_sans_masque` (ch. 7), cheveux attachés si une variante est faite ; de dos devant la porte |
| Maïa | `maia_arche` (manteau de Joss) ; assise sur une pierre |
| Caillou | Tricératops couché / debout (existant) |
| T-Rex de Magma | **nouvelle espèce**, Alpha : profil, face, dos ; rouge sombre, fissures orange sur le dos, fumée aux naseaux ; bouche fermée au repos |
| Daspletosaurus | nouvelle espèce (profil, face, dos) + `_corrompu` (Fournaise) |
| Styracosaurus, Saichania | nouvelles espèces (profil, face, dos) + `_corrompu` |
| Allosaurus, Majungasaurus corrompus | planches `_corrompu` si elles n'existent pas |
| Plaques numérotées | petit prop `plaque_fer` (3, 7, 11, 12, FOURNAISE) ou simple texte |
| Sols | `cendre`, `roche_noire`, `lave` (animée si possible), `croute_refroidie`, `obsidienne` |
| Props forges | `forge_allumee`/`forge_eteinte`, `grande_forge_allumee`/`grande_forge_eteinte`, `cage`, `cage_ouverte`, `cage_grande`, `fut_ambre_noir`, `enclume`, `barricade`/`barricade_tombee`, `auvent`, `soufflet`, `marmite`, `etabli_suie`, `gants_gris`, `traineau_roues`, `masque_os_sol`, `pierre_plate` |
| Props sanctuaire / porte | `vasque_source`, `autel_magma` (fendu après), `lave_paroi`, `coque_lave`, `portail_apex`, `torche`, `camp_helene` (lanterne, couverture, cairn), `boite_fer` (existant) |
| UI | `sceau_volcan.png` (ambre rouge sombre, flamme, fougère), `coeur_ambre` (existant), `antidote_ambre.png` (fiole d'ambre clair), `lettre_isaure.png` |
| Fond de combat | `assets/art/battle/volcan.jpg` |
| Ambiances | `champs_cendres`, `forges_ombre` (ronflement de forge, puis silence), `coulees_lave`, `sanctuaire_magma`, `porte_cratere` ; musiques : réutiliser `OMBRE_MUSIC` (forges), la musique des Alphas (T-Rex), **silence** à la porte (torches, vent) |

---

## Autocritique (trois passes)

**Passe 1 (surprendre).** Le chapitre tel que planifié risquait d'être une liste : forges, Brac, Suie,
T-Rex, Isaure. Les rebonds ajoutés : (1) les corrompus **numérotés** (Brac n'a plus de noms ; Fournaise
est le seul nommé : « il l'aime bien, celui-là ») ; (2) la barricade qui tombe sous les cornes des dinos
apaisés, rendez-vous qu'ils se sont donné ; (3) Brac a enfin ses cartes de visite, et la seule qu'il a
donnée, c'est à Maïa, qui a dit merci ; (4) Dame Suie n'a pas éteint la forge pour voir si Isaure
reviendrait chercher la fiole ; (5) la lettre d'Hélène, posée il y a un an sur l'établi de Dame Suie,
gardée un an sans être ouverte ; (6) le T-Rex « la voit très bien » ; (7) le masque d'obsidienne taillé
dans un éclat ramassé le dernier jour où Hélène et Isaure ont ri ; (8) Isaure dit « on la sortira de là »
dans son marché, pas en confidence ; (9) « Si je la lis maintenant, je ne descends plus. »

**Passe 2 (émouvoir sans cruauté).** Vérifié : aucun dino ne souffre (ils grondent, tremblent, dorment) ;
Brac n'est jamais humilié par Chloé (une phrase, « Elle n'est pas rentrée non plus ») et personne ne rit
de lui quand il est amer ; Dame Suie ne demande pas pardon et Chloé ne le lui offre pas ; Isaure ne pleure
pas, Maïa ne pleure pas (elle rit une fois, et c'est le premier rire du chapitre). Les moments émus
tiennent chacun en moins de cinq répliques et sont suivis d'une drôlerie (le sandwich de Brac, « le
thé » de Roc, Caillou qui éternue).

**Passe 3 (crédibilité de Dame Suie et de Brac).** Dame Suie bascule sur **trois** observations
(Belladone, les dormeurs, Maïa), pas sur un argument : c'est une scientifique qui corrige une table
quand les mesures le disent trois fois. L'antidote existe parce qu'elle l'a fait « par curiosité » après
Aconit (pas par bonté soudaine). Elle rend les carnets parce qu'elle « a travaillé » et que le travail
est fini : logique de chimiste, pas de repentie. Brac reste Brac : vexé, bruyant, il garde ses dinos,
choisit la mer « de loin », et jure. Son unique moment amer (douze ans, « rentrer », les cartes sans
adresse) explique sa fidélité sans la rendre noble. Faiblesses connues : la révélation de l'obsidienne
(page 35) est forte et pourrait sembler trop « écrite » ; elle est volontairement laissée en pensée de
Chloé et proposée à Greg. La mécanique de la jauge de chaleur est une suggestion, pas une exigence.

