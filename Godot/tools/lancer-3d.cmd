@echo off
rem Ambrelune 3D (version PC, en construction) : la zone de démonstration de la migration 3D
rem (docs/migration-3d.md). ZQSD / stick gauche : marcher. Maj / B : courir.
rem Souris (clic droit) / stick droit : tourner la caméra. Molette : zoom.
rem Ne touche pas à la sauvegarde du jeu 2,5D.
cd /d "%~dp0.."
"C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --path . res://world3d/demo/demo_3d.tscn
