set -x
cd hardware
solventc --no-progress probe_s4.sv --stl /tmp/s4.stl --solid x.tube --step-assembly /tmp/s4.step || true
ls -la /tmp/*.stl /tmp/*.step || true
