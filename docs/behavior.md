# Behavior

Normative description of what the hardware does. **State: PR 1 = observed behavior of the
imported Satellite1 daemon** (24-pixel LED ring, derived from the code at SDK `b09092c`).
From PR 5 this file becomes the specification all device plugins must follow. Every PR that
changes visible behavior must change this file.

Pixel numbers refer to the 24-LED Satellite1 ring (0..23). `system color` is the configurable
base color (`led_ring.system_color`, set via config, MQTT or LVA light; default `(0, 90, 255)`; if not set in config, the last value set via MQTT/LVA/socket is restored from `/var/lib/satellite1/led-ring-color.json`).

## LED states

Presentations have a **priority**; the highest active one is shown, otherwise the persistent
**background frame** (set via MQTT/LVA/socket) is shown. Mute indicators are **overlays** drawn on
top of whatever is shown.

| Prio | State (trigger) | Pattern | Color |
|---|---|---|---|
| 20 | Line-out jack plugged in | Two symmetric pixels expand from LED 0 to LED 12, once | system color (or `workflows.jack-led.color`) |
| 20 | Line-out jack unplugged | Two symmetric pixels contract from LED 12 to LED 0, once | same |
| 20 | Volume changed (any source) | Proportional bar over the ring (level = 24 x volume, partial last pixel); volume 0 shows only LED 0 in muted color; shown for `workflows.volume.timeout` (default 1.5 s) | system color / red when 0 |
| 11 | LVA not connected to Home Assistant | "Twinkle" effect until connected | red `(255,0,0)` |
| 11 | `wake_word_detected` | Two opposite trailing blobs rotating, speed 0.5 | system color |
| 11 | `listening` | Same blobs, speed 1.0 | system color |
| 11 | `thinking` | Two opposite pixels (LED 2 and 14) pulsing | system color |
| 11 | `tts_speaking` | Blobs rotating in reverse, speed -1.0 | system color |
| 11 | `error` | Full-ring pulse, 10 cycles, once | red |
| 10 | Timer running | Arc of lit LEDs proportional to remaining time (ring x left/total), small moving brightness dip | system color |
| 10 | Timer ringing | Full-ring pulse until stopped | system color |
| overlay | Microphone muted | Pixels 0, 6, 12, 18 solid | `mic_muted_color` (default red) |
| overlay | Speaker/output muted | Pixels 2,3,4,8,9,10,14,15,16,20,21,22 solid | `speaker_muted_color` (default red) |
| background | Idle | Last background frame (solid color from MQTT/LVA light) or off | configured |

Notes:
- Rotating blobs have a bright head with two fading trail pixels; mic positions (0, 6, 12, 18)
  are capped to brightness 128 so they stay distinguishable from the mute overlay.
- When the pipeline returns to `idle`, the pipeline presentation stops and lower layers show again.

## Buttons

| Button | Source | Event | Action |
|---|---|---|---|
| Volume up | XMOS | `ButtonPressed(volume_up)` | Active output volume + `step` (default 0.05); unmutes if muted |
| Volume down | XMOS | `ButtonPressed(volume_down)` | Volume - `step`; at 0 the output is muted |
| Action | GPIO BCM 7 (debounced) or XMOS (`buttons.action_source`) | `ButtonPressed(action)` | Forwarded to LVA, see below |
| Mic mute | XMOS switch | `MicMuteChanged(muted)` | Mutes/unmutes LVA microphone; mute overlay shown |

"Active output" is the line-out DAC when the jack is plugged in, otherwise the speaker.
There are **no long-press or double-press gestures** in the imported daemon, only single presses.

Action button -> LVA command, depending on the last LVA state:

| LVA state | Command sent |
|---|---|
| timer ringing | `stop_timer_ringing` |
| pipeline active (wake word, listening, thinking, speaking) | `stop_pipeline` |
| media player playing | `stop_media_player` |
| otherwise | `start_listening` |

Optional: `buttons.evdev.*` maps buttons to Linux `KEY_*` events via a uinput device.

## Audio and mute behavior

- Volume is kept per output (`line-out`, `speaker`) and restored from `/var/lib/satellite1/audio-state.json`
  if `restore_volume_on_startup` is enabled.
- Volume changes from LVA, buttons and Unix-socket calls all raise `VolumeChanged` and trigger the volume LED.
- LVA `volume_changed` / `volume_muted` events are applied to the active output; changes originating
  from LVA are not echoed back.

## MQTT / Home Assistant entities

Published via MQTT Discovery (details: [api/mqtt.md](api/mqtt.md)): sensors for temperature,
humidity, illuminance, power delivery contract and XMOS firmware; binary sensors for line-out
connected and microphone muted; event entities for the three buttons (`press`); a light for the LED ring.

## Sensors

AHT20 (temperature, humidity) and LTR303 (illuminance) are read periodically
(`mqtt.publish_interval`, default 60 s) and published **only over MQTT**.
