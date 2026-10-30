# Architecture

## Current state (PR 1: imported daemon)

One asyncio process, `sat-hardware-agent`, owns the Satellite1 HAT hardware exclusively
(XMOS over SPI/GPIO, I2C DACs and sensors, action-button GPIO) and exposes it through
three adapters.

```
 Home Assistant ◀──MQTT──▶ ┌───────────────────────────┐
 LVA (voice assistant) ◀─WebSocket─▶ │  adapters: mqtt, lva, unix_socket │
 local CLI/clients ◀─Unix socket──▶ └──────────┬────────────────┘
                                     events │ ▲ commands
                          ┌──────────────────▼─┴──────────────────┐
                          │ EventHub  +  DaemonCommands             │
                          └───┬───────────────────────┬────────────┘
                 workflows (policy)                services (hardware)
        voice_pipeline_led, timer, mute_led,    led_ring, xmos, gpio, audio,
        volume_led, volume_buttons, jack_led    environment, power, device_info
                 │ uses led_patterns                       │
                 └──────────────▶ LedRingService ◀─────────┘
                                         │
                              satellite1_hw (HAL, components)
                              XMOS · PCM5122 · TAS2780 · AHT20 · LTR303 · USB-PD
```

### Data flow

1. **Hardware -> events:** `services/xmos` polls the XMOS (volume buttons, mic-mute switch,
   optionally the action button); `services/gpio` debounces the direct action button.
   Both publish `ButtonPressed` / `MicMuteChanged` on the `EventHub`.
2. **Events -> policy:** workflows and adapters subscribe to the hub. The LVA adapter turns
   events into LVA peripheral commands (e.g. action button -> `start_listening`) and turns
   LVA events into `VoicePipelineStateChanged`, `LvaTimerChanged`, `LvaConnectionChanged`, ...
3. **Policy -> LEDs:** workflows call `LedRingService.show_animation(...)` with a priority;
   the service renders the highest-priority presentation over the background frame and
   composites pixel overlays (mute indicators) on top.
4. **External control:** MQTT `led_ring/set` and the LVA `light_command` set the persistent
   background frame/system color; Unix-socket methods call `DaemonCommands`.

### Exclusive hardware ownership

A lock file (`--lock-file`, default `/run/satellite1/hardware.lock`, taken at startup) ensures only one daemon
accesses the XMOS/I2C hardware. This is why all Satellite1 functions (LED, buttons, audio,
update/flash) must live in the same process (see Target state).

### Lifecycle

`main.py` -> `Runtime.start()` starts power, environment, XMOS reset, XMOS service, LED ring,
workflows, action button, then the LVA and MQTT adapters (each only if enabled in
config). `Runtime.stop()` reverses this. The XMOS availability task starts the audio
services (DACs, mute LED, volume buttons) when the XMOS becomes available and stops them when it goes away.

## Target state (from PR 5)

```
 LVA ─┐                                 ┌─ I/O plugin: fph_sat1 (LED, buttons, sensors, audio)
 MQTT ┼─▶ Controller ◀─▶ Plugin API ◀───┼─ service plugin: fph_sat1_maintenance (update, reset, status)
 Sock ┘  (state machine,                ├─ I/O plugin: respeaker_2mic / 4mic / usb
          gestures, pattern engine)    └─ I/O plugin: jabra_speak_410
              └─ Pattern module (swappable, default = current LVA patterns)
      shared, serialized XMOS access ◀── both Satellite1 plugins
```

See [plan.md](plan.md) for the PR sequence. Details land in `api/plugin-api.md` and
`api/pattern-api.md` with PR 5.
