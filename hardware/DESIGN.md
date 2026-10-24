# Radiator bot: mechanical design

A gearmotor that clamps to the radiator valve's supply pipe and turns the star handle. A 130 motor
drives a printed five-stage spur train, which drives a wheel conjugate to the handle. The motor's
current says when the stem reaches either end of its screw. An ESP32 (a Seeed XIAO ESP32-C3) on a
perfboard reads the thermostat and runs the motor through a Pololu DRV8874 H-bridge, whose current
output tells it when the motor stalls.

Everything is FDM-printed except the drill rod the gears turn on and the screws. The model is
`radiatorbot.sv`. The valve it fits is `radiator_valve.sv`, and the parts libraries are
`gears.sv`, `motor130.sv` and `boards.sv` (the ESP32 and the motor driver).

## How it works

The bot hangs on the valve's −x side, away from the radiator.

- **The wheel** turns on an 8 mm axle 60 mm from the stem, at the handle's height. It has six
  pockets. The handle's four arms are its teeth, so the handle turns 1.5× per wheel turn. The
  pockets are not designed. In one statement, Solvent sweeps the measured star through the blank
  over a whole wheel turn, as the two turn together, and removes everything it passes through.
  That is a gear shaper's generating cut done with the handle as the cutter, so the wheel is
  conjugate to the handle by construction. The cut is exact, with no scallops.
  - The cutter is everything the handle occupies over the stem's travel.
  - It follows the arms' 8° draft in six steps, each the star's section where the arm is widest
    over that band. Each step over-clears the draft by at most 0.4 mm a side.
  - The drafted star itself, unstepped, is refused in Solvent v0.1.3: its swept region changes
    shape between heights.
- **The ring** is a 48-tooth gear (module 1.5) printed on top of the wheel as one part.
- **The gear train** has five stages on two fixed 5 mm rods, B and D. The motor's pinion drives
  stage 1 on B; stages 2–5 alternate between B and D; the last pinion, on B, drives the ring.
- **The frame** is one print: the gearbox lid, the electronics bay standing on it, and a spine
  up beside the valve to the **clamp**.
  - The clamp is a block split at the stem, round the valve's inlet hex and the supply pipe above
    it.
  - The hex pocket takes the handle's reaction torque positively; nothing relies on friction on
    a round pipe.
  - The cap bolts on from the radiator side with four M4 bolts.
- **The base** is the gearbox's floor and walls, screwed up to the lid. Its floor stops short of
  the ring, and a bridge across it holds the wheel's axle just above the ring.

## The drive

| stage | teeth | module | axles | ratio |
|---|---|---|---|---|
| 1 | 12 → 24 | 0.8 | motor → B | 2 |
| 2 | 12 → 48 | 0.8 | B → D | 4 |
| 3 | 12 → 48 | 0.8 | D → B | 4 |
| 4 | 12 → 48 | 0.8 | B → D | 4 |
| 5 | 12 → 36 | 1.0 | D → B | 3 |
| ring | 12 → 48 | 1.5 | B → wheel | 4 |
| handle | 6 → 4 | — | wheel → handle | ⅔ |

Every 12-tooth pinion is profile-shifted +0.3 against undercut, and its gear −0.3, so the
centre distances stay nominal: B–D is 24 mm and B–wheel is 45 mm.

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

Two bought boards do the work, soldered on headers to a 5 × 7 cm perfboard over the motor. Both
are modelled in `boards.sv` from their makers' drawings and stand on the perfboard's 0.1 in grid
in `radiatorbot.sv`.

| board | what it does | price | where |
|---|---|---|---|
| [Seeed XIAO ESP32-C3](https://www.seeedstudio.com/Seeed-XIAO-ESP32C3-p-5431.html) (SKU 113991054) | Wi-Fi/BLE, USB-C, four ADC pins | $4.99 | Seeed, Digi-Key, Mouser |
| [Pololu DRV8874 carrier](https://www.pololu.com/product/4035) (#4035) | H-bridge, 4.5–37 V, 2.1 A continuous, current output on CS | $11.94 | Pololu and its distributors |

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
- The DRV8874 senses current in the chip, with no shunt resistor. Its CS pin sources 450 µA/A
  into the carrier's 2.49 kΩ, about **1.1 V/A**.
  - The 130's ~1.8 A stall reads about 2.0 V. That is inside the C3's ADC range at 12 dB
    attenuation, about 0–2.5 V, which reads up to about 2.2 A.
  - Its chopping limit is VREF / 1.1 V/A. VREF is tied to SLEEP through 10 kΩ, so with SLEEP at
    3.3 V the limit is about 2.9 A, above stall. The hardware never cuts in before the
    firmware's trip does.
  - The same-sized DRV8876 carrier (#4036) is cheaper but gives 2.5 V/A, so a stall would
    saturate the ADC. Don't substitute it.
  - The Adafruit DRV8871 and TB6612 breakouts have no current output, so they would need an
    INA219 as well.

**Wiring**, all on the perfboard (the XIAO's pins are listed in `boards.sv`):

| XIAO | DRV8874 | |
|---|---|---|
| D1 (GPIO3, ADC1) | CS | the motor's current, 1.1 V/A |
| D3 (GPIO5) | EN/IN1 | PWM: speed |
| D4 (GPIO6) | PH/IN2 | direction |
| D5 (GPIO7) | SLEEP | high to run, low to sleep; VREF follows it |
| D10 (GPIO10) | FAULT | open-drain: the XIAO's internal pull-up |
| GND | GND, PMODE | **PMODE tied to GND** selects PH/EN mode. Left floating, the chip comes up as two independent half-bridges |
| 5V | VIN | the motor's supply, 5 V off USB; or the buck's 6 V, with the XIAO's 5V pin then fed through a diode |
| — | OUT1, OUT2 | the motor |

The thermostat's optocoupler goes to D2 (GPIO4, internal pull-up). Leave D0, D8 and D9 alone:
they are the C3's strapping pins. CS on D0, for one, would hold it low through the 2.49 kΩ at
boot.

**End of travel.** Drive until the CS reading crosses the trip current, held for some tens of
milliseconds so the start-up surge doesn't trip it, then stop.
- Set the trip with the valve in hand, well under stall (see *The drive*). The torque at the
  trip is what seats the valve.
- Ignore the first ~100 ms after each start: the inrush current is near stall.
- Sample with the ADC's 12 dB attenuation and average a few readings. The motor's PWM ripples
  the current.

**In the bay.**
- The XIAO stands at the board's −x end, in columns 0–6 and rows 9 and 15. Its USB-C overhangs
  the board's end and faces a window in the bay's end wall. The window is a USB-C cable's
  moulded plug (12.5 × 7 mm) plus the print clearance. The receptacle stands 14 mm in from the
  wall's outside face, so a plug's overmould reaches in through the window to mate.
- The driver stands in columns 17 and 22, rows 0–6, beside the buck module.
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
- The 48-tooth gears of stages 2–4 (D1, B2, D2) are spoked: five spokes between a hub round the
  pinion and a rim under the tooth roots, the windows' corners rounded. Stages 2 and 3 have
  2.4 mm spokes and rim; stage 4, which carries about 0.5 N·m at stall, has 3 mm. The smaller
  gears and the ring, which carry the most torque, stay solid.

Generate the STLs with `sh hardware/export.sh`. It's one `solventc` run that builds every part
once, and every gear of one size and face once, placed for each copy; `*.stl` is gitignored. Each
gear's teeth are the rack's exact sweep, built as one tooth sector turned round the gear; a spoked
gear is shaped whole and its windows cut after. Set `shaped := 0` in `radiatorbot.sv` to draw every
gear and the wheel as blanks while changing the layout.

## How it's checked

- `solventc hardware/radiatorbot.sv` solves the whole bot at DOF 0, follows `handle_turn` through
  a full turn, and judges the design table's claims (ratio, stall torque, free speed).
- The boards' fit in the bay is claimed in the model and judged on every check:
  - a mated USB plug clears the end wall's window by 0.3 mm;
  - the boards and their headers clear the frame and the cover;
  - the pins' tails under the perfboard clear the motor.
- The gears' clearances were judged with `claim … clear(…)` on a scratch copy. Every gear mesh
  runs with 0.14 mm between flanks. Every housing part clears the valve, except the contacts that
  are meant to be there (the motor on its lid, the base against the frame, the clamp on the pipe).
- The wheel against the handle was checked by intersecting the two at handle turns of 0°, 15°,
  30° and 45°: no overlap at any. A control, the wheel out of step by 15°, overlaps by 529 mm³.
- In Solvent v0.1.3, `clear` claims on the wheel come back undecided, and its pictures leave the
  wheel out (the field mesher can't mesh it). Its STL is built exactly, agrees with the field, and
  is a closed mesh.

## Bill of materials

- **Printed:** frame, base, clamp cap, cover, wheel (with ring), axle collar, motor pinion, and
  compounds B1, B2, B3, D1, D2.
- **Drill rod:** 8 mm × 67 mm (wheel axle); 5 mm × 46 mm, two of them (B and D).
- **Screws:**
  - M4 × 50, four, with nuts (clamp);
  - M3 × 10 self-tapping, eight (base to lid, cover);
  - M2.5 × 6, four (perfboard);
  - M3 set screw (collar).
- **Motor:** one 130 motor from the pile. Its pinion is a press fit on the 2 mm shaft.
- **Electronics, on a 5 × 7 cm perfboard** (no fabbed PCB); see *The electronics*:
  - a Seeed XIAO ESP32-C3 ($4.99), with two 7-pin 0.1 in male headers and its FPC antenna;
  - a Pololu DRV8874 carrier (#4035, $11.94), its headers included: the H-bridge, and its CS pin
    gives the motor's current, read by the XIAO's ADC for the end-of-travel sensing;
  - for 24 VAC off the thermostat transformer: a bridge rectifier and a buck module rated above
    40 V in and about 2.5 A out (rectified 24 VAC peaks near 34 V, beyond an MP1584's rating).
    On a 5 V USB supply instead, leave both out;
  - an optocoupler to read the thermostat's call for heat;
  - a 3-way 5.08 mm screw terminal.
- **Cable entries** are in the bay's end wall: a grommet hole for the thermostat and supply cable,
  and a window on the XIAO's USB-C.

## Assembly

1. Press the B and D rods into the base's floor and the 8 mm axle into the base's bridge.
2. Stack the compounds on the rods (B3, D2, B2, D1, B1) and fit the motor's pinion.
3. Close the base with the frame, putting the motor into its cradle, and fit the four M3 screws
   from inside the bay.
4. Solder the XIAO and the driver to the perfboard on their headers, the long ends down, at the
   grid places above, and cut the tails to 1.5 mm. Wire them as in the table, stick the XIAO's
   antenna under the cover, and screw the perfboard to its posts with the USB-C toward the end
   wall's window.
5. Slide the bot onto the valve from −x, so the inlet hex enters the clamp's pocket, and bolt on
   the cap.
6. Turn the handle so it's closed and **push the wheel up its axle from below** into mesh with
   both the handle and the last pinion. Fit the collar.
   - The star narrows downward and each of the wheel's bands is cut for the star's widest section
     at that band. So the wheel only ever gains clearance as it rises into place.
   - Going in sideways, by contrast, is not assured.

## Open questions

- **Stem travel.** The model assumes the handle as measured is closed, and that it drops 4 mm on
  opening (`stem_travel`). Measure it, closed to open. If the stem doesn't rise, set it to 0 and
  the bands are cut tighter.
- **The inlet hex's orientation** relative to the outlet. The model has a corner on ±x, so the
  bot can stand at multiples of 60° about the stem. Check it on the valve.
- **The thermostat's interface.** It's a 2-wire R/W dry contact, a 24 VAC R/W/C, or something
  else. That decides whether the bot can draw its power from the thermostat wiring.
- **The motors' figures.** See *The drive* above. The stall current also sets the trip, and
  whether a stall reads inside the ADC's ~2.2 A.
- **The boards' heights.** The XIAO's board thickness (taken as 1.2 mm) and the cable's plug
  (taken as 12.5 × 7 mm) are estimates. Check the plug of the cable you'll use against the window.
- **The ring and last pinion run open** under the base, beside the packing nut. A guard would be
  a small printed part.
