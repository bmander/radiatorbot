cd hardware
echo "== claims"; /usr/bin/time -f "%e s" solventc --no-progress radiatorbot.sv 2>&1 | cut -c1-300 | grep -vE "theorem|— holds" | head -40 || true
echo "== checks"
sed 's/^checks := 0 /checks := 1 /' radiatorbot.sv > rb_checks.sv
/usr/bin/time -f "%e s" solventc --no-progress rb_checks.sv 2>&1 | cut -c1-300 | grep -E " s$|error|refuted|undecided|independent|pinion|unsolved|not judged" | head -60 || true
echo "== export"; /usr/bin/time -f "%e s" sh export.sh /tmp/out 2>&1 | grep -E " s$|rror|refuted" | tail -10 || true
ls /tmp/out | wc -l; du -sh /tmp/out
echo "== geared motor"; /usr/bin/time -f "%e s" solventc --no-progress geared_motor.sv 2>&1 | cut -c1-300 | grep -E " s$|error|params|refuted|undecided" | head -20 || true
echo "== planetary"; /usr/bin/time -f "%e s" solventc --no-progress planetary.sv 2>&1 | cut -c1-300 | grep -E " s$|error|params|refuted|undecided" | head -20 || true
