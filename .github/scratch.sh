set -x
cd hardware
mkdir -p /tmp/out
time solventc gears.sv --where shown_sun.volume || true
time solventc --no-progress gears.sv --stl /tmp/out/sun.stl --solid shown_sun || true
ls -la /tmp/out
