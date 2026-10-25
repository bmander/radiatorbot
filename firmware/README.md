# Radiator bot firmware

Firmware for the bot's Arduino Uno R4 Minima. It opens the valve while the thermostat calls for
heat and closes it when the call ends, and it finds each end of the stem's travel by the motor's
current, read off the INA219 in the DRV8871's supply (see `hardware/DESIGN.md`, *The
electronics*). A console on the USB-C port shows what it's doing and sets it up.

## Layout

- `src/` — the R4 side: `main.cpp` (the control loop), `drv8871.cpp` (the H-bridge and the
  motor's current), `ina219.cpp` (the current monitor, over I2C), `console.cpp` (the serial
  console and the log), `port.cpp` (the console's buffered side of the USB port), `storage.cpp`
  (settings in flash), `pins.h`.
- `lib/valve/` — everything that doesn't touch hardware, tested on the host:
  - `controller` — the state machine that drives the valve to an end and knows where it is;
  - `trip_detector` — end of travel from the current: blanking, low-pass, trip and hold;
  - `thermostat` — the thermostat's dry contact, settled;
  - `mode` — where the valve should go: the thermostat's say in auto, the console's in manual;
  - `settings` — the tunable figures and the table the console and the flash use.
- `host_test/` — those tests, against a simulated motor and valve.

## Building

With [PlatformIO](https://platformio.org) (`pip install platformio`):

```sh
pio run -d firmware                  # build
pio run -d firmware -t upload        # flash over the R4's USB-C
pio device monitor -d firmware       # the console, 115200 baud
make -C firmware/host_test           # the host tests (g++ or clang++)
```

The platform is PlatformIO's [renesas-ra](https://github.com/platformio/platform-renesas-ra),
pinned to a release in `platformio.ini`; it brings Arduino's core for the R4, 1.6. The upload
resets the R4 into its bootloader over USB, so flashing needs no buttons. If an upload ever can't
find the board, double-tap its reset button and try again.

## What it does

- **Thermostat.** Its contact goes between D2 and ground, D2 pulled up: closed reads low. A state
  must hold for `stat_settle` (3 s) before the bot acts on it, so a bounce as the mercury rolls,
  or a thermostat's chatter, doesn't run the motor. Closed (calling for heat) → open; open (not
  calling) → closed. If your thermostat's contact opens on a call, `set stat_invert 1`.
- **The drive.** The DRV8871's inputs are PWM'd at 20 kHz, one held high and the other pulled low
  for the on-time, so the bridge brakes through the off-time. The PWM is scaled to the supply
  the INA219 reads, so the motor sees `motor_volts` (6 V) on average at full `duty`, off a 9 V
  adapter or a 12 V one.
- **The current.** The INA219 reads the supply's current, which under the PWM is about the PWM's
  fraction times the motor's. The firmware divides it back out, so every current the console
  shows, and the trips, are the motor's own: a 130 stalls near 1.8 A at 6 V whatever the adapter.
- **A move.** The driver wakes braked and the supply is read; the duty ramps up over `ramp`. Past
  `blank` (the inrush is near stall), the current, low-passed over `filter`, must stay over the
  trip (`trip_open` or `trip_close`) for `hold` to mark the end. Then the motor brakes, the driver
  sleeps 50 ms later, and the bot knows which end it's at.
  - Optionally it runs back for `backoff_open` / `backoff_close` ms after an end, to ease the
    printed train. Both are off by default: backing off the closed end unseats the valve.
  - A change of mind during a move stops it; after `rest` the motor sets off the other way.
- **At power-up** the bot doesn't know where the valve is. Once the thermostat has settled it
  drives to the matching end; if the valve is there already, it stalls at once and trips.
- **Failures.** A move fails if it runs `timeout` (60 s) without tripping, or on a supply fault:
  the supply under 6.5 V (the adapter unplugged, or sagging below where the DRV8871 locks out),
  or the INA219 not answering. The motor stops and the valve's position is unknown. The bot tries again after `retry` (15 min), up to 3 times in a row on its
  own; a change in the thermostat, or the console's `clear`, `open` or `close`, tries again at
  once.
- The loop runs about every millisecond under a 2 s watchdog. Console output never blocks it: it
  waits in a 4 kB buffer while the host catches up, and with no host connected it's dropped.
- Over USB alone the R4 and the console run, but the motor doesn't: every move is a supply fault
  until the wall adapter is plugged in.

## The console

Plug in USB-C and open a terminal at 115200 baud. Every move is logged as it starts and ends:

```
thermostat: calling for heat
opening
open: reached in 23.4 s; running 0.42 A, peak 1.05 A, trip 1.00 A
```

| command | |
|---|---|
| `status` | the mode, the thermostat, the valve, the motor, the supply and the last move |
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
| `duty` | 1.0 | the motor's speed, 0.1–1 of `motor_volts` |
| `motor_volts` | 6 V | the motor's rating: the PWM gives it this on average at full `duty` |
| `ramp` | 80 ms | the soft start |
| `backoff_open`, `backoff_close` | 0 ms | run back after reaching that end |
| `rest` | 500 ms | the motor's rest between moves |
| `retry` | 900 s | the wait after a failed move |
| `motor_invert` | 0 | swap the motor's directions |
| `stat_invert` | 0 | the contact closed means *no* call for heat |
| `stat_settle` | 3000 ms | how long the thermostat must hold a state |

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
   - A stall reads about 1.8 A. The DRV8871 holds the current under about 2.1 A itself, so a
     trip over 2 A never trips.
4. **The thermostat.** `auto`, and turn the thermostat up and down. `status` shows its contact
   and the settled state; if they're backwards, `set stat_invert 1`.
5. `save`.

## Assumptions to check

- The thermostat is a dry contact wired to the bot alone: an old two-wire heating thermostat,
  mercury switch or bimetal, taken off the wall or out of salvage. One still wired to a boiler's
  24 VAC mustn't reach D2 (`hardware/DESIGN.md`, *The thermostat*).
- Calling for heat means fully open and not calling means fully closed: no part-open positions.
- Which way the motor turns the handle depends on its leads, hence `motor_invert`.
- The motor current is worked out from the supply's, which holds while the motor's current runs on
  through the PWM's off-time. That's so at load and at the stall, where the trip is.
