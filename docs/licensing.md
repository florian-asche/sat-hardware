# Licensing

This is a technical summary, not legal advice.

## Result

The repository is distributed under **GPL-3.0** (`LICENSE`, copied verbatim from
the Satellite1-RPi-SDK).

## Why GPL-3.0

| Upstream | License | Consequence |
|---|---|---|
| Satellite1-RPi-SDK | GPL-3.0 | Derived works must be GPL-3.0. Source must be available to recipients of binaries and images. Copyright notices and change records stay. |
| linux-voice-assistant | Apache-2.0 | Apache-2.0 code may be included in a GPL-3.0 work (the reverse is not allowed). License text and notices stay. |

## "only" or "or later"?

The SDK ships the unmodified GPL-3.0 text, declares `license = { file = "LICENSE" }`
in `pyproject.toml`, and has **no per-file headers** and no "or any later version"
notice. We therefore treat the license as **GPL-3.0-only** and use
`GPL-3.0-only` as SPDX identifier for new files. (Per GPL section 14 a program
that names no version could be read as "any version"; we use the conservative
reading. Relaxing to "or later" would need confirmation from the upstream authors.)

## Audit of the upstream repositories

Reviewed at the commits listed in [NOTICE.md](../NOTICE.md).

- **SDK**: no SPDX/copyright headers in source files; one license for the whole tree.
  No firmware binaries are committed (firmware flashing takes a user-supplied path).
  Python dependencies (`smbus2`, `spidev`, `aiomqtt`, `evdev`, `gpiod`, `pydantic`,
  `websockets`) are used as unmodified libraries.
- **LVA**: Apache-2.0 for the code. `sounds/` has its own `LICENSE.md`, and
  `wakewords/` are separate model files. Neither is imported.
  Example dependencies (`apa102-pi`, `gpiozero`, `lgpio`, `rpi-ws281x`, `spidev`,
  `websockets`) must be checked when the matching plugin is added.
- **Images/videos** in the LVA examples (`image.png`, `demo.mp4`) have no separate
  license statement and are **not imported**; own screenshots can replace them.

## Rules for contributions

- New files carry `SPDX-License-Identifier: GPL-3.0-only`.
- Files copied from Apache-2.0 sources keep their original notices and are listed in `NOTICE.md`.
- Docker images must point to the source repository (OCI label `org.opencontainers.image.source`)
  so the GPL source offer is satisfied.
- Before adding a dependency or asset, check its license and note it here.
