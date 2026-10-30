# Code structure

State: **PR 1** (imported daemon, package renamed, otherwise unchanged from
Satellite1-RPi-SDK `b09092c`). The target structure with controller, plugins and
patterns is described in [architecture.md](architecture.md) and arrives in PR 5.
Update this file in every PR that moves, adds or removes modules.

## Repository layout

```
src/
  sat_hardware_agent/   the daemon (console script: sat-hardware-agent)
  satellite1_hw/        Satellite1 HAT hardware access (kept as-is, becomes a plugin later)
  satellite1/           typed async client for the daemon's Unix socket
  satellite1_cli/       CLI tools: sat1, sat1-dac, sat1-speaker, sat1-lineout, sat1-xmos
tests/                  pytest (daemon, client, CLI, components)
etc/satellite1.conf     default TOML configuration
udev/                   udev rules for HAT buttons
Dockerfile, docker-entrypoint.sh, docker-compose*.yml, .env.example
                        runtime image (only installs dist/*.deb) and compose files (docs/docker.md)
script/build-deb        builds the .deb into dist/ (CI and local); script/sat-hardware-agent-entrypoint ships in the .deb
.github/workflows/build.yml  build-deb -> docker image -> multi-arch manifest (GHCR)
debian/                 Debian package (systemd unit, postinst, wheelhouse build)
docker/, Makefile       .deb build in an arm64 container
examples/               small client examples (LED animations, event listener)
docs/                   documentation, see below
```

Renamed in PR 1: package `satellite1d` -> `sat_hardware_agent`, console script
`satellite1d` -> `sat-hardware-agent`. **Unchanged on purpose** (runtime identity,
unified later): systemd unit/user `satellite1d`, `/etc/satellite1.conf`,
`/run/satellite1/satellite1d.sock`, the wire-protocol service name `satellite1d`,
Debian package `satellite1-rpi-sdk`, and the `satellite1*` library packages.

## `sat_hardware_agent`

| Path | Responsibility |
|---|---|
| `main.py` | CLI entry point (`--config`, `--socket`, `--lock-file`, `-v`), logging, starts the runtime |
| `runtime.py` | Builds and starts/stops all services, workflows and adapters; XMOS reset and availability handling |
| `config.py`, `config_load.py` | Pydantic config models and TOML loading |
| `commands.py` | `DaemonCommands`: application commands (RPC methods) composed from services |
| `events.py` | `EventHub`: typed event fan-out to subscribers and sinks |
| `contracts/` | Typed protocols/dataclasses: events, LEDs, audio, environment, microphones, power, XMOS, lifecycle |
| `services/` | Hardware-facing services: `led_ring`, `xmos` (buttons, mic mute, LED transport), `gpio` (action button), `audio` (DACs), `environment`, `power`, `device_info` |
| `workflows/` | Policies reacting to events: `voice_pipeline_led`, `timer`, `mute_led`, `volume_led`, `volume_buttons`, `jack_led` |
| `led_patterns/` | Pure frame generators: `lva` (blob, thinking, pulse, twinkle, timer), `mute`, `volume`, `jack` |
| `adapters/` | External interfaces: `lva/` (WebSocket peripheral API), `mqtt.py`, `unix_socket.py` |
| `event_sinks/evdev.py` | Optional Linux input events for HAT buttons |

Dependency direction: `adapters`, `workflows` -> `contracts` <- `services` -> `satellite1_hw`.
Workflows and adapters talk to services only through `contracts` and the `EventHub`.

## `satellite1_hw`

`sat1_hat.py` (HAT facade), `audio_out.py`, `hal/` (gpio, i2c, sysfs) and
`components/` (AHT20, LTR303, PCM5122, TAS2780, USB-PD, XMOS control, flashrom wrapper).
Excluded from the repo's formatting/lint hooks (as upstream).

## Where do I change what?

| Goal | Place |
|---|---|
| Change how states look | `led_patterns/*` and the matching `workflows/*` (document in [behavior.md](behavior.md)) |
| New LVA event or command | `adapters/lva/` (document in [api/lva.md](api/lva.md)) |
| New MQTT entity | `adapters/mqtt.py` (document in [api/mqtt.md](api/mqtt.md)) |
| New socket method | `commands.py` + `adapters/unix_socket.py` (document in [api/unix-socket.md](api/unix-socket.md)) |
| New config option | `config.py`, `etc/satellite1.conf` |

## Tests

`pytest` from the repo root (`pip install -e '.[daemon,dev]'`; needs Python >= 3.11 and build
tools for `spidev`/`evdev`). `tests/test_sat_hardware_agent/` covers daemon modules.
Lint/format: `ruff check`, `ruff format` (config in `pyproject.toml`).
