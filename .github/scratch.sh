cd hardware
# E: each planet's pin a point seated at its bearing
rm -rf /tmp/e && cp -r . /tmp/e && cd /tmp/e
python3 - <<'PY'
s=open('planetary.sv').read()
s=s.replace("""// == The stage ===""","""// A planet's pin's centre, `orbit` out along the frame's x: seated at its bearing.
component PinAt() {
  in std.top {
    c := point hint((orbit, 0))
    c on_u(d: orbit) std.top
  }
}

// == The stage ===""")
s=s.replace("""    ph := Phasing(ring_at: ring_at, k: k)
""","""    ph := Phasing(ring_at: ring_at, k: k)
    at := PinAt()
    at seats(turn: ph.bearing, up: std.z, east: std.x) std.origin
""")
a=s.index("    ph := Phasing(ring_at: ring_at, k: k)"); b=s.index("// == The ring")
blk=s[a:b].replace("plate.pin[k]","at.c")
s=s[:a]+blk+s[b:]
open('planetary.sv','w').write(s)
PY
grep -n "at.c\|PinAt" planetary.sv | head
echo "== E seated pins"; /usr/bin/time -f "%e s" solventc --no-progress --no-check --set shaped=0 radiatorbot.sv 2>&1 | grep -E "followed| s$|error|params" | head || true
cd - >/dev/null
# F: each planet's pin a point at its radius and bearing off the stage's x
rm -rf /tmp/f && cp -r . /tmp/f && cd /tmp/f
python3 - <<'PY'
s=open('planetary.sv').read()
s=s.replace("""  orbit_turn := frame
  orbit_turn turns(rate) spindle""","""  in std.top {
    construction datum := line(std.top.origin, hint((10, 0)))
    datum.p2 on_u(d: 10mm) std.top
  }
  orbit_turn := frame
  orbit_turn turns(rate) spindle""")
s=s.replace("""    ph := Phasing(ring_at: ring_at, k: k)
""","""    ph := Phasing(ring_at: ring_at, k: k)
    pc := point hint((orbit * cos(ph.bearing), orbit * sin(ph.bearing))) in std.top
    construction to_pin := line(std.top.origin, pc) in std.top
    length(orbit) to_pin
    datum angle(ph.bearing) to_pin
""")
a=s.index("    ph := Phasing(ring_at: ring_at, k: k)"); b=s.index("// == The ring")
blk=s[a:b].replace("plate.pin[k]","pc")
s=s[:a]+blk+s[b:]
open('planetary.sv','w').write(s)
PY
echo "== F angled pins"; /usr/bin/time -f "%e s" solventc --no-progress --no-check --set shaped=0 radiatorbot.sv 2>&1 | grep -E "followed| s$|error|params" | head || true
