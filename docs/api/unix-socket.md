# Unix socket API

Local RPC and event stream for CLI tools and clients. Server: `sat_hardware_agent/adapters/unix_socket.py`;
typed client: `src/satellite1/client.py`; framing: `src/satellite1/_protocol.py`.

- Default path: `/run/satellite1/satellite1d.sock` (`--socket`), directory mode 0750
- Framing: **newline-delimited JSON**, max message size 64 KiB, protocol version `1`
- Request: `{"id": int|str, "method": "<name>", "params": {...}}`
- Success: `{"id": ..., "result": {...}}`; error: `{"id": ..., "error": {"code": "...", "message": "..."}}`
  (codes include `invalid_request`, `method_not_found`)

## Methods

| Method | Purpose |
|---|---|
| `hello` | Handshake: returns `service` (`satellite1d`), protocol version and capability list |
| `system.health` | `status` (`healthy`/`degraded`), `dac`, `xmos`, `led_ring` |
| `power.get_contract` | USB-PD voltage/current |
| `environment.get_readings` | temperature, humidity, illuminance |
| `dac.get_volume` / `dac.set_volume` / `dac.set_mute` | Output volume/mute; param `dac`: `line-out`, `speaker` or `auto` (default) |
| `dac.get_plugged_in` | Line-out jack state |
| `dac.get_amp_level` / `dac.set_amp_level` | Speaker amplifier gain (0..20) |
| `mics.get_muted` | Hardware mic-mute switch |
| `xmos.get_firmware` / `xmos.get_status` | XMOS version / status registers |
| `xmos.reset` | Reset the XMOS |
| `xmos.flash_firmware` | Flash firmware (`path`, optional `verify`) |
| `led.render` | Show a frame (`pixels`) or solid `color` |
| `led.clear` | Clear the background frame |
| `led.get_system_color` / `led.set_system_color` | System color |
| `events.subscribe` | Switch the connection to an event stream |

`led.*` methods exist only if the LED ring is enabled; the `hello` capability list reflects this.

## Events (after `events.subscribe`)

Format `{"event": "<name>", "data": {...}}`:
`buttons.pressed` (`name`), `mics.muted_changed`, `lva.mics.software_muted_changed`,
`lva.voice_pipeline.state_changed` (`state`), `lva.timer.changed`, `lva.connection_changed`,
`audio.volume_changed`, `audio.output_muted_changed`, `audio.speaker_muted_changed`,
`audio.line_out_jack_changed`, `xmos.availability_changed`.
