// The radiator bot: a gearmotor that clamps to the valve's supply pipe and turns the star handle
// through a socket round it.
//
// Coordinates are the valve's (radiator_valve.sv): the stem is std.z, z = 0 is the packing nut's
// bottom face, the radiator lies toward +x.  The bot is laid out in a frame of its own, `bot`,
// turned `bot_turn` (a quarter turn) about the stem, and hangs on that frame's -x side: the
// valve's -y side, beside the outlet, turned 90deg clockwise seen from below from where it hung
// off the outlet's far end.  In the bot's frame:
//
//   - the **socket** is a gear round the handle, turning about the stem with it, its middle the
//     handle's top face's outline straight through: the handle turns it by all four arms at once,
//     and screws down through it as the valve opens.  It turns on a pad on the stem's axis under
//     its floor, at the end of the **stand**, an arm clamped to A, the axle `a_dist` out along -x;
//   - on A, a pinion drives the socket and a 48-tooth ring over it is driven by the **gearbox**
//     above: four printed spur stages on two drill-rod axles, B and D, the 130 motor's pinion
//     driving the first; its base's floor stops short of the ring;
//   - the **frame** is the gearbox's lid and the electronics bay standing on it (the motor, and
//     beside it the RedBoard with a perfboard shield on it carrying the motor driver and its
//     current monitor, the cable entries), a dovetail rail up its end wall;
//   - the **mount**, a print of its own snapped and glued onto the rail, is the spine up beside
//     the valve and the **clamp**'s fixed half, a split block round the inlet hex and the supply
//     pipe above it.  The hex takes the handle's reaction torque positively; the bolted cap
//     closes the clamp from +x, the side away from the bot.
//
// Everything is printed but the drill rod the gears turn on, so the fits below are an FDM
// printer's.  Scrub `handle_open`: the handle screws open down its stem, and the socket and the
// train turn with it.  Set `shaped` to 0 to draw every gear and the socket as blanks while the
// layout is worked on (building them all takes a few minutes).  The design table's requirements
// are claims, judged before the solve; `solventc radiatorbot.sv --where handle_stall_torque`
// reads any figure back in its unit.  Set `checks` to 1 to judge every clearance as well, the
// socket against the handle closed, halfway and open (a couple of minutes more).
//
// The file runs from the numbers to the parts: the stock and the fits, the drive, the heights
// and the plan, then the building blocks, then each part in turn, then the clearances.  Every
// size a part is drawn to is named in the tables up top, so a change is made there.
//
// Numbers marked "~" are estimates to check: the motor's figures (motor130.sv).

unit mm
use std
use std.place (vertical, horizontal, coords, seats, raised)
use std.motion (turns)
use std.shapes
use std.rounds
use radiator_valve (RadiatorValve, handle_dims, body_dims, pipe_dims, handle_gap, stem_travel)
use radiator_valve (open_turns)
use radiator_valve (StarOutline, StarHandle, HexBar, RoundBar)
use gears (ShapedSpur)
use motor130 (Motor130, MotorCan, motor130_dims, motor130_free, motor130_stall_torque)
use boards (RedBoardEsp32, Shield, Tb6612, Ina219, redboard_dims, uno_holes, shield_dims)
use boards (tb6612_dims, ina219_dims, header_dims, pitch)

shaped := 1                    // 1: shape the gears and the socket; 0: blanks, for a quick look
checks := 0                    // 1: judge every clearance (needs `shaped`; ~2 minutes)

// == Stock =======================================================================================
// Drill rod.  The gears turn on fixed rods; the housing holds the rods.
axle_d := 0.5in                 // A, the socket pinion's axle
rod_d := 0.311in                // B and D, the gear train's

// == Fits for an FDM print =======================================================================
run := 0.35mm                   // a printed bore turning on drill rod, over the rod
press := 0.05mm                 // a printed hole a rod is pressed into (drill or ream to fit)
gap := 0.3mm                    // between printed faces that meet or pass
thin := 0.15mm                  // each gear's teeth thinned: 0.3 mm backlash a mesh
chamfer := 0.4mm                // each gear's tips chamfered at both faces, 45deg
bond := 0.25mm                  // a compound's pinion run up into its gear, so the two print as one
wall := 2.4mm                   // six 0.4 mm perimeters
pilot := 2.5mm                  // an M3 screw's self-tapping hole in a print
m3_clear := 3.4mm
m4_clear := 4.6mm
m4_nut_af := 7.3mm              // an M4 nut's pocket across the flats
split := 1mm                    // the clamp's halves stand apart this much before the bolts close it
slip := 0.15mm                  // a glued joint's printed faces, apart each side

axle_bore := axle_d + run       // A's compound's bore, and the collars'
rod_bore := rod_d + run         // every compound's bore

// == The drive ===================================================================================

// The socket and the handle.  The socket's hole is the handle's top face's outline grown
// `socket_fit` all round, the same at every height, so the handle turns it 1:1 by its arms' top
// edges, where the draft leaves them widest, wherever its screw has carried it.  A 24-tooth
// pinion on A drives the socket's 64 teeth: the module is what puts A `a_dist` from the stem.
socket_n := 64
a_n := 24
a_dist := 60mm                  // the stem to A
m_socket := 2 * a_dist / (socket_n + a_n)              // 1.364 mm
socket_fit := 0.3mm             // the chrome casting's arms in the printed hole, each side

// The handle as measured stands closed, its top face `handle_gap` under the packing nut;
// opening, its right-hand stem screws it down `stem_travel` (radiator_valve.sv: 7.21 mm over three
// and a half turns, as measured).
top0 := -handle_gap

// The gear train, motor to A.  Stage 1 runs the motor into B; stages 2-4 ping-pong between B and
// D, which stand one centre distance apart (`cd_bd`: 16 + 64 teeth at module 0.8, or 16 + 48 at
// module 1); the last pinion, on D, drives A's ring.  Every pinion is shifted +0.3 against
// undercut and its gear -0.3, so the centre distances stay nominal.
//
// The pinions on the rods have 16 teeth, not 12: a 12-tooth pinion's roots at module 0.8 stand
// inside a bore on 0.311 in rod.  The claim below holds every such pinion to a 1.5 mm wall
// between its roots and its bore.
pa := 20deg
pin_shift := 0.3
m_small := 0.8mm                // stages 1-3: the finest an 0.4 mm nozzle prints well
m_s4 := 1mm                     // stage 4
m_fin := 1.5mm                  // the ring and its pinion
motor_pin_n := 12               // the motor's pinion, pressed on its 2 mm shaft
s1_n := 24                      // stage 1's gear, on B
pin_n := 16                     // stages 2-4's pinions, on the rods
big_n := 64                     // stages 2 and 3's gears
s4_n := 48                      // stage 4's gear, on D
fin_n := 12                     // the last pinion, on D
ring_n := 48
cd_s1 := m_small * (motor_pin_n + s1_n) / 2             // 14.4 mm, the motor to B
cd_bd := m_small * (pin_n + big_n) / 2                  // 32 mm, B to D
cd_fin := m_fin * (fin_n + ring_n) / 2                  // 45 mm, D to A
claim m_s4 * (pin_n + s4_n) / 2 == cd_bd                // stage 4 stands on the same two rods
pin_wall := m_small * (pin_n / 2 + pin_shift - 1.25) - rod_bore / 2   // roots to bore, module 0.8
claim pin_wall >= 1.5mm

// The bearings of the lines of centres, from the bot's +x: B stands `ab_dist` beyond A, where the
// gearbox was laid out round it, and D `cd_bd` from B at `bd_bearing` (69.2deg), which stands it
// `cd_fin` from A, at `da_bearing` (-41.7deg) from D; B to the motor -60deg.  Each the other way
// round is 180deg on.
ab_dist := 45mm
bd_bearing := acos((ab_dist ^ 2 + cd_bd ^ 2 - cd_fin ^ 2) / (2 * ab_dist * cd_bd))
da_bearing := atan2(-cd_bd * sin(bd_bearing), ab_dist - cd_bd * cos(bd_bearing))
bm_bearing := -60deg

gear_ratio := s1_n / motor_pin_n * (big_n / pin_n) ^ 2 * s4_n / pin_n * ring_n / fin_n   // to A
handle_ratio := gear_ratio * socket_n / a_n             // motor turns a handle turn
claim handle_ratio == 1024

// What it does, from the motor's figures: printed spur meshes at ~0.9, and the socket's six of
// them; the handle in the socket is a direct drive.  The current sensing trips well under the
// stall: at the end of the screw the torque the trip allows is what seats the valve.  What the
// design asks of it: a stall well over what an old packed valve takes to turn, and three and a
// half turns of travel inside half a minute unloaded.
drive_eff := 0.9 ^ 6
handle_free_speed := motor130_free / handle_ratio
handle_stall_torque := motor130_stall_torque * handle_ratio * drive_eff
a_stall_torque := handle_stall_torque * a_n / socket_n / 0.9      // what A's pinion carries
claim handle_stall_torque >= 2Nm
claim handle_free_speed >= 6rpm

// How fast each axle's part turns about its upward axis, in turns a turn open of the handle (a
// turn the handle makes about the downward stem): A 64/24, and each compound back up the train by
// its mesh's ratio, reversed, up to the motor's.
a_rate := socket_n / a_n
d2_rate := -a_rate * ring_n / fin_n
b2_rate := -d2_rate * s4_n / pin_n
d1_rate := -b2_rate * big_n / pin_n
b1_rate := -d1_rate * big_n / pin_n
motor_rate := -b1_rate * s1_n / motor_pin_n
claim motor_rate == -handle_ratio

// == Heights =====================================================================================
// From the floor up: the ring and the last pinion, stages 4 to 1, the lid, the electronics bay
// and its cover.  Faces are 5 mm at module 0.8, 6 at module 1 and 10 at module 1.5, with half a
// millimetre between layers.  The motor stands face down on a pad on the lid, its shaft down
// through both to its pinion in stage 1, high enough that the shaft's end stands a millimetre
// over stage 3's gear on B; the boards stand beside it, so the bay is the motor's height.
floor_z0 := -0.1mm              // the base's floor, round B and D only: A's ring turns beside it
floor_z1 := floor_z0 + 3mm
ring_z0 := 3mm                  // the ring's teeth; the web under it runs down to A's pinion
ring_z1 := ring_z0 + 10mm
fin_z0 := ring_z0 + 0.5mm       // the last pinion
s4_z0 := fin_z0 + 10.5mm
s3_z0 := s4_z0 + 6.5mm
s2_z0 := s3_z0 + 5.5mm
s1_z0 := s2_z0 + 5.5mm
lid_z0 := s1_z0 + 5.5mm
lid_z1 := lid_z0 + 3mm
// Under the ring, round the handle: the socket's top a millimetre over the handle's top face
// closed, so the arms' top edges stand in its hole all the way down the travel, and its teeth
// `socket_face` down from there; its floor's top 1.5 mm under the handle's bottom face open, the
// floor thick enough for the pivot's hole up into it.  A's pinion meshes with the teeth, the web
// over it a print's clearance over the socket.
socket_z1 := top0 + 1mm
socket_face := 10mm
socket_floor := top0 - stem_travel - handle_dims.h - 1.5mm
socket_z0 := socket_floor - 4mm
// The socket's pivot: a printed pin up from the stand's pad on the stem's axis, in a blind hole
// up into the floor's middle, loose by `pivot_play` all round so that the handle, not the pin,
// centres the socket; the pin's top half a millimetre short of the hole's, under a 1 mm roof.
pivot_d := 6mm
pivot_h := 2.5mm                // above the pad
pivot_play := 1mm
socket_body_r := m_socket * (socket_n / 2 - 1.25 - pin_shift) - 1mm   // under its teeth's roots
a_pin_z0 := socket_z1 - socket_face + 0.5mm
web_z0 := socket_z1 + gap
// A's axle: a collar over the ring, under the bridge across the base that holds the axle, and
// the stand under A's pinion, its arm a print's clearance under the socket's floor and its pad
// up to it.
collar_h := 6mm
collar_r := axle_d / 2 + 5mm
collar_z0 := ring_z1 + gap
bridge_z0 := collar_z0 + collar_h
bridge_z1 := bridge_z0 + 6mm
stand_z1 := socket_z0 - gap
stand_z0 := stand_z1 - 4mm
// The mount's joint: the frame's rail stands on the lid, its foot on the mount's shelf, which is
// flush with the lid's underside; the snap's finger hangs in the slot's floor, its barb's
// underside 3 mm up the rail, over a lip of it.
rail_z0 := lid_z0 + 3mm
finger_z0 := rail_z0 + 3mm
motor_z := s3_z0 + 5mm + 1mm + motor130_dims.shaft_len  // the motor's front face, on its pad
claim motor_z >= lid_z1
board_z := lid_z1 + 6mm                                 // the RedBoard's underside, on its posts
shield_z := board_z + shield.top                          // the shield's top face
bay_z1 := motor_z + motor130_dims.len + motor130_dims.back_h + 3mm  // room over it for its leads
clamp_z0 := body_dims.inlet_top - body_dims.inlet_h     // the inlet hex's underside
clamp_z1 := clamp_z0 + 31.7mm

// == Plan ========================================================================================
// The housing's outline, the clamp and the spine, in plan (x, y) in the bot's frame: the box the
// base, the lid, the bay and the cover all share.  Its end wall and its -y side stand about
// 2.4 mm off the tips of the 64-tooth gears on B (at x = -105) and on D (30.9 mm up +y); its +y
// side 4.4 mm, for the RedBoard's 2.3 in across the bay.
box_x0 := -136mm
box_x1 := -35mm
box_y0 := -31mm
box_y1 := 64mm
spine_x1 := -21.5mm             // 4 mm off the valve's bulge and collar
spine_w := 28mm
// The mount's joint, on the end wall's outside about the bot's x: a dovetail rail `dove_root`
// across at the wall, its flanks `dove_angle` off square, standing `dove_h` out; the mount's slot
// is it grown `slip` all round.  The snap is a finger in the slot's floor along z, `finger_t`
// thick and `finger_w` across, its free end down, a slit round it and a relief behind it; the
// barb at its foot stands `barb_h` into the slot, square underneath and ramped over, and falls
// into a notch in the rail's face.
dove_h := 5mm
dove_root := 12mm
dove_angle := 15deg
dove_tip := dove_root + 2 * dove_h * tan(dove_angle)
slot_floor := box_x1 + dove_h + slip
finger_t := 1.6mm
finger_w := 6mm
finger_len := 20mm
finger_slit := 0.8mm
finger_relief := 1mm
barb_h := 0.6mm
barb_flat := 1mm
barb_ramp := 3mm
clamp_reach := 26mm             // each half of the clamp, out from the stem
clamp_w := 48mm                 // its side toward the radiator over the outlet's union nut
clamp_bolt_y := 19mm
nut_clear := 2mm                // the clamp's relief round the outlet's union nut
// The clamp's bolts: both rows over the hex's pocket, the lower row a millimetre and a half over
// its top.
clamp_bolt_z0 := body_dims.inlet_top + gap + m4_clear / 2 + 1.5mm
clamp_bolt_z1 := clamp_z1 - 7mm
screw_inset := wall + 2mm       // the base's and the cover's screws, in from the box's outside
// The RedBoard and its shield (boards.sv) stand beside the motor, by the RedBoard's frame, its
// power header's first pin at (board_ox, board_oy): its jack's mouth a millimetre in from the end
// wall's inside face, its edge 2 mm off the motor's cradle's flat.
cradle_f := motor130_dims.flats / 2 + wall + gap        // the cradle's flats, off the motor's axis
board_ox := box_x0 + wall + 1mm - redboard_dims.jack_x0
board_oy := cd_s1 * sin(bm_bearing) + cradle_f + 2mm - redboard_dims.y0
// The breakouts on the shield's grid, each at its pin field's middle, in the RedBoard's frame:
// the driver's two rows in the shield's rows 1 and 7, its outputs' row (columns 7-12) toward the
// motor and its logic's (columns 5-14) toward the current monitor; the current monitor's pins in
// column 9, rows 11-16, its board out toward +x.  Column 9 is the RedBoard's VIN and 25 too, at
// rows 0 and 19.  The motor's terminal stands in column 17, rows 2 and 4, past the driver's +x
// end.
drv_cx := board_ox + 7.5 * pitch
drv_cy := board_oy + 4 * pitch
ina_cx := board_ox + 7 * pitch
ina_cy := board_oy + 13.5 * pitch
// The end wall's windows: the USB-C's axis and the jack's, as the RedBoard places them.
usb_z := board_z + redboard.usb_z
usb_y := board_oy + redboard_dims.usb_y
jack_z := board_z + redboard.jack_axis
jack_y := board_oy + redboard.jack_y

// == Building blocks =============================================================================

// A point in std.top at (x, y).
component At(x: Length, y: Length) {
  in std.top {
    p := point hint((x, y))
    p coords(du: x, dv: y) std.top
  }
}

// A round post about `c` (drawn in std.top) from z0 to z1.
component Post(c: point, r: Length, z0: Length, z1: Length) {
  in std.top {
    rim := radius(r) circle(center: c)
  }
  body := solid(face(rim), from: z0, to: z1)
}

// A screw's post about `c` from z0 to z1, and the hole `depth` down into it from its top: the
// post goes on one part, the hole comes out of it.
component ScrewPost(c: point, r: Length, z0: Length, z1: Length, hole_d: Length, depth: Length) {
  in std.top {
    rim := radius(r) circle(center: c)
    bore := radius(hole_d / 2) circle(center: c)
  }
  post := solid(face(rim), from: z0, to: z1)
  hole := solid(face(bore), from: z1 - depth, to: z1 + 1mm)
}

// A block square to the world: x0..x1, y0..y1, z0..z1.
component Block(x0: Length, x1: Length, y0: Length, y1: Length, z0: Length, z1: Length) {
  in std.top {
    c := point hint(((x0 + x1) / 2, (y0 + y1) / 2))
    c coords(du: (x0 + x1) / 2, dv: (y0 + y1) / 2) std.top
    sq := std.shapes.CenteredRectangle(c, w: x1 - x0, h: y1 - y0)
  }
  body := solid(face(sq.loop), from: z0, to: z1)
}

// A dovetail up z from z0 to z1 about y = 0, standing out along x: `w0` across at x0, `w1` at x1.
component Dovetail(x0: Length, x1: Length, w0: Length, w1: Length, z0: Length, z1: Length) {
  a := At(x: x0, y: -w0 / 2)
  b := At(x: x1, y: -w1 / 2)
  c := At(x: x1, y: w1 / 2)
  d := At(x: x0, y: w0 / 2)
  body := solid(face(a.p, b.p, c.p, d.p, -> close), from: z0, to: z1)
}

// A snap's barb on a face square to x at `x`, `w` across about y = 0: it stands `h` out toward -x,
// square on its underside at `z`, flat for `flat` and then ramped back into the face over `ramp`,
// and runs half a millimetre back into the face to join it.
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
  body := solid(face(a, b, c, d, e, -> close), from: -w / 2, to: w / 2)
}

// A bore along x at (y, z), from x0 to x1; and a nut's hexagonal pocket so.
component BoreX(y: Length, z: Length, d: Length, x0: Length, x1: Length) {
  in std.side {
    c := point hint((y, z))
    c coords(du: y, dv: z) std.side
    rim := radius(d / 2) circle(center: c)
  }
  body := solid(face(rim), from: x0, to: x1)
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

// A printed collar on a rod standing up std.z at (x, y): a ring `r` round a bore `bore` from z0
// to z1, held by an M3 set screw tapped into it from -x at its middle.
component Collar(x: Length, y: Length, r: Length, bore: Length, z0: Length, z1: Length) {
  axis := At(x: x, y: y)
  ring := Post(axis.p, r: r, z0: z0, z1: z1)
  hole := Post(axis.p, r: bore / 2, z0: z0 - 1mm, z1: z1 + 1mm)
  screw := BoreX(y: y, z: (z0 + z1) / 2, d: pilot, x0: x - r - 1mm, x1: x)
  part := solid(ring.body)
  hole.body cut part
  screw.body cut part
}

// A printed gear seated on an axle: its figure (gears.sv) with its origin `z` up the axle from
// `c`, its axis up the world's z.  `bearing` is the line of centres' to the gear it meshes with,
// from the pinion's axle to the gear's, read from the bot's x (`bot_turn` from the world's), and
// `drives` says which this is: 1 for the pinion, which drives, 0 for the gear it drives.  The
// pinion is shifted +pin_shift and stands a tooth on the line of centres; its gear is shifted
// -pin_shift and stands a space on it (the figure's cut space is on +v: a pinion turned `bearing
// - 90deg - 180deg / N`, its gear `bearing + 90deg`).  Gears of one size and face are one figure,
// shaped once.  A large gear is spoked to save material: `spokes` of them, `web` wide, between a
// hub of radius `hub` (clear of the pinion it carries) and a rim `web` thick under its roots;
// 0 spokes, solid.
component Gear(c: point, z: Length, bearing: Angle, drives: Int, N: Int, m: Length, face: Length,
               bore: Length, spokes: Int, hub: Length, web: Length) {
  at := point
  at raised(d: z, along: std.z) c
  g := ShapedSpur(N: N, m: m, phi: pa, shift: (2 * drives - 1) * pin_shift, thin: thin,
                  z0: 0mm, z1: face, bore: bore, shaped: shaped, chamfer: chamfer,
                  spokes: spokes, hub: hub, web: web)
  g seats(turn: bot_turn + bearing + 90deg + drives * (180deg - 180deg / N), up: std.z,
          east: std.x) at
  construction gear := solid(g.gear)
}

// == The valve ===================================================================================

// The handle's turns open, scrubbed: the handle screws down its stem, and the socket and the train
// turn with it.  Keep the drawing free of redundant rows (the report's `implied:` lines): one makes
// this follow take minutes instead of seconds (bmander/geomsolver#591).
param handle_open: Angle over (0deg, open_turns * 360deg)  // closed to open
valve := RadiatorValve(handle_open: handle_open)

// == The bot's frame =============================================================================
// The bot is drawn in a frame of its own, `bot`, turned `bot_turn` about the stem from the
// valve's: every plan number above (the box, the spine, the clamp, the boards' places) is in it,
// its x out from the stem through the clamp's split to the bot's far end at -x, its z the stem's.
// A quarter turn stands the bot on the valve's -y side, beside the outlet rather than off its far
// end: turned 90deg clockwise as seen from below, looking at the handle.  The parts square to the
// bot (`Block`, `BoreX`, `NutX`, `At` and what stands on it, the collars) are called `in bot`;
// the axles' points are drawn in the world's top plane, turned by `bot_turn`, and every part
// seated on them (the gears, the motor, the boards) is turned by it too.
bot_turn := 90deg
bot := frame
fix(origin == (0mm, 0mm, 0mm)) bot
fix(dir == (cos(bot_turn), sin(bot_turn), 0)) bot.u
fix(dir == (-sin(bot_turn), cos(bot_turn), 0)) bot.v

// == The axles ===================================================================================
// A, the socket's pinion's and the ring's, is `a_dist` out along the bot's -x; B is `cd_fin`
// beyond it; D stands `cd_bd` from B and `cd_fin` from A, its last pinion on the ring; the motor's
// axis M is `cd_s1` from B at `bm_bearing`, from the bot's x.
a_r := -a_dist
b_r := -a_dist - ab_dist
in std.top {
  a_c := point hint((a_r * cos(bot_turn), a_r * sin(bot_turn)))
  a_c coords(du: a_r * cos(bot_turn), dv: a_r * sin(bot_turn)) std.top
  b_c := point hint((b_r * cos(bot_turn), b_r * sin(bot_turn)))
  b_c coords(du: b_r * cos(bot_turn), dv: b_r * sin(bot_turn)) std.top
  d_c := point hint((b_r * cos(bot_turn) + cd_bd * cos(bot_turn + bd_bearing),
                     b_r * sin(bot_turn) + cd_bd * sin(bot_turn + bd_bearing)))
  b_c distance(cd_bd) d_c
  m_c := point hint((b_r * cos(bot_turn) + cd_s1 * cos(bot_turn + bm_bearing),
                     b_r * sin(bot_turn) + cd_s1 * sin(bot_turn + bm_bearing)))
  b_c distance(cd_s1) m_c
  construction b_m := line(b_c, m_c)
  construction b_a := line(b_c, a_c)
  a_c distance(cd_fin) d_c
  b_a angle(bm_bearing) b_m
}
// each axle's spindle, a line up it, for the joints that show the train turning
a_up := point
a_up raised(d: 10mm, along: std.z) a_c
b_up := point
b_up raised(d: 10mm, along: std.z) b_c
d_up := point
d_up raised(d: 10mm, along: std.z) d_c
m_up := point
m_up raised(d: 10mm, along: std.z) m_c
construction a_spindle := line(a_c, a_up)
construction b_spindle := line(b_c, b_up)
construction d_spindle := line(d_c, d_up)
construction m_spindle := line(m_c, m_up)

// The rods: A held in the base's bridge and through the lid, down to the stand; B and D in the
// floor and up into the lid's blind holes.
axle_a := Post(a_c, r: axle_d / 2, z0: stand_z0, z1: lid_z1)
rod_at_b := Post(b_c, r: rod_d / 2, z0: floor_z0, z1: lid_z1 - 1mm)
rod_at_d := Post(d_c, r: rod_d / 2, z0: floor_z0, z1: lid_z1 - 1mm)

// == The socket ==================================================================================
// A gear round the handle about the stem, a body under its teeth down to a floor under the
// handle, and through it all the hole the handle turns it by: the star's top face's outline,
// grown `socket_fit` all round, straight from the floor up out of its top.  It is drawn where the
// handle stands closed (`valve.handle_top`), the hole square to the arms there.
socket_gear := Gear(std.top.origin, z: socket_z1 - socket_face, bearing: 0deg, drives: 0,
                    N: socket_n, m: m_socket, face: socket_face, bore: 4mm, spokes: 0, hub: 0mm,
                    web: 0mm)
socket_body := Post(std.top.origin, r: socket_body_r, z0: socket_z0,
                    z1: socket_z1 - socket_face + bond)
socket_star := StarOutline(valve.handle_top, s: handle_dims)
socket_prism := solid(socket_star.outline, from: socket_floor - top0 + socket_fit,
                      to: socket_z1 - top0 + 1mm)
socket_hole := std.rounds.Grown(socket_prism, d: socket_fit)
construction socket_part := solid(socket_gear.gear)
socket_body.body union socket_part
socket_hole.body cut socket_part
pivot_hole := Post(std.top.origin, r: pivot_d / 2 + pivot_play, z0: socket_z0 - 1mm,
                   z1: socket_z0 + pivot_h + 0.5mm)
pivot_hole.body cut socket_part

// == A's compound ================================================================================
// The pinion that drives the socket, the web over it, and the ring the last pinion drives, one
// print, turning on A.
a_pin := Gear(a_c, z: a_pin_z0, bearing: 0deg, drives: 1, N: a_n, m: m_socket,
              face: web_z0 - a_pin_z0 + bond, bore: axle_bore, spokes: 0, hub: 0mm, web: 0mm)
ring_gear := Gear(a_c, z: ring_z0, bearing: da_bearing, drives: 0, N: ring_n, m: m_fin,
                  face: ring_z1 - ring_z0, bore: axle_bore, spokes: 0, hub: 0mm, web: 0mm)
web := Post(a_c, r: 30mm, z0: web_z0, z1: ring_z0 + bond)
a_bore := Post(a_c, r: axle_bore / 2, z0: a_pin_z0 - 1mm, z1: ring_z1 + 1mm)
construction a_part := solid(a_pin.gear)
web.body union a_part
ring_gear.gear union a_part
a_bore.body cut a_part

// A's compound kept on its axle: the collar over it, under the base's bridge, and the stand
// under it.
collar := Collar(x: -a_dist, y: 0mm, r: collar_r, bore: axle_bore, z0: collar_z0,
                 z1: collar_z0 + collar_h) in bot
collar_part := solid(collar.part)

// == The stand ===================================================================================
// A collar on A under its pinion, held on the rod by its M3 set screw, and an arm from it out
// under the socket to a pad on the stem's axis, which the socket's floor turns on, and the pivot's
// pin up from the pad into the floor's hole.  The pin keeps the pad under the socket's middle and
// the socket over the pad; it is loose in its hole, so the socket finds its own centre on the
// handle and the pad only bears it.  With the pin in the hole, the socket points the arm at the
// stem: tighten the set screw then.
stand_collar := Collar(x: -a_dist, y: 0mm, r: collar_r, bore: axle_bore, z0: stand_z0,
                       z1: a_pin_z0 - gap) in bot
stand_arm := Block(x0: -a_dist, x1: 0mm, y0: -6mm, y1: 6mm, z0: stand_z0, z1: stand_z1) in bot
stand_pad := Post(std.top.origin, r: 8mm, z0: stand_z0, z1: socket_z0)
pivot_pin := Post(std.top.origin, r: pivot_d / 2, z0: stand_z1, z1: socket_z0 + pivot_h)
stand_part := solid(stand_collar.part)
stand_arm.body union stand_part
stand_pad.body union stand_part
pivot_pin.body union stand_part
stand_collar.hole.body cut stand_part

// == The gear train ==============================================================================
// Each compound is its gear and its pinion, the pinion run `bond` up into the gear so the two
// print as one part.  Each pinion's face runs from its own layer up into the gear over it.

// stage 1: the motor's pinion, pressed on its shaft, into B's first compound's gear
motor_pin := Gear(m_c, z: s1_z0 + 0.5mm, bearing: bm_bearing + 180deg, drives: 1, N: motor_pin_n,
                  m: m_small, face: 4.75mm, bore: motor130_dims.shaft_d - 0.1mm,
                  spokes: 0, hub: 0mm, web: 0mm)
// B's first compound: stage 1's gear over stage 2's pinion
b1_gear := Gear(b_c, z: s1_z0, bearing: bm_bearing + 180deg, drives: 0, N: s1_n, m: m_small,
                face: 5mm, bore: rod_bore, spokes: 0, hub: 0mm, web: 0mm)
b1_pin := Gear(b_c, z: s2_z0, bearing: bd_bearing, drives: 1, N: pin_n, m: m_small,
               face: s1_z0 - s2_z0 + bond, bore: rod_bore, spokes: 0, hub: 0mm, web: 0mm)
// D's first: stage 2's gear over stage 3's pinion
d1_gear := Gear(d_c, z: s2_z0, bearing: bd_bearing, drives: 0, N: big_n, m: m_small,
                face: 5mm, bore: rod_bore, spokes: 5, hub: 9mm, web: 2.4mm)
d1_pin := Gear(d_c, z: s3_z0, bearing: bd_bearing + 180deg, drives: 1, N: pin_n, m: m_small,
               face: s2_z0 - s3_z0 + bond, bore: rod_bore, spokes: 0, hub: 0mm, web: 0mm)
// B's second: stage 3's gear over stage 4's pinion, at module 1
b2_gear := Gear(b_c, z: s3_z0, bearing: bd_bearing + 180deg, drives: 0, N: big_n, m: m_small,
                face: 5mm, bore: rod_bore, spokes: 5, hub: 11mm, web: 2.4mm)
b2_pin := Gear(b_c, z: s4_z0, bearing: bd_bearing, drives: 1, N: pin_n, m: m_s4,
               face: s3_z0 - s4_z0 + bond, bore: rod_bore, spokes: 0, hub: 0mm, web: 0mm)
// D's second: stage 4's gear over the last pinion, which drives A's ring
d2_gear := Gear(d_c, z: s4_z0, bearing: bd_bearing, drives: 0, N: s4_n, m: m_s4,
                face: 6mm, bore: rod_bore, spokes: 0, hub: 0mm, web: 0mm)
d2_pin := Gear(d_c, z: fin_z0, bearing: da_bearing, drives: 1, N: fin_n, m: m_fin,
               face: s4_z0 - fin_z0 + bond, bore: rod_bore, spokes: 0, hub: 0mm, web: 0mm)

construction motor_pinion := solid(motor_pin.gear)
construction b1 := solid(b1_gear.gear)
b1_pin.gear union b1
construction d1 := solid(d1_gear.gear)
d1_pin.gear union d1
construction b2 := solid(b2_gear.gear)
b2_pin.gear union b2
construction d2 := solid(d2_gear.gear)
d2_pin.gear union d2

// The socket and the train turning with the handle, at the rates worked out with the drive, each
// read a turn open of the handle, so every joint stands at `handle_open` itself.  The socket turns
// with the handle but stands where it is, the handle screwing through.
socket_turn := frame
socket_turn turns(1) valve.stem_down
fix(value == handle_open) socket_turn
a_turn := frame
a_turn turns(a_rate) a_spindle
fix(value == handle_open) a_turn
d2_turn := frame
d2_turn turns(d2_rate) d_spindle
fix(value == handle_open) d2_turn
b2_turn := frame
b2_turn turns(b2_rate) b_spindle
fix(value == handle_open) b2_turn
d1_turn := frame
d1_turn turns(d1_rate) d_spindle
fix(value == handle_open) d1_turn
b1_turn := frame
b1_turn turns(b1_rate) b_spindle
fix(value == handle_open) b1_turn
motor_turn := frame
motor_turn turns(motor_rate) m_spindle
fix(value == handle_open) motor_turn

socket := socket_part in socket_turn
a_compound := a_part in a_turn
compound_d2 := d2 in d2_turn
compound_b2 := b2 in b2_turn
compound_d1 := d1 in d1_turn
compound_b1 := b1 in b1_turn
pinion := motor_pinion in motor_turn

// == The motor ===================================================================================
// Face down on a pad on the lid, its boss in a recess, its shaft through the pad and the lid to
// its pinion in stage 1; held in a cradle of its own section grown by a wall, a print's clearance
// inside, the pad the cradle's section under it.
motor_at := point
motor_at raised(d: motor_z, along: std.z) m_c
motor := Motor130(motor130_dims)
motor seats(turn: bot_turn, up: std.z, east: std.x) motor_at

cradle_out := MotorCan(motor130_dims, grow: wall + gap, z0: lid_z1 - motor_z, z1: 18mm)
cradle_out seats(turn: bot_turn, up: std.z, east: std.x) motor_at
cradle_in := MotorCan(motor130_dims, grow: gap, z0: 0mm, z1: 19mm)
cradle_in seats(turn: bot_turn, up: std.z, east: std.x) motor_at
cradle := solid(cradle_out.body)
cradle_in.body cut cradle

// == The base: the gearbox's floor and walls =====================================================
// A box from the floor to the lid, hollowed; its floor and its walls are cut away where A's ring
// turns under the train (the whole of its +x end, down there), and a bridge across it, standing
// on the collar, holds A's axle.  Four M3 screws down through the lid
// hold it up to the frame (below).
base_box := Block(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, z0: floor_z0, z1: lid_z0) in bot
base_cavity := Block(x0: box_x0 + wall, x1: box_x1 - wall, y0: box_y0 + wall, y1: box_y1 - wall,
                     z0: floor_z1, z1: lid_z0 + 1mm) in bot
base_shell := solid(base_box.body)
base_cavity.body cut base_shell

bridge := Block(x0: -a_dist, x1: box_x1 - wall, y0: -collar_r, y1: collar_r, z0: bridge_z0,
                z1: bridge_z1) in bot
bridge_boss := Post(a_c, r: collar_r, z0: bridge_z0, z1: bridge_z1)
ring_room := Post(a_c, r: 39mm, z0: floor_z0 - 1mm, z1: ring_z1 + 0.5mm)
ring_side := Block(x0: -a_dist, x1: box_x1 + 1mm, y0: box_y0 - 1mm, y1: box_y1 + 1mm,
                   z0: floor_z0 - 1mm, z1: ring_z1 + 0.5mm) in bot  // and the box's end over it
base_hole_a := Post(a_c, r: (axle_d + press) / 2, z0: bridge_z0 - 1mm, z1: bridge_z1 + 1mm)
base_hole_b := Post(b_c, r: (rod_d + press) / 2, z0: floor_z0 - 1mm, z1: floor_z1 + 1mm)
base_hole_d := Post(d_c, r: (rod_d + press) / 2, z0: floor_z0 - 1mm, z1: floor_z1 + 1mm)

base := solid(base_shell)
bridge.body union base
bridge_boss.body union base
ring_room.body cut base
ring_side.body cut base
base_hole_a.body cut base
base_hole_b.body cut base
base_hole_d.body cut base

// == The frame: the lid and the bay ===============================================================
// One print, the bot's backbone, printed on its lid: A's axle and the train's rods stand in its
// lid, the electronics bay stands on it, and the mount is glued onto the rail up its end wall.
lid := Block(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, z0: lid_z0, z1: lid_z1) in bot
bay_box := Block(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, z0: lid_z1, z1: bay_z1) in bot
bay_room := Block(x0: box_x0 + wall, x1: box_x1 - wall, y0: box_y0 + wall, y1: box_y1 - wall,
                  z0: lid_z1 - 1mm, z1: bay_z1 + 1mm) in bot
bay_shell := solid(bay_box.body)
bay_room.body cut bay_shell

// the mount's rail, from the lid up the end wall to its top, and the notch the snap's barb falls
// into, over the rail's lip
rail := Dovetail(x0: box_x1 - 1mm, x1: box_x1 + dove_h, w0: dove_root - 2mm * tan(dove_angle),
                 w1: dove_tip, z0: rail_z0, z1: bay_z1) in bot
rail_notch := Block(x0: box_x1 + dove_h - barb_h - slip, x1: box_x1 + dove_h + 1mm,
                    y0: -finger_w / 2 - gap, y1: finger_w / 2 + gap, z0: finger_z0 - slip,
                    z1: finger_z0 + barb_flat + barb_ramp + gap) in bot

// the rods' holes, the motor's boss and shaft
lid_hole_a := Post(a_c, r: (axle_d + press) / 2, z0: lid_z0 - 1mm, z1: lid_z1 + 1mm)
lid_hole_b := Post(b_c, r: (rod_d + press) / 2, z0: lid_z0 - 1mm, z1: lid_z1 - 1mm)
lid_hole_d := Post(d_c, r: (rod_d + press) / 2, z0: lid_z0 - 1mm, z1: lid_z1 - 1mm)
motor_boss_room := Post(m_c, r: motor130_dims.boss_d / 2 + gap,
                        z0: motor_z - motor130_dims.boss_h - gap, z1: motor_z + 1mm)
motor_shaft_room := Post(m_c, r: 2.5mm, z0: lid_z0 - 1mm, z1: motor_z)

// the cable entries, in the bay's far end wall: a grommet for the thermostat's cable, low beside
// the motor, and a window each on the RedBoard's barrel jack and its USB-C that a cable's moulded plug
// passes through to mate
grommet := BoreX(y: -14mm, z: lid_z1 + 12mm, d: 8mm, x0: box_x0 - 1mm,
                 x1: box_x0 + wall + 1mm) in bot
usb_slot := Block(x0: box_x0 - 1mm, x1: box_x0 + wall + 1mm,
                  y0: usb_y - redboard_dims.plug_w / 2 - gap, y1: usb_y + redboard_dims.plug_w / 2 + gap,
                  z0: usb_z - redboard_dims.plug_h / 2 - gap,
                  z1: usb_z + redboard_dims.plug_h / 2 + gap) in bot
jack_half := redboard_dims.jack_plug / 2 + gap
jack_slot := Block(x0: box_x0 - 1mm, x1: box_x0 + wall + 1mm, y0: jack_y - jack_half,
                   y1: jack_y + jack_half, z0: jack_z - jack_half, z1: jack_z + jack_half) in bot

frame_part := solid(lid.body)
bay_shell union frame_part
rail.body union frame_part
cradle union frame_part
lid_hole_a.body cut frame_part
lid_hole_b.body cut frame_part
lid_hole_d.body cut frame_part
motor_boss_room.body cut frame_part
motor_shaft_room.body cut frame_part
grommet.body cut frame_part
usb_slot.body cut frame_part
jack_slot.body cut frame_part
rail_notch.body cut frame_part

// == The mount: the spine and the clamp's fixed half =============================================
// A print of its own, so that neither part needs support: the frame prints on its lid, the mount
// on its top, the clamp's and the spine's.  The spine stands on the end wall's outside from the
// lid's underside up to the clamp's top, and carries the frame up beside the valve to the clamp
// round the inlet hex and the pipe.
//
// It slides up onto the frame's rail from below, the rail in a dovetail slot up the spine's back,
// open at its top, until the rail's foot sits on the shelf closing the slot's bottom: the frame
// hangs on the shelf.  There the barb at the foot of a finger in the slot's floor, pushed out by
// the rail's lip in the last few millimetres, snaps into the rail's notch, and holds the two
// together while the glue in the slot sets.  The dovetail's flanks take the handle's reaction
// sideways and outward, the glue the rest.
spine := Block(x0: box_x1 + slip, x1: spine_x1, y0: -spine_w / 2, y1: spine_w / 2, z0: lid_z0,
               z1: clamp_z1) in bot
clamp_main := Block(x0: -clamp_reach, x1: -split / 2, y0: -clamp_w / 2, y1: clamp_w / 2,
                    z0: clamp_z0, z1: clamp_z1) in bot
slot := Dovetail(x0: box_x1 - 1mm,
                 x1: slot_floor,
                 w0: dove_root - 2mm * tan(dove_angle) + 2 * slip / cos(dove_angle),
                 w1: dove_tip + 2 * slip * tan(dove_angle) + 2 * slip / cos(dove_angle),
                 z0: rail_z0 - slip, z1: clamp_z1 + 1mm) in bot
finger_room := Block(x0: slot_floor - 1mm, x1: slot_floor + finger_t + finger_relief,
                     y0: -finger_w / 2 - finger_slit, y1: finger_w / 2 + finger_slit,
                     z0: finger_z0 - finger_slit, z1: finger_z0 + finger_len) in bot
finger := Block(x0: slot_floor, x1: slot_floor + finger_t, y0: -finger_w / 2, y1: finger_w / 2,
                z0: finger_z0, z1: finger_z0 + finger_len + 1mm) in bot
barb := Barb(x: slot_floor, z: finger_z0, h: barb_h, w: finger_w, flat: barb_flat,
             ramp: barb_ramp) in bot

mount_shell := solid(spine.body)
clamp_main.body union mount_shell
slot.body cut mount_shell
finger_room.body cut mount_shell
mount_part := solid(mount_shell)
finger.body union mount_part
barb.body union mount_part
claim frame_part clear(0.1mm) mount_part              // the joint: the glue's room, all round

// == The screws: the base to the lid, the RedBoard, the cover ====================================
// The base's four, up from posts in its corners through the lid, their heads in the bay.
repeat 2 as i {
  repeat 2 as j {
    base_at := At(x: box_x0 + screw_inset + i * (box_x1 - box_x0 - 2 * screw_inset),
                  y: box_y0 + screw_inset + j * (box_y1 - box_y0 - 2 * screw_inset)) in bot
    base_screw := ScrewPost(base_at.p, r: 4mm, z0: floor_z1, z1: lid_z0, hole_d: pilot,
                            depth: 12mm) in bot
    lid_screw := Post(base_at.p, r: m3_clear / 2, z0: lid_z0 - 1mm, z1: lid_z1 + 1mm) in bot
    base_screw.post union base
    base_screw.hole cut base
    lid_screw.body cut frame_part
  }
}

// The RedBoard's four M3s, self-tapping into posts on the lid at its holes (boards.sv), the Uno's.
// The posts are 5 mm across, an M3 standoff's size: the one by the SCL socket stands 3.6 mm off
// its SCL pin.  Each hole runs a millimetre on into the lid.
repeat h in uno_holes {
  board_hole := At(x: board_ox + h.x, y: board_oy + h.y) in bot
  board_screw := ScrewPost(board_hole.p, r: 2.5mm, z0: lid_z1, z1: board_z, hole_d: pilot,
                           depth: board_z - lid_z1 + 1mm) in bot
  board_screw.post union frame_part
  board_screw.hole cut frame_part
}

// The cover's four, down through it into posts in the bay's walls, clear of the boards, the motor
// and the base's screws in the corners: west on the south wall by the end wall, between the
// corner's screw and the motor (the RedBoard's end comes up to the end wall), east by the spine, south
// and north clear of the shield's +x end.
cover_screws := [
  (box_x0 + 16mm, box_y0 + screw_inset),           // west
  (box_x1 - screw_inset, (box_y0 + box_y1) / 2),   // east
  (-55mm, box_y0 + screw_inset),                   // south
  (-55mm, box_y1 - screw_inset),                   // north
]
repeat c in cover_screws {
  cover_at := At(x: c.x, y: c.y) in bot
  cover_screw := ScrewPost(cover_at.p, r: 4mm, z0: lid_z1, z1: bay_z1, hole_d: pilot,
                           depth: 12mm) in bot
  cover_screw.post union frame_part
  cover_screw.hole cut frame_part
}

// == The clamp ===================================================================================
// A block round the inlet hex and the pipe above it, split on the stem's plane square to the
// bot's x: the fixed half is the mount's, on the bot's side, and the cap bolts to it from the
// other, out of the radiator's way, with four M4 bolts, their nuts in pockets in the fixed half's
// back.  The hex's pocket is the hex grown a print's clearance all round, so the hex takes the
// handle's torque; the pipe's bore is the pipe's, so the closing split grips it.  The clamp hangs
// on the hex's top face.
//
// With the bot a quarter turn round, the split crosses the middles of the hex's two flats square
// to the outlet, so each half holds two whole flats and half of each of those, and a corner
// stands in each half's middle.  Both rows of bolts grip the pipe over the hex.  The clamp's side
// toward the radiator reaches out over the outlet's union nut, whose top stands above the hex's
// underside, so both halves are relieved round it: the nut grown `nut_clear` all round.
clamp_cap := Block(x0: split / 2, x1: clamp_reach, y0: -clamp_w / 2, y1: clamp_w / 2,
                   z0: clamp_z0, z1: clamp_z1) in bot
cap_part := solid(clamp_cap.body)

hex_room := std.rounds.Grown(valve.body.inlet.bar, d: gap)
pipe_room := RoundBar(std.top.origin, d: pipe_dims.d + 0.2mm, z0: body_dims.inlet_top,
                      z1: clamp_z1 + 1mm)
hex_room.body cut mount_part
hex_room.body cut cap_part
pipe_room.bar cut mount_part
pipe_room.bar cut cap_part
nut_room := std.rounds.Grown(valve.union.nut.bar, d: nut_clear)
nut_room.body cut mount_part
nut_room.body cut cap_part

repeat 2 as i {
  bolt_lo := BoreX(y: (2 * i - 1) * clamp_bolt_y, z: clamp_bolt_z0, d: m4_clear,
                   x0: -clamp_reach - 1mm, x1: clamp_reach + 1mm) in bot
  bolt_hi := BoreX(y: (2 * i - 1) * clamp_bolt_y, z: clamp_bolt_z1, d: m4_clear,
                   x0: -clamp_reach - 1mm, x1: clamp_reach + 1mm) in bot
  nut_lo := NutX(y: (2 * i - 1) * clamp_bolt_y, z: clamp_bolt_z0, af: m4_nut_af,
                 x0: -clamp_reach - 1mm, x1: -clamp_reach + 4mm) in bot
  nut_hi := NutX(y: (2 * i - 1) * clamp_bolt_y, z: clamp_bolt_z1, af: m4_nut_af,
                 x0: -clamp_reach - 1mm, x1: -clamp_reach + 4mm) in bot
  bolt_lo.body cut mount_part
  bolt_lo.body cut cap_part
  bolt_hi.body cut mount_part
  bolt_hi.body cut cap_part
  nut_lo.nut.bar cut mount_part
  nut_hi.nut.bar cut mount_part
  claim bolt_lo.body clear(1mm) hex_room.body
}

// == The cover ===================================================================================
cover := Block(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, z0: bay_z1, z1: bay_z1 + wall) in bot
cover_part := solid(cover.body)
repeat c in cover_screws {
  cover_hole_at := At(x: c.x, y: c.y) in bot
  cover_hole := Post(cover_hole_at.p, r: m3_clear / 2, z0: bay_z1 - 1mm,
                     z1: bay_z1 + wall + 1mm) in bot
  cover_hole.body cut cover_part
}

// == The electronics =============================================================================
// A SparkFun IoT RedBoard ESP32 screwed down beside the motor, and a perfboard shield plugged
// into it (boards.sv) carrying the two breakouts and the thermostat's and the motor's terminals
// (~ size):
//   - the RedBoard, its USB-C and its barrel jack to the end wall's windows: the wall adapter's
//     9 V in, its own 5 V and 3.3 V, Wi-Fi, programming and the console;
//   - an Adafruit TB6612 breakout, its two bridges tied together on the shield: the H-bridge,
//     off the RedBoard's VIN;
//   - an Adafruit INA219 breakout in the driver's supply: the motor's current over I2C, which the
//     ESP32 reads for the end-of-travel sensing;
//   - a 2-way 5.08 mm screw terminal for the thermostat's two wires, at the shield's -x end by
//     the grommet, its pins in the shield's column 1, rows 7 and 9;
//   - another for the motor's leads, at its +x end, its pins in column 17, rows 2 and 4.
board_c := At(x: board_ox, y: board_oy) in bot
board_at := point
board_at raised(d: board_z, along: std.z) board_c.p
redboard := RedBoardEsp32(redboard_dims)
redboard seats(turn: bot_turn, up: std.z, east: std.x) board_at
shield := Shield(shield_dims, u: redboard_dims, h: header_dims)
shield seats(turn: bot_turn, up: std.z, east: std.x) board_at
drv_c := At(x: drv_cx, y: drv_cy) in bot
ina_c := At(x: ina_cx, y: ina_cy) in bot
drv_at := point
drv_at raised(d: shield_z, along: std.z) drv_c.p
driver := Tb6612(tb6612_dims, h: header_dims)
driver seats(turn: bot_turn + 180deg, up: std.z, east: std.x) drv_at
ina_at := point
ina_at raised(d: shield_z, along: std.z) ina_c.p
monitor := Ina219(ina219_dims, h: header_dims)
monitor seats(turn: bot_turn - 90deg, up: std.z, east: std.x) ina_at
terminal := Block(x0: board_ox - pitch - 3.8mm, x1: board_ox - pitch + 3.8mm,
                  y0: board_oy + 6 * pitch, y1: board_oy + 10 * pitch, z0: shield_z,
                  z1: shield_z + 10mm) in bot
motor_terminal := Block(x0: board_ox + 15 * pitch - 3.8mm, x1: board_ox + 15 * pitch + 3.8mm,
                        y0: board_oy + pitch, y1: board_oy + 5 * pitch, z0: shield_z,
                        z1: shield_z + 10mm) in bot

// The boards in the bay: a mated cable's plug through each of the end wall's windows, and the
// boards, the RedBoard's parts and the pins' tails clear of the frame, the motor and the cover,
// and of one another.  The motor clears the cover over it.
claim redboard.usb_plug clear(0.2mm) frame_part
claim redboard.jack_plug clear(0.2mm) frame_part
claim redboard.parts clear(0.5mm) frame_part
claim redboard.tails clear(0.5mm) frame_part
claim redboard.board clear(1mm) cradle
claim redboard.board clear(1mm) bay_shell
claim redboard.board clear(1mm) motor.motor
claim redboard.parts clear(1mm) motor.motor
claim redboard.tails clear(0.5mm) motor.motor
claim shield.board clear(1mm) motor.motor
claim shield.board clear(1mm) cradle
claim driver.board clear(1mm) motor.motor
claim motor.motor clear(1mm) cover_part
claim shield.board clear(0.5mm) frame_part
claim shield.headers clear(0.5mm) frame_part
claim shield.board clear(0.3mm) redboard.parts
claim driver.board clear(0.5mm) frame_part
claim driver.headers clear(0.5mm) frame_part
claim monitor.board clear(0.5mm) frame_part
claim monitor.headers clear(0.5mm) frame_part
claim driver.headers clear(0.3mm) redboard.parts
claim monitor.headers clear(0.3mm) redboard.parts
claim driver.board clear(1mm) cover_part
claim monitor.board clear(1mm) cover_part
claim terminal.body clear(1mm) cover_part
claim terminal.body clear(0.5mm) frame_part
claim motor_terminal.body clear(1mm) cover_part
claim motor_terminal.body clear(0.5mm) frame_part
claim driver.board clear(0.5mm) monitor.board
claim driver.board clear(0.5mm) motor_terminal.body
claim driver.board clear(0.5mm) shield.headers
claim terminal.body clear(0.5mm) monitor.board
claim terminal.body clear(0.5mm) driver.board
claim motor_terminal.body clear(0.5mm) shield.headers

// == Clearances ==================================================================================
// With `checks` 1, every part's clearance is judged, which builds every shaped part.  The socket
// and the stand are judged against the handle open, A's compound against it closed: the socket
// turns with the handle and its hole is the same at every height, so only the handle's height
// changes, and each comes nearest at that end.  Gears in mesh run 0.15 mm clear a flank; parts
// that rest on one another (the motor on its lid, the base on the frame, the collar on the
// bridge, the socket on the stand's pad) are not claimed clear; the mount clears the base, whose
// end wall stands under its foot's edge.
when checks == 1 {
  rest_handle := StarHandle(valve.handle_top, s: handle_dims, stem_up: 1mm)
  construction open_handle := rest_handle.handle at(under: valve.handle) (open_turns * 360deg)
  claim socket_part clear(0.1mm) open_handle
  claim stand_part clear(1mm) open_handle
  claim a_part clear(1mm) rest_handle.handle
  claim socket clear(0.05mm) a_compound
  claim socket clear(1mm) valve.packing_nut.bar
  claim socket clear(0.3mm) base
  claim socket clear(0.3mm) frame_part
  claim a_compound clear(0.3mm) base
  claim a_compound clear(0.3mm) frame_part
  claim a_compound clear(0.25mm) stand_part
  claim pivot_pin.body clear(0.4mm) socket_part         // loose in its hole, under its roof
  claim a_compound clear(0.25mm) collar.part
  claim a_compound clear(0.05mm) compound_d2
  claim compound_d2 clear(1mm) collar.part
  claim compound_d2 clear(0.05mm) compound_b2
  claim compound_b2 clear(0.05mm) compound_d1
  claim compound_d1 clear(0.05mm) compound_b1
  claim compound_b1 clear(0.05mm) pinion
  claim compound_d2 clear(0.2mm) base
  claim compound_b2 clear(0.2mm) base
  claim compound_b1 clear(0.2mm) frame_part
  claim compound_d1 clear(0.2mm) frame_part
  claim pinion clear(0.2mm) frame_part
  claim compound_b1 clear(0.2mm) motor.motor            // the shaft, through its pinion
  claim compound_d1 clear(0.2mm) motor.motor
  claim compound_b2 clear(0.5mm) motor.motor            // the shaft's end, 1 mm over its spokes
  claim mount_part clear(0.05mm) valve.supply_pipe.bar
  claim cap_part clear(0.05mm) valve.supply_pipe.bar
  claim mount_part clear(0.15mm) valve.body.casting
  claim cap_part clear(0.15mm) valve.body.casting
  claim mount_part clear(2mm) valve.bonnet.bonnet
  claim mount_part clear(2mm) valve.packing_nut.bar
  claim frame_part clear(2mm) valve.bonnet.bonnet
  claim frame_part clear(2mm) valve.packing_nut.bar
  claim mount_part clear(0.1mm) base
  claim base clear(2mm) valve.bonnet.bonnet
  claim base clear(2mm) valve.packing_nut.bar
  claim base clear(0.3mm) valve.star_handle.handle
  claim mount_part clear(1mm) valve.union.nut.bar
  claim cap_part clear(1mm) valve.union.nut.bar
  claim mount_part clear(1mm) valve.body.boss.bar
  claim cap_part clear(1mm) valve.body.boss.bar
}
