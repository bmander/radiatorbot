set -x
cd hardware
time solventc --no-check planetary.sv --where stage.plate.pin[1] --where stage.plate.hp[0] || true
time solventc --no-progress planetary.sv --stl /tmp/barrel.stl --solid barrel --stl /tmp/carrier.stl --solid stage.carrier || true
time solventc --no-check geared_motor.sv || true
time solventc --no-check radiatorbot.sv || true
ls -la /tmp/*.stl || true
