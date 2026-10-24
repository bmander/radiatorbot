// A cast-iron radiator angle valve, as measured on the radiator.  The supply pipe drops into the
// valve's top, the outlet runs sideways through a union into the radiator's spud, and the
// bonnet, packing nut and star handle hang below on the stem.
//
// Coordinates: the stem's axis is std.z, running up through the supply pipe, and z = 0 is the
// bottom face of the packing nut (the sketch's heavy line).  The radiator lies toward +x.
//
// The handle rides a frame turning about the stem's axis.  Scrub `handle_turn`: positive is
// right-handed about the upward axis — clockwise seen from below, looking at the handle — the
// way a right-hand stem thread closes the valve.
//
// Every part is a component.  Each stands in the world's frame and reads its datums (std.top
// square to the stem, std.front through it, std.side square to the outlet), so a part is drawn
// where it is in the assembly and takes only its sizes and stations.  Dimensions are measured
// unless marked "~", an estimate read off the sketch's proportions or the photos, worth checking
// with calipers.

unit mm
use std
use std (horizontal, vertical, turns, round)

// == Dimensions ==================================================================================
// One table per part.  Stations along the stem (z) and along the outlet (x) are from the datums
// above.

// The body casting's sizes, and the interface ValveBody reads them through.
interface BodySizes {
  inlet_af: Length, inlet_top: Length, inlet_h: Length
  bulge_d: Length, bulge_r: Length
  collar_d: Length, collar_top: Length, collar_bottom: Length
  boss_d: Length, boss_x: Length
}
body_dims := {
  inlet_af: 30.0mm,          // inlet hex, across the flats
  inlet_top: 73.3mm,
  inlet_h: 10mm,             // ~
  bulge_d: 33.7mm,
  bulge_r: 25mm,             // ~ the bulge's radius in section
  collar_d: 34mm,            // ~
  collar_top: 37mm,          // ~
  collar_bottom: 29.4mm,
  boss_d: 24mm,              // ~ the outlet boss
  boss_x: 26mm,              // ~ where the boss meets the union nut
}
// ~ the outlet's axis, at the middle of the bulge
outlet_z := (body_dims.inlet_top - body_dims.inlet_h + body_dims.collar_top) / 2

pipe_dims := {
  d: 22.2mm,                 // over the paint
  len: 60mm,                 // ~ the stub drawn
}
bonnet_dims := {
  w: 21.6mm,                 // the square nut, across the flats
  bottom: 18.1mm,
  neck_d: 14mm,              // ~ the threaded neck down to the packing nut
}
packing_dims := {
  af: 20.6mm,
  top: 12.1mm,               // its bottom face is the datum
}
union_dims := {
  af: 33.1mm,
  x1: 42mm,                  // ~ the nut's far face; it starts at the boss
  tail_d: 24mm,              // ~ the tailpiece, nut to spud
}
spud_dims := {
  x: 50mm,                   // the radiator spud's face, from the stem's axis
  d: 46mm,                   // ~
  t: 8mm,                    // ~
}

// The star handle's sizes, and the interface StarHandle reads them through.  `span` and `waist`
// are measured over the rounds: across the tips, and across opposite fillets.
interface StarSizes {
  span: Length, waist: Length, h: Length
  tip_r: Length, fillet_r: Length, draft: Angle
  rim_r: Length, edge_r: Length
  stem_d: Length
}
handle_dims := {
  span: 74.2mm,
  waist: 25.8mm,
  h: 16.0mm,
  tip_r: 3.25mm,             // ~ at the top face; the draft leaves 1 mm at the bottom one
  fillet_r: 4mm,             // ~ the fillet at the arms' base
  draft: 8deg,               // ~ from the side photo
  rim_r: 0.6mm,              // ~ the bottom face's rolled rim: less than the tips' radius there
  edge_r: 0.4mm,             // ~ the top face's edge, just broken
  stem_d: 7mm,               // ~ the stem the handle is fixed to
}
handle_gap := 1.1mm          // bare stem between the packing nut and the handle

// == Building blocks: prisms along an axis =======================================================
// Each draws its section about `c` in the plane `c` is drawn in, and extrudes it from `z0` to
// `z1` along that plane's normal.

// A round bar.
component RoundBar(c: point, d: Length, z0: Length, z1: Length) {
  in c.plane {
    rim := radius(d / 2) circle(center: c)
  }
  bar := solid(face(rim), from: z0, to: z1)
}

// A hexagonal bar by its width across the flats, a corner `phase` from the line `ref`.
component HexBar(c: point, ref: line, af: Length, phase: Angle, z0: Length, z1: Length) {
  in c.plane {
    corners := std.Polygon(c, ref, n: 6, r: af / sqrt(3), phase: phase)
    section := face(corners.v[0], corners.v[1], corners.v[2], corners.v[3], corners.v[4],
                    corners.v[5], -> close)
  }
  bar := solid(section, from: z0, to: z1)
}

// A square bar by its width across the flats, its sides square to the line `ref`.
component SquareBar(c: point, ref: line, w: Length, z0: Length, z1: Length) {
  in c.plane {
    corners := std.Polygon(c, ref, n: 4, r: w / sqrt(2), phase: 45deg)
    section := face(corners.v[0], corners.v[1], corners.v[2], corners.v[3], -> close)
  }
  bar := solid(section, from: z0, to: z1)
}

// == Parts =======================================================================================

// The body casting: a barrel turned about the stem, its bulge centred on the outlet's axis, with
// the inlet hex on top and the outlet boss running out to `outlet`'s plane.
component ValveBody(outlet: point, ref: line, s: BodySizes) {
  // the turned section, on the front plane through the stem's axis: up the axis from the collar's
  // underside, out across the collar, the bulge, and back in at the top
  in std.front {
    bulge_c := point
    std.origin distance(s.bulge_d / 2 - s.bulge_r, along: u) bulge_c
    bulge_c level(std.z) outlet

    foot := point
    std.origin level(right) foot
    std.origin distance(s.collar_bottom, along: v) foot
    section := step(u: s.collar_d / 2) (collar_under := line(foot)) ->
               step(v: s.collar_top) (collar_side := line) ->
               horizontal (collar_over := line(p2: hint((0.4 * s.bulge_d, s.collar_top)))) ->
               (bulge := arc(center: bulge_c)) ->
               horizontal (crown := line(hint((0.4 * s.bulge_d, s.inlet_top - s.inlet_h)))) ->
               (on_axis := line) -> close
    radius(s.bulge_r) bulge
    ccw(bulge_c, bulge.start, bulge.end)            // the bulge on the outside
    std.origin distance(s.inlet_top - s.inlet_h, along: v) bulge.end
    std.origin level(right) crown.p2
  }
  barrel := solid(section, about: std.z)
  inlet := HexBar(std.top.origin, ref, af: s.inlet_af, phase: 0deg,
                  z0: s.inlet_top - s.inlet_h, z1: s.inlet_top)
  boss := RoundBar(outlet, d: s.boss_d, z0: 0mm, z1: s.boss_x)

  casting := solid(barrel)
  inlet.bar union casting
  boss.bar union casting
}

// The bonnet: a square nut under the body's collar and the threaded neck below it.
component Bonnet(ref: line, nut_w: Length, neck_d: Length,
                 z_neck: Length, z_bottom: Length, z_top: Length) {
  nut := SquareBar(std.top.origin, ref, w: nut_w, z0: z_bottom, z1: z_top)
  neck := RoundBar(std.top.origin, d: neck_d, z0: z_neck, z1: z_bottom)
  bonnet := solid(nut.bar)
  neck.bar union bonnet
}

// The outlet's union: the nut, and the tailpiece from it to the radiator's spud.
component OutletUnion(outlet: point, ref: line, nut_af: Length, tail_d: Length,
                      x0: Length, x1: Length, x_spud: Length) {
  nut := HexBar(outlet, ref, af: nut_af, phase: 0deg, z0: x0, z1: x1)
  tailpiece := RoundBar(outlet, d: tail_d, z0: x1, z1: x_spud)
}

// The star handle's outline in plan, drawn on `top` about its origin: four arms, each with straight
// sides, a rounded tip and a fillet where it meets the next arm.  The first arm points along
// `top`'s u.  `span` and `waist` are measured over the rounds: across the tips, and across
// opposite fillets.  The handle below is this outline extruded; the radiator bot's wheel is cut by
// it at the draft's sections.
component StarOutline(top: plane, s: StarSizes) {
  in top {
    hub := point
    hub coincident top.origin

    // One arm and the fillet after it, turned four times, walked counter-clockwise from the
    // apex of a tip: half the tip's round, a straight side, the fillet, the next arm's near side
    // and half the next tip's round to its apex.  The fillet is concave, so it is written from
    // its far end, an arc running counter-clockwise.
    ring 4 about hub {
      tip_c := point hint((s.span / 2 - s.tip_r, 0))
      fillet_c := point hint(((s.waist / 2 + s.fillet_r) / sqrt(2),
                              (s.waist / 2 + s.fillet_r) / sqrt(2)))
      apex := point hint((s.span / 2, 0))
      hub distance(s.waist / 2 + s.fillet_r) fillet_c
      line(fillet_c, tip_c) equal line(fillet_c, next.tip_c)   // the fillet midway between arms
      ccw(hub, tip_c, fillet_c)
      // the apex out along the arm's centre line, `tip_r` past the tip's centre: it sets the
      // tip's radius
      apex coincident(t == s.span / (s.span - 2 * s.tip_r)) line(hub, tip_c)

      // where each piece hands on to the next, seeded where they lie near enough
      p1 := point hint((tip_c.x, s.tip_r))
      p2 := point hint((fillet_c.x - 0.2 * s.fillet_r, fillet_c.y - 0.98 * s.fillet_r))
      p3 := point hint((fillet_c.x - 0.98 * s.fillet_r, fillet_c.y - 0.2 * s.fillet_r))
      p4 := point hint((s.tip_r, tip_c.x))

      tip_half := arc(center: tip_c, start: apex, end: p1)
      side := line(p1, p2)
      fillet := arc(center: fillet_c, start: p3, end: p2)
      next_side := line(p3, p4)
      next_tip_half := arc(center: next.tip_c, start: p4, end: next.apex)

      radius(s.fillet_r) fillet
      side tangent(at: p1) tip_half
      side tangent(at: p2) fillet
      next_side tangent(at: p1) fillet
      next_side tangent(at: p2) next_tip_half
      // each side the common tangent with the arm on its left and the fillet's centre on its right
      ccw(p1, p2, tip_c)
      cw(p1, p2, fillet_c)
      ccw(p3, p4, next.tip_c)
      cw(p3, p4, fillet_c)
    }
    // the first arm out along the plane's u, which places the ring's turn
    hub distance(s.span / 2 - s.tip_r, along: u) tip_c[0]
    hub level(v) tip_c[0]

    outline := face(tip_half[0], side[0], fillet[0], next_side[0], next_tip_half[0],
                    tip_half[1], side[1], fillet[1], next_side[1], next_tip_half[1],
                    tip_half[2], side[2], fillet[2], next_side[2], next_tip_half[2],
                    tip_half[3], side[3], fillet[3], next_side[3], next_tip_half[3])
  }
}

// The star handle and the stem it is fixed to, drawn on `top`, the plane of the handle's top
// face: the draft's parting plane, where the outline is widest.
//
// The outline (`StarOutline`) is extruded `h` down from `top` with a draft, its sides leaning in toward the flat
// bottom face, whose rim is rolled where the chrome turns over; the top face's edge is broken.
component StarHandle(top: plane, s: StarSizes, stem_up: Length) {
  plan := StarOutline(top, s)
  in top {
    stem_rim := radius(s.stem_d / 2) circle(center: plan.hub)
  }
  star := solid(plan.outline, from: -s.h, to: 0mm, draft: s.draft)
  stem := solid(face(stem_rim), from: -s.h / 2, to: stem_up)

  handle := solid(star)
  stem union handle
  handle.star.far round(r: s.rim_r) handle.star       // the bottom face's rolled rim
  handle.star.near round(r: s.edge_r) handle.star     // the top face's broken edge
}

// == The assembly ================================================================================
// The valve as it stands on the radiator, drawn from the tables above, its handle turned
// `handle_turn` about the stem.  A model that works on the valve (the radiator bot) draws it with
// `use radiator_valve (RadiatorValve)` and reads its datums and parts by name: `valve.stem_axis`,
// `valve.handle_top`, `valve.star_handle`.
component RadiatorValve(handle_turn: Angle) {
  // The stem's axis, which the handle turns about; the outlet's axis where it crosses the side
  // plane (x = 0), from which the outlet's parts are stationed along x; and a reference line in
  // each plane the hex parts are drawn in, their flats squared to it.
  in std.front {
    construction stem_axis := vertical line(std.origin, hint((0, 10)))
    length(10mm) stem_axis
  }
  in std.top {
    construction top_ref := horizontal line(std.top.origin, hint((10, 0)))
    length(10mm) top_ref
  }
  in std.side {
    outlet := point hint((0, outlet_z))
    std.side.origin level(u) outlet
    std.side.origin distance(outlet_z, along: v) outlet
    construction side_ref := horizontal line(outlet, hint((10, outlet_z)))
    length(10mm) side_ref
  }

  supply_pipe := RoundBar(std.top.origin, d: pipe_dims.d,
                          z0: body_dims.inlet_top, z1: body_dims.inlet_top + pipe_dims.len)

  body := ValveBody(outlet, top_ref, s: body_dims)

  bonnet := Bonnet(top_ref, nut_w: bonnet_dims.w, neck_d: bonnet_dims.neck_d,
                   z_neck: packing_dims.top, z_bottom: bonnet_dims.bottom,
                   z_top: body_dims.collar_bottom)

  packing_nut := HexBar(std.top.origin, top_ref, af: packing_dims.af, phase: 0deg,
                        z0: 0mm, z1: packing_dims.top)

  union := OutletUnion(outlet, side_ref, nut_af: union_dims.af, tail_d: union_dims.tail_d,
                       x0: body_dims.boss_x, x1: union_dims.x1, x_spud: spud_dims.x)

  radiator_spud := RoundBar(outlet, d: spud_dims.d,
                            z0: spud_dims.x, z1: spud_dims.x + spud_dims.t)

  // The handle's joint: a frame turning about the stem's axis, standing at `handle_turn`.
  handle := frame
  handle turns(1) stem_axis
  fix(value == handle_turn) handle

  // The handle's top face, square to the stem `handle_gap` below the packing nut, and that plane
  // where the joint's turn puts it.
  handle_top := plane
  fix(origin == (0mm, 0mm, -handle_gap)) handle_top
  fix(dir == (1, 0, 0)) handle_top.u
  fix(dir == (0, 1, 0)) handle_top.v
  turned_top := handle_top in handle

  star_handle := StarHandle(turned_top, s: handle_dims, stem_up: handle_gap + packing_dims.top)
}

// The valve with its handle to scrub.  A file that uses this one as a module draws neither the
// valve below nor the parameter.
param handle_turn: Angle over (0deg, 360deg)
valve := RadiatorValve(handle_turn: handle_turn)
