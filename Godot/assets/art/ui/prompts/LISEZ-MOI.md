# Icônes de touches et de manettes

« Input Prompts » de **Kenney** (https://kenney.nl/assets/input-prompts), licence **CC0** (domaine
public) — reprises depuis l'extension Controller Icons, qui les embarque. Copiées ici pour que le
jeu n'en dépende pas (le dossier `addons/` n'est pas livré).

- `key/` : clavier (lettres, flèches, Maj, Espace, Entrée, Échap, F1-F12…)
- `xbox/` : manette Xbox Series (A B X Y, LB RB, sticks, croix, Menu, Vue)
- `ps5/` : manette PlayStation (croix, rond, carré, triangle, L1 R1, options, share…)
- `switch/` : manette Switch (A B X Y, L R ZL ZR, +, −)

Les noms de fichier suivent ceux de Kenney ; la correspondance touche → fichier est dans
`core/prompts.gd`. Lire l'icône d'une action : `Prompts.texture(&"interact")`.
