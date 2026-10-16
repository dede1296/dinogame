# Chapitre 8 — La Plaine Volcanique : plan proposé (16/10/2026, à valider par Greg)

> Brouillon écrit d'après `histoire.md` § Chapitre 8, `bestiaire.md` § Plaine Volcanique, `lore.md`
> (Brac, Dame Suie) et le modèle du chapitre 7 (`chapitre-7-plan.md`). Rien n'est commencé : les points
> marqués **À TRANCHER** attendent Greg.

## Ce que le chapitre doit faire (déjà décidé dans l'histoire)

1. Champs de cendres, coulées de lave, **forges de l'Ombre Noire** ; beaucoup de dinos corrompus qu'on
   apaise et qui se retournent contre les forges.
2. **Brac**, dernier combat : lâché par l'Ombre Noire, il part en jurant.
3. **Dame Suie** change de camp (elle a vu « la fille du Masque marcher à côté de sa mère, sans peur ») :
   elle éteint la grande forge d'ambre noir et donne à Chloé le moyen d'**annuler l'ambre noir**
   (pour le dernier combat).
4. Le **T-Rex de Magma** garde le **5e Cœur** : le combat le plus dur avant la fin. Sceau, Cœur.
5. Pages 35 à 38 du journal : Hélène savait et avait tout prévu (35 sanctuaire, 36 son plan, 37 lettre à
   Isaure aux forges, 38 la veille à la porte du cratère). Isaure attend à la porte de la Terre des Apex.
6. **Maïa est absente** (descendue avec Isaure) : Chloé a Moustique et le masque en carton. Caillou n'est
   plus avec elle non plus.

## Proposition : trois zones (modèle des Cieux)

| Zone (identifiant) | Rôle | Taille indicative |
|---|---|---|
| `champs_cendres` | arrivée par la Descente de Cendre (depuis l'Arche), dinos corrompus et Styracosaurus, Saichania ; page 36 | ~90×70 |
| `forges_ombre` | les forges : camp de l'Ombre, Brac, Dame Suie, la grande forge d'ambre noir ; pages 37 ; lettre à Isaure | ~80×60 |
| `sanctuaire_magma` | coulées de lave, le T-Rex de Magma, le 5e Cœur ; pages 35 et 38 à la porte du cratère | ~70×60 |

Dossier `regions/volcan/`, générées par `tools/zones/*.gd` comme les Cieux (clés de nommage identiques :
`story/volcan*.gd`, `data/dialogue_volcan.gd`, `story/volcan_places.gd`).

## Mécanique propre au chapitre (comme le froid aux Monts, le Vol aux Cieux)

**À TRANCHER.** Trois pistes, par ordre de ma préférence :

- **A. La chaleur** (reprise exacte du mécanisme du froid, `Region.hot`, vêtement/objet résistant à la chaleur
  vendu par Joss ou obtenu chez Rosalie) : peu de code, cohérent, mais déjà vu une fois.
- **B. La lave praticable seulement avec un dino de type pierre/feu** : le dino de tête franchit les coulées
  (compétence de traversée, comme la nage ou l'escalade) ; ça donne une raison d'utiliser l'équipe.
- **C. Les cendres qui cachent le chemin** : zones de cendres épaisses où l'on avance au son/à la trace de
  dinos ; plus original mais plus lourd à coder et à lire.

Je recommande **B**, avec une touche d'**A** (chaleur seulement près des coulées).

## Dinos et combat

- Espèces (bestiaire) : Styracosaurus (champs de cendres, jour, Charge), Saichania (coulées refroidies, jour,
  Charge), Daspletosaurus (coulées de lave, nuit), dinos corrompus (forges, variés), **T-Rex de Magma** (Alpha).
  Niveaux 42 à 48. À créer : 4 fiches `data/species/*.tres` + planches (profil, face, dos).
- Combat de **Brac** (équipe de corrompus) puis combat d'**Alpha** (T-Rex de Magma).
- Apaiser (mécanisme existant) devient central : beaucoup de dinos corrompus ; Dame Suie donne
  « l'antidote » (objet `antidote_ambre`) pour le dernier combat.

## Scènes à écrire (modèle : scène du masque, Fable)

1. Arrivée : la cendre, les forges au loin, Chloé sans Maïa (une pensée courte).
2. Les dinos corrompus qui se retournent contre les forges (visible, animé).
3. Brac : dernier combat et départ en jurant (une ou deux répliques mémorables).
4. Dame Suie : la bascule, la forge éteinte, l'antidote. La plus délicate : « froide, curieuse, pas cruelle ».
5. Le sanctuaire : le T-Rex de Magma, le Cœur, pages 35 à 38.
6. Isaure à la porte (met en place le chapitre 9).

## Images (nano-banana ; repli ComfyUI noté dans `direction-artistique.md`)

Sols (cendre, lave, roche noire), props (forge, enclume, cages, fûts d'ambre noir, coulées), 4 espèces,
Brac/Dame Suie en pied si manquants, fond de combat `volcan`. Règle des mouvements (profil/face/dos) pour
tout nouveau mobile.

## Répartition des agents (une fois le plan validé)

| Agent | Modèle | Possède |
|---|---|---|
| HISTOIRE | Fable | `histoire.md` § Ch. 8, `story/volcan*.gd`, `data/dialogue_volcan.gd` |
| CARTE | Opus | `tools/zones/*volcan*`, `regions/volcan/*`, `story/volcan_places.gd` |
| MÉCANIQUES | Opus | espèces, mécanique choisie, objets, équilibrage 42–48, combat Brac / T-Rex |
| IMAGES | Sonnet | `tools/art-jobs/volcan*.mjs`, `assets/art/**` |

Intégration par moi (patches communs : `world.gd`, `story.gd`, `zone_map.gd`…), commit par lots.
Coût estimé : proche du chapitre 7 (4 agents, plusieurs heures de quota) : à lancer quand Greg a du volume.

## Décisions attendues de Greg

1. Mécanique : A, B (recommandée), C, ou autre ?
2. Trois zones (champs, forges, sanctuaire) : OK ou plus/moins ?
3. Ton de Brac : franc brutal comique, ou plus menaçant ?
4. Quand lancer (quota) et dans quel ordre : histoire d'abord (Fable seul), puis carte/mécaniques/images en parallèle ?
