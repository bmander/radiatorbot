# Radiator bot: mechanical design

A gearmotor that clamps to the radiator valve's supply pipe and turns the star handle. A 130 motor
drives a printed spur train, which turns a socket round the handle. The motor's
current says when the stem reaches either end of its screw. An Arduino Uno R4 Minima reads an
old dry-contact thermostat and runs the motor through an Adafruit DRV8871 H-bridge, on a perfboard
shield plugged into it. An INA219 current monitor in the driver's supply tells it when the motor
stalls. A 9 V wall adapter in the Uno's barrel jack powers it all.

Everything is FDM-printed except the drill rod the gears turn on and the screws. The model is
`radiatorbot.sv`. The valve it fits is `radiator_valve.sv`, and the parts libraries are
`gears.sv`, `motor130.sv` and `boards.sv` (the Uno, its shield, the motor driver and the current
monitor).

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
gearbox grows to hold them: 101 × 93 mm in plan.

The socket reduces 8⁄3 where the conjugate wheel it replaced stepped up 1.5. So the train has one
16 → 64 stage fewer, a compound fewer, and stands 5.5 mm lower.

That is 384:1 from the motor to A and **1024:1 from the motor to the handle**. The motor's
figures are estimates for a servo's 130 at 6 V (`motor130.sv`): 12 000 rpm free and 6 mN·m
stall. With six printed meshes at about 0.9 each, and the handle in the socket a direct drive,
that gives:

- **11.7 rpm free at the handle**, so three and a half turns of travel take 20–30 s under load;
- **3.27 N·m at the handle at stall**, 1.36 N·m at A.

With one mesh fewer, the motor now turns the other way for the same handle turn. The firmware
sets which way is open when it's commissioned (`motor_invert`, in [firmware/README.md](../firmware/README.md)).

`radiatorbot.sv` states the requirements as claims, which every check judges: stall torque
≥ 2 N·m at the handle, free speed ≥ 6 rpm, and the 1024:1 ratio. Read any figure back in its unit,
for example `solventc hardware/radiatorbot.sv --where handle_stall_torque`.

The current trip sets the torque that actually seats the valve. Set it with the valve in hand,
well under stall. Measure the motors in the pile (free speed and stall current at the supply
voltage), put them in `motor130.sv`, and the figures and claims follow.

## The electronics

An Arduino stands beside the motor with a cut-down 5 × 7 cm perfboard shield plugged into it, and
two bought boards and the thermostat's terminal soldered to the shield. All are modelled in
`boards.sv`, from their makers' layouts where there is one, and placed in the bay in
`radiatorbot.sv`.

| board | what it does | price | where |
|---|---|---|---|
| [Arduino Uno R4 Minima](https://store.arduino.cc/products/uno-r4-minima) (ABX00080) | the controller: barrel jack 6–24 V, its own 5 V, USB-C | $20 | Arduino, Digi-Key, Mouser, SparkFun |
| [Adafruit DRV8871 breakout](https://www.adafruit.com/product/3190) (#3190) | H-bridge, 6.5–45 V, current limited at ~2.1 A | $7.50 | Adafruit, Digi-Key |
| [Adafruit INA219 breakout](https://www.adafruit.com/product/904) (#904) | high-side current and voltage over I2C, 0.1 Ω shunt, ±3.2 A | ~$10 | Adafruit, Digi-Key |

**Why these.**
- The Uno R4 Minima takes the wall adapter itself. Its barrel jack takes 6–24 V through a 2 A
  Schottky diode (PMEG6020) to its VIN pin and to its own 1.2 A buck, which makes the board's
  5 V. The driver runs off VIN, so one adapter powers everything, and there are no buck modules to
  set with a meter.
  - Its outline, its sockets and its four M3 holes are the Uno's, the most copied board there is.
    The model takes them from KiCad's Uno R3 footprint.
  - Its USB-C gives programming and the console, and powers the board alone (not the motor).
  - It has no Wi-Fi. The firmware uses none.
  - The XIAO ESP32-C3 the bot had before was a fifth of the price, but it took a 7.5 V buck
    module for the motor, a Mini-360 set to 5.3 V with a Schottky for itself, and, to run off a
    thermostat's 24 VAC, a bridge rectifier and an optocoupler.
- The DRV8871 is the H-bridge. Adafruit publishes its Eagle layout, which the model is taken
  from: a 20.3 × 24.1 mm board on one row of four pins, with two 3.5 mm screw terminals at the
  far end.
  - **It needs 6.5 V or more** and locks out below about 6.4 V, so USB's 5 V can't run the motor.
    Off the 9 V adapter, the 130 (rated for 6 V) would be overdriven, so the firmware scales the
    PWM to the supply the INA219 reads: two thirds at 9 V, half at 12 V. The motor sees 6 V on
    average whatever the adapter, and its stall current is 6 V's.
  - The 30 kΩ on its ILIM pin limits the current to about 2.1 A, above the 130's ~1.8 A stall.
    The hardware never cuts in before the firmware's trip does.
  - It has no current output. That's what the INA219 is for.
  - Its inputs are pulled down on the chip, so the motor stays off while the Uno boots. Both
    inputs low coasts the motor and puts the chip to sleep after 1 ms. There is no sleep pin or
    fault pin to wire.
- The INA219 sits in the driver's supply, on the high side. It reads the current through its
  0.1 Ω shunt over I2C, ±3.2 A.
  - Reading on the high side keeps the driver's ground the Uno's.
  - It reads the supply's voltage as well. The firmware scales the PWM by it, and calls a move a
    motor fault if the adapter is unplugged or sags under the driver's lockout.
  - A 12-bit conversion takes 532 µs, which averages over ten periods of the 20 kHz PWM.
  - It carries the driver's whole draw: the motor's current while the bridge drives, plus the
    chip's few mA. Under the PWM that reads about the PWM's fraction times the motor's current
    (a stall at 9 V reads about 1.2 A), and the firmware divides the fraction back out. The
    currents the console shows, and the trips, are the motor's own.
  - Its bus input is rated to 26 V, so keep the adapter at 24 V or under (the Uno's limit too).
  - Its STEMMA QT sockets go unused, and so does its screw terminal: VIN+ and VIN− are on its
    pins too.

**The thermostat** is an old two-wire heating thermostat: a mercury switch on a bimetal coil, or
a bimetal snap switch, the kind on the wall of a house built in the 1960s or 70s, or out of
architectural salvage. It's a dry contact that closes on a call for heat. It makes no voltage of
its own: in the house it came from, the boiler's 24 V transformer or a standing pilot's thermopile
drove its loop. Here the Uno drives it.
- Its two wires go to a screw terminal on the shield: one to ground, one to D2 through 1 kΩ. A
  4.7 kΩ resistor pulls D2 up to 5 V and a 100 nF capacitor holds it to ground. The contact
  closed reads low.
  - The resistors and the capacitor are for the wire's length: they keep noise and a static spark
    off the pin. The 1 mA through the contact is plenty for mercury, which doesn't tarnish.
  - The firmware acts on a state only once it has held for 3 s, so a bounce as the mercury rolls,
    or the thermostat's own chatter, never runs the motor.
- Its heat anticipator, a small adjustable heater in series with the contact, sees only that
  1 mA, so it never warms. The thermostat then swings a degree or two wider than it would on a
  boiler. A radiator is slow enough not to mind. Its setting doesn't matter.
- Mount it level, as it was on the wall: a mercury switch works by tilting. If its bulb ever
  breaks, the mercury is hazardous waste.
- Use a low-voltage (24 V or millivolt) thermostat. A line-voltage one, for electric baseboard
  heat, is a heavier snap switch labelled 120 or 240 V. It would work as a contact, but it's the
  wrong part.
- **Don't wire a thermostat that also runs a boiler** to D2: its loop carries the boiler's 24 VAC.
  Sharing one would need an optocoupler between the two.

**Power.** A 9 V, 2 A wall adapter with a 5.5 × 2.1 mm centre-positive plug goes into the Uno's
barrel jack: the Mean Well GST18U09-P1J (9 V, 2 A, US wall plug, its P1J plug that size;
[$14.10 at Jameco](https://www.jameco.com/z/GST18U09-P1J-MEAN-WELL-18-Watt-9V-2A-AC-DC-High-Reliability-Industrial-Wall-Adapter-2-1mm-Plug-Level-VI_2225609.html),
and through Mean Well's other distributors). Any regulated 9–12 V adapter with that plug and
1.5 A or more serves.
- At a stall the motor draws about 1.8 A at 6 V, so the adapter carries about 1.2 A at 9 V, and
  the Uno and the INA219 a few tens of mA more. The Uno's Schottky is rated 2 A.
- A 1 A adapter, like Adafruit's 9 V (#63), runs the motor but sits at its limit at each stall.
- A USB cable in the Uno powers it alone, for programming and the console. The motor waits for
  the adapter; until it's in, every move is a motor fault.

**Wiring**, all on the shield (each board's pins are listed in `boards.sv`):

| from | to | |
|---|---|---|
| Uno VIN | INA219 VIN+ | the adapter's 9 V, through the Uno's Schottky |
| INA219 VIN− | DRV8871 VM | the driver's supply, through the shunt |
| Uno 5V | INA219 VCC; a 4.7 kΩ to D2 | the INA219 pulls I2C up to it, the R4's 5 V logic |
| Uno GND | DRV8871 GND, INA219 GND, the thermostat terminal; a 100 nF to D2 | one ground |
| Uno A4 (SDA) | INA219 SDA | I2C; address 0x40 |
| Uno A5 (SCL) | INA219 SCL | |
| Uno D5 | DRV8871 IN1 | PWM (GPT2) |
| Uno D6 | DRV8871 IN2 | PWM (GPT0) |
| Uno D2 | the thermostat terminal, through 1 kΩ | the contact to ground |
| DRV8871 OUT1, OUT2 | the motor | the driver's motor terminal |

To drive, hold one input high and pull the other low for the PWM's on-time (slow decay). The
bridge brakes through the off-time, so the motor's speed follows the PWM, and the supply carries
the motor's current only while the bridge drives. Which input is held high sets the direction.
Both inputs high brakes; both low coasts.

**End of travel.** Drive until the motor's current crosses the trip current, held for some tens
of milliseconds so the start-up surge doesn't trip it, then stop.
- Set the trip with the valve in hand, well under stall (see *The drive*). The torque at the trip
  is what seats the valve.
- Ignore the first ~100 ms after each start: the inrush current is near stall.
- The INA219's 12-bit conversion averages the PWM's ripple out.

**In the bay.**
- The motor stands in the bay's −y half, on a 2.8 mm pad on the lid, and the boards stand beside
  it in the +y half, so the bay is only as tall as the motor. Over the Uno it was 25 mm taller.
- The Uno stands on four 6 mm posts on the lid, at its holes. Its edge stands 2 mm off the
  motor's cradle, and its board 4.7 mm off the motor. The post by its D8–SCL socket stands about
  0.6 mm off its SCL pin's tail.
- Its jack's mouth stands 1 mm in from the end wall, its USB-C's 1.9 mm. The end wall has a
  window on each, a plug's moulded body plus the print clearance: 11 mm square on the jack,
  12.5 × 7 mm on the USB-C.
- The shield is the perfboard, its 7 cm across the Uno, on male headers plugged into the Uno's
  power, analog and D0–D7 sockets (8, 6 and 8 pins).
  - It's cut down to 18 × 20 holes, two rows off each end, which no part used. Its rows then run
    from the power header's (row 0) to the D0–D7 socket's (row 19), and it's no wider than the
    Uno, so it clears the motor's cradle by 3.3 mm. Whole, it would overhang the cradle.
  - Its first column is two holes out from the power header's first pin, and its first row is
    that header's, so all three sockets fall on its grid. It misses the D8–SCL socket, which stands 0.06 in off the grid, and
    stands clear of the jack.
  - Its underside stands 12.6 mm over the Uno's, 2.5 mm over the tops of the Uno's sockets and
    its ICSP header.
- The driver stands in the shield's column 9, rows 2–5, its board out toward +x. Its screw
  terminals face the bay's +x wall, with about 26 mm of room for the motor's leads.
- The INA219 stands in column 9, rows 11–16, its board out toward +x beside the driver's.
- Each Adafruit board stands on one row of pins, with the rest of it held out over the
  shield. A dab of hot glue under its far end stops it rocking.
- The thermostat's 2-way terminal stands at the shield's −x end, in column 1, rows 7 and 9. The
  end wall's grommet is low beside the motor, and the wires come in there and over the Uno's end.
- The motor sets the bay's height: the cover stands 3 mm over its end bell's boss, for its
  terminals and leads. The driver's terminal blocks, the tallest parts on the shield, stand 5.6 mm
  under it.
- The cover's west screw stands on the south wall, between the base's screw in the corner and the
  motor; the Uno's end is up against the end wall.

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
  - the boards, their headers and the Uno's tall parts clear the frame, the cover and one
    another, the shield clearing the Uno's parts by 2.5 mm;
  - the pins' tails under the shield clear the Uno's parts, and the Uno's under it clear the
    posts;
  - the Uno, the shield and the driver clear the motor and its cradle, and the motor clears the
    cover.
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
  - M3 × 8 self-tapping, four (the Uno);
  - M3 set screws, two (the collar and the stand).
- **Motor:** one 130 motor from the pile, as calipered in `motor130.sv`: a 24 mm can, 18.25 mm
  across the flats and 30.65 mm long. Its pinion is a press fit on the 2 mm shaft, which runs on
  5.5 mm past the pinion, beside stage 2, and ends 1 mm over stage 3's gear on B.
- **Electronics** (no fabbed PCB); see *The electronics*:
  - an Arduino Uno R4 Minima (ABX00080, $20): the controller, and the adapter's way in;
  - a 5 × 7 cm perfboard (18 × 24 holes, cut down to 18 × 20), and 0.1 in male headers for it:
    8, 6 and 8 pins;
  - an Adafruit DRV8871 breakout (#3190, $7.50), its header and terminal blocks included: the
    H-bridge. It takes its supply on its VM and GND pins, so its supply terminal can be left
    off; the model keeps its room;
  - an Adafruit INA219 breakout (#904, ~$10), its header included: the motor's current over I2C,
    for the end-of-travel sensing. Leave its terminal block off;
  - a 2-way 5.08 mm screw terminal, a 1 kΩ and a 4.7 kΩ resistor and a 100 nF capacitor: the
    thermostat's input;
  - a 9 V, 2 A wall adapter with a 5.5 × 2.1 mm centre-positive plug: a Mean Well GST18U09-P1J
    (~$14), or any regulated 9–12 V adapter of 1.5 A or more with that plug.
- **The thermostat:** an old two-wire, low-voltage heating thermostat (mercury or bimetal), and
  two-conductor thermostat wire (18/2) to it.
- **Cable entries** are in the bay's end wall: a grommet hole for the thermostat's cable, and a
  window each on the Uno's barrel jack and its USB-C.

## Assembly

1. Press the B and D rods into the base's floor and the ½ in axle into the base's bridge.
   Slide the upper collar up the axle from below, against the bridge, and tighten its set
   screw.
2. Stack the compounds on the rods (D2, B2, D1, B1) and fit the motor's pinion.
3. Close the base with the frame, putting the motor into its cradle, and fit the four M3 screws
   from inside the bay.
4. Make the shield. Plug the male headers into the Uno's power, analog and D0–D7 sockets, lay the
   perfboard on them (cut to 18 × 20 holes, its first row on the power header and its first
   column two holes out from that header's first pin, its 7 cm across the Uno) and solder them, so
   they line up. Solder the driver and the INA219 on their headers, the long ends down, at the
   grid places above, and cut the tails to 1.5 mm.
   Add the thermostat's terminal, the two resistors and the capacitor, and wire them as in the
   table.
5. Screw the Uno to its posts with its jack and USB-C toward the end wall's windows, plug the
   shield on, and connect the motor's leads to the driver's terminal. Pass the thermostat's cable
   through the grommet to its terminal.
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
  must stay under the DRV8871's ~2.1 A limit.
- **The Uno's connectors.** Its outline, sockets and holes are the Uno standard, but the R4
  Minima's USB-C is placed where the R3's USB-B was, and its jack is taken as 11 mm tall with its
  pin 6.5 mm up. Check both against the end wall's windows on the board in hand before printing
  the frame, and the plugs of the cables you'll use (taken as 12.5 × 7 mm and 11 mm square).
- **The boards' heights.** The DRV8871's terminal blocks (taken as 8.5 mm tall) are estimated,
  and stand 5.6 mm under the cover: check them.
- **The ring and last pinion run open** under the base, beside the packing nut. A guard would be
  a small printed part.
