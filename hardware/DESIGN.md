# Radiator bot: mechanical design

A gearmotor that clamps to the radiator valve's supply pipe and turns the star handle. A 130 motor
drives a printed five-stage spur train, which drives a wheel conjugate to the handle. The motor's
current says when the stem reaches either end of its screw. An ESP32 on a perfboard reads the
thermostat and runs the motor.

Everything is FDM-printed except the drill rod the gears turn on and the screws. The model is
`radiatorbot.sv`. The valve it fits is `radiator_valve.sv`, and the parts libraries are
`gears.sv` and `motor130.sv`.

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

## Printing

The fits are an FDM printer's. They're set in one table at the top of `radiatorbot.sv`:

| fit | allowance |
|---|---|
| a gear's bore turning on drill rod | +0.35 mm |
| a rod pressed into the housing | +0.05 mm (drill or ream to fit) |
| printed faces that meet or pass | 0.3 mm |
| each gear's teeth, thinned on the pitch circle | 0.15 mm (0.3 mm backlash a mesh) |
| the wheel's pockets against the chrome handle | 0.6 mm backlash |
| walls | 2.4 mm (six 0.4 mm perimeters) |

- Gears print flat, face down. Module 0.8 is the finest stage; it wants a 0.4 mm nozzle and
  0.12–0.16 mm layers.
- Print the wheel, the ring and stage 5 in PETG or ASA rather than PLA. A radiator is warm, and
  those parts carry the torque.
- Each compound gear (a gear with its pinion) prints as one part.

Generate the STLs with `sh hardware/export.sh`. It's one `solventc` run that builds every part
once; `*.stl` is gitignored. Set `shaped := 0` in `radiatorbot.sv` to draw every gear and the
wheel as blanks while changing the layout.

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
- **Electronics, on a 5 × 7 cm perfboard** (no fabbed PCB):
  - an ESP32 dev board (the bay has room for a DevKitC; a XIAO ESP32-C3 leaves more);
  - a Pololu DRV8874 motor driver carrier: an H-bridge whose IPROPI pin outputs the motor current
    as a voltage, read by the ESP32's ADC for the end-of-travel sensing. An Adafruit DRV8871 or
    TB6612 breakout plus an INA219 current sensor does the same job with more parts;
  - for 24 VAC off the thermostat transformer: a bridge rectifier and a buck module rated above
    40 V in and about 2.5 A out (rectified 24 VAC peaks near 34 V, beyond an MP1584's rating).
    On a 5 V USB supply instead, leave both out;
  - an optocoupler to read the thermostat's call for heat;
  - a 3-way 5.08 mm screw terminal.
- **Cable entries** are in the bay's end wall: a grommet hole for the thermostat and supply cable,
  and a slot for the ESP32's USB.

## Assembly

1. Press the B and D rods into the base's floor and the 8 mm axle into the base's bridge.
2. Stack the compounds on the rods (B3, D2, B2, D1, B1) and fit the motor's pinion.
3. Close the base with the frame, putting the motor into its cradle, and fit the four M3 screws
   from inside the bay.
4. Slide the bot onto the valve from −x, so the inlet hex enters the clamp's pocket, and bolt on
   the cap.
5. Turn the handle so it's closed and **push the wheel up its axle from below** into mesh with
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
- **The motors' figures.** See *The drive* above.
- **The ring and last pinion run open** under the base, beside the packing nut. A guard would be
  a small printed part.
