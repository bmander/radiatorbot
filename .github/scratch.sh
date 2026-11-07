cd hardware
echo "== claims"
time solventc --no-progress radiatorbot.sv 2>&1 | cut -c1-500 | grep -v "theorem" | head -80 || true
echo "== checks"
sed 's/^checks := 0 /checks := 1 /' radiatorbot.sv > rb_checks.sv
time solventc --no-progress rb_checks.sv 2>&1 | cut -c1-500 | grep -v "theorem" | head -120 || true
echo "== export"
time sh export.sh /tmp/out 2>&1 | tail -40 || true
ls -la /tmp/out || true
echo "== geared motor"
time solventc --no-progress geared_motor.sv 2>&1 | cut -c1-500 | grep -v "theorem" | head -40 || true
