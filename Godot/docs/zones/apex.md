# Terre des Apex (carte) — chapitre 9 et épilogue

> Agent CARTE, 19/10. Les deux zones `terre_apex` et `coeur_apex` (`regions/apex/`), générées par
> `tools/zones/apex_terre.gd` et `apex_coeur.gd` (peinture commune `apex_canvas.gd`, qui reprend celle du volcan sans
> lave ni cendre ; décor `apex_decor.gd` ; vérifications `apex_verif.gd`) ; lieux nommés dans `story/apex_places.gd`
> (`ApexPlaces`). **Le plan s'appelle `apex_<x>`, la zone porte son vrai nom** : construire avec
> `--script res://tools/build_zone.gd -- apex_terre --force` (idem `apex_coeur`) ; chaque plan imprime ses
> vérifications (« tous les lieux sont bons »). Le raccord de la porte est dans `tools/zones/volcan_porte.gd` ; les ajouts
> de l'épilogue dans `tools/zones/cabinet.gd` et `port_ambre.gd` (régénérés, ids gardés : seuls les nœuds ajoutés au diff).
> Test sans fenêtre : `tests/apex/test_carte_apex.gd` (GdUnit4).

## Le parti

La caméra regarde le nord : tout ce qui est haut doit être derrière (au nord) ce qu'on regarde, rien de haut au sud d'un
chemin. Or le portail est dans la paroi nord (25 m) de `porte_cratere` : si la Terre des Apex continuait vers le nord,
l'aperçu de la zone voisine au-delà de son bord sud montrerait cette paroi juste derrière Chloé, et la caméra serait dedans.
**On entre donc dans le cratère par son bord NORD**, sur la corniche : le cratère est en contrebas, vers la caméra (toutes ses
parois lui font face). Aperçus : de la porte, le cratère est derrière sa paroi (caché) ; du cratère, le bas de la porte est
au-delà du bord nord, plus bas que la corniche (caché aussi). Même chose entre le cratère et le fond : l'entrée du Cœur est à
son bord nord, et ce qui dépasse au sud du cratère (le haut du Cœur) est loin de toute caméra.

- **`terre_apex` — La Terre des Apex** (80 × 70) : on arrive par le bord nord (x 39-41) sur **la corniche** (16,2 m, comme
  l'esplanade de la porte ; « le bord ») : Isaure, Maïa et Caillou quelques pas devant (partis à `apex_arrivee`), le **cairn**
  d'Hélène et la **page 39** à gauche de l'entrée contre la paroi, le **Roi** perché sur la crête à droite (26 m, hors
  d'atteinte ; parti à `apex_fini`). La corniche fait le tour du nord et descend en pente douce le long de la **paroi ouest**
  (0,5 m par case, le plancher 4 à 12 m plus bas) ; son **bras est** finit en à-pic sur le plancher. Le **plancher** (4 m) :
  roche, veines d'ambre, cristaux allumés, les **blocs des géants** (1 sous la paroi ouest, 2 au pied de la paroi nord, 3 au
  bout du bras est de la corniche, 4 le petit, au sud-est). Au milieu, **le trou** (le fond, 5,5 m de creux : le bloc vu d'en
  haut, puis ses restes, puis le Souverain couché) ; une **rampe** y descend le long de son flanc est, la sortie vers le Cœur à
  son pied. Le sentier (la spirale) : l'entrée, la corniche vers l'ouest, la pente ouest, le sud du plancher, l'est, la rampe.
  Le rebord sud est bas (2 m au-dessus du plancher : la caméra voit par-dessus).
- **`coeur_apex` — Le Cœur des Apex** (50 × 40) : on arrive par le bord nord (x 41-43) ; un **couloir** descend le long de la
  paroi est (0 → −3 m) jusqu'à la **salle ronde** (34 × 25, à ciel ouvert ; murs de la moitié nord à 6 m, face à la caméra,
  ceux de la moitié sud à 1,8 m au-dessus du sol : la caméra voit dedans). Dans la moitié nord, **le bloc** (le Souverain et
  Hélène dedans) ; devant, Isaure, Maïa, Caillou ; à l'ouest, **le rocher** derrière lequel Maïa tire sa mère et Hélène. Les
  états, à chaque chargement : avant l'éveil (le bloc, les trois devant) ; éveillé (`souverain_eveille` : les restes du bloc,
  lui contre la paroi au nord-est, corrompu ; derrière le rocher Isaure qui tient Hélène — une image `isaure_helene` jusqu'à
  `helene_reveillee`, puis Isaure et Hélène assises —, Maïa, Caillou sur la ligne) ; apaisé (`souverain_apaise` : il est
  couché au milieu, devant les restes du bloc) ; après `apex_fini`, seulement lui et les restes.
- **La porte** (`porte_cratere`, ch. 8) : une sortie `VersTerreApex` devant le portail, fermée jusqu'à `apex_ouvert` (sinon le
  dialogue `apex_bloque` et Chloé recule) ; on en ressort sur `DepuisApex` ; Isaure, Maïa et Caillou partent à `apex_ouvert` ;
  le portail prend son image ouverte (`portail_apex_ouvert`) et les torches la leur, éteinte (`torche_eteinte`), une fois ces
  images listées par `world/prop.gd` ; la défaite contre Isaure : `DevantCamp`.
- **Le Cabinet** (épilogue) : Hélène au fauteuil de Roc dès `apex_fini` (`HeleneAssise`, ensuite le post-game), la petite table
  devant (`TableThe`), la tasse bleue dessus à `tasse_bleue`, Isaure à la table de `tasse_bleue` à `epilogue_port`, la caisse
  des carnets sur le bureau dès `carnets_rendus`.
- **Port-Ambre** (épilogue) : le soir du thé (`tasse_bleue` → `epilogue_cabinet`), Maïa sur la marche du Cabinet, Caillou en
  travers de la ruelle ; le lendemain (`epilogue_cabinet`), la jetée : tout le village sur le quai au pied du ponton, Hélène au
  bras de Roc devant eux, Isaure à sa barque, Dame Suie au fond, Brac au bout (ch. 8) et Mastoc à côté, Cabosse et Grognon sur
  le quai. Après `epilogue_fini` restent Isaure, Dame Suie, Cabosse et Grognon ; Mastoc part (sur le ponton, il barrerait le
  chemin de la barque de Maïa).

## Règles que les plans tiennent (et que les vérifications impriment)

- Chaque lieu de l'histoire atteint à pied depuis l'entrée, sur le relief **et** avec les pieds pleins des décors pour murs
  (un bloc ne ferme pas la spirale) ; le fond du trou, le bloc vu d'en haut, le perchoir du Roi, les crêtes : hors d'atteinte.
- Rien de l'histoire hors d'atteinte (sauf ce qui est fait pour : le Roi perché, le bloc et le Souverain vus d'en haut).
- Aucun décor plein sur un chemin ; rien ne flotte (`cieux_pieds.gd`) ; les **empreintes** des images à venir (pieds proposés
  dans le patch de `world/prop.gd`) tiennent sur un sol de niveau, praticable, hors chemin.
- Vérifié à blanc avec les images d'IMAGES (entrées proposées de `prop.gd`, script du scratchpad `ch9/carte/avec_images.gd`) :
  « tous les lieux sont bons », les blocs posés (s'enfoncent de 0 à 18 cm), rien ne flotte.
- Pas de lave ni de cendre ; les **veines d'ambre** sont une couche de couverture (`veines_ambre.png`), dosée case par case le
  long de lignes (méta `veines` de la zone, `regions/apex/<zone>_veines.res`) ; des cristaux allumés les jalonnent. Sols :
  `roche_apex` (cratère), `roche_apex_fond` (le Cœur) ; sentiers dans l'autre des deux. Pas de Vol (méta `vol_interdit` et son
  texte) ; fond de combat `battle/apex.jpg` ; ambiances `terre_apex`, `coeur_apex` ; pas de musique dessinée (silence).
- Doublures tant que `world/prop.gd` ne liste pas les images (la zone est reconstruite ensuite) : le bloc = `crane_geant_desert`,
  ses restes = `cristaux`, les géants = `squelette_geant` / `os_geant`, le cairn = `pierre_plate` ; `isaure_helene`,
  `tasse_bleue`, `caisse_carnets` absents d'ici là ; Hélène = sa planche `helene.png` (dessinée) ; Firmin = `sbire` (sa planche
  sans masque reste à dessiner).
