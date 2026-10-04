@echo off
rem Ambrelune 3D (version PC, en construction) : la Prairie du Grand Crâne en 3D, bâtie depuis la
rem zone du jeu 2,5D, deux fois plus grande (docs/migration-3d.md, phase 4).
rem ZQSD / stick gauche : marcher. Maj / B : courir. Espace / X : sauter. E / A : observer.
rem Souris (clic droit) / stick droit : tourner la caméra. Molette : zoom.
rem Le terrain d'essai : lancer-3d-essai.cmd. Ne touche pas à la sauvegarde du jeu 2,5D.
cd /d "%~dp0.."
"C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --path . res://world3d/zone3d/zone_3d.tscn
