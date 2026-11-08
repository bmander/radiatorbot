// The geared motor, as a module: a 130 motor on a stack of three helical planetary stages
// (planetary.sv), one unit that runs on the bench, with an output shaft out of its foot.  A
// machine that uses it draws `GearedMotor`, seats it where its foot stands, mounts it on
// `Footprint`'s posts, and fixes what it drives to the output shaft: a part on the shaft is cut by
// `out_socket`, pressed onto the shaft's flat and screwed up into the shaft's end.
//
// Drawn about its own origin: P, the motor's axis, is std.z, and z = 0 is the unit's foot, the
// underside of the gearcase's floor.  From the foot up:
//   - the **gearcase**, one print, a cup: a floor the output shaft turns in, and the barrel up from
//     it, its bore the 55 internal teeth every stage's planets run in, and three ribs down its
//     outside, each with an M3's self-tapping hole down from its top and another up from its foot;
//   - the **output shaft**, a steel shaft up P with a flat milled up one side from its foot, the
//     stack's axle and its output in one;
//   - the **stages**, each a carrier on the output shaft and three planets on pins in it: the
//     motor's sun on its shaft at the top, and under each carrier's plate the next stage's sun,
//     printed as one with it.  The last carrier has a hub under its plate instead, down through
//     the floor's bore, and is pressed onto the shaft's flat; the carriers above turn on the shaft
//     where it is round;
//   - the **unit's lid**, one print, over the gearcase's top: the motor's pad and cradle on it,
//     and an ear over each rib, a countersunk M3 down through each into the rib.  A spigot under
//     it presses down into the barrel's bore, onto its teeth's tips, so the lid, the motor and the
//     first sun stand concentric with the ring;
//   - the motor, face down on its pad, its boss pressed into a recess in it, its shaft down
//     through the pad and the lid to the first sun, pressed on it.  It stands in a cradle of its
//     own section grown by a wall, a print's clearance inside: the flats key it against its
//     torque, and a strap across its end bell holds it down on the pad, screwed into two ears up
//     from the cradle's flat walls.
// The output shaft is a print's clearance up and down in the floor: the last carrier's plate over
// the floor's top, and the part screwed to the shaft under its underside, against the hub's end.

unit mm
use std
use std.solids (cut, union)
use std.place (vertical, coords, on_u, on_v, raised, seats)
use std.motion (turns)
use motor130 (Motor130, MotorCan, MotorSizes, motor130_dims)
use fits (run, press, gap, bond, wall, snug, pilot, m3_clear, m3_head_d, m3_head_h)
use parts (Post, Block, Countersink)
use planetary (PlanetaryStage, BarrelTeeth, stage_ratio, stage_h, stage_zb, plate_t)
use planetary (planet_face, sun_tip_r)
use planetary (ring_twist, ring_tip_r, ring_root_r, p_rod_d, p_bore)

// == Heights, from the foot up P =================================================================
// The floor, then each stage a carrier's plate, its planets and a print's clearance (stage_h),
// the barrel's teeth up past the first stage's planets and on up past the lid's spigot, which
// stands a print's clearance over them, and the lid on the barrel's top.  The motor stands on the
// lid on a pad, its shaft down through it to the first sun and on into the first carrier's bore,
// over the top of the output shaft.
case_floor := 4mm               // the gearcase's floor, the output shaft's bearing
c3_z0 := case_floor + gap       // the last carrier's plate, a print's clearance over the floor
c2_z0 := c3_z0 + stage_h
c1_z0 := c2_z0 + stage_h
zb3 := c3_z0 + stage_zb         // each stage's planets' undersides, and its sun's
zb2 := c2_z0 + stage_zb
zb1 := c1_z0 + stage_zb
spigot_z0 := zb1 + planet_face + gap
spigot_h := 2.5mm               // the lid's spigot, down into the barrel's bore
unit_lid_z0 := spigot_z0 + spigot_h
unit_lid_z1 := unit_lid_z0 + 3mm
unit_motor_z := unit_lid_z1 + 2.8mm                         // the motor's front face, on its pad
unit_strap_top := unit_motor_z + motor130_dims.len + wall
p_rod_z1 := unit_motor_z - motor130_dims.shaft_len - 1mm    // the output shaft's top, a
                                                            // millimetre under the motor's shaft

// == The output shaft ============================================================================
// A steel shaft `p_rod_d` across (planetary.sv), cut to length and milled: one flat `out_flat`
// deep up its +x side from its foot to the last carrier's top, ended square there, and an M3
// tapped up into its foot.  The last carrier is pressed onto the flat: its plate, and a hub under
// the plate down through the floor's bore, the floor its bearing, to the hub's end a print's
// clearance under the foot (the shoulder).  The flat's square end stands on the carrier's top, so
// the shaft can't drop through it.  Over the carrier the shaft is round, and the carriers above
// turn on it.  Under the shoulder the flat runs `out_engage` on down: the part the shaft drives is
// pressed onto it, and drawn up against the hub's end by the M3, which draws the shaft's flat end
// down onto the carrier in turn, so the carrier, the shaft and the part are one.
out_flat := 1mm                 // the flat's depth: 5 mm from it across to the far side
out_hub_d := 11mm               // the last carrier's hub, through the floor
out_z := -gap                   // the shoulder: the hub's end
out_engage := 5mm               // the flat, on down from the shoulder into the part it drives
out_foot := out_z - out_engage  // the shaft's foot
out_flat_z1 := c3_z0 + plate_t  // the flat's square end: the last carrier's top
out_tap := 8mm                  // the M3's hole up into the foot, drilled 2.5 mm and tapped
// The barrel's teeth, from the last carrier's underside to half a millimetre over the barrel's
// top (planetary.sv), their datum the foot: a tooth space's middle on the unit's +y there.
teeth_z0 := c3_z0
teeth_z1 := unit_lid_z0 + 0.5mm

// == The lid's registration =======================================================================
// The spigot is a ring pressed into the barrel's bore, `snug` all round inside its teeth's tips: a
// light press, which centres the lid on the ring gear the stages run in.  Its middle is open round
// the motor's sun, whose top stands up into it.
spigot_r := ring_tip_r - snug
spigot_in := sun_tip_r + 1mm                                 // a millimetre round the sun's tips

// == The gearcase and the strap ==================================================================
// The barrel a wall round the teeth's roots; three ribs down its outside, one way of the unit's
// own x, and the screws through them.
unit_barrel_r := ring_root_r + wall
rib_r := 3.2mm
// the ribs' axes, off P: their insides a print's clearance past the teeth's roots
rib_c := ring_root_r + gap + rib_r
rib_bearings := [100deg, 220deg, 300deg]
rib_pilot := 8mm                // each rib's hole up from its foot
// The motor's strap: a bar `wall` thick across the end bell's back, its boss up through it, and a
// leg down each side past the flats onto an ear up from the cradle's flat wall, where a
// countersunk M3 draws it down.  The ears stand `strap_lift` short of the legs, so the strap
// always bears on the end bell, never on them.  The ears swell out from the cradle's flats to
// `ear_t` over a 45deg underside that starts at a height the machine round the unit chooses.
strap_h := 6mm                  // the legs, from the strap's top down
strap_w := 8mm                  // across the flats' middle, clear of the round sides' terminals
strap_lift := 0.5mm
ear_t := 6mm                    // the ears, out from the cradle's pocket
ear_z1 := unit_strap_top - strap_h - strap_lift
cradle_f := motor130_dims.flats / 2 + wall + gap            // the cradle's flats, off P
strap_reach := motor130_dims.flats / 2 + gap + ear_t        // the ears' outer faces, off P

// == Building blocks =============================================================================

// One of the ears the motor's strap is screwed down to, drawn in the motor's frame (its front face
// on std.top, its axis std.z), on the flat at `side` (1, +y; -1, -y): a slab `strap_w` across the
// flat's middle, from the cradle's pocket out to `ear_t`, from z0 to z1.  Below the cradle's top it
// swells out of the cradle's wall over a 45deg underside, so it prints off the wall.
component Ear(s: MotorSizes, side: Int, z0: Length, z1: Length) {
  yi := side * (s.flats / 2 + gap)
  yc := side * (s.flats / 2 + gap + wall)
  yo := side * (s.flats / 2 + gap + ear_t)
  in std.side {
    a := point hint((yi, z0))
    a coords(du: yi, dv: z0) std.side
    b := point hint((yc, z0))
    b coords(du: yc, dv: z0) std.side
    c := point hint((yo, z0 + ear_t - wall))
    c coords(du: yo, dv: z0 + ear_t - wall) std.side
    d := point hint((yo, z1))
    d coords(du: yo, dv: z1) std.side
    e := point hint((yi, z1))
    e coords(du: yi, dv: z1) std.side
  }
  body := solid(std.solids.Prism(face(a, b, c, d, e, -> close), from: -strap_w / 2,
                                 to: strap_w / 2))
}

// Both ears, and the M3's self-tapping hole down into each from its top, on the motor's y.
component StrapEars(s: MotorSizes, z0: Length, z1: Length) {
  screw_y := s.flats / 2 + gap + ear_t / 2
  plus := Ear(s, side: 1, z0: z0, z1: z1)
  minus := Ear(s, side: -1, z0: z0, z1: z1)
  in std.top {
    at_plus := point hint((0, screw_y))
    at_plus on_v(d: screw_y) std.top
    at_minus := point hint((0, -screw_y))
    at_minus on_v(d: -screw_y) std.top
  }
  hole_plus := Post(at_plus, r: pilot / 2, z0: z1 - 8mm, z1: z1 + 1mm)
  hole_minus := Post(at_minus, r: pilot / 2, z0: z1 - 8mm, z1: z1 + 1mm)
  body := solid(plus.body)
  minus.body union body
  holes := solid(hole_plus.body)
  hole_minus.body union holes
}

// The motor's strap, drawn with its top face on std.top and its material under it, the motor's
// axis std.z: a bar `wall` thick over the end bell, its boss up through a hole in it in a ring 2 mm
// wide (the bar is narrower than the boss), and its legs `strap_h` down past the flats, the can's
// section grown a print's clearance between them; an M3 through each leg, countersunk flush (a
// flat head 6 mm across, 90deg).  It prints on its top.
component MotorStrap(s: MotorSizes) {
  y1 := s.flats / 2 + gap + ear_t
  screw_y := s.flats / 2 + gap + ear_t / 2
  bar := Block(x0: -strap_w / 2, x1: strap_w / 2, y0: -y1, y1: y1, z0: -strap_h, z1: 0mm)
  ring := Post(std.top.origin, r: s.back_d / 2 + gap + 2mm, z0: -wall, z1: 0mm)
  pocket := MotorCan(s, grow: gap, z0: -strap_h - 1mm, z1: -wall)
  boss := Post(std.top.origin, r: s.back_d / 2 + gap, z0: -wall - 1mm, z1: 1mm)
  in std.top {
    at_plus := point hint((0, screw_y))
    at_plus on_v(d: screw_y) std.top
    at_minus := point hint((0, -screw_y))
    at_minus on_v(d: -screw_y) std.top
  }
  hole_plus := Post(at_plus, r: m3_clear / 2, z0: -strap_h - 1mm, z1: 1mm)
  hole_minus := Post(at_minus, r: m3_clear / 2, z0: -strap_h - 1mm, z1: 1mm)
  sink_plus := Countersink()
  sink_plus seats(turn: 0deg, up: std.z, east: std.x) at_plus
  sink_minus := Countersink()
  sink_minus seats(turn: 0deg, up: std.z, east: std.x) at_minus
  part := solid(bar.body)
  ring.body union part
  pocket.body cut part
  boss.body cut part
  hole_plus.body cut part
  hole_minus.body cut part
  sink_plus.cone cut part
  sink_minus.cone cut part
}

// A rib down the gearcase's outside, `rib_c` out along the frame's x: the rib from the foot to the
// lid, an M3's self-tapping hole down from its top and another up from its foot, and over it the
// lid's ear, the hole through it and the screw's countersink.  The gearcase seats one at each of
// `rib_bearings`.
component Rib() {
  in std.top {
    c := point hint((rib_c, 0))
    c on_u(d: rib_c) std.top
  }
  post := Post(c, r: rib_r, z0: 0mm, z1: unit_lid_z0)
  top_hole := Post(c, r: pilot / 2, z0: unit_lid_z0 - 10mm, z1: unit_lid_z0 + 1mm)
  foot_hole := Post(c, r: pilot / 2, z0: -1mm, z1: rib_pilot)
  ear := Post(c, r: rib_r, z0: unit_lid_z0, z1: unit_lid_z1)
  ear_hole := Post(c, r: m3_clear / 2, z0: unit_lid_z0 - 1mm, z1: unit_lid_z1 + 1mm)
  sink_at := point
  sink_at raised(d: unit_lid_z1, along: std.z) c
  sink := Countersink()
  sink seats(turn: 0deg, up: std.z, east: std.x) sink_at
}

// The hole a print is pressed onto the output shaft's flat by, about the frame's z from z0 to z1:
// the shaft's section, at rest, `press` over it across and at the flat.
component DHole(z0: Length, z1: Length) {
  bore := Post(std.top.origin, r: (p_rod_d + press) / 2, z0: z0, z1: z1)
  key := Block(x0: p_rod_d / 2 - out_flat + press / 2, x1: p_rod_d / 2 + 1mm,
               y0: -p_rod_d / 2 - 1mm, y1: p_rod_d / 2 + 1mm, z0: z0 - 1mm, z1: z1 + 1mm)
  body := solid(bore.body)
  key.body cut body
}

// == The mounting ================================================================================

// One of the posts the unit stands on, under a rib, drawn as `Rib` is: from `depth` under the foot
// up to it, and the M3 up through the floor under it (`floor_t` thick) and the post into the rib's
// foot, its pan head in a counterbore in the floor's underside.
component Foot(depth: Length, floor_t: Length) {
  in std.top {
    c := point hint((rib_c, 0))
    c on_u(d: rib_c) std.top
  }
  post := Post(c, r: rib_r, z0: -depth, z1: 0mm)
  hole := Post(c, r: m3_clear / 2, z0: -depth - floor_t - 1mm, z1: 1mm)
  head := Post(c, r: m3_head_d / 2 + gap, z0: -depth - floor_t - 1mm,
               z1: -depth - floor_t + m3_head_h + 0.5mm)
}

// What a machine gives the unit to stand on, seated where the unit is: a post under each rib,
// `depth` tall, on a floor `floor_t` thick (`posts`), and the screws' holes up through both
// (`holes`).
component Footprint(depth: Length, floor_t: Length) {
  posts := solid()
  holes := solid()
  repeat b in rib_bearings {
    foot := Foot(depth: depth, floor_t: floor_t)
    foot seats(turn: b, up: std.z, east: std.x) std.origin
    foot.post.body union posts
    foot.hole.body union holes
    foot.head.body union holes
  }
}

// == The unit ====================================================================================

// The geared motor at rest, and turning: its output shaft and the last carrier on it turn
// `out_rate` turns a turn of `roll` about the frame's z, each carrier above it and the motor
// `stage_ratio` faster, the same way.  The strap's ears start to swell out of the cradle's flats
// at `ear_z0`.  A part on the output shaft is `hub_len` long, from the shoulder down; `out_socket`
// is what it is cut by.  `shaped` 0 draws the gears as blanks; `checks` 1 judges every clearance
// inside.
//
// The printed parts, at rest: `gearcase` (`case_blank` and its teeth), `lid`, `strap_part`,
// `motor_sun`, `carrier1` (the first carrier and the second sun), `carrier2` (the second and the
// third sun), `carrier3` (the last carrier and its hub) and `planet`, one of the nine; and the
// steel output shaft, `shaft`.  `carrier_1` … `sun_1` and `out_shaft` are the carriers, the
// motor's sun and the shaft turning.
component GearedMotor(roll: Angle, out_rate: Scalar, ear_z0: Length, hub_len: Length,
                      shaped: Int, checks: Int) {
  claim p_rod_z1 >= zb2 + 4mm     // the first carrier turns on 4 mm of the shaft, or more
  claim unit_motor_z - motor130_dims.shaft_len >= zb2 + 4mm      // the shaft's end in it
  claim unit_motor_z - motor130_dims.boss_h - gap >= unit_lid_z0 + 1mm   // a floor under its boss
  claim hub_len >= out_engage + 0.5mm + 1.5mm + m3_head_h + 0.5mm   // a ledge under the shaft
  claim (out_hub_d - p_rod_d) / 2 >= wall                           // the hub's wall

  in std.front {
    construction spindle := vertical line(std.origin, hint((0, 10)))
    length(10mm) spindle
  }
  c2_rate := out_rate * stage_ratio
  c1_rate := c2_rate * stage_ratio
  motor_rate := c1_rate * stage_ratio
  sun_bore := motor130_dims.shaft_d - 0.1mm      // every sun is one figure, pressed on the shaft

  // The stages, each from its carrier's underside, and told how the barrel's teeth stand at its
  // planets' undersides.
  st1 := PlanetaryStage(z0: c1_z0, ring_at: zb1 * ring_twist, roll: roll, rate: c1_rate,
                        sun_bore: sun_bore, shaped: shaped)
  st2 := PlanetaryStage(z0: c2_z0, ring_at: zb2 * ring_twist, roll: roll, rate: c2_rate,
                        sun_bore: sun_bore, shaped: shaped)
  st3 := PlanetaryStage(z0: c3_z0, ring_at: zb3 * ring_twist, roll: roll, rate: out_rate,
                        sun_bore: sun_bore, shaped: shaped)

  // The prints the stages make: the motor's sun; each carrier with the next stage's sun under it,
  // the carrier's bore down through both; the last with its hub, and the shaft's flat through
  // both.
  construction motor_sun := solid(st1.sun)
  construction carrier1 := solid(st1.carrier)
  st2.sun union carrier1
  bore1 := Post(std.top.origin, r: p_bore / 2, z0: c1_z0 - 10.5mm, z1: c1_z0 + plate_t + 1mm)
  bore1.body cut carrier1
  construction carrier2 := solid(st2.carrier)
  st3.sun union carrier2
  bore2 := Post(std.top.origin, r: p_bore / 2, z0: c2_z0 - 10.5mm, z1: c2_z0 + plate_t + 1mm)
  bore2.body cut carrier2
  construction carrier3 := solid(st3.carrier)
  hub := Post(std.top.origin, r: out_hub_d / 2, z0: out_z, z1: c3_z0 + bond)
  c3_hole := DHole(z0: out_z - 1mm, z1: out_flat_z1 + 1mm)
  hub.body union carrier3
  c3_hole.body cut carrier3
  construction planet := solid(st3.pg[0].gear)       // the part printed nine times

  // The output shaft, at rest: round from its foot to its top, less its flat and its foot's hole.
  shaft_round := Post(std.top.origin, r: p_rod_d / 2, z0: out_foot, z1: p_rod_z1)
  shaft_flat := Block(x0: p_rod_d / 2 - out_flat, x1: p_rod_d / 2 + 1mm, y0: -p_rod_d / 2 - 1mm,
                      y1: p_rod_d / 2 + 1mm, z0: out_foot - 1mm, z1: out_flat_z1)
  shaft_tap := Post(std.top.origin, r: pilot / 2, z0: out_foot - 1mm, z1: out_foot + out_tap)
  construction shaft := solid(shaft_round.body)
  shaft_flat.body cut shaft
  shaft_tap.body cut shaft

  // What a part on the output shaft is cut by: the shaft's section, a press, half a millimetre
  // past its foot; the screw's clearance on down through the part; and its pan head's
  // counterbore up into the part's underside.
  socket_d := DHole(z0: out_foot - 0.5mm, z1: out_z + 1mm)
  socket_screw := Post(std.top.origin, r: m3_clear / 2, z0: out_z - hub_len - 1mm, z1: out_z)
  socket_head := Post(std.top.origin, r: m3_head_d / 2 + gap, z0: out_z - hub_len - 1mm,
                      z1: out_z - hub_len + m3_head_h + 0.5mm)
  construction out_socket := solid(socket_d.body)
  socket_screw.body union out_socket
  socket_head.body union out_socket

  // The motor, its cradle and its strap's ears.
  motor_at := point
  motor_at raised(d: unit_motor_z, along: std.z) std.origin
  motor := Motor130(motor130_dims)
  motor seats(turn: 0deg, up: std.z, east: std.x) motor_at
  cradle_out := MotorCan(motor130_dims, grow: wall + gap, z0: unit_lid_z1 - 1mm - unit_motor_z,
                         z1: 18mm)
  cradle_out seats(turn: 0deg, up: std.z, east: std.x) motor_at
  cradle_in := MotorCan(motor130_dims, grow: gap, z0: 0mm, z1: 19mm)
  cradle_in seats(turn: 0deg, up: std.z, east: std.x) motor_at
  cradle := solid(cradle_out.body)
  cradle_in.body cut cradle
  ears := StrapEars(motor130_dims, z0: ear_z0 - unit_motor_z, z1: ear_z1 - unit_motor_z)
  ears seats(turn: 0deg, up: std.z, east: std.x) motor_at
  ears.body union cradle
  ears.holes cut cradle

  strap_at := point
  strap_at raised(d: unit_strap_top, along: std.z) std.origin
  strap := MotorStrap(motor130_dims)
  strap seats(turn: 0deg, up: std.z, east: std.x) strap_at
  strap_part := solid(strap.part)
  claim strap_part clear(0.4mm) cradle      // its legs short of the ears: it bears on the motor

  // The gearcase: the barrel and its floor, its bore the teeth's tips from the floor up past them
  // to the lid, the last carrier's hub's bore through the floor, and the ribs.
  barrel := Post(std.top.origin, r: unit_barrel_r, z0: 0mm, z1: unit_lid_z0)
  barrel_bore := Post(std.top.origin, r: ring_tip_r, z0: case_floor, z1: unit_lid_z0 + 1mm)
  out_bore := Post(std.top.origin, r: (out_hub_d + run) / 2, z0: -1mm, z1: case_floor + 1mm)
  // `case_blank` is the gearcase but for its teeth: what a machine round the unit judges its
  // clearance against, without building the teeth.
  construction case_blank := solid(barrel.body)
  barrel_bore.body cut case_blank
  out_bore.body cut case_blank
  gearcase := solid(case_blank)
  teeth := BarrelTeeth(gearcase, z0: teeth_z0, z1: teeth_z1, shaped: shaped)

  // The unit's lid: a disc over the gearcase's top, its spigot down into the barrel's bore, an
  // ear over each rib, the motor's pad and cradle on it, and its boss's recess (a light press)
  // and its shaft's hole through it.
  lid_disc := Post(std.top.origin, r: unit_barrel_r, z0: unit_lid_z0, z1: unit_lid_z1)
  in std.top {
    spigot_rim := radius(spigot_r) circle(center: std.top.origin)
    spigot_bore := radius(spigot_in) circle(center: std.top.origin)
  }
  spigot := solid(std.solids.Prism(face(spigot_rim, holes: spigot_bore), from: spigot_z0,
                                   to: unit_lid_z0 + bond))
  motor_boss_room := Post(std.top.origin, r: motor130_dims.boss_d / 2 + snug,
                          z0: unit_motor_z - motor130_dims.boss_h - gap, z1: unit_motor_z + 1mm)
  motor_shaft_room := Post(std.top.origin, r: 2.5mm, z0: unit_lid_z0 - 1mm, z1: unit_motor_z)
  lid := solid(lid_disc.body)
  spigot union lid
  cradle union lid
  motor_boss_room.body cut lid
  motor_shaft_room.body cut lid

  repeat b in rib_bearings {
    rib := Rib()
    rib seats(turn: b, up: std.z, east: std.x) std.origin
    rib.post.body union case_blank
    rib.top_hole.body cut case_blank
    rib.foot_hole.body cut case_blank
    rib.ear.body union lid
    rib.ear_hole.body cut lid
    rib.sink.cone cut lid
  }

  // The train turning, each joint held to `roll` itself.
  c3_turn := frame
  c3_turn turns(out_rate) spindle
  fix(value == roll) c3_turn
  c2_turn := frame
  c2_turn turns(c2_rate) spindle
  fix(value == roll) c2_turn
  c1_turn := frame
  c1_turn turns(c1_rate) spindle
  fix(value == roll) c1_turn
  motor_turn := frame
  motor_turn turns(motor_rate) spindle
  fix(value == roll) motor_turn
  carrier_3 := carrier3 at c3_turn
  out_shaft := shaft at c3_turn
  carrier_2 := carrier2 at c2_turn
  carrier_1 := carrier1 at c1_turn
  sun_1 := motor_sun at motor_turn

  // With `checks` 1, every clearance inside the unit.  Gears in mesh run 0.15 mm clear a flank;
  // the motor rests on its pad and under its strap, and the lid on the gearcase.
  when checks == 1 {
    claim carrier_3 clear(0.15mm) gearcase                // its hub in the floor's bore
    claim out_shaft clear(0.15mm) carrier_2               // the carriers turning on the shaft
    claim out_shaft clear(0.15mm) carrier_1
    claim out_shaft clear(0.15mm) gearcase
    claim carrier_3 clear(0.2mm) carrier_2
    claim carrier_2 clear(0.2mm) carrier_1
    claim carrier_1 clear(0.2mm) sun_1
    claim carrier_2 clear(0.2mm) gearcase
    claim carrier_1 clear(0.2mm) gearcase
    claim sun_1 clear(0.2mm) gearcase
    claim sun_1 clear(0.2mm) lid                         // in the spigot's middle
    claim carrier_1 clear(0.5mm) motor.motor               // the shaft's end, in its bore
    claim planet clear(0.2mm) carrier3                    // on its carrier's plate
    claim planet clear(0.05mm) carrier2                   // in mesh with its sun
    claim st1.pg[0].gear clear(0.2mm) lid                 // under the spigot, as every planet is
    repeat 3 as k {
      claim st1.pg[k].gear clear(0.05mm) gearcase         // in mesh with the barrel
      claim st2.pg[k].gear clear(0.05mm) gearcase
      claim st3.pg[k].gear clear(0.05mm) gearcase
    }
  }
}

// The unit on the bench, its output scrubbed through a turn.  A file that uses this one as a
// module draws neither the unit below nor the parameter.
param out_turn: Angle over (0deg, 360deg)
gearmotor := GearedMotor(roll: out_turn, out_rate: 1, ear_z0: unit_lid_z1 + 10mm, hub_len: 10mm,
                         shaped: 1, checks: 0)
