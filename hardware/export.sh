#!/bin/sh
# Write the radiator bot's printed parts as STL, one file a part, into OUT (default hardware/stl).
# One solventc run: every part is built once, and the wheel and the gears are shaped once.
#
#     sh hardware/export.sh [OUT]
set -eu
here=$(cd "$(dirname "$0")" && pwd)
out=${1:-$here/stl}
solventc=${SOLVENTC:-solventc}
mkdir -p "$out"
set --
for part in wheel_part collar_part motor_pinion b1 b2 b3 d1 d2 base frame_part cap_part cover_part; do
  set -- "$@" --stl "$out/$part.stl" --solid "$part"
done
"$solventc" --no-progress "$here/radiatorbot.sv" "$@" > /dev/null
ls "$out"/*.stl
