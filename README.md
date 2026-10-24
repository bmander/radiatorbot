# radiatorbot

Hardware and software for automating a cast-iron radiator: turning its angle
valve under motor control.

## Layout

- `hardware/` — mechanical models, written in [Solvent](https://github.com/bmander/geomsolver).
  - `radiator_valve.sv` — the existing radiator angle valve as measured: body, supply pipe,
    union, bonnet, packing nut and star handle, with `handle_turn` scrubbing the handle about
    the stem.

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

Check a model:

```sh
solventc hardware/radiator_valve.sv
```
