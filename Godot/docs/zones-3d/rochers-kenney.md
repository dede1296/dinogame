# Catalogue des rochers Kenney Nature Kit 2.1 (Ambrelune, Prairie 3D)

Source : `assets3d_src/nature/kenney/Models/GLTF format/` (CC0, Kenney). Mesures faites dans Blender 5.2 en ligne de commande, sans modifier le jeu.
Échelle vérifiée : `fence_simple` = 1,00 m de large, donc **1 unité = 1 m**. Pivot : centré en XY sur l'origine, base à z = -0,05 m (enfoncé de 5 cm, bon pour poser sur le sol).

Données : `rochers-kenney.json` (60 rochers + 56 pièces de falaise). Planche : `rochers-kenney-planche.png`.

## Constats importants

- **Aucun rocher GRAND (> 2,5 m) dans le kit.** Le plus gros fait ~1,1 m. Pour un bloc de 2,5 m+, il faut soit mettre à l'échelle (×2 à ×2,5, à valider visuellement), soit utiliser les pièces de falaise.
- **Les `stone_*` sont les mêmes formes que les `rock_*`** : géométrie identique (mêmes triangles, mêmes dimensions), seul le matériau change (`rock_` = herbe dessus + terre, `stone_` = pierre nue). Donc **30 formes distinctes seulement**, pas 60.
- `rock_tallA` / `stone_tallA` ont une hauteur de 0,996 m : limite PETIT/MOYEN, classée PETIT.
- Les 60 rochers sont centrés sur l'origine (pas de pivot décalé). Aucune mauvaise orientation détectée.

## Tableau (formes uniques ; `stone_X` = même forme, pierre nue)

| id | L × P × H (m) | tris | famille | forme |
|---|---|---|---|---|
| rock_largeA | 0,78 × 1,02 × 0,26 | 80 | MOYEN | arrondi |
| rock_largeB | 0,77 × 1,02 × 0,43 | 85 | MOYEN | arrondi |
| rock_largeC | 1,06 × 1,02 × 0,32 | 72 | MOYEN | massif |
| rock_largeD | 1,07 × 1,03 × 0,57 | 80 | MOYEN | massif |
| rock_largeE | 1,10 × 0,92 × 0,29 | 64 | MOYEN | massif |
| rock_largeF | 1,10 × 0,90 × 0,48 | 73 | MOYEN | massif |
| rock_smallA | 0,36 × 0,36 × 0,19 | 16 | PETIT | arrondi |
| rock_smallB | 0,36 × 0,36 × 0,18 | 24 | PETIT | arrondi |
| rock_smallC | 0,36 × 0,36 × 0,12 | 16 | PETIT | arrondi |
| rock_smallD | 0,43 × 0,37 × 0,23 | 32 | PETIT | arrondi |
| rock_smallE | 0,36 × 0,31 × 0,26 | 64 | PETIT | massif |
| rock_smallF | 0,35 × 0,31 × 0,25 | 60 | PETIT | massif |
| rock_smallFlatA | 0,50 × 0,43 × 0,06 | 20 | PETIT | plat |
| rock_smallFlatB | 0,43 × 0,40 × 0,06 | 16 | PETIT | plat |
| rock_smallFlatC | 0,47 × 0,36 × 0,06 | 40 | PETIT | plat |
| rock_smallG | 0,59 × 0,69 × 0,25 | 32 | PETIT | haut/élancé |
| rock_smallH | 0,46 × 0,46 × 0,41 | 60 | PETIT | massif |
| rock_smallI | 0,36 × 0,41 × 0,28 | 44 | PETIT | arrondi |
| rock_smallTopA | 0,49 × 0,49 × 0,22 | 52 | PETIT | en gradin |
| rock_smallTopB | 0,62 × 0,65 × 0,28 | 76 | PETIT | en gradin |
| rock_tallA | 0,98 × 0,68 × 1,00 | 136 | PETIT | en gradin |
| rock_tallB | 0,76 × 0,77 × 0,88 | 172 | PETIT | en gradin |
| rock_tallC | 0,46 × 0,44 × 0,78 | 37 | PETIT | haut/élancé |
| rock_tallD | 0,44 × 0,46 × 0,77 | 38 | PETIT | haut/élancé |
| rock_tallE | 0,46 × 0,53 × 0,44 | 38 | PETIT | haut/élancé |
| rock_tallF | 0,44 × 0,51 × 0,57 | 46 | PETIT | haut/élancé |
| rock_tallG | 0,42 × 0,49 × 0,78 | 62 | PETIT | haut/élancé |
| rock_tallH | 0,57 × 0,66 × 0,71 | 78 | PETIT | haut/élancé |
| rock_tallI | 0,46 × 0,46 × 0,81 | 44 | PETIT | haut/élancé |
| rock_tallJ | 0,49 × 0,54 × 0,62 | 42 | PETIT | haut/élancé |

Les formes sont des estimations : métriques de dimensions et lecture visuelle de la planche, pas une analyse de surface. Les tris de `rock_` et `stone_` sont identiques.

Familles : **PETIT 24 formes (48 fichiers)**, **MOYEN 6 formes (12 fichiers)**, GRAND 0.
Formes : haut/élancé 9, arrondi 7 (dont rock_largeA/B), massif 7, en gradin 4, plat 3.

## Règles de variété proposées

- **Secteur rocheux** (pentes, bord de falaise) : 60 % haut/élancé + en gradin, 40 % massif/arrondi ; dominé par les `tall` et `largeC–F`. Toujours au moins 2 MOYEN par parcelle.
- **Secteur plat** (prairie, chemin) : 70 % plat + petits arrondis (`smallFlat*`, `smallA–C`, `smallI`), quelques `smallTop*` en touche ; pas de `tall`.
- **Secteur de falaise** : pièces `cliff_*` pour le relief ; rochers `largeD/E/F` au pied, `tallA/B` en éboulis.
- Règle transverse : pas deux fois la même forme dans un rayon de 6 m ; alterner `rock_` (herbe) et `stone_` (pierre) ; un rocher par ~40 m² au plus pour éviter l'effet de semis.
- Toujours tourner chaque instance (rotation Y aléatoire) et varier l'échelle de ±15 %.

## 5 rochers à mettre en avant (repères)

1. **rock_tallB** : le plus détaillé (172 tris), en gradin, bon repère de hauteur.
2. **rock_largeD** : le plus massif des MOYEN (0,57 m de haut), silhouette lisible.
3. **rock_tallH** : haut/élancé avec une vraie largeur (0,57 × 0,66 m), passe bien en groupe.
4. **rock_smallTopB** : en gradin, plus gros des petits en emprise (0,62 × 0,65 m).
5. **rock_smallFlatA** : le plus réussi des plats, sert de dalle ou de galet posé.

## Chemins

- Données : `C:\Users\Greg\Dinogame\Godot\docs\zones-3d\rochers-kenney.json`
- Ce catalogue : `C:\Users\Greg\Dinogame\Godot\docs\zones-3d\rochers-kenney.md`
- Planche : `C:\Users\Greg\Dinogame\Godot\docs\zones-3d\rochers-kenney-planche.png`
- Pièces de falaise (56) : liste à part dans le JSON (`cliffs`).
