// The bought boards in the electronics bay, as modules: their outlines, the room their parts take,
// and where their pins stand, for stacking them and fitting the bay round them.
//
// The RedBoard and its shield are drawn about the RedBoard's own frame: std.top is its underside,
// which stands on its posts, and the origin is its power header's first pin, so the shield's grid
// has a hole on every one of its pins but the SCL-26 header's (which stands 0.06 in off it).  Its
// sockets and holes are the Uno's, so the frame is the Uno's too.
// The breakouts on the shield are each drawn about their own std.origin as they stand on it:
// std.top is the shield's top face, which a header's plastic stands on, and the origin is the
// middle of its pin field, so a board placed on a grid point has every pin in a hole.  Pins are
// 0.1 in apart; the long ends of the headers go down through the shield, soldered and cut to
// `tail` below its top face.  Sizes marked "~" are read off photos or are a family's usual, worth
// checking on the boards in hand.
//
//   - **SparkFun IoT RedBoard ESP32** (SparkFun WRL-19177, ~$30): an ESP32-WROOM-32E, Wi-Fi, on a
//     2.7 x 2.3 in board, with USB-C (a CH340C serial bridge), and a barrel jack that takes
//     7-15 V through a 3 A Schottky (B340A) to VIN and the board's LM1117, which makes its 5 V.
//     Its sockets and its four holes are the Uno's; the board is 0.1 in wider than the Uno's
//     each side, past its sockets' outer rows of plated holes.  Its 3.3 V logic takes no 5 V.
//   - **The shield**: a 5 x 7 cm perfboard, 18 x 24 holes, cut down to 18 x 20 (two rows off each
//     end, which no part uses) so it's no wider than the Uno's sockets, on male headers plugged
//     down into the RedBoard's power, analog and 25-RX sockets.  Its rows run from the power
//     header's to the 25-RX socket's; it stands off the RedBoard's jack end.
//   - **Adafruit TB6612 breakout** (Adafruit #2448, $5): two H-bridges of 1.2 A each, 4.5-13.5 V,
//     a polarity FET on its motor supply and its STBY pulled up.  19.05 x 26.67 mm, on two rows
//     of pins 0.6 in apart: 10 of supply and logic, and 6 of the two bridges' outputs and ground.
//     It has no current limit and no current output.
//   - **Adafruit INA219 breakout** (Adafruit #904, ~$10): a high-side current and voltage monitor
//     on I2C, across a 0.1 Ohm shunt: +-3.2 A at 0.8 mA.  25.4 x 20.3 mm, one row of 6 pins, a
//     STEMMA QT socket at each end.
//
// The RedBoard's outline and parts are from SparkFun's Eagle layout
// (github.com/sparkfun/SparkFun_IoT_RedBoard-ESP32), the Adafruit boards' from Adafruit's
// (github.com/adafruit/Adafruit-TB6612-Motor-Driver-Breakout-PCB, .../Adafruit-INA219-Current-
// Sensor-PCB, the STEMMA QT revision); their corners, rounded, are drawn square.  The INA219
// stands on its one row of pins, the rest of it held out over the perfboard; the TB6612 on both
// its rows.

unit mm
use std
use std.place (coords, seats, raised)
use std.shapes

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

interface RedBoardSizes {
  x0: Length, x1: Length, y0: Length, y1: Length, pcb_t: Length, socket_h: Length, tail: Length
  jack_x0: Length, jack_x1: Length, jack_y0: Length, jack_y1: Length, jack_h: Length, jack_z: Length
  usb_w: Length, usb_h: Length, usb_in: Length, usb_out: Length, usb_y: Length
  qwiic_x0: Length, qwiic_x1: Length, qwiic_y0: Length, qwiic_y1: Length, qwiic_h: Length
  lipo_x0: Length, lipo_x1: Length, lipo_y0: Length, lipo_y1: Length, lipo_h: Length
  sd_x0: Length, sd_x1: Length, sd_y0: Length, sd_y1: Length, sd_h: Length
  jack_plug: Length, plug_w: Length, plug_h: Length, plug_len: Length
}
redboard_dims := {
  x0: -27.94mm,                 // its outline, from the power header's first pin: 2.7 x 2.3 in,
  x1: 40.64mm,                  // the USB end toward -x; 0.1 in past the Uno's each side in y
  y0: -5.08mm,
  y1: 53.34mm,
  pcb_t: 1.6mm,
  socket_h: 8.5mm,              // the female headers, over its top face
  tail: 1.5mm,                  // ~ its through-hole pins, under its underside
  jack_x0: -30.91mm,            // the barrel jack (SMD), its mouth's lip 3 mm out past the end
  jack_x1: -16.11mm,
  jack_y0: 1.6mm,
  jack_y1: 10.6mm,
  jack_h: 11mm,                 // ~
  jack_z: 6.5mm,                // ~ its pin's axis, over the top face
  usb_w: 8.94mm,                // the USB-C receptacle's shell, standing on the top face
  usb_h: 3.26mm,
  usb_in: 6.48mm,               // back from the board's end
  usb_out: 1.35mm,              // out past it
  usb_y: 36.83mm,               // its axis
  qwiic_x0: -27.46mm,           // the Qwiic socket, a right-angle JST SH by the SCL socket's end,
  qwiic_x1: -22.56mm,           // its mouth to the board's end; unused
  qwiic_y0: 46.53mm,
  qwiic_y1: 52.53mm,
  qwiic_h: 2.9mm,               // ~
  lipo_x0: -10.35mm,            // the LiPo's right-angle JST PH, by the power header; unused
  lipo_x1: -2.35mm,
  lipo_y0: -4.27mm,
  lipo_y1: 3.23mm,
  lipo_h: 5.5mm,                // ~
  sd_x0: -23.48mm,              // the microSD socket, push-push: a card in it would stand 5 mm
  sd_x1: -13.38mm,              // out past the board's end, so none goes in
  sd_y0: 14.47mm,
  sd_y1: 29.98mm,
  sd_h: 2mm,                    // ~
  jack_plug: 11mm,              // ~ a barrel plug's moulded body, mated: the room it needs
  plug_w: 12.5mm,               // ~ a USB-C cable's moulded plug, mated: the room it needs
  plug_h: 7mm,
  plug_len: 30mm,
}

// The RedBoard's sockets, the Uno's, looking down on it, its USB toward -x, each place given as
// its silkscreen labels it (the digital pins by their GPIO, the analog ones by their ADC
// channel):
//   y = 48.26: SCL SDA 3V3 GND 18 19 23 5 27 26 (the Uno's SCL ... D8, x = -9.14 to 13.72), then
//              25 17 16 14 13 4 1 3 (D7 ... D0, x = 17.78 to 35.56, on the 0.1 in grid with the
//              rest)
//   y = 0:     LED REF RST 3V3 5V GND GND VIN (the Uno's NC IOREF RESET 3V3 5V GND GND VIN, x = 0
//              to 17.78), then A5 A4 A7 A6 A3 A0 (GPIO33 32 35 34 39 36, the Uno's A0 ... A5,
//              x = 22.86 to 35.56)
// SDA and SCL are GPIO21 and GPIO22, the Qwiic socket's too, and aren't on the analog socket as
// an Uno's are.  A7, A6, A3 and A0, GPIO34 to 39, only read.  VIN
// is the jack's voltage, through the board's Schottky.
// Each socket as its first pin, its count, and whether the shield plugs into it: all but the
// SCL-26 socket, which stands 0.06 in off the others' grid.
interface SocketPlace { x0: Length, y: Length, n: Int, shield: Int }
uno_top_y := 48.26mm            // the far row of sockets
uno_sockets := [
  {x0: 0mm, y: 0mm, n: 8, shield: 1},              // power
  {x0: 22.86mm, y: 0mm, n: 6, shield: 1},          // analog
  {x0: 17.78mm, y: uno_top_y, n: 8, shield: 1},    // 25-RX
  {x0: -9.14mm, y: uno_top_y, n: 10, shield: 0},   // SCL-26
]

// The Uno's M3 holes, the RedBoard's: by the power header, by the SCL socket, and two at the far
// end.
uno_holes := [(-13.97mm, 0mm), (-12.7mm, uno_top_y), (38.1mm, 5.08mm), (38.1mm, 33.02mm)]

interface ShieldSizes {
  w: Length, h: Length, pcb_t: Length, cols: Int, rows: Int, col0: Length, row0: Length
  plug: Length
}
shield_dims := {
  w: 50mm,                      // a 5 x 7 cm perfboard, its 7 cm across the Uno, cut down to 20
  h: 50.8mm,                    // rows: across the Uno, half a pitch past its outer rows
  pcb_t: 1.6mm,
  cols: 18,                     // its holes, 0.1 in apart, centred on it
  rows: 20,
  col0: -5.08mm,                // its first column's hole, in the Uno's frame: two holes out from
  row0: 0mm,                    // the power header's first pin; its first row, that header's
  plug: 6mm,                    // how far its header pins reach down into the Uno's sockets
}

interface Tb6612Sizes {
  w: Length, row_y: Length, pcb_t: Length, n_logic: Int, n_out: Int
  chip_w: Length, chip_len: Length, chip_x: Length, chip_y: Length, chip_h: Length
}
tb6612_dims := {
  w: 26.67mm,                   // 1.05 in, along its rows of pins
  row_y: 7.62mm,                // each row off the middle: 0.6 in apart, the board 0.75 in across
  pcb_t: 1.6mm,                 // ~
  n_logic: 10,                  // the supply's and the logic's, at -y
  n_out: 6,                     // the bridges' outputs and ground, at +y
  chip_w: 7.8mm,                // the TB6612FNG, an SSOP-24, along the rows
  chip_len: 7.6mm,              // across its leads
  chip_x: 1.65mm,
  chip_y: -0.25mm,
  chip_h: 1.6mm,                // ~
}

// The TB6612's pins, looking down on its parts with its outputs' row toward +y, from -x:
//   -y: PWMA AIN2 AIN1 STBY BIN1 BIN2 PWMB GND VCC VM
//   +y: AO1 AO2 GND GND BO2 BO1
// VM is its motor supply, through the polarity FET; VCC its logic's, 2.7-5.5 V.  STBY is pulled
// up to VCC (10 kOhm) on the board.  Its 3.5 mm terminal block, VM and GND again at the board's
// +x end, isn't fitted.

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

// A box square to the body's frame: x0..x1, y0..y1, z0..z1, its middle placed by its ordinates.
component Box(x0: Length, x1: Length, y0: Length, y1: Length, z0: Length, z1: Length) {
  cx := (x0 + x1) / 2
  cy := (y0 + y1) / 2
  in std.top {
    c := point hint((cx, cy))
    c coords(du: cx, dv: cy) std.top
    sq := std.shapes.CenteredRectangle(c, w: x1 - x0, h: y1 - y0)
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

// A row of `n` male pins along x from x = x0, plugged down into the RedBoard's sockets under the
// shield: the plastic between the sockets and the shield, and the pins from `plug` down in the
// sockets up through the shield.
component PlugRow(h: HeaderSizes, s: ShieldSizes, u: RedBoardSizes, at: SocketPlace) {
  x0 := at.x0
  y := at.y
  n := at.n
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

// One of the RedBoard's sockets along x from x = x0, `n` pins: its plastic on the board's top
// face, and its pins' tails under it.
component SocketRow(u: RedBoardSizes, at: SocketPlace) {
  x0 := at.x0
  y := at.y
  n := at.n
  plastic := Box(x0: x0 - pitch / 2, x1: x0 + (n - 0.5) * pitch, y0: y - pitch / 2,
                 y1: y + pitch / 2, z0: u.pcb_t, z1: u.pcb_t + u.socket_h)
  tails := Box(x0: x0 - 0.5mm, x1: x0 + (n - 1) * pitch + 0.5mm, y0: y - 0.5mm, y1: y + 0.5mm,
               z0: -u.tail, z1: 0mm)
}

// The SparkFun IoT RedBoard ESP32, in its own frame (std.top its underside), its USB and its jack
// toward -x: its board, the parts on it (the tall ones: the jack, the USB-C and the sockets; and
// the low ones by its end, the Qwiic, the LiPo's JST and the microSD) and the pins' tails under
// it.  `usb_plug` and `jack_plug` are the room a mated cable's plug takes, out from each mouth
// along -x, for the bay's wall to clear.
component RedBoardEsp32(s: RedBoardSizes) {
  z1 := s.pcb_t                                    // its top face
  pcb := Box(x0: s.x0, x1: s.x1, y0: s.y0, y1: s.y1, z0: 0mm, z1: z1)
  jack := Box(x0: s.jack_x0, x1: s.jack_x1, y0: s.jack_y0, y1: s.jack_y1, z0: z1,
              z1: z1 + s.jack_h)
  usb := Box(x0: s.x0 - s.usb_out, x1: s.x0 + s.usb_in, y0: s.usb_y - s.usb_w / 2,
             y1: s.usb_y + s.usb_w / 2, z0: z1, z1: z1 + s.usb_h)
  qwiic := Box(x0: s.qwiic_x0, x1: s.qwiic_x1, y0: s.qwiic_y0, y1: s.qwiic_y1, z0: z1,
               z1: z1 + s.qwiic_h)
  lipo := Box(x0: s.lipo_x0, x1: s.lipo_x1, y0: s.lipo_y0, y1: s.lipo_y1, z0: z1,
              z1: z1 + s.lipo_h)
  sd := Box(x0: s.sd_x0, x1: s.sd_x1, y0: s.sd_y0, y1: s.sd_y1, z0: z1, z1: z1 + s.sd_h)

  board := solid(pcb.body)
  parts := solid(jack.body)
  usb.body union parts
  qwiic.body union parts
  lipo.body union parts
  sd.body union parts
  tails := solid()
  repeat at in uno_sockets {
    socket := SocketRow(s, at)
    socket.plastic.body union parts
    socket.tails.body union tails
  }

  usb_z := z1 + s.usb_h / 2                        // the receptacle's axis, up from its underside
  usb_x := s.x0 - s.usb_out                        // its mouth
  usb_room := Box(x0: usb_x - s.plug_len, x1: usb_x, y0: s.usb_y - s.plug_w / 2,
                  y1: s.usb_y + s.plug_w / 2, z0: usb_z - s.plug_h / 2, z1: usb_z + s.plug_h / 2)
  construction usb_plug := solid(usb_room.body)
  jack_y := (s.jack_y0 + s.jack_y1) / 2
  jack_axis := z1 + s.jack_z                       // the jack's pin, up from its underside
  jack_room := Box(x0: s.jack_x0 - s.plug_len, x1: s.jack_x0, y0: jack_y - s.jack_plug / 2,
                   y1: jack_y + s.jack_plug / 2, z0: jack_axis - s.jack_plug / 2,
                   z1: jack_axis + s.jack_plug / 2)
  construction jack_plug := solid(jack_room.body)
}

// The perfboard shield on the RedBoard, in its frame: its board, and the headers that plug it
// into the RedBoard's power, analog and 25-RX sockets.  `top` is its top face, up from the
// RedBoard's underside, which the breakouts stand on.
component Shield(s: ShieldSizes, u: RedBoardSizes, h: HeaderSizes) {
  top := u.pcb_t + u.socket_h + h.body_h + s.pcb_t  // over the sockets and its headers' plastic
  mx := (s.w - (s.cols - 1) * pitch) / 2           // its margins, past the outer holes
  my := (s.h - (s.rows - 1) * pitch) / 2
  pcb := Box(x0: s.col0 - mx, x1: s.col0 + (s.cols - 1) * pitch + mx, y0: s.row0 - my,
             y1: s.row0 + (s.rows - 1) * pitch + my, z0: top - s.pcb_t, z1: top)

  board := solid(pcb.body)
  headers := solid()
  repeat at in uno_sockets {
    when at.shield == 1 {
      plug := PlugRow(h, s, u, at)
      plug.plastic.body union headers
      plug.pins union headers
    }
  }
}

// The Adafruit TB6612 breakout on its two rows of pins along x, its outputs' row toward +y.
component Tb6612(s: Tb6612Sizes, h: HeaderSizes) {
  z0 := h.body_h
  z1 := z0 + s.pcb_t
  // the board reaches a pitch past the logic's row, and half a pitch past the outputs'
  pcb := Box(x0: -s.w / 2, x1: s.w / 2, y0: -s.row_y - pitch, y1: s.row_y + pitch / 2,
             z0: z0, z1: z1)
  chip := Box(x0: s.chip_x - s.chip_w / 2, x1: s.chip_x + s.chip_w / 2,
              y0: s.chip_y - s.chip_len / 2, y1: s.chip_y + s.chip_len / 2,
              z0: z1, z1: z1 + s.chip_h)
  logic := HeaderRow(h, y: -s.row_y, n: s.n_logic, pcb_t: s.pcb_t)
  outputs := HeaderRow(h, y: s.row_y, n: s.n_out, pcb_t: s.pcb_t)

  board := solid(pcb.body)
  chip.body union board
  headers := solid(logic.plastic.body)
  logic.pins union headers
  outputs.plastic.body union headers
  outputs.pins union headers
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
  redboard := RedBoardEsp32(redboard_dims)
  shield := Shield(shield_dims, u: redboard_dims, h: header_dims)
  in std.top {
    drv_at := point hint((7.5 * pitch, 4 * pitch))
    drv_at coords(du: 7.5 * pitch, dv: 4 * pitch) std.top
    ina_at := point hint((7 * pitch, 13.5 * pitch))
    ina_at coords(du: 7 * pitch, dv: 13.5 * pitch) std.top
  }
  drv_on := point
  drv_on raised(d: shield.top, along: std.z) drv_at
  drv := Tb6612(tb6612_dims, h: header_dims)
  drv seats(turn: 180deg, up: std.z, east: std.x) drv_on
  ina_on := point
  ina_on raised(d: shield.top, along: std.z) ina_at
  ina := Ina219(ina219_dims, h: header_dims)
  ina seats(turn: -90deg, up: std.z, east: std.x) ina_on
}
