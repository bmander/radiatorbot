cd hardware
echo "== claims"; /usr/bin/time -f "%e s" solventc --no-progress radiatorbot.sv 2>&1 | cut -c1-300 | grep -vE "theorem|— holds" | head -20 || true
echo "== checks"
sed 's/^checks := 0 /checks := 1 /' radiatorbot.sv > rb_checks.sv
/usr/bin/time -f "%e s" solventc --no-progress rb_checks.sv 2>&1 | cut -c1-260 | grep -E " s$|error|refuted|undecided|independent|pg.gear|pinion|unsolved|params" | head -40 || true
echo "== geared motor, checks"
sed 's/shaped: 1, checks: 0)/shaped: 1, checks: 1)/' geared_motor.sv > gm_checks.sv
/usr/bin/time -f "%e s" solventc --no-progress gm_checks.sv 2>&1 | cut -c1-260 | grep -E " s$|error|refuted|undecided|pg.gear|params" | head -20 || true
