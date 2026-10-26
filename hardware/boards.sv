// The bought boards in the electronics bay, as modules: their outlines, the room their parts take,
// and where their pins stand, for stacking them and fitting the bay round them.
//
// The Uno and its shield are drawn about the Uno's own frame: std.top is the Uno's underside, which
// stands on its posts, and the origin is its power header's first pin, so the shield's grid has
// a hole on every one of the Uno's pins but the D8-SCL header's (which stands 0.06 in off it).
// The breakouts on the shield are each drawn about their own std.origin as they stand on it:
// std.top is the shield's top face, which a header's plastic stands on, and the origin is the
// middle of its pin field, so a board placed on a grid point has every pin in a hole.  Pins are
// 0.1 in apart; the long ends of the headers go down through the shield, soldered and cut to
// `tail` below its top face.  Sizes marked "~" are read off photos or are a family's usual, worth
// checking on the boards in hand.
//
//   - **Arduino Uno R4 Minima** (Arduino ABX00080, $20): an RA4M1 on the Uno's 2.7 x 2.1 in board,
//     with USB-C, and a barrel jack that takes 6-24 V through a Schottky diode to VIN and the
//     board's 5 V buck.  Its outline, its headers and its holes are the Uno R3's (KiCad's
//     Arduino_UNO_R3 footprint), which the R4 keeps; its jack is the R3's; its USB-C receptacle is
//     placed where the R3's USB-B was (~).
//   - **The shield**: a 5 x 7 cm perfboard, 18 x 24 holes, on male headers plugged down into the
//     Uno's power, analog and D0-D7 sockets.  Its long side runs across the Uno; it stands off
//     the Uno's jack end.
//   - **Adafruit DRV8871 breakout** (Adafruit #3190, $7.50): an H-bridge for one brushed motor,
//     6.5-45 V, its current held under ~2.1 A by the 30 kOhm on ILIM.  20.3 x 24.1 mm, one row of
//     4 pins and two 2-way 3.5 mm screw terminals (the motor's, and the supply's) at the far end.
//     It has no current output.
//   - **Adafruit INA219 breakout** (Adafruit #904, ~$10): a high-side current and voltage monitor
//     on I2C, across a 0.1 Ohm shunt: +-3.2 A at 0.8 mA.  25.4 x 20.3 mm, one row of 6 pins, a
//     STEMMA QT socket at each end.
//
// The Adafruit boards' outlines, pins and parts are from Adafruit's Eagle layouts
// (github.com/adafruit/Adafruit-DRV8871-Breakout-PCB, .../Adafruit-INA219-Current-Sensor-PCB,
// the STEMMA QT revision); their corners, rounded 2.54 mm, are drawn square.  Each stands on its
// one row of pins, the rest of it held out over the perfboard.

unit mm
use std
use std (coords, on_u, on_v, seats, raised)

pitch := 2.54mm                 // 0.1 in: every header's, and the perfboard's grid

// A header under a board: the plastic it stands on and its pins.  `tail` is how far a pin reaches
// below the perfboard's top face, through the board (1.6 mm) and its solder, cut there; `over` how
// far the short end stands above the board's top face, past its own solder.
interface HeaderSizes { body_h: Length, body_w: Length, pin_w: Length, tail: Length, over: Length }
header_dims := {
  body_h: 2.5mm,                // the plastic between the boards
  body_w: 2.54mm,
  pin_w: 0.64mm,
  tail: 3.1mm,                  // ~ 1.6 mm of perfboard and 1.5 mm cut below it
  over: 1.0mm,                  // ~
}

interface UnoSizes {
  x0: Length, x1: Length, y0: Length, y1: Length, pcb_t: Length, socket_h: Length, tail: Length
  analog_x0: Length, low_x0: Length, high_x0: Length, top_y: Length
  hole_a_x: Length, hole_b_x: Length, hole_far_x: Length, hole_far_y0: Length, hole_far_y1: Length
  jack_x0: Length, jack_x1: Length, jack_y0: Length, jack_y1: Length, jack_h: Length, jack_z: Length
  usb_w: Length, usb_h: Length, usb_in: Length, usb_out: Length, usb_y: Length
  icsp_x: Length, icsp_y: Length, icsp_h: Length
  jack_plug: Length, plug_w: Length, plug_h: Length, plug_len: Length
}
uno_dims := {
  x0: -27.94mm,                 // its outline, from the power header's first pin: 2.7 x 2.1 in,
  x1: 40.64mm,                  // the USB end toward -x
  y0: -2.54mm,
  y1: 50.8mm,
  pcb_t: 1.6mm,
  socket_h: 8.5mm,              // the female headers, over its top face
  tail: 1.5mm,                  // ~ its through-hole pins, under its underside
  analog_x0: 22.86mm,           // the sockets' first pins (the power header's is the origin):
  low_x0: 17.78mm,              // A0, D7 and SCL; D7 ... D0 and SCL ... D8 along y = top_y
  high_x0: -9.14mm,
  top_y: 48.26mm,
  hole_a_x: -13.97mm,           // its M3 holes: by the power header (y = 0), by the SCL socket
  hole_b_x: -12.7mm,            // (y = top_y), and two at the far end
  hole_far_x: 38.1mm,
  hole_far_y0: 5.08mm,
  hole_far_y1: 33.02mm,
  jack_x0: -29.84mm,            // the barrel jack, its mouth out past the board's end
  jack_x1: -16.51mm,
  jack_y0: 0.64mm,
  jack_y1: 9.53mm,
  jack_h: 11mm,                 // ~
  jack_z: 6.5mm,                // ~ its pin's axis, over the top face
  usb_w: 8.94mm,                // the USB-C receptacle's shell, standing on the top face
  usb_h: 3.26mm,
  usb_in: 7.35mm,               // ~ back from the board's end
  usb_out: 1mm,                 // ~ out past it
  usb_y: 35.56mm,               // ~ its axis
  icsp_x: 36.2mm,               // ~ the 2 x 3 ICSP header's middle, by the far end
  icsp_y: 24.13mm,
  icsp_h: 8.5mm,                // ~ its pins' tops
  jack_plug: 11mm,              // ~ a barrel plug's moulded body, mated: the room it needs
  plug_w: 12.5mm,               // ~ a USB-C cable's moulded plug, mated: the room it needs
  plug_h: 7mm,
  plug_len: 30mm,
}

// The Uno's sockets, looking down on it, its USB toward -x:
//   y = 48.26: SCL SDA AREF GND D13 ... D8 (x = -9.14 to 13.72), then D7 ... D0 (x = 17.78 to
//              35.56, on the 0.1 in grid with the rest)
//   y = 0:     NC IOREF RESET 3V3 5V GND GND VIN (x = 0 to 17.78), then A0 ... A5 (x = 22.86 to
//              35.56)
// SDA and SCL are A4 and A5 again.  VIN is the jack's voltage, through the board's Schottky.

interface ShieldSizes {
  w: Length, h: Length, pcb_t: Length, cols: Int, rows: Int, col0: Length, row0: Length
  plug: Length
}
shield_dims := {
  w: 50mm,                      // a 5 x 7 cm perfboard, its 7 cm across the Uno
  h: 70mm,
  pcb_t: 1.6mm,
  cols: 18,                     // its holes, 0.1 in apart, centred on it
  rows: 24,
  col0: -5.08mm,                // its first column's, and row's, holes, in the Uno's frame: two
  row0: -5.08mm,                // holes out from the power header's first pin
  plug: 6mm,                    // how far its header pins reach down into the Uno's sockets
}
// The shield's top face, which the breakouts stand on, up from the Uno's underside: over the
// sockets and its headers' plastic.
shield_top := uno_dims.pcb_t + uno_dims.socket_h + header_dims.body_h + shield_dims.pcb_t

interface Drv8871Sizes {
  w: Length, len: Length, back: Length, pcb_t: Length, n: Int
  chip_w: Length, chip_len: Length, chip_x: Length, chip_y: Length, chip_h: Length
  cap: Length, cap_x: Length, cap_y: Length, cap_h: Length
  block_w: Length, block_d: Length, block_x: Length, block_y: Length, block_h: Length
}
drv8871_dims := {
  w: 20.32mm,                   // 0.8 in, along its row of pins
  len: 24.13mm,                 // 0.95 in, away from it
  back: 2.54mm,                 // the board behind the pins' line
  pcb_t: 1.6mm,                 // ~
  n: 4,
  chip_w: 5mm,                  // the DRV8871, an HSOP-8, across its leads
  chip_len: 6.2mm,
  chip_x: -5.46mm,
  chip_y: 8.38mm,
  chip_h: 1.7mm,                // ~
  cap: 6.6mm,                   // the 22 uF 63 V electrolytic's square base
  cap_x: 4.32mm,
  cap_y: 8.64mm,
  cap_h: 7.7mm,                 // ~ a 6.3 x 7.7 mm can
  block_w: 7mm,                 // each 2-way 3.5 mm screw terminal: the motor's at -x, the supply's
  block_d: 7mm,                 // at +x, their wires entering from the board's far end
  block_x: 4.32mm,
  block_y: 17.88mm,
  block_h: 8.5mm,               // ~
}

// The DRV8871's pins, looking down on its parts with its terminals toward +y, from -x:
//   IN2 IN1 VM GND
// and its terminals so: OUT2 OUT1, then VM GND (the supply's, the pins' VM and GND again).  IN1
// and IN2 are pulled down on the chip: both low coasts the motor, and sleeps it after 1 ms.

interface Ina219Sizes {
  w: Length, len: Length, back: Length, pcb_t: Length, n: Int
  shunt_w: Length, shunt_len: Length, shunt_y: Length, shunt_h: Length
  chip: Length, chip_y: Length, chip_h: Length
  qt_w: Length, qt_len: Length, qt_x: Length, qt_y: Length, qt_h: Length
}
ina219_dims := {
  w: 25.4mm,                    // 1.0 in, along its row of pins
  len: 20.32mm,                 // 0.8 in, away from it
  back: 2.54mm,
  pcb_t: 1.6mm,                 // ~
  n: 6,
  shunt_w: 6.4mm,               // the 0.1 Ohm shunt, a 2512
  shunt_len: 3.2mm,
  shunt_y: 8.64mm,
  shunt_h: 0.7mm,
  chip: 3mm,                    // the INA219, an SOT23-8
  chip_y: 4.45mm,
  chip_h: 1.45mm,
  qt_w: 4.3mm,                  // each STEMMA QT socket, a side-entry JST SH, its mouth to the
  qt_len: 6.1mm,                // board's end
  qt_x: 10.11mm,
  qt_y: 7.67mm,
  qt_h: 2.95mm,
}

// The INA219's pins, looking down on its parts with its far end toward +y, from -x:
//   VCC GND SCL SDA VIN- VIN+
// VIN+ to VIN- is the shunt; the 3.5 mm terminal at the far end is the same two nets, and isn't
// fitted.  SCL and SDA are pulled up to VCC (10 kOhm) on the board; the address is 0x40.

// A box square to the body's frame: x0..x1, y0..y1, z0..z1.  Its middle is placed by its
// ordinates, or on an axis where one is zero (a zero ordinate is a relation, not a number).
component Box(x0: Length, x1: Length, y0: Length, y1: Length, z0: Length, z1: Length) {
  cx := (x0 + x1) / 2
  cy := (y0 + y1) / 2
  in std.top {
    c := point hint((cx, cy))
    when cx != 0mm and cy != 0mm {
      c coords(du: cx, dv: cy) std.top
    }
    when cx != 0mm and cy == 0mm {
      c on_u(d: cx) std.top
    }
    when cx == 0mm and cy != 0mm {
      c on_v(d: cy) std.top
    }
    when cx == 0mm and cy == 0mm {
      c coincident std.top.origin
    }
    sq := std.CenteredRectangle(c, w: x1 - x0, h: y1 - y0)
  }
  body := solid(face(sq.loop), from: z0, to: z1)
}

// A row of `n` pins along x at y, centred on x = 0, under a board `pcb_t` thick: the plastic and
// the pins through it, the perfboard and the board.
component HeaderRow(h: HeaderSizes, y: Length, n: Int, pcb_t: Length) {
  plastic := Box(x0: -n * pitch / 2, x1: n * pitch / 2, y0: y - h.body_w / 2, y1: y + h.body_w / 2,
                 z0: 0mm, z1: h.body_h)
  pins := solid()
  repeat n as k {
    px := (k - (n - 1) / 2) * pitch
    pin := Box(x0: px - h.pin_w / 2, x1: px + h.pin_w / 2, y0: y - h.pin_w / 2, y1: y + h.pin_w / 2,
               z0: -h.tail, z1: h.body_h + pcb_t + h.over)
    pin.body union pins
  }
}

// A row of `n` male pins along x from x = x0, plugged down into the Uno's sockets under the
// shield: the plastic between the sockets and the shield, and the pins from `plug` down in the
// sockets up through the shield.
component PlugRow(h: HeaderSizes, s: ShieldSizes, u: UnoSizes, x0: Length, y: Length, n: Int) {
  z0 := u.pcb_t + u.socket_h                       // the sockets' tops
  pcb_t := s.pcb_t
  plug := s.plug
  plastic := Box(x0: x0 - pitch / 2, x1: x0 + (n - 0.5) * pitch, y0: y - h.body_w / 2,
                 y1: y + h.body_w / 2, z0: z0, z1: z0 + h.body_h)
  pins := solid()
  repeat n as k {
    px := x0 + k * pitch
    pin := Box(x0: px - h.pin_w / 2, x1: px + h.pin_w / 2, y0: y - h.pin_w / 2, y1: y + h.pin_w / 2,
               z0: z0 - plug, z1: z0 + h.body_h + pcb_t + h.over)
    pin.body union pins
  }
}

// One of the Uno's sockets along x from x = x0, `n` pins: its plastic on the Uno's top face, and
// its pins' tails under the Uno.
component SocketRow(u: UnoSizes, x0: Length, y: Length, n: Int) {
  plastic := Box(x0: x0 - pitch / 2, x1: x0 + (n - 0.5) * pitch, y0: y - pitch / 2,
                 y1: y + pitch / 2, z0: u.pcb_t, z1: u.pcb_t + u.socket_h)
  tails := Box(x0: x0 - 0.5mm, x1: x0 + (n - 1) * pitch + 0.5mm, y0: y - 0.5mm, y1: y + 0.5mm,
               z0: -u.tail, z1: 0mm)
}

// The Uno R4 Minima, in its own frame (std.top its underside), its USB and its jack toward -x:
// its board, the parts on it (the tall ones: the jack, the USB-C, the ICSP header and the
// sockets) and the pins' tails under it.  `usb_plug` and `jack_plug` are the room a mated cable's
// plug takes, out from each mouth along -x, for the bay's wall to clear.
component UnoR4Minima(s: UnoSizes) {
  z1 := s.pcb_t                                    // its top face
  pcb := Box(x0: s.x0, x1: s.x1, y0: s.y0, y1: s.y1, z0: 0mm, z1: z1)
  jack := Box(x0: s.jack_x0, x1: s.jack_x1, y0: s.jack_y0, y1: s.jack_y1, z0: z1,
              z1: z1 + s.jack_h)
  usb := Box(x0: s.x0 - s.usb_out, x1: s.x0 + s.usb_in, y0: s.usb_y - s.usb_w / 2,
             y1: s.usb_y + s.usb_w / 2, z0: z1, z1: z1 + s.usb_h)
  icsp := Box(x0: s.icsp_x - pitch, x1: s.icsp_x + pitch, y0: s.icsp_y - 1.5 * pitch,
              y1: s.icsp_y + 1.5 * pitch, z0: z1, z1: z1 + s.icsp_h)
  power := SocketRow(s, x0: 0mm, y: 0mm, n: 8)
  analog := SocketRow(s, x0: s.analog_x0, y: 0mm, n: 6)
  low := SocketRow(s, x0: s.low_x0, y: s.top_y, n: 8)
  high := SocketRow(s, x0: s.high_x0, y: s.top_y, n: 10)

  board := solid(pcb.body)
  parts := solid(jack.body)
  usb.body union parts
  icsp.body union parts
  power.plastic.body union parts
  analog.plastic.body union parts
  low.plastic.body union parts
  high.plastic.body union parts
  tails := solid(power.tails.body)
  analog.tails.body union tails
  low.tails.body union tails
  high.tails.body union tails

  usb_z := z1 + s.usb_h / 2                        // the receptacle's axis, up from its underside
  usb_x := s.x0 - s.usb_out                        // its mouth
  usb_room := Box(x0: usb_x - s.plug_len, x1: usb_x, y0: s.usb_y - s.plug_w / 2,
                  y1: s.usb_y + s.plug_w / 2, z0: usb_z - s.plug_h / 2, z1: usb_z + s.plug_h / 2)
  construction usb_plug := solid(usb_room.body)
  jack_y := (s.jack_y0 + s.jack_y1) / 2
  jack_room := Box(x0: s.jack_x0 - s.plug_len, x1: s.jack_x0, y0: jack_y - s.jack_plug / 2,
                   y1: jack_y + s.jack_plug / 2, z0: z1 + s.jack_z - s.jack_plug / 2,
                   z1: z1 + s.jack_z + s.jack_plug / 2)
  construction jack_plug := solid(jack_room.body)
}

// The perfboard shield on the Uno, in the Uno's frame: its board, and the headers that plug it
// into the Uno's power, analog and D0-D7 sockets.  Its top face is `shield_top` up from the
// Uno's underside.
component Shield(s: ShieldSizes, u: UnoSizes, h: HeaderSizes) {
  mx := (s.w - (s.cols - 1) * pitch) / 2           // its margins, past the outer holes
  my := (s.h - (s.rows - 1) * pitch) / 2
  pcb := Box(x0: s.col0 - mx, x1: s.col0 + (s.cols - 1) * pitch + mx, y0: s.row0 - my,
             y1: s.row0 + (s.rows - 1) * pitch + my, z0: shield_top - s.pcb_t, z1: shield_top)
  power := PlugRow(h, s, u, x0: 0mm, y: 0mm, n: 8)
  analog := PlugRow(h, s, u, x0: u.analog_x0, y: 0mm, n: 6)
  low := PlugRow(h, s, u, x0: u.low_x0, y: u.top_y, n: 8)

  board := solid(pcb.body)
  headers := solid(power.plastic.body)
  analog.plastic.body union headers
  low.plastic.body union headers
  power.pins union headers
  analog.pins union headers
  low.pins union headers
}

// The Adafruit DRV8871 breakout on its row of pins along x, its terminals toward +y.
component Drv8871(s: Drv8871Sizes, h: HeaderSizes) {
  z0 := h.body_h
  z1 := z0 + s.pcb_t
  pcb := Box(x0: -s.w / 2, x1: s.w / 2, y0: -s.back, y1: s.len - s.back, z0: z0, z1: z1)
  chip := Box(x0: s.chip_x - s.chip_w / 2, x1: s.chip_x + s.chip_w / 2,
              y0: s.chip_y - s.chip_len / 2, y1: s.chip_y + s.chip_len / 2,
              z0: z1, z1: z1 + s.chip_h)
  cap := Box(x0: s.cap_x - s.cap / 2, x1: s.cap_x + s.cap / 2, y0: s.cap_y - s.cap / 2,
             y1: s.cap_y + s.cap / 2, z0: z1, z1: z1 + s.cap_h)
  motor_block := Box(x0: -s.block_x - s.block_w / 2, x1: -s.block_x + s.block_w / 2,
                     y0: s.block_y - s.block_d / 2, y1: s.block_y + s.block_d / 2,
                     z0: z1, z1: z1 + s.block_h)
  supply_block := Box(x0: s.block_x - s.block_w / 2, x1: s.block_x + s.block_w / 2,
                      y0: s.block_y - s.block_d / 2, y1: s.block_y + s.block_d / 2,
                      z0: z1, z1: z1 + s.block_h)
  row := HeaderRow(h, y: 0mm, n: s.n, pcb_t: s.pcb_t)

  board := solid(pcb.body)
  chip.body union board
  cap.body union board
  motor_block.body union board
  supply_block.body union board
  headers := solid(row.plastic.body)
  row.pins union headers
}

// The Adafruit INA219 breakout on its row of pins along x, its far end toward +y.
component Ina219(s: Ina219Sizes, h: HeaderSizes) {
  z0 := h.body_h
  z1 := z0 + s.pcb_t
  pcb := Box(x0: -s.w / 2, x1: s.w / 2, y0: -s.back, y1: s.len - s.back, z0: z0, z1: z1)
  shunt := Box(x0: -s.shunt_w / 2, x1: s.shunt_w / 2, y0: s.shunt_y - s.shunt_len / 2,
               y1: s.shunt_y + s.shunt_len / 2, z0: z1, z1: z1 + s.shunt_h)
  chip := Box(x0: -s.chip / 2, x1: s.chip / 2, y0: s.chip_y - s.chip / 2, y1: s.chip_y + s.chip / 2,
              z0: z1, z1: z1 + s.chip_h)
  qt_w := Box(x0: -s.qt_x - s.qt_w / 2, x1: -s.qt_x + s.qt_w / 2, y0: s.qt_y - s.qt_len / 2,
              y1: s.qt_y + s.qt_len / 2, z0: z1, z1: z1 + s.qt_h)
  qt_e := Box(x0: s.qt_x - s.qt_w / 2, x1: s.qt_x + s.qt_w / 2, y0: s.qt_y - s.qt_len / 2,
              y1: s.qt_y + s.qt_len / 2, z0: z1, z1: z1 + s.qt_h)
  row := HeaderRow(h, y: 0mm, n: s.n, pcb_t: s.pcb_t)

  board := solid(pcb.body)
  shunt.body union board
  chip.body union board
  qt_w.body union board
  qt_e.body union board
  headers := solid(row.plastic.body)
  row.pins union headers
}

preview {
  uno := UnoR4Minima(uno_dims)
  shield := Shield(shield_dims, u: uno_dims, h: header_dims)
  in std.top {
    drv_at := point hint((7 * pitch, 3.5 * pitch))
    drv_at coords(du: 7 * pitch, dv: 3.5 * pitch) std.top
    ina_at := point hint((7 * pitch, 13.5 * pitch))
    ina_at coords(du: 7 * pitch, dv: 13.5 * pitch) std.top
  }
  drv_on := point
  drv_on raised(d: shield_top, along: std.z) drv_at
  drv := Drv8871(drv8871_dims, h: header_dims)
  drv seats(turn: -90deg, up: std.z, east: std.x) drv_on
  ina_on := point
  ina_on raised(d: shield_top, along: std.z) ina_at
  ina := Ina219(ina219_dims, h: header_dims)
  ina seats(turn: -90deg, up: std.z, east: std.x) ina_on
}
