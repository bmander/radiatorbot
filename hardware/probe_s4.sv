// Temporary probe: a slab carried up a screw, cut from a tube in a component, its roll left to the tube.
unit mm
use std
use std.shapes
use std.solids (cut)
use std.place (vertical, coords)
use std.motion (screws, turns)
use parts (Post)
component Tube() {
  in std.front {
    construction spindle := vertical line(std.origin, hint((0, 10)))
    length(10mm) spindle
  }
  in std.top {
    a := point hint((10, 0))
    a coords(du: 10mm, dv: 0mm) std.top
    sq := std.shapes.CenteredRectangle(a, w: 2mm, h: 2mm)
  }
  rim := Post(std.top.origin, r: 12mm, z0: 0mm, z1: 10mm)
  bore := Post(std.top.origin, r: 9.5mm, z0: -1mm, z1: 11mm)
  tube := solid(rim.body)
  bore.body cut tube
  slab := solid(std.solids.Prism(face(sq.loop), from: -0.5mm, to: 0.5mm))
  screw := frame
  screw screws(50mm) spindle
  index := frame
  index turns(1) spindle
  space := solid({ p | some t: p in slab at(under: screw) t })
  space cut tube
  repeat 2 as j {
    turned := space at(under: index) ((j + 1) * 120deg)
    turned cut tube
  }
}
x := Tube()
