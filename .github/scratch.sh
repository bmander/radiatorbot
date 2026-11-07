set -x
cd hardware
solventc --version
time solventc probe_frame.sv --where q --where b.c || true
time solventc planetary.sv || true
time solventc --no-progress planetary.sv --stl /tmp/barrel.stl --solid barrel --stl /tmp/carrier.stl --solid stage.carrier || true
ls -la /tmp/*.stl || true
