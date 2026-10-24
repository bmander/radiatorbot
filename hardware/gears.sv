// Spur gears for the radiator bot's gearbox, as a module.
//
// Every gear is printed, so every gear is **shaped**: its blank is cut by the basic rack's tooth
// stood at a run of instants of the rack rolling on the gear's pitch circle, as a gear shaper or a
// hob cuts one.  Nothing states an involute; the flanks the bites leave are one, and a small pinion
// is undercut where a real one would be.  The rack's tooth is drawn `thin` wider than the basic
// rack's, so the printed tooth comes out that much thinner on its pitch circle: a pair's backlash
// is the two gears' `thin`s added, which is what an FDM print's swollen flanks need to run.
//
// A gear is drawn about its own std.origin, its axis std.z and its faces at z0 and z1, so it is
// placed by a mate and every copy of one size is one figure.  Its solid is construction: an
// assembly makes its parts of gears (a compound is two, joined), and shows those.

unit mm
use std
use std (vertical, turns, slides, coords, on_v)

// A shaped spur gear: N teeth of module m and pressure angle phi, its rack drawn `shift` modules
// out from the pitch circle (a profile shift; a pinion under 17 teeth wants about (17 - N) / 17 to
// lose its undercut, and the wheel it runs with the same taken off, so the centre distance stays
// m (N1 + N2) / 2).  `step` is the roll between bites: the scallops it leaves on a flank are about
// (R step)^2 / 8 rho deep, rho the involute's radius of curvature there.
//
// The bites cut one tooth space, the one centred on +v (std.y); the others are that space turned
// a pitch at a time about the axis, so a tooth is centred 180deg / N on from +v.  With `shaped`
// 0 the gear is its blank, its tip cylinder: quick to draw while the layout is worked on.
component ShapedSpur(N: Int, m: Length, phi: Angle, shift: Scalar, thin: Length, z0: Length,
                     z1: Length, bore: Length, step: Angle, shaped: Int) {
  R := m * N / 2                         // the pitch circle
  Rp := R + shift * m                    // where the rack's pitch line stands off the axis
  Rt := Rp + m                           // the tip: an addendum off the rack's pitch line
  hw := pi * m / 4 + thin / 2            // the rack tooth's half thickness on its pitch line
  // how far the rack runs while its tooth is inside the tip circle, as a roll of the blank
  reach := sqrt(Rt ^ 2 - (Rp - 1.25 * m) ^ 2) + hw + 1.5 * m * tan(phi)
  window := reach / R * 1rad

  in std.front {
    construction spindle := vertical line(std.origin, hint((0, 10)))
    length(10mm) spindle
  }
  in std.top {
    // the rack's pitch line, tangent to the pitch circle at +v and running -u: the way the
    // blank's pitch point goes as it turns counter-clockwise, so the rack rolls with it
    construction rack_line := line(hint((10, Rp)), hint((0, Rp)))
    rack_line.p1 coords(du: 10mm, dv: Rp) std.top
    rack_line.p2 on_v(d: Rp) std.top

    // the basic rack's tooth, pointing in: its flanks lean `phi` off the radial, it runs a full
    // dedendum (1.25 m) in past the pitch line to cut the root, and out past the blank's tip
    a := point hint((-hw - 1.5 * m * tan(phi), Rp + 1.5 * m))
    b := point hint((-hw + 1.25 * m * tan(phi), Rp - 1.25 * m))
    c := point hint((hw - 1.25 * m * tan(phi), Rp - 1.25 * m))
    d := point hint((hw + 1.5 * m * tan(phi), Rp + 1.5 * m))
    a coords(du: -hw - 1.5 * m * tan(phi), dv: Rp + 1.5 * m) std.top
    b coords(du: -hw + 1.25 * m * tan(phi), dv: Rp - 1.25 * m) std.top
    c coords(du: hw - 1.25 * m * tan(phi), dv: Rp - 1.25 * m) std.top
    d coords(du: hw + 1.5 * m * tan(phi), dv: Rp + 1.5 * m) std.top
    rack_tooth := face(a, b, c, d, -> close)

    tip := circle(center: std.top.origin) hint(r: Rt)
    radius(Rt) tip
    hole := circle(center: std.top.origin) hint(r: bore / 2)
    radius(bore / 2) hole
    construction pitch := circle(center: std.top.origin) hint(r: R)
    radius(R) pitch
  }
  private construction tooth := solid(rack_tooth, from: z0 - 1mm, to: z1 + 1mm)

  // the generating roll: the blank turns, the rack slides its pitch circle's length a turn
  blank_turn := frame
  blank_turn turns(1) spindle
  rack := frame
  rack slides(2 * pi * R) rack_line
  index := frame
  index turns(1) spindle

  construction gear := solid(face(tip, holes: hole), from: z0, to: z1)
  when shaped == 1 {
    private construction space := solid()
    repeat round(2 * window / step) + 1 as k {
      bite := tooth at(under: rack, seen_from: blank_turn) (-window + k * step)
      bite union space
    }
    space cut gear
    repeat N - 1 as j {
      turned := space at(under: index) ((j + 1) * 360deg / N)
      turned cut gear
    }
  }
}

preview {
  pinion := ShapedSpur(N: 12, m: 1.5mm, phi: 20deg, shift: 0.3, thin: 0.15mm, z0: 0mm, z1: 10mm,
                       bore: 6.35mm, step: 3deg, shaped: 1)
  shown := solid(pinion.gear)
}
