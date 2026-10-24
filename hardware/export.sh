#!/bin/sh
# Write the radiator bot's printed parts as STL, one file a part, into OUT (default hardware/stl).
# Each run shapes the gears and the wheel it needs; the whole set takes several minutes.
#
#     sh hardware/export.sh [OUT]
set -eu
here=$(cd "$(dirname "$0")" && pwd)
out=${1:-$here/stl}
solventc=${SOLVENTC:-solventc}
mkdir -p "$out"
for part in wheel_part collar_part motor_pinion b1 b2 b3 d1 d2 base frame_part cap_part cover_part; do
  start=$(date +%s)
  "$solventc" --no-progress "$here/radiatorbot.sv" --stl "$out/$part.stl" --solid "$part" > /dev/null
  echo "$part.stl ($(($(date +%s) - start)) s)"
done
