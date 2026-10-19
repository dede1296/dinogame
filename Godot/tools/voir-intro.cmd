@echo off
rem Regarder l'intro d'Ambrelune en entier, en temps réel, dans une fenêtre 1600 x 900 (docs/cinematiques.md, Voir les films).
rem Échap deux fois (ou maintenu), B, ou un clic sur « Passer » : tout passer. Espace, Entrée ou un clic : image suivante.
rem La fenêtre se ferme toute seule à la fin du film. Ne touche jamais à la sauvegarde de la partie.
"C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0.." --resolution 1600x900 --script res://tools/voir_cinematiques.gd -- film=intro
