# Ambrelune — prototype Godot

Version parallèle d'Ambrelune dans **Godot 4.7** (renderer **Mobile**), pour comparer avec la
version Phaser (`../nouveau/`) avant toute décision de migration. **Rien ici ne modifie la
version Phaser** : les assets réutilisés y sont *copiés*, jamais déplacés.

Contenu actuel (vertical slice, étape 1) : une portion des **Plaines des Fougères** avec Chloé,
Vif (son Velociraptor), des Protoceratops sauvages, Maïa, le tronc à trancher (**Tranche**),
le rocher de la grotte (**Charge**, à débloquer par hybridation), le fragment d'ambre et la
page 1 du journal d'Hélène (voix enregistrée), la sauvegarde locale, les contrôles tactiles,
la musique des Plaines (le même thème que Phaser) et l'ambiance sonore.

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
F3 (ou tap à trois doigts) pour l'overlay de performances.

## Organisation

```
core/       autoloads : Game (état), Save (sauvegarde), Audio (bus, fondus), Router (transitions)
data/       données éditables : espèces (.tres), capacités, dialogues
game/       logique pure (Dino : construction par parties → hybrides)
actors/     Chloé, compagnon, dinos sauvages, PNJ (+ SheetFrames : planches → animations)
world/      région, sol (shader), décor (Prop), obstacles, objets, herbes hautes, caméra
regions/    une scène par région + le TileSet de terrain partagé
ui/         dialogue, contrôles tactiles, overlay de performances (autoloads)
scenes/     écran titre
assets/     art (généré par nano-banana → tools/process-art.mjs), audio
tools/      outils de production (exclus des exports)
docs/       direction artistique, protocole de comparaison
```

### Ajouter du contenu

- **Un dino** : une planche nano-banana (fond magenta, 2×3 cases, profil vers la droite) →
  l'ajouter dans `tools/process-art.mjs` → créer `data/species/<id>.tres` (dupliquer un
  existant dans l'Inspecteur) → l'inscrire dans `data/species_db.gd`.
- **Un décor** : ajouter un nœud *Prop* dans `Entities` et choisir son `kind` dans l'Inspecteur
  (sprite, ombre, collision et balancement viennent de `world/prop.gd`).
- **Le terrain** : sélectionner `Terrain` (TileMapLayer) et peindre chemin / hautes herbes /
  eau ; le sol peint et les herbes se mettent à jour en direct dans l'éditeur.
- **Une région** : dupliquer `regions/plaines/plaines_sud.tscn`, l'inscrire dans
  `world/world.gd` (`REGIONS`). La région donne sa musique et son ambiance (Inspecteur).
- **Un dialogue** : `data/dialogue_db.gd` (les répliques dépendent des drapeaux d'histoire).

## Outils

| Outil | Rôle |
|---|---|
| `node Godot/tools/process-art.mjs` | Planches nano-banana (JPG magenta) → PNG détourés, frames alignées, textures raccordables |
| `godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario=walk\|story` | Test automatique avec captures d'écran et vérification sauvegarde/chargement |
| `node Godot/tools/render-phaser-music.mjs plaines 6` | Enregistre un thème de la musique Phaser en boucle Ogg sans couture (voir l'en-tête) |
| `tools/bootstrap_plaines.gd` | A généré la première région (une fois) ; la scène s'édite désormais dans Godot |

## Builds (Android, Web)

Les APK et builds Web sont des **artefacts**, jamais versionnés (`build/` est ignoré).
Le workflow `.github/workflows/godot-build.yml` les produit sur GitHub :

- onglet *Actions* › « Godot — APK Android et build Web » › *Run workflow* → artefacts
  `Ambrelune-android` (APK) et `Ambrelune-web` ;
- tag `godot-v0.1.0` (par ex.) → GitHub Release avec `Ambrelune.apk`, à télécharger
  directement depuis le S25 Ultra.

Pour garder la même signature d'un build à l'autre (mise à jour sans désinstaller), créer un
keystore une fois et le mettre dans le secret `ANDROID_DEBUG_KEYSTORE_BASE64` :
```
keytool -genkeypair -keystore ambrelune.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
base64 -w0 ambrelune.keystore   # → valeur du secret
```
Export local possible aussi (SDK Android + Java 17 + modèles d'export 4.7.2 requis, non
installés sur ce PC pour l'instant).
