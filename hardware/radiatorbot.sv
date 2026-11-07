// The radiator bot: a geared motor that clamps to the valve's supply pipe and turns the star handle
// through a socket round it.
//
// Coordinates are the valve's (radiator_valve.sv): the stem is std.z, z = 0 is the packing nut's
// bottom face, the radiator lies toward +x.  The bot is laid out in a frame of its own, `bot`,
// turned a quarter turn about the stem, and hangs on that frame's -x side: the
// valve's -y side, beside the outlet, turned 90deg clockwise seen from below from where it hung
// off the outlet's far end.  In the bot's frame:
//
//   - the **socket** is a gear round the handle, turning about the stem with it, its middle the
//     handle's top face's outline straight through: the handle turns it by all four arms at once,
//     and screws down through it as the valve opens.  It turns on a pad on the stem's axis under
//     its floor, at the end of the **stand**, an arm clamped to A, the axle `a_dist` out along -x;
//   - on A, a pinion drives the socket and a 48-tooth ring over it is driven by the **geared
//     motor** (geared_motor.sv) on P: a 130 motor on a stack of three helical planetary stages,
//     one unit, standing on three posts up from the base's floor.  Its output shaft comes out of
//     its foot, and the last pinion, a print of its own, is screwed onto the shaft's end under it,
//     in mesh with A's ring;
//   - the **keeper**, the gearbox's lid, presses down into the base's walls: it holds A's top;
//   - the **frame** is the electronics bay standing on the base and the keeper (beside the
//     motor, the RedBoard with a perfboard shield on it carrying the motor driver and its
//     current monitor, the cable entries), a dovetail rail up its end wall;
//   - the **mount**, a print of its own snapped and glued onto the rail, is the spine up beside
//     the valve and the **clamp**'s fixed half, a split block round the inlet hex and the supply
//     pipe above it.  The hex takes the handle's reaction torque positively; the bolted cap
//     closes the clamp from +x, the side away from the bot.
//
// The parts are drawn from modules: the stock and the fits (fits.sv), the building blocks
// (parts.sv), the geared motor and its stages (geared_motor.sv, planetary.sv), the gears
// (gears.sv), the motor, the boards and the valve.  Scrub `handle_open`: the handle screws open
// down its stem, and the socket and the train turn with it.  Set `shaped` to 0 to draw every gear
// and the socket as blanks while the layout is worked on (building them all takes a few minutes).
// The design table's requirements are claims, judged before the solve; `solventc radiatorbot.sv
// --where handle_stall_torque` reads any figure back in its unit.  Set `checks` to 1 to judge
// every clearance as well, the socket against the handle closed, halfway and open (a couple of
// minutes more).
//
// The file runs from the numbers to the parts: the drive, the heights and the plan, then the
// bot's own building blocks, then each part in turn, then the clearances.  Every size a part is
// drawn to is named in the tables up top, or in its module's, so a change is made there.
//
// Numbers marked "~" are estimates to check: the motor's figures (motor130.sv).

unit mm
use std
use std.solids (cut, union)
use std.place (horizontal, coords, seats, raised)
use std.motion (turns)
use std.shapes
use std.rounds
use std.rounds (round)
use radiator_valve (RadiatorValve, handle_dims, body_dims, pipe_dims, handle_gap, stem_travel)
use radiator_valve (open_turns)
use radiator_valve (StarOutline, StarHandle, RoundBar)
use gears (ShapedSpur)
use motor130 (MotorCan, motor130_dims, motor130_free, motor130_stall_torque)
use boards (RedBoardEsp32, Shield, Tb6612, Ina219, redboard_dims, uno_holes, shield_dims)
use boards (tb6612_dims, ina219_dims, header_dims, pitch)
use fits (run, press, gap, bond, wall, boss_wall, slip, snug, pa, thin, chamfer)
use fits (pilot, m3_clear, m3_head_d, m3_head_h, m4_clear, m4_nut_af)
use parts (Post, ScrewPost, Block, RoundedBlock, Dovetail, UnderSlope, Barb, BoreX, NutX, Collar)
use planetary (stage_ratio, ToothSpace)
use geared_motor (GearedMotor, Footprint, unit_lid_z0, unit_lid_z1, unit_motor_z, unit_strap_top)
use geared_motor (unit_barrel_r, cradle_f, strap_w, strap_reach, teeth_z0, teeth_z1)

shaped := 1                    // 1: shape the gears and the socket; 0: blanks, for a quick look
checks := 0                    // 1: judge every clearance (needs `shaped`; ~2 minutes)

// == Stock =======================================================================================
// Drill rod: A's axle, held in the base's bridge and the keeper.  The geared motor's rod and pins
// are its own (planetary.sv).
axle_d := 0.5in                 // A, the socket pinion's axle
axle_bore := axle_d + run       // A's compound's bore, and the collars'
split := 1mm                    // the clamp's halves stand apart this much before the bolts close it

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

// The gear train, motor to A: the geared motor on P, its three planetary stages each turning its
// carrier one turn for `stage_ratio` of its sun's (planetary.sv), and a spur pinion on its output
// shaft driving A's ring.  The ring and the socket's spur stages turn slowly (A 45 rpm at most,
// the pinion 180), where a spur mesh is quiet, and a helix on the socket would push it up and
// down the handle.  The pinion is shifted +pin_shift, the gears it drives -pin_shift, so the
// centre distances stay nominal.
pin_shift := 0.3
m_fin := 1.5mm                  // the ring and its pinion
fin_n := 12                     // the last pinion, on the geared motor's output shaft
ring_n := 48
cd_fin := m_fin * (fin_n + ring_n) / 2                  // 45 mm, P to A

// P stands beside the electronics bay's boards, and `cd_fin` from A: `p_y` off the bot's x, and
// so `p_x` along it.
p_y := -12.47mm
p_x := -a_dist - sqrt(cd_fin ^ 2 - p_y ^ 2)                    // -103.24 mm

gear_ratio := stage_ratio ^ 3 * ring_n / fin_n               // motor turns an A turn: 304
handle_ratio := gear_ratio * socket_n / a_n                  // a handle turn: 810

// What it does, from the motor's figures: printed meshes at ~0.9 each.  A planetary stage loses
// only on the power its meshes roll through, the sun turning against its carrier: with the ring
// fixed, (1 + 0.9 ^ 2 (i - 1)) / i of it reaches the carrier, 0.855 here.  Then the ring's and the
// socket's spur meshes, and the handle in the socket is a direct drive.  The current sensing trips
// well under the stall: at the end of the screw the torque the trip allows is what seats the
// valve.  What the design asks of it: a stall well over what an old packed valve takes to turn,
// about three quarters of what the spur train it replaces gave (1024:1 through six spur meshes,
// 3.75 N·m) and no more, since that seated the valve harder than it needed; and three and a
// half turns of travel inside half a minute unloaded.
mesh_eff := 0.9
stage_eff := (1 + mesh_eff ^ 2 * (stage_ratio - 1)) / stage_ratio
drive_eff := stage_eff ^ 3 * mesh_eff ^ 2
handle_free_speed := motor130_free / handle_ratio
handle_stall_torque := motor130_stall_torque * handle_ratio * drive_eff
a_stall_torque := handle_stall_torque * a_n / socket_n / mesh_eff     // what A's pinion carries
spur_stall_torque := motor130_stall_torque * 1024 * mesh_eff ^ 6    // the spur train's, before
claim handle_stall_torque >= 2Nm
claim handle_stall_torque >= 0.7 * spur_stall_torque
claim handle_stall_torque <= 0.8 * spur_stall_torque
claim handle_free_speed >= 6rpm

// How fast each part turns about its upward axis, in turns a turn open of the handle (a turn the
// handle makes about the downward stem): A 64/24, the geared motor's output and its pinion back
// from A's ring, reversed, and the motor `stage_ratio` cubed faster, the same way.
a_rate := socket_n / a_n
c3_rate := -a_rate * ring_n / fin_n
motor_rate := c3_rate * stage_ratio ^ 3
claim motor_rate == -handle_ratio

// == Heights =====================================================================================
// From the floor up: A's ring and the last pinion beside it, then the geared motor standing a
// print's clearance over the pinion, its lid level with the keeper; the electronics bay and its
// cover.  The base's floor runs round P only: A's ring turns beside it.  The geared motor's
// heights are its own (geared_motor.sv), from its foot, which stands at `unit_z0`.
floor_z0 := -3.1mm
floor_z1 := floor_z0 + 6mm
ring_z0 := 3mm                  // the ring's teeth; the web under it runs down to A's pinion
ring_z1 := ring_z0 + 10mm
fin_z0 := ring_z0 + 0.5mm       // the last pinion, its face up to the output shaft's shoulder
fin_face := 10mm
unit_z0 := fin_z0 + fin_face + gap                      // the geared motor's foot
lid_z0 := unit_z0 + unit_lid_z0                         // its lid, and the keeper
lid_z1 := unit_z0 + unit_lid_z1
motor_z := unit_z0 + unit_motor_z                       // the motor's front face, on its pad
strap_top := unit_z0 + unit_strap_top
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
// A's axle: a collar over the ring, under the bridge across the base that holds the axle, which
// stands from there up to the keeper, and the stand under A's pinion, its arm a print's clearance
// under the socket's floor and its pad up to it.
collar_h := 6mm
collar_r := axle_d / 2 + 5mm
collar_z0 := ring_z1 + gap
bridge_z0 := collar_z0 + collar_h
bridge_z1 := lid_z0
// A's axle stands up into a post on the keeper's top, its hole blind under a 1 mm roof.
post_z1 := lid_z1 + 2.5mm
rod_z1 := post_z1 - 1mm
stand_z1 := socket_z0 - gap
stand_z0 := stand_z1 - 4mm
// The keeper presses down into the top of the base, whose walls run up past the gears to its
// top; the frame (the electronics bay) stands on the base, the keeper and the geared motor's lid,
// its own floor `case_z1` thick round the keeper's post and the motor's cradle, which come up
// through it.
case_z1 := lid_z1 + wall
// The mount's joint: the frame's rail leaves the end wall 2 mm up from the frame's underside, its
// foot sloped up and out at 45deg so it prints from the wall, and stands on the mount's shelf,
// sloped so under it, the mount's foot flush with the frame's underside; the snap's finger hangs
// in the slot's floor, its barb's underside 2.5 mm over the foot at the rail's face, a lip of it.
rail_z0 := lid_z1 + 2mm
finger_z0 := rail_z0 + dove_h + 2.5mm
board_z := lid_z1 + 6mm                                 // the RedBoard's underside, on its posts
shield_z := board_z + shield.top                          // the shield's top face
bay_z1 := motor_z + motor130_dims.len + motor130_dims.back_h + 3mm  // room over it for its leads
// The motor's strap's ears swell out of the cradle's flats from level with the top of the
// RedBoard's LiPo socket, which the +y one passes over.
ear_z0 := board_z + redboard_dims.pcb_t + redboard_dims.lipo_h
clamp_z0 := body_dims.inlet_top - body_dims.inlet_h     // the inlet hex's underside
clamp_z1 := clamp_z0 + 31.7mm

// == Plan ========================================================================================
// The housing's outline, the clamp and the spine, in plan (x, y) in the bot's frame: the box the
// base, the bay and the cover all share.  Its -y wall clears the geared motor's barrel; its +y
// side stands 4.4 mm off the RedBoard's 2.3 in across the bay.
box_x0 := -136mm
box_x1 := -35mm
box_y0 := -44.5mm
box_y1 := 64mm
claim box_y0 + wall + 1mm <= p_y - unit_barrel_r - gap     // the gearcase inside the box's walls
// The box's four upright corners are rounded outside, and inside by as much less the wall, so the
// walls keep their thickness round them: a square corner is where a print's floor lifts first.
box_r := 5mm
box_r_in := box_r - wall
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
screw_inset := wall + 2mm       // the cover's screws, in from the box's outside
// The base's screws, in from the box's outside: their heads stand on the frame's floor in the
// bay's corners, a millimetre clear of its walls; their posts reach out into both walls.
base_screw_inset := wall + m3_head_d / 2 + 1mm
base_post_r := base_screw_inset - wall + 0.7mm   // past the cavity's rounded corner, not tangent to it
// The RedBoard and its shield (boards.sv) stand beside the motor, by the RedBoard's frame, its
// power header's first pin at (board_ox, board_oy): its jack's mouth a millimetre in from the end
// wall's inside face, its edge 2 mm off the motor's cradle's flat.
board_ox := box_x0 + wall + 1mm - redboard_dims.jack_x0
board_oy := p_y + cradle_f + 2mm - redboard_dims.y0
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

// == The bot's building blocks ===================================================================

// A printed spur gear seated on an axle at `c`: its figure (gears.sv) with its origin `z` up the
// axle, its axis up the world's z.  `mesh` is the line of centres, from the pinion's axle to the
// gear's, and `drives` says which this is: 1 for the pinion, which drives, 0 for the gear it
// drives.  The pinion is shifted +pin_shift and stands a tooth on the line of centres; its gear is
// shifted -pin_shift and stands a space on it (the figure's cut space is on +v: a pinion turned
// `90deg + 180deg - 180deg / N` from the line, its gear `90deg`).  Gears of one size and face are
// one figure, shaped once.
component Gear(c: point, mesh: line, z: Length, drives: Int, N: Int, m: Length, face: Length,
               bore: Length) {
  at := point
  at raised(d: z, along: std.z) c
  g := ShapedSpur(N: N, m: m, phi: pa, shift: (2 * drives - 1) * pin_shift, thin: thin,
                  z0: 0mm, z1: face, bore: bore, shaped: shaped, chamfer: chamfer,
                  spokes: 0, hub: 0mm, web: 0mm)
  g seats(turn: 90deg + drives * (180deg - 180deg / N), up: std.z, east: mesh) at
  construction gear := solid(g.gear)
}

// A joint between the keeper and a wall of the base, drawn in its own frame (its origin on the
// wall's inside face at z = 0, x in from the wall, y along it): a dovetail rail up the wall from
// its sloped foot to the base's top, the slot in the keeper's pad that slides down over it (the
// rail grown `snug` all round), and the pad, `anchor_w` along the wall and `anchor_d` deep, `snug`
// off it.
component KeeperJoint() {
  rail_z0 := lid_z0 - rail_h
  tail := Dovetail(x0: -1mm, x1: rail_h, w0: rail_root - 2mm * tan(dove_angle), w1: rail_tip,
                   z0: rail_z0, z1: lid_z1)
  heel := UnderSlope(x0: 0mm, x1: rail_h + 1mm, z0: rail_z0, zb: rail_z0 - 1mm, w: rail_tip + 2mm)
  groove := Dovetail(x0: -1mm, x1: rail_h + snug,
                     w0: rail_root - 2mm * tan(dove_angle) + 2 * snug / cos(dove_angle),
                     w1: rail_tip + 2 * snug * tan(dove_angle) + 2 * snug / cos(dove_angle),
                     z0: lid_z0 - 1mm, z1: lid_z1 + 1mm)
  pad := Block(x0: snug, x1: anchor_d, y0: -anchor_w / 2, y1: anchor_w / 2, z0: lid_z0, z1: lid_z1)
  rail := solid(tail.body)
  heel.body cut rail
  slot := solid(groove.body)
}

// The RedBoard's four posts on the frame's floor, drawn in the RedBoard's frame (boards.sv: its
// underside on std.top, its origin its power header's first pin): one at each of the Uno's holes,
// from `z0` up to the board, and an M3's self-tapping hole `depth` down into each.
component BoardPosts(z0: Length, depth: Length) {
  posts := solid()
  holes := solid()
  repeat h in uno_holes {
    c := point hint((h.x, h.y)) in std.top
    c coords(du: h.x, dv: h.y) std.top
    screw := ScrewPost(c, r: 2.5mm, z0: z0, z1: 0mm, hole_d: pilot, depth: depth)
    screw.post union posts
    screw.hole union holes
  }
}

// == The valve ===================================================================================

// The handle's turns open, scrubbed: the handle screws down its stem, and the socket and the train
// turn with it.  Keep the drawing free of redundant rows (the report's `implied:` lines): one makes
// this follow take minutes instead of seconds (bmander/geomsolver#591).
param handle_open: Angle over (0deg, open_turns * 360deg)  // closed to open
valve := RadiatorValve(handle_open: handle_open)

// == The bot's frame =============================================================================
// The bot is drawn in a frame of its own, `bot`, turned a quarter turn about the stem from the
// valve's: every plan number above (the box, the spine, the clamp, the boards' places) is in it,
// its x out from the stem through the clamp's split to the bot's far end at -x, its z the stem's.
// A quarter turn stands the bot on the valve's -y side, beside the outlet rather than off its far
// end: turned 90deg clockwise as seen from below, looking at the handle.  The parts square to the
// bot (`Block`, `BoreX`, `NutX` and what is made of them) are called `in bot`; a point of the
// plan is drawn in the world's top plane, its ordinates along the bot's axes; and every part
// seated on a point (the gears, the geared motor, the collars, the boards) takes its heading from
// the bot's x.
bot := frame
fix(origin == (0mm, 0mm, 0mm)) bot
fix(dir == (0, 1, 0)) bot.u      // a quarter turn: the bot's x along the world's y
fix(dir == (-1, 0, 0)) bot.v     // and its y along the world's -x

// == The axles ===================================================================================
// A, the socket's pinion's and the ring's, is `a_dist` out along the bot's -x; P, the geared
// motor's, is `cd_fin` from it at (p_x, p_y), its pinion on the ring.  The lines of centres run
// from each pinion's axle to its gear's.
in std.top {
  a_c := point hint((0, -a_dist))         // seeds in the world's plan: the bot's (x, y) is (-y, x)
  std.origin distance(-a_dist, along: bot.u) a_c
  std.origin distance(0mm, along: bot.v) a_c
  p_c := point hint((-p_y, p_x))
  std.origin distance(p_x, along: bot.u) p_c
  std.origin distance(p_y, along: bot.v) p_c
  construction a_mesh := line(a_c, std.top.origin)
  construction p_mesh := line(p_c, a_c)
}
// each axle's spindle, a line up it, for the joints that show the train turning
a_up := point
a_up raised(d: 10mm, along: std.z) a_c
p_up := point
p_up raised(d: 10mm, along: std.z) p_c
construction a_spindle := line(a_c, a_up)
construction p_spindle := line(p_c, p_up)

// A's rod, held in the base's bridge and up into its post on the keeper, down to the stand.
axle_a := Post(a_c, r: axle_d / 2, z0: stand_z0, z1: rod_z1)

// == The socket ==================================================================================
// A gear round the handle about the stem, a body under its teeth down to a floor under the
// handle, and through it all the hole the handle turns it by: the star's top face's outline,
// grown `socket_fit` all round, straight from the floor up out of its top.  It is drawn where the
// handle stands closed (`valve.handle_top`), the hole square to the arms there.
socket_gear := Gear(std.top.origin, mesh: a_mesh, z: socket_z1 - socket_face, drives: 0,
                    N: socket_n, m: m_socket, face: socket_face, bore: 4mm)
socket_body := Post(std.top.origin, r: socket_body_r, z0: socket_z0,
                    z1: socket_z1 - socket_face + bond)
socket_star := StarOutline(valve.handle_top, s: handle_dims)
socket_prism := solid(std.solids.Prism(socket_star.outline,
                                       from: socket_floor - top0 + socket_fit,
                                       to: socket_z1 - top0 + 1mm))
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
a_pin := Gear(a_c, mesh: a_mesh, z: a_pin_z0, drives: 1, N: a_n, m: m_socket,
              face: web_z0 - a_pin_z0 + bond, bore: axle_bore)
ring_gear := Gear(a_c, mesh: p_mesh, z: ring_z0, drives: 0, N: ring_n, m: m_fin,
                  face: ring_z1 - ring_z0, bore: axle_bore)
web := Post(a_c, r: 30mm, z0: web_z0, z1: ring_z0 + bond)
a_bore := Post(a_c, r: axle_bore / 2, z0: a_pin_z0 - 1mm, z1: ring_z1 + 1mm)
construction a_part := solid(a_pin.gear)
web.body union a_part
ring_gear.gear union a_part
a_bore.body cut a_part

// A's compound kept on its axle: the collar over it, under the base's bridge, and the stand
// under it.  Each collar's set screw is driven from the bot's -x.
collar := Collar(r: collar_r, bore: axle_bore, z0: collar_z0, z1: collar_z0 + collar_h)
collar seats(turn: 0deg, up: std.z, east: bot.u) a_c
collar_part := solid(collar.part)

// == The stand ===================================================================================
// A collar on A under its pinion, held on the rod by its M3 set screw, and an arm from it out
// under the socket to a pad on the stem's axis, which the socket's floor turns on, and the pivot's
// pin up from the pad into the floor's hole.  The pin keeps the pad under the socket's middle and
// the socket over the pad; it is loose in its hole, so the socket finds its own centre on the
// handle and the pad only bears it.  With the pin in the hole, the socket points the arm at the
// stem: tighten the set screw then.
stand_collar := Collar(r: collar_r, bore: axle_bore, z0: stand_z0, z1: a_pin_z0 - gap)
stand_collar seats(turn: 0deg, up: std.z, east: bot.u) a_c
stand_arm := Block(x0: -a_dist, x1: 0mm, y0: -6mm, y1: 6mm, z0: stand_z0, z1: stand_z1) in bot
stand_pad := Post(std.top.origin, r: 8mm, z0: stand_z0, z1: socket_z0)
pivot_pin := Post(std.top.origin, r: pivot_d / 2, z0: stand_z1, z1: socket_z0 + pivot_h)
stand_part := solid(stand_collar.part)
stand_arm.body union stand_part
stand_pad.body union stand_part
pivot_pin.body union stand_part
stand_collar.hole.body cut stand_part

// == The geared motor ============================================================================
// The 130 motor and its planetary stack, one unit (geared_motor.sv), its foot `unit_z0` up P and
// its x along the bot's.  It stands on three posts up from the base's floor, an M3 up through the
// floor and each post into a rib on the gearcase's outside; the frame's floor bears down on its
// lid, and its hole round the cradle's flats keeps the unit square.  Its output shaft turns as
// A's ring drives the last pinion back, and the motor `stage_ratio` cubed faster.
//
// The unit stands in a frame of its own, `unit_frame`: its origin on P at the foot's height, its
// axes the bot's.  (A frame the unit is drawn `in`, rather than the unit seated on P: seated, its
// every part's rows join the seat's, and solventc v0.1.14 then takes minutes, not a minute, to
// follow the handle's turns.)
unit_at := point
unit_at raised(d: unit_z0, along: std.z) p_c
unit_frame := frame
unit_frame.origin coincident unit_at
unit_frame.u parallel(sense: same) bot.u
unit_frame.v parallel(sense: same) bot.v
gearmotor := GearedMotor(roll: handle_open, out_rate: c3_rate, ear_z0: ear_z0 - unit_z0,
                         hub_len: fin_face, tooth_space: tooth_space, shaped: shaped,
                         checks: checks) in unit_frame
unit_feet := Footprint(depth: unit_z0 - floor_z1, floor_t: floor_z1 - floor_z0) in unit_frame
// The barrel's tooth space, swept up its screw over the unit's foot (planetary.sv: solventc
// v0.1.14 sweeps a screw only over a parameter the document declares), for the unit to cut.
unit_foot := plane
unit_foot.origin coincident unit_at
unit_foot.u parallel(sense: same) bot.u
unit_foot.v parallel(sense: same) bot.v
param teeth_s: Scalar over (0, 1)
tooth_space := solid({ p | some teeth_s: p in ToothSpace(unit_foot, z0: teeth_z0, z1: teeth_z1, s: teeth_s).section at teeth_s })
// its printed parts, as the export names them
construction motor_sun := solid(gearmotor.motor_sun)
construction carrier1 := solid(gearmotor.carrier1)
construction carrier2 := solid(gearmotor.carrier2)
construction carrier3 := solid(gearmotor.carrier3)
construction planet := solid(gearmotor.planet)
construction gearcase_part := solid(gearmotor.gearcase)
construction unit_lid_part := solid(gearmotor.lid)
construction strap_part := solid(gearmotor.strap_part)
motor_at := point
motor_at raised(d: motor_z, along: std.z) p_c

// == The last pinion =============================================================================
// A spur pinion of its own under the geared motor, a tooth toward A's ring: pressed up onto the
// output shaft's hexagon against its shoulder and screwed up into the shaft's end, its pan head in
// a counterbore in the pinion's underside (the unit's `out_socket`).
fin_pin := Gear(p_c, mesh: p_mesh, z: fin_z0, drives: 1, N: fin_n, m: m_fin, face: fin_face,
                bore: m3_clear)
construction pinion_part := solid(fin_pin.gear)
gearmotor.out_socket cut pinion_part

// The socket and the train turning with the handle, at the rates worked out with the drive, each
// read a turn open of the handle, so every joint stands at `handle_open` itself.  The socket turns
// with the handle but stands where it is, the handle screwing through.  (The geared motor turns
// its own, at the same rate.)
socket_turn := frame
socket_turn turns(1) valve.stem_down
fix(value == handle_open) socket_turn
a_turn := frame
a_turn turns(a_rate) a_spindle
fix(value == handle_open) a_turn
c3_turn := frame
c3_turn turns(c3_rate) p_spindle
fix(value == handle_open) c3_turn

socket := socket_part at socket_turn
a_compound := a_part at a_turn
pinion := pinion_part at c3_turn

// == The base: the gearbox's floor and walls =====================================================
// A box from the floor up to the keeper's top, hollowed: the keeper presses down into its walls'
// top, onto the tops of the bridge and the bulkhead.  Its floor and its walls are cut away where
// A's ring turns under the train (the whole of its +x end, down there), and a bridge standing on
// the collar and up to the keeper holds A's axle.  The bridge runs out to the end wall, and a
// bulkhead across the box through A ties it into both side walls as well: on its own the end
// wall, a thin plate over the ring's room, would flex under it.  The bulkhead stands from the
// ring's room up to the keeper, a print's clearance round the collar.
//
// The geared motor stands on three posts up from the floor (its `Footprint`), screwed up into
// them from under the floor, and a hole through the floor under the last pinion reaches its
// screw.  Four M3 screws down through the frame's floor hold the base up to the frame (below),
// the keeper and the unit's lid clamped between them.
base_box := RoundedBlock(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, r: box_r, z0: floor_z0,
                         z1: lid_z1) in bot
base_cavity := RoundedBlock(x0: box_x0 + wall, x1: box_x1 - wall, y0: box_y0 + wall,
                            y1: box_y1 - wall, r: box_r_in, z0: floor_z1, z1: lid_z1 + 1mm) in bot
base_shell := solid(base_box.body)
base_cavity.body cut base_shell

bridge := Block(x0: -a_dist, x1: box_x1 - wall, y0: -collar_r, y1: collar_r, z0: bridge_z0,
                z1: bridge_z1) in bot
bridge_boss := Post(a_c, r: collar_r, z0: bridge_z0, z1: bridge_z1)
bulkhead := Block(x0: -a_dist - wall, x1: -a_dist + wall, y0: box_y0, y1: box_y1,
                  z0: ring_z1 + 0.5mm, z1: bridge_z1) in bot
collar_room := Post(a_c, r: collar_r + gap, z0: ring_z1, z1: bridge_z0)
ring_r := 39mm                  // the room A's ring turns in, about A
ring_room := Post(a_c, r: ring_r, z0: floor_z0 - 1mm, z1: ring_z1 + 0.5mm)
ring_side := Block(x0: -a_dist, x1: box_x1 + 1mm, y0: box_y0 - 1mm, y1: box_y1 + 1mm,
                   z0: floor_z0 - 1mm, z1: ring_z1 + 0.5mm) in bot  // and the box's end over it
base_hole_a := Post(a_c, r: (axle_d + press) / 2, z0: bridge_z0 - 1mm, z1: bridge_z1 + 1mm)
pinion_reach := Post(p_c, r: m3_head_d / 2, z0: floor_z0 - 1mm, z1: floor_z1 + 1mm)

base := solid(base_shell)
bridge.body union base
bridge_boss.body union base
bulkhead.body union base
unit_feet.posts union base
collar_room.body cut base
ring_room.body cut base
ring_side.body cut base
base_hole_a.body cut base
unit_feet.holes cut base
pinion_reach.body cut base
claim gearmotor.gearcase clear(1mm) base_shell            // its ribs clear of the box's walls

// == The keeper: A's top and the base's walls ====================================================
// One print, a cross of beams 3 mm deep, held in the base by three pads slotted down over dovetail
// rails on its walls: it holds the top of A's axle, in a post on its top, and ties the walls.
//   - A spine runs from A out to the end wall over the bridge, and a cross beam over the bulkhead
//     from side wall to side wall: the keeper stands on the bridge and the bulkhead, and each of
//     the three ends is a pad `anchor_w` along its wall;
//   - up the middle of each pad's end, a dovetail slot, the rail grown `snug` all round: it
//     slides down over the rail, a light press on its flanks, and the rail holds the pad to its
//     wall and square along it, so the keeper can neither spread nor pull in off the walls;
//   - every beam runs into A's hub or its pad through a fillet in plan.
// Nothing else touches the walls.  The frame stands on the base's walls and its corner posts, A's
// post and the motor's cradle up through holes in its floor, and its floor bears down on the
// keeper's beams and the geared motor's lid.  It prints on its beams' undersides.
keeper_beam := 6mm
anchor_w := 14mm
anchor_d := 6mm                 // the pads' depth, in from the walls
// The rails, one up the middle of each wall's inside face where a pad meets it: a dovetail
// `rail_h` out from the wall, `rail_root` across at the wall, its flanks the mount's joint's
// `dove_angle` off square, up to the base's top; its foot slopes off the wall at 45deg, full depth
// at the keeper's underside, so the base prints it without support.
rail_h := 3mm
rail_root := 5mm
rail_tip := rail_root + 2 * rail_h * tan(dove_angle)
keeper_x1 := box_x1 - wall - snug
keeper_y0 := box_y0 + wall + snug
keeper_y1 := box_y1 - wall - snug
spine_beam := Block(x0: -a_dist, x1: keeper_x1, y0: -keeper_beam / 2, y1: keeper_beam / 2,
                    z0: lid_z0, z1: lid_z1) in bot
cross_beam := Block(x0: -a_dist - keeper_beam / 2, x1: -a_dist + keeper_beam / 2, y0: keeper_y0,
                    y1: keeper_y1, z0: lid_z0, z1: lid_z1) in bot
// Each joint where it stands on its wall's inside face, at the rail's middle, and its heading in
// from the wall, from the bot's x.
keeper_rails_at := [
  {x: box_x1 - wall, y: 0mm, a: 180deg},           // east, over the bridge
  {x: -a_dist, y: box_y0 + wall, a: 90deg},        // south, over the bulkhead
  {x: -a_dist, y: box_y1 - wall, a: -90deg},       // north, over the bulkhead
]
keeper_rails := solid()
// A's post on the keeper's top and its hole up into it
lid_post_r := axle_d / 2 + boss_wall
hub_a := Post(a_c, r: lid_post_r, z0: lid_z0, z1: lid_z1)
lid_post_a := Post(a_c, r: lid_post_r, z0: lid_z1, z1: post_z1)
lid_hole_a := Post(a_c, r: (axle_d + press) / 2, z0: lid_z0 - 1mm, z1: rod_z1)

// The keeper's pieces unioned whole, each named by its path in the keeper for its fillets:
// `keeper_fillet` in plan wherever a beam meets A's hub or a pad, all within the beams'
// depth, so none reaches up past the keeper's top to the frame's floor or down to the gears.
keeper_fillet := 3mm
keeper_part := solid()
spine_beam.body union keeper_part
cross_beam.body union keeper_part
hub_a.body union keeper_part
repeat r in keeper_rails_at {
  rail_at := point hint((-r.y, r.x)) in std.top
  std.origin distance(r.x, along: bot.u) rail_at
  std.origin distance(r.y, along: bot.v) rail_at
  joint := KeeperJoint()
  joint seats(turn: r.a, up: std.z, east: bot.u) rail_at
  joint.rail union base
  joint.rail union keeper_rails
  joint.slot cut keeper_part
  pad_bar := solid(joint.pad.body)
  pad_bar union keeper_part
}
claim keeper_rails clear(0.04mm) keeper_part          // the press: `snug` all round each rail
keeper_part.spine_beam round(r: keeper_fillet) keeper_part.hub_a
keeper_part.spine_beam round(r: keeper_fillet) keeper_part.pad_bar
keeper_part.cross_beam round(r: keeper_fillet) keeper_part.hub_a
keeper_part.cross_beam round(r: keeper_fillet) keeper_part.pad_bar
lid_post_a.body union keeper_part
lid_hole_a.body cut keeper_part

// == The frame: the electronics bay ==============================================================
// One print, the bot's backbone, printed on its floor: it stands on the base and the keeper, the
// boards stand on its floor, and the mount is glued onto the rail up its end wall.  Its floor has
// a hole round the keeper's post and round the motor's cradle, its ears and its strap, a print's
// clearance all round, so it goes down over the keeper with the motor strapped in.
case_floor := RoundedBlock(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, r: box_r, z0: lid_z1,
                           z1: case_z1) in bot
bay_box := RoundedBlock(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, r: box_r, z0: lid_z1,
                        z1: bay_z1) in bot
bay_room := RoundedBlock(x0: box_x0 + wall, x1: box_x1 - wall, y0: box_y0 + wall,
                         y1: box_y1 - wall, r: box_r_in, z0: lid_z1 - 1mm, z1: bay_z1 + 1mm) in bot
bay_shell := solid(bay_box.body)
bay_room.body cut bay_shell
floor_hole_a := Post(a_c, r: lid_post_r + gap, z0: lid_z1 - 1mm, z1: case_z1 + 1mm)
floor_hole_m := MotorCan(motor130_dims, grow: wall + 2 * gap, z0: lid_z1 - 1mm - motor_z,
                         z1: case_z1 + 1mm - motor_z)
floor_hole_m seats(turn: 0deg, up: std.z, east: bot.u) motor_at
floor_hole_ears := Block(x0: -strap_w / 2 - gap, x1: strap_w / 2 + gap,
                         y0: -strap_reach - gap, y1: strap_reach + gap,
                         z0: lid_z1 - 1mm - motor_z, z1: case_z1 + 1mm - motor_z)
floor_hole_ears seats(turn: 0deg, up: std.z, east: bot.u) motor_at

// the mount's rail, from its sloped foot up the end wall to its top, and the notch the snap's
// barb falls into, over the rail's lip
rail := Dovetail(x0: box_x1 - 1mm, x1: box_x1 + dove_h, w0: dove_root - 2mm * tan(dove_angle),
                 w1: dove_tip, z0: rail_z0, z1: bay_z1) in bot
rail_heel := UnderSlope(x0: box_x1, x1: box_x1 + dove_h + 1mm, z0: rail_z0, zb: rail_z0 - 1mm,
                        w: dove_tip + 2mm) in bot
rail_heel.body cut rail.body
rail_notch := Block(x0: box_x1 + dove_h - barb_h - slip, x1: box_x1 + dove_h + 1mm,
                    y0: -finger_w / 2 - gap, y1: finger_w / 2 + gap, z0: finger_z0 - slip,
                    z1: finger_z0 + barb_flat + barb_ramp + gap) in bot

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

frame_part := solid(case_floor.body)
bay_shell union frame_part
rail.body union frame_part
floor_hole_a.body cut frame_part
floor_hole_m.body cut frame_part
floor_hole_ears.body cut frame_part
grommet.body cut frame_part
usb_slot.body cut frame_part
jack_slot.body cut frame_part
rail_notch.body cut frame_part

// == The mount: the spine and the clamp's fixed half =============================================
// A print of its own, so that neither part needs support: the frame prints on its floor, the
// mount on its top, the clamp's and the spine's.  The spine stands on the end wall's outside from
// the frame's underside up to the clamp's top, and carries the frame up beside the valve to the
// clamp round the inlet hex and the pipe.
//
// It slides up onto the frame's rail from below, the rail in a dovetail slot up the spine's back,
// open at its top, until the rail's foot sits on the shelf closing the slot's bottom: the frame
// hangs on the shelf, the slope of both pressing the rail's flanks into the slot's.  There the
// barb at the foot of a finger in the slot's floor, pushed out by the rail's lip in the last few
// millimetres, snaps into the rail's notch, and holds the two together while the glue in the slot
// sets.  The dovetail's flanks take the handle's reaction sideways and outward, the glue the rest.
spine := Block(x0: box_x1 + slip, x1: spine_x1, y0: -spine_w / 2, y1: spine_w / 2, z0: lid_z1,
               z1: clamp_z1) in bot
clamp_main := Block(x0: -clamp_reach, x1: -split / 2, y0: -clamp_w / 2, y1: clamp_w / 2,
                    z0: clamp_z0, z1: clamp_z1) in bot
slot := Dovetail(x0: box_x1 - 1mm,
                 x1: slot_floor,
                 w0: dove_root - 2mm * tan(dove_angle) + 2 * slip / cos(dove_angle),
                 w1: dove_tip + 2 * slip * tan(dove_angle) + 2 * slip / cos(dove_angle),
                 z0: rail_z0 - 1mm, z1: clamp_z1 + 1mm) in bot
slot_heel := UnderSlope(x0: box_x1 - 1mm, x1: slot_floor + 1mm,
                        z0: rail_z0 - slip * sqrt(2) - 1mm, zb: rail_z0 - 2mm,
                        w: dove_tip + 2mm) in bot
slot_heel.body cut slot.body
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
// The base's four, up from posts in its corners, which stand up to the base's top beside the
// keeper, through the frame's floor, their heads on it in the bay's corners.  Each head is claimed
// clear of the bay's walls, and of the RedBoard, which stands over the -x, +y one.
repeat 2 as i {
  repeat 2 as j {
    bx := box_x0 + base_screw_inset + i * (box_x1 - box_x0 - 2 * base_screw_inset)
    by := box_y0 + base_screw_inset + j * (box_y1 - box_y0 - 2 * base_screw_inset)
    base_at := point hint((-by, bx)) in std.top
    std.origin distance(bx, along: bot.u) base_at
    std.origin distance(by, along: bot.v) base_at
    base_screw := ScrewPost(base_at, r: base_post_r, z0: floor_z1, z1: lid_z1, hole_d: pilot,
                            depth: 12mm)
    lid_screw := Post(base_at, r: m3_clear / 2, z0: lid_z1 - 1mm, z1: case_z1 + 1mm)
    base_head := Post(base_at, r: m3_head_d / 2, z0: case_z1, z1: case_z1 + m3_head_h)
    base_screw.post union base
    base_screw.hole cut base
    lid_screw.body cut frame_part
    claim base_screw.post clear(0.5mm) keeper_part
    claim base_screw.post clear(0.5mm) gearmotor.lid
    claim base_head.body clear(0.5mm) bay_shell
    claim base_head.body clear(0.5mm) redboard.board
    claim base_head.body clear(0.5mm) redboard.tails
  }
}

// The RedBoard's four M3s, self-tapping into posts on the frame's floor at its holes (boards.sv),
// the Uno's.  The posts are 5 mm across, an M3 standoff's size: the one by the SCL socket stands
// 3.6 mm off its SCL pin.  Each hole runs a millimetre on into the floor.
board_posts := BoardPosts(z0: lid_z1 - board_z, depth: board_z - case_z1 + 1mm)
board_posts seats(turn: 0deg, up: std.z, east: bot.u) board_at
board_posts.posts union frame_part
board_posts.holes cut frame_part

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
  cover_at := point hint((-c.y, c.x)) in std.top
  std.origin distance(c.x, along: bot.u) cover_at
  std.origin distance(c.y, along: bot.v) cover_at
  cover_screw := ScrewPost(cover_at, r: 4mm, z0: lid_z1, z1: bay_z1, hole_d: pilot, depth: 12mm)
  cover_screw.post union frame_part
  cover_screw.hole cut frame_part
  cover_hole := Post(cover_at, r: m3_clear / 2, z0: bay_z1 - 1mm, z1: bay_z1 + wall + 1mm)
  cover_hole.body cut cover_part
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
// A plate over the bay, screwed down into the four posts in its walls (above).
cover := RoundedBlock(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, r: box_r, z0: bay_z1,
                      z1: bay_z1 + wall) in bot
cover_part := solid(cover.body)

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
in std.top {
  board_c := point hint((-board_oy, board_ox))
  std.origin distance(board_ox, along: bot.u) board_c
  std.origin distance(board_oy, along: bot.v) board_c
  drv_c := point hint((-drv_cy, drv_cx))
  std.origin distance(drv_cx, along: bot.u) drv_c
  std.origin distance(drv_cy, along: bot.v) drv_c
  ina_c := point hint((-ina_cy, ina_cx))
  std.origin distance(ina_cx, along: bot.u) ina_c
  std.origin distance(ina_cy, along: bot.v) ina_c
}
board_at := point
board_at raised(d: board_z, along: std.z) board_c
redboard := RedBoardEsp32(redboard_dims)
redboard seats(turn: 0deg, up: std.z, east: bot.u) board_at
shield := Shield(shield_dims, u: redboard_dims, h: header_dims)
shield seats(turn: 0deg, up: std.z, east: bot.u) board_at
drv_at := point
drv_at raised(d: shield_z, along: std.z) drv_c
driver := Tb6612(tb6612_dims, h: header_dims)
driver seats(turn: 180deg, up: std.z, east: bot.u) drv_at
ina_at := point
ina_at raised(d: shield_z, along: std.z) ina_c
monitor := Ina219(ina219_dims, h: header_dims)
monitor seats(turn: -90deg, up: std.z, east: bot.u) ina_at
terminal := Block(x0: board_ox - pitch - 3.8mm, x1: board_ox - pitch + 3.8mm,
                  y0: board_oy + 6 * pitch, y1: board_oy + 10 * pitch, z0: shield_z,
                  z1: shield_z + 10mm) in bot
motor_terminal := Block(x0: board_ox + 15 * pitch - 3.8mm, x1: board_ox + 15 * pitch + 3.8mm,
                        y0: board_oy + pitch, y1: board_oy + 5 * pitch, z0: shield_z,
                        z1: shield_z + 10mm) in bot

// The boards in the bay: a mated cable's plug through each of the end wall's windows, and the
// boards, the RedBoard's parts and the pins' tails clear of the frame, the motor, its cradle and
// strap, and the cover, and of one another.  The motor and its strap clear the cover over them, and
// the cradle and its strap clear the frame, whose floor goes down over them.
claim redboard.usb_plug clear(0.2mm) frame_part
claim redboard.jack_plug clear(0.2mm) frame_part
claim redboard.parts clear(0.5mm) frame_part
claim redboard.tails clear(0.5mm) frame_part
claim redboard.board clear(1mm) gearmotor.cradle
claim redboard.board clear(1mm) bay_shell
claim redboard.board clear(1mm) gearmotor.motor.motor
claim redboard.parts clear(1mm) gearmotor.motor.motor
claim redboard.tails clear(0.5mm) gearmotor.motor.motor
claim shield.board clear(1mm) gearmotor.motor.motor
claim shield.board clear(1mm) gearmotor.cradle
claim driver.board clear(1mm) gearmotor.motor.motor
claim gearmotor.motor.motor clear(1mm) cover_part
claim gearmotor.strap_part clear(1mm) cover_part
claim gearmotor.cradle clear(0.25mm) frame_part
claim gearmotor.strap_part clear(0.5mm) frame_part
claim redboard.parts clear(1mm) gearmotor.cradle
claim redboard.parts clear(1mm) gearmotor.strap_part
claim shield.board clear(1mm) gearmotor.strap_part
claim shield.headers clear(0.5mm) gearmotor.cradle
claim shield.headers clear(0.5mm) gearmotor.strap_part
claim driver.board clear(1mm) gearmotor.cradle
claim driver.board clear(1mm) gearmotor.strap_part
claim driver.headers clear(0.5mm) gearmotor.strap_part
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
// With `checks` 1, every part's clearance is judged, which builds every shaped part (the geared
// motor judges its own inside).  The socket and the stand are judged against the handle open, A's
// compound against it closed: the socket turns with the handle and its hole is the same at every
// height, so only the handle's height changes, and each comes nearest at that end.  Gears in mesh
// run 0.15 mm clear a flank; parts that rest on one another (the geared motor on its posts and
// under the frame, its pinion on its shaft, the keeper in the base, the frame on both, the collar
// on the bridge, the socket on the stand's pad) are not claimed clear; the mount clears the base,
// whose end wall stands under its foot's edge.
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
  claim a_compound clear(0.3mm) keeper_part
  claim a_compound clear(0.25mm) stand_part
  claim pivot_pin.body clear(0.4mm) socket_part         // loose in its hole, under its roof
  claim a_compound clear(0.25mm) collar.part
  claim a_compound clear(0.05mm) pinion                 // A's ring and the last pinion
  claim pinion clear(1mm) collar.part
  claim pinion clear(0.3mm) base                        // over the floor, inside the posts
  claim pinion clear(0.25mm) gearmotor.gearcase         // under the unit's foot
  claim a_compound clear(0.3mm) gearmotor.gearcase      // the ring under the unit's foot
  claim gearmotor.gearcase clear(0.5mm) keeper_part
  claim gearmotor.lid clear(0.5mm) base
  claim gearmotor.lid clear(0.5mm) keeper_part
  claim mount_part clear(0.05mm) valve.supply_pipe.bar
  claim cap_part clear(0.05mm) valve.supply_pipe.bar
  claim mount_part clear(0.15mm) valve.body.casting
  claim cap_part clear(0.15mm) valve.body.casting
  claim mount_part clear(2mm) valve.bonnet.bonnet
  claim mount_part clear(2mm) valve.packing_nut.bar
  claim frame_part clear(2mm) valve.bonnet.bonnet
  claim frame_part clear(2mm) valve.packing_nut.bar
  claim keeper_part clear(2mm) valve.bonnet.bonnet
  claim keeper_part clear(2mm) valve.packing_nut.bar
  claim mount_part clear(0.1mm) base
  claim mount_part clear(0.1mm) keeper_part
  claim base clear(2mm) valve.bonnet.bonnet
  claim base clear(2mm) valve.packing_nut.bar
  claim base clear(0.3mm) valve.star_handle.handle
  claim mount_part clear(1mm) valve.union.nut.bar
  claim cap_part clear(1mm) valve.union.nut.bar
  claim mount_part clear(1mm) valve.body.boss.bar
  claim cap_part clear(1mm) valve.body.boss.bar
}
