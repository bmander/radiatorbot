# radiatorbot

Hardware and software for automating a cast-iron radiator: turning its angle
valve under motor control.

[Open in Solvent IDE](https://bmander.github.io/geomsolver/?github=bmander/radiatorbot/blob/main/hardware/radiatorbot.sv)
— the `hardware/` models in the browser, opened on `radiatorbot.sv`, read from `main`.

## Layout

- `hardware/` — mechanical models, written in [Solvent](https://github.com/bmander/geomsolver).
  - `radiatorbot.sv` — the bot: a 130 motor and a printed spur train turning the valve's star
    handle through a socket round it, which the handle screws through as it opens. It also has the
    gearbox, an electronics bay with a SparkFun IoT RedBoard ESP32 and a perfboard shield carrying
    the motor driver and its current monitor, and a split clamp round the valve's inlet hex and
    supply pipe. `handle_open` scrubs the handle open, screwing down its stem, and the train with
    it.
  - `radiator_valve.sv` — the existing radiator angle valve as measured: body, supply pipe,
    union, bonnet, packing nut and star handle. It's a `RadiatorValve` component the bot draws;
    opened by itself, its `handle_open` scrubs the handle open, screwing it down the stem 2.06 mm
    a turn over three and a half turns, as measured.
  - `gears.sv` — printed spur gears, cut by a rack's exact generating sweep (true involutes,
    undercut where it would be), with FDM backlash, chamfered tips and optional spokes.
  - `motor130.sv` — the 130-size motor and its can's section, for the cradle that holds it.
  - `boards.sv` — the bought boards: a SparkFun IoT RedBoard ESP32, the perfboard shield plugged
    into it, and on the shield an Adafruit TB6612 motor driver (its two bridges tied together) and
    an Adafruit INA219 current monitor (which senses the stall), on their headers.
  - `DESIGN.md` — how the bot works, the drive's numbers, fits, bill of materials, assembly and
    open questions.
  - `export.sh` — writes every printed part as STL, and the whole bot as one STEP assembly.
- `firmware/` — the RedBoard's firmware, a PlatformIO project: it opens the valve while an
  old dry-contact thermostat calls for heat and closes it after, finding each end of travel by the
  motor's current, with a console on USB and on Wi-Fi (telnet), and a page for a phone to turn the
  heat on or off from anywhere, over Tailscale. See [firmware/README.md](firmware/README.md).

## Tooling: Solvent

The `.sv` files are Solvent documents, checked with `solventc`. Use the **prebuilt binaries**
from [bmander/geomsolver](https://github.com/bmander/geomsolver) rather than building from
source:

```sh
curl -fsSL https://raw.githubusercontent.com/bmander/geomsolver/main/scripts/install-solventc.sh | sh
```

This installs `solventc` to `~/.local/bin` (set `SOLVENTC_DIR` to change that, or
`SOLVENTC_VERSION` to pin a tag) and checks the download against the release's `SHA256SUMS`.
Linux and macOS (x86-64 and arm64) are covered by the script; for Windows, download the zip from
the [releases page](https://github.com/bmander/geomsolver/releases).

The language reference is the **Solvent primer**, `solvent-primer.md`. The installer leaves a copy
beside the binary (`~/.local/bin/solvent-primer.md`) matching the version you installed; it's also
in the repo at
[docs/solvent-primer.md](https://github.com/bmander/geomsolver/blob/main/docs/solvent-primer.md).

Check a model, and write the printed parts and the assembly:

```sh
solventc hardware/radiator_valve.sv
solventc hardware/radiatorbot.sv
solventc --no-check hardware/radiatorbot.sv   # the layout alone, its solids' claims unjudged
sh hardware/export.sh            # every printed part as STL, and radiatorbot.step, into hardware/stl
```

The models are checked with Solvent v0.1.10 (`SOLVENTC_VERSION=v0.1.10` pins the installer to
it), which solves the bot and judges its claims in about fifteen seconds, and exports it in about
two and a half minutes. The models use its lists (`repeat h in LIST`), read numbers off component
instances (`shield.top`), cut clearances as a part's body grown (`std.rounds.Grown`) and import
the standard library's words from its modules (`use std.place (coords)`, `use std.shapes`), so
they need v0.1.10 or later. Every gear is its rack's exact sweep; the
printed parts' STLs come to 4.0 MB and the assembly's STEP to 35 MB. v0.1.6 wrote the 16-tooth
pinions' straight tip edges as dense B-splines, doubling the STEP (bmander/geomsolver#644).

Every push that changes a model, or `export.sh`, runs `export.sh` in GitHub Actions
(`.github/workflows/export.yml`, Solvent pinned to v0.1.10 there too) and keeps its output on the
run's page: `radiatorbot-stl-<sha>`, a zip of the printed parts' STLs, and `radiatorbot-step-<sha>`,
the assembly. It can also be run by hand from the Actions tab.
