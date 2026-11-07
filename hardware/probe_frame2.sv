// Temporary probe: the bot's frame, its axes held outright.
unit mm
use std
use std.place (coords)
use parts (Block)
bot := frame
fix(origin == (0mm, 0mm, 0mm)) bot
fix(dir == (0, 1, 0)) bot.u
fix(dir == (-1, 0, 0)) bot.v
b := Block(x0: 10mm, x1: 20mm, y0: -1mm, y1: 1mm, z0: 0mm, z1: 1mm) in bot
in std.top {
  q := point
  q coords(du: 10mm, dv: 2mm) bot
}
