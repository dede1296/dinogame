#!/bin/sh
# Rend une ou plusieurs partitions (ou thèmes d'origine : theme:monts) avec FluidSynth + GeneralUser GS
# → ogg/<piste>_sf.ogg (à écouter avant de livrer).
# Usage : sh rendre.sh volcan souverain theme:monts theme:victoire
cd "$(dirname "$0")" || exit 1
FS=bin/fluidsynth-v2.6.1-win10-x64-cpp11/bin/fluidsynth.exe
mkdir -p out ogg
for p in "$@"; do
  b="${p#theme:}"; extra=""
  case "$b" in victoire|capture) [ "$b" != "$p" ] && extra="--once" ;; esac
  rm -f out/$b.mid out/${b}_*.mid out/$b.wav out/${b}_*.wav
  node export_midi.mjs "$p" || exit 1
  wavs=""
  for m in out/$b.mid out/${b}_[0-9].mid; do
    [ -f "$m" ] || continue
    w="${m%.mid}.wav"
    "$FS" -ni -F "$w" -r 48000 -g 0.8 sf/GeneralUser-GS.sf2 "$m" < /dev/null > /dev/null 2>&1 || exit 1
    wavs="${wavs:+$wavs,}../music-sf/$w"
  done
  (cd ../music-synth && node render.mjs "$p" $extra --from-wav "$wavs" --out "../music-sf/ogg/${b}_sf.ogg" --force) | head -c 220; echo
done
