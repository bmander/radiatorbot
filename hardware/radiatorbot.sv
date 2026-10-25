// The radiator bot: a gearmotor that clamps to the valve's supply pipe and turns the star handle
// through a wheel conjugate to it.
//
// Coordinates are the valve's (radiator_valve.sv): the stem is std.z, z = 0 is the packing nut's
// bottom face, the radiator lies toward +x.  The bot hangs on the valve's -x side:
//
//   - the **wheel** turns about an axle `wheel_c` out along -x, at the handle's height.  Its
//     pockets are what the handle, drafted as it is, sweeps through its blank as the two turn
//     together and the stem screws down its travel, one statement: the conjugate the handle would
//     cut if it were a gear shaper.  A 48-tooth ring on its top face is driven by the gearbox;
//     a collar either side of it keeps it on its axle;
//   - the **gearbox** above it is five printed spur stages on two drill-rod axles, B and D, the
//     130 motor's pinion driving the first; its base's floor stops short of the wheel's ring;
//   - the **frame** is the gearbox's lid, the electronics bay standing on it (the motor, the
//     perfboard over the motor with the ESP32, the motor driver and its current monitor on it, the
//     cable entries), and the spine up beside the valve to the **clamp**, a split block round the
//     inlet hex and the supply pipe above it.  The hex takes the handle's reaction torque
//     positively; the bolted cap closes the clamp from +x.
//
// Everything is printed but the drill rod the gears turn on, so the fits below are an FDM
// printer's.  Scrub `handle_turn`: the wheel and the train turn with the handle.  Set `shaped` to
// 0 to draw every gear and the wheel as blanks while the layout is worked on (building them all
// takes a few minutes).  The design table's requirements are claims, judged before the solve;
// `solventc radiatorbot.sv --where handle_stall_torque` reads any figure back in its unit.  Set
// `checks` to 1 to judge every clearance as well, the wheel against the handle through a whole
// period of their mesh (about four minutes more).
//
// The file runs from the numbers to the parts: the stock and the fits, the drive, the heights
// and the plan, then the building blocks, then each part in turn, then the clearances.  Every
// size a part is drawn to is named in the tables up top, so a change is made there.
//
// Numbers marked "~" are estimates to check: the motor's figures (motor130.sv) and the stem's
// travel, which no measurement has said yet.

unit mm
use std
use std (vertical, horizontal, turns, coords, seats, raised)
use radiator_valve (RadiatorValve, handle_dims, body_dims, pipe_dims, handle_gap)
use radiator_valve (StarOutline, StarSizes, StarHandle, HexBar, RoundBar)
use gears (ShapedSpur)
use motor130 (Motor130, MotorCan, motor130_dims, motor130_free, motor130_stall_torque)
use boards (XiaoEsp32C3, Drv8871, Ina219, xiao_dims, drv8871_dims, ina219_dims, header_dims, pitch)

shaped := 1                    // 1: shape the gears and the wheel; 0: blanks, for a quick look
checks := 0                    // 1: judge every clearance (needs `shaped`; ~4 minutes)

// == Stock =======================================================================================
// Drill rod.  The gears and the wheel turn on fixed rods; the housing holds the rods.
axle_d := 0.5in                 // A, the wheel's axle
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

axle_bore := axle_d + run       // the wheel's bore, and the collars'
rod_bore := rod_d + run         // every compound's bore

// == The drive ===================================================================================

// The wheel and the handle.  The star is a four-toothed gear of pitch radius `star_pitch_r`; the
// wheel has `wheel_n` pockets, so the handle turns wheel_n / 4 times a turn of the wheel.
wheel_n := 6
star_pitch_r := 24mm
wheel_c := star_pitch_r * (1 + wheel_n / 4)            // the stem to the wheel's axle: 60 mm
wheel_backlash := 0.6mm         // the chrome casting's arms against printed pockets
stem_travel := 4mm              // ~ how far the handle drops opening the valve, closed to open

// The handle as measured stands closed, its top face `handle_gap` under the packing nut;
// opening, a right-hand stem screws it down `stem_travel`.  The wheel spans the arms' depth with
// half a millimetre spare above and the rolled rim spare below.
top0 := -handle_gap
wheel_top := top0 + 0.5mm
wheel_bottom := top0 - handle_dims.h + 1.5mm
wheel_rim := wheel_c - handle_dims.waist / 2 - 1mm      // clear of the star's waist by 1 mm

// The gear train, motor to wheel.  Stage 1 runs the motor into B; stages 2-5 ping-pong between
// B and D, which stand one centre distance apart (`cd_bd`: 16 + 64 teeth at module 0.8, or
// 16 + 48 at module 1); the last pinion, on B, drives the wheel's ring.  Every pinion is shifted
// +0.3 against undercut and its gear -0.3, so the centre distances stay nominal.
//
// The pinions on the rods have 16 teeth, not 12: a 12-tooth pinion's roots at module 0.8 stand
// inside a bore on 0.311 in rod.  The claim below holds every such pinion to a 1.5 mm wall
// between its roots and its bore.
pa := 20deg
pin_shift := 0.3
m_small := 0.8mm                // stages 1-4: the finest an 0.4 mm nozzle prints well
m_s5 := 1mm                     // stage 5
m_fin := 1.5mm                  // the ring and its pinion
motor_pin_n := 12               // the motor's pinion, pressed on its 2 mm shaft
s1_n := 24                      // stage 1's gear, on B
pin_n := 16                     // stages 2-5's pinions, on the rods
big_n := 64                     // stages 2-4's gears
s5_n := 48                      // stage 5's gear, on B
fin_n := 12                     // the last pinion, on B
ring_n := 48
cd_s1 := m_small * (motor_pin_n + s1_n) / 2             // 14.4 mm, the motor to B
cd_bd := m_small * (pin_n + big_n) / 2                  // 32 mm, B to D
cd_fin := m_fin * (fin_n + ring_n) / 2                  // 45 mm, B to the wheel
claim m_s5 * (pin_n + s5_n) / 2 == cd_bd                // stage 5 stands on the same two rods
pin_wall := m_small * (pin_n / 2 + pin_shift - 1.25) - rod_bore / 2   // roots to bore, module 0.8
claim pin_wall >= 1.5mm

// The bearings of the lines of centres, from +x: B to the wheel 0deg, B to D 75deg, B to the
// motor -60deg; each the other way round is 180deg on.
bd_bearing := 75deg
bm_bearing := -60deg

gear_ratio := s1_n / motor_pin_n * (big_n / pin_n) ^ 3 * s5_n / pin_n * ring_n / fin_n
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

// How fast each axle's part turns, in turns a turn of the handle: the wheel -4/6, and each
// compound back up the train by its mesh's ratio, reversed, up to the motor's.
wheel_rate := -4 / wheel_n
b3_rate := -wheel_rate * ring_n / fin_n
d2_rate := -b3_rate * s5_n / pin_n
b2_rate := -d2_rate * big_n / pin_n
d1_rate := -b2_rate * big_n / pin_n
b1_rate := -d1_rate * big_n / pin_n
motor_rate := -b1_rate * s1_n / motor_pin_n
claim motor_rate == -handle_ratio

// == Heights =====================================================================================
// From the floor up: the ring and the last pinion, stages 5 to 1, the lid, the electronics bay
// and its cover.  Faces are 5 mm at module 0.8, 6 at module 1 and 10 at module 1.5, with half a
// millimetre between layers.  The motor stands face down on the lid, its pinion through it.
floor_z0 := -0.1mm              // the base's floor, round B and D only: the wheel turns under it
floor_z1 := floor_z0 + 3mm
ring_z0 := 3mm                  // the ring's teeth; the web under it runs down to the wheel
ring_z1 := ring_z0 + 10mm
fin_z0 := ring_z0 + 0.5mm       // the last pinion
s5_z0 := fin_z0 + 10.5mm
s4_z0 := s5_z0 + 6.5mm
s3_z0 := s4_z0 + 5.5mm
s2_z0 := s3_z0 + 5.5mm
s1_z0 := s2_z0 + 5.5mm
lid_z0 := s1_z0 + 5.5mm
lid_z1 := lid_z0 + 3mm
// The wheel's axle: a collar under the wheel and one over it, a print's clearance off its faces,
// and the bridge across the base that holds the axle standing on the upper collar.
collar_h := 6mm
collar_r := axle_d / 2 + 5mm
lo_collar_z1 := wheel_bottom - gap
hi_collar_z0 := ring_z1 + gap
bridge_z0 := hi_collar_z0 + collar_h
bridge_z1 := bridge_z0 + 6mm
spine_z0 := s5_z0               // the spine's foot, over the wheel's ring
board_z := lid_z1 + motor130_dims.len + 3mm             // the perfboard's underside, over the motor
bay_z1 := board_z + 1.6mm + 14mm                        // room for the modules on their headers
clamp_z0 := body_dims.inlet_top - body_dims.inlet_h     // the inlet hex's underside
clamp_z1 := clamp_z0 + 31.7mm

// == Plan ========================================================================================
// The housing's outline, the clamp and the spine, in plan (x, y): the box the base, the lid, the
// bay and the cover all share.  Its end wall and its sides stand about 2.4 mm off the tips of
// the 64-tooth gears on B (at x = -105) and on D (30.9 mm up +y).
box_x0 := -136mm
box_x1 := -35mm
box_y0 := -31mm
box_y1 := 62mm
spine_x1 := -21.5mm             // 4 mm off the valve's bulge and collar
spine_w := 28mm
clamp_reach := 26mm             // each half of the clamp, out from the stem
clamp_w := 50mm
clamp_bolt_y := 20mm
screw_inset := wall + 2mm       // the base's and the cover's screws, in from the box's outside
board_w := 70mm                 // a 5 x 7 cm perfboard
board_h := 50mm
board_cx := box_x0 + 47.5mm     // its USB end set by the end wall's window
board_cy := 9mm
board_post_dx := 33mm           // its corner holes, from its centre
board_post_dy := 23mm
board_cols := 24                // its holes, 0.1 in apart, centred on it
board_rows := 18
grid_x0 := board_cx - (board_cols - 1) * pitch / 2       // the first column's holes
grid_y0 := board_cy - (board_rows - 1) * pitch / 2       // the first row's
board_top := board_z + 1.6mm
// The boards on the perfboard's grid (boards.sv), each at its pin field's middle: the XIAO's pins
// in columns 0-6, rows 9 and 15, its USB out over the board's end toward the bay's end wall; the
// driver's in column 15, rows 2-5, its terminals toward +x; the current monitor's in columns
// 15-20, row 11, its board toward +y.
xiao_cx := grid_x0 + 3 * pitch
xiao_cy := grid_y0 + 12 * pitch
drv_cx := grid_x0 + 15 * pitch
drv_cy := grid_y0 + 3.5 * pitch
ina_cx := grid_x0 + 17.5 * pitch
ina_cy := grid_y0 + 11 * pitch
usb_z := board_top + header_dims.body_h + xiao_dims.pcb_t + xiao_dims.usb_h / 2   // its axis

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
// from the pinion's axle to the gear's, and `drives` says which this is: 1 for the pinion, which
// drives, 0 for the gear it drives.  The pinion is shifted +pin_shift and stands a tooth on the
// line of centres; its gear is shifted -pin_shift and stands a space on it (the figure's cut
// space is on +v: a pinion turned `bearing - 90deg - 180deg / N`, its gear `bearing + 90deg`).
// Gears of one size and face are one figure, shaped once.  A large gear is spoked to save
// material: `spokes` of them, `web` wide, between a hub of radius `hub` (clear of the pinion it
// carries) and a rim `web` thick under its roots; 0 spokes, solid.
component Gear(c: point, z: Length, bearing: Angle, drives: Int, N: Int, m: Length, face: Length,
               bore: Length, spokes: Int, hub: Length, web: Length) {
  at := point
  at raised(d: z, along: std.z) c
  g := ShapedSpur(N: N, m: m, phi: pa, shift: (2 * drives - 1) * pin_shift, thin: thin,
                  z0: 0mm, z1: face, bore: bore, shaped: shaped, chamfer: chamfer,
                  spokes: spokes, hub: hub, web: web)
  g seats(turn: bearing + 90deg + drives * (180deg - 180deg / N), up: std.z, east: std.x) at
  construction gear := solid(g.gear)
}

// == The wheel ===================================================================================

// The wheel conjugate to the star: a disc of radius `rim` about `c` from z_bot to z_top, less
// everything the handle sweeps through as it turns about `stem` and the wheel about `spindle`,
// `n / 4` handle turns a wheel turn, over a whole turn of the wheel.  The cutter is all the
// handle, grown by `grow`, occupies over its travel `travel` down from where it stands closed
// (its top face `top_z` up): the draft leans its sides in toward the bottom face, so at every
// height the widest section of it is the one nearest its top face.  Below the top face where
// it stands open (on `open_top`) that is the open star's own; above it, up to the closed top
// face and on up past the wheel so the pockets stay open, it is the top face's, which passes
// through every height in between.  The cutter is the open star and that prism; the star where
// it stands closed lies inside them.
component ConjugateWheel(open_top: plane, stem: line, spindle: line, c: point, s: StarSizes,
                         n: Int, rim: Length, z_bot: Length, z_top: Length, top_z: Length,
                         travel: Length, grow: Length, shaped: Int) {
  grown := {span: s.span + 2 * grow, waist: s.waist + 2 * grow, h: s.h, tip_r: s.tip_r + grow,
            fillet_r: s.fillet_r - grow, draft: s.draft, rim_r: s.rim_r, edge_r: s.edge_r,
            stem_d: s.stem_d}
  opened := StarOutline(open_top, s: grown)
  construction cutter := solid(opened.outline, from: -s.h, to: 0mm, draft: s.draft)
  crown := solid(opened.outline, from: 0mm, to: z_top - (top_z - travel) + 1mm)
  crown union cutter

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
// `cd_bd` from B at `bd_bearing`; the motor's axis M is `cd_s1` from B at `bm_bearing`.
in std.top {
  a_c := point in std.top, std.front
  std.top.origin distance(-wheel_c, along: u) a_c
  b_c := point in std.top, std.front
  std.top.origin distance(-wheel_c - cd_fin, along: u) b_c
  d_c := point hint((-wheel_c - cd_fin + cd_bd * cos(bd_bearing), cd_bd * sin(bd_bearing)))
  b_c distance(cd_bd) d_c
  m_c := point hint((-wheel_c - cd_fin + cd_s1 * cos(bm_bearing), cd_s1 * sin(bm_bearing)))
  b_c distance(cd_s1) m_c
  construction b_d := line(b_c, d_c)
  construction b_m := line(b_c, m_c)
  construction b_a := line(b_c, a_c)
  b_a angle(bd_bearing) b_d
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

// The rods: A held in the base's bridge and through the lid, B and D in the floor and up into
// the lid's blind holes.
axle_a := Post(a_c, r: axle_d / 2, z0: lo_collar_z1 - collar_h, z1: lid_z1)
rod_at_b := Post(b_c, r: rod_d / 2, z0: floor_z0, z1: lid_z1 - 1mm)
rod_at_d := Post(d_c, r: rod_d / 2, z0: floor_z0, z1: lid_z1 - 1mm)

// == The wheel and its ring ======================================================================
// the handle's top face where it stands open, `stem_travel` down
open_top := plane
fix(origin == (0mm, 0mm, top0 - stem_travel)) open_top
fix(dir == (1, 0, 0)) open_top.u
fix(dir == (0, 1, 0)) open_top.v
cw := ConjugateWheel(open_top, valve.stem_axis, a_spindle, a_c, s: handle_dims, n: wheel_n,
                     rim: wheel_rim, z_bot: wheel_bottom, z_top: wheel_top, top_z: top0,
                     travel: stem_travel, grow: wheel_backlash / 2, shaped: shaped)

ring_gear := Gear(a_c, z: ring_z0, bearing: 0deg, drives: 0, N: ring_n, m: m_fin,
                  face: ring_z1 - ring_z0, bore: axle_bore, spokes: 0, hub: 0mm, web: 0mm)

web := Post(a_c, r: 33mm, z0: wheel_top, z1: ring_z0 + bond)
wheel_bore := Post(a_c, r: axle_bore / 2, z0: wheel_bottom - 1mm, z1: ring_z1 + 1mm)
construction wheel_part := solid(cw.wheel)
web.body union wheel_part
ring_gear.gear union wheel_part
wheel_bore.body cut wheel_part

// The wheel kept on its axle: a collar under it, and one over it, under the base's bridge.  The
// two are one print.
lo_collar := Collar(x: -wheel_c, y: 0mm, r: collar_r, bore: axle_bore, z0: lo_collar_z1 - collar_h,
                    z1: lo_collar_z1)
hi_collar := Collar(x: -wheel_c, y: 0mm, r: collar_r, bore: axle_bore, z0: hi_collar_z0,
                    z1: hi_collar_z0 + collar_h)
collar_part := solid(lo_collar.part)

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
// B's second: stage 3's gear over stage 4's pinion
b2_gear := Gear(b_c, z: s3_z0, bearing: bd_bearing + 180deg, drives: 0, N: big_n, m: m_small,
                face: 5mm, bore: rod_bore, spokes: 5, hub: 9mm, web: 2.4mm)
b2_pin := Gear(b_c, z: s4_z0, bearing: bd_bearing, drives: 1, N: pin_n, m: m_small,
               face: s3_z0 - s4_z0 + bond, bore: rod_bore, spokes: 0, hub: 0mm, web: 0mm)
// D's second: stage 4's gear over stage 5's pinion, at module 1
d2_gear := Gear(d_c, z: s4_z0, bearing: bd_bearing, drives: 0, N: big_n, m: m_small,
                face: 5mm, bore: rod_bore, spokes: 5, hub: 11mm, web: 3mm)
d2_pin := Gear(d_c, z: s5_z0, bearing: bd_bearing + 180deg, drives: 1, N: pin_n, m: m_s5,
               face: s4_z0 - s5_z0 + bond, bore: rod_bore, spokes: 0, hub: 0mm, web: 0mm)
// B's third: stage 5's gear over the last pinion, which drives the wheel's ring
b3_gear := Gear(b_c, z: s5_z0, bearing: bd_bearing + 180deg, drives: 0, N: s5_n, m: m_s5,
                face: 6mm, bore: rod_bore, spokes: 0, hub: 0mm, web: 0mm)
b3_pin := Gear(b_c, z: fin_z0, bearing: 0deg, drives: 1, N: fin_n, m: m_fin,
               face: s5_z0 - fin_z0 + bond, bore: rod_bore, spokes: 0, hub: 0mm, web: 0mm)

construction motor_pinion := solid(motor_pin.gear)
construction b1 := solid(b1_gear.gear)
b1_pin.gear union b1
construction d1 := solid(d1_gear.gear)
d1_pin.gear union d1
construction b2 := solid(b2_gear.gear)
b2_pin.gear union b2
construction d2 := solid(d2_gear.gear)
d2_pin.gear union d2
construction b3 := solid(b3_gear.gear)
b3_pin.gear union b3

// The train turning with the handle, at the rates worked out with the drive.
wheel_turn := frame
wheel_turn turns(wheel_rate) a_spindle
fix(value == handle_turn) wheel_turn
b3_turn := frame
b3_turn turns(b3_rate) b_spindle
fix(value == handle_turn) b3_turn
d2_turn := frame
d2_turn turns(d2_rate) d_spindle
fix(value == handle_turn) d2_turn
b2_turn := frame
b2_turn turns(b2_rate) b_spindle
fix(value == handle_turn) b2_turn
d1_turn := frame
d1_turn turns(d1_rate) d_spindle
fix(value == handle_turn) d1_turn
b1_turn := frame
b1_turn turns(b1_rate) b_spindle
fix(value == handle_turn) b1_turn
motor_turn := frame
motor_turn turns(motor_rate) m_spindle
fix(value == handle_turn) motor_turn

wheel := wheel_part in wheel_turn
compound_b3 := b3 in b3_turn
compound_d2 := d2 in d2_turn
compound_b2 := b2 in b2_turn
compound_d1 := d1 in d1_turn
compound_b1 := b1 in b1_turn
pinion := motor_pinion in motor_turn

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
// wheel's ring turns under the train (the whole of its +x end, down there), and a bridge across
// it, standing on the upper collar, holds the wheel's axle.  Four M3 screws down through the lid
// hold it up to the frame (below).
base_box := Block(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, z0: floor_z0, z1: lid_z0)
base_cavity := Block(x0: box_x0 + wall, x1: box_x1 - wall, y0: box_y0 + wall, y1: box_y1 - wall,
                     z0: floor_z1, z1: lid_z0 + 1mm)
base_shell := solid(base_box.body)
base_cavity.body cut base_shell

bridge := Block(x0: -wheel_c, x1: box_x1 - wall, y0: -collar_r, y1: collar_r, z0: bridge_z0,
                z1: bridge_z1)
bridge_boss := Post(a_c, r: collar_r, z0: bridge_z0, z1: bridge_z1)
ring_room := Post(a_c, r: 39mm, z0: floor_z0 - 1mm, z1: ring_z1 + 0.5mm)
ring_side := Block(x0: -wheel_c, x1: box_x1 + 1mm, y0: box_y0 - 1mm, y1: box_y1 + 1mm,
                   z0: floor_z0 - 1mm, z1: ring_z1 + 0.5mm)       // and the box's end over it
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

// == The frame: the lid, the bay, the spine and the clamp's fixed half ===========================
// One print, the bot's backbone: the wheel's axle and the train's rods stand in its lid, the
// electronics bay stands on it, and the spine carries it all up beside the valve to the clamp
// round the inlet hex and the pipe.
lid := Block(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, z0: lid_z0, z1: lid_z1)
bay_box := Block(x0: box_x0, x1: box_x1, y0: box_y0, y1: box_y1, z0: lid_z1, z1: bay_z1)
bay_room := Block(x0: box_x0 + wall, x1: box_x1 - wall, y0: box_y0 + wall, y1: box_y1 - wall,
                  z0: lid_z1 - 1mm, z1: bay_z1 + 1mm)
bay_shell := solid(bay_box.body)
bay_room.body cut bay_shell

spine := Block(x0: box_x1, x1: spine_x1, y0: -spine_w / 2, y1: spine_w / 2, z0: spine_z0,
               z1: clamp_z1)
clamp_main := Block(x0: -clamp_reach, x1: -split / 2, y0: -clamp_w / 2, y1: clamp_w / 2,
                    z0: clamp_z0, z1: clamp_z1)

// the rods' holes, the motor's boss and shaft
lid_hole_a := Post(a_c, r: (axle_d + press) / 2, z0: lid_z0 - 1mm, z1: lid_z1 + 1mm)
lid_hole_b := Post(b_c, r: (rod_d + press) / 2, z0: lid_z0 - 1mm, z1: lid_z1 - 1mm)
lid_hole_d := Post(d_c, r: (rod_d + press) / 2, z0: lid_z0 - 1mm, z1: lid_z1 - 1mm)
motor_boss_room := Post(m_c, r: motor130_dims.boss_d / 2 + gap,
                        z0: lid_z1 - motor130_dims.boss_h - gap, z1: lid_z1 + 1mm)
motor_shaft_room := Post(m_c, r: 2.5mm, z0: lid_z0 - 1mm, z1: lid_z1)

// the cable entries, in the bay's far end wall: a grommet for the thermostat's and the supply's
// cable, low beside the motor, and a window on the XIAO's USB-C that a cable's moulded plug
// passes through to mate (the receptacle stands back from the wall's inside face)
grommet := BoreX(y: 30mm, z: lid_z1 + 12mm, d: 8mm, x0: box_x0 - 1mm, x1: box_x0 + wall + 1mm)
usb_slot := Block(x0: box_x0 - 1mm, x1: box_x0 + wall + 1mm,
                  y0: xiao_cy - xiao_dims.plug_w / 2 - gap, y1: xiao_cy + xiao_dims.plug_w / 2 + gap,
                  z0: usb_z - xiao_dims.plug_h / 2 - gap, z1: usb_z + xiao_dims.plug_h / 2 + gap)

frame_part := solid(lid.body)
bay_shell union frame_part
spine.body union frame_part
clamp_main.body union frame_part
cradle union frame_part
lid_hole_a.body cut frame_part
lid_hole_b.body cut frame_part
lid_hole_d.body cut frame_part
motor_boss_room.body cut frame_part
motor_shaft_room.body cut frame_part
grommet.body cut frame_part
usb_slot.body cut frame_part

// == The screws: the base to the lid, the perfboard, the cover ===================================
// The base's four, up from posts in its corners through the lid, their heads in the bay.
repeat 2 as i {
  repeat 2 as j {
    base_at := At(x: box_x0 + screw_inset + i * (box_x1 - box_x0 - 2 * screw_inset),
                  y: box_y0 + screw_inset + j * (box_y1 - box_y0 - 2 * screw_inset))
    base_screw := ScrewPost(base_at.p, r: 4mm, z0: floor_z1, z1: lid_z0, hole_d: pilot,
                            depth: 12mm)
    lid_screw := Post(base_at.p, r: m3_clear / 2, z0: lid_z0 - 1mm, z1: lid_z1 + 1mm)
    base_screw.post union base
    base_screw.hole cut base
    lid_screw.body cut frame_part
  }
}

// The perfboard's four M2.5s, into posts on the lid at its corner holes.
repeat 2 as i {
  repeat 2 as j {
    board_at := At(x: board_cx + (2 * i - 1) * board_post_dx,
                   y: board_cy + (2 * j - 1) * board_post_dy)
    board_screw := ScrewPost(board_at.p, r: 3mm, z0: lid_z1, z1: board_z, hole_d: 2.2mm,
                             depth: 8mm)
    board_screw.post union frame_part
    board_screw.hole cut frame_part
  }
}

// The cover's four, down through it into posts in the bay's walls, clear of the board: west by
// the end wall (moved to y = -3 mm, clear of the USB plug), east by the spine, south and north.
cover_w := At(x: box_x0 + screw_inset, y: -3mm)
cover_e := At(x: box_x1 - screw_inset, y: board_cy)
cover_s := At(x: -65mm, y: box_y0 + screw_inset)
cover_n := At(x: -65mm, y: box_y1 - screw_inset)
cover_screw_w := ScrewPost(cover_w.p, r: 4mm, z0: lid_z1, z1: bay_z1, hole_d: pilot, depth: 12mm)
cover_screw_e := ScrewPost(cover_e.p, r: 4mm, z0: lid_z1, z1: bay_z1, hole_d: pilot, depth: 12mm)
cover_screw_s := ScrewPost(cover_s.p, r: 4mm, z0: lid_z1, z1: bay_z1, hole_d: pilot, depth: 12mm)
cover_screw_n := ScrewPost(cover_n.p, r: 4mm, z0: lid_z1, z1: bay_z1, hole_d: pilot, depth: 12mm)
cover_screw_w.post union frame_part
cover_screw_e.post union frame_part
cover_screw_s.post union frame_part
cover_screw_n.post union frame_part
cover_screw_w.hole cut frame_part
cover_screw_e.hole cut frame_part
cover_screw_s.hole cut frame_part
cover_screw_n.hole cut frame_part

// == The clamp ===================================================================================
// A block round the inlet hex and the pipe above it, split on the stem's plane square to x:
// the fixed half is the frame's, the cap bolts to it from +x with four M4 bolts, their nuts in
// pockets in the fixed half's back.  The hex's pocket stands a print's clearance off every flat,
// so the hex takes the handle's torque; the pipe's bore is the pipe's, so the closing split
// grips it.  The clamp hangs on the hex's top face.
clamp_cap := Block(x0: split / 2, x1: clamp_reach, y0: -clamp_w / 2, y1: clamp_w / 2,
                   z0: clamp_z0, z1: clamp_z1)
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
cover_hole_w := Post(cover_w.p, r: m3_clear / 2, z0: bay_z1 - 1mm, z1: bay_z1 + wall + 1mm)
cover_hole_e := Post(cover_e.p, r: m3_clear / 2, z0: bay_z1 - 1mm, z1: bay_z1 + wall + 1mm)
cover_hole_s := Post(cover_s.p, r: m3_clear / 2, z0: bay_z1 - 1mm, z1: bay_z1 + wall + 1mm)
cover_hole_n := Post(cover_n.p, r: m3_clear / 2, z0: bay_z1 - 1mm, z1: bay_z1 + wall + 1mm)
cover_hole_w.body cut cover_part
cover_hole_e.body cut cover_part
cover_hole_s.body cut cover_part
cover_hole_n.body cut cover_part

// == The electronics =============================================================================
// Bought boards soldered on headers to a 5 x 7 cm perfboard (boards.sv), and the room the rest
// take (~ sizes):
//   - a Seeed XIAO ESP32-C3, its USB-C to the end wall's window: power, programming and logs;
//   - an Adafruit DRV8871 breakout: the H-bridge, its terminals toward the bay's +x wall;
//   - an Adafruit INA219 breakout in the driver's supply: the motor's current over I2C, which the
//     XIAO reads for the end-of-travel sensing;
//   - a buck module (22 x 17) and a bridge rectifier: the motor's 7.5 V, off 24 VAC from the
//     thermostat's transformer or a DC adapter (the DRV8871 wants 6.5 V at least);
//   - a mini buck module (Mini-360 size, 17 x 11) taking the 7.5 V down to the XIAO's 5 V;
//   - a 3-way 5.08 mm screw terminal for the supply's and the thermostat's wires, by the grommet.
perfboard := Block(x0: board_cx - board_w / 2, x1: board_cx + board_w / 2,
                   y0: board_cy - board_h / 2, y1: board_cy + board_h / 2, z0: board_z,
                   z1: board_top)
xiao_c := At(x: xiao_cx, y: xiao_cy)
drv_c := At(x: drv_cx, y: drv_cy)
ina_c := At(x: ina_cx, y: ina_cy)
xiao_at := point
xiao_at raised(d: board_top, along: std.z) xiao_c.p
xiao := XiaoEsp32C3(xiao_dims, h: header_dims)
xiao seats(turn: 0deg, up: std.z, east: std.x) xiao_at
drv_at := point
drv_at raised(d: board_top, along: std.z) drv_c.p
driver := Drv8871(drv8871_dims, h: header_dims)
driver seats(turn: -90deg, up: std.z, east: std.x) drv_at
ina_at := point
ina_at raised(d: board_top, along: std.z) ina_c.p
monitor := Ina219(ina219_dims, h: header_dims)
monitor seats(turn: 0deg, up: std.z, east: std.x) ina_at
buck := Block(x0: board_cx - 16.5mm, x1: board_cx + 5.5mm, y0: board_cy - 23mm,
              y1: board_cy - 6mm, z0: board_top, z1: board_top + 5mm)
regulator := Block(x0: board_cx - 10mm, x1: board_cx + 1.1mm, y0: board_cy + 5mm,
                   y1: board_cy + 22.3mm, z0: board_top, z1: board_top + 4.5mm)
terminal := Block(x0: board_cx - 34mm, x1: board_cx - 19mm, y0: board_cy - 23mm,
                  y1: board_cy - 15mm, z0: board_top, z1: board_top + 10mm)

// The boards in the bay: a mated USB cable's plug through the end wall's window, and the boards,
// their headers and the pins' tails under the perfboard clear of the frame, the motor and the
// cover, and of one another and the buck modules' room.
claim xiao.plug clear(0.2mm) frame_part
claim xiao.board clear(0.5mm) frame_part
claim xiao.headers clear(0.5mm) frame_part
claim driver.board clear(0.5mm) frame_part
claim driver.headers clear(0.5mm) frame_part
claim monitor.board clear(0.5mm) frame_part
claim monitor.headers clear(0.5mm) frame_part
claim xiao.headers clear(0.5mm) motor.motor
claim driver.headers clear(0.5mm) motor.motor
claim monitor.headers clear(0.5mm) motor.motor
claim xiao.board clear(1mm) cover_part
claim driver.board clear(1mm) cover_part
claim monitor.board clear(1mm) cover_part
claim driver.board clear(0.5mm) monitor.board
claim driver.board clear(0.5mm) buck.body
claim monitor.board clear(0.5mm) regulator.body
claim xiao.board clear(0.5mm) regulator.body

// == Clearances ==================================================================================
// With `checks` 1, every part's clearance is judged, which builds every shaped part.  The wheel
// is judged against the handle closed, half open and nearly open, both read at rolls of the
// pair's generating motion across a whole period of the mesh (90deg of the handle: one arm
// through one pocket).  Gears in mesh run 0.15 mm clear a flank; parts that rest on one another
// (the motor on its lid, the base on the frame, the upper collar on the bridge) are not claimed
// clear.
when checks == 1 {
  rest_handle := StarHandle(valve.handle_top, s: handle_dims, stem_up: 1mm)
  repeat 7 as k {
    construction handle_at := rest_handle.handle at(under: cw.gen_handle) (k * 15deg)
    construction wheel_at := wheel_part at(under: cw.gen_wheel) (k * 15deg)
    claim wheel_at clear(0.1mm) handle_at
  }
  // and partway down its travel, half open and nearly open, where the pockets' walls turn from
  // the top face's section to the open star's draft
  half_top := plane
  fix(origin == (0mm, 0mm, top0 - stem_travel / 2)) half_top
  fix(dir == (1, 0, 0)) half_top.u
  fix(dir == (0, 1, 0)) half_top.v
  near_top := plane
  fix(origin == (0mm, 0mm, top0 - 0.95 * stem_travel)) near_top
  fix(dir == (1, 0, 0)) near_top.u
  fix(dir == (0, 1, 0)) near_top.v
  half_handle := StarHandle(half_top, s: handle_dims, stem_up: 1mm)
  near_handle := StarHandle(near_top, s: handle_dims, stem_up: 1mm)
  repeat 3 as k {
    construction half_at := half_handle.handle at(under: cw.gen_handle) (k * 30deg)
    construction near_at := near_handle.handle at(under: cw.gen_handle) (k * 30deg + 15deg)
    construction wheel_half := wheel_part at(under: cw.gen_wheel) (k * 30deg)
    construction wheel_near := wheel_part at(under: cw.gen_wheel) (k * 30deg + 15deg)
    claim wheel_half clear(0.1mm) half_at
    claim wheel_near clear(0.1mm) near_at
  }
  claim wheel clear(0.5mm) valve.packing_nut.bar
  claim wheel clear(0.3mm) base
  claim wheel clear(0.3mm) frame_part
  claim wheel clear(0.1mm) compound_b3
  claim wheel clear(0.25mm) lo_collar.part
  claim wheel clear(0.25mm) hi_collar.part
  claim lo_collar.part clear(2mm) valve.star_handle.handle
  claim compound_b3 clear(1mm) hi_collar.part
  claim compound_b3 clear(0.05mm) compound_d2
  claim compound_d2 clear(0.05mm) compound_b2
  claim compound_b2 clear(0.05mm) compound_d1
  claim compound_d1 clear(0.05mm) compound_b1
  claim compound_b1 clear(0.05mm) pinion
  claim compound_b3 clear(0.2mm) base
  claim compound_d2 clear(0.2mm) base
  claim compound_b2 clear(0.2mm) base
  claim compound_b1 clear(0.2mm) frame_part
  claim compound_d1 clear(0.2mm) frame_part
  claim pinion clear(0.2mm) frame_part
  claim frame_part clear(0.05mm) valve.supply_pipe.bar
  claim cap_part clear(0.05mm) valve.supply_pipe.bar
  claim frame_part clear(0.15mm) valve.body.casting
  claim cap_part clear(0.15mm) valve.body.casting
  claim frame_part clear(2mm) valve.bonnet.bonnet
  claim frame_part clear(2mm) valve.packing_nut.bar
  claim base clear(2mm) valve.bonnet.bonnet
  claim base clear(2mm) valve.packing_nut.bar
  claim base clear(0.3mm) valve.star_handle.handle
  claim frame_part clear(1mm) valve.union.nut.bar
}
