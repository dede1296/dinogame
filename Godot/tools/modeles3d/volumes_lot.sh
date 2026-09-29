#!/usr/bin/env bash
# Enchaîne les étapes des grands décors en vraie 3D pour les sortes données (voir volumes.py) :
# face -> prep Blender -> flancs peints par ComfyUI (en tête de file) -> textures -> bake Blender
# (atlas, cuisson de la peinture, de l'occlusion et des normales : modèle 3D v2, 1 à 2 min CPU)
# -> Prop.KINDS (le modèle, la collision). Reste à faire ensuite : l'import Godot (--headless --import).
# Une sorte n'est traitée que si son maillage Hunyuan3D est déjà sorti de ComfyUI.
#   bash volumes_lot.sh maison_jaune maison_port …
set -u
cd "$(dirname "$0")"
PY=/c/ComfyUI_windows_portable/python_embeded/python.exe
BL="/c/Program Files/Blender Foundation/Blender 5.2/blender.exe"
OUT=/c/ComfyUI_windows_portable/ComfyUI/output
for K in "$@"; do
	if ! ls "$OUT"/volumes/ | grep -qE "^${K}(_[a-z])?_[0-9]+_\.glb$"; then echo "SAUTE $K (pas de maillage)"; continue; fi
	$PY volumes.py face "$K" || continue
	"$BL" --background --python volumes_blender.py -- prep "$K" 2>&1 | grep -E "PREP_OK|Error|Traceback" || true
	$PY volumes.py flancs "$K" || continue
	ID=$(curl -s -X POST http://127.0.0.1:8188/prompt -H "Content-Type: application/json" \
		--data-binary @"C:/ComfyUI_windows_portable/dino_workflows/vol_flancs_$K.api.json" | $PY -c "import json,sys; print(json.load(sys.stdin)['prompt_id'])")
	# Attendre la peinture (l'historique de ComfyUI contient l'id quand c'est fini).
	for _ in $(seq 1 720); do
		if curl -s "http://127.0.0.1:8188/history/$ID" | grep -q '"outputs"'; then break; fi
		sleep 5
	done
	$PY volumes.py textures "$K" || continue
	"$BL" --background --python volumes_blender.py -- bake "$K" 2>&1 | grep -E "BAKE_OK|TEMPS|Error|Traceback" || true
	$PY volumes.py kinds "$K"   # Prop.KINDS : le modèle et sa collision (emprise au sol)
	cat /c/ComfyUI_windows_portable/blender_tests/volumes/"$K"/info.json | $PY -c "import json,sys; i=json.load(sys.stdin); print('INFO', '$K', 'angle', i['theta_deg'], 'iou', i['iou'], 'faces', i['faces'], 'solid_px', i['solid_px'])"
done
