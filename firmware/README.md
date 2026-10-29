# Radiator bot firmware

Firmware for the bot's SparkFun IoT RedBoard ESP32. It opens the valve while the thermostat calls
for heat and closes it when the call ends, and it finds each end of the stem's travel by the
motor's current, read off the INA219 in the TB6612's supply (see `hardware/DESIGN.md`, *The
electronics*). A console on the USB-C port shows what it's doing and sets it up. On Wi-Fi the same
console is on telnet's port, and a page for a phone turns the heat on or off, at home or, over
Tailscale, from anywhere.

## Layout

- `src/` — the ESP32 side: `main.cpp` (the control task and the loop), `tb6612.cpp` (the
  H-bridge and the motor's current), `ina219.cpp` (the current monitor, over I2C), `console.cpp`
  (the console and the log), `port.cpp` (the console's buffered side of a serial link),
  `storage.cpp` (settings in flash), `wlan.cpp` (the network, kept in flash), `remote.cpp` (the
  telnet console and the web page), `pins.h`.
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
pio run -d firmware -t upload        # flash over the RedBoard's USB-C
pio device monitor -d firmware       # the console, 115200 baud
make -C firmware/host_test           # the host tests (g++ or clang++)
```

The platform is [pioarduino's build of espressif32](https://github.com/pioarduino/platform-espressif32),
pinned to its release 55.03.312 in `platformio.ini`; it brings Espressif's Arduino core 3.3.12, on
ESP-IDF 5.5. PlatformIO's own espressif32 stops at the Arduino core 2.0.17, and pioarduino carries
it on: PlatformIO fetches it from its URL like any other platform, so nothing else needs
installing. The board is PlatformIO's `sparkfun_esp32_iot_redboard`.

The RedBoard's USB-C goes through a CH340C serial bridge, which resets the ESP32 into its
bootloader for an upload, so flashing needs no buttons. Linux and recent macOS have its driver
built in; Windows fetches it, or it's on [WCH's site](https://www.wch-ic.com/downloads/CH341SER_EXE.html).
If an upload ever can't connect, hold the board's GPIO0 button (the one that isn't RESET) as it
starts.

## Getting it on the network

Plug in USB-C, open the console (`pio device monitor -d firmware`), and give it your network:

```
wifi ssid My Home Network
wifi pass correct horse battery staple
```

Both are kept in flash, and the bot rejoins on every boot. It logs the link as it comes up:

```
wifi: on My Home Network as 192.168.1.50 (radiatorbot.local), -58 dBm
```

Give the bot a fixed address in your router (a DHCP reservation for its MAC), so the address you
bookmark stays its. The bot runs the valve whether or not it has a network, and a link lost for a
minute is started afresh.

- **The page:** `http://192.168.1.50/` (or `http://radiatorbot.local/` at home) on a phone or a
  computer. It shows where the valve is and why, the thermostat, the motor, the supply and the
  last move, refreshed every two seconds. Its buttons are **Heat on** (open), **Heat off**
  (close), **Thermostat** (back to auto) and **Stop**, and folded under them is the console, a
  line at a time.
- **The console:** `telnet 192.168.1.50` (or `nc 192.168.1.50 23`): the same commands and log as
  on USB. One client at a time; a new one takes it over.
- **What the buttons mean.** The thermostat is a contact, and the bot can't change its setting.
  What the bot can do is override it. **Heat on** opens the valve and holds it open whatever the
  thermostat says, and **Heat off** closes and holds it, until **Thermostat** hands the valve
  back. That's how you warm the room before you get home. A reboot hands it back too: the bot
  always starts in auto.

Neither the page nor the console asks for a password. Anyone who can reach the bot can run it,
so keep it on a network that's yours, and reach it from outside only through Tailscale, as
below; never forward a port to it. The page's commands are only taken with its own
`X-Radiatorbot` header, so another website open in a browser on your network can't send one. The
Wi-Fi password is kept in the ESP32's flash unencrypted.

### From anywhere, over Tailscale

There's no Tailscale client for a microcontroller, so the ESP32 can't join your tailnet itself.
Something always on at home that runs Tailscale (a Raspberry Pi, a NAS or a home server) routes
to it instead, as a [subnet router](https://tailscale.com/kb/1019/subnets):

1. On that machine (Linux), let it forward, and advertise a route to the bot's address alone:

   ```sh
   echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale.conf
   sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
   sudo tailscale set --advertise-routes=192.168.1.50/32
   ```

   A `/32` routes the bot and nothing else on your network; `192.168.1.0/24` would route all of
   it.
2. In the [admin console](https://login.tailscale.com/admin/machines), open that machine's
   *Edit route settings* and approve the route.
3. On the phone, with the Tailscale app connected, open `http://192.168.1.50/`. iOS and Android
   take approved routes as they are; a Linux client needs `tailscale set --accept-routes`.

Use the address, not `radiatorbot.local`: mDNS names don't cross the tailnet. If the phone's own
network uses the same addresses as your home's (a hotel's 192.168.1.x, say), the local one
wins; a home network on an unusual range, such as 192.168.47.x, avoids it. With
[ACLs](https://tailscale.com/kb/1018/acls), the route can be limited to your own devices.

## What it does

- **Thermostat.** Its contact goes between pin 4 (GPIO4) and ground, pin 4 pulled up to 3.3 V:
  closed reads low. A state must hold for `stat_settle` (3 s) before the bot acts on it, so a
  bounce as the mercury rolls, or a thermostat's chatter, doesn't run the motor. Closed (calling
  for heat) → open; open (not calling) → closed. If your thermostat's contact opens on a call,
  `set stat_invert 1`.
- **The drive.** The TB6612's two bridges are tied together as one. The direction is held on
  AIN1/AIN2 and the PWM input is driven at 20 kHz, low for the off-time, so the bridge brakes
  through it. The PWM is scaled to the supply the INA219 reads, so the motor sees `motor_volts`
  (9 V) on average at full `duty`, off a 9 V adapter or a 12 V one. Between moves STBY puts the
  driver to sleep.
- **The current.** The INA219 reads the supply's current, which under the PWM is about the PWM's
  fraction times the motor's. The firmware divides it back out, so every current the console
  shows, and the trips, are the motor's own: the bot's 130 stalls at about 1.2 A at 9 V whatever
  the adapter.
- **A move.** The driver wakes braked and the supply is read; the duty ramps up over `ramp`. Past
  `blank` (the inrush is near stall), the current, low-passed over `filter`, must stay over the
  trip (`trip_open` or `trip_close`) for `hold` to mark the end. Then the motor brakes, the driver
  sleeps 50 ms later, and the bot knows which end it's at.
  - Optionally it runs back for `backoff_open` / `backoff_close` ms after an end, to ease the
    printed train. Both are off by default: backing off the closed end unseats the valve.
  - A change of mind during a move stops it; after `rest` the motor sets off the other way.
- **At power-up** the bot doesn't know where the valve is. Once the thermostat has settled it
  drives to the matching end; if the valve is there already, it stalls at once and trips.
- **Failures.** A move fails if it runs `timeout` (60 s) without tripping, or on a motor fault:
  the supply under 6.5 V (the adapter unplugged, or sagging), over 13.5 V (more than the TB6612
  takes), or the INA219 not answering. The motor stops and the valve's position is unknown. The
  bot tries again after `retry` (15 min), up to 3 times in a row on its own; a change in the
  thermostat, or the console's `clear`, `open` or `close`, tries again at once.
- **The tasks.** The control loop runs every millisecond in a FreeRTOS task of its own, above
  the Arduino loop, under a 2 s watchdog. The Arduino loop runs the consoles, the Wi-Fi and the
  page, and may wait on a slow client as long as it likes: a move never waits on the network.
  Console output never blocks either: it waits in a 2 kB buffer while the other end catches up.
- Over USB alone the RedBoard and the console run, but the motor doesn't: every move is a motor
  fault until the wall adapter is plugged in.

## The console

Plug in USB-C and open a terminal at 115200 baud, or telnet to the bot. Every move is logged as it
starts and ends:

```
thermostat: calling for heat
opening
open: reached in 23.4 s; running 0.42 A, peak 1.05 A, trip 1.00 A
```

| command | |
|---|---|
| `status` | the mode, the thermostat, the valve, the motor, the supply, the last move and the Wi-Fi |
| `open`, `close` | drive to that end, ignoring the thermostat (manual mode) |
| `stop` | stop the motor and hold still (manual mode) |
| `auto` | follow the thermostat again; the bot always starts in auto |
| `clear` | forget a failed move and try again now |
| `get [name]` | list the settings, or one |
| `set name value` | change a setting at once; it's lost at reboot unless saved |
| `save` | keep the settings in flash |
| `defaults` | every setting back to its default (then `save` to keep them) |
| `trace ms` / `trace off` | print the current every `ms` during moves |
| `wifi` | how the link is doing: the network, the bot's address and the signal |
| `wifi ssid NAME` | join the network NAME, kept in flash (it may have spaces) |
| `wifi pass PASSWORD` | its password, kept in flash, and join it |
| `wifi forget` | leave the network and forget it |
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
| `motor_volts` | 9 V | the motor's voltage: the PWM gives it this on average at full `duty` |
| `ramp` | 80 ms | the soft start |
| `backoff_open`, `backoff_close` | 0 ms | run back after reaching that end |
| `rest` | 500 ms | the motor's rest between moves |
| `retry` | 900 s | the wait after a failed move |
| `motor_invert` | 0 | swap the motor's directions |
| `stat_invert` | 0 | the contact closed means *no* call for heat |
| `stat_settle` | 3000 ms | how long the thermostat must hold a state |

The trips take 2 A at most. The TB6612 has no current limit of its own, so a trip over the stall
would never trip, and the motor would stall on to the timeout.

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
   - A stall reads about 1.2 A. Nothing but the trip stops it, so keep the trips well under.
4. **The thermostat.** `auto`, and turn the thermostat up and down. `status` shows its contact
   and the settled state; if they're backwards, `set stat_invert 1`.
5. `save`.

## Assumptions to check

- The thermostat is a dry contact wired to the bot alone: an old two-wire heating thermostat,
  mercury switch or bimetal, taken off the wall or out of salvage. One still wired to a boiler's
  24 VAC mustn't reach pin 4 (`hardware/DESIGN.md`, *The thermostat*).
- Calling for heat means fully open and not calling means fully closed: no part-open positions.
- Which way the motor turns the handle depends on its leads, hence `motor_invert`.
- The motor current is worked out from the supply's, which holds while the motor's current runs on
  through the PWM's off-time. That's so at load and at the stall, where the trip is.
- The firmware has been compiled and run on the host against stand-ins for the ESP32's
  libraries, written to the Arduino core 3.3.12's headers, but not yet on a RedBoard. The first
  `pio run` and the first move on the bench are the real test.
