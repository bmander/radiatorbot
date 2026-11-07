cd hardware
# F: each planet's pin a point at its radius and bearing off the stage's x
rm -rf /tmp/f && cp -r . /tmp/f && cd /tmp/f
python3 - <<'PY'
s=open('planetary.sv').read()
s=s.replace("use std.place (vertical, on_v, raised, seats)","use std.place (vertical, on_u, on_v, raised, seats)")
s=s.replace("""  orbit_turn := frame
  orbit_turn turns(rate) spindle""","""  in std.top {
    construction datum := line(std.top.origin, hint((10, 0)))
    datum.p2 on_u(d: 10mm) std.top
  }
  orbit_turn := frame
  orbit_turn turns(rate) spindle""")
s=s.replace("""    ph := Phasing(ring_at: ring_at, k: k)
""","""    ph := Phasing(ring_at: ring_at, k: k)
    pc := point hint((orbit, 0)) in std.top
    construction to_pin := line(std.top.origin, pc) in std.top
    length(orbit) to_pin
    datum angle(ph.bearing) to_pin
""")
a=s.index("    ph := Phasing(ring_at: ring_at, k: k)"); b=s.index("// == The ring")
blk=s[a:b].replace("plate.pin[k]","pc")
s=s[:a]+blk+s[b:]
open('planetary.sv','w').write(s)
PY
echo "== F angled pins"; /usr/bin/time -f "%e s" solventc --no-progress --no-check --set shaped=0 radiatorbot.sv 2>&1 | grep -E "followed| s$|error|params|solve" | head || true
echo "== F full"; /usr/bin/time -f "%e s" solventc --no-progress radiatorbot.sv 2>&1 | grep -E "followed| s$|error|params|solve|refuted|undecided" | head || true
