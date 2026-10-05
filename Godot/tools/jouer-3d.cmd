@echo off
rem Ambrelune 3D (version PC) : lance le jeu construit (build/windows/Ambrelune.exe), sans Godot.
rem Pour le reconstruire : Godot > Projet > Exporter > « Windows Desktop », ou
rem "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --export-release "Windows Desktop" build/windows/Ambrelune.exe
rem ZQSD / stick gauche : marcher. Maj / B : courir. Espace / X : sauter. E / A : observer.
cd /d "%~dp0..\build\windows"
if not exist Ambrelune.exe (
  echo Ambrelune.exe introuvable : reconstruire le build Windows d'abord.
  pause
  exit /b 1
)
start "" Ambrelune.exe
