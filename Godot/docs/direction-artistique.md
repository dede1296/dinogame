# Direction artistique — Ambrelune (Godot)

Objectif : **l'Ambrelune actuel, avec une qualité de production supérieure**. Même univers,
mêmes personnages, mêmes couleurs ; plus de détail, plus d'animation, plus d'effets.

**Rendu 2,5D** (depuis le 2026-09-26) : un sol 3D en relief, sur lequel les images 2D (décor,
personnages, dinos) tiennent debout face à la caméra, légèrement inclinée. Conséquences pour les
images :
- tout est dessiné **de face, vu légèrement du dessus** (comme les arbres actuels), jamais en
  isométrique : une façade de maison est parallèle à l'écran ;
- les personnages ont 4 directions ; les dinos un profil et une planche face/dos ;
- pas d'ombre peinte au sol dans les images : les ombres sont calculées (soleil, lune) ;
- les très grands éléments (arbres) deviennent transparents quand ils cachent Chloé.
- le décor debout reçoit un éclairage « arrondi » (volume) et une ombre de contact au pied ;
  les parois de falaise ont leur propre texture (`assets/art/ground/falaise.png`, raccordable,
  1 répétition ≈ 2,2 m) ; l'eau lit la hauteur du sol (profondeur, écume sur la rive).
- **Monde ouvert** : les bords d'une région sont naturels, jamais un mur invisible. Montagnes en
  **corniches** de 2 niveaux (2,4 m) plutôt qu'en pente douce (une longue pente se lit comme un
  talus flou) ; forêt dense (arbres posés automatiquement, **buissons le long des chemins** pour
  ne rien masquer) ; mer avec plage de sable.
- **Entrées de grotte** : un trou sombre aux bords irréguliers, au fond d'une encoche creusée
  dans une vraie colline, jamais une porte posée dans le vide. Les portes d'ambre de l'histoire
  sont prises dans une falaise ou une encoche du relief.
- **Falaises** : roche plus grise et plus sombre que les chemins (ocre), avec une ombre au pied
  de chaque paroi, pour ne jamais confondre un chemin et un flanc de colline. Les murs de
  collision couvrent toute la profondeur de la paroi dessinée : personne ne se tient dessus.
- **Carte du monde** : style carte d'exploratrice sur papier (couleurs douces du sol, relief
  ombré depuis le nord-ouest, courbes de niveau brunes, bois en petites couronnes, trait de rive) ;
  l'inexploré reste papier blanc, avec un bord brun irrégulier comme brûlé.

## Style

- Illustration cartoon **peinte à la main** : contours **brun foncé** nets, ombrage peint doux,
  **lumière dorée venant du haut à gauche**, ambiance chaleureuse et lisible (jeu pour Chloé :
  amical, jamais effrayant).
- Vue **top-down trois-quarts** (on voit le dessus et la face des objets), comme la version Phaser.
- Personnages en **proportions chibi** (~2,5 têtes), expressifs.
- Dinos : silhouettes claires, couleurs naturalistes légèrement saturées, ventre clair,
  yeux expressifs. Les familles restent reconnaissables (raptor, cératopsien…).
- Décors : végétation préhistorique (fougères arborescentes, araucarias, fougères), fleurs
  roses, jaunes et violettes, pierres grises, bois brun chaud.

## Palette de référence

| Rôle | Couleur |
|---|---|
| Fond d'interface (ardoise) | `#1b1f28` |
| Accent ambre (bordures, titres) | `#c98a2a` / clair `#fac259` |
| Texte clair | `#f5eddb` |
| Herbe | verts chauds `#5f9a36` → `#8fbf45` |
| Chemins | ocre `#c79a5a`, bords plus sombres |
| Eau | `#22607a` (profond) → `#54a0a0` (bord), écume `#edf2db` |
| Contours | brun `#2a180c` |

Chloé : cheveux auburn en queue de cheval (barrette sarcelle), t-shirt sarcelle, gilet
d'explorateur kaki, short olive, bottines brunes, sac ambre.
Maïa : peau brun chaud, cheveux bouclés noirs, bandana rouge, débardeur moutarde, short
cargo marine, corde à l'épaule.

## Production des images (nano-banana)

- Toujours décrire le style ci-dessus dans le prompt ; pour un nouveau personnage, **éditer
  une planche existante** (référence de style) plutôt que partir de zéro.
- Fond **magenta pur `#FF00FF`** uni, sans ombre au sol ni texte → détourage par
  `tools/process-art.mjs` (décontamination des bords incluse).
- Planches de personnages : grille **4×4** (bas, gauche, droite, haut × 4 pas).
  Planches de dinos : **2×3** (3 pas de marche ; repos, repos 2, attaque), profil **vers la droite**.
  **Un dino ne se couche que s'il dort** : les poses de repos sont debout (une pose couchée ou
  assise ne sert qu'au sommeil) ; l'attente alterne des poses debout, la respiration fait le reste.
  **Nouvelle espèce : donner son anatomie réelle dès la première demande** (plan du corps,
  pattes / nageoires / ailes, cou, queue, tête et signes distinctifs), dans le prompt comme dans
  la consigne d'un agent, et vérifier la planche reçue contre elle. Une espèce proche sert de
  référence de **style et de grille**, jamais de corps : une recoloration n'est au mieux qu'un
  remplaçant provisoire, à inscrire dans « À refaire » (règle de l'utilisateur, 28/09).
  Planches de décor : objets bien séparés (détection automatique, ordre de lecture).
- Textures de sol : vues de dessus, sans ombre directionnelle, rendues raccordables par l'outil.
- Résolution : générer en 2K, exporter à **2× la taille d'affichage** (le jeu est pensé en
  1280×720 et affiché à ~2× sur le S25 Ultra) ; le mipmapping gère les réductions.

### Sans crédits nano-banana : ComfyUI (règle de l'utilisateur, 28/09)

Si nano-banana répond 402 / `RESOURCE_EXHAUSTED`, on ne s'arrête pas : on passe sur **ComfyUI en
local** (127.0.0.1:8188, gratuit) en respectant au maximum la direction artistique — SD 1.5 + LoRA
`ambrelune_style` (0,8) + IPAdapter (0,6) sur une image du jeu de la même famille, img2img depuis
un guide (rendu Blender, croquis, image voisine) plutôt que texte seul ; on compare au style du jeu
et on refait si ça s'en écarte. À défaut, un repli sans génération (image composée à partir d'une
autre). **Tout ce qui est fait ainsi est inscrit dans la liste ci-dessous**, à refaire avec
nano-banana quand les crédits reviennent (recharger sur ai.studio).

### À refaire avec nano-banana

Ce qui a été fait par ComfyUI, en repli, ou par un nano-banana qui a échoué. Ajouter une ligne à
chaque nouveau repli ; retirer la ligne une fois refait.

| Élément | Fichiers | Fait aujourd'hui par | À faire avec nano-banana |
|---|---|---|---|
| Corde de falaise, nid de tortues vide (29/09) | `generated_imgs/derived-finition-corde-nid.jpg` → `props/corde_falaise.png`, `nid_tortue_vide.png` | nano-banana a peint une ombre portée floue sous les deux objets et a refusé deux fois de l'effacer : bande basse repeinte en magenta à la main | Redemander sans ombre portée (le résultat actuel est propre) |
| Maisons de Havre-Doré 1 à 4 (bleue, corail, sauge, ivoire) : côtés et dos | `generated_imgs/vues/havre_maison_{1..4}_cote.png` et `_dos.png` → `assets/models/volumes/havre_maison_*.glb` | Repli : composés depuis la vue de face (`maisons.py vues`, porte et lanterne effacées, mur étiré ; dos = face en miroir). Une repeinte ComfyUI floutait sans rien apporter | Dessiner le côté droit et le dos (même méthode que les boutiques), puis `maisons.py textures` + `tout` |
| Relais des Dresseurs : vue de côté | `generated_imgs/vues/havre_relais_cote.png` | nano-banana a échoué (3 essais) : vue de 3/4, seul le grand mur est utilisé ; croupes peintes avec les tuiles de la façade | Retenter un vrai profil à 90° |
| Cabane sur pilotis : vue de côté | `generated_imgs/vues/cabane_pilotis_cote.png` | nano-banana a dessiné un pignon en planches, contraire aux croupes retenues : seul le mur latéral est utilisé | Redessiner le côté avec un toit de chaume à croupes |
| Cabane sur pilotis : image du jeu | `assets/art/props/cabane_pilotis.png` | Dessin d'origine en 3/4 (sert en qualité basse et dans l'éditeur 2D), alors que le modèle 3D suit la vue de face | La remplacer par la vue de face (`generated_imgs/vues/cabane_pilotis_face.png`, déjà faite) si on la juge meilleure |
| Maison du Clos Blanc (zone d'essai) | `assets/art/props/maison_3d.png`, `assets/models/maison_3d.glb` | ComfyUI (SD 1.5 + LoRA + IPAdapter) sur des rendus Blender d'un modèle fait à la main | La refaire en « bâtiment assemblé » (vues face/côté/dos nano-banana), ou retirer la zone d'essai |
| Défauts mineurs de vues nano-banana | `generated_imgs/vues/maison_blanche_dos.png` (cheminée recentrée au lieu d'être à gauche), `cabinet_cote.png` (mur trop profond, raccourci par `remodeler`), `phare_ruine_dos.png` (nid oublié, morceau de toit dessiné en parapluie entier ; jamais vu en jeu) | nano-banana, 1er essai gardé | Retenter si on revoit ces maisons de près |
| Tentes (camp de l'Ombre Noire, tente nomade du Désert) : faces cachées | `assets/models/volumes/tente.glb`, `tente_nomade.glb` (travail : `blender_tests/maisons/tente*/`, `tools/modeles3d/tentes.py`) | Repli : modèle tiré du seul dessin 3/4 (calage avec lacet) ; pan et mur gauches, pignon du fond, cordes cachées **par symétrie** (le pignon du fond = le rabat gauche en miroir) ; cordes devant la toile effacées du dessin par remplissage | Dessiner une vraie vue de dos et de côté gauche, repeindre les faces cachées — **sans intérêt tant que la caméra ne tourne pas** (elle regarde toujours vers le nord : le dos n'est jamais vu, le côté gauche à peine) |
| Palissade du camp : dos et côtés des pieux | `assets/models/volumes/palissade.glb` (`tools/modeles3d/pieux.py`) | Repli : seul le dessin de face ; dos des pieux peint par leur devant, ombre peinte des côtés atténuée, cordes peintes d'un bout de corde du dessin ; reste un peu plus sombre que l'image | Vues de côté et de dos — **sans intérêt tant que la caméra ne tourne pas** |
| Plesiosaurus : planche de profil, poses 1 et 4 | `assets/art/dinos/plesiosaurus.png` | nano-banana : le cou/la tête effleure le bord de sa case (empiète un peu sur la case voisine dans la planche source) ; recadrage indépendant par case (pas d'union de recadrage) pour éviter tout mélange avec la case voisine, mais la tête reste légèrement rognée sur 2 des 6 poses | Redemander ces deux poses avec la tête/cou un peu plus rentrés dans leur case |
| Intérieurs des ouvertures et des portes | 10 sortes : cabinet, havre_herboristerie, havre_mercerie, havre_comptoir, havre_sellerie, havre_relais, havre_entrepot, cabane_pilotis, tente, tente_nomade (`tools/modeles3d/interieurs.py`, réglages `pieces` / `tente.interieur` de `maisons.json`) | Pièces en volumes (embrasure, boîte, meubles simples) avec textures du jeu (plancher, terre, sable, mur_cabinet, enduits des vues) ; **détails des meubles et du fond peints par ComfyUI** (img2img débruitage 0,40-0,60 sur un guide Blender, `generated_imgs/interieurs/<sorte>_piece0.png` + `_guide.png`), 28/09. L'étal de la Mercerie n'a rien de ComfyUI | Repeindre chaque `<sorte>_piece0.png` avec nano-banana depuis son `_guide.png` (objets plus lisibles : flotteurs de liège de la cabane, bocaux, selles), puis `maisons.py peindre` / `tout <sorte>` |
| Détails vivants (29/09) : 4 planches retouchées | `generated_imgs/derived-vivants-{cote-plage,flore-actuelle,flore-future,apex}.png` → `rocher_recif`, `cycas`, `ginkgo`, `sapin_neige`…, `prele_geante`… (`tools/art-jobs/vivants_decor.mjs`) | nano-banana a recopié des restes de la planche de référence (fleurs sur le rocher du récif, bûche et boule fantômes) et a refusé 2 fois de les effacer : restes peints en magenta à la main. Il reste un fil rose de 2 px au pied du cycas | Redemander ces planches avec une référence sans fleurs ni bûche (ou effacer par nano-banana) |
| Détails vivants (29/09) : défauts mineurs | `nid_tortue.png` (œufs dessinés, même quand le nid est vide), `peau_mue.png` (peau muée qui rappelle un peu un animal couché), `etagere_bocaux.png` (étiquettes en fausses lettres) | nano-banana, gardé | Variante « nid vide » ; peau plus aplatie, froissée ; étiquettes sans lettres |

## Échelle et conventions

- Grille logique **48 px** (comme Phaser). 1 case = 48 px en 2D = 1 m en 3D ; un niveau de
  relief = 1,2 m.
- L'origine d'un objet = son point de contact au sol (tri en Y).
- **Tailles vues à l'écran** (règle de l'utilisateur, 28/09) : hauteur dans la vue 3D, étirement
  des images compris (×1,15, `WorldView.STRETCH`), donc comparable aux maisons en vraie 3D
  (portes 1,63 à 1,94 m). Étude et tableaux : `echelles.md` (scratchpad du 28/09).
- **Personnes** (`data/heights.gd`, une ligne par planche) : Chloé **1,50 m** (≈ 63 px de haut en
  2D, échelle 0,363) ; femmes 1,50–1,70 (Maïa, Pervenche 1,50 ; Sirocco 1,55 ; la marchande 1,60 ;
  Rosalie, Lilou 1,62 ; Dame Suie 1,68 ; Isaure et le Masque 1,70) ; hommes 1,65–2,00, le haut
  pour les méchants (Joss 1,65, 15 ans ; Roc 1,72 ; le pêcheur 1,74 ; Gaspard 1,78 ; les sbires
  1,80 ; Ferréol 1,82 ; le garde 1,85 ; Brac 2,00). Échelle du sprite = hauteur × 48 / (hauteur
  dessinée × 1,15) ; ombre 20,5 px par mètre de hauteur.
- **Dinos adultes** (`DinoSpecies.world_scale`) : on cale le gabarit T = √(hauteur × longueur) de
  l'animal réel, vrai jusqu'à 1,5 m, compressé au-delà : 1,5 × (T / 1,5)^0,6 (plancher 0,5 m).
  Ex. Compsognathus 0,54 m, Velociraptor 1,10 m (plus petit que Chloé), Ankylosaurus 1,97,
  Tricératops 2,79, Parasaurolophus 2,94, Spinosaure 4,01 (hauteurs vues, idle de profil).
- **Croissance** (`DinoSize.growth`) : un jeune éclôt grand comme un chat (≈ 0,45 m ; une petite
  espèce à 55 % de sa taille, jamais sous 0,40 m pour rester lisible) et grandit en courbe douce
  (smoothstep) jusqu'à l'adulte au **niveau 14**. Écho (Parasaurolophus) : 1,0 m au niv. 5,
  1,9 m au niv. 8, 2,8 m au niv. 12, 3,0 m adulte. Les sauvages tirent leur niveau à
  l'apparition (Plaines : des jeunes ; Forêt et après : des adultes). Au combat, le même âge
  (× √ croissance).
- **Poses** : l'attente (`idle_frames`) n'a que des poses debout ; une pose couchée ne sert qu'au
  sommeil (`sleep_frame`, animation `sleep`, jouée par `Sleeper`) : Spinosaure (attente 3,
  sommeil 4), Oviraptor (attente 0, sommeil 4).
- **Dinos de scène** (`DinoNpc`) : `size_scale` = part d'un adulte (Alphas et Chef de Meute ×1,2,
  Spinosaure Ancestral ×1,25, Vieux Rempart ×1,3, Voix du Marais ×1,1, jeune Baryonyx ×0,55) ;
  `level` > 0 = un jeune de ce niveau (bébés du Cabinet : niveau 5, la taille du dino reçu ;
  doublures des dinos de l'équipe : leur niveau). Leur combat reprend cette taille (règle `size`).
  Le petit volé n'a pas grandi (nourri à l'ambre noir) : niveau 5 dans le monde et quand il
  rejoint Chloé (`ForetCamp.STOLEN_LEVEL`), même s'il combat au niveau 16 chez Brac.
- **Montures** : un dino qui porte Chloé (selle, nage) ne dépasse pas **1,95 m** (≈ 1,3 × Chloé,
  `DinoSize.MOUNT_MAX_M`) : il rétrécit en 0,45 s quand elle monte et regrandit quand elle
  descend ; la selle suit sa taille (`Saddle.place`). Un dino plus petit garde la sienne.
- **Reptiles marins porteurs** (Plesiosaurus, Ichthyosaurus, Elasmosaurus, Archelon ; nage et
  plongée) : réglés sur leur **longueur** et non sur √(hauteur × longueur) (leur dessin, cou
  dressé, est aussi haut que long : la règle générale en faisait des canards sous Chloé) :
  3,3 m, 2,9 m, 4,6 m et 2,9 m de long (`tools/marins_taille.gd` réécrit leur
  `world_scale` depuis la planche : à relancer quand une planche change) ; dans l'eau ils gardent
  leur taille en portant Chloé (pas de plafond de 1,95 m : `DinoSize.mount_scale(…, in_water)`) ;
  elle s'assoit à la base du cou.
- **Compagnon** : il suit Chloé à la moitié de sa longueur + 0,5 m (8 points de piste au moins,
  `DinoSize.follow_gap`), ne se tient jamais sur ses pieds (moitié de sa longueur + 12 px au plus
  près) ; placé à côté d'elle, à gauche, assez loin pour sa longueur (`Companion.stand_beside`).
- **Combats** (`DinoSpecies.battle_scale`) : les mêmes tailles, écarts adoucis (gabarit à l'écran
  ∝ √ gabarit du monde) : du plus petit au plus grand ×2,9 (×8 dans le monde) ; le Spinosaure
  garde la taille qu'il avait (392 px de haut côté joueur en 1280×720).
- **Objets à l'échelle humaine ×0,70** (échelle, collision, ombre, balancement dans `Prop.KINDS`) :
  tonneau, banc, caisses, casiers, étals, lanterne, panneau, clôture, bac à fleurs, cordage,
  bitte, ancre, filet, séchoir, barque, mobilier du Cabinet (bureau, bibliothèque, fauteuil,
  établi, lampe, couveuse, socle, fougère en pot), feu de camp, puits, table et caisses du camp.
  Inchangés : la nature (herbes hautes comprises), les maisons et grands décors, le chariot-cage
  du Désert (il porte le Carnotaurus) ; la tente, la tente nomade et la palissade (vraie 3D) sont
  déjà à l'échelle de Chloé 1,50 m. Les cages du camp sont **agrandies ×1,35** (un Deinonychus
  adulte, un jeune Dilophosaurus ×0,8 y tiennent).
- **Caméra** : distance 12 m par défaut (8 à 20), visée 0,7 m au-dessus des pieds ; la distance
  mémorisée avant le 28/09 est ramenée une fois ×0,75 ; décor « occultant » (transparent devant
  Chloé) au-dessus de 1,6 m ; signes au-dessus des têtes calés sur le haut du dessin (+0,3 m).
- Ombres : calculées en 3D (soleil, lune), pas d'ombre peinte dans les sprites.
- Effets vivants préférés aux images fixes : balancement des plantes (shader), eau animée,
  ombres de nuages, pollen, lueur de l'ambre, lumière qui tourne avec l'heure.

## Mouvement ajouté aux images

Les planches n'ont que 3 ou 4 images par cycle de marche : le jeu ajoute un mouvement calculé
par-dessus (`world/view3d/sprite_motion.gd`), à tous les personnages et dinos de l'exploration.
À la marche, un petit rebond à chaque pas dessiné (les planches dessinent un pas par cycle,
deux pour les vues de face et de dos des dinos) : le corps est au plus haut sur l'image où les
jambes se croisent, trouvée en mesurant l'écart des pieds, et s'écrase un peu quand le pied
touche le sol. Les pas tournent vite pour suivre ce rebond : 14 à 15 images/s pour les
personnages, `walk_fps` × 1,5 pour les dinos de profil (`SheetFrames`) ; à l'arrêt, une respiration lente, chacun à son rythme. Tout est mis à l'échelle
depuis les pieds, qui restent plantés ; l'ombre ne rebondit pas. En selle, Chloé suit le pas de
sa monture. En combat, la respiration seule (`battle/breathe.gdshader`, au niveau des sommets
pour s'ajouter aux autres animations). Pas de fondu entre deux images (doubles contours sur des
dessins cernés). Démo : scénario `demo_live` de `tools/capture.gd`, mouvement activé et coupé
à tour de rôle.

## Détails vivants (29/09 : décor, histoire et flore faits ; faune : voir sa propre passe)

Demande de l'utilisateur (28/09) : **ce qu'un texte décrit doit se voir**. Si une bulle, un texte
d'arrivée ou une ligne « examiner » dit « des petits crabes se baladent », on voit de petits crabes
se balader. Même principe pour les oiseaux, les poissons, les papillons, les lucioles, la fumée, le
linge qui sèche… : de petits sprites animés, posés dans les zones et les scènes. C'est la suite
naturelle de la règle « animer ce que disent les bulles », appliquée à l'ambiance. Et (29/09) :
**faune et flore adaptées à chaque milieu** (pas de papillons au-dessus de la mer, des moustiques
dans la jungle…), en pensant déjà aux zones à venir.

Méthode suivie (29/09) :
1. **Inventaire**, zone par zone, de ce qui est décrit mais invisible : toutes les bulles de
   narration de `story/*.gd`, `data/dialogue_*.gd` (panneaux, cachettes des pages du journal),
   `world/examine.gd`, textes d'arrivée ; comparé aux images de `assets/art/props/` et aux sortes
   « en attente » que les plans de zones prévoyaient déjà avec un remplaçant (Côte, récif).
2. **Images** : 8 planches nano-banana (édition d'une planche du jeu en référence de style, fond
   magenta, objets bien séparés), traitées par `tools/art-jobs/vivants_decor.mjs` (helper `props`,
   boîtes explicites quand le sable ou la neige de deux objets se touchent). Quand nano-banana
   laisse un reste de la planche de référence (bouée, fleurs, bûche fantôme) et refuse de
   l'effacer, on peint ce reste en magenta dans une copie `generated_imgs/derived-vivants-*.png`,
   sans rien toucher d'autre. 54 sortes ajoutées à `Prop.KINDS` (bloc « Détails vivants »), tailles
   réglées sur des hauteurs réelles (objets des gens à l'échelle de Chloé).
3. **Placement** par les plans de zones (`tools/zones/*.gd`, puis `tools/build_zone.gd --force`),
   jamais en éditant les scènes : chaque zone est d'abord reconstruite à part et comparée à la
   scène en place (seuls les décors changent). Deux règles pour ne rien déplacer :
   - une ligne de table de dispersion change de **sorte** mais garde sa **chance** (les tirages au
     hasard restent les mêmes, la forêt ne bouge pas) ; les ajouts de plantes se font avec leur
     propre graine, après tout le reste (`_vivants` du Désert) ;
   - une pierre qu'on retourne (`cailloux`) qui tenait la place d'une nouvelle sorte (coquillages,
     algues de la Côte) reste une pierre jusqu'à ce que les galets d'ambre soient cachés, puis
     devient ce qu'elle remplaçait — sauf si elle cache un galet (`_swap_stand_ins` de
     `tools/zones/cote.gd`) : aucun galet n'a changé de place.
4. Les objets qui n'apparaissent que pendant une scène sont posés par la scène
   (`CS.prop(kind, at_px, name)`), pas par la zone.

**Fait** (captures : `vivants/agent1/` du scratchpad du 29/09) :
- Côte : coquillages (dont une ammonite), algues échouées, bois flotté, rochers de rivage et du
  récif, oyats des dunes, palmiers de la côte, nids de Ptéranodons (aussi dans la scène de la
  colonie), nids de tortues, la boîte en fer d'Hélène dans sa niche (elle reste, vide, après la
  page 23), un masque d'os sculpté sur la Cale (page 24), cycas dans les prés ; grottes marines :
  « H. + I. » gravé, algues ; récif : varech, coraux, éponges, anémones, herbiers, deux pierres à
  masque d'os tournées vers le fond.
- Histoire : la grande étagère du Cabinet (bocaux, crâne de Compsognathus, théière), la table du
  poste d'observation d'Hélène, la peau muée du Parasaurolophus, la pierre plate de l'îlot de
  l'étang, la pioche et le seau d'ambre des sbires (lumineux), l'anneau de pieux aux cordes
  coupées et les fougères écrasées de la clairière, les noms gravés sur une pierre plate (Griffe-
  Grise, la Voix, le Vieux Rempart), les pierres d'ambre de l'îlot de la Voix, le panier de fioles
  de Dame Suie (il part avec elle), la statue de Spinosaure du hall du temple, l'autel de pierre
  des Cœurs (temple, sanctuaire), la natte de fouilles de Tante Sirocco, sa vertèbre géante, les
  côtes pétrifiées dans le sable, la caisse d'ambre noir et les cordes sous le chariot de Brac.
- **Flore par milieu** (plantes du Mésozoïque) : prêles (marais, jungle, oasis, étang), cycas
  (jungle, côte, oasis), ginkgos (clairières rocheuses), roseaux secs (le Marais qui sèche à
  l'entrée du Désert), petit conifère du désert (Frenelopsis) et rocher à lichen orange. Les
  fleurs de prairie qui poussaient dans la jungle, le marais, l'oasis et les prés de la côte ont
  cédé leur place à ces plantes (mêmes emplacements).
- **Zones à venir** (images prêtes, pas encore de zone) : Monts Gelés (sapin enneigé, arbuste
  givré, rocher enneigé à lichen), Cieux Éternels (pin tordu sur sa corniche, nid géant sur un
  piton, tronc à lianes), Plaine Volcanique (tronc calciné aux braises, fougères pionnières dans
  la cendre), Terre des Apex (bennettitale Williamsonia, magnolia, prêle géante, lianes).

**Passe de finition (29/09, faite)** — `tools/art-jobs/finition.mjs` :
- objets tenus en scène, montrés par `Stage.show_thing` (fondu) et rangés par `Stage.take_thing`
  (Chloé se penche, l'objet s'efface) : boîte en fer-blanc de Griffe-Grise, piège à mâchoires,
  tube de cuivre de la Voix, boîte ronde du Vieux Rempart, registre du Passeur — à ~1,3-1,5 fois
  leur taille réelle (0,3-0,7 m) pour rester lisibles sur téléphone ;
- roue du chariot de Brac peinte (`props/roue_chariot.png`, tournée pixel par pixel par
  `DesertSanctuaire._turned` ; repli sur le dessin du code) ;
- nids de Dimorphodons (0,7 m), rocher en forme d'œuf (~2 m, comme les rochers voisins),
  buisson-nid de Chipie, frise de masques au temple (décalée à gauche : la porte cache le centre) ;
- nid de tortues vide : `StoryProp.after_flag` / `after_kind` au chargement, `Stage.repaint` en
  direct à la fin de la scène ;
- Cabinet : lanterne à son crochet (et crochet vide la nuit où Roc sort : `FlaggedProp`), petit
  poêle à bouilloire contre le mur ;
- petites bêtes : escargot, fourmis, ammonite (`WildlifeDB`).

**Règles apprises** : un objet mural (applique, lanterne à un crochet) se pose au pied du mur avec
un `foot` NÉGATIF (prop.gd : l'image monte de −foot × sa hauteur), jamais comme un objet au sol
(la lanterne de 3 m traversait le mur du Cabinet). Toujours contrôler la taille réelle d'une
nouvelle sorte (hauteur de l'image × scale, rapportée à la bibliothèque ≈ 2 m) : plusieurs objets
sortaient 3 à 4 fois trop grands. Deux décors de la même profondeur qui se chevauchent se
découpent en escalier : décaler l'un de quelques centimètres (murs du Cabinet).

**Retouches avant le chapitre 6 (29/09, faites)** — `tools/art-jobs/avant_ch6.mjs`, `retouches_ch6.mjs` :
- corde de Brac (3,9 m) au pied de la vraie paroi du cul-de-sac du canyon des Vents (8,15 ; 6,05),
  là où `DesertSanctuaire._cliff_foot` l'envoie grimper ;
- rocher gravé « PAR OÙ ?! » (`rocher_grave`, 1,5 m), montré dans la tempête pendant que Chloé
  tourne en rond, effacé ensuite ;
- frise du temple redessinée (des dizaines de masques d'os : becs, crêtes, cornes), centrée
  au-dessus de l'entrée, accrochée dans la paroi (`foot` négatif) ; `Region._clear_exit_corridors`
  épargne désormais les décors accrochés (il effaçait la frise, posée devant une sortie) ;
- feu de camp peint : foyer (pierres, bûches noircies, braises), flamme animée en 6 temps
  (`flamme_anim.png`, `WorldView._fire_flame`), fumée en particules (`fumee.png`,
  `WorldView._fire_smoke`) ; `tools/draw-placeholders.mjs` ne réécrit plus `feu_camp.png` ;
- Ptéranodon en vol : vrai cycle (haut, à plat, bas, remontée), une image nano-banana par pose,
  corps ramenés à la même taille (facteur `k` par pose mesuré sur l'iris).

**Reste à faire** : rien de connu pour les chapitres 1 à 5.
La faune (crabes, moustiques, libellules, poissons, ptérosaures en vol…) a sa propre passe
(`assets/art/fauna/`, `world/view3d/wildlife.gd`).

## Variantes de personnages (28/09 : première passe faite)

Demande de l'utilisateur (28/09) : des planches de personnages **accessoirisés** et dans
**d'autres positions** que la marche. Inventaire complet (accessoires de `data/items_db.gd` et des
scènes, gestes décrits dans `story/*.gd`) : `variantes_persos.md` (scratchpad du 28/09).
Planche de contrôle : `generated_imgs/captures/variantes_persos.png`.

**Faites (nano-banana, en éditant la planche du personnage)** — `tools/art-jobs/variantes.mjs` :

| Planche | Grille | Quand le jeu la montre |
|---|---|---|
| `chloe_selle_masque.png` | celle de `chloe_selle.png` (1×4) | sous l'eau (`Player.diving`) : toujours en selle sur son plongeur, avec le masque de Joss |
| `chloe_selle_gilet.png` | idem | sur le dos d'un nageur à la surface (`Player.swimmer`, pas de monture) |
| `chloe_bottes.png` | celle de `chloe.png` (4×4) | à pied, dès qu'elle a les bottes de Rosalie (objet clé `bottes`) |
| `chloe_accroupie.png` | 1 ligne × 4 directions (2ᵉ ligne : doublon, inutilisé) | pose de scène `&"accroupi"` : s'agenouiller, fouiller, se cacher |
| `chloe_nage.png` | 2 lignes × 4 directions (2 temps de brasse) | pose de scène `&"nage"` : Chloé nage seule, mise à la surface |
| `joss_bocal.png` | celle de `joss.png` (4×4) | Joss au bocal (prototype n° 7), scène du lagon (ch. 5) |
| `{maia,chloe,tante_sirocco}_assise.png`, `{roc,pecheur,sbire}_assis.png` (29/09) | 2 lignes × 4 directions en cases de 240 × 184 (2ᵉ ligne : la personne debout, étalon d'échelle, inutilisée) | pose de scène `&"assis"` (`Stage.sit`) : Maïa au belvédère, Chloé à côté d'elle, Gustave qui ravaude son filet, Firmin qui vide sa botte, Tante Sirocco en tailleur, Roc dans son fauteuil (ch. 3 et 5) |
| `dinos/pteranodon_vol.png` (29/09) | 1 ligne × 4 battements, profil vers la droite | vol en scène (`CoteStage.fly` / `circle` : toute espèce qui a `dinos/<espèce>_vol.png`) |

**Poses assises (29/09)** : nano-banana dessine une planche 2 × 4 à partir de la planche de marche
(rangée 1 : la pose, rangée 2 : debout) ; il mélange souvent les profils, remis dans l'ordre par
`orderViews` (`tools/art-jobs/variantes.mjs`, liste `SITTING` : colonne et miroir par vue). Découpe
à la hauteur dessinée du personnage (`Heights`) prise sur l'union : les têtes des deux rangées ont
la même taille, c'est ce qui compte (assise, une petite garde presque sa hauteur debout : grosse
tête, genoux sous le menton). Cases larges (240 px) pour un filet étalé ou des jambes allongées.

**Échelle** : chaque variante est détourée à la **même échelle de dessin** que la planche de base
(px de sortie par px de source), mesurée sur la largeur de la tête (76 px dans `chloe.png`) ou sur
l'union des images quand la composition est la même (réglages commentés dans le fichier de jobs).
Les variantes rejoignent donc les SpriteFrames du personnage et gardent son échelle de sprite
(`Heights` : `chloe_bottes`, `joss_bocal` y ont leur ligne, bocal compris). Les poses sont dans des
cases de la taille des images de marche (123 × 184, pieds à 4 px du bas) : les pieds ne bougent pas.

**Comment le jeu choisit** (`actors/outfits.gd`, class `Outfits`) :
- à pied : animations `bottes:walk_<dir>` / `bottes:idle_<dir>` si elle a les bottes
  (`Outfits.walk_look()`, lu par `Player._animate`) ; les préfixes gardent la direction en fin de
  nom (le rebond de `sprite_motion.gd` la lit) ;
- en selle (`Saddle.place`) : `masque:ride_<dir>` sous l'eau, `gilet:ride_<dir>` sur un nageur à
  la surface, sinon `ride_<dir>` (`Outfits.saddle_look`). Sous l'eau, le masque seul (le gilet sert
  à la surface) ;
- pose de scène : `Stage.pose(actor, &"accroupi", secs)` (0 : jusqu'à `Stage.pose(actor, &"")`),
  tournée là où l'acteur regarde, rend `false` si la pose n'est pas dessinée (on garde alors un
  écrasement). `CoteStage.kneel()` et `get_up()` s'en servent (filet du lagon, caisses des grottes,
  près de Maïa), et Chloé cachée derrière les caisses du camp (`ForetCamp._hide`). La pose
  `&"nage"` place l'image à la surface sur l'eau profonde (48 % sous la ligne d'eau), la découpe
  (l'eau cache le bas) et cache l'ombre ;
- autre tenue pour une scène : `Stage.dress(npc, &"bocal")` (`&""` : la tenue habituelle), la
  planche de base est gardée en méta. Joss la met en sortant de l'eau (`CoteLagon._jar`) et la
  garde jusqu'à la fin de la scène ; au prochain chargement de la zone, il ne l'a plus.

**Tests** : `tools/scenarios/variantes_bottes.gd`, `variantes_poses.gd`, `variantes_selle.gd`,
`variantes_joss.gd` (commandes `pose`, `dress`, `face` de `tools/capture.gd`). Une capture à la
fois : deux Godot en même temps saturent la carte graphique (4 Go) quand ComfyUI tourne.

**Reste à faire** :
- les bottes en selle (`chloe_selle*.png` gardent les bottines) ;
- ~~poses assises~~ faites le 29/09 (voir le tableau) ; Maïa agenouillée près des cordes du pont
  (`ForetFin._to_the_cut_span`) reste un écrasement (pas d'accroupie pour elle) ;
- le Passeur (feuille `sbire`) avec son masque d'os et sa pipe ;
- Joss au bocal dès l'arrivée à la Côte (« la tête dans un bocal », disent les pêcheurs) : il
  faudrait une tenue réglée par drapeau sur le PNJ de la zone ;
- `chloe_nage.png` se lit un peu comme un vol hors de l'eau (vue de face surtout) : bien dans
  l'eau, à refaire si on la montre hors de l'eau.

## Décors fixes en relief (abandonné)

> **Abandonné le 28/09** : en jeu, les décors en bas-relief paraissaient déformés (jugement de
> l'utilisateur) ; tous les décors ordinaires sont revenus à leurs images. Le code de rendu des
> reliefs est retiré de `WorldView` ; les maillages, cartes de normales et d'occlusion sont
> archivés hors dépôt (`C:/ComfyUI_windows_portable/blender_tests/archive/reliefs/`). Le script
> `reliefs.py` reste pour mémoire. Ne pas reproposer sans une idée neuve.

Chaque décor fixe (sans balancement `sway`, sans flottement `"float"`, sans vrai modèle
`"model"`) devient un maillage OBJ qui garde son image exactement de face, creusé selon une
carte de profondeur estimée par Depth Anything 3 (ComfyUI). Script (`tools/modeles3d/`, lu en
entier) : `reliefs.py`. Python de ComfyUI pour ce script : `python_embeded/python.exe`.

**Étapes**
1. `python reliefs.py prep [sorte…]` : image de travail sur fond gris par sorte
   (`ComfyUI/input/relief_<sorte>.png`) et workflow `tools/modeles3d/profondeur_comfyui.json`
   (format API) à lancer dans ComfyUI.
2. Dans ComfyUI, le modèle DA3 (`depth_anything_3_mono_large.safetensors`, dossier ComfyUI
   `models/geometry_estimation`) doit tourner en **fp32** — en fp16, cartes de profondeur vides
   sur la GTX 1650 Ti — avec la normalisation `min_max` (déjà réglé dans le workflow généré).
3. `python reliefs.py collect [sorte…]` : copie la dernière carte de chaque sorte depuis
   `ComfyUI/output/relief/` vers `tools/modeles3d/profondeurs/<sorte>.png` (gris, 320 px au
   plus ; dossier versionné mais ignoré par Godot via son `.gdignore`).
4. `python reliefs.py build [sorte…]` : maillage `assets/models/reliefs/<sorte>.obj` (+ mesures
   `_reliefs.json`) pour chaque sorte dont la carte existe.
5. `python reliefs.py normals [sorte…]` (~30 s pour tout) : les **détails** que le maillage (~10
   cases/m) ne peut pas porter — briques, tuiles, planches, lattes des volets, fissures —
   dans `assets/models/reliefs/<sorte>_n.png` (carte de normales **complète** : forme générale
   issue de la même profondeur que `build`, + détails du dessin ; repère de l'image : R = +X,
   G = +Y haut, B = vers la caméra ; fond (128,128,255)) et `<sorte>_ao.png` (creux, 255 = pas
   d'ombre, jamais sous 0,5). Détails : un trait sombre fin (plus sombre que l'image « fermée »
   par un disque de 2,5 px, ou luminance < 0,12) est un creux, chanfreiné de part et d'autre
   (rayons 1,5 et 4 px) ; les aplats sombres larges (mousse, volets) ne sont pas creusés ; un
   passe-bande de luminance fait ressortir le clair. Poids par sorte `DETAIL` (1,1-1,3 pierre,
   bois, tuiles ; 0,25-0,8 objets lisses). Import Godot : `_n` en « normal map » sans perte
   (RGB8), `_ao` sans perte (les `.import` sont versionnés).

**Réglages** (dans `reliefs.py`)
- `DEPTH` : profondeur totale de chaque sorte, en fraction de sa largeur (0,6 par défaut) — plat
  pour un panneau ou une porte, plein et rond pour un rocher ou une tente.
- Le relief n'avance vers la caméra que jusqu'où le permet sa collision (recul limité, rayon du
  joueur inclus) : jamais plus près que ce qu'on pouvait déjà traverser en 2D.
- `SLOPE = 1.0` : pente max 45°, pour ne pas étirer les bords proches en parois verticales.
- Le pied de l'objet (bande basse, au centre) est recalé sur le plan de l'image après le lissage
  de pente, pour ne jamais faire flotter ou enfoncer un objet fin.

**Pièges**
- fp16 sur DA3 donne des cartes vides sur la GTX 1650 Ti : toujours fp32.
- Les sortes qui bougent (`sway > 0`), qui flottent (`"float"`) ou qui ont déjà un vrai modèle
  (`"model"`) sont exclues d'office : elles gardent leur image.

**Rendu en jeu** : `world/view3d/relief.gdshader` (éclairé comme les images : normale face
caméra, pied plus sombre ; seul le côté face au soleil suit les vraies faces du maillage).
`WorldView._add_props` choisit, par sorte : modèle réel (`"model"`) > relief (qualité
`relief_props`, sinon image) > image. Qualité basse : images partout. Commande de capture
`reliefs` (`true`/`false`, zone reconstruite) pour comparer côte à côte.
**Détails par shader** (`relief.gdshader`, `normal_mode` 1 pour les reliefs, 2 pour les modèles) :
la normale « image » reste la base de l'éclairage (cohérence avec les images voisines) ; la carte
floutée (mip 4) remplace la normale du maillage dans le terme « côté soleil » (jamais les deux :
la forme compterait double) ; les détails ajoutent `detail × sun_light × dot(écart fin − flou,
soleil)`, borné à ±0,5 et de moyenne nulle (pas de dérive de luminosité : mesuré −0,6 à +0,5/255
à midi, le soir, la nuit) ; cavités = `ao / ao floutée` (seuls les creux s'assombrissent).
Réglages dans `world_view.gd` : `RELIEF_DETAIL = 1.2`, `MODEL_DETAIL = 3.0` (la carte cuite des
modèles est douce), `cavity = 1.0`. Les détails suivent aussi la lune, discrètement. Miroir :
R inversé (et tangente/binormale des modèles). Commande de capture `details` (true/false) pour
comparer. Coût : dans le bruit (au pire ~5 %). Scénario
`tools/scenarios/reliefs_test.gd` : port, Plaines, Désert en images puis en relief, puis mesure
de fréquence d'image (sans vsync) dans le cimetière du Désert — pas de coût mesuré, ~250 im/s
aussi bien en images qu'en reliefs.

**Limite** : bas-relief seulement (pas de vrai dos ni de vrais flancs) — pour un grand décor
qu'on contourne, voir « Grands décors en vraie 3D » ci-dessous.

## Bâtiments assemblés en vraie 3D (méthode retenue, 28/09)

> **Règle permanente** : les bâtiments sont en 3D (maisons, boutiques, entrepôts, cabanes),
> ainsi que les tentes et les palissades ; **tout ce qui est en 3D l'est aussi dans les futures
> implémentations, avec les mêmes règles** (ci-dessous) — un bâtiment ou une structure de ce type
> dans une nouvelle région se fait d'emblée en « bâtiment assemblé ». Plantes, rochers et petits
> objets restent des images.

Les 5 bâtiments en 3D (maison_blanche, maison_jaune, maison_port, cabinet, cabane_pilotis) sont
**assemblés** : un modèle simple et propre (coins arrondis, murs bosselés, biseaux) aux proportions
mesurées sur des **vues dessinées cohérentes** (face, côté droit, dos), chaque face peinte par le
morceau de la vue qui la montre, détails par carte de normales tirée des dessins. Pourquoi pas
Hunyuan3D : les dessins du jeu mélangent une façade vue de face et un toit vu d'en haut ; pour les
reproduire, la reconstruction invente des toits trop hauts, et la peinture projetée s'étire sur
les pentes (verdict de l'utilisateur : « déformé », « textures des toits pas bien appliquées »).

**Exigences de l'utilisateur** : les flancs des toits, vus de face, ne sont **jamais verticaux**
(croupes, ou pignon en façade dont les pans descendent) ; fidélité au dessin avant tout.
**Éléments de façade dans le plan de la façade** : fenêtres, portes, volets, jardinières, enseignes
restent au niveau du mur — peints, ou en volume très peu saillant (≤ 8 cm) dont le dessus et les
côtés ont leur propre peinture (terre et fleurs, bois, métal), **jamais la projection de la
façade** (sinon la fenêtre « ressort sur le dessus » : défaut de la jardinière de maison_jaune).
Pas de bâtiment en double dans une même ville : chaque bâtiment a son dessin (Havre-Doré avait
repris les maisons de Port-Ambre).
**Vraies ouvertures** (règle générale pour toute 3D) : quand le dessin montre une ouverture
(entrée de tente aux pans relevés, porte ouverte, embrasure sans battant, fenêtre sans vitre,
passage, arcade), le modèle a un vrai trou avec un intérieur en volume (profondeur, parois et fond
assombris, sol) : on voit dedans, surtout de 3/4. Bien analyser le dessin d'abord : une porte
pleine, un volet clos, une vitre ou une toile rabattue ne sont pas des ouvertures.
**Le maillage suit les formes du dessin** (règle générale pour toute 3D : bâtiments, props,
décor) : faîtages et égouts affaissés ou bombés, murs pas tout à fait droits, cheminées penchées,
rives irrégulières — le contour du modèle projeté doit coller au contour du dessin dans chaque
vue, lignes intérieures importantes comprises (égout, faîtage). Jamais une ligne droite là où le
dessin est creusé (défaut du toit de l'entrepôt, 28/09).

**Étapes**, pour un bâtiment
1. **Vues** (nano-banana, `mcp__nano-banana__edit_image`, fond magenta, 1:1, 1K, réflexion haute) :
   `generated_imgs/vues/<sorte>_face|cote|dos.png`, détourées, recadrées, **même hauteur en px**
   entre les trois (même échelle). Face = le dessin du jeu s'il est bien de face (la cabane, de
   3/4, a été redessinée). Prompt : point de vue exact (« tourné de 90° vers la droite… la
   façade de profil au bord gauche »), même style, mêmes couleurs, mêmes contours, mêmes
   proportions, flancs de toit inclinés ; en référence le dessin + les vues déjà faites.
2. `python tools/modeles3d/maisons.py textures <sorte>` (Python de ComfyUI) : textures par vue
   (contour brun extérieur rongé, couleurs étendues), relief des détails, retouches (cheminée
   peinte sur le toit, balcon devant les fenêtres : remplacés par le dessin voisin), motifs
   répétés pour les dessus qu'aucune vue ne montre (terrasse, plancher).
3. `blender -b -P tools/modeles3d/maisons.py -- tout <sorte>` : **calage** (pour chaque vue,
   l'élévation et le décalage qui recouvrent le mieux sa silhouette ; `calage_<v>.png` montre
   les arêtes du modèle tracées sur la vue : à regarder), **bake** (dont l'**ajustement à la
   silhouette** du dessin, `tools/modeles3d/ajuste.py` : le maillage fin se déforme doucement pour
   que contour haut, égout, bords des murs et dessous suivent chaque vue — face et dos se partagent
   la hauteur, le côté donne la profondeur ; petits volumes (cheminées, lucarnes, cristal) bougés
   d'un bloc, 8 cm de penchée au plus ; écart > 0,12 m ignoré = un choix de forme différent de la
   vue ; contrôle : `-- ajuste <sorte>` → `ajuste_contour_<v>.png` ; déplacement moyen 3 à 9 cm ;
   puis atlas 2048, peinture, normales, occlusion légère 0,35 ; Cycles CPU ; export
   `assets/models/volumes/<sorte>.glb`, une surface), **rendus** de contrôle.
4. `python tools/modeles3d/maisons.py planche <sorte>` → `generated_imgs/captures/
   maisons_assemblees_<sorte>.png` (dessin, modèle calé sur chaque vue, caméra du jeu 0°/40°,
   ±45°/35°, dos) : **à juger avant d'aller en jeu**.
5. `Prop.KINDS` : `"model"` et `"solid"` (emprise au sol en px, affichée par `bake`) ; import
   Godot (`--headless --import`) ; vérification en jeu à midi et le soir.

**Réglages** : `tools/modeles3d/maisons.json` (clé `_aide`) — dimensions par sorte (murs, toits :
axe du faîte, égout, faîtage, croupes > 0 = flanc incliné, pignons, toits croisés), cheminées,
marches, boîtes et cylindres (balcon, pilotis, jardinière, descente d'eau), redans, cristaux ;
élévation de peinture par vue (0-18°, par partie si besoin : chaume de la cabane à 5°) ;
rectangles à effacer ou remplacer ; `raccourcir` (vue dessinée trop profonde). Travail hors
dépôt : `C:/ComfyUI_windows_portable/blender_tests/maisons/<sorte>/` (`calage.json`,
`calage_<v>.png`, atlas, `modele.blend`). Modèles de 470 à 1 700 faces.

**Rendu en jeu** : `relief.gdshader` (normal_mode 2), l'assombrissement du pied est mesuré sur la
hauteur du maillage (`foot_height`, réglé par `WorldView._relief_material`) — sur un atlas,
`UV.y` ne veut rien dire (taches en damier sur les toits).

**Bâtiments en 3D (28/09)** : Port-Ambre — maison_blanche, maison_jaune, maison_port (toit à
croupes bas derrière le bandeau), cabinet ; Marais — cabane_pilotis ; Havre-Doré — 10 bâtiments
propres (`havre_herboristerie`, `_mercerie`, `_relais`, `_comptoir`, `_sellerie`, `_entrepot`,
`havre_maison_1` à `_4`, dessins et concepts : `generated_imgs/vues/havre.json`, planche
`planche_rue_havre.png`). Scénario de vérification : `tools/scenarios/havre_batiments.gd`.
Outils ajoutés à `maisons.py` (voir `_aide`) : règles de peinture `toiture:` (motif posé sur
chaque pan), `toiture_flancs:`, `facade:` ; motif pris sur une autre sorte, `repete`, `egaliser`
(retire la lumière peinte du dessin) ; `remodeler` (répéter/retirer des bandes d'une vue aux
mauvaises proportions) ; commande `vues` (côté et dos **composés depuis la face**, réglage
`depuis_face`, quand aucune vue dessinée n'existe — repli des crédits nano-banana épuisés ; une
repeinte ComfyUI (SD 1.5 + LoRA + IPAdapter, denoise 0,35) essayée sur ces murs floutait sans
rien apporter).
Côte — `phare_ruine` (vieux phare en ruine de la Pointe aux Ptéranodons, 3,8 m de diamètre, 9,3 m
avec le reste de la lanterne) : tour ronde un peu conique au bord cassé, creuse (dedans, arase, fond),
fers tordus, morceau de toit de cuivre tombé, nid ; porte peinte fermée, deux fentes = vraies
ouvertures. Méthode inverse : le modèle d'abord (réglages ci-dessus), puis des **guides** rendus
depuis lui (face, côté, dos, 12°) que nano-banana a repeints en gardant la silhouette (recouvrement
0,96 à 0,99) ; les lignes du bord cassé tombent donc sur celles du dessin (scratchpad du 28/09,
`phare/`). Outils ajoutés à `maisons.py` : tour ronde (`segments`, `fruit`), `murs.ruine`, `tiges`,
`coupoles`, `cylindres.profil`, `cote_gauche`, peintre `face_sinon:` (la face seulement là où elle
se voit vraiment, par rayon), `vues.<v>.lumiere_face` (la lumière peinte de la face portée autour
de l'axe : pas de raccord clair/sombre entre les vues d'une tour ronde).

**Limites connues** : cabane, dessus des pilotis et bord du plancher un peu flous de biais ;
havre_maison_1 à 4, côtés et dos composés depuis la face (à redessiner quand nano-banana aura des
crédits) ; pignons croisés des maisons 2 et 4 très présents vus d'en haut ; à Havre-Doré, la
ruelle est (x 50-51) bute contre l'entrepôt (9 m de large ; il n'a pas été déplacé : la scène de
nuit de Ferréol, `story/havre.gd`, est calée sur x 48,5).

**Portes animées (28/09)** : une sorte où l'on entre a une variante `assets/models/volumes/portes/
<sorte>.glb` (cabinet, havre_herboristerie, _mercerie, _relais, _comptoir, _sellerie, _entrepot) :
le corps avec une vraie ouverture et une pièce derrière, et le battant `porte` (ou `porte_g` /
`porte_d`), origine sur l'axe des gonds, fermé ; extras glTF `ouverture` (degrés signés, vers
l'intérieur) et `seuil` (x, z en m, repère de la sorte). Le glb du jeu reste d'un seul tenant, porte
fermée. En jeu (`world/view3d/doors.gd`), quand un nœud 2D en a besoin (StoryProp d'une boutique,
bâtiment d'où part un ZoneExit), la vue pose ce corps à part (hors MultiMesh) et chaque battant sur
un pivot à ses gonds (mêmes matériaux RELIEF, carte de normales comprise, maillage recalé dans le
repère du corps pour que le pied assombri raccorde ; miroir du bâtiment suivi) ; il tourne en
0,4 s avec `door_open.wav` (fermeture : le même, plus bas et plus grave). API `WorldView.door`,
`open_door`, `set_door`, `door_near`, `door_of_exit` ; pendant un passage de porte, le décor devient
transparent comme si Chloé était restée devant la porte (`WorldView.occlusion_px`) : la façade ne
s'efface pas quand elle passe le seuil, et la rangée de maisons derrière la caméra ne « claque » pas.
Mises en scène (`story/doorway.gd`) : on va devant la porte, on s'y tourne, elle s'ouvre, on monte
les marches (image soulevée jusqu'au bas du battant, sur les 0,4 m devant la façade), on passe le seuil
et on s'efface dans le noir (le chambranle et le linteau cachent par la profondeur) ; en sortant,
l'inverse, puis la porte se referme. Le compagnon suit s'il passe sous le linteau, sinon il attend à
côté de la porte (`Companion.outside` pendant la visite d'une autre zone). Cabinet : entrée et
sortie (`World.goto_zone`) ; boutiques du Havre (herboristerie, mercerie, comptoir : le marchand
entre le premier, ressort après Chloé et reprend sa place) ; entrepôt (Ferréol, la nuit) ; Roc qui
sort du Cabinet (et laisse la porte ouverte). Qualité basse (images) : pas de battant, les mêmes
pas et le bruit de la porte. Scénario : `tools/scenarios/portes_test.gd`.

## Grands décors en vraie 3D (Hunyuan3D) — abandonné pour les maisons

> Remplacé pour les bâtiments par les « Bâtiments assemblés » ci-dessus. Les rochers, os, statue,
> arche, canyon produits ainsi ont été jugés déformés en jeu et sont revenus aux images. Reste
> ci-dessous pour mémoire (et pour un objet organique si un jour ça s'y prête).

Pour les décors qu'on contourne (une maison, un rocher de canyon…), Hunyuan3D 2.0 (ComfyUI)
sculpte un vrai volume à partir de l'image du jeu posée sur fond blanc ; Blender l'allège, cale
l'angle sous lequel Hunyuan a lu l'image, met à l'échelle du jeu, pose le pied de façade à
l'origine, projette l'image du jeu elle-même sur la face, et deux flancs peints par ComfyUI
(couleurs des rendus Blender, style du jeu) sur l'est et l'ouest. Scripts (`tools/modeles3d/`,
lus en entier) : `volumes.py` (étapes hors Blender, Python de ComfyUI), `volumes_blender.py`
(`prep`, `bake`), `volumes_lot.sh` (enchaîne tout).

**Étapes**, pour une sorte
1. `python volumes.py hunyuan <sorte…>` : pose l'image du jeu sur fond blanc carré (marge 25 %),
   écrit `ComfyUI/input/hy3d_<sorte>.png` et le workflow `dino_workflows/hy3d_<sorte>.json`
   (checkpoint `hunyuan3d-dit-v2_fp16.safetensors`, dossier ComfyUI `models/checkpoints` — dépôt
   Comfy-Org/hunyuan3D_2.0_repackaged, 4,9 Go ; octree 192 par défaut, 256 pour plus de détail)
   à lancer dans ComfyUI ; sortie `output/volumes/<sorte>_*.glb`.
2. `python volumes.py face <sorte>` : texture de face = l'image du jeu, alpha rongé de 6 px sur
   le contour extérieur (sinon le contour brun s'étire sur les bords du modèle), couleurs
   étendues de 40 px dans le fond ; écrit `tex_face.png` et `tex_face_guide.png` (sans contour,
   pour guider les flancs) dans `blender_tests/volumes/<sorte>/`.
3. `blender --background --python volumes_blender.py -- prep <sorte>` : importe le dernier
   `.glb` d'Hunyuan (`<sorte>_00001_.glb`, ou `<sorte>_b_00001_.glb` pour une autre graine : le
   plus récent ; jamais `rocher_canyon` pour `rocher`), refait le brut en voxels de ~1,5 cm (le
   « haut », ~1,5 M triangles, gardé dans `modele.blend` sous `<sorte>_haut` pour la cuisson :
   le brut d'Hunyuan a des milliers d'arêtes partagées par 3-4 faces aux endroits fins, que
   Decimate ne sait pas simplifier — c'est ce qui donnait un toit plat et une cheminée déformée),
   puis l'allège en « bas » (`FACES` par sorte : maisons 50 000, Cabinet 55 000, rochers et
   tentes 12 000-20 000 ; sans le dessous posé au sol), trouve l'angle sous
   lequel Hunyuan a lu l'image (meilleur IoU de silhouette, testé tous les 5° puis affiné), met à
   l'échelle du jeu (la largeur de l'image, à la constante `scale` de `Prop.KINDS` près, cale la
   largeur en x du modèle), pose le pied de façade à l'origine (recul `FRONT_CLEAR`, comme le
   bord avant de la collision d'un Prop), écrit `info.json` (angle, IoU, tailles, `solid_px`) et
   `modele.blend`, rend la face et les flancs est/ouest en 640×640 fond transparent pour ComfyUI.
4. `python volumes.py flancs <sorte>` : workflow ComfyUI (checkpoint SD 1.5
   `v1-5-pruned-emaonly-fp16.safetensors` + LoRA `ambrelune_style.safetensors` 0,8/0,8 +
   IPAdapter Advanced `ip-adapter-plus_sd15` + `CLIP-ViT-H-14-laion2B-s32B-b79K`, poids 0,6, sur
   l'image du jeu) qui repeint les deux rendus Blender ; img2img denoise 0,5, 25 pas, cfg 7,
   dpmpp_2m karras, graine 7 ; écrit `dino_workflows/vol_flancs_<sorte>.json` (à lancer dans
   ComfyUI) et `.api.json` (pour l'API `/prompt`, avec `"front": true` : en tête de file).
5. `python volumes.py textures <sorte>` : retire le fond et le contour brun extérieur des flancs
   peints (6 px, même piège qu'à l'étape 2), étend les couleurs de 48 px ; `tex_est.png`,
   `tex_ouest.png`.
6. `blender --background --python volumes_blender.py -- bake <sorte>` (Cycles **CPU** : le GPU
   est à ComfyUI ; ~80 s, dont occlusion 50 s) : rouvre `modele.blend` ; atlas UV 2048² du bas
   (Smart UV Project 66°, petits îlots fusionnés, marges 12 px, débord 16 px) ; **cuit** dans
   l'atlas la peinture (la face projetée — UV calées au `prep` — et chaque flanc sur les faces
   qui le voient le mieux, lancer de rayon ; une face vue presque autant des deux flancs prend
   celui de son côté), l'**occlusion** du haut (portée 0,35 m, multipliée dans la couleur à 0,6)
   et la **carte de normales** du haut vers le bas (cage auto 3-12 cm) ; export
   `assets/models/volumes/<sorte>.glb` : une surface, tangentes, `baseColor` (JPEG q92) +
   `normalTexture`. Étape `maillages` : refait haut et bas sans toucher à l'angle ni aux flancs
   déjà peints (`bake` la lance seule si `modele.blend` est d'avant cette version).
7. `python volumes.py kinds <sorte>` : écrit dans `Prop.KINDS` (`world/prop.gd`) la clé `"model"`
   et la collision `"solid"` = emprise au sol (`info.json` → `solid_px`). Puis import Godot
   (`--headless --import`).

Tout d'un coup : `bash volumes_lot.sh <sorte…>` (étapes 2 à 7 ; saute une sorte sans maillage Hunyuan déjà sorti
dans `output/volumes/`), avec `python_embeded/python.exe` et `Blender 5.2/blender.exe` ; envoie
la peinture des flancs à `http://127.0.0.1:8188/prompt` et attend qu'elle apparaisse dans
`/history/<id>` avant de continuer. `bash volumes_suite.sh <sorte…>` : attend que le maillage de chaque sorte sorte de ComfyUI (jusqu'à 45 min), puis `volumes_lot.sh` (journal `blender_tests/volumes/suite.log`).

**Dans le jeu** : clé `"model"` de `Prop.KINDS` (`res://assets/models/volumes/<sorte>.glb`) et
`"solid"` = emprise au sol donnée par `info.json` (`solid_px`). `WorldView._model_mesh` /
`_add_props` posent le maillage en MultiMesh avec `relief.gdshader` (une matière par surface,
qualité `relief_props`, sinon image). Un décor interactif de cette sorte (StoryProp, ex. la
Mercerie) est reflété par son modèle (`_prop_model` / `_sync_model`) : mêmes mécanismes que les
reliefs — miroir (`flip`), fondu (`opacity`, tramé), transparence quand il cache Chloé.

**Durées mesurées** (GTX 1650 Ti, 4 Go) : ~14 min par décor en octree 192 (~20 min en 256), dont
~10 min d'échantillonnage (`KSampler`). La carte est bien utilisée même si le Gestionnaire des
tâches affiche 0 % : il montre le moteur « 3D », pas CUDA.

**Pièges**
- Un brut d'Hunyuan peut rater (`maison_port` : pas de toit, murs troués) : le regarder en gris
  (`blender_tests/voir_grand.py`) et le refaire avec une autre graine, sortie `volumes/<sorte>_b`.
- ComfyUI affiche « Missing VAE keys ['encoder…'] » pour Hunyuan3D : sans importance (le modèle
  reconditionné n'a que le décodeur, seul utile pour partir d'une image).
- Ne jamais alléger le brut directement (voir étape 3) : toujours passer par le remaillage voxel.
- L'atlas couleur (~21 Mo de mémoire vidéo sur mobile avec l'import par défaut) : à surveiller ;
  la carte de normales est importée en compression VRAM adaptée (BC5 / ETC2 RG11), sans
  différence visible.
- Le contour brun de l'image ne doit toucher ni les flancs ni les bords du modèle : texture de
  face rongée de 6 px, guide des flancs sans contour (étape 2, `face`).
- numpy 2 : utiliser `np.ptp(a)`, pas `a.ptp()`.
- Après réouverture d'un `.blend` (étape `bake`), créer les nœuds de matériau explicitement
  (`nodes.clear()` puis reconstruire) : le nœud par défaut peut manquer.

**État au 28/09** : 15 sortes produites, **seules les maisons gardées en 3D** (en attente du
verdict de l'utilisateur) : maison_blanche (réussie), maison_jaune (pli sombre sous le pignon),
cabinet (trop sombre, lierre en paquets), cabane_pilotis (flaques violettes de l'image devenues
du volume, bois sombre). Revenus en images et archivés hors dépôt
(`blender_tests/archive/volumes/`) : rochers, rocher de canyon, arche, squelette, crâne, os,
statue (jugés déformés en jeu), maison_port, tente, tente_nomade (bruts d'Hunyuan ratés : murs
sans toit, formes cassées). Leçon : Hunyuan3D lit mal les images très dessinées en perspective
(tentes, maison du port) et prend les ombres/flaques peintes au sol pour du volume.

**Travail hors dépôt** : `C:/ComfyUI_windows_portable/blender_tests/volumes/<sorte>/`
(`info.json`, `modele.blend`, rendus, textures) ; sorties ComfyUI `output/volumes/`,
`output/volumes_flancs/`.

**Vérifier** : scénario `tools/scenarios/volumes_test.gd` (chaque décor de face, de côté, au
crépuscule ; images vs relief ; un décor reflété, la Mercerie du Havre Doré).

## Bâtiments en vraie 3D peinte (Blender + ComfyUI)

Méthode à la main (cas particulier) : tout le modèle est sculpté dans Blender, sans passer par
Hunyuan3D — pour une forme organique qu'on veut contrôler pierre par pierre ; pour un grand décor
de la liste ci-dessus, préférer « Grands décors en vraie 3D » (plus rapide, un seul script).

Essai validé dans la zone d'essai `clos_blanc` (la maison de pierre, lanceur
`tools/lancer-maison-3d.cmd`). La forme est modélisée dans Blender, ComfyUI la peint dans le
style du jeu, puis les peintures sont projetées sur le modèle, qui est posé dans la vue 3D comme
un décor.

**Fichiers** (`tools/modeles3d/`) : `maison_3d_organique.py` (modèle, rendus, projection et
export), `prep_texture.py`, `peinture_comfyui.json` (workflow ComfyUI, format API),
`lora_kaggle.ipynb` (entraînement de la LoRA). Hors dépôt, dans `C:\ComfyUI_windows_portable\` :
la LoRA `ComfyUI/models/loras/ambrelune_style.safetensors` (SD 1.5, 38 Mo, entraînée sur 45 images
du jeu : 5 dinos, 5 personnages, 10 décors), le checkpoint `v1-5-pruned-emaonly-fp16`,
`ip-adapter-plus_sd15` + `CLIP-ViT-H-14-laion2B-s32B-b79K`. Les rendus Blender vont dans
`blender_tests/renders/`. Python de ComfyUI (`python_embeded/python.exe`) pour `prep_texture.py`.
Dans le jeu : `assets/models/<nom>.glb`, la clé `"model"` de `Prop.KINDS`,
`WorldView._model_mesh` / `_add_props` / `_prop_model`, `world/view3d/relief.gdshader`.

**Étapes**
1. **Modéliser organique**, jamais en pavés droits (l'utilisateur les a refusés : « trop
   simplet, trop droit ») : pierres posées une à une (biseau, sommets déplacés, légère rotation),
   murs subdivisés et bosselés par un bruit, coins arrondis, ardoises rang par rang, faîtage et
   cheminée en éléments séparés. 1 unité Blender = 1 m, ×1,6 à l'export (`GAME_SCALE`).
2. **Rendre** (`blender --background --python maison_3d_organique.py -- render`) : deux vues à
   l'angle de la caméra du jeu (40°, `CameraRig.PITCH_DEG`), la façade (azimut 0°) et le pignon
   est (90°), 640×640, fond transparent. Poser les vues sur fond blanc dans `ComfyUI/input`.
3. **Peindre** (`peinture_comfyui.json`) : SD 1.5 + LoRA `ambrelune_style` (0,8 / 0,8),
   CLIP −1, IPAdapter Advanced (poids 0,6, linear, V only) sur une illustration existante de
   l'objet ; img2img denoise 0,5, 25 pas, cfg 7, dpmpp_2m karras, graine 7. Prompt :
   `ambrelune style, <objet>, front view from above, high angle, irregular rounded hand-cut
   stones, uneven slate tiles, bold thick dark brown outline, clean lineart, cel shading,
   vibrant saturated colors, mobile game sprite, sticker style, plain white background` ;
   négatif : `photo, realistic, 3d render, cgi, flat grey shading, …`. Vérifier que la peinture
   se superpose au rendu (mêmes contours).
4. **Préparer** (`prep_texture.py peinture.png texture.png`) : retire le fond et **7 px du
   contour brun extérieur** (projeté, il ferait une teinte foncée aux arêtes), puis étend les
   couleurs de 48 px dans le fond (petits décalages de projection).
5. **Projeter et exporter** (`-- bake face.png cote.png Godot/assets/models/<nom>.glb`) : chaque
   face prend la vue qui la voit le mieux sans obstacle (lancer de rayon) ; l'arrière = la façade
   en miroir, l'ouest = le pignon est en miroir. Les UV par défaut des cubes sont supprimés
   (sinon l'export les garde et le modèle sort sans peinture). Origine = milieu du pied de
   façade (la porte), comme un Prop. Maison : ~20 000 faces, 3 Mo, 2 matériaux.
6. **Dans Godot** : `--headless --import` ; dans `Prop.KINDS`,
   `"model": "res://assets/models/<nom>.glb"` et `solid` = emprise au sol en px (largeur ×
   profondeur, 48 px par m) ; l'image `props/<kind>.png` ne sert plus qu'à l'éditeur 2D et
   en qualité basse ;
   répliques d'examen dans `Examine.LINES` / `REACH`.
7. **Vérifier** : scénarios `tools/scenarios/maison_3d_test.gd` (porte, examen, pignon, Chloé
   derrière) et `maison_3d_heures.gd` (aube, midi, crépuscule, nuit, pluie ; commande de capture
   `camera_distance` pour voir le bâtiment entier).

**Rendu en jeu** (`relief.gdshader`, comme les décors en relief) : le maillage du .glb est
chargé une fois (cache par chemin), chaque surface reçoit un matériau `relief` avec sa
peinture importée, puis un MultiMesh par sorte (décor fixe, aperçu des zones voisines). Il est
éclairé exactement comme les images (normale d'une image debout tournée vers la caméra, pied
plus sombre ; seul le côté face au soleil suit ses vraies faces), projette et reçoit les
ombres, se retourne (`flip`) par le shader et devient transparent (un pixel sur deux, tout le
bâtiment) quand il cache Chloé. Un décor reflété (StoryProp…) de cette sorte est un
MeshInstance3D du même maillage, tant que son sprite montre l'image de sa sorte ; son fondu
(`modulate.a`) passe par l'uniforme d'instance `opacity` (tramé). Qualité basse
(`relief_props` coupé) : l'image. (L'ancien `painted_model.gdshader`, un nœud par décor, est
supprimé ; ses mesures de luminosité du 27/09 ne valent plus.)

**Limites connues** : l'arrière et l'ouest sont des miroirs (pour un bâtiment asymétrique,
peindre quatre vues) ; la peinture du modèle organique sort plus grise que l'illustration plate
(demander des murs crème et chauds dans le prompt pour s'en rapprocher) ; un seul maillage,
sans niveaux de détail.

## Points à surveiller

- Halo rose léger autour des objets lumineux (l'ambre) : la lueur se mélange au magenta ;
  régénérer ces objets sans halo et ajouter la lueur en jeu (PointLight2D).
- Chaque espèce = une planche de profil (6 cases) + une planche face/dos (8 cases), produites
  par lots, région par région (~60 espèces, voir [bestiaire.md](bestiaire.md)).
