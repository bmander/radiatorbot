// The bought boards in the electronics bay, as modules: their outlines on the perfboard, the room
// their parts take, and where their pins stand, for placing them on the perfboard's grid and
// fitting the bay round them.
//
// Each is drawn about its own std.origin as it stands on the perfboard: std.top is the
// perfboard's top face, which its header's plastic stands on, and the origin is the middle of its
// pin field, so a board placed on a grid point has every pin in a hole.  Pins are 0.1 in apart;
// the long ends of the headers go down through the perfboard, soldered and cut to `tail` below
// its top face.  Sizes marked "~" are read off photos or are a family's usual, worth checking on
// the boards in hand.
//
//   - **Seeed XIAO ESP32-C3** (Seeed SKU 113991054, $4.99): an ESP32-C3 with USB-C, 21 x 17.8 mm,
//     14 castellated pins in two rows 0.6 in apart.  Its outline, its pins and its USB-C
//     receptacle are from Seeed's KiCad layout (XIAO ESP32C3 v1.3).  It wants the FPC antenna it
//     comes with on its U.FL connector.
//   - **Pololu DRV8874 carrier** (Pololu #4035, $11.94): an H-bridge for one brushed motor,
//     4.5-37 V, 2.1 A continuous; its CS pin gives the motor's current as ~1.1 V/A across
//     2.49 kOhm.  0.6 x 0.7 in, 14 pins in two rows 0.5 in apart, from Pololu's dimension drawing.

unit mm
use std
use std (coords, on_v, seats)

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

interface XiaoSizes {
  len: Length, w: Length, pcb_t: Length, rows: Length, n: Int
  usb_w: Length, usb_h: Length, usb_in: Length, usb_out: Length
  chip: Length, chip_x: Length, chip_y: Length, chip_h: Length
  ufl: Length, ufl_x: Length, ufl_h: Length
  plug_w: Length, plug_h: Length, plug_len: Length
}
xiao_dims := {
  len: 20.955mm,                // along the USB's axis
  w: 17.78mm,
  pcb_t: 1.2mm,                 // ~
  rows: 15.24mm,                // the two rows of pins, 0.6 in apart
  n: 7,                         // pins a row
  usb_w: 8.94mm,                // the USB-C receptacle: its shell, standing on the board's top face
  usb_h: 3.26mm,
  usb_in: 5.84mm,               // back from the board's end
  usb_out: 1.51mm,              // out past it
  chip: 5mm,                    // the ESP32-C3, a 5 x 5 QFN
  chip_x: 0.69mm,               // from the pin field's middle, away from the USB
  chip_y: 2.39mm,
  chip_h: 0.9mm,
  ufl: 2.6mm,                   // the antenna's U.FL connector, at the end away from the USB
  ufl_x: 9.08mm,
  ufl_h: 1.25mm,
  plug_w: 12.5mm,               // ~ a USB-C cable's moulded plug, mated: the room it needs
  plug_h: 7mm,
  plug_len: 30mm,
}

// The ESP32-C3's pins, in a row from the USB end; looking down on it, its USB toward -x:
//   -y: D0 D1 D2 D3 D4 D5 D6
//   +y: 5V GND 3V3 D10 D9 D8 D7
// D0-D2 are ADC1 (A0-A2); D0, D8 and D9 are strapping pins.

interface DriverSizes {
  len: Length, w: Length, pcb_t: Length, rows: Length, n: Int
  parts_w: Length, parts_len: Length, parts_h: Length
}
drv8874_dims := {
  len: 17.78mm,                 // 0.7 in, along the rows
  w: 15.24mm,                   // 0.6 in
  pcb_t: 1.6mm,                 // ~
  rows: 12.7mm,                 // 0.5 in apart
  n: 7,
  parts_w: 10mm,                // ~ the chip and its capacitors, between the rows
  parts_len: 16mm,
  parts_h: 1.7mm,               // ~ the tallest, the bulk capacitors
}

// The DRV8874's pins, in a row from +y; looking down on its parts:
//   -x: VM GND EN/IN1 PH/IN2 PMODE SLEEP VREF
//   +x: VIN GND OUT1 OUT2 IMODE FAULT CS

// A box square to the body's frame: x0..x1, y0..y1, z0..z1.
component Box(x0: Length, x1: Length, y0: Length, y1: Length, z0: Length, z1: Length) {
  in std.top {
    c := point hint(((x0 + x1) / 2, (y0 + y1) / 2))
    c coords(du: (x0 + x1) / 2, dv: (y0 + y1) / 2) std.top
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

// The XIAO ESP32-C3 on its headers, its USB toward -x.  `plug` is the room a mated cable's plug
// takes, out from the receptacle's mouth along -x, for the bay's wall to clear.  It is drawn
// facing the way the bay seats it, at `turn: 0deg`: seated a half turn on a `raised` point, it
// comes out upside down (bmander/geomsolver#629).
component XiaoEsp32C3(s: XiaoSizes, h: HeaderSizes) {
  z0 := h.body_h                                   // the board's underside
  z1 := z0 + s.pcb_t
  pcb := Box(x0: -s.len / 2, x1: s.len / 2, y0: -s.w / 2, y1: s.w / 2, z0: z0, z1: z1)
  usb := Box(x0: -s.len / 2 - s.usb_out, x1: -s.len / 2 + s.usb_in, y0: -s.usb_w / 2,
             y1: s.usb_w / 2, z0: z1, z1: z1 + s.usb_h)
  chip := Box(x0: s.chip_x - s.chip / 2, x1: s.chip_x + s.chip / 2, y0: s.chip_y - s.chip / 2,
              y1: s.chip_y + s.chip / 2, z0: z1, z1: z1 + s.chip_h)
  ufl := Box(x0: s.ufl_x - s.ufl / 2, x1: s.ufl_x + s.ufl / 2, y0: -s.ufl / 2, y1: s.ufl / 2,
             z0: z1, z1: z1 + s.ufl_h)
  row_a := HeaderRow(h, y: -s.rows / 2, n: s.n, pcb_t: s.pcb_t)
  row_b := HeaderRow(h, y: s.rows / 2, n: s.n, pcb_t: s.pcb_t)

  board := solid(pcb.body)
  usb.body union board
  chip.body union board
  ufl.body union board
  headers := solid(row_a.plastic.body)
  row_b.plastic.body union headers
  row_a.pins union headers
  row_b.pins union headers

  usb_z := z1 + s.usb_h / 2                        // the receptacle's axis, up from the perfboard
  usb_x := -s.len / 2 - s.usb_out                  // its mouth, out from the pin field's middle
  plug_room := Box(x0: usb_x - s.plug_len, x1: usb_x, y0: -s.plug_w / 2, y1: s.plug_w / 2,
                   z0: usb_z - s.plug_h / 2, z1: usb_z + s.plug_h / 2)
  construction plug := solid(plug_room.body)
}

// The Pololu DRV8874 carrier on its headers, its rows along y.
component Drv8874(s: DriverSizes, h: HeaderSizes) {
  z0 := h.body_h
  z1 := z0 + s.pcb_t
  pcb := Box(x0: -s.w / 2, x1: s.w / 2, y0: -s.len / 2, y1: s.len / 2, z0: z0, z1: z1)
  parts := Box(x0: -s.parts_w / 2, x1: s.parts_w / 2, y0: -s.parts_len / 2, y1: s.parts_len / 2,
               z0: z1, z1: z1 + s.parts_h)
  board := solid(pcb.body)
  parts.body union board

  // the rows drawn along x and turned a quarter onto y
  rows := HeaderPair(h, rows: s.rows, n: s.n, pcb_t: s.pcb_t)
  rows seats(turn: 90deg, up: std.z, east: std.x) std.origin
}

// Two header rows `rows` apart, about the origin.
component HeaderPair(h: HeaderSizes, rows: Length, n: Int, pcb_t: Length) {
  row_a := HeaderRow(h, y: -rows / 2, n: n, pcb_t: pcb_t)
  row_b := HeaderRow(h, y: rows / 2, n: n, pcb_t: pcb_t)
  headers := solid(row_a.plastic.body)
  row_b.plastic.body union headers
  row_a.pins union headers
  row_b.pins union headers
}

preview {
  xiao := XiaoEsp32C3(xiao_dims, h: header_dims)
  in std.top {
    drv_at := point hint((0, 25))
    drv_at on_v(d: 25mm) std.top
  }
  drv := Drv8874(drv8874_dims, h: header_dims)
  drv seats(turn: 0deg, up: std.z, east: std.x) drv_at
}
