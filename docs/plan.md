# Plan: Multi-Device Satellite Hardware Daemon

Projektname: **SAT-Hardware-Agent**. Ziel: Den Daemon `satellite1d` aus `FutureProofHomes/Satellite1-RPi-SDK` (inkl. MQTT) herauslösen, als Docker-Image paketieren (analog zu `OHF-Voice/linux-voice-assistant`, kurz LVA) und zu einem Daemon ausbauen, der mehrere Hardware-Geräte (FPH Satellite1 + LVA-Examples) einheitlich steuert.

- Ziel-Repo: https://github.com/florian-asche/sat-hardware (leer, Default-Branch `main`)
- Lokaler Checkout: `/home/florian/repos/SAT-Hardware` (aktuell kein Git-Repo → wird zum Clone von oben)
- **Arbeitsweise:** Jeder Schritt = eigener Branch = eigener Pull Request (MR) gegen `main`. Kein Schritt baut auf ungemergtem Code auf; der nächste Schritt startet erst nach dem Merge des vorherigen.
- Dieses Dokument ist nur der Plan. Es wird noch nichts umgesetzt.

---

## 1. Lizenzen

| Quelle | Lizenz | Konsequenz |
|---|---|---|
| Satellite1-RPi-SDK | **GPL-3.0** | Abgeleitete Werke müssen unter GPL-3.0 (oder kompatibel) stehen, Quellcode muss verfügbar sein (bei Docker-Image-Verteilung: Quellcode-Angebot/Link im Image und README), Copyright-/Änderungsvermerke bleiben erhalten. |
| linux-voice-assistant | **Apache-2.0** | Darf in ein GPL-3.0-Projekt übernommen werden (Apache-2.0 ist GPLv3-kompatibel, nicht umgekehrt). Lizenztext, Copyright-Hinweise und „geändert"-Vermerke beibehalten; ggf. `NOTICE`-Inhalt übernehmen. |

**Folgerung:** Das neue Repo `sat-hardware` steht als Ganzes unter **GPL-3.0-or-later bzw. GPL-3.0** (richtet sich danach, ob der Upstream „only" oder „or later" schreibt – wird in Schritt 0 geprüft). Du darfst es verwenden, ändern, als Docker-Image veröffentlichen und auch eigene Teile ergänzen – aber nicht proprietär/closed-source weitergeben. Eigener Code von dir darf GPL sein; Apache-Teile behalten ihre Apache-Header.

Zu klären/prüfen in Schritt 0 (ich verlasse mich nicht auf die GitHub-Anzeige allein):
- Einzelne Dateien/Header im SDK mit abweichender Lizenz (z. B. Treiber `tas2780`, `pcm5122`, `flashrom_wrapper`, `xmos_*`, Firmware-Binaries).
- Abhängigkeiten mit eigener Lizenz (Python-Pakete, `libmpv` etc.) – nur relevant fürs Image, wird in `THIRD_PARTY_LICENSES.md` aufgelistet.
- Marken/Logos: Bilder (`image.png`, `demo.mp4`) in den LVA-Examples nur übernehmen, wenn Lizenz eindeutig; sonst weglassen.
- Hinweis: Das ist eine technische Einschätzung, keine Rechtsberatung.

---

## 2. Bestandsaufnahme Upstream (Stand heute)

**Satellite1-RPi-SDK** (Branch `develop`), Struktur:

- `src/satellite1d/` – der **Daemon**: `adapters/` (`mqtt.py`, `unix_socket.py`, `protocol.py`, `lva/`), `contracts/` (`leds`, `events`, `audio`, `environment`, `microphones`, `power`, `xmos`, `lifecycle`), `event_sinks/`, `config*.py`, `commands.py`
- `src/satellite1_hw/` – Hardware-Zugriff: `sat1_hat.py`, `hal/` (gpio, i2c, sysfs), `components/` (aht20, ltr303, dac/pcm5122, tas2780, power_delivery, xmos, flashrom)
- `src/satellite1/` – Client-Bibliothek (Protokoll zum Daemon)
- `src/satellite1_cli/` – CLI (led, environment, dac, xmos, sat1)
- `examples/` – `led_ring_animations.py`, `listen_events.py`
- Packaging/Betrieb: `debian/` (+ systemd-Service), `docker/` (Deb-Build), `udev/`, `etc/satellite1.conf`, `pyproject.toml`, `uv.lock`, `Makefile`, `tests/`

**linux-voice-assistant** (Branch `main`):

- Packaging/Projekt-Hygiene als Vorlage: `Dockerfile`, `docker-compose*.yml`, `docker-entrypoint.sh`, `.env.example`, `.github/` (CI/Release), `CHANGELOG.md`, `AGENTS.md`, `CLAUDE.md`, `.kilo/`, `docs/`, `tests/`, `version.txt`
- `examples/` (Geräte):
  1. Satellite1 HAT Board
  2. ReSpeaker 2mic HAT
  3. ReSpeaker 4mic HAT
  4. ReSpeaker Mic Array v2.0 (USB)
  5. Jabra Speak 410 (nur Audio/Taste, vermutlich keine RGB-LEDs)
  6. Peripheral web console (Browser-UI zum Testen der Peripherie-API)
- LVA-seitige Schnittstelle: `peripheral_api.py` (Peripherie-API, an die die Beispiele andocken)

---

## 3. Entscheidungen (von dir bestätigt)

| Thema | Entscheidung |
|---|---|
| Projekt-/Paketname | **SAT-Hardware-Agent** (Repo `sat-hardware`, Python-Paket `sat_hardware_agent`, Binary/Service `sat-hardware-agent`, Docker-Image `ghcr.io/florian-asche/sat-hardware-agent`) |
| Sprache | Englisch (Code, Docs, Commits, PRs); Chat mit dir bleibt Deutsch |
| PR-Fluss | Strikt nacheinander: ein PR, Merge, dann der nächste |
| Plan | Wird ins Repo eingecheckt (`docs/plan.md`), **als allererster Schritt** nach dem lokalen Checkout |
| Sensoren | Nicht über die LVA-API. LVA bekommt nur **Button-Input und LED-Steuerung**. Sensordaten laufen ausschließlich über **MQTT** (generischer Sensor-Layer, geräteabhängig per Config/Capabilities) |
| Peripheral web console | Wird mit übernommen, bleibt am Ende (PR 11) |
| Packaging | **Beides**: Debian-Packaging (.deb, systemd) bleibt erhalten **und** zusätzlich ein Docker-Image |
| Flash | Firmware-Flash bleibt wie im Upstream (keine zusätzliche Sperre per Config) |
| Doku pro Schritt | **Jeder PR pflegt die Doku mit**: Code-Aufbau (`docs/code-structure.md`), `docs/behavior.md` und API-Beschreibung (`docs/api/`). Ein PR ohne passende Doku-Änderung wird nicht gemergt (Checkliste im PR-Template, Regel in `AGENTS.md`) |
| Lizenz | Richtet sich nach dem Upstream-Header (Prüfung in PR 0) |
| Jabra Speak 410 | Wird als **Plugin/Gerätemodul** umgesetzt |
| Umfang Sat1 | **Keine Aufspaltung des Daemons.** Alles, was im Upstream-Daemon steckt (LED, Buttons, Sensoren, Audio, XMOS inkl. Flash/Update, Power, Device-Info, CLI), bleibt erhalten und wandert in Sat1-Plugins |
| Zwei Sat1-Plugins | (1) **I/O-Plugin** für LED + Buttons (+ Sensoren, Audio) und (2) **Maintenance-Plugin** für Update/Firmware/Reset/Status. Grund: Die XMOS-Schnittstelle kann nicht von zwei Programmen genutzt werden, also laufen beide Plugins im **selben Agent** und teilen sich einen gemeinsamen, serialisierten XMOS-Zugriff |
| LED-Muster | Wie die LEDs leuchten, ist im Controller in ein austauschbares **Pattern-/Theme-Modul** ausgelagert, damit später andere LED-Muster nutzbar sind |

---

## 4. Was steckt im Daemon? Zuordnung zu Controller und Plugins

Prinzip: **Nichts aus dem Upstream-Daemon wird weggelassen oder abgespalten** (auch das Debian-Packaging bleibt erhalten und wird zusätzlich zum Docker-Image gepflegt). Alles bleibt funktional erhalten und wird nur anders einsortiert: hardwareunabhängige Teile in den Controller, alles Sat1-spezifische in die Sat1-Plugins.

Wichtigste Erkenntnis aus dem Code: Beim Satellite1 laufen **LED-Ring und Action-Button über den XMOS-Chip** (`[led_ring] backend = "xmos"`, `[buttons] action_source = "gpio"|"xmos"`), ebenso Status, Reset und Firmware-Flash. Da nur ein Programm die XMOS-Schnittstelle nutzen kann, teilen sich beide Sat1-Plugins einen gemeinsamen XMOS-Zugriff im Agent.

| Bereich | Dateien (Upstream) | Ziel |
|---|---|---|
| Kern | `main`, `runtime`, `config`, `config_load`, `commands`, `events` | Core/Controller |
| MQTT | `adapters/mqtt.py` | Adapter (Controller) |
| LVA-Adapter | `adapters/lva/*` | Adapter (Controller); über LVA nur LED + Button |
| Unix-Socket | `adapters/unix_socket.py` | Adapter (Controller) |
| LED-Zustände/Workflows | `contracts/leds`, `workflows/*_led`, `voice_pipeline_led`, `timer` | **Controller** (Zustandslogik) |
| LED-Muster | `led_patterns/*` (lva, mute, volume, jack) | **Pattern-Modul im Controller**, austauschbar (Default = Upstream-Muster) |
| LED-Ring-Rendering | `services/led_ring` | Sat1-I/O-Plugin (Backend `xmos`) |
| Buttons | `services/gpio`, `event_sinks/evdev`, `workflows/volume_buttons`, `udev/…rules` | Sat1-I/O-Plugin (Gesten/Aktionen im Controller) |
| Sensoren | `services/environment`, `components/aht20`, `ltr303` | Sat1-I/O-Plugin; Ausgabe nur per MQTT |
| Audio | `services/audio`, `audio_out`, `components/dac`, `pcm5122`, `tas2780`, `contracts/audio`, `workflows/jack_led`, `volume_led` | Sat1-I/O-Plugin (Capability `audio`) |
| Mikrofon-Mute | `contracts/microphones` | Sat1-I/O-Plugin |
| XMOS-Zugriff | `services/xmos`, `components/xmos_device_cntrl` | **gemeinsamer XMOS-Zugriff im Agent** (von beiden Sat1-Plugins genutzt) |
| Update/Firmware | `components/flashrom_wrapper`, Flash-Teile in `contracts/xmos`, `cli_xmos` | **Sat1-Maintenance-Plugin** |
| Reset/Status/Flash-Mode | `contracts/xmos` (Status, Reset, Flash-Mode) | Maintenance-Plugin (steuert über den gemeinsamen XMOS-Zugriff) |
| Strom (USB-PD) | `services/power`, `components/power_delivery`, `contracts/power` | Maintenance-Plugin (Status per MQTT) |
| Geräteinfo | `services/device_info` | Maintenance-Plugin |
| Client-Lib | `src/satellite1/*` | umbenannt, Teil des Agents (Unix-Socket-Client) |
| CLI | `satellite1_cli/*` (led, environment, dac, xmos, sat1) | CLI des Agents; Subkommandos je nach geladenem Plugin |
| Packaging | `debian/` (inkl. systemd-Service, postinst/postrm), `docker/Dockerfile.deb.*`, `Makefile`, `udev/` | **bleibt**: .deb-Build (umbenannt auf `sat-hardware-agent`) **zusätzlich** zum Docker-Image |
| Doku/Beispiele | `examples/*` | Entwickler-Doku |
| Tests | `tests/*` | übernommen, passend zugeordnet |

Für LVA gilt (Examples): `Dockerfile`/`compose.yml`/`DOCS.md` pro Gerät und die **Peripheral web console** (`peripheral_web_console.html`) werden übernommen; Bilder/Videos nur bei eindeutiger Lizenz.

---

## 5. Pull-Request-Reihenfolge (strikt nacheinander)

Jeder Punkt = ein Branch = ein PR gegen `main`; Conventional-Commits-Titel; Doku passend zum Inhalt im selben PR. Nach jedem PR halte ich an, du reviewst/mergst, dann geht es weiter. Ich erstelle PRs nur nach deiner Freigabe.

**Schritt 0 (kein PR) – Checkout:** `git clone https://github.com/florian-asche/sat-hardware` nach `/home/florian/repos/SAT-Hardware` (dort liegt bisher nur `PLAN.md`; ich verschiebe sie in den Clone und lege sie als `docs/plan.md` ab). Upstream-Klone (SDK, LVA) nur im Scratch-Verzeichnis.

### PR 0 – Repo-Grundlage + Plan + Labels/PR-Template
`LICENSE` (GPL-3.0), `NOTICE.md` (Herkunft beider Upstreams mit URL + Commit-Hash), `docs/licensing.md` (Audit aus Abschnitt 1, inkl. Datei-Header-Prüfung), `.gitignore`, `README.md`, `docs/plan.md`. Zusätzlich (nach LVA-Vorbild): `.github/PULL_REQUEST_TEMPLATE.md` (Typ-Checkbox, Behavior-/Doku-Checkliste), `.github/workflows/pr-labels.yaml` (setzt das Label aus der angekreuzten Typ-Checkbox, schlägt fehl bei 0 oder >1 Häkchen), `.github/release.yml` (Release-Notes-Kategorien nach Label) und die dafür nötigen Repo-Labels.

### PR 1 – Daemon-Import (weitgehend unverändert)
Umfang: der komplette Upstream-Daemon laut Abschnitt 4 (inkl. Debian-Packaging), zuerst als reine Kopie (Upstream-Commit-Hash in der Commit-Message), danach minimale Anpassungen (Umbenennung auf `sat_hardware_agent`, Pfade/Config-Name). `pyproject.toml`, `uv.lock`, Tests. Docs: `docs/code-structure.md`, `docs/architecture.md` (Ist-Zustand), `docs/behavior.md` (Ist-Verhalten LEDs/Tasten/MQTT/LVA, aus dem Code abgeleitet), `docs/api/lva.md`, `docs/api/mqtt.md`, `docs/api/unix-socket.md`. Check: Tests laufen, Daemon startet im Mock-Modus.

### PR 2 – Docker-Image
`Dockerfile` (installiert nur das gebaute `.deb`, Non-Root), `script/build-deb`, Entrypoint im `.deb`, `.github/workflows/build.yml` (build-deb → docker → manifest), `docker-compose.yml`, `docker-compose.dev.yml`, `.env.example`, `.dockerignore`. Zugriff auf `/dev/gpiochip*`, `/dev/i2c-*`, `/dev/spidev*`, `/dev/input`, USB nach Bedarf. Config per Env/Volume. Das Debian-Packaging aus PR 1 bleibt daneben bestehen; beide Wege (Docker und .deb) nutzen dieselbe Config und dieselben udev-Regeln. Docs: `docs/docker.md`, `docs/debian.md`.

### PR 3 – CI, Release, Changelog
**GitHub Actions** (`build.yml` in PR 2 begonnen; PR 3 ergänzt Lint/Tests und Release): `build-deb` je Architektur (amd64 + native arm64) → Docker-Image, das nur das `.deb` installiert → Multi-Arch-Manifest in GHCR; Release bei Tag mit `.deb`-Artefakten, `CHANGELOG.md` (Keep a Changelog + SemVer), `version.txt`, `docs/release.md`. Voraussetzung: Packages-Schreibrechte im Repo (von dir freizuschalten).

### PR 4 – KI-Regeln & Entwicklungs-Workflow
`AGENTS.md`, `CLAUDE.md` (verweist auf AGENTS.md), `CONTRIBUTING.md`, PR-Template; Regeln: Struktur, Build/Test-Befehle, Stil, „Doku mitpflegen", `behavior.md` ist normativ, ein Thema pro PR, Lizenz-Header, **Doku-Pflicht je PR** (`code-structure.md`, `behavior.md`, `docs/api/`), PR-Template mit Doku-Checkliste (Template selbst kommt bereits in PR 0). Optional `.kilo/` falls gewünscht.

### PR 5 – Controller, Pattern-Modul + Plugin-System (Refactoring)
Zentrale Vorgabe: Es gibt **einen Controller**, der das gesamte Verhalten steuert. Je nach konfigurierter Hardware werden **Plugins geladen**, die der Controller steuert. Plugins enthalten keine Logik zu Zuständen oder Farben, nur Hardwarezugriff.

```
 LVA-API ─┐                                       ┌─ I/O-Plugin: fph_sat1 (LED, Buttons, Sensoren, Audio)
 MQTT ────┼─▶  Controller  ◀──▶  Plugin-API  ◀────┼─ Maintenance-Plugin: fph_sat1_maintenance (Update, Reset, Status, Power)
 Socket ──┘  (State-Machine,                      ├─ I/O-Plugin: respeaker_2mic / 4mic / usb
              Gesten, Pattern-Engine)             └─ I/O-Plugin: jabra_speak_410
                    │
                    └─ Pattern-Modul (austauschbar): "default" (Upstream-Muster), später weitere
                                        ▲
              gemeinsamer, serialisierter XMOS-Zugriff (Agent-Ressource) ◀── beide Sat1-Plugins
```

Aufgaben des **Controllers** (hardwareunabhängig, normativ in `behavior.md`):
- Lädt beim Start die in der Config gewählten Plugins (`device = "fph_sat1"`, optional `services = ["fph_sat1_maintenance"]`), prüft Capabilities und bricht bei ungültiger Config klar ab.
- Hält das Zustandsmodell (idle/listening/thinking/speaking/muted/error/timer/volume).
- Erkennt Tasten-Gesten (press/long/double) aus rohen Plugin-Events und leitet Aktionen ab (Wake/Stop, Mute, Lautstärke).
- Betreibt die Adapter (LVA, MQTT, Unix-Socket) und verteilt Events und Kommandos.
- Verwaltet den Plugin-Lifecycle (start, stop, Fehler, Neustart/Backoff).

**Pattern-Modul (ausgelagert aus dem Controller):**
- Schnittstelle: `Pattern.render(state, t, led_layout) -> Frame`. Der Controller liefert Zustand und Zeit, das Pattern liefert die Farben/Animation als logisches Bild auf einem virtuellen Ring.
- Das Upstream-Verhalten (`led_patterns/lva, mute, volume, jack`) wird als Pattern `default` übernommen und bleibt unverändert.
- Weitere Muster später als eigene Pattern-Pakete (Entry Points `sat_hardware_agent.patterns`), Auswahl per Config (`pattern = "default"`); Muster dürfen die normativen Zustände/Farbzuordnungen nur bewusst überschreiben (dokumentiert in `behavior.md`).

Aufgaben eines **Plugins**:
- Deklariert **Capabilities**: LED-Anzahl/-Layout, Tasten, Sensoren, optional Audio, Mic-Mute, Wartung (Update/Reset/Status).
- Setzt Pixel: Der Controller liefert das logische Bild, das Plugin mappt es auf die echte Hardware (z. B. 24 → 12 → 3 → 1 LED).
- Liefert rohe Button-Events und Sensorwerte (Sensoren nur über MQTT, nie über LVA).
- Plugins, die dieselbe Hardware teilen (beide Sat1-Plugins am XMOS), greifen **nur über die gemeinsame Agent-Ressource** zu. Diese serialisiert Transaktionen (asyncio-Lock), kennt einen **Wartungsmodus** (während Firmware-Flash pausiert der I/O-Zugriff, LEDs zeigen „Update läuft") und hält den Prozess-Lock (`flock` in `/run`) gegen einen zweiten Besitzer.

Plugin-API (Skizze, Details in PR 5):
```python
class HardwarePlugin(Protocol):
    capabilities: Capabilities
    async def start(self, ctx: PluginContext) -> None: ...   # ctx.resources["xmos"] u. a.
    async def stop(self) -> None: ...
    async def set_leds(self, frame: Frame) -> None: ...      # nur mit leds-Capability
    # Plugin meldet über ctx.emit(...): ButtonEvent, SensorReading, AudioChange, MaintenanceEvent
```
- Laden über Python **Entry Points** (`sat_hardware_agent.plugins`); eingebaute und externe Plugins funktionieren gleich (auch Jabra).
- Pro Plugin eigene Config-Sektion (`[plugin.fph_sat1]`, …) mit Schema, vom Controller validiert.
- Genau **ein I/O-Plugin** (LED/Buttons) ist aktiv; beliebig viele **Service-Plugins** (z. B. Maintenance) dürfen zusätzlich laufen.

Verzeichnisstruktur:
```
src/sat_hardware_agent/
  controller/   Controller, State-Machine, Gesten
  patterns/     Pattern-API + Pattern "default" (Upstream-Muster)
  core/         Lifecycle, Event-Bus, Config, Logging, shared resources (XMOS)
  adapters/     lva (nur LED + Button), mqtt (inkl. Sensoren + HA-Discovery), unix_socket
  plugins/
    api.py      HardwarePlugin, Capabilities, Frame, Events
    loader.py   Entry-Point-Loading, Capability-Check
    mock/       Referenz-Plugin für Tests
```
Docs: `docs/api/plugin-api.md`, `docs/api/pattern-api.md`, `code-structure.md`. `behavior.md` wird **normativ**; `architecture.md` auf Zielzustand (Controller/Plugin/Pattern-Diagramm, Event-Fluss, Lifecycle, Shared-XMOS). Gemeinsame Verhaltenstests laufen gegen jedes Plugin (zunächst Mock).

### PR 6 – Sat1 I/O-Plugin `fph_sat1`
Der Sat1-Code für LED-Ring (24 Pixel, XMOS-Backend), Buttons (GPIO/XMOS, evdev/udev), Sensoren AHT20/LTR303, Audio (DAC PCM5122, Amp TAS2780, Jack, Volume) und Mic-Mute als Plugin `plugins/fph_sat1/`. Verhalten unverändert (Regressionstest der LED-Frames). Der XMOS-Zugriff wird als gemeinsame Agent-Ressource (`core/resources/xmos`) angelegt, inkl. Lock. `docs/devices/fph-sat1.md`.

### PR 6b – Sat1 Maintenance-Plugin `fph_sat1_maintenance`
Update/Firmware-Flash (`flashrom_wrapper`), XMOS-Status/Reset/Flash-Mode, USB-PD-Info, Device-Info und zugehörige CLI-Kommandos und MQTT-/Socket-Kommandos. Nutzt dieselbe XMOS-Ressource wie das I/O-Plugin, damit nur ein Programm die Schnittstelle anspricht. Wartungsmodus-Handshake mit dem Controller (I/O pausiert, LEDs signalisieren „Update läuft", danach Neustart des I/O-Plugins). Docs: `docs/maintenance.md`. Flash-Verhalten wie im Upstream (explizites Kommando, optional Verify); zusätzlich nur der Wartungsmodus-Handshake mit dem Controller.

### PR 7–10 – ein Plugin pro PR (Reihenfolge nach Komplexität)
7. ReSpeaker 2mic HAT · 8. ReSpeaker 4mic HAT · 9. ReSpeaker Mic Array v2.0 (USB) · 10. **Jabra Speak 410 als Plugin** (eingeschränkte Capabilities, v. a. Tasten, evtl. keine RGB-LED).
Je PR: Treiber + Mapping, `docs/devices/<name>.md`, Compose-Beispiel, Tests gegen die gemeinsame Verhaltenssuite, Changelog-Eintrag. Gleiches Verhalten: gleiche Farben/Zustände; abweichende LED-Zahl/-Form über dokumentierte Mapping-Regeln (z. B. 24er-Ring → 12 → 3 → 1 LED); fehlende Tasten/LEDs über Capabilities übersprungen. Tasten: Hauptaktion (Wake/Stop), Mute, Lautstärke ± – soweit Hardware vorhanden. Sensoren pro Gerät per MQTT, sofern vorhanden.

### PR 11 – Peripheral web console
Übernahme von `peripheral_web_console.html` als Test-/Debug-UI gegen die Peripherie-/LVA-API (LED + Button), Docs `docs/web-console.md`. Hängt von der finalen LVA-Schnittstelle (PR 5) ab; Platzierung in der Reihenfolge ggf. früher, wenn du sie zum Testen der Geräte brauchst.

### PR 12 – Abschluss
Doku-Review, `CHANGELOG.md`, Release `v0.1.0`.

---

## 6. Dokumentation (von Anfang an, in jedem PR gepflegt)

**Regel:** Jeder PR ändert die Doku passend zum Code im selben PR. Die PR-Beschreibung nennt die geänderten Doku-Dateien; das PR-Template enthält die Checkliste (Code-Aufbau aktualisiert? Verhalten in `behavior.md`? API-Änderungen in `docs/api/`? Changelog?).

| Datei | Inhalt | Start |
|---|---|---|
| `README.md` | Überblick, Quickstart (Docker/.deb), Lizenz | PR 0 |
| `docs/plan.md`, `docs/licensing.md`, `NOTICE.md` | Plan, Herkunft & Lizenzen | PR 0 |
| `docs/code-structure.md` | **Aufbau des Codes**: Verzeichnisbaum, Modulverantwortlichkeiten, Abhängigkeitsrichtung, wo man was ändert/ergänzt (neues Plugin, neues Pattern, neuer Adapter) | PR 1 (Ist), laufend |
| `docs/architecture.md` | Komponenten, Controller/Plugin/Pattern-Diagramm, Datenfluss, Lifecycle, Shared-XMOS | PR 1 (Ist), PR 5 (Soll) |
| `docs/behavior.md` | Normativ: Zustände, Farben, Animationen, Tasten-Gesten/-Aktionen, Mapping auf kleinere LED-Ringe, MQTT-Entitäten | PR 1 (Ist), PR 5 (normativ), laufend |
| `docs/api/lva.md` | LVA-/Peripherie-API (nur LED + Button): Nachrichten, Felder, Beispiele | PR 1 |
| `docs/api/mqtt.md` | Topics, Payloads, HA-Discovery, Sensor-Entitäten | PR 1 |
| `docs/api/unix-socket.md` | Socket-Protokoll, Kommandos, Events, Client-Lib | PR 1 |
| `docs/api/plugin-api.md` | `HardwarePlugin`, Capabilities, Events, Shared Resources, Lifecycle, Plugin-Config | PR 5 |
| `docs/api/pattern-api.md` | `Pattern`-Schnittstelle, Frame-Format, Muster-Entry-Points | PR 5 |
| `docs/docker.md`, `docs/debian.md`, `docs/release.md` | Betrieb & Release | PR 2 / PR 3 |
| `docs/devices/*.md`, `docs/maintenance.md`, `docs/web-console.md` | Pro Plugin/Gerät, Update/Flash, Web console | ab PR 6 |
| `CHANGELOG.md` | Versionshistorie | ab PR 3 |
| `AGENTS.md` / `CLAUDE.md` | KI-Regeln (inkl. obige Doku-Regel) | PR 4 |

Doku-Lieferung je PR (Minimum):
- PR 0: Lizenz-/Herkunftsdoku, README.
- PR 1: `code-structure.md`, `architecture.md`, `behavior.md` (Ist), `api/lva.md`, `api/mqtt.md`, `api/unix-socket.md` – aus dem importierten Code abgeleitet.
- PR 2/3: Betrieb, Release, Env-/Config-Referenz.
- PR 4: Doku-Regeln in `AGENTS.md`/`CONTRIBUTING.md`/PR-Template.
- PR 5: `code-structure`, `architecture`, `behavior` (normativ), `api/plugin-api.md`, `api/pattern-api.md`; Anpassung der drei bestehenden API-Dokumente.
- PR 6/6b/7–10: je `docs/devices/<name>.md`, Aktualisierung von `code-structure.md`, `behavior.md` (Gerätemapping), ggf. API-Ergänzungen.
- PR 11: `docs/web-console.md`, Anpassung `api/lva.md`.
- PR 12: Gesamtreview aller Docs auf Konsistenz mit dem Code.

## 7. Technische Randbedingungen

- Push/PR-Erstellung per `gh`; Authentifizierung und Schreibrechte auf `florian-asche/sat-hardware` müssen bei dir vorhanden sein.
- Echte Hardware-Tests sind für mich nicht möglich; verifiziert wird mit Unit-Tests, Mock-Gerät und Container-Start. Hardwareprüfung bleibt bei dir.
- Upstream-Abweichungen (SDK `develop` kann sich ändern): Ich pinne den Commit-Hash in `NOTICE.md`.

## 8. Noch offen

Alle bisherigen Fragen sind entschieden. Neue Punkte ergeben sich ggf. in PR 0 (Lizenz-Audit) und PR 1 (Import).
