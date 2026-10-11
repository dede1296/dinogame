# Sprites et mouvements — la règle commune

> Demande de Greg, 11/10 : « prévoir des sprites adaptés aux mouvements (barques dans le sens du
> mouvement, etc.) pour tous les sprites du jeu ; une cohérence graphique, artistique et technique. »
> Ce document fixe la règle et le plan. Rien n'est encore dessiné pour lui : c'est l'étape 0.
> **Calendrier : en fin de développement** (décision de Greg, 11/10). D'ici là, seule la règle
> s'applique : tout NOUVEAU sprite la suit, pour que le travail de reprise n'augmente pas.

## Le principe

**Tout ce qui bouge dans le monde se montre dans le sens où il va.** Pas d'image de profil qui glisse
de côté vers le haut de l'écran, pas de barque qui avance en crabe, pas de dino qui marche de dos avec
la tête de profil. Une entité mobile a les vues dont ses mouvements ont besoin ; la tricherie
(retourner une image, la faire pivoter) n'est permise que là où elle ne se voit pas.

## Où l'on en est (état relevé le 11/10)

| Famille | Directions dessinées | Mécanique | Écart |
|---|---|---|---|
| **Chloé** (`assets/art/characters/chloe*.png`, ~25 planches de tenues et de poses) | 4 directions : bas, gauche, droite, haut, × 4 images de marche (`SheetFrames.character`) | marche, course, nage, selle, accroupie, assise, main, grimpe | les poses spéciales (nage, selle, grimpe) n'ont pas toutes les 4 directions |
| **PNJ** (Maïa, Roc, Brac, Bertille…) | idem Chloé | marche, assis, accroupi | à auditer, une par une |
| **Dinos** (48 espèces, `assets/art/dinos/`) | profil (marche à 3 images, attente, attaque) **+ face et dos** pour les 48 | `SheetFrames.dino` choisit profil ou face/dos selon la direction (`dino_anims`) | corrompus : 9 espèces dessinées, 39 par shader ; nage et vol : 2 espèces |
| **Faune** (`assets/art/fauna/`, 22 planches : libellule, grenouille, crabe…) | 1 vue, retournée | déplacement par code | à auditer : les bêtes qui vont vers le haut ou le bas de l'écran |
| **Véhicules / embarcations** (`props/barque.png`, `chariot_cage.png`, `voiture_arbre.png`) | **1 image de profil** | la barque de Maïa glisse (`story/barque.gd`) ; le chariot de Brac est un décor | **c'est le cas qui a déclenché la demande** : une barque doit avoir un avant, un arrière et un dessus selon qu'elle part vers l'est, le nord ou le sud |
| **Montures** (Chloé sur un dino, `chloe_selle*.png`) | profil + face/dos selon l'espèce | `RideButton` | à auditer |
| **Volants / nageurs** (`ptero_vol.png`, `pteranodon_vol.png`, `chloe_nage.png`, dinos marins) | 1 vue | vol et nage par code | vols de face/dos, plongée sous l'eau |
| **Décors animés** (feu, fumée, eau, drapeaux) | sans objet (sans direction) | shaders et planches | sans écart de direction |

## La règle technique (à tenir pour toute nouvelle image)

1. **Vues requises selon la famille.**
   - Marcheur (humain, dino, bête) : **profil droit** (le gauche est la même image retournée), **face** (vers le bas de l'écran) et **dos** (vers le haut). Trois vues, pas quatre : le retournement est gratuit et invisible pour un profil. (Chloé garde ses 4 lignes, héritage.)
   - Véhicule ou embarcation : **profil, trois-quarts avant, trois-quarts arrière** — ou profil + face + dos si le trois-quarts n'est pas dessiné —, avec une animation de mouvement (rames, remous) et, pour une barque, l'**étrave et le sillage** dans le sens du déplacement.
   - Volant : profil + face (vol vers soi) + dos (vol qui s'éloigne), ailes à trois positions au moins.
   - Nageur : profil + face/dos, avec la ligne d'eau (la moitié basse masquée par l'eau, pas un sprite posé dessus).
2. **Mise en page des planches.** Une planche par entité et par famille de vues ; colonnes = images de l'animation, lignes = vues, dans l'ordre profil, face, dos ; cellules de taille égale ; **origine = les pieds** (centre bas de la cellule), ombre au sol à part (`Shadow`).
3. **Nommage des animations**, déjà celui du jeu : `walk`, `idle`, `attack`, `sleep`, `walk_down`, `idle_down`, `walk_up`, `idle_up`. Un véhicule : `move`, `move_down`, `move_up`, `idle`, `idle_down`, `idle_up`. Le sens du mouvement choisit l'animation (`SheetFrames.dino_anims` fait déjà ce choix : une fonction commune `SheetFrames.anims_for(entity, direction)` la généralise).
4. **Échelle** : une entité garde la même taille à l'écran quelle que soit la vue (hauteur de référence dans `Heights`, 1 case = 1 m) ; on contrôle que face et profil se superposent à ±5 % en hauteur.
5. **Pas de rotation d'image** pour simuler une direction, sauf pour un objet sans avant (une feuille, une boule). Un petit roulis d'embarcation (balancement) est permis : c'est du mouvement, pas de la direction.

## La règle artistique

- **Même main partout** : contour, palette, lumière (chaude en haut à gauche, comme les décors) et traitement des ombres de `docs/direction-artistique.md`. Une nouvelle vue se dessine **à partir de la vue existante** (nano-banana en édition de l'image de référence), jamais en repartant d'une page blanche : sinon l'espèce change de tête d'une vue à l'autre.
- Chaque entité a une **fiche de référence** (profil + face + dos sur une même image) validée avant de produire les images d'animation.
- Un défaut de cohérence repéré (couleur, proportion, accessoire qui change) se note dans `direction-artistique.md § À refaire` au lieu de se rattraper en silence.

## Le garde-fou : un contrôle automatique

Un script `tools/audit-sprites.mjs` (à écrire, étape 1) parcourt les données du jeu et **liste, par famille, ce qui manque** : espèces sans face/dos, PNJ sans les quatre directions, entités qui bougent mais n'ont qu'une vue, planches dont les cellules ne sont pas égales, hauteurs face/profil qui divergent de plus de 5 %. Il sort un tableau (md) et un code de sortie ; on le relance à chaque lot d'images, et c'est lui — pas la mémoire de quelqu'un — qui dit que la cohérence est tenue.

## Le plan

| Étape | Quoi | Qui | Dessin ? |
|---|---|---|---|
| 0 | cette règle, validée par Greg | fait | non |
| 1 | `audit-sprites.mjs` : l'état exact, entité par entité | un agent Sonnet | non |
| 2 | `SheetFrames.anims_for` : un seul chemin pour « quelle animation pour ce mouvement » (Chloé, PNJ, dinos, bêtes, véhicules) | un agent Sonnet, test ciblé | non |
| 3 | **La barque de Maïa et les embarcations** : fiche de référence, trois vues, rames, étrave, sillage ; brancher `story/barque.gd` et les barques de décor qui bougent | un agent Opus + nano-banana | oui |
| 4 | Poses spéciales de Chloé (nage, selle, grimpe) dans les 4 directions | un agent Sonnet + nano-banana, par lots de 3 poses | oui |
| 5 | PNJ : combler les directions manquantes relevées par l'audit | agents Sonnet en parallèle, un par groupe | oui |
| 6 | Faune et volants : face/dos là où ça se voit | agent Sonnet + nano-banana | oui |
| 7 | Revue de cohérence : planche de contact par famille, comparée à la fiche de référence | moi, avec captures | non |

Les étapes 3 à 6 dépendent des **crédits nano-banana** ; sans crédits, repli ComfyUI en respectant la
direction artistique, et chaque repli est noté dans `direction-artistique.md § À refaire avec nano-banana`.
