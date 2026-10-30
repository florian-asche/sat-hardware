# LVA peripheral API (agent as client)

The agent connects as a **WebSocket client** to the Linux Voice Assistant peripheral API
(`[lva] url`, default `ws://127.0.0.1:6055`), reconnecting after `reconnect_delay` (3 s).
Over this interface the agent only handles **buttons, LED control, mute and volume state**;
sensors are never sent to LVA (use MQTT). Messages are JSON text frames.

Implementation: `sat_hardware_agent/adapters/lva/` (`adapter.py`, `protocol.py`).

## Commands sent to LVA

Format: `{"command": "<name>", "data": {...}}` (`data` optional).

| Command | Data | Sent when |
|---|---|---|
| `start_listening` | - | Action button, LVA idle |
| `stop_pipeline` | - | Action button, pipeline active |
| `stop_timer_ringing` | - | Action button, timer ringing |
| `stop_media_player` | - | Action button, media player playing |
| `mute_mic` / `unmute_mic` | - | Hardware mic-mute switch changed |
| `set_volume` | `{"volume": float 0..1}` | Hardware volume changed (not when the change came from LVA); acknowledged by a `volume_changed` event within 3 s |
| `register_light` | `{"name":"LED Ring","object_id":"led_ring","effects":[],"supports_rgb":true,"supports_brightness":true}` | On connect, if `[lva] register_led_ring = true` |

## Events received from LVA

Format: `{"event": "<name>", "data": {...}}`.

| Event | Data | Effect in the agent |
|---|---|---|
| `snapshot` | current state | Initial state sync (mute, volume, connection) |
| `wake_word_detected`, `listening`, `thinking`, `tts_speaking` | - | `VoicePipelineStateChanged` -> LED pattern, action-button context |
| `idle`, `tts_finished` | - | pipeline `idle` |
| `pipeline_error` | - | pipeline `error` (red pulse) |
| `timer_ticking`, `timer_updated`, `timer_ringing` | `id`, `name`, `total_seconds`, `seconds_left` | `LvaTimerChanged` -> timer LEDs |
| `media_player_playing` | - | action button context |
| `muted` | `{"muted": bool}` | LVA software mic mute -> mute overlay |
| `volume_changed` | `{"volume": float}` | Apply to active output (source `lva`) |
| `volume_muted` | `{"muted": bool}` | Mute/unmute active output |
| `zeroconf` | `{"status": "getting_started"\|"connected"}` | LVA connection state |
| `disconnected` / HA connection info | `{"ha_connected": bool}` | `LvaConnectionChanged` -> twinkle when false |
| `light_command` | `{"object_id":"led_ring","state":bool,"red","green","blue","brightness"}` (0..1 floats) | Sets system color and background frame |

Unknown events are ignored. Field names above come from the adapter code; the LVA repository
is the authority for the full protocol.
