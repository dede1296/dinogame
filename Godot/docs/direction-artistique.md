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
| Chapitre 6, Pachyrhinosaurus : planche de profil et face/dos | `assets/art/dinos/pachyrhinosaurus.png`, `_face_dos.png` | nano-banana, 2 essais : garde deux petites cornes frontales recourbées et une bosse plutôt sur la joue que sur l'arête du nez ; la collerette n'a pas nettement deux pointes recourbées isolées | Redemander la tête seule : bosse nasale plate et rugueuse bien centrée sur le museau, cornes frontales effacées, collerette à deux pointes bien détachées |
| Chapitre 6, Cryolophosaure Titan : planche face/dos | `assets/art/dinos/cryolophosaure_titan_face_dos.png` | nano-banana a dessiné la crête en éventail bien plus large que sur la planche de profil (cohérente en soi mais disproportionnée par rapport au profil) ; léger halo rose près du souffle de buée (fond magenta mal détouré) | Redemander avec la même taille de crête que le profil ; retirer le halo rose |
| Chapitre 6, edmontosaurus/minmi : planches de profil | `assets/art/dinos/edmontosaurus.png`, `minmi.png` (sources `generated_imgs/edited-...-9xsb0x.jpg`, `-a5fmgf.jpg`) | nano-banana a dessiné 3×3 (9 poses) au lieu de 3×2 deux fois de suite (signalé par l'agent mécaniques) ; recomposées en 3×2 par `tools/art-jobs/monts.mjs` (`recompose3x3to3x2` : découpe en 3×3, union alignée, 6 cases choisies à la main) plutôt que retenter une 3e fois | Repropre : redemander proprement en 3×2 si on veut les 3 poses écartées (edmontosaurus : la cabrée gueule ouverte, tête tronquée en haut de sa case ; minmi : la case (1,0) trop claire/orangée) |
| Chapitre 6, statue_cryolophosaure | `assets/art/props/statue_cryolophosaure.png` | nano-banana, gardé : la crête se lit un peu comme une crête simple verticale plutôt que clairement transversale (c'est une statue patinée, moins critique que sur l'espèce jouable) | Vérifier une fois la vraie espèce en jeu ; redemander si la crête ne se lit pas comme un éventail transversal |
| Chapitre 6, neige_chemin.png | `assets/art/ground/neige_chemin.png` | nano-banana, 2 essais : se lit plus comme des cailloux dans la neige que comme un chemin tassé net (les bords ocre du chemin d'origine ont disparu) | Redemander avec des bords bien plus sombres/gris que le terrain autour, sans cailloux apparents |
| Chapitre 6, sol_grotte_glace.png | `assets/art/ground/sol_grotte_glace.png` | nano-banana a gardé des éclats d'ambre orangés hérités de `grotte_sol.png` (texture d'origine) au lieu d'un sol de glace uni | Redemander sans les éclats d'ambre si on les trouve trop présents en jeu (actuellement jugé passable, cohérent avec le thème de l'ambre) |
| Chapitre 7, Isaure sans masque (3e version, 11/10 soir) | `characters/isaure_sans_masque.png` (anciennes : `_v1`, `_v2`), `_assise.png` (ancienne `_assise_v2.png`) | nano-banana : UN seul visage sur toutes les cases (la v2 mélangeait deux visages en rangée de face) ; mi-quarantaine à cinquantaine, cernes, rides fines, gris dans le chignon ; encore un peu doux vu la taille chibi. **Greg à valider** | Si trop vieille ou trop douce : un 4e essai ; l'assise a été tracée avec des traits de grille effacés par `eraseGridLines` |
| Chapitre 7, vieux_harnais / masque_obsidienne / nuage_bas / arche_vent_loin | `props/vieux_harnais.png`, `masque_obsidienne.png`, `nuage_bas_1..4.png`, `arche_vent_loin.png` | nano-banana, 1er essai gardé ; le masque ressemble un peu à un galet noir à fentes (pas de relief de visage) ; `arche_vent_loin` est faite SANS génération (teinte, désaturation et flou de `arche_vent.png`) car nano-banana rendait un fond en dégradé impossible à détourer : ses détails (spirales, plumes) restent devinables | Redemander une arche lointaine nette sur fond magenta ; masque : ajouter un nez et un menton marqués |
| Chapitre 7, Quetzalcoatlus : membranes de vol | `dinos/quetzalcoatlus_vol.png`, `_vol_face_dos.png` (anciennes : `_v1.png` ; le combat dans le ciel lit ces planches) | refaites gris-blanc (elles sortaient saumon) ; la planche de marche garde des ailes repliées crème-beige : accord moyen | Les passer en gris si on les juge trop beiges |
| Chapitre 7, vol de profil : 2 images sur 4 identiques | `dinos/{quetzalcoatlus,hatzegopteryx,tupandactylus,tapejara}_vol.png` | nano-banana : 4 poses demandées, mais la pose « mi-haute » sortait à chaque essai avec un filé rose flou (3 essais) : cycle haut / plané / bas / plané (3 poses distinctes) | Redemander la pose mi-haute seule, nette |
| Chapitre 7, vol face/dos : pose « ailes basses » | `dinos/*_vol_face_dos.png` | nano-banana : la 3e colonne est parfois très repliée (ailes en U) ; tupandactylus de face : 4e pose avec la tête tournée de 3/4 | Redemander ces cases |
| Chapitre 7, `chloe_vol*.png` (3e version, 11/10) | `characters/chloe_vol.png`, `chloe_vol_manteau.png` (anciennes : `_v2.png`) | Assise à califourchon : cuisse en avant, genou plié à environ 90°, une seule jambe de profil, jambes écartées de face et de dos, mains sur les poignées ; réduite à 75 % autour du point d'assise (bassin à ±2 px de la 2e version) ; de profil gauche la jambe pend presque droite ; face de `chloe_vol` : yeux fermés (rire) | Si le calage ne plaît pas : `SHRINK` dans `cieux_persos.mjs` |
| Chapitre 8, daspletosaurus / saichania : ressemblance avec leurs voisins | `dinos/daspletosaurus*.png`, `saichania*.png` | Daspletosaurus : éditée depuis l'Allosaurus, silhouette de profil proche (tête plus lourde, corps plus trapu seulement de face/dos) ; Saichania : éditée depuis l'Ankylosaurus, même ocre (les cornes du crâne et les épines plus petites la distinguent) | Si on les confond en jeu : Daspletosaurus plus trapu de profil (crâne plus haut, cou plus court), Saichania plus pâle/grise |
| Chapitre 8, lave : sol non animé | `ground/lave.png` | Une seule image raccordable (nano-banana ne fait pas de planche animée) ; l'animation se fait par défilement/shader du sol | Au besoin, une planche de 4 images décalées |
| Chapitre 8, autel_magma_fendu : lueur recolorée | `props/autel_magma_fendu.png` | La lueur de la fente, peinte sur le magenta, sortait rose : repeinte en orange par `recolor()` (tools/art-jobs/volcan_decors.mjs) | Redemander l'autel fendu avec la fente éclairée sur un fond d'une autre couleur |
| Chapitre 8, fiche de Brac assis : colonnes recomposées | `characters/brac_assis_cage.png` | nano-banana a dessiné 6 colonnes au lieu de 4 : recomposées en 4 ; la rangée du bas (debout, inutilisée) a son profil gauche = le droit retourné | Rien si la rangée du bas reste inutilisée |
| ~~Chapitre 8, trex_magma de face : fumée~~ fait le 19/10 (passe finale) | `dinos/trex_magma_face_dos.png` (anciennes : `_v1`, `_v2`, `_v3`) | nano-banana, cellule par cellule (tête agrandie sur magenta, consigne restrictive) : deux petits filets de fumée blancs sortent des naseaux et montent le long du museau ; tête recomposée sur le corps d'origine, dos intact | Rien (têtes très légèrement plus rondes qu'avant, invisible en jeu) |
| Chapitre 9, Souverain : planches 3×2 et vue de dos | `dinos/souverain*.png` | nano-banana a dessiné 3×3 (9 poses) : recomposées en 3×2 par `apex_especes.mjs` (cases choisies) ; l'attaque saine a la gueule ouverte, l'apaisé n'en a pas ; de dos, la queue épaisse se lit un peu comme un triangle clair | Redemander la vue de dos avec la queue plus fine et le cou visible si on le prend pour un ankylosaure |
| Chapitre 9, Souverain couché : couleurs | `dinos/souverain_couche.png` | la version apaisée est plus grise que `souverain_apaise.png` (olive) ; les deux rangées sont quasi identiques | Les harmoniser si on les met côte à côte en jeu |
| ~~Chapitre 9, portail ouvert~~ fait le 19/10 | `props/portail_apex_ouvert.png` (ancienne : `_v1`) | nano-banana : cinq disques (2+3), même cadrage 462×475 | Rien |
| Chapitre 9, bloc du Souverain : la forme dedans | `props/bloc_souverain*.png` | l'animal piégé a des pointes d'ankylosaure sur le dos (plus que les plaques lisses de l'espèce) | Redemander avec `souverain.png` en référence |
| Chapitre 9, `isaure_helene` | `props/isaure_helene.png` | dessinée en gros plan (têtes plus grandes que les sprites), Isaure aux cheveux plus gris que sur sa planche | À refaire en chibi si elle jure avec les sprites en jeu |
| Chapitre 9, Hélène assise : profils | `characters/helene_assise.png`, `helene_sol.png` | profil droit = profil gauche retourné (fauteuil et assise au sol) ; rangée « debout soutenue » : le bras tendu est retourné avec le profil | Dessiner les deux profils si le bras tendu se voit mal |
| Chapitre 9, `helene.png` : ordre des rangées | `characters/helene.png` | éditée depuis `bertille.png`, qui a la rangée du dos EN PREMIER (ordre du jeu : face, gauche, droite, dos) : rangées remises dans l'ordre du jeu après découpe | ~~Vérifier `bertille.png`~~ fait le 19/10 : `helene.png` est correcte (face, gauche, droite, dos ; 4×4 de 133×184, personnage de 176 px comme roc/bertille/maia), rien à corriger |
| Finitions ch. 8-9 (19/10) : Hélène sans fauteuil | `characters/helene_assise_sans_fauteuil.png` (960×368, 2×4 cases de 240×184 ; anciennes : `_v1`, `_v2`, `helene_assise.png`) | nano-banana : vue de dos assise refaite (passe finale 19/10) : tête plus grosse (proportion des autres vues), jupe resserrée ; autres cases intactes | Rien ; à regarder sur le fauteuil de Roc |
| Finitions ch. 8-9 : Firmin sans masque | `characters/firmin_sans_masque.png` (400×736, 4×4 de 100×184 comme `sbire.png`, 4 pas par rangée) | nano-banana, depuis `sbire.png` : capuche baissée, cheveux roux-brun, barbe de trois jours, sans pioche ni masque ; dos refait (capuche baissée) | Rien ; à brancher dans `actors/outfits.gd` / `apex_decor.gd` (`FIRMIN`) |
| Finitions ch. 8-9 : Maïa sur la pierre, manteau de `maia_arche` | `characters/maia_pierre.png` (1040×480, 2×4 de 260×240 ; ancienne : `maia_pierre_v1.png`) | nano-banana, deux rangées refaites (assise et debout) avec le manteau bleu pâle à fourrure ; la pierre est redessinée un peu plus petite et plus haute | Si la pierre jure avec le décor, la redemander plus large ; rangée du bas inutilisée |
| Finitions ch. 8-9 : Léonce au port | `characters/leonce_port.png` (464×736, 4×4 de 116×184 comme `pecheur.png` ; anciennes : `_v2`, `_v3`) | nano-banana, depuis `sbire.png` + visage de `leonce_assis.png` : sans masque ni capuche, filet à flotteurs sur l'avant-bras, navette à la main, cape sombre ; trou du bas du filet (case de face) rebouché par script le 19/10 | Rien |
| Corrections 19/10 : Maïa arche assise, Léonce assis | `characters/maia_arche_assise.png`, `leonce_assis.png` (anciennes : `_v2`) | Maïa : têtes de la rangée assise agrandies de 24 % par script (≈ têtes de `maia_assise.png`) ; Léonce : case 2 = case 1 en miroir (cape alignée sur les autres cases) | Rien (retouches par script, pas par nano-banana) |

## Plaine Volcanique (art, chapitre 8, 17/10)




Images du chapitre 8 (agent IMAGES, jobs `tools/art-jobs/volcan_especes.mjs`, `volcan_decors.mjs`, `volcan_persos.mjs`, sorties par
`node Godot/tools/process-art.mjs <chemin>` depuis la racine du dépôt ; **toujours un chemin précis** comme `dinos/styracosaurus.png`
ou `props/forge_allumee.png` : un nom court comme `_corrompu.png` relance aussi les anciens jobs). Aucune image existante n'a été touchée
(`cage.png` et `pierre_plate.png` existaient déjà : mes versions s'appellent `cage_fermee` et `pierre_plate_volcan`). **Aucun repli ComfyUI :
tout est fait avec nano-banana.**

| Quoi | Fichiers | Format |
|---|---|---|
| Espèces (profil + face/dos) | `dinos/{styracosaurus,saichania,daspletosaurus,trex_magma}.png` + `_face_dos.png` | profil 3×2 cellules 248×198, 218×153, 266×223, 300×268 ; face/dos 4×2 même cellule |
| Corrompus (profil seul, veines lilas, yeux blanc-violet, éclats d'ambre noir) | `dinos/{styracosaurus,saichania,daspletosaurus,allosaurus,majungasaurus}_corrompu.png` | 3×2, cellule de l'espèce saine (allosaurus 262×218, majungasaurus 246×208) |
| Sols | `ground/{cendre,roche_noire,lave,croute_refroidie,obsidienne}.png` | 512×512 raccordables (lave : fixe) |
| Forges | `props/{forge_allumee,forge_eteinte,forge_eteinte_2,forge_eteinte_3,grande_forge_allumee,grande_forge_eteinte}.png` | PNG détourés |
| Cages, barricade, fût | `props/{cage_fermee,cage_ouverte,cage_grande,barricade,barricade_tombee,fut_ambre_noir}.png` | idem (la `cage` d'origine reste utilisable) |
| Atelier de Suie et de Brac | `props/{enclume,auvent,soufflet,marmite,etabli_suie,gants_gris,traineau_roues,masque_os_sol,pierre_plate_volcan}.png` | idem |
| Sanctuaire et porte | `props/{vasque_source,autel_magma,autel_magma_fendu,coque_lave,lave_paroi,torche,plaque_fer,portail_apex,camp_helene}.png` | idem (`plaque_fer` vierge : numéros écrits par le jeu ; `coque_lave` = îlot de croûte refroidie, lecture libre de « coque ») |
| Interface | `ui/{sceau_volcan,antidote_ambre,lettre_isaure}.png` | 160×160 |
| Fond de combat | `battle/volcan.jpg` | 1920×1072, cadrage de `cieux.jpg` |
| Personnages | `characters/dame_suie_sans_lunettes.png` (4×4, 94×184), `brac_assis_cage.png`, `leonce_assis.png` (2×4, 240×184), `maia_pierre.png` (2×4, 260×240 : la pierre est dans le dessin) | rangée 1 = assis [face, gauche, droite, dos], rangée 2 = debout (échelle, inutilisée) |

Méthode : nano-banana édite une planche du jeu (Tricératops, Ankylosaurus, Allosaurus pour les espèces ; `terre`, `palissade`,
`cage`, `tente`, `boite_fer`, `sceau_cieux`, `battle/cieux.jpg` pour le décor ; `dame_suie`, `brac`, `sbire_assis`, `maia_assise`
pour les personnages) avec l'anatomie réelle dans le prompt ; fond magenta ; `align: "bottom"` + `isolate` pour les profils.
Chloé « montée » pour la lave : la planche `chloe_selle*.png` (profil, face, dos) existe déjà et suffit, rien de dessiné.

## Terre des Apex (art, chapitre 9, 19/10)

Images du chapitre 9 (agent IMAGES, jobs `tools/art-jobs/apex_especes.mjs`, `apex_decors.mjs`, `apex_ui.mjs`, `apex_persos.mjs`, sorties par
`node Godot/tools/process-art.mjs <chemin précis>`, jamais un nom court). Aucun fichier existant touché. **Aucun repli ComfyUI : tout est fait avec nano-banana.**
Les quatre dinos d'Isaure (Hauban, Bouline, Étrave, Carène) sont des espèces existantes (`pteranodon`, `baryonyx`, `suchomimus`, `archelon`) : rien de nouveau.

| Quoi | Fichiers | Format |
|---|---|---|
| Le Souverain (nouvelle espèce : archosaure archaïque ~12 m, quadrupède bas, tête longue de théropode, double rangée de plaques veinées d'ambre) | `dinos/souverain.png` + `souverain_face_dos.png` | profil 3×2 cellules 475×228 (hauteur de cadre 220), face/dos 4×2 même cellule |
| Variantes | `dinos/souverain_corrompu.png` (veines violettes, éclats d'ambre noir, yeux blanc-violet, effrayé, sans blessure), `souverain_apaise.png` (veines éteintes, brun-gris, yeux calmes) | 3×2, cellule 475×228 (pas de face/dos : shader comme les autres corrompus) |
| Couché, yeux ouverts | `dinos/souverain_couche.png` | 3×2 cellules 385×228 : colonnes = veines d'ambre / corrompu / apaisé (les deux rangées = même pose, légère variation) |
| Sols | `ground/{roche_apex,roche_apex_fond,veines_ambre,veines_ambre_blanc,veines_ambre_or}.png` | 512×512 raccordables ; les trois `veines_ambre*` = même dessin, lueur ambre / blanche (éveil) / or (après) : à fondre par le jeu |
| Grand bloc | `props/{bloc_souverain,bloc_souverain_fendu,bloc_souverain_eclate}.png` | 824×1039, 811×1039, 798×684 (le Souverain et Hélène dedans) |
| Blocs des géants | `props/bloc_geant_{1,2,3,4}.png`, `cairn_helene.png` | 671×848 (×3), 342×413, 64×54 |
| Portail | `props/portail_apex_ouvert.png` | 462×475 (même empreinte que `portail_apex.png`) |
| Petits objets | `props/{tasse_bleue,caisse_carnets,torche_eteinte,masque_carton_sol,isaure_helene}.png` | 69×78, 100×106, 60×125, 52×41, 132×130 |
| Interface | `ui/insigne_gardienne.png` | 160×160 |
| Fond de combat | `battle/apex.jpg` | 1920×1072, cadrage de `volcan.jpg` |
| Hélène (nouveau) | `characters/helene.png` (4×4 : face, gauche, droite, dos ; chapeau de paille, canne), `helene_assise.png` (2×4 : fauteuil + couverture + moufles rouges, rangée 2 debout), `helene_sol.png` (2×4 : assise au sol, puis debout soutenue un bras tendu) | 133×184, 240×184, 240×184 par case |
| Isaure | `characters/isaure_masque_carton.png` (4×4, le masque de Maïa à la main) | 138×184 par case ; ses cheveux sont déjà attachés dans `isaure_sans_masque.png` |

Méthode : nano-banana édite une planche du jeu (Ankylosaurus pour le Souverain ; `roche_noire`, `ambre`, `portail_apex`, `banc`, `torche`, `volcan.jpg`, `sceau_marais` pour le décor ; `bertille`, `roc_assis`, `isaure_sans_masque*` pour les personnages) avec l'anatomie / la tenue dans le prompt. Le Souverain : le premier essai de face/dos recopiait l'Ankylosaurus (cornes, tête d'ankylosaure), refait en ne donnant que le profil du Souverain comme image.
Pas de `banc` nouveau (`props/banc.png` existe) ; le carton « Ambrelune » et les pages 39/40 sont du texte écrit par le jeu, sans image ; `moufles.png` et `masque_carton.png` (ui) existent déjà. Caillou, Maïa, Brac : planches existantes (`triceratops` pose d'attaque, `maia_arche`, `brac_assis_cage`), aucune variante dessinée.

## Échelle et conventions

Images du chapitre 7 (agent IMAGES, tout dans des jobs `tools/art-jobs/cieux_especes.mjs`, `cieux_persos.mjs`,
`cieux_decors.mjs`, sorties par `node Godot/tools/process-art.mjs <nom>` depuis la racine du dépôt ; `npm install` à la
racine d'abord si `node_modules` manque). Aucune image existante n'a été touchée. **Les crédits nano-banana se sont épuisés
brièvement le 11/10 à 13 h 34, puis rechargés : tout a été refait avec nano-banana (aucun repli). Reste : voir « À refaire » (lignes « Chapitre 7 »).

| Quoi | Fichiers | Format |
|---|---|---|
| Espèces (profil + face/dos) | `dinos/{rhamphorhynchus,tapejara,tupandactylus,hatzegopteryx,quetzalcoatlus}.png` + `_face_dos.png` | profil 3×2, cellules 184×158, 214×188, 225×198, 275×223, 280×228 ; face/dos 4×2, même cellule (specs_planches.md) |
| Vol de profil et de face/dos | `dinos/{quetzalcoatlus,hatzegopteryx,tupandactylus,tapejara}_vol.png` ; `_vol_face_dos.png` + `pteranodon_vol_face_dos.png` | profil 4×1 cellule 380×230 ; face/dos 4×2 (ailes en V, plané, basses, plané), cellule minimale par espèce, plané calé sur celui du profil (±1 %) |
| Chloé en vol | `characters/chloe_vol.png`, `chloe_vol_manteau.png` | 4×1, cellule 150×228 (ordre de `chloe_selle.png` : face, gauche, droite, dos) |
| Isaure sans masque, Maïa des Cieux | `characters/isaure_sans_masque.png` (+ `_assise.png` 2×4 cases 240×184, `_v1.png` première version), `maia_arche.png` | 4×4, cellule 135-137×184 (Isaure 1,70 m comme le Masque, Maïa 1,50 m) |
| Sols | `ground/{nuages,pierre_cieux,nid,pont_lianes}.png` | 512×512 raccordables |
| Décors | `props/{nid_cieux,nid_cieux_vide,piton_haut,piton_bas,rochers_cieux,plume_geante_1..3,drapeau_vent_1,2,pont_lianes_h,pont_lianes_v,pilier_pont_1,2,pont_lianes_rompu,arche_vent}.png` | PNG détourés (arche_vent 1200×890 : un seul morceau, deux piliers + voûte, ouverture transparente) |
| Interface | `ui/{sceau_cieux,harnais_vol,meteo_vent}.png` | 160×160 |
| Fond de combat | `battle/cieux.jpg` | 1920×1072, cadrage de `monts.jpg` (deux plateaux de pierre, mer de nuages) |

Méthode : nano-banana édite une planche du jeu (Ptéranodon pour les espèces, `chloe_selle*.png`, `masque.png` avec
`isaure.png` en référence du visage, `maia.png`, `monts.jpg`…) ; l'anatomie réelle est dans chaque prompt ; fond magenta ;
`sheet({ align: "bottom", isolate: true })` pour les profils (les ailes de la pose d'attaque débordaient de leur case) ;
`composeFourColumns` quand une planche face/dos sort à 6 colonnes ; `alignWithBase` recale les pas des personnages.
Pièges : un format 8:1 donne des images floues (la planche de vol est à demander en 2×2 ou 4:1) ; nano-banana garde la mise
en page de la planche de départ (3×2) même quand on en demande une autre ; un magenta terne (non #FF00FF) laisse un halo
rose (`flattenBackground`). Les ombres ne sont pas peintes. Le Quetzalcoatlus « Roi » est la même planche (cicatrices sur
la membrane, bec et crête ambre, duvet gris-blanc).

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

## Retouches du 18/10 (agent IMAGES)

Faites avec nano-banana (aucun repli ComfyUI), anciens fichiers gardés à côté (`_v1` ou `_avant`), jobs/notes dans `tools/art-jobs/retouches_volcan.mjs` :
poteau_lianes (bouts de corde pendants effacés par script), `battle/volcan.jpg` (plumes et drapeau retirés), `leonce_assis` (masque d'os réduit à ~45 %, cellule par cellule),
`trex_magma` (6e pose : gueule ouverte, rugissement), `trex_magma_face_dos` (fumée des naseaux), `chloe_vol` / `chloe_vol_manteau` (vue de face recentrée par décalage de pixels, sans nano-banana).

## Cinématiques (intro et fin) — 19/10/2026

Toutes les peintures sont dans `assets/art/cinematiques/` (2560×1440, nano-banana en 2752×1536 réduit proprement ; générées en édition à partir des planches et de l'écran titre). Cheveux de Chloé auburn (décision de Greg). Intro : `intro_01`…`intro_09` + `intro_05_carte_vide` ; fin : `fin_01`…`fin_09`, `fin_06_dinos_{base,vif,bastion,echo}`, `fin_09_journal_sans_trait` ; `credits_fond` (sert aussi à F-10, le carton « Ambrelune » est du texte moteur).

Corrigés le 19/10 (passe de cohérence, édition nano-banana en gardant composition et style) : `fin_03` (Isaure en tenue sombre de marin, manches retroussées, mains nues ; forge sans toit, briques et pièces au sol), `fin_05` (visage de Chloé repris sur `intro_07`, insigne épinglé à plat sans cordon), `fin_07` (Mastoc tient la lanterne dans la gueule, tête d'Allosaurus de sa planche — son rouge-orangé est bien celui de la planche —, « Z » supprimés), `fin_06_dinos_echo` (Parasaurolophus vert sauge à rayures, crête et bec corail ; l'oiseau se bouche les oreilles), `fin_06_dinos_vif` (silhouette du fond retirée), `fin_08` (Souverain : petites écailles/bosses, plus de grandes plaques), `fin_09_journal` et `_sans_trait` (écriture d'Hélène remplacée par un gribouillis manuscrit illisible dessiné par script, « — H. » conservé ; les deux images restent superposables), `intro_05_carte_vide` (compas et fougère repris pixel pour pixel de `intro_05_carte` : se superposent).

Passe finale du 19/10 (agent IMAGES, `tools/art-jobs/retouches_final.mjs`) : Isaure harmonisée (intro_07/08/09 : casquette de marin, écharpe rouge, tenue de sa planche `isaure.png` ; fin_02/fin_04 : chignon gris, vêtements sombres de `isaure_sans_masque.png`), `fin_06_dinos_bastion` (Ankylosaurus ocre de sa planche, lichen discret, massue de queue lisible, Maïa avec sa corde), `fin_06_dinos_base` (fumée du volcan retirée, comme les trois variantes), `intro_05_carte` et `_vide` (boussole sans lettres ni chiffres, repères gravés ; cadran collé à l'identique sur les deux), `intro_04` (œuf corail allongé). `fin_01` : vérifié, volcan et cheminées sans fumée. Cohérence de Chloé vérifiée dans toutes les peintures (auburn, barrette, taches de rousseur, sac, gilet) : rien à corriger.

Retouches « Fable » du 19/10 (agent IMAGES, nano-banana, collées par masque flouté pour ne toucher que la zone voulue) : `fin_08_souverain` (trois blocs d'ambre sombre veinés d'or au fond du cratère, avec un sauropode, un théropode et un cératopsien couchés : les « blocs des géants » ; Souverain, ciel et mer inchangés) ; `intro_05_carte` (à l'encre : trois cheminées de forge qui fument et un petit masque d'os près du « ? » du volcan, zone 800-1700 × 500-1050 seulement). `intro_05_carte_vide` NON touchée : la carte et la carte vide restent superposables, l'encre en plus.

Défauts connus restants (courts, sans gravité) :
- `intro_05_carte` : cheminées et masque sont légèrement colorés (beige) plutôt qu'en encre brune pure ; à refaire avec nano-banana si Greg le veut plus « trait ». `fin_08_souverain` : les blocs sont un peu gros pour des « hameaux de géants ».
- `fin_08_souverain` : la spirale de l'île reste approximative (non retouchée : pas simple sans toucher au Souverain).
- `fin_09_journal` : les gribouillis ont un air régulier de près (le moteur peut les flouter).
- `fin_02_barque_visiteurs` : Isaure change peu (déjà proche de sa planche) ; l'édition a aussi légèrement redessiné de petits détails.
- `intro_04_oeufs` : l'œuf corail, désormais très long, touche presque le petit mot collé sur le dôme.

## Diagonales de Chloé

Planches de marche en trois-quarts (19/10) : `characters/chloe_diag.png`, `chloe_bottes_diag.png`, `chloe_manteau_diag.png`.
Cellules de la planche de base (123×184, 122×185, 143×184), 4 colonnes (cycle de marche : jambes ensemble, grand pas, pied arrière levé,
pied avant en balancement) × 2 lignes : 0 = bas-gauche (trois-quarts face), 1 = haut-gauche (trois-quarts dos). Les diagonales droites
sont affichées en miroir horizontal. Hauteur dessinée ≈ 175 px, pieds 4 px au-dessus du bas de la cellule. Méthode : `tools/art-jobs/diagonales_chloe.mjs`.
À refaire avec nano-banana si le pas inverse (autre jambe devant) est jugé nécessaire.
