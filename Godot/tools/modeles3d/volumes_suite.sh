#!/usr/bin/env bash
# Traite les grands décors en vraie 3D au fil de l'eau : pour chaque sorte (dans l'ordre de la
# file ComfyUI), attend que son maillage Hunyuan3D sorte (jusqu'à 45 min), puis volumes_lot.sh.
#   bash volumes_suite.sh maison_port cabinet …   (journal : blender_tests/volumes/suite.log)
set -u
cd "$(dirname "$0")"
OUT=/c/ComfyUI_windows_portable/ComfyUI/output
for K in "$@"; do
	for _ in $(seq 1 540); do
		ls "$OUT"/volumes/ | grep -qE "^${K}(_[a-z])?_[0-9]+_\.glb$" && break
		sleep 5
	done
	echo "=== $K $(date +%H:%M)"
	bash volumes_lot.sh "$K"
done
echo "=== FINI $(date +%H:%M)"
