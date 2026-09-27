@echo off
rem Démo en direct de ce qui a été fait (fin de la Forêt, Marais Brumeux, Désert Aride).
rem P : pause   N : étape suivante   Espace : réplique suivante.
rem La démo écrit sa propre sauvegarde (capture_save.json), jamais celle de la partie.
cd /d "%~dp0.."
"C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --path . --script res://tools/capture.gd -- scenario=demo_nuit
