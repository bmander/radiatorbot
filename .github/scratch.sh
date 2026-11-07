cd hardware
echo "== new shaped=0"; /usr/bin/time -f "%e s" solventc --no-progress --no-check --set shaped=0 radiatorbot.sv 2>&1 | grep -E "followed| s$|error|params|solve" | head -20 || true
echo "== planetary"; /usr/bin/time -f "%e s" solventc --no-progress --no-check planetary.sv 2>&1 | grep -E " s$|error|params|solve" | head -20 || true
