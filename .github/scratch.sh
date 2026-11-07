cd hardware
rm -rf /tmp/h && cp -r . /tmp/h && cd /tmp/h
python3 - <<'PY'
s=open('radiatorbot.sv').read()
s=s.replace("gearmotor seats(turn: 0deg, up: std.z, east: bot.u) unit_at\n","")
s=s.replace("unit_feet seats(turn: 0deg, up: std.z, east: bot.u) unit_at\n","")
s=s.replace("                         checks: checks)\n","                         checks: checks) in unit_f\n",1)
s=s.replace("unit_feet := Footprint(depth: unit_z0 - floor_z1, floor_t: floor_z1 - floor_z0)","unit_feet := Footprint(depth: unit_z0 - floor_z1, floor_t: floor_z1 - floor_z0) in unit_f")
s=s.replace("unit_at := point\n","""unit_f := frame
fix(origin == (-p_y, p_x, unit_z0)) unit_f
fix(dir == (0, 1, 0)) unit_f.u
fix(dir == (-1, 0, 0)) unit_f.v
unit_lx := axis
unit_ly := axis
fix(dir == (0, 1, 0), origin == (-p_y, p_x, unit_z0)) unit_lx
fix(dir == (-1, 0, 0), origin == (-p_y, p_x, unit_z0)) unit_ly
unit_level := plane(u: unit_lx, v: unit_ly)
unit_at := point
""")
s=s.replace("ToothSpace(gearmotor.std.top,","ToothSpace(unit_level,")
open('radiatorbot.sv','w').write(s)
PY
grep -n "unit_f\|unit_level" radiatorbot.sv | head
echo "== H unit in a held frame"; /usr/bin/time -f "%e s" solventc --no-progress --no-check --set shaped=0 radiatorbot.sv 2>&1 | grep -E "followed| s$|error|params|solve" | head || true
