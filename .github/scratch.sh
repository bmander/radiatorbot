set -x
cd hardware
solventc --no-progress probe_s1.sv --stl /tmp/s1.stl --solid x.space || true
solventc --no-progress probe_s2.sv --stl /tmp/s2.stl --solid top_space || true
solventc --no-progress probe_s2.sv --stl /tmp/s3.stl --solid inner.space || true
ls -la /tmp/*.stl || true
