@echo off
rem Regarder la fin d'Ambrelune puis les crédits, en entier, en temps réel, dans une fenêtre 1600 x 900
rem (docs/cinematiques.md, Voir les films). Le dino de départ de F-06 se choisit (Vif si rien n'est dit) :
rem   voir-fin-et-credits.cmd velociraptor   (Vif)
rem   voir-fin-et-credits.cmd ankylosaurus   (Bastion)
rem   voir-fin-et-credits.cmd parasaurolophus   (Écho)
rem (« starter=ankylosaurus », « bastion », « echo » marchent aussi.)
rem Échap deux fois (ou maintenu), B, ou un clic sur « Passer » : tout passer. Dans les crédits, Espace : pause.
rem La fenêtre se ferme toute seule à la fin des crédits. Ne touche jamais à la sauvegarde de la partie.
"C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0.." --resolution 1600x900 --script res://tools/voir_cinematiques.gd -- film=fin %*
