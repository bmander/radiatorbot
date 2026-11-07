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
use std.place (vertical, on_u, raised, seats)
use std.motion (turns)
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

// == The stage ===================================================================================

// One planetary stage at rest, and its planets turning, drawn up the frame's z from its carrier's
// underside at `z0` (a number, not a seat: drawn in the frame of what holds it, it gives the solve
// no frame of its own to place, which keeps the bot's check quick).  Its carrier turns
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
// Its teeth climb right-handed (`planet_hand`), a turn a lead; at the frame's z = 0 a tooth
// space's middle stands on +v, so at a height `z` the teeth stand `z * ring_twist` round from
// there, which `PlanetaryStage` is told as `ring_at`.
//
// An internal gear's tooth space is the tooth of an external gear of its count, module and helix,
// the same hand: its flanks are involute helicoids of the same base circle.  So the ring is cut by
// that gear, rack-cut as every other gear here (gears.sv): its addendum the ring's dedendum, so
// its tips reach the ring's roots, and its teeth `thin` fatter, so the ring's come out `thin`
// thinner.  A tooth of it stands on +v at z = 0, half a pitch back from where its own cut space
// stands.  Its blank is a ring of its own inside the bore, so it cuts nothing but the spaces.
// `shaped` 0 cuts its blank instead: the ring's bore out to its teeth's roots, for a quick look.
component BarrelTeeth(body: solid, z0: Length, z1: Length, shaped: Int) {
  cutter := ShapedHelical(N: ring_teeth, m: m_stack, phi: pa, beta: helix, hand: planet_hand,
                          shift: 0, add: 1.25, thin: -thin, z0: z0, z1: z1,
                          bore: 2 * (ring_tip_r - 2mm), shaped: shaped, chamfer: 0mm)
  cutter seats(turn: -180deg / ring_teeth, up: std.z, east: std.x) std.origin
  cutter.gear cut body
}

preview {
  stage := PlanetaryStage(z0: 0mm, ring_at: stage_zb * ring_twist, roll: 0deg, rate: 1,
                          sun_bore: 1.88mm, shaped: 1)
  rim := Post(std.top.origin, r: ring_root_r + wall, z0: 0mm, z1: stage_h + 1mm)
  bore := Post(std.top.origin, r: ring_tip_r, z0: -1mm, z1: stage_h + 2mm)
  barrel := solid(rim.body)
  bore.body cut barrel
  teeth := BarrelTeeth(barrel, z0: -0.5mm, z1: stage_h + 1.5mm, shaped: 1)
}
