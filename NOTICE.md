# Notice

SAT-Hardware-Agent is licensed under the **GNU General Public License v3.0**
(see [LICENSE](LICENSE)). It is a derivative work of the projects listed below.
Their copyright and license notices are preserved. Changes are recorded in the
git history of this repository.

## Upstream projects

### Satellite1-RPi-SDK (GPL-3.0)

- Source: https://github.com/FutureProofHomes/Satellite1-RPi-SDK
- Branch / commit reviewed: `develop` @ `b09092c21d48434c3cbc5b8a3fb4f82d1bf25eb1`
- Copyright: Mischa Siekmann / FutureProofHomes and contributors
- License: GNU GPL v3 (`LICENSE` of the upstream repository)
- Used for: the `satellite1d` daemon (MQTT, LVA adapter, LED, buttons, sensors,
  audio, XMOS access, maintenance), CLI, client library, Debian packaging.

### linux-voice-assistant (Apache-2.0)

- Source: https://github.com/OHF-Voice/linux-voice-assistant
- Branch / commit reviewed: `main` @ `5b980d0609e59a7baa0d3c8d05dde4c8698f3420`
- License: Apache License 2.0 (`LICENSE.md` of the upstream repository)
- Used for: packaging, CI and release layout, AI rules, device examples
  (Satellite1 HAT, ReSpeaker 2mic/4mic/USB, Jabra Speak 410, Peripheral web console).
- Apache-2.0 files keep their original license and notices when copied; the
  combined work is distributed under GPL-3.0.

Exact commit hashes of each import are also recorded in the commit messages of
the import pull requests.
