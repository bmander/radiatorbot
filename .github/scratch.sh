cd hardware
echo "== now"; solventc --no-progress --no-check --set shaped=0 radiatorbot.sv --where gearmotor.motor_at --where p_c 2>&1 | grep -E "error|motor_at|p_c" | head || true
rm -rf /tmp/j && cp -r . /tmp/j && cd /tmp/j
python3 - <<'PY'
s=open('radiatorbot.sv').read()
s=s.replace("""in bot {
  unit_frame := frame
  fix(origin == (p_x, p_y, unit_z0)) unit_frame
  fix(dir == (1, 0, 0)) unit_frame.u
  fix(dir == (0, 1, 0)) unit_frame.v
}""","""unit_at := point
unit_at raised(d: unit_z0, along: std.z) p_c
unit_frame := frame
unit_frame.origin coincident unit_at
unit_frame.u parallel(sense: same) bot.u
unit_frame.v parallel(sense: same) bot.v""")
open('radiatorbot.sv','w').write(s)
PY
echo "== J relations"; /usr/bin/time -f "%e s" solventc --no-progress --set shaped=0 radiatorbot.sv --where gearmotor.motor_at 2>&1 | cut -c1-250 | grep -E "followed| s$|error|params|solve|motor_at|base_shell" | head || true
cd /home/runner/work/radiatorbot/radiatorbot/hardware
rm -rf /tmp/k && cp -r . /tmp/k && cd /tmp/k
python3 - <<'PY'
s=open('radiatorbot.sv').read()
s=s.replace("""in bot {
  unit_frame := frame
  fix(origin == (p_x, p_y, unit_z0)) unit_frame
  fix(dir == (1, 0, 0)) unit_frame.u
  fix(dir == (0, 1, 0)) unit_frame.v
}""","""unit_frame := frame
fix(origin == (-p_y, p_x, unit_z0)) unit_frame
fix(dir == (0, 1, 0)) unit_frame.u
fix(dir == (-1, 0, 0)) unit_frame.v""")
open('radiatorbot.sv','w').write(s)
PY
echo "== K world"; /usr/bin/time -f "%e s" solventc --no-progress --set shaped=0 radiatorbot.sv --where gearmotor.motor_at 2>&1 | cut -c1-250 | grep -E "followed| s$|error|params|solve|motor_at|base_shell" | head || true
