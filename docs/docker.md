# Docker

The agent runs as a container next to the Linux Voice Assistant. Image:
`ghcr.io/florian-asche/sat-hardware-agent` (pushed to GHCR by GitHub Actions; or build locally).
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

Build locally instead of pulling (see "Image contents and build"): run `script/build-deb`, then
`docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build`.

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

## Image contents and build

The image contains **only the Debian package**; the `Dockerfile` copies nothing but `dist/*.deb`.
Everything the container needs (venv wheelhouse, `sat-hardware-agent-entrypoint`, config template
`/etc/satellite1.conf`, udev rules) is shipped inside the package. So the container, the Raspberry
Pi install and the release artifact are the same thing.

Two steps, mirrored by the GitHub Actions workflow (`.github/workflows/build.yml`):

```
# 1. build the package for the local architecture into dist/ (runs in debian:trixie)
docker run --rm -v "$PWD":/src -w /src debian:trixie script/build-deb
# 2. install it into the runtime image
docker build -t sat-hardware-agent:local .
```

`debian:trixie-slim` base; `apt` resolves the package dependencies (`python3-venv`, `flashrom`,
`libgpiod3`); the package's postinst builds `/opt/satellite1/venv` from the wheelhouse and links
`sat-hardware-agent`, `sat1`, ... The service user `satellite1d` is created beforehand with
UID/GID 1000; systemd/udev steps of the postinst are skipped because they do not exist in the container.
Healthcheck: connect to the control socket. The OCI source label (`org.opencontainers.image.source`)
points to this repository, which is the GPL source offer.

## GitHub Actions workflow

`.github/workflows/build.yml` has three jobs: `build-deb` (matrix amd64 on `ubuntu-24.04`, arm64 on
the native `ubuntu-24.04-arm` runner, runs `script/build-deb` in `debian:trixie`, uploads
`deb-<arch>`), `image` (downloads the matching `.deb` into `dist/`, builds the image, smoke-tests
`sat-hardware-agent --help` / `sat1 --help`) and `manifest` (multi-arch tag). Images go to
`ghcr.io/<owner>/sat-hardware-agent` on pushes to `main` (tag `main`) and on `v*` tags (tag `vX.Y.Z`
and `latest`); pull requests build and test but do not push. No extra secrets: `GITHUB_TOKEN` with
`packages: write`.

## Limitations

- Built and smoke-tested on amd64 (package builds with `script/build-deb`, installs in the image, CLI works, fails cleanly without GPIO hardware). Running
  on a Raspberry Pi with a Satellite1 HAT is **not verified yet**; multi-arch (arm64) builds are done by the GitHub Actions workflow. The workflow has not run yet (only validated as YAML; its steps were reproduced locally); the repository may need Actions package permissions for GHCR.
- Firmware flashing from the container needs `flashrom` access to the same SPI device; untested.
