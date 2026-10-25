# Radiator bot: mechanical design

A gearmotor that clamps to the radiator valve's supply pipe and turns the star handle. A 130 motor
drives a printed five-stage spur train, which drives a wheel conjugate to the handle. The motor's
current says when the stem reaches either end of its screw. An ESP32 (a Seeed XIAO ESP32-C3) on a
perfboard reads the thermostat and runs the motor through an Adafruit DRV8871 H-bridge. An INA219
current monitor in the driver's supply tells it when the motor stalls.

Everything is FDM-printed except the drill rod the gears turn on and the screws. The model is
`radiatorbot.sv`. The valve it fits is `radiator_valve.sv`, and the parts libraries are
`gears.sv`, `motor130.sv` and `boards.sv` (the ESP32, the motor driver and the current monitor).

## How it works

The bot hangs on the valve's −x side, away from the radiator.

- **The wheel** turns on a ½ in axle 60 mm from the stem, at the handle's height. A collar on
  the axle under it and another over it keep it in place. It has six pockets. The handle's four
  arms are its teeth, so the handle turns 1.5× per wheel turn. The pockets are not designed. In
  one statement, Solvent sweeps the measured star through the blank over a whole wheel turn, as
  the two turn together, and removes everything it passes through.
  That is a gear shaper's generating cut done with the handle as the cutter, so the wheel is
  conjugate to the handle by construction. The cut is exact, with no scallops.
  - The cutter is everything the handle occupies over the stem's travel. The arms' 8° draft
    leans them in toward their bottom face, so that is the star where it stands open, and above
    it a straight prism of the star's top face, which passes every height from open up to closed.
    The star where it stands closed lies inside them.
  - Each pocket's walls lean with the draft below the handle's open top face and stand straight
    above it, with no step between: the arm clears by the same 0.3 mm anywhere on its travel.
- **The ring** is a 48-tooth gear (module 1.5) printed on top of the wheel as one part.
- **The gear train** has five stages on two fixed 0.311 in rods, B and D. The motor's pinion
  drives stage 1 on B; stages 2–5 alternate between B and D; the last pinion, on B, drives the
  ring.
- **The frame** is one print: the gearbox lid, the electronics bay standing on it, and a spine
  up beside the valve to the **clamp**.
  - The clamp is a block split at the stem, round the valve's inlet hex and the supply pipe above
    it.
  - The hex pocket takes the handle's reaction torque positively; nothing relies on friction on
    a round pipe.
  - The cap bolts on from the radiator side with four M4 bolts.
- **The base** is the gearbox's floor and walls, screwed up to the lid. Its floor stops short of
  the ring, and a bridge across it holds the wheel's axle, standing on the upper collar just
  above the ring.

## The drive

| stage | teeth | module | axles | ratio |
|---|---|---|---|---|
| 1 | 12 → 24 | 0.8 | motor → B | 2 |
| 2 | 16 → 64 | 0.8 | B → D | 4 |
| 3 | 16 → 64 | 0.8 | D → B | 4 |
| 4 | 16 → 64 | 0.8 | B → D | 4 |
| 5 | 16 → 48 | 1.0 | D → B | 3 |
| ring | 12 → 48 | 1.5 | B → wheel | 4 |
| handle | 6 → 4 | — | wheel → handle | ⅔ |

Every pinion is profile-shifted +0.3 against undercut, and its gear −0.3, so the centre
distances stay nominal: B–D is 32 mm and B–wheel is 45 mm.

The pinions on the rods have 16 teeth. A 12-tooth pinion at module 0.8 has its roots on an
8.1 mm circle, inside the 8.25 mm bore a 0.311 in rod needs. At 16 teeth the roots stand 1.5 mm
clear of the bore; `radiatorbot.sv` claims that wall, so a change of rod or pinion that thins it
fails the check. Each stage keeps its ratio, so the gears grow to 64 and 48 teeth, and the
gearbox grows to hold them: 101 × 93 mm in plan, up from 95 × 75.

That is 1536:1 from the motor to the wheel and **1024:1 from the motor to the handle**. The
motor's figures are estimates for a servo's 130 at 6 V (`motor130.sv`): 12 000 rpm free and
6 mN·m stall. With printed meshes at about 0.9 each and the wheel at 0.8, that gives:

- **11.7 rpm free at the handle**, so three turns of travel take 20–30 s under load;
- **2.61 N·m at the handle at stall**, 4.9 N·m at the wheel.

`radiatorbot.sv` states the requirements as claims, which every check judges: stall torque
≥ 2 N·m at the handle, free speed ≥ 6 rpm, and the 1024:1 ratio. Read any figure back in its unit,
for example `solventc hardware/radiatorbot.sv --where handle_stall_torque`.

The current trip sets the torque that actually seats the valve. Set it with the valve in hand,
well under stall. Measure the motors in the pile (free speed and stall current at the supply
voltage), put them in `motor130.sv`, and the figures and claims follow.

## The electronics

Three bought boards do the work, soldered on headers to a 5 × 7 cm perfboard over the motor. All
three are modelled in `boards.sv` from their makers' layouts and stand on the perfboard's 0.1 in
grid in `radiatorbot.sv`.

| board | what it does | price | where |
|---|---|---|---|
| [Seeed XIAO ESP32-C3](https://www.seeedstudio.com/Seeed-XIAO-ESP32C3-p-5431.html) (SKU 113991054) | Wi-Fi/BLE, USB-C, four ADC pins | $4.99 | Seeed, Digi-Key, Mouser |
| [Adafruit DRV8871 breakout](https://www.adafruit.com/product/3190) (#3190) | H-bridge, 6.5–45 V, current limited at ~2.1 A | $7.50 | Adafruit, Digi-Key |
| [Adafruit INA219 breakout](https://www.adafruit.com/product/904) (#904) | high-side current and voltage over I2C, 0.1 Ω shunt, ±3.2 A | ~$10 | Adafruit, Digi-Key |

**Why these.**
- The XIAO is the cheapest ESP32 board with a dimensioned drawing (Seeed publishes its outline
  and KiCad layout). The model's pins and USB-C receptacle are taken from that layout. Cheap
  DevKit clones differ from seller to seller.
  - It is 21 × 17.8 mm against a DevKitC's 55 × 28.
  - Its USB-C gives power, programming and logs. The C3's built-in USB-JTAG resets the chip
    into the bootloader itself, so the buttons are never needed.
  - It comes with an FPC antenna on a U.FL lead. Stick it under the bay's cover, the side away
    from the cast iron.
  - Digi-Key's listing says the board no longer comes with header pins. Buy two 7-pin 0.1 in
    male headers with it, or Seeed's "pre-soldered" version.
- The DRV8871 is the H-bridge. Adafruit publishes its Eagle layout, which the model is taken
  from: a 20.3 × 24.1 mm board on one row of four pins, with two 3.5 mm screw terminals at the
  far end.
  - **It needs 6.5 V or more** and locks out below about 6.4 V, so USB's 5 V can't run the motor.
    The motor's supply is a buck module set to 7.5 V. The 130 is rated for 6 V, so the firmware
    caps the PWM at 80 %. The motor then sees 6 V on average, and its stall current is 6 V's.
  - The 30 kΩ on its ILIM pin limits the current to about 2.1 A, above the 130's ~1.8 A stall.
    The hardware never cuts in before the firmware's trip does.
  - It has no current output. That's what the INA219 is for.
  - Its inputs are pulled down on the chip, so the motor stays off while the XIAO boots. Both
    inputs low coasts the motor and puts the chip to sleep after 1 ms. There is no sleep pin or
    fault pin to wire.
- The INA219 sits in the driver's supply, on the high side. It reads the current through its
  0.1 Ω shunt over I2C, ±3.2 A at 0.8 mA a count.
  - Reading on the high side keeps the driver's ground the XIAO's.
  - It reads the rail's voltage as well, so the firmware can tell a sagging supply from a stall.
  - A 12-bit conversion takes 532 µs, which averages over many periods of a 20 kHz PWM.
  - It carries the driver's whole draw: the motor's current while the bridge drives, plus the
    chip's few mA. Under PWM that reads about the duty times the motor's current, so a stall at
    the 80 % cap reads about 1.4 A.
  - Its STEMMA QT sockets go unused, and so does its screw terminal: VIN+ and VIN− are on its
    pins too.
- The Pololu DRV8874 carrier (#4035) the bot had before reads its own current on a CS pin and
  runs from 5 V, at $11.94. The DRV8871 and the INA219 together cost about $17.50 and need the
  7.5 V supply.

**Power.** A bridge rectifier and a buck module take 24 VAC off the thermostat's transformer, or a
9–24 V DC adapter, to 7.5 V for the motor. A Mini-360 buck module takes that 7.5 V down to 5.3 V,
and a Schottky diode drops it to the XIAO's 5V pin. A USB cable in the XIAO powers the XIAO alone,
for programming and logs; the motor waits for the supply.

**Wiring**, all on the perfboard (each board's pins are listed in `boards.sv`):

| from | to | |
|---|---|---|
| XIAO D3 (GPIO5) | DRV8871 IN1 | PWM: one way |
| XIAO D10 (GPIO10) | DRV8871 IN2 | PWM: the other way |
| XIAO D4 (GPIO6, SDA) | INA219 SDA | I2C, pulled up to 3.3 V on the INA219; address 0x40 |
| XIAO D5 (GPIO7, SCL) | INA219 SCL | |
| XIAO 3V3 | INA219 VCC | |
| XIAO GND | DRV8871 GND, INA219 GND | one ground with the supply's |
| the 7.5 V buck's output | INA219 VIN+, the Mini-360's input | |
| INA219 VIN− | DRV8871 VM | the driver's supply, through the shunt |
| the Mini-360's output (5.3 V) | XIAO 5V | through a Schottky diode (1N5819) |
| DRV8871 OUT1, OUT2 | the motor | the driver's motor terminal |

To drive, hold one input high and pull the other low for the duty (slow decay). The bridge brakes
through the off-time, so the motor's speed follows the duty, and the supply carries the motor's
current only while the bridge drives. Which input is held high sets the direction. Both inputs low
coasts.

The thermostat's optocoupler goes to D2 (GPIO4, internal pull-up). Leave D0, D8 and D9 alone:
they are the C3's strapping pins.

**End of travel.** Drive until the INA219's current crosses the trip current, held for some tens
of milliseconds so the start-up surge doesn't trip it, then stop.
- Set the trip with the valve in hand, well under stall (see *The drive*), at the duty the
  firmware runs at. The current the INA219 reads scales with the duty. The torque at the trip is
  what seats the valve.
- Ignore the first ~100 ms after each start: the inrush current is near stall.
- Read the INA219 at 12 bits, or average a few readings with its own averaging. The motor's PWM
  ripples the current.

**In the bay.**
- The XIAO stands at the board's −x end, in columns 0–6 and rows 9 and 15. Its USB-C overhangs
  the board's end and faces a window in the bay's end wall. The window is a USB-C cable's
  moulded plug (12.5 × 7 mm) plus the print clearance. The receptacle stands 14 mm in from the
  wall's outside face, so a plug's overmould reaches in through the window to mate.
- The driver stands in column 15, rows 2–5, beside the 7.5 V buck. Its screw terminals face the
  bay's +x wall, with about 23 mm of room for the motor's leads.
- The INA219 stands in columns 15–20, row 11, its board out toward +y, beside the Mini-360.
- Each Adafruit board stands on one row of pins, with the rest of it held out over the
  perfboard. A dab of hot glue under its far end stops it rocking.
- The driver's terminal blocks are the tallest parts on the board. They stand 1.4 mm under the
  cover.
- The cover's west screw boss moved to y = −3 mm, out of the plug's way.

## Printing

The fits are an FDM printer's. They're set in one table at the top of `radiatorbot.sv`:

| fit | allowance |
|---|---|
| a gear's bore turning on drill rod | +0.35 mm |
| a rod pressed into the housing | +0.05 mm (drill or ream to fit) |
| printed faces that meet or pass | 0.3 mm |
| each gear's teeth, thinned on the pitch circle | 0.15 mm (0.3 mm backlash a mesh) |
| each gear's tips, chamfered 45° at both faces | 0.4 mm |
| the wheel's pockets against the chrome handle | 0.6 mm backlash |
| walls | 2.4 mm (six 0.4 mm perimeters) |

- Gears print flat, face down. Module 0.8 is the finest stage; it wants a 0.4 mm nozzle and
  0.12–0.16 mm layers.
- Print the wheel, the ring and stage 5 in PETG or ASA rather than PLA. A radiator is warm, and
  those parts carry the torque.
- Each compound gear (a gear with its pinion) prints as one part.
- The chamfers keep the first layer's squash (elephant's foot) and the top edge's burr out of the
  mesh.
- The 64-tooth gears of stages 2–4 (D1, B2, D2) are spoked: five spokes between a hub round the
  pinion and a rim under the tooth roots, the windows' corners rounded. Stages 2 and 3 have
  2.4 mm spokes and rim; stage 4, which carries about 0.5 N·m at stall, has 3 mm. The smaller
  gears and the ring, which carry the most torque, stay solid.

Generate the STLs with `sh hardware/export.sh`. It's one `solventc` run that builds every part
once, and every gear of one size and face once, placed for each copy; `*.stl` and `*.step` are
gitignored. The same run writes `radiatorbot.step`, the whole bot as one STEP assembly for a CAD
system: a part for each object (the valve as measured, the bought parts as their outlines and the
printed parts), each placed where it stands, the valve's and the boards' grouped under them. Each
gear's teeth are the rack's exact sweep, built as one tooth sector turned round the gear; a spoked
gear is shaped whole and its windows cut after. Set `shaped := 0` in `radiatorbot.sv` to draw every
gear and the wheel as blanks while changing the layout.

## How it's checked

- `solventc hardware/radiatorbot.sv` solves the whole bot at DOF 0, follows `handle_turn` through
  a full turn, and judges the design table's claims (ratio, stall torque, free speed, and the
  pinions' walls round their bores).
- The boards' fit in the bay is claimed in the model and judged on every check:
  - a mated USB plug clears the end wall's window by 0.3 mm;
  - the boards and their headers clear the frame, the cover, one another and the buck modules;
  - the pins' tails under the perfboard clear the motor.
- With `checks := 1` in `radiatorbot.sv`, every clearance is judged as well. That builds every
  shaped part and measures the wheel at thirteen poses, so it takes about four minutes.
  - The wheel is judged against the handle at seven rolls across a whole period of the mesh
    (0° to 90° of the handle: one arm through one pocket), and at three rolls each half open and
    nearly open (2 mm and 3.8 mm down the stem's travel).
  - Closed and half open, it clears by 0.353–0.361 mm, where the top face's broken edge passes
    the pockets' straight band. Nearly open, it clears by 0.311–0.325 mm against the drafted
    walls below, close to the 0.3 mm the cutter was grown by.
  - Every gear mesh runs 0.14 mm clear between flanks.
  - Every housing part clears the valve, except the contacts meant to be there (the motor on its
    lid, the base against the frame, the clamp on the pipe).

## Bill of materials

- **Printed:** frame, base, clamp cap, cover, wheel (with ring), two axle collars (one STL,
  `collar_part`), motor pinion, and compounds B1, B2, B3, D1, D2.
- **Drill rod:** ½ in × 68 mm (wheel axle); 0.311 in × 45 mm, two of them (B and D).
- **Screws:**
  - M4 × 50, four, with nuts (clamp);
  - M3 × 10 self-tapping, eight (base to lid, cover);
  - M2.5 × 6, four (perfboard);
  - M3 set screws, two (collars).
- **Motor:** one 130 motor from the pile. Its pinion is a press fit on the 2 mm shaft.
- **Electronics, on a 5 × 7 cm perfboard** (no fabbed PCB); see *The electronics*:
  - a Seeed XIAO ESP32-C3 ($4.99), with two 7-pin 0.1 in male headers and its FPC antenna;
  - an Adafruit DRV8871 breakout (#3190, $7.50), its header and terminal blocks included: the
    H-bridge. It takes its supply on its VM and GND pins, so its supply terminal can be left
    off; the model keeps its room;
  - an Adafruit INA219 breakout (#904, ~$10), its header included: the motor's current over I2C,
    for the end-of-travel sensing. Leave its terminal block off;
  - for the motor's 7.5 V: a bridge rectifier and a buck module rated above 40 V in and about
    2.5 A out (rectified 24 VAC peaks near 34 V, beyond an MP1584's rating). Off a 9–24 V DC
    adapter, the same two parts serve;
  - a Mini-360 buck module set to 5.3 V and a 1N5819 Schottky diode, for the XIAO's 5 V;
  - an optocoupler to read the thermostat's call for heat;
  - a 3-way 5.08 mm screw terminal.
- **Cable entries** are in the bay's end wall: a grommet hole for the thermostat and supply cable,
  and a window on the XIAO's USB-C.

## Assembly

1. Press the B and D rods into the base's floor and the ½ in axle into the base's bridge.
   Slide the upper collar up the axle from below, against the bridge, and tighten its set
   screw.
2. Stack the compounds on the rods (B3, D2, B2, D1, B1) and fit the motor's pinion.
3. Close the base with the frame, putting the motor into its cradle, and fit the four M3 screws
   from inside the bay.
4. Solder the XIAO, the driver and the INA219 to the perfboard on their headers, the long ends
   down, at the grid places above, and cut the tails to 1.5 mm. Wire them as in the table, stick
   the XIAO's antenna under the cover, and screw the perfboard to its posts with the USB-C toward
   the end wall's window.
5. Slide the bot onto the valve from −x, so the inlet hex enters the clamp's pocket, and bolt on
   the cap.
6. Turn the handle so it's closed and **push the wheel up its axle from below** into mesh with
   both the handle and the last pinion, up against the upper collar. Fit the lower collar.
   - The star narrows downward and each of the wheel's bands is cut for the star's widest section
     at that band. So the wheel only ever gains clearance as it rises into place.
   - Going in sideways, by contrast, is not assured.

## Open questions

- **Stem travel.** The model assumes the handle as measured is closed, and that it drops 4 mm on
  opening (`stem_travel`). Measure it, closed to open. If the stem doesn't drop, set it to 0 and
  the pockets' straight band above the draft goes.
- **The inlet hex's orientation** relative to the outlet. The model has a corner on ±x, so the
  bot can stand at multiples of 60° about the stem. Check it on the valve.
- **The thermostat's interface.** It's a 2-wire R/W dry contact, a 24 VAC R/W/C, or something
  else. That decides whether the bot can draw its power from the thermostat wiring.
- **The motors' figures.** See *The drive* above. The stall current also sets the trip, and
  must stay under the DRV8871's ~2.1 A limit.
- **The boards' heights.** The XIAO's board thickness (taken as 1.2 mm) and the cable's plug
  (taken as 12.5 × 7 mm) are estimates. Check the plug of the cable you'll use against the window.
  The DRV8871's terminal blocks (taken as 8.5 mm tall) are estimated too, and stand 1.4 mm under
  the cover: check them.
- **The ring and last pinion run open** under the base, beside the packing nut. A guard would be
  a small printed part.
