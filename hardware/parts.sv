// The radiator bot's building blocks, as a module: the posts, blocks, bores and joints its printed
// parts are made of.  Each is drawn in the frame its instance stands in, from its own datums: a
// part square to the bot is called `in` the bot's frame (radiatorbot.sv), and one about an axle is
// drawn about a point and up the frame's z.

unit mm
use std
use std.solids (cut, union)
use std.place (coords)
use std.shapes
use std.rounds (round)
use radiator_valve (HexBar)
use fits (pilot)

// A round post about `c` (drawn in std.top) from z0 to z1.
component Post(c: point, r: Length, z0: Length, z1: Length) {
  in std.top {
    rim := radius(r) circle(center: c) hint(r: r)
  }
  body := solid(std.solids.Prism(face(rim), from: z0, to: z1))
}

// A screw's post about `c` from z0 to z1, and the hole `depth` down into it from its top: the
// post goes on one part, the hole comes out of it.
component ScrewPost(c: point, r: Length, z0: Length, z1: Length, hole_d: Length, depth: Length) {
  in std.top {
    rim := radius(r) circle(center: c)
    bore := radius(hole_d / 2) circle(center: c)
  }
  post := solid(std.solids.Prism(face(rim), from: z0, to: z1))
  hole := solid(std.solids.Prism(face(bore), from: z1 - depth, to: z1 + 1mm))
}

// A block square to its frame: x0..x1, y0..y1, z0..z1.
component Block(x0: Length, x1: Length, y0: Length, y1: Length, z0: Length, z1: Length) {
  in std.top {
    c := point hint(((x0 + x1) / 2, (y0 + y1) / 2))
    c coords(du: (x0 + x1) / 2, dv: (y0 + y1) / 2) std.top
    sq := std.shapes.CenteredRectangle(c, w: x1 - x0, h: y1 - y0)
  }
  body := solid(std.solids.Prism(face(sq.loop), from: z0, to: z1))
}

// The same block with its four upright corners rounded, radius r.
component RoundedBlock(x0: Length, x1: Length, y0: Length, y1: Length, r: Length, z0: Length,
                       z1: Length) {
  in std.top {
    a := point hint((x0, y0))
    a coords(du: x0, dv: y0) std.top
    b := point hint((x1, y0))
    b coords(du: x1, dv: y0) std.top
    c := point hint((x1, y1))
    c coords(du: x1, dv: y1) std.top
    d := point hint((x0, y1))
    d coords(du: x0, dv: y1) std.top
    outline := (south := line(a, b)) -> round(r: r) (east := line(b, c)) -> round(r: r)
               (north := line(c, d)) -> round(r: r) (west := line(d, a)) -> round(r: r) close
  }
  body := solid(std.solids.Prism(outline, from: z0, to: z1))
}

// A dovetail up z from z0 to z1 about its frame's x, standing out along x: `w0` across at x0,
// `w1` at x1.
component Dovetail(x0: Length, x1: Length, w0: Length, w1: Length, z0: Length, z1: Length) {
  in std.top {
    a := point hint((x0, -w0 / 2))
    a coords(du: x0, dv: -w0 / 2) std.top
    b := point hint((x1, -w1 / 2))
    b coords(du: x1, dv: -w1 / 2) std.top
    c := point hint((x1, w1 / 2))
    c coords(du: x1, dv: w1 / 2) std.top
    d := point hint((x0, w0 / 2))
    d coords(du: x0, dv: w0 / 2) std.top
  }
  body := solid(std.solids.Prism(face(a, b, c, d, -> close), from: z0, to: z1))
}

// What stands under a 45deg slope across the frame's x, `w` wide: from x0 to x1, under
// z0 + (x - x0), down to zb.
component UnderSlope(x0: Length, x1: Length, z0: Length, zb: Length, w: Length) {
  in std.front {
    a := point hint((x0, zb))
    a coords(du: x0, dv: zb) std.front
    b := point hint((x1, zb))
    b coords(du: x1, dv: zb) std.front
    c := point hint((x1, z0 + x1 - x0))
    c coords(du: x1, dv: z0 + x1 - x0) std.front
    d := point hint((x0, z0))
    d coords(du: x0, dv: z0) std.front
  }
  body := solid(std.solids.Prism(face(a, b, c, d, -> close), from: -w / 2, to: w / 2))
}

// A snap's barb on a face square to x at `x`, `w` across about the frame's x: it stands `h` out
// toward -x, square on its underside at `z`, flat for `flat` and then ramped back into the face
// over `ramp`, and runs half a millimetre back into the face to join it.
component Barb(x: Length, z: Length, h: Length, w: Length, flat: Length, ramp: Length) {
  in std.front {
    a := point hint((x - h, z))
    a coords(du: x - h, dv: z) std.front
    b := point hint((x + 0.5mm, z))
    b coords(du: x + 0.5mm, dv: z) std.front
    c := point hint((x + 0.5mm, z + flat + ramp))
    c coords(du: x + 0.5mm, dv: z + flat + ramp) std.front
    d := point hint((x, z + flat + ramp))
    d coords(du: x, dv: z + flat + ramp) std.front
    e := point hint((x - h, z + flat))
    e coords(du: x - h, dv: z + flat) std.front
  }
  body := solid(std.solids.Prism(face(a, b, c, d, e, -> close), from: -w / 2, to: w / 2))
}

// A bore along x at (y, z), from x0 to x1; and a nut's hexagonal pocket so.
component BoreX(y: Length, z: Length, d: Length, x0: Length, x1: Length) {
  in std.side {
    c := point hint((y, z))
    c coords(du: y, dv: z) std.side
    rim := radius(d / 2) circle(center: c)
  }
  body := solid(std.solids.Prism(face(rim), from: x0, to: x1))
}
component NutX(y: Length, z: Length, af: Length, x0: Length, x1: Length) {
  in std.side {
    c := point hint((y, z))
    c coords(du: y, dv: z) std.side
    construction ref := horizontal line(c, hint((y + 5mm, z)))
    length(5mm) ref
  }
  nut := HexBar(c, ref, af: af, phase: 30deg, z0: x0, z1: x1)
}

// A printed collar on a rod up its frame's z: a ring `r` round a bore `bore` from z0 to z1, held
// by an M3 set screw tapped into it from -x at its middle.  Seated on the rod's axis, its x the
// way the screw is driven from.
component Collar(r: Length, bore: Length, z0: Length, z1: Length) {
  ring := Post(std.top.origin, r: r, z0: z0, z1: z1)
  hole := Post(std.top.origin, r: bore / 2, z0: z0 - 1mm, z1: z1 + 1mm)
  screw := BoreX(y: 0mm, z: (z0 + z1) / 2, d: pilot, x0: -r - 1mm, x1: 0mm)
  part := solid(ring.body)
  hole.body cut part
  screw.body cut part
}

// A countersink for an M3 flat head (6 mm across, 90deg), drawn with the face it opens on on
// std.top: seated at a screw's hole where it opens, it sinks the head flush.
component Countersink() {
  in std.top {
    rim := radius(3mm) circle(center: std.top.origin)
  }
  cone := solid(std.solids.Drafted(face(rim), from: -1.7mm, to: 0.5mm, draft: 45deg))
}
