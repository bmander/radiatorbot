cd hardware
time solventc --no-progress --timings radiatorbot.sv 2>&1 | cut -c1-300 | grep -v "theorem\|— holds" | head -60 || true
