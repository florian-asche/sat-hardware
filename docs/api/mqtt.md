# MQTT API

Enabled with `[mqtt] enabled = true`. The agent connects as client (`host`, `port`, optional
`username`/`password_file`, `tls`) and publishes **Home Assistant MQTT Discovery** entities.
Implementation: `sat_hardware_agent/adapters/mqtt.py`.

- Base topic: `<topic_prefix>/<device_id>` (defaults: prefix `satellite1`, device id = hostname)
- Availability: `<base>/availability` = `online` / `offline` (retained, last will `offline`)
- Client id: `satellite1-<device_id>`; HA device identifier `satellite1_<device_id>`
- Discovery prefix: `homeassistant/<component>/<device_id>/<object>/config` (retained)

## Entities

| Entity | HA component | State topic | Notes |
|---|---|---|---|
| Temperature | sensor | `<base>/environment/temperature/state` | °C, AHT20 |
| Humidity | sensor | `<base>/environment/humidity/state` | %, AHT20 |
| Illuminance | sensor | `<base>/environment/illuminance/state` | lx, LTR303 |
| Power Delivery Contract | sensor (diagnostic) | `<base>/power/contract/state` | e.g. `5V @ 3A` |
| XMOS Firmware | sensor (diagnostic) | `<base>/xmos/firmware/state` | version string |
| Line-out connected | binary_sensor | `<base>/line_out/connected/state` | `ON`/`OFF` |
| Microphone muted | binary_sensor | `<base>/microphone/muted/state` | `ON`/`OFF`/`unavailable`, retained |
| Volume Up / Action / Volume Down Button | event | `<base>/buttons/<name>/event` | payload `{"event_type":"press"}` |
| LED Ring | light (JSON schema) | state `<base>/led_ring/state`, command `<base>/led_ring/set` | see below |

Sensor values are published every `publish_interval` (default 60 s).

## LED ring light

Command (`<base>/led_ring/set`), HA JSON light schema:
`{"state":"ON","color":{"r":0,"g":90,"b":255},"brightness":255}` or `{"state":"OFF"}`.
`ON` sets the solid background frame and (default) the system color used by all patterns;
`OFF` clears the background. State is reported on `<base>/led_ring/state` as
`{"state":"ON","color":{"r","g","b"},"brightness":<max channel>}`.
When MQTT is used for the LED ring, set `[lva] register_led_ring = false` to avoid a duplicate light.
