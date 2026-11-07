// Temporary probe: the bot's frame without sines.
unit mm
use std
use std.place (coords)
use parts (Block)
bot_turn := 90deg
bot := std.top at(under: std.z) bot_turn
b := Block(x0: 10mm, x1: 20mm, y0: -1mm, y1: 1mm, z0: 0mm, z1: 1mm) in bot
in std.top {
  q := point
  q coords(du: 10mm, dv: 2mm) bot
}
