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
//     above: a stack of three planetary stages with helical teeth on P, under the 130 motor, its
//     last carrier's pinion on the ring; the stack turns in a barrel up through the base, its
//     teeth the stages' ring gear, and the base's floor stops short of A's ring, a bridge and a
//     bulkhead across it holding A;
//   - the **keeper**, the gearbox's lid, presses down into the base's walls: it holds A's top
//     and the motor, on a plate spigoted into the barrel, in a cradle with a strap across its
//     end bell;
//   - the **frame** is the electronics bay standing on the base and the keeper (beside the
//     motor, the RedBoard with a perfboard shield on it carrying the motor driver and its
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
use std.solids (cut, union)
use std.place (vertical, horizontal, coords, seats, raised)
use std.motion (turns)
use std.shapes
use std.rounds
use std.rounds (round)
use radiator_valve (RadiatorValve, handle_dims, body_dims, pipe_dims, handle_gap, stem_travel)
use radiator_valve (open_turns)
use radiator_valve (StarOutline, StarHandle, HexBar, RoundBar)
use gears (ShapedSpur, ShapedHelical)
use motor130 (Motor130, MotorCan, MotorSizes, motor130_dims, motor130_free, motor130_stall_torque)
use boards (RedBoardEsp32, Shield, Tb6612, Ina219, redboard_dims, uno_holes, shield_dims)
use boards (tb6612_dims, ina219_dims, header_dims, pitch)

shaped := 1                    // 1: shape the gears and the socket; 0: blanks, for a quick look
checks := 0                    // 1: judge every clearance (needs `shaped`; ~2 minutes)

// == Stock =======================================================================================
// Drill rod.  The gears turn on fixed rods; the housing holds the rods, each in posts of its own.
axle_d := 0.5in                 // A, the socket pinion's axle
p_rod_d := 4mm                  // P, the planetary stack's: its carriers turn on it
pin_d := 3mm                    // the planets' pins: 3 x 10 mm hardened dowel pins
pin_len := 10mm

// == Fits for an FDM print =======================================================================
run := 0.35mm                   // a printed bore turning on drill rod, over the rod
press := 0.05mm                 // a printed hole a rod is pressed into (drill or ream to fit)
gap := 0.3mm                    // between printed faces that meet or pass
thin := 0.15mm                  // each gear's teeth thinned: 0.3 mm backlash a mesh
chamfer := 0.4mm                // each gear's tips chamfered at both faces, 45deg
bond := 0.25mm                  // a compound's pinion run up into its gear, so the two print as one
wall := 2.4mm                   // six 0.4 mm perimeters
boss_wall := 2 * wall           // a post's wall round a rod pressed into it
pilot := 2.5mm                  // an M3 screw's self-tapping hole in a print
m3_clear := 3.4mm
m3_head_d := 5.6mm              // an M3 pan head (ISO 7045, and a self-tapper's), across and tall
m3_head_h := 2.4mm
m4_clear := 4.6mm
m4_nut_af := 7.3mm              // an M4 nut's pocket across the flats
split := 1mm                    // the clamp's halves stand apart this much before the bolts close it
slip := 0.15mm                  // a glued joint's printed faces, apart each side
snug := 0.05mm                  // a printed part pressed into a printed one, apart each side: a
                                // light press as an FDM print comes out (its outsides print a
                                // little fat and its insides a little lean); sand to fit

axle_bore := axle_d + run       // A's compound's bore, and the collars'
p_bore := p_rod_d + run         // every carrier's bore

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

// The gear train, motor to A: a stack of three planetary stages on the motor's axis, P, under the
// motor, and the stack's output, a spur pinion under its last carrier, driving A's ring.  Each
// stage is a sun, three planets on steel pins in a carrier, and the ring round them, fixed: one
// internal gear, the barrel the stack turns in, runs the whole stack's height, so every planet
// screws down it into place.  The first sun is pressed on the motor's shaft; each carrier carries
// the next stage's sun under it, and the last the pinion.  The stages are alike: a 14-tooth sun,
// 16-tooth planets and the 46-tooth ring, (14 + 46) / 3 a whole number, so three planets spaced
// evenly mesh both.
//
// The teeth are helical, 25deg, for quiet: each tooth comes into mesh across the face rather than
// all along it at once, and a planet's 6 mm face overlaps a whole pitch, so one tooth pair is
// always in full contact.  The suns are left-handed, the planets and the ring right-handed.  At
// 25deg a 14-tooth sun keeps its involute down to where the planets' tips reach, so no tooth is
// shifted and the stack's centre distances are nominal.  Module 0.8 (normal) throughout: the
// finest an 0.4 mm nozzle prints well, with the gear's teeth loaded far under what PETG bears.
//
// The ring and the socket's spur stages stay: they turn slowly (A 45 rpm at most, the pinion 180),
// where a spur mesh is quiet, and a helix on the socket would push it up and down the handle.
pa := 20deg
pin_shift := 0.3
m_fin := 1.5mm                  // the ring and its pinion
fin_n := 12                     // the last pinion, under the stack's last carrier
ring_n := 48
cd_fin := m_fin * (fin_n + ring_n) / 2                  // 45 mm, P to A
m_stack := 0.8mm                // the stack's normal module
helix := 25deg
sun_n := 14
planet_n := 16
ring_teeth := 46                // the barrel's internal teeth
claim ring_teeth == sun_n + 2 * planet_n
stack_planets := 3
claim (sun_n + ring_teeth) / stack_planets == 20             // the planets spaced evenly
m_t := m_stack / cos(helix)                                  // the transverse module, 0.883 mm
orbit := m_t * (sun_n + planet_n) / 2                        // P to each planet, 13.24 mm
ring_pitch := m_t * ring_teeth / 2                           // 20.30 mm
ring_tip_r := ring_pitch - m_stack                           // the barrel's bore, 19.50 mm
ring_root_r := ring_pitch + 1.25 * m_stack                   // 21.30 mm
sun_hand := -1
planet_hand := 1
// the planets' steel pins, pressed into their carrier's plate, and the rod P's carriers turn on
pin_seat := 4mm
pin_wall := m_stack * (planet_n / (2 * cos(helix)) - 1.25) - (pin_d + run) / 2
claim pin_wall >= 1.5mm                                      // a planet's roots to its bore
sun_wall := m_stack * (sun_n / (2 * cos(helix)) - 1.25) - (p_rod_d + run) / 2
claim sun_wall >= 1.5mm                                      // a sun's roots to its bore

// P stands where the motor stood, beside the electronics bay's boards, and `cd_fin` from A; its
// pinion stands a tooth toward A at `pa_bearing` from the bot's x, A's ring a space toward P.
p_y := -12.47mm
p_x := -a_dist - sqrt(cd_fin ^ 2 - p_y ^ 2)                    // -103.24 mm
pa_bearing := atan2(-p_y, -a_dist - p_x)                       // 16.1deg

// Each stage turns its carrier one turn for `stage_ratio` of its sun's, the same way: 1 + 46 / 14.
stage_ratio := 1 + ring_teeth / sun_n
gear_ratio := stage_ratio ^ 3 * ring_n / fin_n               // motor turns an A turn: 315
handle_ratio := gear_ratio * socket_n / a_n                  // a handle turn: 840

// What it does, from the motor's figures: printed meshes at ~0.9 each.  A planetary stage loses
// only on the power its meshes roll through, the sun turning against its carrier: with the ring
// fixed, (1 + 0.9 ^ 2 (i - 1)) / i of it reaches the carrier, 0.854 here.  Then the ring's and the
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
// handle makes about the downward stem): A 64/24, the last carrier and its pinion back from A's
// ring, reversed, and each carrier above it and the motor `stage_ratio` faster, the same way.
// A planet turns on its pin against its carrier as the ring turns against it, 46/16 the other way.
a_rate := socket_n / a_n
c3_rate := -a_rate * ring_n / fin_n
c2_rate := c3_rate * stage_ratio
c1_rate := c2_rate * stage_ratio
motor_rate := c1_rate * stage_ratio
claim motor_rate == -handle_ratio

// == Heights =====================================================================================
// From the floor up: A's ring and the last pinion beside it, then the stack's three stages, the
// lid (the keeper's plate), the electronics bay and its cover.  Each stage is its carrier's plate
// and, a print's clearance over it, its planets, a print's clearance under the next carrier's
// plate; each sun hangs under the plate over its stage, from level with its planets' undersides.
// The barrel's teeth run from the last carrier's plate up past the first stage's planets, and a
// plain counterbore over them takes the keeper's spigot.  The motor stands face down on the
// keeper's plate, its shaft down through it to the first sun and on into the first carrier's bore,
// over the top of P's rod; the boards stand beside it, so the bay is the motor's height.
floor_z0 := -3.1mm              // the base's floor, round P only: A's ring turns beside it
floor_z1 := floor_z0 + 6mm
ring_z0 := 3mm                  // the ring's teeth; the web under it runs down to A's pinion
ring_z1 := ring_z0 + 10mm
fin_z0 := ring_z0 + 0.5mm       // the last pinion, its face up to the last carrier's plate
plate_t := 4.5mm                // a carrier's plate, its pins pressed `pin_seat` down into it
planet_face := 6mm
stage_h := plate_t + gap + planet_face + gap               // 11.1 mm
c3_z0 := ring_z1 + 0.5mm        // the last carrier's plate, half a millimetre over A's ring
c2_z0 := c3_z0 + stage_h
c1_z0 := c2_z0 + stage_h
zb3 := c3_z0 + plate_t + gap    // each stage's planets' undersides, and its sun's
zb2 := c2_z0 + plate_t + gap
zb1 := c1_z0 + plate_t + gap
band_z0 := c3_z0                // the barrel's teeth
band_z1 := zb1 + planet_face + gap
spigot_z0 := band_z1 + gap      // the keeper's spigot, down into the counterbore
lid_z0 := band_z1 + 2mm
lid_z1 := lid_z0 + 3mm
claim pin_len - pin_seat <= planet_face                     // each pin's top under its planet's
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
// A's axle stands up into a post on the keeper's top, its hole blind under a 1 mm roof; P's rod
// stands in the floor and up through the carriers into the first, a millimetre under the end of
// the motor's shaft, which runs on down into the same bore.
post_z1 := lid_z1 + 2.5mm
rod_z1 := post_z1 - 1mm
p_rod_z1 := motor_z - motor130_dims.shaft_len - 1mm
claim p_rod_z1 >= zb2 + 4mm     // the first carrier turns on 4 mm of the rod, or more
stand_z1 := socket_z0 - gap
stand_z0 := stand_z1 - 4mm
// The lid is the keeper's plate, pressed down into the top of the base, whose walls run up past
// the gears to its top; the frame (the electronics bay) stands on the base and the keeper, its own
// floor `case_z1` thick round the keeper's posts and the motor's cradle, which come up through it.
case_z1 := lid_z1 + wall
// The mount's joint: the frame's rail leaves the end wall 2 mm up from the frame's underside, its
// foot sloped up and out at 45deg so it prints from the wall, and stands on the mount's shelf,
// sloped so under it, the mount's foot flush with the frame's underside; the snap's finger hangs
// in the slot's floor, its barb's underside 2.5 mm over the foot at the rail's face, a lip of it.
rail_z0 := lid_z1 + 2mm
finger_z0 := rail_z0 + dove_h + 2.5mm
motor_z := lid_z1                                       // the motor's front face, on the keeper
claim motor_z - motor130_dims.shaft_len >= c1_z0 - 1mm  // the shaft's end in the first carrier
claim motor_z - motor130_dims.boss_h - gap >= spigot_z0 + 1mm
board_z := lid_z1 + 6mm                                 // the RedBoard's underside, on its posts
shield_z := board_z + shield.top                          // the shield's top face
bay_z1 := motor_z + motor130_dims.len + motor130_dims.back_h + 3mm  // room over it for its leads
// The motor's strap: a bar `wall` thick across the end bell's back, its boss up through it, and a
// leg down each side past the flats onto an ear up from the cradle's flat wall, where a
// countersunk M3 draws it down.  The ears stand `strap_lift` short of the legs, so the strap
// always bears on the end bell, never on them.  The ears swell out from the cradle's flats to
// `ear_t` over a 45deg underside that starts clear over the RedBoard's edge beside the cradle.
strap_top := motor_z + motor130_dims.len + wall
strap_h := 6mm                  // the legs, from the strap's top down
strap_w := 8mm                  // across the flats' middle, clear of the round sides' terminals
strap_lift := 0.5mm
ear_t := 6mm                    // the ears, out from the cradle's pocket
ear_z0 := board_z + 5mm         // where the ears start to swell out of the cradle's flats
ear_z1 := strap_top - strap_h - strap_lift
strap_screw_y := motor130_dims.flats / 2 + gap + ear_t / 2   // off the motor's axis
clamp_z0 := body_dims.inlet_top - body_dims.inlet_h     // the inlet hex's underside
clamp_z1 := clamp_z0 + 31.7mm

// == Plan ========================================================================================
// The housing's outline, the clamp and the spine, in plan (x, y) in the bot's frame: the box the
// base, the lid, the bay and the cover all share.  Its -y wall takes in the stack's barrel, which
// runs into it; its +y side stands 4.4 mm off the RedBoard's 2.3 in across the bay.
box_x0 := -136mm
box_x1 := -35mm
box_y0 := -38mm
box_y1 := 64mm
// The stack's barrel about P: its teeth's root, a counterbore a print's clearance over it for the
// keeper's spigot, and a wall round that; the keeper's plate over it stands on the barrel's top.
cb_r := ring_root_r + gap
barrel_r := cb_r + wall
carrier_r := ring_tip_r - 0.5mm                             // the carriers' plates, in its bore
lid_disc_r := cb_r + 0.9mm                                  // the keeper's plate over P
claim box_y0 + 1mm <= p_y - barrel_r                         // the barrel within the box's -y wall
claim box_y0 + wall + 0.5mm <= p_y - lid_disc_r
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
base_post_r := base_screw_inset - wall + 0.5mm
// The RedBoard and its shield (boards.sv) stand beside the motor, by the RedBoard's frame, its
// power header's first pin at (board_ox, board_oy): its jack's mouth a millimetre in from the end
// wall's inside face, its edge 2 mm off the motor's cradle's flat.
cradle_f := motor130_dims.flats / 2 + wall + gap        // the cradle's flats, off the motor's axis
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

// A block square to the world: x0..x1, y0..y1, z0..z1.
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

// A dovetail up z from z0 to z1 about y = 0, standing out along x: `w0` across at x0, `w1` at x1.
component Dovetail(x0: Length, x1: Length, w0: Length, w1: Length, z0: Length, z1: Length) {
  a := At(x: x0, y: -w0 / 2)
  b := At(x: x1, y: -w1 / 2)
  c := At(x: x1, y: w1 / 2)
  d := At(x: x0, y: w0 / 2)
  body := solid(std.solids.Prism(face(a.p, b.p, c.p, d.p, -> close), from: z0, to: z1))
}

// A bar from (x0, y0) to (x1, y1), `w` wide, from z0 to z1.
component Bar(x0: Length, y0: Length, x1: Length, y1: Length, w: Length, z0: Length, z1: Length) {
  len := sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
  nx := -(y1 - y0) / len * w / 2
  ny := (x1 - x0) / len * w / 2
  a := At(x: x0 - nx, y: y0 - ny)
  b := At(x: x1 - nx, y: y1 - ny)
  c := At(x: x1 + nx, y: y1 + ny)
  d := At(x: x0 + nx, y: y0 + ny)
  body := solid(std.solids.Prism(face(a.p, b.p, c.p, d.p, -> close), from: z0, to: z1))
}

// What stands under a 45deg slope across y = 0, `w` wide: from x0 to x1, under z0 + (x - x0), down
// to zb.
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

// A dovetail rail for the keeper, drawn in its own frame (its origin on a wall's inside face, x in
// from the wall, y along it), and the slot in the keeper's pad that slides down over it: the rail
// up from its sloped foot to the base's top, and the slot the rail grown `snug` all round.
component KeeperRail() {
  rail_z0 := lid_z0 - rail_h
  tail := Dovetail(x0: -1mm, x1: rail_h, w0: rail_root - 2mm * tan(dove_angle), w1: rail_tip,
                   z0: rail_z0, z1: lid_z1)
  heel := UnderSlope(x0: 0mm, x1: rail_h + 1mm, z0: rail_z0, zb: rail_z0 - 1mm, w: rail_tip + 2mm)
  groove := Dovetail(x0: -1mm, x1: rail_h + snug,
                     w0: rail_root - 2mm * tan(dove_angle) + 2 * snug / cos(dove_angle),
                     w1: rail_tip + 2 * snug * tan(dove_angle) + 2 * snug / cos(dove_angle),
                     z0: lid_z0 - 1mm, z1: lid_z1 + 1mm)
  rail := solid(tail.body)
  heel.body cut rail
  slot := solid(groove.body)
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

// Both ears, and the M3's self-tapping hole down into each from its top.
component StrapEars(s: MotorSizes, z0: Length, z1: Length) {
  plus := Ear(s, side: 1, z0: z0, z1: z1)
  minus := Ear(s, side: -1, z0: z0, z1: z1)
  at_plus := At(x: 0mm, y: strap_screw_y)
  at_minus := At(x: 0mm, y: -strap_screw_y)
  hole_plus := Post(at_plus.p, r: pilot / 2, z0: z1 - 8mm, z1: z1 + 1mm)
  hole_minus := Post(at_minus.p, r: pilot / 2, z0: z1 - 8mm, z1: z1 + 1mm)
  body := solid(plus.body)
  minus.body union body
  holes := solid(hole_plus.body)
  hole_minus.body union holes
}

// The motor's strap, drawn with its top face on std.top and its material under it, the motor's
// axis std.z: a bar `wall` thick over the end bell, its boss up through a hole in it in a ring 2 mm
// wide (the bar is narrower than the boss), and its legs
// `strap_h` down past the flats, the can's section grown a print's clearance between them; an M3
// through each leg, countersunk flush (a flat head 6 mm across, 90deg).  It prints on its top.
component MotorStrap(s: MotorSizes) {
  y1 := s.flats / 2 + gap + ear_t
  bar := Block(x0: -strap_w / 2, x1: strap_w / 2, y0: -y1, y1: y1, z0: -strap_h, z1: 0mm)
  ring := Post(std.top.origin, r: s.back_d / 2 + gap + 2mm, z0: -wall, z1: 0mm)
  pocket := MotorCan(s, grow: gap, z0: -strap_h - 1mm, z1: -wall)
  boss := Post(std.top.origin, r: s.back_d / 2 + gap, z0: -wall - 1mm, z1: 1mm)
  at_plus := At(x: 0mm, y: strap_screw_y)
  at_minus := At(x: 0mm, y: -strap_screw_y)
  hole_plus := Post(at_plus.p, r: m3_clear / 2, z0: -strap_h - 1mm, z1: 1mm)
  hole_minus := Post(at_minus.p, r: m3_clear / 2, z0: -strap_h - 1mm, z1: 1mm)
  in std.top {
    sink_plus_rim := radius(3mm) circle(center: at_plus.p)
    sink_minus_rim := radius(3mm) circle(center: at_minus.p)
  }
  sink_plus := solid(std.solids.Drafted(face(sink_plus_rim), from: -1.7mm, to: 0.5mm, draft: 45deg))
  sink_minus := solid(std.solids.Drafted(face(sink_minus_rim), from: -1.7mm, to: 0.5mm,
                                         draft: 45deg))
  part := solid(bar.body)
  ring.body union part
  pocket.body cut part
  boss.body cut part
  hole_plus.body cut part
  hole_minus.body cut part
  sink_plus cut part
  sink_minus cut part
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

// A printed helical gear of the stack seated on an axle: its figure (gears.sv) with its origin
// `z` up the axle from `c`, its axis up the world's z, turned `turn` from the world's x (its cut
// space, centred on its own +v at its underside, then at `turn + 90deg`).  `add` and `thin_by`
// are the figure's: an internal gear's cutter is its tooth count with `add` 1.25 and `thin_by`
// -thin.  Gears of one size and face are one figure, shaped once.
component Helical(c: point, z: Length, turn: Angle, N: Int, hand: Int, add: Scalar,
                  thin_by: Length, face: Length, bore: Length, chamfer_by: Length) {
  at := point
  at raised(d: z, along: std.z) c
  g := ShapedHelical(N: N, m: m_stack, phi: pa, beta: helix, hand: hand, shift: 0, add: add,
                     thin: thin_by, z0: 0mm, z1: face, bore: bore, shaped: shaped,
                     chamfer: chamfer_by)
  g seats(turn: turn, up: std.z, east: std.x) at
  construction gear := solid(g.gear)
}

// How a stage's gears stand at rest, its planets' and its sun's undersides at `zb`: its planets
// at bearings `bot_turn + k 120deg` from P in the world, `planet(k)`'s turn, and its sun's, `sun`,
// each the turn its Helical is seated at.  The barrel's teeth stand as its cutter was seated
// (`ring_turn`, at `band_z0`), and climb a right hand's turn to `zb`.  The planet's tooth that
// points out at the barrel stands in a tooth space of it, turned by as much as the space is from
// the planet's bearing, in their ratio; its sun stands so that the planet's space toward it holds
// one of the sun's teeth, as rolling would bring them.  The three planets' meshes agree because
// (14 + 46) / 3 is whole.
component Phasing(zb: Length, k: Int) {
  ring_at := ring_turn + planet_hand * (zb - band_z0) * tan(helix) / ring_pitch * 180deg / pi
  bearing0 := bot_turn
  bearing := bot_turn + k * 120deg
  off := 90deg + ring_at + 180deg / ring_teeth - bearing0    // the barrel's space off planet 0
  sun := (180deg * planet_n - off * ring_teeth) / sun_n - 90deg + bearing0
  planet := bearing + 90deg - (90deg + sun + 180deg / sun_n - bearing) * sun_n / planet_n
}

// A carrier's plate on P, `c_z0` up, its bore and its three pins' holes, blind `pin_seat` down
// from its top, at bearings `bot_turn + k 120deg`: the plate's solid and its holes', each cut from
// the compound it is in.
component CarrierPlate(c: point, c_z0: Length) {
  plate := Post(c, r: carrier_r, z0: c_z0, z1: c_z0 + plate_t)
  holes := solid()
  repeat 3 as k {
    hole_at := At(x: pw_x + orbit * cos(bot_turn + k * 120deg),
                  y: pw_y + orbit * sin(bot_turn + k * 120deg))
    hole := Post(hole_at.p, r: (pin_d + press) / 2, z0: c_z0 + plate_t - pin_seat,
                 z1: c_z0 + plate_t + 1mm)
    hole.body union holes
  }
  bore := Post(c, r: p_bore / 2, z0: c_z0 - 20mm, z1: c_z0 + plate_t + 1mm)
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
// A, the socket's pinion's and the ring's, is `a_dist` out along the bot's -x; P, the stack's and
// the motor's, is `cd_fin` from it at (p_x, p_y), its last pinion on the ring.
a_r := -a_dist
pw_x := p_x * cos(bot_turn) - p_y * sin(bot_turn)           // P in the world's plan
pw_y := p_x * sin(bot_turn) + p_y * cos(bot_turn)
in std.top {
  a_c := point hint((a_r * cos(bot_turn), a_r * sin(bot_turn)))
  a_c coords(du: a_r * cos(bot_turn), dv: a_r * sin(bot_turn)) std.top
  p_c := point hint((pw_x, pw_y))
  p_c coords(du: pw_x, dv: pw_y) std.top
}
// each axle's spindle, a line up it, for the joints that show the train turning
a_up := point
a_up raised(d: 10mm, along: std.z) a_c
p_up := point
p_up raised(d: 10mm, along: std.z) p_c
construction a_spindle := line(a_c, a_up)
construction p_spindle := line(p_c, p_up)

// The rods: A held in the base's bridge and up into its post on the keeper, down to the stand; P
// in the floor, up through the carriers into the first.
axle_a := Post(a_c, r: axle_d / 2, z0: stand_z0, z1: rod_z1)
rod_at_p := Post(p_c, r: p_rod_d / 2, z0: floor_z0, z1: p_rod_z1)

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
a_pin := Gear(a_c, z: a_pin_z0, bearing: 0deg, drives: 1, N: a_n, m: m_socket,
              face: web_z0 - a_pin_z0 + bond, bore: axle_bore, spokes: 0, hub: 0mm, web: 0mm)
ring_gear := Gear(a_c, z: ring_z0, bearing: pa_bearing, drives: 0, N: ring_n, m: m_fin,
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

// == The planetary stack =========================================================================
// Three stages on P, from the motor down: the motor's sun, pressed on its shaft; under each
// carrier's plate the next stage's sun, run `bond` up into the plate so the two print as one part,
// and under the last carrier's the pinion that drives A's ring.  Every carrier turns on P's rod.
// Each plate holds its stage's three planets on steel pins pressed down into it, the planets a
// print's clearance over it and under the next carrier's plate, which keeps them on their pins.
// The barrel round them all is the base's (below).  Each stage's gears stand as `Phasing` works
// out, so every planet meshes its sun and the barrel at rest.
ring_turn := 0deg               // the barrel's cutter, seated at `band_z0`
ph3 := Phasing(zb: zb3, k: 0)
ph2 := Phasing(zb: zb2, k: 0)
ph1 := Phasing(zb: zb1, k: 0)

// the first stage's sun, pressed on the motor's shaft
sun1 := Helical(p_c, z: zb1, turn: ph1.sun, N: sun_n, hand: sun_hand, add: 1, thin_by: thin,
                face: planet_face, bore: motor130_dims.shaft_d - 0.1mm, chamfer_by: chamfer)
construction motor_sun := solid(sun1.gear)

// the first carrier, and the second stage's sun under it
plate1 := CarrierPlate(p_c, c_z0: c1_z0)
sun2 := Helical(p_c, z: zb2, turn: ph2.sun, N: sun_n, hand: sun_hand, add: 1, thin_by: thin,
                face: c1_z0 - zb2 + bond, bore: p_bore, chamfer_by: chamfer)
construction carrier1 := solid(plate1.plate.body)
sun2.gear union carrier1
plate1.bore.body cut carrier1
plate1.holes cut carrier1

// the second, and the third stage's sun under it
plate2 := CarrierPlate(p_c, c_z0: c2_z0)
sun3 := Helical(p_c, z: zb3, turn: ph3.sun, N: sun_n, hand: sun_hand, add: 1, thin_by: thin,
                face: c2_z0 - zb3 + bond, bore: p_bore, chamfer_by: chamfer)
construction carrier2 := solid(plate2.plate.body)
sun3.gear union carrier2
plate2.bore.body cut carrier2
plate2.holes cut carrier2

// the last, and the spur pinion under it, a tooth toward A's ring
plate3 := CarrierPlate(p_c, c_z0: c3_z0)
fin_pin := Gear(p_c, z: fin_z0, bearing: pa_bearing, drives: 1, N: fin_n, m: m_fin,
                face: c3_z0 - fin_z0 + bond, bore: p_bore, spokes: 0, hub: 0mm, web: 0mm)
construction carrier3 := solid(plate3.plate.body)
fin_pin.gear union carrier3
plate3.bore.body cut carrier3
plate3.holes cut carrier3

// One planet, the last stage's first, at rest: the part printed nine times.
planet_at := At(x: pw_x + orbit * cos(ph3.bearing), y: pw_y + orbit * sin(ph3.bearing))
planet_gear := Helical(planet_at.p, z: zb3, turn: ph3.planet, N: planet_n, hand: planet_hand,
                       add: 1, thin_by: thin, face: planet_face, bore: pin_d + run,
                       chamfer_by: chamfer)
construction planet := solid(planet_gear.gear)

// The socket and the train turning with the handle, at the rates worked out with the drive, each
// read a turn open of the handle, so every joint stands at `handle_open` itself.  The socket turns
// with the handle but stands where it is, the handle screwing through.
socket_turn := frame
socket_turn turns(1) valve.stem_down
fix(value == handle_open) socket_turn
a_turn := frame
a_turn turns(a_rate) a_spindle
fix(value == handle_open) a_turn
c3_turn := frame
c3_turn turns(c3_rate) p_spindle
fix(value == handle_open) c3_turn
c2_turn := frame
c2_turn turns(c2_rate) p_spindle
fix(value == handle_open) c2_turn
c1_turn := frame
c1_turn turns(c1_rate) p_spindle
fix(value == handle_open) c1_turn
motor_turn := frame
motor_turn turns(motor_rate) p_spindle
fix(value == handle_open) motor_turn

socket := socket_part at socket_turn
a_compound := a_part at a_turn
carrier_3 := carrier3 at c3_turn
carrier_2 := carrier2 at c2_turn
carrier_1 := carrier1 at c1_turn
sun_1 := motor_sun at motor_turn

// Every planet and its pin: each turned on its pin against its carrier, then carried round P with
// it, the stage's carrier's rate.
stages := [
  {zb: zb3, rate: c3_rate},
  {zb: zb2, rate: c2_rate},
  {zb: zb1, rate: c1_rate},
]
repeat st in stages {
  orbit_turn := frame
  orbit_turn turns(st.rate) p_spindle
  fix(value == handle_open) orbit_turn
  repeat 3 as k {
    ph := Phasing(zb: st.zb, k: k)
    pc := At(x: pw_x + orbit * cos(ph.bearing), y: pw_y + orbit * sin(ph.bearing))
    pc_up := point
    pc_up raised(d: 10mm, along: std.z) pc.p
    construction pc_spindle := line(pc.p, pc_up)
    pg := Helical(pc.p, z: st.zb, turn: ph.planet, N: planet_n, hand: planet_hand, add: 1,
                  thin_by: thin, face: planet_face, bore: pin_d + run, chamfer_by: chamfer)
    pin := Post(pc.p, r: pin_d / 2, z0: st.zb - gap - pin_seat,
                z1: st.zb - gap - pin_seat + pin_len)
    spin := frame
    spin turns(-st.rate * ring_teeth / planet_n) pc_spindle
    fix(value == handle_open) spin
    spun := pg.gear at spin
    planet_shown := spun at orbit_turn
    pin_shown := pin.body at orbit_turn
    when checks == 1 {
      claim pg.gear clear(0.05mm) base               // in mesh with the barrel
    }
  }
}

// == The motor ===================================================================================
// Face down on the keeper's plate over P, its boss in a recess, its shaft down through the plate
// and its spigot to the first sun, pressed on it; held in a cradle of its own section grown by a
// wall, a print's clearance inside, standing on the plate.  The flats key it against its torque;
// a strap across its end bell holds it down on the plate, screwed into two ears up from the
// cradle's flat walls.
motor_at := point
motor_at raised(d: motor_z, along: std.z) p_c
motor := Motor130(motor130_dims)
motor seats(turn: bot_turn, up: std.z, east: std.x) motor_at

cradle_out := MotorCan(motor130_dims, grow: wall + gap, z0: lid_z1 - motor_z - 1mm, z1: 18mm)
cradle_out seats(turn: bot_turn, up: std.z, east: std.x) motor_at
cradle_in := MotorCan(motor130_dims, grow: gap, z0: 0mm, z1: 19mm)
cradle_in seats(turn: bot_turn, up: std.z, east: std.x) motor_at
cradle := solid(cradle_out.body)
cradle_in.body cut cradle
ears := StrapEars(motor130_dims, z0: ear_z0 - motor_z, z1: ear_z1 - motor_z)
ears seats(turn: bot_turn, up: std.z, east: std.x) motor_at
ears.body union cradle
ears.holes cut cradle

strap_at := point
strap_at raised(d: strap_top, along: std.z) p_c
strap := MotorStrap(motor130_dims)
strap seats(turn: bot_turn, up: std.z, east: std.x) strap_at
strap_part := solid(strap.part)
claim strap_part clear(0.4mm) cradle      // its legs short of the ears: it bears on the motor

// == The base: the gearbox's floor and walls =====================================================
// A box from the floor up to the keeper's top, hollowed: the keeper presses down into its walls'
// top, onto the tops of the bridge, the bulkhead, the barrel and the corner posts.  Its floor and
// its walls are cut away where A's ring turns under the train (the whole of its +x end, down
// there), and a bridge standing on the collar and up to the keeper holds A's axle.  The bridge
// runs out to the end wall, and a bulkhead across the box through A ties it into both side walls
// as well: on its own the end wall, a thin plate over the ring's room, would flex under it.  The
// bulkhead stands from the ring's room up to the keeper, a print's clearance round the collar.
//
// The stack's barrel stands up from the floor round P, into the -y wall, to the keeper's
// underside: through its bore the 46 internal teeth every stage's planets run in, one right-handed
// helical gear from the last carrier's plate up past the first stage's planets, cut by its tooth
// count's own helical gear grown a clearance (`Helical` with `add` 1.25); under them its plain
// bore, where the last pinion turns and A's ring comes in through the ring's room; over them a
// counterbore the keeper's spigot drops into, which stands the motor over P.  P's rod stands in
// the floor, the last pinion running just over it.  Four M3 screws down through the frame's floor
// and the keeper hold the base up to the frame (below), the keeper clamped between them.
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
barrel := Post(p_c, r: barrel_r, z0: floor_z1 - 1mm, z1: lid_z0)
barrel_bore := Post(p_c, r: ring_tip_r, z0: floor_z1, z1: band_z1)
counterbore := Post(p_c, r: cb_r, z0: band_z1, z1: lid_z0 + 1mm)
ring_cutter := Helical(p_c, z: band_z0, turn: ring_turn, N: ring_teeth, hand: planet_hand,
                       add: 1.25, thin_by: -thin, face: band_z1 - band_z0, bore: 10mm,
                       chamfer_by: 0mm)
base_hole_p := Post(p_c, r: (p_rod_d + press) / 2, z0: floor_z0 - 1mm, z1: floor_z1 + 1mm)

base := solid(base_shell)
bridge.body union base
bridge_boss.body union base
bulkhead.body union base
barrel.body union base
collar_room.body cut base
ring_room.body cut base
ring_side.body cut base
barrel_bore.body cut base
counterbore.body cut base
ring_cutter.gear cut base
base_hole_a.body cut base
base_hole_p.body cut base

// == The keeper: the gearbox's lid, A's top and the motor ========================================
// One print, a frame of beams 3 mm deep with open bays between them and a plate over the stack,
// held in the base by four pads slotted down over dovetail rails on its walls: it holds the top
// of A's axle, in a post on its top, and the motor, on the plate in its cradle, so the gearbox and
// its motor are whole without the frame.
//   - A spine runs from end wall to end wall through the plate and A, over the bridge, and a cross
//     beam over the bulkhead from side wall to side wall: the keeper stands on the bridge, the
//     bulkhead and the barrel's top, and each of the four ends is a pad `anchor_w` along its wall;
//   - up the middle of each pad's end, a dovetail slot, the rail grown `snug` all round: it
//     slides down over the rail, a light press on its flanks, and the rail holds the pad to its
//     wall and square along it, so the keeper can neither spread nor pull in off the walls;
//   - the plate over P stands on the barrel's top, and a spigot under it drops into the barrel's
//     counterbore, `snug` all round, so the motor's shaft stands on P's axis: the first sun meshes
//     its planets as truly as the barrel stands them;
//   - every beam runs into its hub, the plate or a pad through a fillet in plan.
// Nothing else touches the walls.  The frame stands on the base's walls and its corner posts, A's
// post and the cradle up through holes in its floor, and its floor bears down on the keeper's
// beams and plate.  It prints on its beams' undersides, the spigot standing up from the plate.
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
keeper_x0 := box_x0 + wall + snug
keeper_x1 := box_x1 - wall - snug
keeper_y0 := box_y0 + wall + snug
keeper_y1 := box_y1 - wall - snug
spine_beam := Bar(x0: keeper_x0, y0: 0mm, x1: keeper_x1, y1: 0mm, w: keeper_beam, z0: lid_z0,
                  z1: lid_z1) in bot
cross_beam := Bar(x0: -a_dist, y0: keeper_y0, x1: -a_dist, y1: keeper_y1, w: keeper_beam,
                  z0: lid_z0, z1: lid_z1) in bot
// Each rail's frame: its origin on the wall's inside face at the rail's middle, at z = 0, its x
// in from the wall, its y along it; `a` is that inward direction's bearing in the bot's plan.
keeper_rails_at := [
  {x: box_x0 + wall, y: 0mm, a: 0deg},             // west, the far end wall
  {x: box_x1 - wall, y: 0mm, a: 180deg},           // east, over the bridge
  {x: -a_dist, y: box_y0 + wall, a: 90deg},        // south, over the bulkhead
  {x: -a_dist, y: box_y1 - wall, a: -90deg},       // north, over the bulkhead
]
keeper_rails := solid()
// A's post on the keeper's top and its hole up into it; the plate over P and its spigot, the
// motor's boss's recess and its shaft's hole
lid_post_r := axle_d / 2 + boss_wall
hub_a := Post(a_c, r: lid_post_r, z0: lid_z0, z1: lid_z1)
lid_post_a := Post(a_c, r: lid_post_r, z0: lid_z1, z1: post_z1)
lid_hole_a := Post(a_c, r: (axle_d + press) / 2, z0: lid_z0 - 1mm, z1: rod_z1)
hub_p := Post(p_c, r: lid_disc_r, z0: lid_z0, z1: lid_z1)
spigot := Post(p_c, r: cb_r - snug, z0: spigot_z0, z1: lid_z0 + 0.5mm)
motor_boss_room := Post(p_c, r: motor130_dims.boss_d / 2 + gap,
                        z0: motor_z - motor130_dims.boss_h - gap, z1: motor_z + 1mm)
motor_shaft_room := Post(p_c, r: 2.5mm, z0: spigot_z0 - 1mm, z1: motor_z)

// The keeper's pieces unioned whole, each named by its path in the keeper for its fillets:
// `keeper_fillet` in plan wherever a beam meets a hub, the plate or a pad, all within the beams'
// depth, so none reaches up past the keeper's top to the frame's floor or down to the gears.
keeper_fillet := 3mm
keeper_part := solid()
spine_beam.body union keeper_part
cross_beam.body union keeper_part
hub_a.body union keeper_part
hub_p.body union keeper_part
spigot.body union keeper_part
repeat r in keeper_rails_at {
  rail_f := frame
  fix(origin == (r.x * cos(bot_turn) - r.y * sin(bot_turn),
                 r.x * sin(bot_turn) + r.y * cos(bot_turn), 0mm)) rail_f
  fix(dir == (cos(bot_turn + r.a), sin(bot_turn + r.a), 0)) rail_f.u
  fix(dir == (-sin(bot_turn + r.a), cos(bot_turn + r.a), 0)) rail_f.v
  joint := KeeperRail() in rail_f
  joint.rail union base
  joint.rail union keeper_rails
  joint.slot cut keeper_part
  // the pad, `anchor_w` along the wall and `anchor_d` deep, `snug` off it
  pad_bar := Bar(x0: r.x + snug * cos(r.a), y0: r.y + snug * sin(r.a),
                 x1: r.x + anchor_d * cos(r.a), y1: r.y + anchor_d * sin(r.a), w: anchor_w,
                 z0: lid_z0, z1: lid_z1) in bot
  pad_bar.body union keeper_part
}
claim keeper_rails clear(0.04mm) keeper_part          // the press: `snug` all round each rail
cradle union keeper_part
keeper_part.spine_beam round(r: keeper_fillet) keeper_part.hub_a
keeper_part.spine_beam round(r: keeper_fillet) keeper_part.hub_p
keeper_part.spine_beam round(r: keeper_fillet) keeper_part.pad_bar
keeper_part.cross_beam round(r: keeper_fillet) keeper_part.hub_a
keeper_part.cross_beam round(r: keeper_fillet) keeper_part.pad_bar
lid_post_a.body union keeper_part
lid_hole_a.body cut keeper_part
motor_boss_room.body cut keeper_part
motor_shaft_room.body cut keeper_part

// == The frame: the electronics bay ==============================================================
// One print, the bot's backbone, printed on its floor: it stands on the base and the keeper, the
// boards stand on its floor, and the mount is glued onto the rail up its end wall.  Its floor has
// a hole round each of the keeper's posts and round the motor's cradle, its ears and its strap, a
// print's clearance all round, so it goes down over the keeper with the motor strapped in.
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
floor_hole_m seats(turn: bot_turn, up: std.z, east: std.x) motor_at
floor_hole_ears := Block(x0: -strap_w / 2 - gap, x1: strap_w / 2 + gap,
                         y0: -strap_screw_y - ear_t / 2 - gap, y1: strap_screw_y + ear_t / 2 + gap,
                         z0: lid_z1 - 1mm - motor_z, z1: case_z1 + 1mm - motor_z)
floor_hole_ears seats(turn: bot_turn, up: std.z, east: std.x) motor_at

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
// hangs on the shelf, the slope of both pressing the rail's flanks into the slot's.  There the barb at the foot of a finger in the slot's floor, pushed out by
// the rail's lip in the last few millimetres, snaps into the rail's notch, and holds the two
// together while the glue in the slot sets.  The dovetail's flanks take the handle's reaction
// sideways and outward, the glue the rest.
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
    base_at := At(x: bx, y: by) in bot
    base_screw := ScrewPost(base_at.p, r: base_post_r, z0: floor_z1, z1: lid_z1, hole_d: pilot,
                            depth: 12mm) in bot
    lid_screw := Post(base_at.p, r: m3_clear / 2, z0: lid_z1 - 1mm, z1: case_z1 + 1mm) in bot
    base_head := Post(base_at.p, r: m3_head_d / 2, z0: case_z1, z1: case_z1 + m3_head_h) in bot
    base_screw.post union base
    base_screw.hole cut base
    lid_screw.body cut frame_part
    claim base_screw.post clear(0.5mm) keeper_part
    claim base_head.body clear(0.5mm) bay_shell
    claim base_head.body clear(0.5mm) redboard.board
    claim base_head.body clear(0.5mm) redboard.tails
  }
}

// The RedBoard's four M3s, self-tapping into posts on the frame's floor at its holes (boards.sv),
// the Uno's.  The posts are 5 mm across, an M3 standoff's size: the one by the SCL socket stands
// 3.6 mm off its SCL pin.  Each hole runs a millimetre on into the floor.
repeat h in uno_holes {
  board_hole := At(x: board_ox + h.x, y: board_oy + h.y) in bot
  board_screw := ScrewPost(board_hole.p, r: 2.5mm, z0: lid_z1, z1: board_z, hole_d: pilot,
                           depth: board_z - case_z1 + 1mm) in bot
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
cover := RoundedBlock(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, r: box_r, z0: bay_z1,
                      z1: bay_z1 + wall) in bot
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
// boards, the RedBoard's parts and the pins' tails clear of the frame, the motor, its cradle and
// strap, and the cover, and of one another.  The motor and its strap clear the cover over them, and
// the keeper's cradle and its strap clear the frame, whose floor goes down over them.
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
claim strap_part clear(1mm) cover_part
claim cradle clear(0.25mm) frame_part
claim strap_part clear(0.5mm) frame_part
claim redboard.parts clear(1mm) cradle
claim redboard.parts clear(1mm) strap_part
claim shield.board clear(1mm) strap_part
claim shield.headers clear(0.5mm) cradle
claim shield.headers clear(0.5mm) strap_part
claim driver.board clear(1mm) cradle
claim driver.board clear(1mm) strap_part
claim driver.headers clear(0.5mm) strap_part
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
// that rest on one another (the motor on its pad and under its strap, the keeper in the base, the
// frame on both, the collar on the bridge, the socket on the stand's pad) are not claimed clear;
// the mount clears the base, whose end wall stands under its foot's edge.
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
  claim a_compound clear(0.05mm) carrier_3              // A's ring and the last pinion
  claim carrier_3 clear(1mm) collar.part
  claim carrier_3 clear(0.2mm) carrier_2
  claim carrier_2 clear(0.2mm) carrier_1
  claim carrier_1 clear(0.2mm) sun_1
  claim carrier_3 clear(0.2mm) base
  claim carrier_2 clear(0.2mm) base
  claim carrier_1 clear(0.2mm) base
  claim sun_1 clear(0.2mm) base
  claim sun_1 clear(0.2mm) keeper_part
  claim carrier_1 clear(0.5mm) motor.motor              // the shaft's end, in its bore
  claim planet clear(0.2mm) carrier3                     // on its carrier's plate
  claim planet clear(0.05mm) carrier2                    // in mesh with its sun
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
