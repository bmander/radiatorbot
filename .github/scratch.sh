cd hardware
echo "== shaped=0"; /usr/bin/time -f "%e s" solventc --no-progress --no-check --set shaped=0 radiatorbot.sv 2>&1 | grep -E "followed| s$|error|params|solve" | head -20 || true
echo "== claims"; /usr/bin/time -f "%e s" solventc --no-progress radiatorbot.sv 2>&1 | cut -c1-300 | grep -E "followed| s$|error|params|solve|refuted|undecided|pinion|gearcase" | head -40 || true
echo "== geared motor"; /usr/bin/time -f "%e s" solventc --no-progress geared_motor.sv 2>&1 | cut -c1-300 | grep -E " s$|error|params|solve|refuted|undecided" | head -20 || true
echo "== planetary"; /usr/bin/time -f "%e s" solventc --no-progress planetary.sv 2>&1 | cut -c1-300 | grep -E " s$|error|params|solve|refuted|undecided" | head -20 || true
