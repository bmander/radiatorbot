// A 130-size brushed DC motor as a module: its outline for the cradle that holds it and the
// figures the gearbox is sized from.
//
// Drawn about its own std.origin, face down: the front face (the shaft end) on std.top, the can
// rising up std.z behind it to the plastic end bell, the shaft and its bushing's boss pointing
// down, the end bell's bearing boss up.  The can is round with two flats; the end bell follows
// its section, and its two terminal tabs are left out.  The sizes are calipered off the motor in
// the pile, and so are the electrical figures, measured on the bench (see below): another
// winding's differ, so measure a new motor's the same way and the rest follows.

unit mm
use std

interface MotorSizes {
  d: Length, flats: Length, len: Length
  boss_d: Length, boss_h: Length
  shaft_d: Length, shaft_len: Length
  back_d: Length, back_h: Length
}
motor130_dims := {
  d: 24mm,                 // the can's diameter over the round sides
  flats: 18.25mm,          // across the flats
  len: 30.65mm,            // front face to the end bell's back, its boss and the terminals aside
  boss_d: 6.14mm,          // the front bushing's boss
  boss_h: 1.5mm,
  shaft_d: 1.98mm,
  shaft_len: 16.3mm,       // out past the front face: 14.8 mm past the boss
  back_d: 8.45mm,          // the end bell's bearing boss
  back_h: 1.92mm,
}

// Electrical, at the 9 V the firmware gives it (`motor_volts`).  The gearbox reads the stall
// torque and the free speed; the stall current is what the current sensing trips below.
// Measured with firmware/tools/bench.html: free-running from 30% to 100% of 9 V, the current
// from the INA219 and the speed from the microphone (its fundamental, matched once by ear against
// a tone: this motor sounds mostly its even multiples), the winding's resistance from a stall.
// It fits V = I R + ke w with ke = kt = 6.06 mN·m/A, I0 = 61 mA and R = 7.5 Ω (the driver's
// included), 173 rpm rms over nine points; the stall current and torque follow from R.
motor130_volts := 9V
motor130_free := 13476rpm       // no-load speed
motor130_stall_torque := 0.0069Nm  // 6.9 mN·m: kt (V / R - I0)
motor130_stall_amps := 1.2A     // V / R

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
    back_rim := radius(s.back_d / 2) circle(center: std.top.origin)
  }
  boss := solid(face(boss_rim), from: -s.boss_h, to: 0mm)
  shaft := solid(face(shaft_rim), from: -s.shaft_len, to: 0mm)
  back := solid(face(back_rim), from: s.len, to: s.len + s.back_h)
  motor := solid(shell.body)
  boss union motor
  shaft union motor
  back union motor
}

preview {
  m := Motor130(motor130_dims)
}
