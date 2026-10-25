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
use std (coords, on_u, on_v, seats)

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

// The XIAO ESP32-C3 on its headers, its USB toward -x.  `plug` is the room a mated cable's plug
// takes, out from the receptacle's mouth along -x, for the bay's wall to clear.
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
  xiao := XiaoEsp32C3(xiao_dims, h: header_dims)
  in std.top {
    drv_at := point hint((0, 15))
    drv_at on_v(d: 15mm) std.top
    ina_at := point hint((30, 0))
    ina_at on_u(d: 30mm) std.top
  }
  drv := Drv8871(drv8871_dims, h: header_dims)
  drv seats(turn: 0deg, up: std.z, east: std.x) drv_at
  ina := Ina219(ina219_dims, h: header_dims)
  ina seats(turn: 0deg, up: std.z, east: std.x) ina_at
}
