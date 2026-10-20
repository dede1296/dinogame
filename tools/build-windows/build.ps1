# Ambrelune pour Windows : copie propre du projet (sans addons, outils, tests, 3D), export, puis installateur si Inno Setup est là.
#   powershell -ExecutionPolicy Bypass -File tools\build-windows\build.ps1 [-SansInstallateur]
param([switch]$SansInstallateur)
$ErrorActionPreference = "Continue"
$repo = (Resolve-Path "$PSScriptRoot\..\..").Path
$src = Join-Path $repo "Godot"
$stage = Join-Path $env:TEMP "ambrelune_stage"
$godot = "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe"
$out = Join-Path $repo "dist"

Write-Host "1/4 Copie du projet dans $stage"
robocopy $src $stage /MIR /NFL /NDL /NJH /NJS /NP /XD addons world3d models3d demo tools .godot build reports tests gddraw .git /XF *.lnk .mcp.json | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy a échoué ($LASTEXITCODE)" }

Write-Host "2/4 project.godot sans les extensions de l'éditeur"
$pg = Join-Path $stage "project.godot"
$lines = Get-Content $pg -Encoding UTF8 | Where-Object { $_ -notmatch '^(MCPRuntimeServer|PhantomCameraManager)=' -and $_ -notmatch '^enabled=PackedStringArray\("res://addons/' }
Set-Content $pg $lines -Encoding UTF8

Write-Host "3/4 Import et export (plusieurs minutes)"
& $godot --headless --path $stage --import 2>&1 | Out-Null
New-Item -ItemType Directory -Force (Join-Path $stage "build\windows") | Out-Null
& $godot --headless --path $stage --export-release "Windows Desktop" "build/windows/Ambrelune.exe" 2>&1 | Select-String "ERROR|SCRIPT ERROR|Parse" | Select-Object -First 20
$exe = Join-Path $stage "build\windows\Ambrelune.exe"
if (-not (Test-Path $exe)) { throw "Ambrelune.exe n'a pas été produit" }
New-Item -ItemType Directory -Force $out | Out-Null
Copy-Item $exe (Join-Path $out "Ambrelune.exe") -Force
Write-Host ("Ambrelune.exe : {0:N0} Mo -> {1}" -f ((Get-Item $exe).Length / 1MB), $out)

if ($SansInstallateur) { return }
$iscc = @("C:\Program Files (x86)\Inno Setup 6\ISCC.exe", "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { Write-Host "4/4 Inno Setup absent : pas d'installateur (winget install JRSoftware.InnoSetup)"; return }
Write-Host "4/4 Installateur"
& $iscc "/O$out" "$PSScriptRoot\ambrelune.iss" | Select-Object -Last 3
