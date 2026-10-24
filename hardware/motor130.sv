// A 130-size brushed DC motor, the kind pulled from hobby servos, as a module: its outline for
// the cradle that holds it and the figures the gearbox is sized from.
//
// Drawn about its own std.origin, face down: the front face (the shaft end) on std.top, the can
// rising up std.z behind it, the shaft and its bushing's boss pointing down.  The can is round
// with two flats.  Sizes marked "~" are the common 130's, worth checking on the motors in the pile;
// so are the electrical figures, which differ from winding to winding (a servo's motor is wound
// for 4.8-6 V): measure the stall current at the supply voltage and the free speed, and the rest
// follows.

unit mm
use std

interface MotorSizes {
  d: Length, flats: Length, len: Length
  boss_d: Length, boss_h: Length
  shaft_d: Length, shaft_len: Length
}
motor130_dims := {
  d: 20.1mm,               // ~ the can's diameter over the round sides
  flats: 15.1mm,           // ~ across the flats
  len: 25.1mm,             // ~ front face to the end bell's back, terminals aside
  boss_d: 6.15mm,          // ~ the front bushing's boss
  boss_h: 1.6mm,           // ~
  shaft_d: 2.0mm,
  shaft_len: 8.0mm,        // ~ out past the front face
}

// ~ electrical: a servo's 130 at 6 V.  The gearbox reads the stall torque and the free speed;
// the stall current is what the current sensing trips below.
motor130_volts := 6V
motor130_free := 12000rpm       // ~ no-load speed
motor130_stall_torque := 0.006Nm   // ~ 6 mN·m
motor130_stall_amps := 1.8A     // ~

// The can's section grown by `grow` all round (negative shrinks it), from z0 to z1: the can itself
// at no growth, and the pocket and outside of a cradle that holds one.
component MotorCan(s: MotorSizes, grow: Length, z0: Length, z1: Length) {
  r := s.d / 2 + grow
  f := s.flats / 2 + grow
  // the round sides as arcs about the axis, the flats as chords
  in std.top {
    fr := point hint((sqrt(r ^ 2 - f ^ 2), f))
    fl := point hint((-sqrt(r ^ 2 - f ^ 2), f))
    bl := point hint((-sqrt(r ^ 2 - f ^ 2), -f))
    br := point hint((sqrt(r ^ 2 - f ^ 2), -f))
    std.top.origin distance(f, along: v) fr
    std.top.origin distance(f, along: v) fl
    std.top.origin distance(-f, along: v) bl
    std.top.origin distance(-f, along: v) br
    ccw(std.top.origin, br, fr)
    ccw(std.top.origin, fl, bl)
    section := (right := arc(center: std.top.origin, start: br, end: fr)) ->
               (top_flat := line(fr, fl)) ->
               (left := arc(center: std.top.origin, start: fl, end: bl)) ->
               (bottom_flat := line(bl, br)) -> close
    radius(r) right
    radius(r) left
  }
  body := solid(section, from: z0, to: z1)
}

component Motor130(s: MotorSizes) {
  shell := MotorCan(s, grow: 0mm, z0: 0mm, z1: s.len)
  in std.top {
    boss_rim := radius(s.boss_d / 2) circle(center: std.top.origin)
    shaft_rim := radius(s.shaft_d / 2) circle(center: std.top.origin)
  }
  boss := solid(face(boss_rim), from: -s.boss_h, to: 0mm)
  shaft := solid(face(shaft_rim), from: -s.shaft_len, to: 0mm)
  motor := solid(shell.body)
  boss union motor
  shaft union motor
}

preview {
  m := Motor130(motor130_dims)
}
