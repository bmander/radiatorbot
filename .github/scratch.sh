cd hardware
git show 935a57e:hardware/radiatorbot.sv > old_bot.sv
echo "== old shaped=0"; /usr/bin/time -f "%e s" solventc --no-progress --no-check --set shaped=0 old_bot.sv 2>&1 | grep -E "followed| s$" || true
echo "== new shaped=0"; /usr/bin/time -f "%e s" solventc --no-progress --no-check --set shaped=0 radiatorbot.sv 2>&1 | grep -E "followed| s$" || true
# B: no planet motion
rm -rf /tmp/b && cp -r . /tmp/b && cd /tmp/b
python3 - <<'PY'
s=open('planetary.sv').read()
a=s.index("    spin := frame\n"); b=s.index("    pin_shown := pin.body at orbit_turn\n")+len("    pin_shown := pin.body at orbit_turn\n")
s=s[:a]+s[b:]
open('planetary.sv','w').write(s)
PY
echo "== B no planet motion"; /usr/bin/time -f "%e s" solventc --no-progress --no-check --set shaped=0 radiatorbot.sv 2>&1 | grep -E "followed| s$|error" || true
cd - >/dev/null
# C: no planets' gears at all (pg, pin) but motion frames kept
rm -rf /tmp/c && cp -r . /tmp/c && cd /tmp/c
python3 - <<'PY'
s=open('planetary.sv').read()
a=s.index("  orbit_turn := frame\n"); b=s.index("// == The ring")
s=s[:a]+"}\n\n"+s[b:]
s=s.replace("  construction planet := solid(st3.pg[0].gear)       // the part printed nine times\n","")
open('planetary.sv','w').write(s)
g=open('geared_motor.sv').read()
g=g.replace("  construction planet := solid(st3.pg[0].gear)       // the part printed nine times\n","  construction planet := solid(st3.sun)\n")
open('geared_motor.sv','w').write(g)
PY
echo "== C no planets"; /usr/bin/time -f "%e s" solventc --no-progress --no-check --set shaped=0 radiatorbot.sv 2>&1 | grep -E "followed| s$|error" | head || true
cd - >/dev/null
# D: carriers drawn plain (no CarrierPlate ring): the plate a disc
rm -rf /tmp/d && cp -r . /tmp/d && cd /tmp/d
python3 - <<'PY'
s=open('planetary.sv').read()
a=s.index("  half := carrier_arm / 2\n"); b=s.index("  construction plate := solid(std.solids.Prism(outline")
s=s[:a]+"""  in std.top {
    hub := point
    hub coincident std.top.origin
    ring stack_planets about hub {
      pin := point hint((orbit, 0))
    }
    hub distance(orbit, along: u) pin[0]
    hub level(v) pin[0]
    disc := radius(orbit + pin_boss_r) circle(center: hub)
    outline := face(disc)
  }
"""+s[b:]
open('planetary.sv','w').write(s)
PY
echo "== D plain plates"; /usr/bin/time -f "%e s" solventc --no-progress --no-check --set shaped=0 radiatorbot.sv 2>&1 | grep -E "followed| s$|error" | head || true
