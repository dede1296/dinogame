# Comparaison Phaser ↔ Godot — protocole et relevés

But : décider **sur des mesures** si Ambrelune reste sur Phaser, passe sur Godot, ou mélange
les deux. Aucune migration n'est engagée tant que cette comparaison n'est pas conclue.

Appareil de référence : **Samsung Galaxy S25 Ultra**. Phaser : navigateur/PWA
(https://dede1296.github.io/dinogame/). Godot : APK natif (workflow GitHub) et build Web.

## Mesures

L'overlay Godot (F3 / tap à trois doigts) affiche : FPS, **pire image de la dernière demi-seconde**
(les saccades se voient là, pas dans la moyenne), draw calls, objets, mémoire, latence audio,
renderer. Côté Phaser, utiliser le panneau de performances du navigateur (chrome://inspect
depuis le PC) et noter les mêmes grandeurs.

| Critère | Protocole | Phaser | Godot |
|---|---|---|---|
| Démarrage | chronomètre : icône → écran titre jouable | | |
| Entrée en jeu | « Continuer » → contrôle de Chloé | | |
| Fluidité exploration | 60 s de marche dans les Plaines : FPS moyen, pire image | | |
| Charge | se placer face à l'étang + hautes herbes + 3 dinos à l'écran | | |
| Chauffe/batterie | 15 min de jeu : température ressentie, % batterie | | |
| Taille | APK / poids téléchargé | | |

## Audio (point sensible : saccades de musique dans le navigateur)

Même musique des deux côtés : le thème « plaines » de Phaser est enregistré tel quel en Ogg
(cycle complet de 6 passages, ~3 min 33) par `tools/render-phaser-music.mjs`. Phaser le
synthétise en direct (séquenceur JS sur le fil principal) ; Godot le lit en streaming sur son
propre fil audio.

| Test | Comment | Phaser | Godot |
|---|---|---|---|
| Musique longue | laisser tourner 10 min (plusieurs cycles) : coupures ? couture de boucle audible ? | | |
| Charge + musique | marcher vite, ouvrir des dialogues, trancher le tronc pendant la musique | | |
| SFX simultanés | pas + cris des dinos + effets en même temps : tout est-il joué ? | | |
| Voix + musique | page du journal d'Hélène (voix, musique atténuée puis rétablie) | | |
| Arrière-plan | bouton Accueil 30 s puis retour : la musique reprend-elle proprement ? | | |
| Écran verrouillé | verrouiller/déverrouiller pendant la musique | | |
| Latence | tap sur A → son d'interaction : délai ressenti | | |
| Exploration → combat → retour | toucher un Protoceratops : la musique des Plaines doit reprendre là où elle s'était arrêtée (Godot : oui, par conception) ; ambiance atténuée pendant le combat | | |
| Jingles | victoire, capture : pas de coupure, retour propre au thème | | |

## Graphismes

| Critère | Phaser | Godot |
|---|---|---|
| Netteté des personnages/décors sur l'écran 1440p | | |
| Animations (marche 4 directions, dinos) | | |
| Végétation vivante (balancement, herbes qui s'écartent) | | |
| Eau | | |
| Lumière / ombres (ombres de contact, nuages, lueur de l'ambre) | | |
| Particules (pollen, débris du tronc) | | |

## Développement

| Critère | Phaser | Godot |
|---|---|---|
| Ajouter une zone | carte en code (`world/maps/*.js`) | scène `.tscn` + terrain peint dans l'éditeur, aperçu en direct |
| Ajouter un dino | parties vectorielles en code | planche nano-banana + fiche `.tres` |
| Ajouter un effet | code Canvas/WebGL | shaders, particules, lumières 2D intégrés |
| Itération | rechargement navigateur instantané | F5 ~2 s, éditeur visuel, débogueur |
| Tests automatisés | Playwright | `tools/capture.gd` (scénarios + captures) |

## Relevés

### 2026-09-26 — PC de développement (GTX 1650 Ti, Windows, D3D12, renderer Mobile)

- 60 FPS constants (vsync), pire image ~17 ms en exploration ; une image à ~21 ms (47 FPS
  instantané) à la première découpe du tronc (première utilisation des particules : compilation
  de shader). À surveiller sur le téléphone.
- 105–215 draw calls, 300–550 objets selon la zone ; ~88 Mo de mémoire statique.
- Latence de sortie audio : 11 ms (WASAPI).
- Aucune erreur de script sur les scénarios « walk » et « story » ; sauvegarde → chargement vérifiés.
- Plus tard dans la journée : **tout** projet Godot fenêtré tombait à ~6 FPS, écran titre compris,
  quelle que soit la taille de fenêtre ou le pilote (D3D12/Vulkan), alors qu'en headless le jeu
  tournait en temps réel. Cause environnementale (Windows en mode « Économie d'énergie » et
  éditeur Godot ouvert en parallèle), pas le jeu : refaire les mesures PC en mode « Performances »,
  éditeur fermé. Les mesures qui comptent sont celles du S25 Ultra.
- Musique : `plaines.ogg` = cycle complet du thème Phaser (213,33 s, 3,9 Mo, Vorbis q5) ;
  sa lecture seule ne coûte rien de mesurable (144 FPS headless avec ou sans).

- Combat (même journée, mode « Performances ») : 60 FPS ; musique « sauvage » (13,3 s en boucle),
  jingles « victoire » et « capture » enregistrés depuis Phaser ; retour au thème des Plaines à
  la position quittée, vérifié par le scénario `fight` de `tools/capture.gd`.
- Première utilisation des particules : une image lente (compilation de shader). Préchauffage
  ajouté au lancement du combat ; à vérifier sur le téléphone.

### S25 Ultra — *à faire* (après le premier APK)
