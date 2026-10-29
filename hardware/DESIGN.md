# Radiator bot: mechanical design

A gearmotor that clamps to the radiator valve's supply pipe and turns the star handle. A 130 motor
drives a printed spur train, which turns a socket round the handle. The motor's
current says when the stem reaches either end of its screw. A SparkFun IoT RedBoard ESP32 reads
an old dry-contact thermostat and runs the motor through an Adafruit TB6612 H-bridge, on a
perfboard shield plugged into it. An INA219 current monitor in the driver's supply tells it when
the motor stalls. A 9 V wall adapter in the RedBoard's barrel jack powers it all, and its Wi-Fi
puts the bot on the home network, for a phone.

Everything is FDM-printed except the drill rod the gears turn on and the screws. The model is
`radiatorbot.sv`. The valve it fits is `radiator_valve.sv`, and the parts libraries are
`gears.sv`, `motor130.sv` and `boards.sv` (the RedBoard, its shield, the motor driver and the
current monitor).

## How it works

The bot hangs on the valve's −y side, beside the outlet. Seen from below, looking up at the
handle, it stands a quarter turn clockwise from where it hung before, off the outlet's far end
(−x). `radiatorbot.sv` lays the bot out in a frame of its own, `bot`, turned `bot_turn` (90°)
about the stem. Its x runs out from the stem through the clamp's split, and the bot hangs on its
−x side. Directions below (the bay's −y half, the driver toward +x) are that frame's.

- **The socket** is a 64-tooth gear (module 1.364) round the handle, turning about the stem
  with it. Its middle is a hole the shape of the handle's top face, grown 0.3 mm all round,
  straight from its floor up out of its top. The handle turns it 1:1, all four arms at once.
  - The stem screws the handle 7.21 mm down over its three and a half turns, as measured (the
    bare stem under the packing nut opens from 4.38 mm to 11.59 mm). `radiator_valve.sv` draws
    the handle on a screw along its stem, 2.06 mm a turn. The socket stays where it is, and the
    handle screws up and down through its hole.
  - The arms' 8° draft leans them in toward their bottom face, so each arm is widest at its top
    edge. The socket's top stands 1 mm over the handle's top face when it's closed, and its hole
    runs on down past where the handle stands open. So every arm's top edge is always in the
    hole, 0.3 mm off its wall, and that edge, the straight length of each arm's side, drives.
  - The arms' play in the hole is ±0.5° of the handle, and each arm is driven near its tip.
  - Under the open handle's bottom face the socket has a 4 mm floor. It turns on a pad on the
    stem's axis at the end of the **stand**, an arm clamped to A under its pinion.
  - The pivot is a 6 mm pin printed up from the pad into an 8 mm blind hole in the floor's
    middle. The pin keeps the pad under the socket and the socket over the pad.
  - The pin is 1 mm loose all round on purpose. The handle centres the socket to 0.3 mm, and the
    pin never fights it for the centre, however the stand is set. The pad only bears the
    socket's weight.
- **A** is a fixed ½ in axle 60 mm from the stem. A's compound turns on it: a 24-tooth pinion
  driving the socket, and over it a 48-tooth ring (module 1.5) driven by the train, one print.
  The upper collar over the ring and the stand under the pinion keep it in place.
- **The gear train** has four stages on two fixed 0.311 in rods, B and D. The motor's pinion
  drives stage 1 on B; stages 2–4 alternate between B and D; the last pinion, on D, drives the
  ring.
  - B stands 45 mm beyond A, where the gearbox was laid out. D stands 32 mm from B at 69.2°, so
    it is 45 mm from A as well.
- **The frame** is one print: the gearbox lid, the electronics bay standing on it (the motor on a
  pad, the boards beside it), and a spine up beside the valve to the **clamp**.
  - The clamp is a block split at the stem, round the valve's inlet hex and the supply pipe above
    it. The fixed half is the frame's; the cap closes it from the side away from the bot (the
    valve's +y), out of the radiator's way, with four M4 bolts whose nuts sit in pockets in the
    fixed half's back.
  - The hex pocket takes the handle's reaction torque positively; nothing relies on friction on
    a round pipe.
  - The hex has a flat square to the outlet, so the split crosses the middles of two flats: each
    half holds two whole flats and half of each of those, with a corner in its middle.
  - Both rows of bolts grip the pipe above the hex. The lower row clears the hex's pocket by about
    3 mm, and at least 1 mm is claimed.
  - The clamp is 48 mm across, so its radiator-side face reaches out over the outlet's union nut
    (18.5 mm from the stem, 18.8 mm thick), whose top stands above the hex's underside. Both
    halves are relieved round the nut, its hex grown 2 mm all round.
- **The base** is the gearbox's floor and walls, screwed up to the lid. Its floor stops short of
  the ring, and a bridge across it holds A's axle, standing on the upper collar just above the
  ring.

## The drive

| stage | teeth | module | axles | ratio |
|---|---|---|---|---|
| 1 | 12 → 24 | 0.8 | motor → B | 2 |
| 2 | 16 → 64 | 0.8 | B → D | 4 |
| 3 | 16 → 64 | 0.8 | D → B | 4 |
| 4 | 16 → 48 | 1.0 | B → D | 3 |
| ring | 12 → 48 | 1.5 | D → A | 4 |
| socket | 24 → 64 | 1.364 | A → handle | 8⁄3 |

Every pinion is profile-shifted +0.3 against undercut, and its gear −0.3, so the centre
distances stay nominal: B–D is 32 mm, D–A 45 mm and A–stem 60 mm.

The pinions on the rods have 16 teeth. A 12-tooth pinion at module 0.8 has its roots on an
8.1 mm circle, inside the 8.25 mm bore a 0.311 in rod needs. At 16 teeth the roots stand 1.5 mm
clear of the bore; `radiatorbot.sv` claims that wall, so a change of rod or pinion that thins it
fails the check. Each stage keeps its ratio, so the gears grow to 64 and 48 teeth, and the
gearbox grows to hold them: 101 × 95 mm in plan, 2 mm of that for the RedBoard in the bay
over it.

The socket reduces 8⁄3 where the conjugate wheel it replaced stepped up 1.5. So the train has one
16 → 64 stage fewer, a compound fewer, and stands 5.5 mm lower.

That is 384:1 from the motor to A and **1024:1 from the motor to the handle**. The motor's
figures are measured on the bench at the 9 V the firmware gives it (`motor130.sv`): 13 500 rpm
free and 6.9 mN·m stall, at 1.2 A. With six printed meshes at about 0.9 each, and the handle in
the socket a direct drive, that gives:

- **13.2 rpm free at the handle**, so three and a half turns of travel take 20–30 s under load;
- **3.76 N·m at the handle at stall**, 1.57 N·m at A.

At 6 V the same motor would give 8 700 rpm and 4.7 mN·m: 2.6 N·m at the handle, too little
margin. Its winding is 7.5 Ω, so at 9 V it stalls at 1.2 A, well inside the driver.

With one mesh fewer, the motor now turns the other way for the same handle turn. The firmware
sets which way is open when it's commissioned (`motor_invert`, in [firmware/README.md](../firmware/README.md)).

`radiatorbot.sv` states the requirements as claims, which every check judges: stall torque
≥ 2 N·m at the handle, free speed ≥ 6 rpm, and the 1024:1 ratio. Read any figure back in its unit,
for example `solventc hardware/radiatorbot.sv --where handle_stall_torque`.

The current trip sets the torque that actually seats the valve. Set it with the valve in hand,
well under stall. Another motor's figures differ: measure it on the bench with
[firmware/tools/bench.html](../firmware/tools/bench.html) (its speed against its voltage, heard,
and its stall), put them in `motor130.sv`, and the figures and claims follow.

## The electronics

A SparkFun IoT RedBoard ESP32 stands beside the motor with a cut-down 5 × 7 cm perfboard shield
plugged into it, and two bought boards and two screw terminals soldered to the shield. All are
modelled in `boards.sv`, from their makers' layouts, and placed in the bay in `radiatorbot.sv`.

| board | what it does | price | where |
|---|---|---|---|
| [SparkFun IoT RedBoard ESP32](https://www.sparkfun.com/products/19177) (WRL-19177) | the controller: Wi-Fi, barrel jack 7–15 V, its own 5 V and 3.3 V, USB-C | ~$30 | SparkFun, Digi-Key |
| [Adafruit TB6612 breakout](https://www.adafruit.com/product/2448) (#2448) | two H-bridges of 1.2 A, 4.5–13.5 V, tied together here as one of 2 A | $5 | Adafruit, Digi-Key |
| [Adafruit INA219 breakout](https://www.adafruit.com/product/904) (#904) | high-side current and voltage over I2C, 0.1 Ω shunt, ±3.2 A | ~$10 | Adafruit, Digi-Key |

**Why these.**
- The RedBoard takes the wall adapter itself. Its barrel jack takes 7–15 V through a 3 A
  Schottky diode (B340A) to its VIN pin, and to the LM1117 that makes the board's 5 V, from which
  a 700 mA regulator makes its 3.3 V. The driver runs off VIN, so one adapter powers everything.
  - Its sockets and its four M3 holes are the Uno's, so a shield made for an Uno's sockets plugs
    in. The board itself is 0.1 in wider each side, 2.7 × 2.3 in: the bay is 2 mm wider for it.
  - Its ESP32 has Wi-Fi: the bot's console is on the network as well as on the USB-C, and it
    serves a page for a phone (see [firmware/README.md](../firmware/README.md)).
  - Its USB-C, through a CH340C serial bridge, gives programming and the console, and powers the
    board alone (not the motor).
  - **It's 3.3 V logic, and no pin takes 5 V.** Everything on the shield runs off its 3V3.
  - Its silkscreen labels its digital pins by their GPIO (4, 13, 25…) and its analog ones by
    their ADC channel, not by the Uno's places: its analog socket reads A5, A4, A7, A6, A3, A0
    (GPIO33, 32, 35, 34, 39, 36), and the last four are input only.
  - Its I2C pins, GPIO21 and GPIO22 (labelled SDA and SCL), aren't on the analog socket as an
    Uno's are. They're on its Qwiic socket, whose mouth faces the bay's end wall 3 mm away, and on
    the SCL–26 socket, off the shield's grid. The ESP32 puts I2C on any two pins that drive, so
    the INA219 is on the analog socket's first two, A5 and A4 (GPIO33 and GPIO32).
  - The linear 5 V regulator turns the adapter's extra volts to heat: about 0.4 W at 9 V with
    the Wi-Fi up, twice that at 12 V. 9 V is the adapter to use.
  - The Uno R4 Minima the bot had before had no Wi-Fi.
- The TB6612 is the H-bridge. Adafruit publishes its Eagle layout, which the model is taken from:
  a 19.05 × 26.67 mm board on two rows of pins 0.6 in apart, 10 of supply and logic and 6 of the
  outputs.
  - **Its two bridges are tied together**, input to input and output to output, as one bridge of
    twice the current. Each is rated 1.2 A, and every move ends in a stall: the 130 stalls at
    1.2 A at 9 V. Paralleled, the chip's rated about 2 A continuous, which is what Pololu
    recommends for a motor that stalls. The three logic pins drive both bridges at once.
  - Its motor supply takes 4.5–13.5 V (15 V at most), so the adapter stays at 12 V or under. The
    firmware scales the PWM to the supply the INA219 reads, so the motor sees 9 V on average
    (`motor_volts`): all of a 9 V adapter, three quarters of a 12 V one. Its speed and stall
    current are 9 V's whatever the adapter, but for a 9 V adapter's sag under load.
  - **It has no current limit**, only a thermal shutdown. The firmware's trip is all that stops
    a stall, so it takes trips of 2 A at most: a trip over the stall would never trip, and the
    motor would stall on to the move's timeout.
  - It has no current output. That's what the INA219 is for.
  - IN1 high and IN2 low drives one way while the PWM input is high, the other way with them
    swapped. PWM low, or both inputs high, brakes; both low coasts. STBY low sleeps the chip, its
    outputs off; the breakout pulls it up.
  - A 10 kΩ on the shield pulls the PWM input down, so while the ESP32 boots, its pins
    floating, the bridge can only brake or coast.
  - Its logic takes 2.7–5.5 V, and runs off the RedBoard's 3V3.
- The INA219 sits in the driver's supply, on the high side. It reads the current through its
  0.1 Ω shunt over I2C, ±3.2 A.
  - Reading on the high side keeps the driver's ground the RedBoard's.
  - It reads the supply's voltage as well. The firmware scales the PWM by it, and calls a move a
    motor fault if the adapter is unplugged, sags under 6.5 V, or is over the TB6612's 13.5 V.
  - A 12-bit conversion takes 532 µs, which averages over ten periods of the 20 kHz PWM.
  - It carries the driver's whole draw: the motor's current while the bridge drives, plus the
    chip's few mA. Under the PWM that reads about the PWM's fraction times the motor's current
    (a stall reads about 1.2 A off a 9 V adapter, 0.9 A off a 12 V one), and the firmware divides
    the fraction back out. The
    currents the console shows, and the trips, are the motor's own.
  - It runs off the RedBoard's 3V3, so its 10 kΩ pull-ups hold I2C at 3.3 V. Two 4.7 kΩ on the
    shield stiffen them for 400 kHz.
  - Its STEMMA QT sockets go unused, and so does its screw terminal: VIN+ and VIN− are on its
    pins too.

**The thermostat** is an old two-wire heating thermostat: a mercury switch on a bimetal coil, or
a bimetal snap switch, the kind on the wall of a house built in the 1960s or 70s, or out of
architectural salvage. It's a dry contact that closes on a call for heat. It makes no voltage of
its own: in the house it came from, the boiler's 24 V transformer or a standing pilot's thermopile
drove its loop. Here the RedBoard drives it.
- Its two wires go to a screw terminal on the shield: one to ground, one to pin 4 (GPIO4)
  through 1 kΩ. A 4.7 kΩ resistor pulls it up to 3.3 V and a 100 nF capacitor holds it to
  ground. The contact closed reads low.
  - The resistors and the capacitor are for the wire's length: they keep noise and a static spark
    off the pin. The 0.7 mA through the contact is plenty for mercury, which doesn't tarnish.
  - The firmware acts on a state only once it has held for 3 s, so a bounce as the mercury rolls,
    or the thermostat's own chatter, never runs the motor.
- Its heat anticipator, a small adjustable heater in series with the contact, sees only that
  0.7 mA, so it never warms. The thermostat then swings a degree or two wider than it would on a
  boiler. A radiator is slow enough not to mind. Its setting doesn't matter.
- Mount it level, as it was on the wall: a mercury switch works by tilting. If its bulb ever
  breaks, the mercury is hazardous waste.
- Use a low-voltage (24 V or millivolt) thermostat. A line-voltage one, for electric baseboard
  heat, is a heavier snap switch labelled 120 or 240 V. It would work as a contact, but it's the
  wrong part.
- **Don't wire a thermostat that also runs a boiler** to pin 4: its loop carries the boiler's
  24 VAC. Sharing one would need an optocoupler between the two.
- From the phone page or the console, the bot can be told to open or close regardless, and
  handed back to the thermostat after. It can't change the thermostat's setting.

**Power.** A 9 V, 2 A wall adapter with a 5.5 × 2.1 mm centre-positive plug goes into the
RedBoard's barrel jack: the Mean Well GST18U09-P1J (9 V, 2 A, US wall plug, its P1J plug that size;
[$14.10 at Jameco](https://www.jameco.com/z/GST18U09-P1J-MEAN-WELL-18-Watt-9V-2A-AC-DC-High-Reliability-Industrial-Wall-Adapter-2-1mm-Plug-Level-VI_2225609.html),
and through Mean Well's other distributors). Any regulated 9–12 V adapter with that plug and
1.5 A or more serves; 9 V keeps the RedBoard's regulator cool. A 12 V one holds the motor's 9 V
steady under load, but warms the regulator.
- At a stall the motor draws about 1.2 A at 9 V, so the adapter carries about 1.2 A at 9 V (0.9 A
  at 12 V), and the RedBoard (its Wi-Fi up) and the INA219 a hundred mA or so more. The
  RedBoard's Schottky is rated 3 A.
- A 1 A adapter, like Adafruit's 9 V (#63), runs the motor but sits at its limit at each stall.
- A USB cable in the RedBoard powers it alone, for programming and the console. The motor waits
  for the adapter; until it's in, every move is a motor fault.

**Wiring**, all on the shield (each board's pins are listed in `boards.sv`; the RedBoard's pins
are named as its silkscreen labels them, the ESP32 GPIO in brackets where the label isn't it).
The same as a schematic:

![The shield's wiring: the RedBoard's pins, the INA219, the TB6612 and the two terminals](wiring.svg)

| from | to | |
|---|---|---|
| RedBoard VIN | INA219 VIN+ | the adapter's 9 V, through the RedBoard's Schottky |
| INA219 VIN− | TB6612 VM | the driver's supply, through the shunt |
| RedBoard 3.3V | INA219 VCC, TB6612 VCC; a 4.7 kΩ each to 4, A5 and A4 | the 3.3 V logic; nothing on the shield sees 5 V |
| RedBoard GND | TB6612 GND (all three), INA219 GND, the thermostat terminal; a 100 nF to 4; a 10 kΩ to 25 | one ground |
| RedBoard A5 (GPIO33) | INA219 SDA | I2C at 400 kHz; address 0x40 |
| RedBoard A4 (GPIO32) | INA219 SCL | |
| RedBoard 13 | TB6612 STBY | low sleeps the driver |
| RedBoard 16 | TB6612 AIN1 and BIN1 | the direction |
| RedBoard 17 | TB6612 AIN2 and BIN2 | |
| RedBoard 25 | TB6612 PWMA and PWMB | the 20 kHz PWM, pulled down |
| RedBoard 4 | the thermostat terminal, through 1 kΩ | the contact to ground |
| TB6612 AO1 and BO1 | the motor terminal's first way | the bridges' outputs, tied |
| TB6612 AO2 and BO2 | its second way | |

**On the shield's grid**, looking down on it, columns 0–17 from its −x end (the jack's) and rows
0–19 from the power header's, as `radiatorbot.sv` places them:

| where | pins, in order |
|---|---|
| row 0, columns 2–9 | the RedBoard's power socket: LED, REF, RST, 3.3V, 5V, GND, GND, VIN |
| row 0, columns 11–16 | its analog socket: A5 (GPIO33), A4 (GPIO32), A7, A6, A3, A0 |
| row 19, columns 9–16 | its 25–RX socket: 25, 17, 16, 14, 13, 4, 1/TX-0, 3/RX-0 |
| row 1, columns 7–12 | the TB6612's outputs: BO1, BO2, GND, GND, AO2, AO1 |
| row 7, columns 5–14 | its logic: VM, VCC, GND, PWMB, BIN2, BIN1, STBY, AIN1, AIN2, PWMA |
| column 9, rows 11–16 | the INA219: VIN+, VIN−, SDA, SCL, GND, VCC |
| column 1, rows 7 and 9 | the thermostat's terminal |
| column 17, rows 2 and 4 | the motor's terminal |

Each of the TB6612's twins stands in the same row as the other: PWMB in column 8
and PWMA in 14, BIN2 in 9 and AIN2 in 13, BIN1 in 10 and AIN1 in 12; BO1 in 7 and AO1 in 12, BO2
in 8 and AO2 in 11. The resistors and the capacitor go where they're short and clear of the
breakouts' boards, which stand over the shield: the TB6612's covers columns 4–14, rows 1–8, and
the INA219's columns 8–16, rows 9–18.

Tie each pair of the TB6612's pins with a short wire or a solder bridge on the shield's
underside, so both bridges always see the same inputs and drive the same leads. To drive, hold
the direction on AIN1/AIN2 and pull PWM low for the off-time (slow decay). The bridge brakes
through the off-time, so the motor's speed follows the PWM, and the supply carries the motor's
current only while the bridge drives.

**End of travel.** Drive until the motor's current crosses the trip current, held for some tens
of milliseconds so the start-up surge doesn't trip it, then stop.
- Set the trip with the valve in hand, well under stall (see *The drive*). The torque at the trip
  is what seats the valve.
- Ignore the first ~100 ms after each start: the inrush current is near stall.
- The INA219's 12-bit conversion averages the PWM's ripple out.

**In the bay.**
- The motor stands in the bay's −y half, on a 2.8 mm pad on the lid, and the boards stand beside
  it in the +y half, so the bay is only as tall as the motor.
- The RedBoard stands on four 6 mm posts on the lid, at its holes. Its edge stands 2 mm off the
  motor's cradle, its board 4.7 mm off the motor, and its far edge 1.8 mm off the bay's +y wall.
  The post by its SCL–26 socket stands about 0.6 mm off its SCL pin's tail.
- Its jack's mouth stands 1 mm in from the end wall, its USB-C's 2.6 mm. The end wall has a
  window on each, a plug's moulded body plus the print clearance: 11 mm square on the jack,
  12.5 × 7 mm on the USB-C.
- Its microSD socket, by its end, stays empty: a card in it would stand into the end wall.
- The shield is the perfboard, its 7 cm across the RedBoard, on male headers plugged into its
  power, analog and 25–RX sockets (8, 6 and 8 pins).
  - It's cut down to 18 × 20 holes, two rows off each end, which no part used. Its rows then run
    from the power header's (row 0) to the 25–RX socket's (row 19), and it clears the motor's
    cradle by 5.8 mm.
  - Its first column is two holes out from the power header's first pin, and its first row is
    that header's, so all three sockets fall on its grid. It misses the SCL–26 socket, which
    stands 0.06 in off the grid, and stands clear of the jack.
  - Its underside stands 12.6 mm over the RedBoard's, 2.5 mm over the tops of the sockets.
- The TB6612 stands on both its rows: its outputs' row in the shield's row 1, columns 7–12, toward
  the motor, and its logic's in row 7, columns 5–14. It clears the plug pins in row 0 by 1.8 mm.
- The INA219 stands in column 9, rows 11–16, its board out toward +x, 1.3 mm clear of the
  TB6612's. It stands on one row of pins, the rest of it held out over the shield; a dab of hot
  glue under its far end stops it rocking.
- The thermostat's 2-way terminal stands at the shield's −x end, in column 1, rows 7 and 9. The
  end wall's grommet is low beside the motor, and the wires come in there and over the
  RedBoard's end.
- The motor's 2-way terminal stands at its +x end, in column 17, rows 2 and 4, 1.9 mm past the
  TB6612's end, with 14 mm of room for the leads before the bay's +x wall.
- The motor sets the bay's height: the cover stands 3 mm over its end bell's boss, for its
  terminals and leads. The screw terminals, the tallest parts on the shield, stand 8.2 mm under
  it.
- The cover's west screw stands on the south wall, between the base's screw in the corner and the
  motor; the RedBoard's end is up against the end wall.

## Printing

The fits are an FDM printer's. They're set in one table at the top of `radiatorbot.sv`:

| fit | allowance |
|---|---|
| a gear's bore turning on drill rod | +0.35 mm |
| a rod pressed into the housing | +0.05 mm (drill or ream to fit) |
| printed faces that meet or pass | 0.3 mm |
| each gear's teeth, thinned on the pitch circle | 0.15 mm (0.3 mm backlash a mesh) |
| each gear's tips, chamfered 45° at both faces | 0.4 mm |
| the socket's hole round the chrome handle | 0.3 mm each side |
| walls | 2.4 mm (six 0.4 mm perimeters) |

- Gears print flat, face down. Module 0.8 is the finest stage; it wants a 0.4 mm nozzle and
  0.12–0.16 mm layers.
- Print the socket, A's compound and D2 in PETG or ASA rather than PLA. A radiator is warm, and
  those parts carry the torque.
- Each compound gear (a gear with its pinion) prints as one part.
- The chamfers keep the first layer's squash (elephant's foot) and the top edge's burr out of the
  mesh.
- The 64-tooth gears of stages 2 and 3 (D1, B2) are spoked: five 2.4 mm spokes between a hub
  round the pinion and a 2.4 mm rim under the tooth roots, the windows' corners rounded. The
  smaller gears, the ring and the socket, which carry the most torque, stay solid.
- The socket prints floor down, its hole open at the top.

Generate the STLs with `sh hardware/export.sh`. It's one `solventc` run that builds every part
once, and every gear of one size and face once, placed for each copy; `*.stl` and `*.step` are
gitignored. The same run writes `radiatorbot.step`, the whole bot as one STEP assembly for a CAD
system: a part for each object (the valve as measured, the bought parts as their outlines and the
printed parts), each placed where it stands, the valve's and the boards' grouped under them. Each
gear's teeth are the rack's exact sweep, built as one tooth sector turned round the gear; a spoked
gear is shaped whole and its windows cut after. Set `shaped := 0` in `radiatorbot.sv` to draw every
gear and the socket as blanks while changing the layout.

## How it's checked

- `solventc hardware/radiatorbot.sv` solves the whole bot at DOF 0, follows `handle_open` from
  closed through three and a half turns open, the handle screwing down its stem, and judges the
  design table's claims (ratio, stall torque, free speed, and the pinions' walls round their
  bores).
- The boards' fit in the bay is claimed in the model and judged on every check:
  - a mated USB-C plug and a mated barrel plug each clear their window in the end wall by 0.3 mm;
  - the boards, their headers, the terminals and the RedBoard's tall parts clear the frame, the
    cover and one another, the shield clearing the RedBoard's parts by 2.5 mm and the RedBoard
    clearing the bay's walls by 1.8 mm;
  - the pins' tails under the shield clear the RedBoard's parts, and the RedBoard's under it
    clear the posts;
  - the RedBoard, the shield and the driver clear the motor and its cradle, and the motor clears
    the cover.
- With `checks := 1` in `radiatorbot.sv`, every clearance is judged as well. That builds every
  shaped part, so it takes about two minutes.
  - The socket turns with the handle and its hole is the same at every height, so only the
    handle's height in it changes. The socket and the stand are judged against the handle open,
    where they come nearest; A's compound against it closed. The socket clears the handle by
    0.357 mm at the arms' top edges, where the top face's broken edge meets the hole's wall.
  - A's compound clears the handle by 1.3 mm (its web over the handle's top face); the stand
    clears it by 3 mm, at the pivot pin's top. The socket clears the packing nut by 4.1 mm.
  - Every gear mesh runs 0.14 mm clear between flanks.
  - The motor's shaft, out past its pinion, clears B's first compound by 3.4 mm and D's by 14,
    and its end clears B's second by 1.8 mm.
  - Every housing part clears the valve, except the contacts meant to be there (the motor on its
    pad, the base against the frame, the clamp on the pipe). Both of the clamp's halves clear the
    outlet's union nut by 2 mm and its boss by 1.2 mm.

## Bill of materials

- **Printed:** frame, base, clamp cap, cover, socket, A's compound (its pinion and the ring),
  the stand, the upper collar (`collar_part`), motor pinion, and compounds B1, B2, D1, D2.
- **Drill rod:** ½ in × 78 mm (A's axle); 0.311 in × 45 mm, two of them (B and D).
- **Screws:**
  - M4 × 50, four, with nuts (clamp);
  - M3 × 10 self-tapping, eight (base to lid, cover);
  - M3 × 8 self-tapping, four (the RedBoard);
  - M3 set screws, two (the collar and the stand).
- **Motor:** one 130 motor from the pile, as calipered in `motor130.sv`: a 24 mm can, 18.25 mm
  across the flats and 30.65 mm long. Its pinion is a press fit on the 2 mm shaft, which runs on
  5.5 mm past the pinion, beside stage 2, and ends 1 mm over stage 3's gear on B.
- **Electronics** (no fabbed PCB); see *The electronics*:
  - a SparkFun IoT RedBoard ESP32 (WRL-19177, ~$30): the controller, its Wi-Fi, and the
    adapter's way in;
  - a 5 × 7 cm perfboard (18 × 24 holes, cut down to 18 × 20), and 0.1 in male headers for it:
    8, 6 and 8 pins;
  - an Adafruit TB6612 breakout (#2448, $5), its headers included: the H-bridge, its two bridges
    tied together on the shield. It takes its supply on its VM and GND pins: leave its terminal
    block off;
  - an Adafruit INA219 breakout (#904, ~$10), its header included: the motor's current over I2C,
    for the end-of-travel sensing. Leave its terminal block off;
  - two 2-way 5.08 mm screw terminals: the thermostat's and the motor's;
  - a 1 kΩ, three 4.7 kΩ and a 10 kΩ resistor and a 100 nF capacitor: the thermostat's input,
    the I2C's pull-ups and the PWM's pull-down;
  - a 9 V, 2 A wall adapter with a 5.5 × 2.1 mm centre-positive plug: a Mean Well GST18U09-P1J
    (~$14), or any regulated 9–12 V adapter of 1.5 A or more with that plug.
- **The thermostat:** an old two-wire, low-voltage heating thermostat (mercury or bimetal), and
  two-conductor thermostat wire (18/2) to it.
- **Cable entries** are in the bay's end wall: a grommet hole for the thermostat's cable, and a
  window each on the RedBoard's barrel jack and its USB-C.

## Assembly

1. Press the B and D rods into the base's floor and the ½ in axle into the base's bridge.
   Slide the upper collar up the axle from below, against the bridge, and tighten its set
   screw.
2. Stack the compounds on the rods (D2, B2, D1, B1) and fit the motor's pinion.
3. Close the base with the frame, putting the motor into its cradle, and fit the four M3 screws
   from inside the bay.
4. Make the shield. Plug the male headers into the RedBoard's power, analog and 25–RX sockets, lay
   the perfboard on them (cut to 18 × 20 holes, its first row on the power header and its first
   column two holes out from that header's first pin, its 7 cm across the board) and solder them,
   so they line up. Solder the TB6612 and the INA219 on their headers, the long ends down, at the
   grid places above, and cut the tails to 1.5 mm. Tie the TB6612's twin pins together under the
   shield (AIN1–BIN1, AIN2–BIN2, PWMA–PWMB, AO1–BO1, AO2–BO2).
   Add the two terminals, the resistors and the capacitor, and wire them as in the table. Before
   plugging the shield in, check with a meter that no pin of it reaches the RedBoard's 5V.
5. Screw the RedBoard to its posts with its jack and USB-C toward the end wall's windows, plug
   the shield on, and connect the motor's leads to the motor terminal. Pass the thermostat's
   cable through the grommet to its terminal.
6. Slide the bot onto the valve from −y, so the inlet hex enters the clamp's pocket. Drop the
   four M4 nuts into their pockets in the fixed half's back, and bolt on the cap from +y.
7. **Push A's compound up its axle from below**, its ring into mesh with D2's last pinion, up
   against the upper collar.
8. Turn the handle so it's closed. **Push the socket up over the handle from below**, its teeth
   into mesh with A's pinion, until its top stands 1 mm over the handle's top face. Turn the
   handle a little to bring its arms into the hole: the hole is straight and the arms narrow
   downward, so they go in freely.
9. Hold the socket there and slide the stand up A's axle from below, swinging its arm under the
   socket so its pin goes up into the floor's hole. Stop when its pad bears the floor and its
   collar stands 0.3 mm under A's compound. The pin in its hole points the arm at the stem;
   tighten the set screw.

## Open questions

- **Under the handle.** The socket's floor stands 1.5 mm under the handle's bottom face when it's
  open, and the pivot's hole leaves a 1 mm roof in it. The model takes that face as flat. A screw or nut holding the handle on its stem, under
  it, would need a recess in the floor: check before printing the socket.
- **Round the handle.** The socket reaches 44.6 mm from the stem all round, 7.5 mm past the arms'
  tips, at the handle's height. Check that the radiator and the floor leave it room.
- **The motors' figures.** See *The drive* above. The stall current also sets the trip, and
  must stay under the paralleled TB6612's ~2 A: a 130 that stalls well over it wants a bigger
  driver.
- **The RedBoard's connectors.** Its outline, its parts' places and its jack's and USB-C's
  footprints are from SparkFun's layout, but its jack is taken as 11 mm tall with its pin 6.5 mm
  up. Check both against the end wall's windows on the board in hand before printing the frame,
  and the plugs of the cables you'll use (taken as 12.5 × 7 mm and 11 mm square).
- **The boards' heights.** The screw terminals (taken as 10 mm tall) stand 8.2 mm under the
  cover: check them.
- **The ring and last pinion run open** under the base, beside the packing nut. A guard would be
  a small printed part.
