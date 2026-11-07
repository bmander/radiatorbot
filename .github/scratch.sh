set -x
cd hardware
timeout 1200 solventc --no-check --timings radiatorbot.sv 2>&1 | cut -c1-400 | grep -v theorem | head -150 || true
