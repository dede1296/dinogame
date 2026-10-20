#!/bin/sh
# Rend une ou plusieurs partitions avec FluidSynth + GeneralUser GS → ogg/<piste>_sf.ogg (à écouter avant de livrer).
# Usage : sh rendre.sh volcan souverain cieux
cd "$(dirname "$0")" || exit 1
FS=bin/fluidsynth-v2.6.1-win10-x64-cpp11/bin/fluidsynth.exe
mkdir -p out ogg
for p in "$@"; do
  rm -f out/$p.mid out/${p}_*.mid out/$p.wav out/${p}_*.wav
  node export_midi.mjs "$p" || exit 1
  wavs=""
  for m in out/$p.mid out/${p}_[0-9].mid; do
    [ -f "$m" ] || continue
    w="${m%.mid}.wav"
    "$FS" -ni -F "$w" -r 48000 -g 0.8 sf/GeneralUser-GS.sf2 "$m" < /dev/null > /dev/null 2>&1 || exit 1
    wavs="${wavs:+$wavs,}../music-sf/$w"
  done
  (cd ../music-synth && node render.mjs "$p" --from-wav "$wavs" --out "../music-sf/ogg/${p}_sf.ogg" --force) | head -c 200; echo
done
