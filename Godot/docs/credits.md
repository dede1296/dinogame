# Crédits d'Ambrelune

> Contenu prêt à être affiché dans le jeu. Généré à la main le 19/10/2026 ; la version pour le code est
> `data/credits_data.gd` (à régénérer si ce fichier change). Détails et points à vérifier :
> [licences-audit.md](licences-audit.md).
> Les lignes marquées « (À VÉRIFIER) » ne doivent pas être affichées telles quelles : Greg tranche d'abord.

## Création

**Ambrelune**

Un jeu créé par **Grégory Cuypers**
Création, histoire, direction du jeu

## Outils

Ambrelune a été fabriqué avec l'aide d'outils d'intelligence artificielle.
Grégory Cuypers a imaginé le jeu, l'histoire et les personnages, et a dirigé chaque étape.

- Code et écriture : Claude, par Anthropic
- Images : nano-banana (modèle d'image Gemini de Google)
- Sons et ambiances : Stable Audio Open 1.0, par Stability AI, et ElevenLabs
- Voix de quelques personnages : ElevenLabs
- Images retouchées en local : ComfyUI
- Moteur : Godot Engine

**Powered by Stability AI**

## Assets et licences

### Bruitages et pas
- Pas sur le sol : « RPG Audio » de Kenney (www.kenney.nl), domaine public (CC0)
- Bruitages (portes, coups, pièces, pages, verre, pierre) : packs sonores de Kenney (www.kenney.nl), domaine public (CC0)

### Icônes de touches et de manettes
- « Input Prompts » de Kenney (www.kenney.nl), domaine public (CC0)

### Polices
- Caveat, par The Caveat Project Authors, licence SIL Open Font 1.1

### Musiques
- Les musiques sont composées pour le jeu (synthétiseur du jeu).

### Ambiances, cris et pas de neige
- Générés avec ElevenLabs et Stable Audio Open 1.0 pour le jeu.

### Voix
- Les voix du prologue sont générées avec ElevenLabs.

### Images
- Les décors, personnages, dinosaures et objets sont dessinés pour le jeu avec nano-banana, sous la direction de Grégory Cuypers.

## Moteur et bibliothèques

- Ambrelune utilise **Godot Engine** 4.7, © 2014-présent Godot Engine contributors, © 2007-2014 Juan Linietsky, Ariel Manzur, licence MIT. https://godotengine.org
- Godot embarque d'autres bibliothèques libres (FreeType, HarfBuzz, libogg, libvorbis, zlib, mbedTLS, et d'autres).
  Leurs mentions et licences complètes sont fournies avec le jeu (fichier `LICENSES-GODOT.txt`) et affichées dans l'écran « Licences ».
- Éléments d'interface de démonstration du plugin LimboAI : © 2024 Aleksandra Snitsaruk, licence CC BY 4.0 (À VÉRIFIER : seulement si le dossier `demo/` reste dans l'export)

## Remerciements

- Chloé, pour qui ce jeu existe.
- Kenney, pour ses assets libres.
- La communauté Godot.
- Les joueurs et les joueuses.

---

## Obligations de licence (section technique, à ne pas afficher telle quelle)

Ce qui DOIT être affiché ou fourni avec le jeu exporté :

1. **Godot (MIT)** : le texte de la licence MIT de Godot et le copyright doivent accompagner le jeu. Les licences des
   bibliothèques tierces du moteur aussi. Godot fournit tout cela à l'exécution :
   `Engine.get_license_text()` (licence Godot), `Engine.get_license_info()` (texte des licences par nom),
   `Engine.get_copyright_info()` (copyrights des composants tiers : liste de {name, parts[{files, copyright, license}]}),
   `Engine.get_author_info()` / `get_donor_info()` (facultatif). L'écran « Licences » doit les lister.
2. **Stability AI Community License** (Stable Audio Open 1.0) : afficher « Powered by Stability AI » dans l'interface,
   la page du jeu ou la documentation ; fournir la licence et un fichier `NOTICE` avec l'attribution à qui reçoit le jeu ;
   inscription chez Stability AI pour usage commercial ; plafond de 1 000 000 $ de revenu annuel (au-delà, licence à demander).
   Texte relu sur https://stability.ai/community-license-agreement le 19/10/2026 (À VÉRIFIER par Greg avant sortie).
3. **Caveat (SIL OFL 1.1)** : le fichier `assets/fonts/Caveat-OFL.txt` doit rester joint aux fichiers de la police.
   Pas d'obligation d'affichage, mais on la crédite.
4. **Kenney (CC0)** : aucune obligation. Crédit offert par courtoisie.
5. **LimboAI demo (CC BY 4.0)** : crédit obligatoire SI `demo/` est dans l'export. Plus simple : l'exclure (voir l'audit).
6. **ElevenLabs, plan gratuit** : les conditions disent que le plan gratuit est pour un usage NON commercial. Si le jeu est
   vendu ou monétisé, il faut un plan payant (puis régénérer, ou obtenir l'accord d'ElevenLabs). À VÉRIFIER par Greg avant toute vente.
7. **Plugins Godot** : les plugins (MIT, Apache, etc.) ne sont pas livrés avec le jeu exporté (l'export exclut `addons/*`) :
   aucune mention obligatoire. S'ils étaient inclus un jour, il faudrait ajouter leurs licences.
8. **Pas d'obligation** pour les images faites avec nano-banana, mais à vérifier : conditions Google de l'API Gemini
   (usage commercial des images, filigrane SynthID invisible).
