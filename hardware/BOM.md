# Radiator bot: bill of materials

Everything that goes into one bot, as modelled in `radiatorbot.sv` and described in `DESIGN.md`.
Quantities are for one bot. Sizes marked "~" are estimates in the model, worth checking on the
parts in hand. Prices are given only where the design has them.

## Printed parts

Twelve parts, each written as `hardware/stl/<file>.stl` by `sh hardware/export.sh`. Gears print
flat, face down, with a 0.4 mm nozzle at 0.12–0.16 mm layers (module 0.8 is the finest).

| # | file | part | what it is | material |
|---|---|---|---|---|
| 1 | `frame_part` | frame | the gearbox lid, the electronics bay, the spine and the clamp's fixed half, one print | PLA or PETG |
| 2 | `base` | base | the gearbox's floor and walls, and the bridge holding the wheel's axle | PLA or PETG |
| 3 | `cap_part` | clamp cap | the clamp's other half, bolted on from the radiator side | PETG or ASA |
| 4 | `cover_part` | cover | the electronics bay's lid | PLA or PETG |
| 5 | `wheel_part` | wheel | the 6-pocket wheel conjugate to the handle, with the 48-tooth module 1.5 ring on top | **PETG or ASA** |
| 6 | `collar_part` | axle collar | keeps the wheel on its axle from below; takes the M3 set screw | PETG or ASA |
| 7 | `motor_pinion` | motor pinion | 12 teeth, module 0.8; pressed on the motor's 2 mm shaft | PLA or PETG |
| 8 | `b1` | compound B1 | 24 T gear (stage 1) and 12 T pinion (stage 2), module 0.8; on rod B | PLA or PETG |
| 9 | `d1` | compound D1 | 48 T gear (stage 2, spoked, 2.4 mm) and 12 T pinion (stage 3), module 0.8; on rod D | PLA or PETG |
| 10 | `b2` | compound B2 | 48 T gear (stage 3, spoked, 2.4 mm) and 12 T pinion (stage 4), module 0.8; on rod B | PLA or PETG |
| 11 | `d2` | compound D2 | 48 T gear (stage 4, spoked, 3 mm), module 0.8, and 12 T pinion (stage 5), module 1; on rod D | **PETG or ASA** |
| 12 | `b3` | compound B3 | 36 T gear (stage 5), module 1, and 12 T pinion driving the ring, module 1.5; on rod B | **PETG or ASA** |

The wheel and stage 5 (D2's pinion, B3) carry the most torque and sit by a warm radiator: print
them in PETG or ASA, not PLA. The clamp sits on the supply pipe, the warmest place on the bot.

## Bought mechanical parts

| item | qty | size | use | notes |
|---|---|---|---|---|
| Drill rod (silver steel), 8 mm | 1 | 8 mm × 67 mm | the wheel's axle (A), pressed into the base's bridge and the lid | cut from stock; ground h6/h8 |
| Drill rod (silver steel), 5 mm | 2 | 5 mm × 46 mm | rods B and D, pressed into the base's floor and the lid | cut from stock |
| M4 bolt, socket or hex head | 4 | M4 × 50 | the clamp: cap to fixed half | see the note below on length |
| M4 hex nut | 4 | 7 mm AF, 3.2 mm thick | in the pockets in the clamp's fixed half | plain nuts; a nyloc won't fit the 4 mm pocket |
| M3 screw, self-tapping into plastic | 8 | M3 × 10, pan head | 4 base to lid (from inside the bay), 4 cover to bay | 2.5 mm pilots in the print |
| M2.5 screw, self-tapping into plastic | 4 | M2.5 × 6, pan head | the perfboard to its posts | 2.2 mm pilots in the print |
| M3 set screw | 1 | M3 × 6, cup point | the axle collar | the collar's wall is 3 mm; it self-taps the 2.5 mm hole |
| Rubber grommet | 1 | for an 8 mm hole, ~2.4 mm panel | the thermostat and supply cable's entry in the bay's end wall | |

## Motor

| item | qty | notes |
|---|---|---|
| 130-size brushed DC motor | 1 | from the pile (a hobby servo's, wound for 4.8–6 V). The model assumes ~12 000 rpm free, ~6 mN·m and ~1.8 A stall at 6 V (`motor130.sv`). Measure free speed and stall current at the supply voltage and put them in `motor130.sv`: the drive's claims and the current trip follow from them. |

## Electronics

All on a perfboard over the motor; no fabbed PCB. Wiring is in `DESIGN.md`, *The electronics*.

### Always fitted

| item | qty | part | price | where | notes |
|---|---|---|---|---|---|
| Microcontroller | 1 | [Seeed XIAO ESP32-C3](https://www.seeedstudio.com/Seeed-XIAO-ESP32C3-p-5431.html), SKU 113991054 | $4.99 | Seeed, Digi-Key, Mouser | comes with its FPC antenna on a U.FL lead; stick it under the cover |
| Male pin header, 0.1 in | 2 | 1 × 7 | | | for the XIAO, which no longer ships with headers (or buy Seeed's pre-soldered version) |
| Motor driver | 1 | [Pololu DRV8874 carrier](https://www.pololu.com/product/4035), #4035 | $11.94 | Pololu and its distributors | headers included. **Not** the DRV8876 (#4036): its 2.5 V/A current output saturates the ADC at stall |
| Perfboard | 1 | 5 × 7 cm, 0.1 in grid (24 × 18 holes) | | | the posts stand 66 × 46 mm apart; drill its corner holes out to 2.7 mm if they're smaller |
| Screw terminal | 1 | 3-way, 5.08 mm pitch | | | the supply's and thermostat's wires, by the grommet |
| Hookup wire | — | 24–26 AWG | | | the perfboard's wiring and the motor's leads |

Budget for the two boards: **$16.93**, before shipping.

### Power: one of these

| option | items |
|---|---|
| **5 V USB supply** | a USB-C cable and a 5 V USB power adapter, through the XIAO's USB-C. Nothing else fitted. |
| **24 VAC off the thermostat's transformer** | a bridge rectifier, ≥ 100 V, ≥ 2 A, through-hole (e.g. a DB-series or W04M), and a buck module rated **above 40 V in** and about **2.5 A out**, set to 6 V (rectified 24 VAC peaks near 34 V, beyond an MP1584's rating). Also a diode (e.g. a 1N5819 Schottky) to feed the XIAO's 5V pin from the buck. The model reserves 22 × 17 × 5 mm for the buck, an MP1584 module's size; most high-voltage modules are bigger, so check the one you pick fits the bay. |

### Thermostat input

| item | qty | notes |
|---|---|---|
| Optocoupler | 1 | reads the thermostat's call for heat into the XIAO's D2 (internal pull-up). Its type and input resistor depend on the thermostat's interface, an open question in `DESIGN.md`: an AC-input part (e.g. a PC814) for a 24 VAC call, or a PC817-type with a series resistor. A plain dry contact could go to D2 directly. |
| Resistor | 1 | the optocoupler's input resistor, sized for the thermostat's voltage |

## Consumables and tools

- Filament: PETG or ASA (wheel, D2, B3, clamp cap, collar), and PLA or PETG for the rest.
- Solder, flux, side cutters (the header tails are cut to 1.5 mm under the perfboard).
- A drill or reamer at 5 mm and 8 mm, to bring the rods' printed holes to a press fit.
- A hacksaw or cut-off wheel for the drill rod; deburr the ends.
- Hex keys or a driver for the M4 bolts, the M3 set screw and the screws.
- A USB-C cable to program the XIAO, whatever the power option.

## Notes

- **The M4 bolts' length.** With the clamp's 26 mm halves and a 4 mm-deep nut pocket, an M4 × 50
  reaches only 2–3 mm into a 3.2 mm nut once the split closes. An M4 × 55 engages the whole nut
  and stands 2–3 mm proud of the fixed half's back face, clear of the spine. Check on the print.
- **Not in the model:** the reservoir capacitor after the bridge rectifier, if the buck module
  doesn't carry enough input capacitance of its own (e.g. 100 µF, ≥ 63 V), and the optocoupler's
  parts. Both wait on the thermostat's interface.
- **The ring and the last pinion run open** under the base. A guard would be one more printed
  part (see `DESIGN.md`, *Open questions*).
