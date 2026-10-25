# Radiator bot firmware

Firmware for the bot's Seeed XIAO ESP32-C3. It opens the valve while the thermostat calls for heat
and closes it when the call ends, and it finds each end of the stem's travel by the motor's
current, read off the DRV8874's CS pin (see `hardware/DESIGN.md`, *The electronics*). A console on
the USB-C port shows what it's doing and sets it up. It uses no Wi-Fi or Bluetooth.

## Layout

- `src/` — the ESP32 side: `main.cpp` (the control loop), `drv8874.cpp` (the H-bridge and the
  ADC), `console.cpp` (the serial console), `storage.cpp` (settings in flash), `pins.h`.
- `lib/valve/` — everything that doesn't touch hardware, tested on the host:
  - `controller` — the state machine that drives the valve to an end and knows where it is;
  - `trip_detector` — end of travel from the current: blanking, low-pass, trip and hold;
  - `thermostat` — the optocoupler's input, pulsing from 24 VAC or steady from DC, settled;
  - `settings` — the tunable figures and the table the console and the flash use.
- `host_test/` — those tests, against a simulated motor and valve.

## Building

With [PlatformIO](https://platformio.org) (`pip install platformio`):

```sh
pio run -d firmware                  # build
pio run -d firmware -t upload        # flash over the XIAO's USB-C
pio device monitor -d firmware       # the console, 115200 baud
make -C firmware/host_test           # the host tests (g++ or clang++)
```

The platform is [pioarduino](https://github.com/pioarduino/platform-espressif32)'s, for the Arduino
core 3.x, pinned to a release in `platformio.ini`. The C3's USB-JTAG resets it into the bootloader
itself, so flashing needs no buttons.

## What it does

- **Thermostat.** The optocoupler on D2 pulls the input low while it conducts. Off 24 VAC it
  conducts only on half-cycles, so the input counts as low if it was low in the last 60 ms. A
  state must then hold for `stat_settle` (3 s) before the bot acts on it. Calling for heat →
  open; not calling → closed. If your wiring has the optocoupler conduct when the thermostat is
  *satisfied*, `set stat_invert 1`.
- **A move.** The driver wakes; the ADC's offset is read with the motor braked; the duty ramps up
  over `ramp`. Past `blank` (the inrush is near stall), the current, low-passed over `filter`,
  must stay over the trip (`trip_open` or `trip_close`) for `hold` to mark the end. Then the
  motor brakes, the driver sleeps 50 ms later, and the bot knows which end it's at.
  - Optionally it runs back for `backoff_open` / `backoff_close` ms after an end, to ease the
    printed train. Both are off by default: backing off the closed end unseats the valve.
  - A change of mind during a move stops it; after `rest` the motor sets off the other way.
- **At power-up** the bot doesn't know where the valve is. Once the thermostat has settled it
  drives to the matching end; if the valve is there already, it stalls at once and trips.
- **Failures.** A move fails if it runs `timeout` (60 s) without tripping, or if the driver's
  FAULT pin goes low (overcurrent, overheating, undervoltage). The motor stops and the valve's
  position is unknown. The bot tries again after `retry` (15 min), up to 3 times in a row on its
  own; a change in the thermostat, or the console's `clear`, `open` or `close`, tries again at
  once.
- The loop runs about every millisecond under the loop watchdog. Console output never blocks it:
  with no host reading, output is dropped.

## The console

Plug in USB-C and open a terminal at 115200 baud. Every move is logged as it starts and ends:

```
thermostat: calling for heat
opening
open: reached in 23.4 s; running 0.42 A, peak 1.05 A, trip 1.00 A
```

| command | |
|---|---|
| `status` | the mode, the thermostat, the valve, the motor and the last move |
| `open`, `close` | drive to that end, ignoring the thermostat (manual mode) |
| `stop` | stop the motor and hold still (manual mode) |
| `auto` | follow the thermostat again; the bot always starts in auto |
| `clear` | forget a failed move and try again now |
| `get [name]` | list the settings, or one |
| `set name value` | change a setting at once; it's lost at reboot unless saved |
| `save` | keep the settings in flash |
| `defaults` | every setting back to its default (then `save` to keep them) |
| `trace ms` / `trace off` | print the current every `ms` during moves |
| `reboot` | |

## Settings

| name | default | |
|---|---|---|
| `trip_open` | 1.0 A | the current that marks the open end |
| `trip_close` | 1.0 A | the current that marks the closed end: it sets the torque that seats the valve |
| `hold` | 50 ms | how long the current must stay over the trip |
| `blank` | 150 ms | how long after a start the trip is ignored |
| `filter` | 10 ms | the current's low-pass time constant |
| `timeout` | 60 s | the longest a move may take |
| `duty` | 1.0 | the PWM duty on EN, 0.1–1 |
| `ramp` | 80 ms | the soft start |
| `backoff_open`, `backoff_close` | 0 ms | run back after reaching that end |
| `rest` | 500 ms | the motor's rest between moves |
| `retry` | 900 s | the wait after a failed move |
| `motor_invert` | 0 | swap the motor's directions |
| `stat_invert` | 0 | the optocoupler conducting means *no* call for heat |
| `stat_settle` | 3000 ms | how long the thermostat must hold a state |
| `cs_gain` | 1.1205 V/A | the DRV8874's current output: 450 µA/A into 2.49 kΩ |

## Setting it up on the valve

The trip defaults are placeholders. The design (`hardware/DESIGN.md`, *The drive*) says to set
them with the valve in hand, well under the stall.

1. **Direction.** With the bot on the valve, `stop` to hold, then turn the handle by hand to
   halfway. `open`, and watch the handle: if it turns toward closed, `stop`,
   `set motor_invert 1`, and try again.
2. **The running current.** `trace 100`, then `close` and `open` once each. Each move's log line
   gives its running current; the trace shows the current climb at the end as the stem stops.
3. **The trips.** Set each between the running current and the stall, low enough that the
   closing torque seats the valve without straining the train, e.g. `set trip_close 0.9`. Then
   close and open a few times and check each move ends `reached`, in about the same time.
   - If moves end early, mid-travel, the trip is too low for a stiff stretch of the stem.
   - If a stall reads near 2.2 A, it's at the top of the ADC's range: the trip must be under it.
4. **The thermostat.** `auto`, and turn the thermostat up and down. `status` shows its input
   and the settled state; if they're backwards, `set stat_invert 1`.
5. `save`.

## Assumptions to check

- The thermostat reaches D2 through the optocoupler, pulling it low while it conducts; whether
  that's a dry contact, 24 VAC R/W or something else is still open (`hardware/DESIGN.md`, *Open
  questions*). Either kind of drive reads correctly; only the sense may need `stat_invert`.
- Calling for heat means fully open and not calling means fully closed: no part-open positions.
- Which way PH turns the handle depends on the motor's leads, hence `motor_invert`.
