# radiatorbot

Hardware and software for automating a cast-iron radiator: turning its angle
valve under motor control.

## Layout

- `hardware/` — mechanical models, written in [Solvent](https://github.com/bmander/geomsolver).
  - `radiatorbot.sv` — the bot: a 130 motor and a five-stage printed spur train turning the
    valve's star handle through a wheel generated as the handle's conjugate. It also has the
    gearbox, an electronics bay with the ESP32 and the motor driver on perfboard, and a split clamp
    round the valve's inlet hex and supply pipe. `handle_turn` scrubs the handle and the train
    with it.
  - `radiator_valve.sv` — the existing radiator angle valve as measured: body, supply pipe,
    union, bonnet, packing nut and star handle. It's a `RadiatorValve` component the bot draws;
    opened by itself, its `handle_turn` scrubs the handle about the stem.
  - `gears.sv` — printed spur gears, cut by a rack's exact generating sweep (true involutes,
    undercut where it would be), with FDM backlash, chamfered tips and optional spokes.
  - `motor130.sv` — the 130-size motor and its can's section, for the cradle that holds it.
  - `boards.sv` — the bought boards on the perfboard: a Seeed XIAO ESP32-C3 and a Pololu DRV8874
    motor driver (whose current output senses the stall), on their headers.
  - `DESIGN.md` — how the bot works, the drive's numbers, fits, bill of materials, assembly and
    open questions.
  - `export.sh` — writes every printed part as STL.

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

Check a model, and write the printed parts:

```sh
solventc hardware/radiator_valve.sv
solventc hardware/radiatorbot.sv
sh hardware/export.sh            # every printed part as STL, into hardware/stl
```

The models are checked with Solvent v0.1.4 (`SOLVENTC_VERSION=v0.1.4` pins the installer to it).
The gears are cut by their exact rack sweeps, which v0.1.4 builds slowly; geomsolver's faster
swept-cut build (`make solventc` on its `main` once it lands, or a release after v0.1.4) exports
the whole bot in under a minute, its STLs smaller than the bites' were (4.2 MB against 8.4).
