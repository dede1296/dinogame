# Ambrelune — Godot

**Base principale et unique** du développement d'Ambrelune depuis le 2026-09-26 : **Godot 4.7**,
renderer **Mobile**, **Android d'abord** (paysage, tactile). La version Phaser (`../nouveau/`)
n'évolue plus : elle sert de **référence** (mécaniques, données, dialogues, art, sons). Rien ici ne
la modifie ; les assets réutilisés y sont *copiés*, jamais déplacés.

**Rendu 2,5D** : le monde se joue en 2D (physique, collisions, sorties, rencontres, sauvegarde
restent en 2D) et s'affiche en 3D par une couche de vue (`world/view3d/`) : sol en relief
(niveaux, falaises, rampes, eau creusée), décor et personnages dessinés debout face à la caméra,
soleil et lune avec ombres, brume, flou lointain, caméra inclinée zoomable (pincement, molette,
réglage). Aucun nœud 2D du monde n'est dessiné ; la caméra 2D sert encore au son positionnel.

Contenu actuel (vertical slice) : le prologue (Port-Ambre, le Cabinet du Pr Roc, le choix du
petit), puis les **Plaines des Fougères** en **une seule grande carte ouverte** (120 × 90 cases :
route du port, carrefour, étang, anse et sa plage, bosquet d'Hélène derrière le tronc à trancher
(**Tranche**), Grotte des Échos dans sa colline derrière le rocher (**Charge**), falaises derrière
la porte d'ambre (**Résonance**) avec le poste d'observation d'Hélène, Grand Crâne et l'antre de son Alpha),
bordée de montagnes, de forêt et de mer ; la carte du monde qui se dévoile en explorant ; jour et
nuit, météo, habitats par lieu et par heure, la barre d'équipe, les pages du journal d'Hélène,
la sauvegarde locale, les contrôles tactiles, la musique et l'ambiance sonore.

**La bible du jeu** (lore, histoire complète, mécaniques, bestiaire) est dans `docs/` :
[lore](docs/lore.md) · [histoire](docs/histoire.md) · [mécaniques](docs/mecaniques.md) ·
[bestiaire](docs/bestiaire.md).

## Lancer

- **Éditeur Godot** : ouvrir `Godot/project.godot` (Godot 4.7.2), F5.
- **VS Code** : ouvrir `Godot/ambrelune-godot.code-workspace` (Fichier › Ouvrir l'espace de
  travail à partir d'un fichier…), ou ouvrir directement le dossier `Godot/`. **Pas** le dossier
  `Dinogame` seul : l'extension *godot-tools* ne s'active que si `project.godot` est à la racine
  d'un dossier ouvert. Puis F5 (« Ambrelune (Godot) »).
  Pour que le débogueur et l'autocomplétion GDScript de VS Code parlent à Godot, laisser
  l'éditeur Godot ouvert (serveur de langage sur le port 6005).
- **Ligne de commande** :
  ```
  "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --path Godot
  ```

Contrôles : flèches/ZQSD-WASD ou manette pour bouger, Espace/Entrée/E (ou A) pour interagir,
M (ou le bouton carte sous ☰) pour la carte, F3 (ou tap à trois doigts) pour afficher ou masquer l'overlay de performances (masqué au lancement).

**Mode débogage** : appui long sur l'horloge (en haut à droite) ou F2 : changer l'heure et la
vitesse du temps, forcer la météo (beau temps, pluie, brume), mettre n'importe quelle espèce en
tête d'équipe ou la combattre, soigner, donner de l'expérience ou des objets, aller dans une zone,
afficher les performances. À masquer avant une vraie sortie publique.

## Organisation

```
core/       autoloads : Quality (niveau graphique), Game (état), Save (sauvegarde),
            Audio (bus, fondus), Router (transitions)
data/       données éditables : espèces (.tres), capacités, dialogues
game/       logique pure (Dino : stats par parties, niveaux, attaques)
actors/     Chloé, compagnon, dinos sauvages, PNJ (+ SheetFrames : planches → animations)
world/      zone (Region : terrain, relief, falaises), décor (Prop), obstacles, objets, habitats, sorties
world/view3d/  rendu 2,5D : WorldView (reflet 3D de la zone), HeightMap (relief), CameraRig, shaders
regions/    une scène par zone (regions/<région>/<zone>.tscn) + le TileSet de terrain partagé
ui/         dialogue, contrôles tactiles, overlay de performances (autoloads),
            Paramètres (SettingsMenu), carte du monde (MapScreen), marges des encoches (SafeArea)
scenes/     écran titre
assets/     art (généré par nano-banana → tools/process-art.mjs), audio
tools/      outils de production (exclus des exports) : plans des zones (tools/zones/),
            images des grandes régions (tools/maps/)
docs/       bible du jeu (lore, histoire, mécaniques, bestiaire), direction artistique
```

### Ajouter du contenu

- **Un dino** : une planche nano-banana (fond magenta, 2×3 cases, profil vers la droite) et une
  planche face/dos (2×4, obtenue en retouchant une planche existante avec le profil en référence) →
  les ajouter dans `tools/process-art.mjs` (`node Godot/tools/process-art.mjs <nom>`) → créer `data/species/<id>.tres` (dupliquer un
  existant dans l'Inspecteur) → l'inscrire dans `data/species_db.gd`.
- **Un décor** : ajouter un nœud *Prop* dans `Entities` et choisir son `kind` dans l'Inspecteur
  (sprite, ombre, collision et balancement viennent de `world/prop.gd`).
- **Le terrain** : sélectionner `Terrain` (TileMapLayer) et peindre herbe / chemin / hautes
  herbes / eau / forêt / sable ; le sol peint et les herbes se mettent à jour en direct dans
  l'éditeur. La forêt est infranchissable : ses arbres sont posés automatiquement à l'affichage
  (densité selon la qualité ; des buissons plutôt que des arbres le long des chemins).
- **Le relief** : propriété `relief` de la zone (Inspecteur, ou `RELIEF` dans le plan de la zone) :
  une ligne de caractères par rangée de cases, `0`–`9` = niveau (1,2 m chacun), `r` = rampe.
  Entre deux niveaux, une falaise infranchissable est créée automatiquement. Les grandes régions
  ont plutôt une hauteur libre par case (`height_data`, lue dans leur image de relief) :
  une falaise apparaît là où deux cases voisines diffèrent de plus de 0,75 m.
- **Une zone** : écrire son plan dans `tools/zones/<id>.gd` (terrain en caractères, décor,
  panneaux, points d'arrivée, sorties, habitats ; voir `port_ambre.gd`), la générer
  avec `tools/build_zone.gd`, puis l'inscrire dans `world/world.gd` (`ZONES`). Ensuite, la scène
  s'édite dans Godot. La zone donne sa musique, son ambiance, ses niveaux (Inspecteur).
- **Une grande région ouverte** (comme les Plaines) : deux images, 1 pixel = 1 case, dans
  `tools/maps/` : `<id>_sols.png` (le sol, par couleurs exactes : herbe, chemin, hautes herbes,
  eau, forêt, sable ; voir `SOLS` dans `gen-plaines.mjs`) et `<id>_relief.png` (gris : 1 niveau
  de gris = 5 cm). Elles se retouchent dans n'importe quel logiciel de dessin, ou se régénèrent
  depuis leur script (`node Godot/tools/maps/gen-plaines.mjs`, qui les écrase). Le plan
  (`tools/zones/plaines.gd`) les lit via `ZoneBuilder.region_from_maps` et y ajoute le décor
  semé, l'histoire, les points d'arrivée, les sorties et les habitats ; puis
  `build_zone.gd -- plaines --force`. Les entrées de grotte sont des nœuds *CaveMouth* (un trou
  sombre au fond d'une encoche du relief) ; la sortie se place juste devant.
- **La carte du monde** : rien à faire, elle se dessine depuis le sol et le relief de la zone.
  Les noms affichés sont ceux des habitats (`label`), les sorties y sont fléchées (noms dans
  `MapScreen.ZONE_NAMES`). Ce que Chloé a vu est enregistré dans la sauvegarde (`Game.explored`).
- **Les dinos d'une zone** : des nœuds *Habitat* (dans `Habitats`) : une zone rectangulaire et
  sa liste de *Encounter* (espèce, niveaux, poids, moment de la journée, caché dans les herbes
  ou visible en liberté). Les dinos visibles apparaissent selon l'heure.
- **Un passage entre zones** : un nœud *ZoneExit* (dans `Exits`) : zone et point d'arrivée cibles.
  Les points d'arrivée (`Spawns`) doivent être hors des sorties.
- **Une ambiance sonore** : la zone nomme son type de lieu (`ambience_id` : `plaines`, `port`,
  `grotte`, `cabinet`…) ; chaque type est décrit dans `data/ambience_db.gd` : des nappes en
  boucle (fondu enchaîné, jamais de couture audible), dont certaines suivent la distance à la mer
  ou à un feu (nœuds du groupe `fire`), et des sons ponctuels (oiseaux le jour, mouettes, rafales,
  gouttes). Un nouveau son : l'ajouter dans `tools/prepare-ambience.mjs` (même volume pour tous).
- **Fouiller, se reposer** : un arbre (`arbre_rond`, `fougere_arbre`, `araucaria`) ou des
  `cailloux` se fouillent tout seuls (`world/search.gd`) ; un `banc` ou un `feu_camp` permet de se
  reposer (`world/rest.gd`). Les galets d'ambre d'une zone se cachent dans son plan avec
  `ZoneBuilder.hide_pebbles` (arbres, pierres, terre à creuser au Flair, recoins ; seulement là où
  Chloé peut aller) ; leur nombre est `Region.pebbles`.
- **Ce que dit un objet ou un personnage hors quête** : `world/examine.gd` (lignes par sorte de décor :
  maisons, caisses, meubles…) et `DialogueDB.chatter` (répliques tournantes par personnage).
- **Les objectifs** (carte, conseils des personnages) : `story/objectives.gd`, calculés d'après les drapeaux.
- **La carte** : `ui/map_screen.gd` (l'écran), `ui/zone_map.gd` (carte d'une zone, zoom et déplacement),
  `ui/island_map.gd` (l'île et ses régions : `REGIONS`, à compléter à chaque nouvelle région).
- **Des quêtes annexes** : leurs scènes dans `story/` (ex. `plaines_annexes.gd`), lancées par un
  PNJ (`event`) ou un décor (`StoryProp`). Outils de mise en scène : `FleeingDino` (un dino qui fuit
  de point en point, reprise après chargement), `Sleeper` (un dino qui dort), `MoonFord` (un gué qui
  n'existe qu'à la pleine lune, `Game.is_full_moon()`), `Game.egg` (un œuf qui éclot en marchant).
- **Un dialogue** : `data/dialogue_db.gd` (les répliques dépendent des drapeaux d'histoire).

## Qualité graphique (Basse / Moyenne / Haute)

Tout ce qui coûte au GPU passe par l'autoload **`Quality`** (`core/quality.gd`), jamais par des
tests de niveau dispersés : les profils sont dans `Quality.PROFILES` (particules, balancement du
décor, densité des herbes, ombres de nuages, lumières, détail de l'eau, images/s max).

- **Premier lancement** : niveau proposé d'après le GPU (Adreno / Mali / Immortalis / Xclipse /
  PowerVR) et la mémoire du téléphone ; marqué « Recommandée » dans les réglages.
- **Joueur** : *Paramètres → Graphismes* (écran titre, ou bouton ☰ en jeu, qui met en pause).
  Enregistré dans `user://settings.cfg`, à part de la sauvegarde de partie.
- **Nouvel effet** : lire un réglage et suivre les changements, par exemple
  `p.amount = Quality.scaled(40)` et `Quality.changed.connect(_apply_quality)`. Un nouveau
  réglage = une clé de plus dans les trois profils.
- **Tester** : `scenario=quality` de `tools/capture.gd` capture les trois niveaux et le menu ;
  l'overlay de performances (F3 / tap à trois doigts) affiche le niveau actif.

## Outils

| Outil | Rôle |
|---|---|
| `node Godot/tools/gen-sound.mjs ambience/pluie 22 loop "<description>"` | Génère un son (ElevenLabs, clé dans `.env.local`) dans `assets/audio/` |
| `AUDIO_MODULES=<node_modules> node Godot/tools/prepare-ambience.mjs [nom…]` | Sons d'ambiance MP3 → Ogg au même volume (et sifflement retiré si besoin) dans `assets/audio/ambience/` |
| `node Godot/tools/draw-placeholders.mjs` | Images dessinées en vectoriel : feu de camp, flamme et papillon (comme la version web), galet et monticule (provisoires) |
| `node Godot/tools/process-art.mjs` | Planches nano-banana (JPG magenta) → PNG détourés, frames alignées, textures raccordables |
| `godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario=monde\|story\|plaines2\|raccords\|perf\|battle\|fight\|quality\|zones\|meteo\|debug\|ui_combat\|combat_meteo\|prologue\|title` | Test automatique avec captures d'écran et vérification sauvegarde/chargement |
| `node Godot/tools/render-phaser-music.mjs plaines 6` | Enregistre un thème de la musique Phaser en boucle Ogg sans couture (voir l'en-tête) |
| `godot --headless --path Godot --script res://tools/build_zone.gd -- <id>` | Génère une zone depuis son plan `tools/zones/<id>.gd` (refuse d'écraser sans `--force`) |
| `node Godot/tools/maps/gen-atlas.mjs` | L'atlas de l'île : l'image de la carte, les régions (pour les clics et la brume) et `data/atlas_db.gd` (noms, zones, niveaux) |
| `node Godot/tools/maps/gen-plaines.mjs` | Redessine les images de sol et de relief des Plaines (`tools/maps/`), à regénérer ensuite avec `build_zone.gd` |

## Builds (Android, Web)

Les APK et builds Web sont des **artefacts**, jamais versionnés (`build/` est ignoré).
Le workflow `.github/workflows/godot-build.yml` les produit sur GitHub :

- **chaque push sur `godot-prototype`** touchant `Godot/` publie une Release
  « Ambrelune Godot — build N » avec `Ambrelune.apk`, à télécharger directement depuis le
  téléphone : https://github.com/dede1296/dinogame/releases ;
- tag `godot-v0.1.0` (par ex.) → Release nommée, pour marquer une version ;
- les artefacts `Ambrelune-android` et `Ambrelune-web` restent aussi sur chaque run (onglet *Actions*).

**Signature** : les APK sont signés avec une clé fixe (secret GitHub
`ANDROID_DEBUG_KEYSTORE_BASE64`), donc une nouvelle version s'installe par-dessus l'ancienne.
La clé est conservée hors du dépôt, dans `C:\Users\Greg\ambrelune-signature\` (à sauvegarder :
sans elle, il faudra désinstaller une fois pour changer de clé). Elle a été créée ainsi :
```
MSYS_NO_PATHCONV=1 openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 10000 -subj "/CN=Ambrelune/O=Dinogame/C=FR"
openssl pkcs12 -export -inkey key.pem -in cert.pem -name androiddebugkey -passout pass:android -out ambrelune.keystore
base64 -w0 ambrelune.keystore   # → valeur du secret
```
Export local possible aussi (SDK Android + Java 17 + modèles d'export 4.7.2 requis, non
installés sur ce PC pour l'instant).
