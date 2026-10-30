# Docker

The agent runs as a container next to the Linux Voice Assistant. Image:
`ghcr.io/florian-asche/sat-hardware-agent` (published by CI from PR 3 on; until then build locally).
The Debian package (see `debian/`) remains available and uses the same configuration format.

> **Only one process may own the Satellite1 hardware (XMOS/I2C).** Stop the Debian service
> `satellite1d` before starting the container. The agent takes a lock (`hardware.lock`) and
> refuses to start if another owner exists.

## Quick start

```
cp .env.example .env            # set GPIO_GID / I2C_GID / SPI_GID
mkdir -p config && sudo chown 1000:1000 config   # writable for the container user (UID 1000)
docker compose up -d
docker compose logs -f
```

On first start the entrypoint writes the documented default configuration to
`./config/satellite1.conf`. Edit it (MQTT, LVA, workflows) and restart the container.

Build locally instead of pulling:

```
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

## Device access

The container runs as non-root user `satellite1d` (UID/GID 1000) and gets access through
supplementary groups matching the **host's** device groups. Find the numeric IDs with:

```
ls -ln /dev/gpiochip0 /dev/i2c-1 /dev/spidev0.0
```

and put them into `.env` (`GPIO_GID`, `I2C_GID`, `SPI_GID`). Devices passed through by default:
`/dev/gpiochip0`, `/dev/i2c-1`, `/dev/spidev0.0` (Satellite1 HAT). Enable I2C/SPI on the host
(`raspi-config`). For the optional evdev button mapping (`[buttons.evdev]`) also pass `/dev/uinput`
and load the `uinput` module on the host.

## Configuration and state

| Item | Container path | Compose |
|---|---|---|
| Config file | `/config/satellite1.conf` (`CONFIG_FILE`) | bind mount `./config` |
| Persistent state (volume, LED color) | `/var/lib/satellite1` | named volume |
| Control socket + hardware lock | `/run/satellite1` | named volume `sat-hardware-agent-run` |
| MQTT password | file inside `/config`, referenced by `mqtt.password_file` | bind mount |

Environment variables: `CONFIG_FILE`, `SOCKET_PATH`, `LOCK_FILE`, `LOG_VERBOSITY` (0/1/2).
LVA must be reachable at `[lva] url` (default `ws://127.0.0.1:6055`); the compose file uses
`network_mode: host` for that reason.

## CLI inside the container

```
docker compose exec sat-hardware-agent sat1 led --help
docker compose exec sat-hardware-agent sat1 environment
```

## Image contents

Multi-stage build on `python:3.13-slim-trixie`: dependencies are installed from `uv.lock`
(hash-checked), then the project. Runtime packages: `libgpiod3`, `flashrom`, `ca-certificates`.
Healthcheck: connect to the control socket. The image carries the OCI source label
(`org.opencontainers.image.source`) pointing to this repository, which is the GPL source offer.

## Limitations

- Built and smoke-tested on amd64 (starts, CLI works, fails cleanly without GPIO hardware). Running
  on a Raspberry Pi with a Satellite1 HAT is **not verified yet**; multi-arch (arm64) builds come with CI in PR 3.
- Firmware flashing from the container needs `flashrom` access to the same SPI device; untested.
