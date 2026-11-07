// Temporary probe: the bot's frame without sines.
unit mm
use std
use std.place (coords)
use parts (Block)
bot_turn := 90deg
bot := frame
fix(origin == (0mm, 0mm, 0mm)) bot
bot.u perpendicular std.z
bot.v perpendicular std.z
std.x angle(bot_turn, about: std.z) bot.u
bot.u perpendicular(sense: ccw, about: std.z) bot.v
b := Block(x0: 10mm, x1: 20mm, y0: -1mm, y1: 1mm, z0: 0mm, z1: 1mm) in bot
in std.top {
  q := point
  std.origin distance(10mm, along: bot.u) q
  std.origin distance(2mm, along: bot.v) q
}
