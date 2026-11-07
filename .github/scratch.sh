cd hardware
time solventc --no-progress --no-check --set shaped=0 radiatorbot.sv 2>&1 | cut -c1-300 | grep -v theorem | head -60
time solventc --no-progress --no-check --lint radiatorbot.sv 2>&1 | cut -c1-300 | grep -v theorem | head -60
