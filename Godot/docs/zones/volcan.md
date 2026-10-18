# Plaine Volcanique (carte) — chapitre 8

> Agent CARTE, 17-18/10. Les cinq zones `champs_cendres`, `forges_ombre`, `coulees_lave`, `sanctuaire_magma`,
> `porte_cratere` (`regions/volcan/`), générées par `tools/zones/volcan_champs.gd`, `volcan_forges.gd`,
> `volcan_coulees.gd`, `volcan_sanctuaire.gd`, `volcan_porte.gd` (peinture commune `volcan_canvas.gd`, décor
> `volcan_decor.gd`, vérifications `volcan_verif.gd`) ; lieux nommés dans `story/volcan_places.gd` (`VolcanPlaces`).
> **Le plan s'appelle `volcan_<x>`, la zone porte son vrai nom** : construire avec
> `--script res://tools/build_zone.gd -- volcan_champs --force` (idem `volcan_forges`, `volcan_coulees`,
> `volcan_sanctuaire`, `volcan_porte`) ; chaque plan imprime ses vérifications (« tous les lieux sont bons »).

## Le parti

Les zones montent vers le nord, vers le volcan (la caméra regarde le nord : le flanc du volcan, la face de la
plateforme des forges, les terrasses de la porte lui font face ; rien de haut ne cache un chemin).
- **`champs_cendres` — Les Champs de Cendre** (90 × 70) : la Descente de Cendre (la crête de l'Arche, 14,4 m à son
  bord nord) arrive par le bord sud (x 44-46) et continue en **versant de cendre** jusqu'à la plaine (6,4 m, rangée 48) :
  une pente régulière (0,38 m par case : la caméra voit par-dessus), le sentier en lacets. Au pied : le premier feu,
  le panneau d'Hélène. La plaine : cendre en bosses, troncs calcinés, fougères de cendre (les Styracosaurus, de jour) ;
  à mi-chemin, les **traces** (déclencheur `Traces`) autour de la **pierre plate** (`PierrePlate`), le creux de Caillou
  et ses roseaux mâchés ; plus au nord, **Numéro 3** au pied d'une cage ouverte (`CageOuverte`), un fût renversé
  (`FutRenverse`) ; au nord-est, la bosse d'une vieille coulée refroidie (croûte : les Saichania). Bord nord : les forges.
- **`forges_ombre` — Les Forges de l'Ombre** (80 × 60) : le camp dans un creux de cendre au pied du volcan (6,4 m).
  Léonce et deux masques d'os près des fûts (partis à `grande_forge_eteinte`), les trois petites forges
  (`Forge1` ouest, `Forge2` nord-ouest, `Forge3` est), chacune gardée par son numéroté (`Numero7` Saichania,
  `Numero11` Allosaurus, `Numero12` Majungasaurus, corrompus, partis une fois leur forge éteinte), cages (surtout
  ouvertes), fûts d'ambre noir, tentes, palissades. Au fond, une **plateforme de roche** (9,4 m, face à la caméra) :
  une **encoche** taillée dans sa face y monte (3 cases), fermée par la **barricade** (`Barricade`, partie à
  `barricade_tombee` ; ses cages tombées à côté). Sur la plateforme, en haut de l'encoche, le camp de **Brac**
  (`BracVolcan`, son feu, sa marmite, Mastoc, Cabosse, Grognon, **Fournaise** dans un enclos de palissades dont
  la clôture avant s'ouvre à `brac_volcan_vu`, sa tente ; `MasqueBrac` dans la cendre après `brac_parti`) ; au fond,
  la **grande forge** (`GrandeForge`, 7 m) et le coin de **Dame Suie** (`SuieVolcan`, `Etabli`, ses fioles, Mandragore,
  le traîneau ; ses gants sur l'établi après `suie_partie`). Sortie nord (depuis la plateforme) vers les coulées,
  **fermée jusqu'à `suie_partie`** (dialogue `coulees_fermees`).
- **`coulees_lave` — Les Coulées de lave** (80 × 60) : roche noire, flanc du volcan au nord (16 m). Au sud, l'arrivée
  (9,4 m), un feu, les coulées refroidies (croûte : Saichania de jour). **La première coulée** traverse toute la zone
  (rangées ~40-43, 3 à 4 cases de large) : personne ne passe à pied ; son déclencheur `PremiereCoulee` et le panneau
  sur la rive sud. Au-delà (sur un dino de pierre ou de feu) : deux bras de lave descendus du flanc, un **lac de lave**
  et son **rocher** au milieu (page 36 et une boîte en fer : seulement à dos de dino), les Daspletosaurus la nuit ; la
  **faille** du sanctuaire au fond de son encoche dans le flanc (`Faille`, CaveMouth ; la gravure `GravureFaille` à
  côté) ; au nord-est, le **chemin du cratère**, une entaille qui monte au bord nord (12,6 m) : **la lave qui se retire**
  en remplit le bas (rangées 4-10) et sa sortie est fermée tant que `lave_retiree` est faux (dialogue `cratere_bloque`).
- **`sanctuaire_magma` — Le Sanctuaire de Magma** (48 × 42, intérieur, lumière chaude, pas de musique) : le couloir de
  la faille monte du bord sud dans une salle ronde d'obsidienne (28 × 22) ; un anneau de lave le long des murs (pas à
  l'entrée) ; la vasque (source chaude) à l'entrée, l'**autel** au milieu (`AutelMagma`, fendu après
  `trex_magma_battu`), la paroi de verre où coule la lave au nord, le **T-Rex de Magma** devant (`TrexMagma`, Alpha) ;
  la page 35 dans une fente derrière l'autel, **seulement après `trex_magma_battu`** ; des cristaux d'ambre autour.
  Les murs de la moitié sud sont bas (la caméra voit dans la salle). Pas de jauge de chaleur ici (méta `chaleur` 0).
- **`porte_cratere` — La Porte du Cratère** (50 × 40) : le haut du chemin du cratère (12,6 m) monte en lacets (deux
  rampes : à l'est puis à l'ouest, deux terrasses face à la caméra, la croûte qui fume encore le long du chemin)
  jusqu'à l'esplanade (16,2 m) devant la paroi du cratère : le **portail** de la Terre des Apex (`PortailApex`, 7 m)
  entre ses deux torches, **Isaure** de dos face à lui (`IsaurePorte`), **Maïa** à côté (`MaiaPorte`), **Caillou**
  derrière (`CaillouPorte`), le **camp d'Hélène** contre la paroi (`CampHelene`) et la page 38 sous son cairn. Pas de
  musique (les torches, le vent).

Raccords (centres des sorties alignés pour l'aperçu au-delà des bords, hauteurs égales au bord) : Arche (x 19-21, nord,
14,4 m) ↔ champs (x 44-46, sud) ; champs (x 44-46, nord, 6,4 m) ↔ forges (x 39-41, sud) ; forges (x 55-57, nord, 9,4 m)
↔ coulées (x 39-41, sud) ; coulées (x 63-65, nord, 12,6 m) ↔ porte (x 23-25, sud) ; la faille (intérieure) ↔ sanctuaire
(x 23-25, sud). Les arrivées s'appellent `Depuis<Zone>` (`VolcanPlaces.SPAWN_*`).

## La lave (contrat avec MÉCANIQUES : `scratchpad/ch8/contrat_lave.md`, `actors/lava.gd`)

- Ses cases sont du sol **`rock`** (les seules de ces zones), enfoncé de 0,25 m (pas de falaise), listées dans la méta
  **`lave`** de la zone : une `Image` L8, un pixel par case, blanc = lave (`regions/volcan/<zone>_lave.res`). C'est
  `Lava`/`LavaField` qui arrête Chloé à pied (couche 32) et la fait passer à dos d'un dino « Cuir de feu ».
- **`lave_retrait`** (même format, `coulees_lave_lave_retrait.res`) : le bas du chemin du cratère ; sol ordinaire
  dessous (la rampe), un mur pour tous jusqu'à `lave_retiree`.
- Ce qu'on voit : une couche de couverture « lave » (`lave.png`) sur les deux ; la croûte refroidie sur les rives
  (2 cases) et les coulées refroidies ; pas de cendre à moins de 3 cases de la lave.
- Méta `vol_interdit` (+ `vol_interdit_texte` : la fumée) sur les cinq zones : le Vol sauterait la lave et la
  barricade. Fond de combat `battle/volcan.jpg` ; ambiances = l'identifiant de la zone.

## Règles que les plans tiennent (et que les vérifications impriment)

- Chaque lieu clé atteint **à pied sans toucher la lave** depuis l'arrivée, ou, au-delà de la première coulée,
  **seulement à dos de dino** (le rocher de la page 36, la faille, la gravure, le pied du chemin du cratère) ; la sortie
  vers la porte **seulement une fois la lave retirée**.
- La barricade **ferme** l'encoche tant qu'elle est là (son pied plein, plus la largeur de Chloé) : la plateforme,
  Brac, Dame Suie et la sortie vers les coulées sont coupés.
- Rien de l'histoire sur la lave (personnes, dinos, pages, panneaux, galets, arrivées) ; aucun décor solide sur un
  chemin (sauf la barricade, faite pour) ; rien ne flotte (mesure de `cieux_pieds.gd` ; les choses posées sur un meuble,
  `foot` négatif, comme les gants, à part).
- Les décors dessinés par IMAGES (`forge_allumee`… `camp_helene`) sont posés **dès que `world/prop.gd` les liste**
  (entrées proposées dans `scratchpad/ch8/patch_carte.md`) ; d'ici là, des doublures (`autel`, `phare_ruine`,
  `rempart_eboulis`, `porte_vents`, `lanterne`, `natte_fouilles`…). Avec les entrées proposées, les cinq zones ont été
  construites à blanc (`scratchpad/ch8/carte/avec_images.gd`) : « tous les lieux sont bons », rien ne flotte.
- Personnages assis : les planches de pose (`leonce_assis`, `brac_assis_cage`, `maia_pierre`) ont la cage et la pierre
  dans le dessin : la carte ne pose ni cage sous Brac ni pierre sous Maïa ; les PNJ sont debout (`sbire`, `brac`,
  `maia_arche`) jusqu'à ce que les scènes les assoient.
