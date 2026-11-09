#!/bin/sh
# Render the README pictures with solventc v0.1.15 or later.
# Usage: sh hardware/render.sh [OUT]
# SOLVENTC selects the executable; OUT defaults to hardware/images.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
out=${1:-$here/images}
solventc=${SOLVENTC:-solventc}
mkdir -p "$out"

# The assembly, its electronics with the cover and bay frame hidden, and a
# longitudinal section through the valve stem and the compound gear's axle.
"$solventc" --no-progress "$here/radiatorbot.sv" --size 1600 \
  --png "$out/assembly.png" --view 120,25 \
  --png "$out/electronics.png" --view 120,25 --hide cover_part,frame_part \
  --png "$out/valve-section.png" --view right --section x=0mm \
  > /dev/null

# The same geared-motor module used by the assembly, on its own datum:
# expose the three stages, cut along their common shaft, then across the
# lowest stage's teeth (z = case_floor + gap + stage_zb + planet_face / 2).
"$solventc" --no-progress "$here/geared_motor.sv" --size 1600 \
  --png "$out/planetary-gears.png" --view home --hide gearmotor.gearcase \
  --png "$out/motor-section.png" --view right --section x=0mm \
  --png "$out/planetary-section.png" --view top --section z=12.1mm \
  > /dev/null

printf 'Rendered README pictures in %s\n' "$out"
