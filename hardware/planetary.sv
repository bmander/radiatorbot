// A planetary stage with helical teeth, and the internal gear its planets run in, as a module: the
// geared motor (geared_motor.sv) stacks three of these on the motor's axis inside one barrel.
//
// A stage is a sun, three planets on steel pins and the carrier the pins are pressed into, drawn
// about its own origin: the axis is std.z and the carrier's plate stands on std.top, the planets a
// print's clearance over it.  The ring round them is fixed and one with the next stage's, an
// internal gear the whole stack's height (`BarrelTeeth`, cut from the gearcase), so a stage is
// told only how the ring's teeth stand at its planets' undersides (`ring_at`), and stands its sun
// and planets to mesh with them.  Each stage is a 17-tooth sun, 19-tooth planets and the 55-tooth
// ring, (17 + 55) / 3 a whole number, so three planets spaced evenly mesh both; the carrier turns
// one turn for `stage_ratio` of its sun's, the same way.
//
// The teeth are helical, 25deg, for quiet: each tooth comes into mesh across the face rather than
// all along it at once, and a planet's 6 mm face overlaps a whole pitch, so one tooth pair is
// always in full contact.  The suns are left-handed, the planets and the ring right-handed.  At
// 25deg a 17-tooth sun is cut without undercut (the cutter's straight flank stops short of where
// it would fold the flank back, which the helical cut refuses), so no tooth is shifted and the
// centre distances are nominal.  Module 0.8 (normal) throughout: the finest an 0.4 mm nozzle
// prints well, with the teeth loaded far under what PETG bears.
//
// Every place round the axis is a turn, not a sine: the carrier's arms are one arm in a `ring`,
// each planet a gear seated at its pin and turned by the angle its mesh asks, and the ring's tooth
// spaces one space turned a pitch at a time.

unit mm
use std
use std.solids (cut, union)
use std.place (vertical, on_u, on_v, raised, seats)
use std.motion (turns, screws)
use gears (ShapedHelical)
use fits (run, press, gap, bond, wall, pa, thin, chamfer)
use parts (Post)

// == The teeth ===================================================================================
m_stack := 0.8mm                // the normal module
helix := 25deg
sun_n := 17
planet_n := 19
ring_teeth := 55                // the barrel's internal teeth
stack_planets := 3
sun_hand := -1
planet_hand := 1
m_t := m_stack / cos(helix)                                  // the transverse module, 0.883 mm
orbit := m_t * (sun_n + planet_n) / 2                        // the axis to each planet, 15.89 mm
ring_pitch := m_t * ring_teeth / 2                           // 24.27 mm
ring_tip_r := ring_pitch - m_stack                           // the barrel's bore, 23.47 mm
sun_tip_r := m_t * sun_n / 2 + m_stack                       // a sun's tips, 8.30 mm
ring_root_r := ring_pitch + 1.25 * m_stack                   // 25.27 mm
ring_lead := 2 * pi * ring_pitch / tan(helix)                // a tooth's rise a turn: 327 mm
ring_twist := planet_hand * 360deg / ring_lead               // its turn a millimetre up
stage_ratio := 1 + ring_teeth / sun_n                        // sun turns a carrier turn: 4.24

// == The pins, the carrier and the heights =======================================================
// The planets turn on 3 x 10 mm hardened dowel pins pressed `pin_seat` down into their carrier's
// plate; the carriers turn on a 4 mm drill rod up the axis.  From the carrier's underside up: its
// plate, then a print's clearance, the planets, and a print's clearance under the next stage's
// plate.  The sun stands level with its planets and runs `bond` up into the plate over them, the
// carrier it is printed with.
pin_d := 3mm
pin_len := 10mm
pin_seat := 4mm
p_rod_d := 4mm
p_bore := p_rod_d + run         // a carrier's bore, turning on the rod
planet_bore := pin_d + run
plate_t := 4.5mm
planet_face := 6mm
stage_zb := plate_t + gap                                  // the planets' and the sun's undersides
stage_h := plate_t + gap + planet_face + gap               // 11.1 mm, carrier to carrier
sun_face := planet_face + gap + bond
pin_wall := m_stack * (planet_n / (2 * cos(helix)) - 1.25) - planet_bore / 2   // roots to bore
sun_wall := m_stack * (sun_n / (2 * cos(helix)) - 1.25) - p_bore / 2

// The carrier's plate: an arm out to each pin, a boss round the pin's end, and a straight web from
// each arm to the next, `carrier_web` from the axis.  Each web stands over the whole of the sun's
// top under it and out over the inner rims of the planets below it, so whichever way the carrier
// stands it keeps them down on their pins.
pin_boss_r := pin_d / 2 + wall
carrier_arm := 1.6 * pin_boss_r                          // 6.2 mm, short of the bosses' 7.8
carrier_web := 8.5mm
carrier_fillet := 2mm

// == Building blocks =============================================================================

// A printed helical gear of the stack seated on an axle: its figure (gears.sv) with its origin
// `z` up the axle from `c`, its axis up the frame's z, turned `rot` from the frame's x (its cut
// space, centred on its own +v at its underside, then at `rot + 90deg`).  Gears of one size, face
// and bore are one figure, shaped once.
component Helical(c: point, z: Length, rot: Angle, N: Int, hand: Int, face: Length,
                  bore: Length, shaped: Int) {
  at := point
  at raised(d: z, along: std.z) c
  g := ShapedHelical(N: N, m: m_stack, phi: pa, beta: helix, hand: hand, shift: 0, add: 1,
                     thin: thin, z0: 0mm, z1: face, bore: bore, shaped: shaped, chamfer: chamfer)
  g seats(turn: rot, up: std.z, east: std.x) at
  construction gear := solid(g.gear)
}

// How a stage's gears stand at rest, the ring's teeth standing `ring_at` (a tooth space's middle
// on +v, turned that much) at the planets' undersides: planet `k`'s turn,
// `planet`, and its sun's, `sun`, each the turn its Helical is seated at.  Planet `k` stands at
// `bearing`, the first on the stage's x.  The planet's tooth that points out at the ring stands in
// a tooth space of it, turned by as much as the space is from the planet's bearing, in their
// ratio; the sun stands so that the first planet's space toward it holds one of its teeth, as
// rolling would bring them.  The other planets' meshes agree because (17 + 55) / 3 is whole.
component Phasing(ring_at: Angle, k: Int) {
  bearing := k * 360deg / stack_planets
  off := 90deg + ring_at                                       // the ring's space off planet 0
  sun := (180deg * planet_n - off * ring_teeth) / sun_n - 90deg
  planet := bearing + 90deg - (90deg + sun + 180deg / sun_n - bearing) * sun_n / planet_n
}

// The carrier's plate, drawn as one outline on std.top, from `z0` up `plate_t`: one arm and the
// web after it, turned round the axis for each planet.  The arm runs out to the pin (`pin`, the
// first on std.x), a little narrower than the boss round the pin's end, its sides running into the
// boss (as wide as the boss, they would meet it on a diameter, which the solve holds only by a
// double root); the web runs from the arm's side to the next arm's, `carrier_web` from the axis,
// rounded `carrier_fillet` into both.  Less the pins' holes, blind `pin_seat` down from its
// top.  One outline and a prism, rather than bars and posts unioned and filleted, which solventc
// v0.1.14 builds slowly and meshes badly.
component CarrierPlate(z0: Length) {
  half := carrier_arm / 2
  hub_x := 2 * carrier_web - sqrt(3) * half       // seeds: where a web meets an arm, for three
  in std.top {
    hub := point
    hub coincident std.top.origin
    ring stack_planets about hub {
      pin := point hint((orbit, 0))
      construction arm := line(hub, pin)
      // the arm's sides, `half` either side of it: where the webs meet them, and where they run
      // into the boss, on the near side of the pin
      hm := point hint((hub_x, -half))
      bm := point hint((orbit - pin_boss_r + 0.5mm, -half))
      bp := point hint((orbit - pin_boss_r + 0.5mm, half))
      hp := point hint((hub_x, half))
      hm distance(half, side: right) arm
      bm distance(half, side: right) arm
      bp distance(half, side: left) arm
      hp distance(half, side: left) arm
      hub distance(<= orbit, along: arm) bm
      hub distance(<= orbit, along: arm) bp
      // the web square to the line midway between the arms
      line(hub, hp) equal line(hub, next.hm)
      radius(pin_boss_r) boss
      hub distance(carrier_web, side: left) web
      // the walk, last: its round at the brace rounds the corner into the next arm
      (out := line(hm, bm)) -> (boss := arc(center: pin, start: bm, end: bp)) ->
        (back := line(bp, hp)) -> (corner := round(r: carrier_fillet))
        (web := line(hp, next.hm)) -> (elbow := round(r: carrier_fillet))
    }
    hub distance(orbit, along: u) pin[0]
    hub level(v) pin[0]
    outline := face(out[0], boss[0], back[0], corner[0], web[0], elbow[0],
                    out[1], boss[1], back[1], corner[1], web[1], elbow[1],
                    out[2], boss[2], back[2], corner[2], web[2], elbow[2])
  }
  construction plate := solid(std.solids.Prism(outline, from: z0, to: z0 + plate_t))
  repeat stack_planets as k {
    hole := Post(pin[k], r: (pin_d + press) / 2, z0: z0 + plate_t - pin_seat,
                 z1: z0 + plate_t + 1mm)
    hole.body cut plate
  }
}

// A barrel tooth space's flank at radius `r`: its angle off the space's middle, the involute of
// the ring's base circle through the pitch circle `space_half` off it.
ring_alpha := atan(tan(pa) / cos(helix))                    // the transverse pressure angle
ring_base := ring_pitch * cos(ring_alpha)
space_half := (pi * m_t / 2 + thin / cos(helix)) / (2 * ring_pitch) * 1rad
component Flank(r: Length) {
  at_r := acos(ring_base / r)
  th := space_half + (tan(ring_alpha) * 1rad - ring_alpha) - (tan(at_r) * 1rad - at_r)
}

// == The stage ===================================================================================

// One planetary stage at rest, and its planets turning, drawn up the frame's z from its carrier's
// underside at `z0` (a number, not a seat: drawn in the frame of what holds it, the stage's rows
// stay out of that frame's, which keeps the bot's follow of its handle quick).  Its carrier turns
// `rate` turns a turn of `roll` about the frame's z, and each planet on its pin against it,
// ring_teeth / planet_n turns the other way, carried round with it.  The carrier's plate with its
// pins' holes (`carrier`) and the sun (`sun`, bored `sun_bore`) are drawn at rest, for the unit to
// make its compounds of: a sun is printed with the carrier of the stage above it.  The pins (`pin`)
// and the planets (`planet_shown`) are drawn turning; `pg[k].gear` is planet `k` at rest.
component PlanetaryStage(z0: Length, ring_at: Angle, roll: Angle, rate: Scalar,
                         sun_bore: Length, shaped: Int) {
  claim ring_teeth == sun_n + 2 * planet_n
  claim stack_planets == 3                              // CarrierPlate's outline has three arms
  claim (sun_n + ring_teeth) / stack_planets == 24      // the planets spaced evenly
  claim pin_wall >= 1.5mm                               // a planet's roots to its bore
  claim sun_wall >= 1.5mm                               // a sun's roots to a carrier's bore
  claim pin_len - pin_seat <= planet_face               // each pin's top under its planet's
  claim carrier_web >= sun_tip_r                         // the webs over the sun's tips
  claim carrier_web >= orbit - m_t * planet_n / 2 - m_stack + 1mm   // and the planets' rims
  claim carrier_arm < 2 * pin_boss_r                    // the arm's sides meet the boss aslant

  in std.front {
    construction spindle := vertical line(std.origin, hint((0, 10)))
    length(10mm) spindle
  }
  plate := CarrierPlate(z0: z0)
  construction carrier := solid(plate.plate)
  at_sun := Phasing(ring_at: ring_at, k: 0)
  sun_gear := Helical(std.top.origin, z: z0 + stage_zb, rot: at_sun.sun, N: sun_n, hand: sun_hand,
                      face: sun_face, bore: sun_bore, shaped: shaped)
  construction sun := solid(sun_gear.gear)

  // Every planet and its pin: each turned on its pin against its carrier, then carried round
  // with it, the carrier's rate: the same as riding the carrier's frame, as primer 0.207 has it.
  // Each pin's centre stands `orbit` out at its planet's bearing from the frame's x, where the
  // carrier's arm is drawn to it.
  in std.top {
    construction datum := line(std.top.origin, hint((10, 0)))
    datum.p2 on_u(d: 10mm) std.top
  }
  orbit_turn := frame
  orbit_turn turns(rate) spindle
  fix(value == roll) orbit_turn
  repeat stack_planets as k {
    ph := Phasing(ring_at: ring_at, k: k)
    pc := point hint((orbit, 0)) in std.top
    construction to_pin := line(std.top.origin, pc) in std.top
    length(orbit) to_pin
    datum angle(ph.bearing) to_pin
    pc_up := point
    pc_up raised(d: 10mm, along: std.z) pc
    construction pc_spindle := line(pc, pc_up)
    pg := Helical(pc, z: z0 + stage_zb, rot: ph.planet, N: planet_n, hand: planet_hand,
                  face: planet_face, bore: planet_bore, shaped: shaped)
    pin := Post(pc, r: pin_d / 2, z0: z0 + plate_t - pin_seat,
                z1: z0 + plate_t - pin_seat + pin_len)
    spin := frame
    spin turns(-rate * ring_teeth / planet_n) pc_spindle
    fix(value == roll) spin
    construction spun := pg.gear at spin
    planet_shown := spun at orbit_turn
    pin_shown := pin.body at orbit_turn
  }
}

// == The ring ====================================================================================
// The ring's teeth: the internal gear of `ring_teeth` the stages' planets run in, about the axis.
// Its teeth climb right-handed (`planet_hand`), a turn a lead; on the plane a machine names its
// teeth's datum (`level`: square to the axis, its origin on it, its axes the frame's) a tooth
// space's middle stands on +v, so `z` over it the teeth stand `z * ring_twist` round from there,
// which `PlanetaryStage` is told as `ring_at`.
//
// An internal gear's tooth space is the tooth of an external gear of its count, module and helix:
// its flanks are involutes of the same base circle, curving away from the space's middle.  So one
// space is drawn in the transverse plane as that tooth stands (`thin` thicker, so the ring's teeth
// come out `thin` thinner), and swept up a screw about the axis of the teeth's lead: the screw's
// sweep of the section, exactly.  Each flank is the arc through three points of its involute, from
// a print's clearance inside the teeth's tips to their root, within 4 µm of it; the right flank is
// the left mirrored in the space's middle.  The space is turned a pitch at a time round the axis
// for the rest (`BarrelTeeth`).
//
// Two workarounds for solventc v0.1.14, each to undo when geomsolver fixes it:
//   - the spaces are drawn rather than cut by a 55-tooth helical gear, since a body cut by sweeps
//     cannot itself be cut from another (bmander/geomsolver#818);
//   - v0.1.14 sweeps a section up a screw only as a face family over a parameter the document
//     declares, at its top: `ToothSpace` is that face, and the document that draws the ring
//     sweeps it, `solid({ p | some s: p in ToothSpace(level, …, s: s).section at s })`, and
//     hands the space to what cuts it.  Run z0 and z1 past the body's other faces (a millimetre
//     into a floor, half a millimetre over the top): flush, v0.1.14 leaves a sliver on the bore's
//     rim, which the STL refuses (bmander/geomsolver#821, #836).

// One tooth space's section, drawn on `level` about its normal, carried up the screw from `z0` to
// `z1` over it as `s` runs from 0 to 1.
component ToothSpace(level: plane, z0: Length, z1: Length, s: Scalar) {
  claim planet_hand == 1          // the screw below climbs right-handed
  r_in := ring_tip_r - gap
  r_mid := (r_in + ring_root_r) / 2
  f_in := Flank(r: r_in)
  f_mid := Flank(r: r_mid)
  f_root := Flank(r: ring_root_r)
  screw := frame
  screw screws(ring_lead) level.normal
  fix(value == 360deg * (z0 + (z1 - z0) * s) / ring_lead) screw
  in screw {
    in level {
      // the space's middle, up +v
      construction middle := line(level.origin, hint((0, 10)))
      middle.p2 on_v(d: 10mm) level
      // the left flank's three points, each at its radius and `th` round from the middle (seeded
      // a small angle's run off it)
      li := point hint((-r_in * f_in.th / 1rad, r_in))
      lm := point hint((-r_mid * f_mid.th / 1rad, r_mid))
      lr := point hint((-ring_root_r * f_root.th / 1rad, ring_root_r))
      construction to_li := line(level.origin, li)
      construction to_lm := line(level.origin, lm)
      construction to_lr := line(level.origin, lr)
      length(r_in) to_li
      length(r_mid) to_lm
      length(ring_root_r) to_lr
      middle angle(f_in.th) to_li
      middle angle(f_mid.th) to_lm
      middle angle(f_root.th) to_lr
      // the right flank's, mirrored
      ri := point hint((r_in * f_in.th / 1rad, r_in))
      rm := point hint((r_mid * f_mid.th / 1rad, r_mid))
      rr := point hint((ring_root_r * f_root.th / 1rad, ring_root_r))
      ri symmetry(middle) li
      rm symmetry(middle) lm
      rr symmetry(middle) lr
      // each flank bulges away from the space's middle, its centre across the middle from it,
      // about 8.7 mm off: seeded 19deg round on the far side, 22.6 mm out
      flank_l := arc(center: hint((7.4, 21.4)), start: lr, end: li)
      lm coincident flank_l
      flank_r := arc(center: hint((-7.4, 21.4)), start: ri, end: rr)
      rm coincident flank_r
      root_arc := arc(center: hint((0, 0)), start: rr, end: lr)
      radius(ring_root_r) root_arc
      inner_edge := line(ri, li)
    }
    section := face(flank_l, root_arc, flank_r, inner_edge)
  }
}

// The ring's teeth cut from `body`, about the frame's z: `space`, one tooth space swept
// (`ToothSpace`), and it turned a pitch at a time for the rest.
component BarrelTeeth(body: solid, space: solid) {
  in std.front {
    construction spindle := vertical line(std.origin, hint((0, 10)))
    length(10mm) spindle
  }
  index := frame
  index turns(1) spindle
  space cut body
  repeat ring_teeth - 1 as j {
    turned := space at(under: index) ((j + 1) * 360deg / ring_teeth)
    turned cut body
  }
}

preview {
  param teeth_s: Scalar over (0, 1)
  stage := PlanetaryStage(z0: 0mm, ring_at: stage_zb * ring_twist, roll: 0deg, rate: 1,
                          sun_bore: 1.88mm, shaped: 1)
  rim := Post(std.top.origin, r: ring_root_r + wall, z0: 0mm, z1: stage_h)
  bore := Post(std.top.origin, r: ring_tip_r, z0: -1mm, z1: stage_h + 1mm)
  barrel := solid(rim.body)
  bore.body cut barrel
  space := solid({ p | some teeth_s: p in ToothSpace(std.top, z0: -1.5mm, z1: stage_h + 0.5mm, s: teeth_s).section at teeth_s })
  teeth := BarrelTeeth(barrel, space: space)
}
