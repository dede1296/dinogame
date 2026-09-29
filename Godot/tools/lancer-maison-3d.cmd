@echo off
rem Le Clos Blanc : la maison modelée dans Blender puis peinte par ComfyUI, à visiter librement.
rem Flèches / ZQSD pour marcher, Espace devant la porte pour l'examiner, F2 : menu de débogage.
rem Le jeu écrit sa propre sauvegarde (capture_save.json), jamais celle de la partie.
cd /d "%~dp0.."
"C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --path . --script res://tools/capture.gd -- scenario_file=res://tools/scenarios/maison_3d.gd
