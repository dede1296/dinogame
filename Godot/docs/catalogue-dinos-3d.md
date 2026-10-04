# Catalogue des modèles 3D de dinosaures (phase 3)

Recherche du 04/10/2026. Les licences ne comptent pas (jeu non distribué) ; on note source, URL, auteur.
Fichiers téléchargés dans `C:\Users\Greg\Dinogame\assets3d_src\dinos\` (hors projet Godot, rien converti).

## 1. Constat

L'offre **gratuite, téléchargeable sans compte, riggée et animée** tient en **deux packs** (16 dinos) :

| Pack | Auteur / URL | Contenu | Style | Triangles | Anims | Local |
|---|---|---|---|---|---|---|
| **Gobkit Free Dinosaur Pack** | Gobkit — https://gobkit.itch.io/gobkit-free-dinosaur-pack (zip direct : https://gobkit.com/freebies/dino/gobkit-dino-pack.zip, manifeste https://gobkit.com/api/free) | 10 GLB : Trex, Triceratops, Stegosaurus, Ankylosaurus, Spinosaurus, Carnotaurus, Pachycephalosaurus, Oviraptor, Pterodactylus, Plesiosaurus | cartoon très low-poly, couleurs cuites, atlas `Texture001.png` commun, squelette commun | 520 à 1 060 | **une seule piste de 120 images à 24 fps à découper** : idle 0-29 (boucle), attack 30-59, dead 60-89 (une fois), walk 90-119. Pas de run | `gobkit\dino\` |
| **Animated Dinosaur Pack** | Quaternius — https://quaternius.com/packs/animateddinosaurs.html ; GLB via poly.pizza : https://poly.pizza/bundle/Animated-Dinosaur-Bundle-SmoLdBLO2K | 6 GLB : Parasaurolophus, T-Rex, Velociraptor, Triceratops, Stegosaurus, Apatosaurus | low-poly facetté, couleurs de sommets, sans texture | 1 250 à 2 280 | **clips séparés** : Idle, Walk, Run, Attack, Jump, Death (Apatosaurus : Death nommé « Stegosaurus_Death ») | `quaternius\` |

Autres téléchargés : `gobkit\animal\` (10 animaux Gobkit, même style que le pack dino : utile pour le **Shark** → Mosasaure, Platypus, Rhino…), `mesh2motion\` (3 `.blend` CC0 : T-rex, dragon, kaiju, pour Blender ; https://github.com/Mesh2Motion/mesh2motion-assets).

Les deux packs ont un style voisin (aplats, low-poly, pas de réalisme) mais **pas identique** : Gobkit = atlas lisse et très simple, Quaternius = facettes plus détaillées. À harmoniser par un matériau commun dans Godot (voir recommandation).

Hors de ces packs : rien de gratuit dans le même style. Voir § 4.

## 2. Tableau par espèce (48)

Légende statut : **A** modèle de l'espèce, riggé/animé, téléchargé ; **B** individu nommé = modèle de son espèce, agrandi + teinte/accessoire (pas de nouvelle anatomie requise) ; **C** pas de modèle exact, mais une **espèce proche à l'anatomie compatible** est riggée : à adapter sous Blender (proportions, crête, queue, cou, cornes) en gardant le squelette, donc les animations ; **D** aucun candidat.
Chemins relatifs à `assets3d_src\dinos\`. G = gobkit\dino\, Q = quaternius\ (fichier `<Nom>_-_Free_Model_By_Quaternius.glb`).

| Espèce (id) | St. | Meilleur candidat / base | Source | Riggé / anims | Local |
|---|---|---|---|---|---|
| ankylosaurus | A | Ankylosaurus | Gobkit | oui, idle/attack/dead/walk | G\Ankylosaurus.glb |
| carnotaurus | A | Carnotaurus | Gobkit | idem | G\Carnotaurus.glb |
| oviraptor | A | Oviraptor | Gobkit | idem | G\Oviraptor.glb |
| pachycephalosaurus | A | Pachycephalosaurus | Gobkit | idem | G\Pachycephalosaurus.glb |
| plesiosaurus | A | Plesiosaurus | Gobkit | idem | G\Plesiosaurus.glb |
| spinosaurus | A | Spinosaurus | Gobkit | idem | G\Spinosaurus.glb |
| stegosaurus | A | Stegosaurus (Q plus détaillé, G plus simple) | Quaternius / Gobkit | oui ; Q : 6 clips dont run | Q\Stegosaurus ; G\Stegosaurus.glb |
| triceratops | A | Triceratops | Quaternius / Gobkit | oui ; Q : 6 clips dont run | Q\Triceratops ; G\Triceratops.glb |
| parasaurolophus | A | Parasaurolophus | Quaternius | oui, 6 clips | Q\Parasaurolophus |
| velociraptor | A | Velociraptor | Quaternius | oui, 6 clips | Q\Velociraptor |
| griffe_grise | B | Velociraptor (c'est un vieux Velociraptor, cf. .tres), vieilli/cicatrices | Quaternius | oui | Q\Velociraptor |
| velociraptor_sables | B | Velociraptor, robe pâle | Quaternius | oui | Q\Velociraptor |
| vieux_rempart | B | Ankylosaurus (mère de Bastion), plus massif | Gobkit | oui | G\Ankylosaurus.glb |
| voix_du_marais | B | Parasaurolophus (mère d'Écho), crête plus grande | Quaternius | oui | Q\Parasaurolophus |
| cryolophosaure_titan | B | grand théropode « tyran » : T-Rex + crête en éventail (Blender, léger) | Quaternius / Gobkit | oui | Q\T-Rex ; G\Trex.glb |
| allosaurus | C | T-Rex (Q) : tête plus longue, bras plus longs, crêtes sourcilières | Quaternius | oui | Q\T-Rex |
| dilophosaurus | C | Carnotaurus ou T-Rex réduit + double crête, cou fin | Gobkit | oui | G\Carnotaurus.glb |
| majungasaurus | C | Carnotaurus (abélisauridé, même famille : museau court, bras minuscules) | Gobkit | oui | G\Carnotaurus.glb |
| masiakasaurus | C | Carnotaurus réduit (abélisauridé) + dents avant projetées | Gobkit | oui | G\Carnotaurus.glb |
| nanuqsaurus | C | T-Rex réduit (tyrannosauridé) | Quaternius | oui | Q\T-Rex |
| baryonyx | C | Spinosaurus sans voile, museau de croco, griffe de pouce | Gobkit | oui | G\Spinosaurus.glb |
| suchomimus | C | Spinosaurus, voile bas | Gobkit | oui | G\Spinosaurus.glb |
| utahraptor | C | Velociraptor, massif, sans plumes ou emplumé selon DA | Quaternius | oui | Q\Velociraptor |
| deinonychus | C | Velociraptor, museau plus robuste | Quaternius | oui | Q\Velociraptor |
| troodon | C | Velociraptor, yeux/crâne arrondi, plus fin | Quaternius | oui | Q\Velociraptor |
| microraptor | C | Velociraptor miniature + 4 ailes (ajout membrane) | Quaternius | oui | Q\Velociraptor |
| compsognathus | C | Velociraptor/Oviraptor miniature, cou long, sans grande griffe | Quaternius / Gobkit | oui | Q\Velociraptor |
| therizinosaurus | C (fragile) | Oviraptor (théropode herbivore à plumes) + très longues griffes, ventre rond, cou ; forme à reconstruire largement | Gobkit | oui | G\Oviraptor.glb |
| brachiosaurus | C | Apatosaurus (sauropode : cou/queue/quatre piliers) ; il faut relever l'avant (pattes avant plus longues, cou vertical) | Quaternius | oui, 6 clips | Q\Apatosaurus |
| protoceratops | C | Triceratops réduit, collerette sans cornes | Quaternius | oui | Q\Triceratops |
| psittacosaurus | C | Triceratops réduit, bipède possible ; bec de perroquet (pose plus difficile : bipède) | Gobkit | oui | G\Triceratops.glb |
| pachyrhinosaurus | C | Triceratops, bosse nasale à la place de la corne | Quaternius | oui | Q\Triceratops |
| corythosaurus | C | Parasaurolophus, crête en demi-disque | Quaternius | oui | Q\Parasaurolophus |
| edmontosaurus | C | Parasaurolophus sans crête, bec plat | Quaternius | oui | Q\Parasaurolophus |
| iguanodon | C | Parasaurolophus sans crête, pouce-pique, plus robuste | Quaternius | oui | Q\Parasaurolophus |
| ouranosaurus | C | Parasaurolophus + voile dorsal | Quaternius | oui | Q\Parasaurolophus |
| leaellynasaura | C | Parasaurolophus miniature, tête ronde, longue queue | Quaternius | oui | Q\Parasaurolophus |
| minmi | C | Ankylosaurus réduit, sans massue | Gobkit | oui | G\Ankylosaurus.glb |
| pinacosaurus | C | Ankylosaurus, massue de queue conservée, plus léger | Gobkit | oui | G\Ankylosaurus.glb |
| stygimoloch | C | Pachycephalosaurus + épines autour du dôme | Gobkit | oui | G\Pachycephalosaurus.glb |
| elasmosaurus | C | Plesiosaurus, cou très allongé | Gobkit | oui | G\Plesiosaurus.glb |
| mosasaure_abyssal | C | Shark (Gobkit animal) allongé + mâchoire ; ou Plesiosaurus | Gobkit | oui (idle/attack/dead/walk) | gobkit\animal\Shark.glb |
| pteranodon | C | Pterodactylus + crête céphalique ; ajouter clip « vol » (battement) | Gobkit | oui (walk à adapter en vol) | G\Pterodactylus.glb |
| dimorphodon | C | Pterodactylus, grosse tête, queue longue | Gobkit | oui | G\Pterodactylus.glb |
| anurognathus | C | Pterodactylus miniature, queue courte | Gobkit | oui | G\Pterodactylus.glb |
| ichthyosaurus | D | rien de proche ; Shark Gobkit = approximation (nageoire dorsale, forme torpille) mais anatomie différente | Gobkit (animal) | oui | gobkit\animal\Shark.glb |
| archelon | D | aucune tortue riggée gratuite trouvée (poly.pizza « Turtle » : statiques, styles divers) ; à créer (carapace + 4 palettes) | — | — | — |
| koolasuchus | D | amphibien géant : aucun candidat ; à créer (à la rigueur Platypus/Hippo Gobkit comme base, à remodeler) | — | — | — |

## 3. Bilan chiffré

- **A + B (modèle direct, riggé/animé, utilisable tel quel ou teinté/agrandi) : 15 espèces** (10 A + 5 B).
- **C (variante sur squelette existant, travail Blender de remodelage ; animations héritées) : 30 espèces** (dont mosasaure_abyssal, pteranodon et therizinosaurus à risque).
- **D (rien d'exploitable) : 3 espèces** (ichthyosaurus approximé, archelon, koolasuchus).
- Statiques seuls : 0 espèce ; rien de statique n'a été retenu, car la cohérence prime (les packs statiques gratuits sont de styles variés).
- Total A+B+C = **45 / 48**, mais seules **15** sont prêtes aujourd'hui ; **30+ est atteignable** en ajoutant les variantes C (une variante = copie du mesh, sculpture/échelle des proportions, même squelette ou re-skin automatique).

Réserve : une variante C « fidèle » est un vrai travail de modélisation (le critère « jamais de recoloration » de la mémoire du projet impose de remodeler l'anatomie : crête, museau, cou, proportions). Prévoir ~20-40 min par variante simple (Parasaurolophus → Edmontosaurus) et plus pour les cas lointains (Therizinosaurus, Microraptor, Brachiosaurus, Archelon).

## 4. Sources examinées et écartées

- **Payantes** (~7 $ chacune, pas de téléchargement sans action humaine) : FSaur — Brachiosaurus (https://fsaur.itch.io/brachiosaurus), Velociraptor (https://fsaur.itch.io/low-poly-velociraptor), Triceratops (https://fsaur.itch.io/triceratops), T-rex 1 420 tris (https://fsaur.itch.io/trex-set-animation-pack) : riggés, 6-7 animations (idle, walk, run, attack, drink, call), GLB/FBX, scène de démo Godot. Même auteur donc style cohérent : **meilleur complément si Greg accepte d'acheter** (Brachiosaurus surtout). Cute Cartoon Dinosaurs Pack (6 dinos colorés, 17 anims, https://superhivemarket.com/products/cute-cartoon-dinosaurs-pack-fully-rigged-animated-3d-characters) : style enfantin, mal assorti.
- **Payants, statiques** : Akochan Low Poly Dinosaur Pack, 60 modèles, ~3 100 tris, GLB, 3,99 $ (https://akochan-lu.itch.io/low-poly-dinosaur-pack-60) : pas riggé, mais beaucoup d'espèces, à rigger/animer soi-même (Mesh2Motion). Ultimate Dinosaurs Pack (uqel, 18,88 $, .rbxm Roblox, statique) : inexploitable.
- **GitHub MyDinoEncyclopedia/3D-Models** : Allosaurus, Brachiosaurus, Gallimimus, Spinosaurus, Velociraptor, Plesiosaurus, quelques animés ; mais modèles réalistes de 5-25 Mo chacun, styles mélangés, provenance Sketchfab : rejeté (cohérence et poids).
- **poly.pizza** : hors le pack Quaternius, que des modèles isolés disparates (Diplodocus, Armored Brachio, Sea Monsters, Long-Necked Turtle…, statiques ou non animés), non retenus.
- **Sketchfab** (collections « Low Poly Dinosaurs », ex. https://sketchfab.com/vendol21/collections/low-poly-dinosaurs-5564da5c0a6941aababd73caec03b161) et **Fab**, CGTrader, TurboSquid, Free3D : téléchargement exigeant un compte/jeton, donc non téléchargé ; styles mélangés.
- **OpenGameArt** : quelques Brontosaure / Dromaeosaure low-poly isolés, non vérifiés ; **Kenney** : aucun dinosaure.
- **Mesh2Motion** (https://github.com/Mesh2Motion/mesh2motion-assets, outil web gratuit) : auto-rigging d'un mesh statique sur des squelettes quadrupède/oiseau/dragon avec bibliothèque d'animations, CC0. À évaluer pour rigger les variantes ou le pack Akochan.

## 5. Recommandation

**Pack de base : Gobkit (10 dinos) + Quaternius (6 dinos)**, soit 16 modèles de style voisin, rigs minuscules (500 à 2 300 triangles, adaptés à la GTX 1650 Ti avec des dizaines de dinos à l'écran).

1. **Homogénéisation** : donner aux 16 modèles un même matériau Godot (palette ou ombrage cartoon commun, mêmes contours/éclairage) ; mettre Quaternius à l'échelle de Gobkit ou l'inverse. Préférer en cas de doublon (Stegosaurus, Triceratops, T-Rex) un seul pack par espèce, de préférence **Quaternius** (6 clips séparés dont Run, plus détaillé) pour les 6 espèces qu'il couvre, et Gobkit pour les 7 qu'il est seul à couvrir. Le décalage de style est le principal risque : à valider par un essai visuel (une scène avec Gobkit Ankylosaurus et Quaternius Triceratops côte à côte) avant d'engager le reste.
2. **Animations** : table générique `idle/walk/run/attack/sleep/eat` → clip. Gobkit : découper la piste unique en 4 `Animation` par plages d'images (24 fps) à l'import ; pas de run (utiliser walk accéléré), pas de sleep ni eat (idle ralenti / pose couchée à créer pour « dort », attaque abaissée pour « mange »). Quaternius : clips prêts, pas de sleep/eat non plus. **Sleep, eat, vol, nage** sont à créer pour tous (AnimationPlayer ou Blender), en s'appuyant sur les règles du projet (un dino ne se couche que s'il dort).
3. **Combler les trous** :
   - 30 espèces C : variantes Blender sur le même squelette, par familles (abélisauridés/Carnotaurus ; spinosauridés/Spinosaurus ; tyrannosauridés/T-Rex ; dromaeosauridés/Velociraptor ; ceratopsiens/Triceratops ; hadrosaures/Parasaurolophus ; ankylosaures/Ankylosaurus ; ptérosaures/Pterodactylus ; plésiosaures/Plesiosaurus). Commencer par les plus proches : majungasaurus, suchomimus, baryonyx, edmontosaurus, corythosaurus, iguanodon, ouranosaurus, pachyrhinosaurus, protoceratops, utahraptor, deinonychus, nanuqsaurus, allosaurus, minmi, pinacosaurus, stygimoloch, elasmosaurus → 17 espèces faciles = 15 + 17 = **32 espèces, l'objectif de 30 atteint** sans rien acheter.
   - Cas durs (microraptor, therizinosaurus, brachiosaurus, mosasaure, pteranodon en vol, dilophosaurus, psittacosaurus, leaellynasaura, compsognathus, troodon, masiakasaurus, dimorphodon, anurognathus) : phase suivante.
   - D : Archelon, Koolasuchus, Ichthyosaurus à modéliser (deux packs de base donnent leur squelette type : quadrupède/Plesiosaurus pour Archelon, Shark pour Ichthyosaurus) ; ou acheter/rigger via Mesh2Motion.
   - Option payante peu coûteuse : FSaur Brachiosaurus (7 $) pour un vrai brachiosaure ; Akochan 60 pack (4 $) comme source de silhouettes pour les variantes C ou à rigger avec Mesh2Motion.
4. **Étape suivante conseillée** : essai de style (Godot) avec 3 modèles, puis le pipeline d'import (découpe des clips Gobkit, table générique), puis les variantes C par lots de famille.
