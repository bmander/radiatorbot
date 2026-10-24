// The radiator bot: a gearmotor that clamps to the valve's supply pipe and turns the star handle
// through a wheel conjugate to it.
//
// Coordinates are the valve's (radiator_valve.sv): the stem is std.z, z = 0 is the packing nut's
// bottom face, the radiator lies toward +x.  The bot hangs on the valve's -x side:
//
//   - the **wheel** turns about an axle `wheel_c` out along -x, at the handle's height.  Its
//     pockets are what the handle sweeps through its blank as the two turn together, one
//     statement: the conjugate the handle would cut if it were a gear shaper.  A 48-tooth ring on
//     its top face is driven by the gearbox;
//   - the **gearbox** above it is five printed spur stages on two drill-rod axles, B and D, the
//     130 motor's pinion driving the first; its base's floor stops short of the wheel's ring;
//   - the **frame** is the gearbox's lid, the electronics bay standing on it (the motor, the
//     perfboard over the motor with the ESP32 and the motor driver on it, the cable entries), and
//     the spine up beside the valve to the **clamp**, a split block round the inlet hex and the
//     supply pipe above it.  The hex takes the handle's reaction torque positively; the bolted
//     cap closes the clamp from +x.
//
// Everything is printed but the drill rod the gears turn on, so the fits below are an FDM
// printer's.  Scrub `handle_turn`: the wheel and the train turn with the handle.  Set `shaped` to
// 0 to draw every gear and the wheel as blanks while the layout is worked on (building them all
// takes a few minutes).  The design table's requirements are claims, judged before the solve;
// `solventc radiatorbot.sv --where handle_stall_torque` reads any figure back in its unit.
//
// Numbers marked "~" are estimates to check: the motor's figures (motor130.sv) and the stem's
// travel, which no measurement has said yet.

unit mm
use std
use std (vertical, horizontal, turns, coords, seats, raised)
use radiator_valve (RadiatorValve, handle_dims, body_dims, pipe_dims, handle_gap)
use radiator_valve (StarOutline, StarSizes, HexBar, RoundBar)
use gears (ShapedSpur)
use motor130 (Motor130, MotorCan, motor130_dims, motor130_free, motor130_stall_torque)
use boards (XiaoEsp32C3, Drv8874, xiao_dims, drv8874_dims, header_dims, pitch)

shaped := 1                    // 1: shape the gears and the wheel; 0: blanks, for a quick look

// == The drive ===================================================================================

// The wheel and the handle.  The star is a four-toothed gear of pitch radius `star_pitch_r`; the
// wheel has `wheel_n` pockets, so the handle turns wheel_n / 4 times a turn of the wheel.
wheel_n := 6
star_pitch_r := 24mm
wheel_c := star_pitch_r * (1 + wheel_n / 4)            // the stem to the wheel's axle: 60 mm
wheel_backlash := 0.6mm         // the chrome casting's arms against printed pockets
stem_travel := 4mm              // ~ how far the handle drops opening the valve, closed to open
wheel_bands := 6                // the draft followed in steps: each over-clears it by <= 0.4 mm

// The handle as measured stands closed, its top face `handle_gap` under the packing nut;
// opening, a right-hand stem screws it down `stem_travel`.  The wheel spans the arms' depth with
// half a millimetre spare above and the rolled rim spare below.
top0 := -handle_gap
wheel_top := top0 + 0.5mm
wheel_bottom := top0 - handle_dims.h + 1.5mm
wheel_rim := wheel_c - handle_dims.waist / 2 - 1mm      // clear of the star's waist by 1 mm

// The gear train, motor to wheel.  Stage 1 runs the motor into B; stages 2-5 ping-pong between
// B and D, which stand one centre distance apart (`cd_bd`: 12 + 48 teeth at module 0.8, or
// 12 + 36 at module 1); the last pinion, on B, drives the wheel's ring.  Pinions of 12 teeth are
// shifted +0.3 against undercut and their gears -0.3, so the centre distances stay nominal.
pa := 20deg
pin_n := 12
pin_shift := 0.3
m_small := 0.8mm                // stages 1-4: the finest an 0.4 mm nozzle prints well
m_s5 := 1mm                     // stage 5
m_fin := 1.5mm                  // the ring and its pinion
s1_n := 24                      // stage 1's gear, on B
big_n := 48                     // stages 2-4's gears
s5_n := 36                      // stage 5's gear, on B
ring_n := 48
cd_s1 := m_small * (pin_n + s1_n) / 2                   // 14.4 mm, the motor to B
cd_bd := m_small * (pin_n + big_n) / 2                  // 24 mm, B to D
cd_fin := m_fin * (pin_n + ring_n) / 2                  // 45 mm, B to the wheel
gear_ratio := s1_n / pin_n * (big_n / pin_n) ^ 3 * s5_n / pin_n * ring_n / pin_n
handle_ratio := gear_ratio * 4 / wheel_n                // motor turns a handle turn
claim handle_ratio == 1024

// What it does, from the motor's figures: printed spur meshes at ~0.9, the wheel and the star
// at ~0.8.  The current sensing trips well under the stall: at the end of the screw the torque
// the trip allows is what seats the valve.  What the design asks of it: a stall well over what an
// old packed valve takes to turn, and three turns of travel inside half a minute unloaded.
drive_eff := 0.9 ^ 6 * 0.8
handle_free_speed := motor130_free / handle_ratio
handle_stall_torque := motor130_stall_torque * handle_ratio * drive_eff
wheel_stall_torque := handle_stall_torque * wheel_n / 4 / 0.8      // what the wheel's ring carries
claim handle_stall_torque >= 2Nm
claim handle_free_speed >= 6rpm

// Drill rod.  The gears and the wheel turn on fixed rods; the housing holds the rods.
axle_d := 8mm                   // the wheel's
rod_b := 5mm
rod_d := 5mm

// == Fits for an FDM print =======================================================================
run := 0.35mm                   // a printed bore turning on drill rod, over the rod
press := 0.05mm                 // a printed hole a rod is pressed into (drill or ream to fit)
gap := 0.3mm                    // between printed faces that meet or pass
thin := 0.15mm                  // each gear's teeth thinned: 0.3 mm backlash a mesh
chamfer := 0.4mm                // each gear's tips chamfered at both faces, 45deg
wall := 2.4mm                   // six 0.4 mm perimeters
pilot := 2.5mm                  // an M3 screw's self-tapping hole in a print
m3_clear := 3.4mm
m4_clear := 4.6mm
m4_nut_af := 7.3mm              // an M4 nut's pocket across the flats
split := 1mm                    // the clamp's halves stand apart this much before the bolts close it

// == Heights =====================================================================================
// From the floor up: the ring and the last pinion, stages 5 to 1, the lid, the electronics bay
// and its cover.  Faces are 5 mm at module 0.8, 6 at module 1 and 10 at module 1.5, with half a
// millimetre between layers.  The motor stands face down on the lid, its pinion through it.
floor_z0 := -0.1mm              // the base's floor, round B and D only: the wheel turns under it
floor_z1 := floor_z0 + 3mm
ring_z0 := 3mm                  // the ring's teeth; the web under it runs down to the wheel
fin_z0 := ring_z0 + 0.5mm       // the last pinion
s5_z0 := fin_z0 + 10.5mm
s4_z0 := s5_z0 + 6.5mm
s3_z0 := s4_z0 + 5.5mm
s2_z0 := s3_z0 + 5.5mm
s1_z0 := s2_z0 + 5.5mm
lid_z0 := s1_z0 + 5.5mm
lid_z1 := lid_z0 + 3mm
bridge_z0 := s5_z0              // the wheel's axle held in a bridge across the base, over the ring
bridge_z1 := s5_z0 + 6mm
board_z := lid_z1 + motor130_dims.len + 3mm             // the perfboard's underside, over the motor
bay_z1 := board_z + 1.6mm + 14mm                        // room for the modules on their headers
clamp_z0 := body_dims.inlet_top - body_dims.inlet_h     // the inlet hex's underside
clamp_z1 := clamp_z0 + 31.7mm

// == Plan ========================================================================================
// The housing's outline, the clamp and the spine, in plan (x, y): the box the base, the lid, the
// bay and the cover all share.
box_x0 := -130mm
box_x1 := -35mm
box_y0 := -28mm
box_y1 := 47mm
spine_x1 := -21.5mm             // 4 mm off the valve's bulge and collar
spine_w := 28mm
clamp_reach := 26mm             // each half of the clamp, out from the stem
clamp_w := 50mm
clamp_bolt_y := 20mm
board_w := 70mm                 // a 5 x 7 cm perfboard
board_h := 50mm
board_cx := -82.5mm
board_cy := 9mm
board_cols := 24                // its holes, 0.1 in apart, centred on it
board_rows := 18
grid_x0 := board_cx - (board_cols - 1) * pitch / 2       // the first column's holes
grid_y0 := board_cy - (board_rows - 1) * pitch / 2       // the first row's
board_top := board_z + 1.6mm
// The boards on the perfboard's grid (boards.sv), each at its pin field's middle: the XIAO's pins
// in columns 0-6, rows 9 and 15, its USB out over the board's end toward the bay's end wall; the
// driver's in columns 17 and 22, rows 0-6.
xiao_cx := grid_x0 + 3 * pitch
xiao_cy := grid_y0 + 12 * pitch
drv_cx := grid_x0 + 19.5 * pitch
drv_cy := grid_y0 + 3 * pitch
usb_z := board_top + header_dims.body_h + xiao_dims.pcb_t + xiao_dims.usb_h / 2   // its axis

// == Building blocks =============================================================================

// A round post about `c` (drawn in std.top) from z0 to z1.
component Post(c: point, r: Length, z0: Length, z1: Length) {
  in std.top {
    rim := radius(r) circle(center: c)
  }
  body := solid(face(rim), from: z0, to: z1)
}

// A block square to the world: x0..x1, y0..y1, z0..z1.
component Block(x0: Length, x1: Length, y0: Length, y1: Length, z0: Length, z1: Length) {
  in std.top {
    c := point hint(((x0 + x1) / 2, (y0 + y1) / 2))
    c coords(du: (x0 + x1) / 2, dv: (y0 + y1) / 2) std.top
    sq := std.CenteredRectangle(c, w: x1 - x0, h: y1 - y0)
  }
  body := solid(face(sq.loop), from: z0, to: z1)
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

// A printed gear seated on an axle: its figure (gears.sv) with its origin `z` up the axle from
// `c`, its axis up the world's z, turned `phase` about it.  A driving gear has a tooth on the line
// of centres and the gear it drives a space: with the cut space on +v, a pinion turned
// `bearing - 90deg - 180deg / N` and its gear `bearing + 90deg`, `bearing` the line of centres'
// from the pinion's axle to the gear's.  Gears of one size and face are one figure, shaped once.
// A large gear is spoked to save material: `spokes` of them, `web` wide, between a hub of radius
// `hub` (clear of the pinion it carries) and a rim `web` thick under its roots; 0 spokes, solid.
component Gear(c: point, z: Length, phase: Angle, N: Int, m: Length, shift: Scalar,
               face: Length, bore: Length, shaped: Int, spokes: Int, hub: Length, web: Length) {
  at := point
  at raised(d: z, along: std.z) c
  g := ShapedSpur(N: N, m: m, phi: pa, shift: shift, thin: thin, z0: 0mm, z1: face, bore: bore,
                  shaped: shaped, chamfer: chamfer, spokes: spokes, hub: hub, web: web)
  g seats(turn: phase, up: std.z, east: std.x) at
}

// == The wheel ===================================================================================

// A band of the star: its section `depth` under the top face (the draft has moved each side
// `depth tan(draft)` in), grown `grow` all round for the backlash, from z0 to z1 measured up the
// stem from the top face.
component StarBand(top: plane, s: StarSizes, depth: Length, z0: Length, z1: Length,
                   grow: Length) {
  o := grow - depth * tan(s.draft)
  plan := StarOutline(top, s: {span: s.span + 2 * o, waist: s.waist + 2 * o, h: s.h,
                               tip_r: s.tip_r + o, fillet_r: s.fillet_r - o, draft: s.draft,
                               rim_r: s.rim_r, edge_r: s.edge_r, stem_d: s.stem_d})
  construction prism := solid(plan.outline, from: z0, to: z1)
}

// The wheel conjugate to the star: a disc of radius `rim` about `c` from z_bot to z_top, less
// everything the star sweeps through as it turns about `stem` and the wheel about `spindle`,
// `n / 4` handle turns a wheel turn, over a whole turn of the wheel.  The cutter is all the
// handle occupies over its travel, following the draft in `bands` steps: each band the star's
// widest section the band ever meets, the section at its top as the handle stands lowest
// (`travel` down from `top`, at `top_z`), or the top face's own where the band reaches above
// that.  The top band runs on up past the wheel, so the pockets stay open above the handle.
//
// (The drafted star itself, unstepped, is refused: its swept region changes shape between
// heights, which the loft through stations can't carry.)
component ConjugateWheel(top: plane, stem: line, spindle: line, c: point, s: StarSizes, n: Int,
                         rim: Length, z_bot: Length, z_top: Length, top_z: Length,
                         travel: Length, bands: Int, grow: Length, shaped: Int) {
  band := (z_top - z_bot) / bands
  construction cutter := solid()
  repeat bands as k {
    sl := StarBand(top, s, depth: max(0mm, top_z - travel - (z_top - k * band)),
                   z0: z_top - (k + 1) * band - top_z - 1mm * floor((k + 1) / bands),
                   z1: z_top - k * band - top_z + 1mm * (1 - min(k, 1)), grow: grow)
    sl.prism union cutter
  }
  in std.top {
    edge := radius(rim) circle(center: c)
  }
  gen_handle := frame
  gen_handle turns(1) stem
  gen_wheel := frame
  gen_wheel turns(-4 / n) spindle
  wheel := solid(face(edge), from: z_bot, to: z_top)
  when shaped == 1 {
    private construction space := sweep(cutter over t in (0deg, 90deg * n), under: gen_handle,
                                        seen_from: gen_wheel)
    space cut wheel
  }
}

// == The valve ===================================================================================

// The handle's turn, scrubbed: the wheel and the train turn with it.  Keep the drawing free of
// redundant rows (the report's `implied:` lines): one makes this follow take minutes instead of
// seconds (bmander/geomsolver#591).
param handle_turn: Angle over (0deg, 360deg)
valve := RadiatorValve(handle_turn: handle_turn)

// == The axles ===================================================================================
// A, the wheel's, is `wheel_c` out along -x; B is the last pinion's, `cd_fin` beyond it; D stands
// `cd_bd` from B, turned up toward +y; the motor's axis M is `cd_s1` from B, down toward -y.
in std.top {
  a_c := point in std.top, std.front
  std.top.origin distance(-wheel_c, along: u) a_c
  b_c := point in std.top, std.front
  std.top.origin distance(-wheel_c - cd_fin, along: u) b_c
  d_c := point hint((-105 + 24 * cos(75deg), 24 * sin(75deg)))
  b_c distance(cd_bd) d_c
  m_c := point hint((-105 + 14.4 * cos(-60deg), 14.4 * sin(-60deg)))
  b_c distance(cd_s1) m_c
  construction b_d := line(b_c, d_c)
  construction b_m := line(b_c, m_c)
  construction b_a := line(b_c, a_c)
  b_a angle(75deg) b_d
  b_a angle(-60deg) b_m
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

// == The wheel and its ring ======================================================================
cw := ConjugateWheel(valve.handle_top, valve.stem_axis, a_spindle, a_c, s: handle_dims,
                     n: wheel_n, rim: wheel_rim, z_bot: wheel_bottom, z_top: wheel_top,
                     top_z: top0, travel: stem_travel, bands: wheel_bands,
                     grow: wheel_backlash / 2, shaped: shaped)

ring_gear := Gear(a_c, z: ring_z0, phase: 0deg + 90deg, N: ring_n, m: m_fin, shift: -pin_shift,
             face: 10mm, bore: axle_d + run, shaped: shaped, spokes: 0, hub: 0mm, web: 0mm)

web := Post(a_c, r: 33mm, z0: wheel_top, z1: ring_z0 + 0.25mm)
wheel_bore := Post(a_c, r: (axle_d + run) / 2, z0: wheel_bottom - 1mm, z1: ring_z0 + 11mm)
construction wheel_part := solid(cw.wheel)
web.body union wheel_part
ring_gear.g.gear union wheel_part
wheel_bore.body cut wheel_part

// The wheel kept on its axle from below: a collar with an M3 set screw.
collar := Post(a_c, r: 7mm, z0: wheel_bottom - 4.5mm, z1: wheel_bottom - gap)
collar_bore := Post(a_c, r: (axle_d + run) / 2, z0: wheel_bottom - 5mm, z1: wheel_bottom)
collar_screw := BoreX(y: 0mm, z: wheel_bottom - 2.4mm, d: pilot, x0: -wheel_c - 8mm,
                      x1: -wheel_c)
collar_part := solid(collar.body)
collar_bore.body cut collar_part
collar_screw.body cut collar_part

// == The gear train ==============================================================================
// Bearings of the lines of centres: the motor to B 120deg, B to D 75deg, D to B 255deg, B to the
// wheel 0deg.  Each compound is its gear and its pinion, the pinion run a quarter millimetre up
// into the gear so the two print as one part.

// stage 1: the motor's pinion, pressed on its shaft, into B's first compound's gear
motor_pin := Gear(m_c, z: s1_z0 + 0.5mm, phase: 120deg - 90deg - 15deg, N: pin_n, m: m_small,
                  shift: pin_shift, face: 4.75mm, bore: motor130_dims.shaft_d - 0.1mm,
                  shaped: shaped, spokes: 0, hub: 0mm, web: 0mm)
// B's first compound: stage 1's gear over stage 2's pinion
b1_gear := Gear(b_c, z: s1_z0, phase: 120deg + 90deg, N: s1_n, m: m_small, shift: -pin_shift,
                face: 5mm, bore: rod_b + run, shaped: shaped, spokes: 0, hub: 0mm, web: 0mm)
b1_pin := Gear(b_c, z: s2_z0, phase: 75deg - 90deg - 15deg, N: pin_n, m: m_small,
               shift: pin_shift, face: 5.75mm, bore: rod_b + run, shaped: shaped,
               spokes: 0, hub: 0mm, web: 0mm)
// D's first: stage 2's gear over stage 3's pinion
d1_gear := Gear(d_c, z: s2_z0, phase: 75deg + 90deg, N: big_n, m: m_small, shift: -pin_shift,
                face: 5mm, bore: rod_d + run, shaped: shaped, spokes: 5, hub: 8mm, web: 2.4mm)
d1_pin := Gear(d_c, z: s3_z0, phase: 255deg - 90deg - 15deg, N: pin_n, m: m_small,
               shift: pin_shift, face: 5.75mm, bore: rod_d + run, shaped: shaped,
               spokes: 0, hub: 0mm, web: 0mm)
// B's second: stage 3's gear over stage 4's pinion
b2_gear := Gear(b_c, z: s3_z0, phase: 255deg + 90deg, N: big_n, m: m_small, shift: -pin_shift,
                face: 5mm, bore: rod_b + run, shaped: shaped, spokes: 5, hub: 8mm, web: 2.4mm)
b2_pin := Gear(b_c, z: s4_z0, phase: 75deg - 90deg - 15deg, N: pin_n, m: m_small,
               shift: pin_shift, face: 5.75mm, bore: rod_b + run, shaped: shaped,
               spokes: 0, hub: 0mm, web: 0mm)
// D's second: stage 4's gear over stage 5's pinion, at module 1
d2_gear := Gear(d_c, z: s4_z0, phase: 75deg + 90deg, N: big_n, m: m_small, shift: -pin_shift,
                face: 5mm, bore: rod_d + run, shaped: shaped, spokes: 5, hub: 9mm, web: 3mm)
d2_pin := Gear(d_c, z: s5_z0, phase: 255deg - 90deg - 15deg, N: pin_n, m: m_s5,
               shift: pin_shift, face: 6.75mm, bore: rod_d + run, shaped: shaped,
               spokes: 0, hub: 0mm, web: 0mm)
// B's third: stage 5's gear over the last pinion, which drives the wheel's ring
b3_gear := Gear(b_c, z: s5_z0, phase: 255deg + 90deg, N: s5_n, m: m_s5, shift: -pin_shift,
                face: 6mm, bore: rod_b + run, shaped: shaped, spokes: 0, hub: 0mm, web: 0mm)
b3_pin := Gear(b_c, z: fin_z0, phase: 0deg - 90deg - 15deg, N: pin_n, m: m_fin,
               shift: pin_shift, face: 10.75mm, bore: rod_b + run, shaped: shaped,
               spokes: 0, hub: 0mm, web: 0mm)

construction motor_pinion := solid(motor_pin.g.gear)
construction b1 := solid(b1_gear.g.gear)
b1_pin.g.gear union b1
construction d1 := solid(d1_gear.g.gear)
d1_pin.g.gear union d1
construction b2 := solid(b2_gear.g.gear)
b2_pin.g.gear union b2
construction d2 := solid(d2_gear.g.gear)
d2_pin.g.gear union d2
construction b3 := solid(b3_gear.g.gear)
b3_pin.g.gear union b3

// The train turning with the handle, a turn of it: the wheel -4/6, and each compound back up
// the train by its mesh's ratio, reversed — up to the motor's -1024.
wheel_turn := frame
wheel_turn turns(-4 / wheel_n) a_spindle
fix(value == handle_turn) wheel_turn
b3_turn := frame
b3_turn turns(4 / wheel_n * ring_n / pin_n) b_spindle
fix(value == handle_turn) b3_turn
d2_turn := frame
d2_turn turns(-4 / wheel_n * ring_n / pin_n * s5_n / pin_n) d_spindle
fix(value == handle_turn) d2_turn
b2_turn := frame
b2_turn turns(4 / wheel_n * ring_n / pin_n * s5_n / pin_n * big_n / pin_n) b_spindle
fix(value == handle_turn) b2_turn
d1_turn := frame
d1_turn turns(-4 / wheel_n * ring_n / pin_n * s5_n / pin_n * (big_n / pin_n) ^ 2) d_spindle
fix(value == handle_turn) d1_turn
b1_turn := frame
b1_turn turns(4 / wheel_n * ring_n / pin_n * s5_n / pin_n * (big_n / pin_n) ^ 3) b_spindle
fix(value == handle_turn) b1_turn
motor_turn := frame
motor_turn turns(-handle_ratio) m_spindle
fix(value == handle_turn) motor_turn

wheel := wheel_part in wheel_turn
compound_b3 := b3 in b3_turn
compound_d2 := d2 in d2_turn
compound_b2 := b2 in b2_turn
compound_d1 := d1 in d1_turn
compound_b1 := b1 in b1_turn
pinion := motor_pinion in motor_turn

// The rods: A held in the base's bridge and the lid, B and D in the floor and the lid.
axle_a := Post(a_c, r: axle_d / 2, z0: wheel_bottom - 5mm, z1: lid_z1)
rod_at_b := Post(b_c, r: rod_b / 2, z0: floor_z0, z1: lid_z1)
rod_at_d := Post(d_c, r: rod_d / 2, z0: floor_z0, z1: lid_z1)

// == The motor ===================================================================================
// Face down on the lid, its boss in a recess, its pinion through the lid into stage 1; held in a
// cradle of its own section grown by a wall, a print's clearance inside.
motor_at := point
motor_at raised(d: lid_z1, along: std.z) m_c
motor := Motor130(motor130_dims)
motor seats(turn: 0deg, up: std.z, east: std.x) motor_at

cradle_out := MotorCan(motor130_dims, grow: wall + gap, z0: 0mm, z1: 18mm)
cradle_out seats(turn: 0deg, up: std.z, east: std.x) motor_at
cradle_in := MotorCan(motor130_dims, grow: gap, z0: -1mm, z1: 19mm)
cradle_in seats(turn: 0deg, up: std.z, east: std.x) motor_at
cradle := solid(cradle_out.body)
cradle_in.body cut cradle

// == The base: the gearbox's floor and walls =====================================================
// A box from the floor to the lid, hollowed; its floor and its walls are cut away where the
// wheel's ring turns under the train, and a bridge across it holds the wheel's axle.  Four M3
// screws at its corners hold it up to the lid.
base_box := Block(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, z0: floor_z0, z1: lid_z0)
base_cavity := Block(x0: box_x0 + wall, x1: box_x1 - wall, y0: box_y0 + wall, y1: box_y1 - wall, z0: floor_z1, z1: lid_z0 + 1mm)
ring_room := Post(a_c, r: 39mm, z0: floor_z0 - 1mm, z1: ring_z0 + 10.5mm)
base_shell := solid(base_box.body)
base_cavity.body cut base_shell

base := solid(base_shell)
bridge := Block(x0: -wheel_c, x1: box_x1 - wall, y0: -9mm, y1: 9mm, z0: bridge_z0, z1: bridge_z1)
bridge_boss := Post(a_c, r: 9mm, z0: bridge_z0, z1: bridge_z1)
bridge.body union base
bridge_boss.body union base
in std.top {
  corner_00 := point hint((-125.6, -23.6))
  corner_00 coords(du: box_x0 + wall + 2mm, dv: box_y0 + wall + 2mm) std.top
  corner_10 := point hint((-39.4, -23.6))
  corner_10 coords(du: box_x1 - wall - 2mm, dv: box_y0 + wall + 2mm) std.top
  corner_01 := point hint((-125.6, 42.6))
  corner_01 coords(du: box_x0 + wall + 2mm, dv: box_y1 - wall - 2mm) std.top
  corner_11 := point hint((-39.4, 42.6))
  corner_11 coords(du: box_x1 - wall - 2mm, dv: box_y1 - wall - 2mm) std.top
}
base_post_00 := Post(corner_00, r: 4mm, z0: floor_z1, z1: lid_z0)
base_post_10 := Post(corner_10, r: 4mm, z0: floor_z1, z1: lid_z0)
base_post_01 := Post(corner_01, r: 4mm, z0: floor_z1, z1: lid_z0)
base_post_11 := Post(corner_11, r: 4mm, z0: floor_z1, z1: lid_z0)
base_post_00.body union base
base_post_10.body union base
base_post_01.body union base
base_post_11.body union base
ring_room.body cut base
base_hole_a := Post(a_c, r: (axle_d + press) / 2, z0: bridge_z0 - 1mm, z1: bridge_z1 + 1mm)
base_hole_b := Post(b_c, r: (rod_b + press) / 2, z0: floor_z0 - 1mm, z1: floor_z1 + 1mm)
base_hole_d := Post(d_c, r: (rod_d + press) / 2, z0: floor_z0 - 1mm, z1: floor_z1 + 1mm)
base_hole_a.body cut base
base_hole_b.body cut base
base_hole_d.body cut base
base_pilot_00 := Post(corner_00, r: pilot / 2, z0: lid_z0 - 12mm, z1: lid_z0 + 1mm)
base_pilot_10 := Post(corner_10, r: pilot / 2, z0: lid_z0 - 12mm, z1: lid_z0 + 1mm)
base_pilot_01 := Post(corner_01, r: pilot / 2, z0: lid_z0 - 12mm, z1: lid_z0 + 1mm)
base_pilot_11 := Post(corner_11, r: pilot / 2, z0: lid_z0 - 12mm, z1: lid_z0 + 1mm)
base_pilot_00.body cut base
base_pilot_10.body cut base
base_pilot_01.body cut base
base_pilot_11.body cut base

// == The frame: the lid, the bay, the spine and the clamp's fixed half ===========================
// One print, the bot's backbone: the wheel's axle and the train's rods stand in its lid, the
// electronics bay stands on the lid, and the spine carries it all up beside the valve to the
// clamp round the inlet hex and the pipe.
lid := Block(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, z0: lid_z0, z1: lid_z1)
lid_boss := Post(a_c, r: 9mm, z0: s3_z0, z1: lid_z0)
bay_box := Block(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, z0: lid_z1, z1: bay_z1)
bay_room := Block(x0: box_x0 + wall, x1: box_x1 - wall, y0: box_y0 + wall, y1: box_y1 - wall, z0: lid_z1 - 1mm, z1: bay_z1 + 1mm)
bay_shell := solid(bay_box.body)
bay_room.body cut bay_shell

spine := Block(x0: box_x1, x1: spine_x1, y0: -spine_w / 2, y1: spine_w / 2, z0: bridge_z0, z1: clamp_z1)
clamp_main := Block(x0: -clamp_reach, x1: -split / 2, y0: -clamp_w / 2, y1: clamp_w / 2, z0: clamp_z0, z1: clamp_z1)

// the perfboard's four posts, and four bosses for the cover's screws, clear of the board
in std.top {
  board_00 := point hint((-115.5, -14))
  board_00 coords(du: board_cx - 33mm, dv: board_cy - 23mm) std.top
  board_10 := point hint((-49.5, -14))
  board_10 coords(du: board_cx + 33mm, dv: board_cy - 23mm) std.top
  board_01 := point hint((-115.5, 32))
  board_01 coords(du: board_cx - 33mm, dv: board_cy + 23mm) std.top
  board_11 := point hint((-49.5, 32))
  board_11 coords(du: board_cx + 33mm, dv: board_cy + 23mm) std.top
  cover_w := point hint((-126, -3))
  cover_w coords(du: box_x0 + wall + 2mm, dv: -3mm) std.top                // clear of the USB plug
  cover_e := point hint((-39, 9))
  cover_e coords(du: box_x1 - wall - 2mm, dv: board_cy) std.top
  cover_s := point hint((-65, -24))
  cover_s coords(du: -65mm, dv: box_y0 + wall + 2mm) std.top
  cover_n := point hint((-65, 43))
  cover_n coords(du: -65mm, dv: box_y1 - wall - 2mm) std.top
}
board_post_00 := Post(board_00, r: 3mm, z0: lid_z1, z1: board_z)
board_post_10 := Post(board_10, r: 3mm, z0: lid_z1, z1: board_z)
board_post_01 := Post(board_01, r: 3mm, z0: lid_z1, z1: board_z)
board_post_11 := Post(board_11, r: 3mm, z0: lid_z1, z1: board_z)
cover_post_w := Post(cover_w, r: 4mm, z0: lid_z1, z1: bay_z1)
cover_post_e := Post(cover_e, r: 4mm, z0: lid_z1, z1: bay_z1)
cover_post_s := Post(cover_s, r: 4mm, z0: lid_z1, z1: bay_z1)
cover_post_n := Post(cover_n, r: 4mm, z0: lid_z1, z1: bay_z1)

frame_part := solid(lid.body)
lid_boss.body union frame_part
bay_shell union frame_part
spine.body union frame_part
clamp_main.body union frame_part
cradle union frame_part
board_post_00.body union frame_part
board_post_10.body union frame_part
board_post_01.body union frame_part
board_post_11.body union frame_part
cover_post_w.body union frame_part
cover_post_e.body union frame_part
cover_post_s.body union frame_part
cover_post_n.body union frame_part

// the rods' holes, the motor's boss and shaft, the screws up from the base
lid_hole_a := Post(a_c, r: (axle_d + press) / 2, z0: s3_z0 - 1mm, z1: lid_z1 + 1mm)
lid_hole_b := Post(b_c, r: (rod_b + press) / 2, z0: lid_z0 - 1mm, z1: lid_z1 - 1mm)
lid_hole_d := Post(d_c, r: (rod_d + press) / 2, z0: lid_z0 - 1mm, z1: lid_z1 - 1mm)
motor_boss_room := Post(m_c, r: motor130_dims.boss_d / 2 + gap, z0: lid_z1 - motor130_dims.boss_h - gap,
                        z1: lid_z1 + 1mm)
motor_shaft_room := Post(m_c, r: 2.5mm, z0: lid_z0 - 1mm, z1: lid_z1)
lid_hole_a.body cut frame_part
lid_hole_b.body cut frame_part
lid_hole_d.body cut frame_part
motor_boss_room.body cut frame_part
motor_shaft_room.body cut frame_part
lid_screw_00 := Post(corner_00, r: m3_clear / 2, z0: lid_z0 - 1mm, z1: lid_z1 + 1mm)
lid_screw_10 := Post(corner_10, r: m3_clear / 2, z0: lid_z0 - 1mm, z1: lid_z1 + 1mm)
lid_screw_01 := Post(corner_01, r: m3_clear / 2, z0: lid_z0 - 1mm, z1: lid_z1 + 1mm)
lid_screw_11 := Post(corner_11, r: m3_clear / 2, z0: lid_z0 - 1mm, z1: lid_z1 + 1mm)
lid_screw_00.body cut frame_part
lid_screw_10.body cut frame_part
lid_screw_01.body cut frame_part
lid_screw_11.body cut frame_part
board_pilot_00 := Post(board_00, r: 1.1mm, z0: board_z - 8mm, z1: board_z + 1mm)
board_pilot_10 := Post(board_10, r: 1.1mm, z0: board_z - 8mm, z1: board_z + 1mm)
board_pilot_01 := Post(board_01, r: 1.1mm, z0: board_z - 8mm, z1: board_z + 1mm)
board_pilot_11 := Post(board_11, r: 1.1mm, z0: board_z - 8mm, z1: board_z + 1mm)
board_pilot_00.body cut frame_part
board_pilot_10.body cut frame_part
board_pilot_01.body cut frame_part
board_pilot_11.body cut frame_part
cover_pilot_w := Post(cover_w, r: pilot / 2, z0: bay_z1 - 12mm, z1: bay_z1 + 1mm)
cover_pilot_e := Post(cover_e, r: pilot / 2, z0: bay_z1 - 12mm, z1: bay_z1 + 1mm)
cover_pilot_s := Post(cover_s, r: pilot / 2, z0: bay_z1 - 12mm, z1: bay_z1 + 1mm)
cover_pilot_n := Post(cover_n, r: pilot / 2, z0: bay_z1 - 12mm, z1: bay_z1 + 1mm)
cover_pilot_w.body cut frame_part
cover_pilot_e.body cut frame_part
cover_pilot_s.body cut frame_part
cover_pilot_n.body cut frame_part

// the cable entries, in the bay's far end wall: a grommet for the thermostat's and the supply's
// cable, low beside the motor, and a window on the XIAO's USB-C that a cable's moulded plug
// passes through to mate (the receptacle stands back from the wall's inside face)
grommet := BoreX(y: 30mm, z: lid_z1 + 12mm, d: 8mm, x0: box_x0 - 1mm, x1: box_x0 + wall + 1mm)
usb_slot := Block(x0: box_x0 - 1mm, x1: box_x0 + wall + 1mm,
                  y0: xiao_cy - xiao_dims.plug_w / 2 - gap, y1: xiao_cy + xiao_dims.plug_w / 2 + gap,
                  z0: usb_z - xiao_dims.plug_h / 2 - gap, z1: usb_z + xiao_dims.plug_h / 2 + gap)
grommet.body cut frame_part
usb_slot.body cut frame_part

// == The clamp ===================================================================================
// A block round the inlet hex and the pipe above it, split on the stem's plane square to x:
// the fixed half is the frame's, the cap bolts to it from +x with four M4 bolts, their nuts in
// pockets in the fixed half's back.  The hex's pocket stands a print's clearance off every flat,
// so the hex takes the handle's torque; the pipe's bore is the pipe's, so the closing split
// grips it.  The clamp hangs on the hex's top face.
clamp_cap := Block(x0: split / 2, x1: clamp_reach, y0: -clamp_w / 2, y1: clamp_w / 2, z0: clamp_z0, z1: clamp_z1)
cap_part := solid(clamp_cap.body)

hex_room := HexBar(std.top.origin, valve.top_ref, af: body_dims.inlet_af + 2 * gap, phase: 0deg,
                   z0: clamp_z0 - 1mm, z1: body_dims.inlet_top + 0.2mm)
pipe_room := RoundBar(std.top.origin, d: pipe_dims.d + 0.2mm, z0: body_dims.inlet_top,
                      z1: clamp_z1 + 1mm)
hex_room.bar cut frame_part
hex_room.bar cut cap_part
pipe_room.bar cut frame_part
pipe_room.bar cut cap_part

repeat 2 as i {
  bolt_lo := BoreX(y: (2 * i - 1) * clamp_bolt_y, z: clamp_z0 + 5mm, d: m4_clear,
                   x0: -clamp_reach - 1mm, x1: clamp_reach + 1mm)
  bolt_hi := BoreX(y: (2 * i - 1) * clamp_bolt_y, z: clamp_z1 - 7mm, d: m4_clear,
                   x0: -clamp_reach - 1mm, x1: clamp_reach + 1mm)
  nut_lo := NutX(y: (2 * i - 1) * clamp_bolt_y, z: clamp_z0 + 5mm, af: m4_nut_af,
                 x0: -clamp_reach - 1mm, x1: -clamp_reach + 4mm)
  nut_hi := NutX(y: (2 * i - 1) * clamp_bolt_y, z: clamp_z1 - 7mm, af: m4_nut_af,
                 x0: -clamp_reach - 1mm, x1: -clamp_reach + 4mm)
  bolt_lo.body cut frame_part
  bolt_lo.body cut cap_part
  bolt_hi.body cut frame_part
  bolt_hi.body cut cap_part
  nut_lo.nut.bar cut frame_part
  nut_hi.nut.bar cut frame_part
}

// == The cover ===================================================================================
cover := Block(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, z0: bay_z1, z1: bay_z1 + wall)
cover_part := solid(cover.body)
cover_hole_w := Post(cover_w, r: m3_clear / 2, z0: bay_z1 - 1mm, z1: bay_z1 + wall + 1mm)
cover_hole_e := Post(cover_e, r: m3_clear / 2, z0: bay_z1 - 1mm, z1: bay_z1 + wall + 1mm)
cover_hole_s := Post(cover_s, r: m3_clear / 2, z0: bay_z1 - 1mm, z1: bay_z1 + wall + 1mm)
cover_hole_n := Post(cover_n, r: m3_clear / 2, z0: bay_z1 - 1mm, z1: bay_z1 + wall + 1mm)
cover_hole_w.body cut cover_part
cover_hole_e.body cut cover_part
cover_hole_s.body cut cover_part
cover_hole_n.body cut cover_part

// == The electronics =============================================================================
// Bought boards soldered on headers to a 5 x 7 cm perfboard (boards.sv), and the room the rest
// take (~ sizes):
//   - a Seeed XIAO ESP32-C3, its USB-C to the end wall's window: power, programming and logs;
//   - a Pololu DRV8874 carrier: the H-bridge, and its CS pin gives the motor's current as
//     ~1.1 V/A, which the XIAO's ADC reads for the end-of-travel sensing;
//   - a mini buck module (MP1584 size, 22 x 17) and a bridge rectifier, for 24 VAC off the
//     thermostat's transformer; with a 5 V USB supply instead, neither is fitted;
//   - a 3-way 5.08 mm screw terminal for the supply's and the thermostat's wires, by the grommet.
perfboard := Block(x0: board_cx - board_w / 2, x1: board_cx + board_w / 2, y0: board_cy - board_h / 2, y1: board_cy + board_h / 2, z0: board_z, z1: board_top)
in std.top {
  xiao_c := point hint((-104.1, 17.9))
  xiao_c coords(du: xiao_cx, dv: xiao_cy) std.top
  drv_c := point hint((-62.2, -5))
  drv_c coords(du: drv_cx, dv: drv_cy) std.top
}
xiao_at := point
xiao_at raised(d: board_top, along: std.z) xiao_c
xiao := XiaoEsp32C3(xiao_dims, h: header_dims)
xiao seats(turn: 0deg, up: std.z, east: std.x) xiao_at
drv_at := point
drv_at raised(d: board_top, along: std.z) drv_c
driver := Drv8874(drv8874_dims, h: header_dims)
driver seats(turn: 0deg, up: std.z, east: std.x) drv_at
buck := Block(x0: board_cx - 12mm, x1: board_cx + 10mm, y0: board_cy - 23mm, y1: board_cy - 6mm, z0: board_top, z1: board_top + 5mm)
terminal := Block(x0: board_cx - 34mm, x1: board_cx - 19mm, y0: board_cy - 23mm, y1: board_cy - 15mm, z0: board_top, z1: board_top + 10mm)

// The boards in the bay: a mated USB cable's plug through the end wall's window, and the boards,
// their headers and the pins' tails under the perfboard clear of the frame, the motor and the
// cover.
claim xiao.plug clear(0.2mm) frame_part
claim xiao.board clear(0.5mm) frame_part
claim xiao.headers clear(0.5mm) frame_part
claim driver.board clear(0.5mm) frame_part
claim driver.rows.headers clear(0.5mm) frame_part
claim xiao.headers clear(0.5mm) motor.motor
claim driver.rows.headers clear(0.5mm) motor.motor
claim xiao.board clear(1mm) cover_part
claim driver.board clear(1mm) cover_part
