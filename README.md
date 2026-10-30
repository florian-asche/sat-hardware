# SAT-Hardware-Agent

One agent that controls the LEDs, buttons and sensors of voice-assistant satellite
hardware. A central controller loads a hardware plugin that matches the configured
device (FutureProofHomes Satellite1, ReSpeaker HATs, Jabra Speak 410, ...).

Status: work in progress. See [docs/plan.md](docs/plan.md).

## Documentation

- [docs/code-structure.md](docs/code-structure.md) – layout and where to change what
- [docs/architecture.md](docs/architecture.md) – components and data flow
- [docs/behavior.md](docs/behavior.md) – LED states, buttons, entities
- [docs/docker.md](docs/docker.md) – container image and compose
- [docs/api/](docs/api) – LVA, MQTT and Unix-socket interfaces
- [docs/plan.md](docs/plan.md) – roadmap

## Quick start (Docker)

```
cp .env.example .env && mkdir -p config && sudo chown 1000:1000 config
docker compose up -d
```

See [docs/docker.md](docs/docker.md) (device groups, configuration, limitations).

## Development

```
python3.11 -m venv .venv && . .venv/bin/activate
pip install -e '.[daemon,dev]'   # needs build tools for spidev/evdev
pytest && ruff check src tests
```

## License

GPL-3.0, see [LICENSE](LICENSE), [NOTICE.md](NOTICE.md) and [docs/licensing.md](docs/licensing.md).
It is derived from the Satellite1-RPi-SDK (GPL-3.0) and linux-voice-assistant (Apache-2.0).
