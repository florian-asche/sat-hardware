# Changelog

All notable changes are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/). The released version is defined by the top entry of
`debian/changelog` (see [docs/release.md](docs/release.md)).

## [Unreleased]

### Added
- Import of the Satellite1-RPi-SDK daemon (MQTT, LVA adapter, LED ring, buttons, sensors, audio, XMOS access).
- Docker image that installs only the Debian package; `script/build-deb`.
- GitHub Actions: CI (lint, tests), package and image build (amd64, arm64), release with `.deb` attachments.
- Documentation: code structure, architecture, behavior, LVA/MQTT/Unix-socket API, Docker, licensing.

### Changed
- Python package `satellite1d` renamed to `sat_hardware_agent`; console script is `sat-hardware-agent`.
