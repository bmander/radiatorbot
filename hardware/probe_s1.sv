// Temporary probe: a screw's face family inside a component, its parameter a formal.
unit mm
use std
use std.shapes
use std.solids (cut)
use std.place (vertical, coords)
use std.motion (screws)
component BT(s: Scalar) {
  in std.front {
    construction spindle := vertical line(std.origin, hint((0, 10)))
    length(10mm) spindle
  }
  screw := frame
  screw screws(50mm) spindle
  fix(value == 90deg * s) screw
  in screw {
    in std.top {
      a := point hint((10, 0))
      a coords(du: 10mm, dv: 0mm) std.top
      sq := std.shapes.CenteredRectangle(a, w: 2mm, h: 2mm)
    }
    section := face(sq.loop)
  }
  space := solid({ p | some s: p in section at s })
}
param s: Scalar over (0, 1)
x := BT(s: s)
