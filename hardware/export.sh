#!/bin/sh
# Write the radiator bot's printed parts as STL, one file a part, and the whole bot as one STEP
# assembly (`radiatorbot.step`: the valve, the bought parts and the printed ones, each placed where
# it stands), into OUT (default hardware/stl).  One solventc run: every part is built once, and
# the socket and the gears are shaped once.
#
#     sh hardware/export.sh [OUT]
set -eu
here=$(cd "$(dirname "$0")" && pwd)
out=${1:-$here/stl}
solventc=${SOLVENTC:-solventc}
mkdir -p "$out"
set --
for part in socket_part a_part stand_part collar_part motor_pinion b1 b2 d1 d2 base frame_part \
    mount_part cap_part cover_part; do
  set -- "$@" --stl "$out/$part.stl" --solid "$part"
done
"$solventc" --no-progress "$here/radiatorbot.sv" --step-assembly "$out/radiatorbot.step" "$@" \
  > /dev/null
ls "$out"/*.stl "$out"/radiatorbot.step
