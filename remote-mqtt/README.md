# Remote MQTT Component

Drives a Component that runs on its own board (e.g. a second Raspberry Pi) over MQTT,
instead of polling it over HTTP. The Component's `mender-mqtt-agent` holds one persistent,
outbound-only connection to a broker on the System Device; the `mqtt-component` Interface
pushes each state's command to it and blocks for the result. Neither board ever accepts an
inbound connection.

```
                     System Device (RPi #1)                                Component (RPi #2, ...)
┌───────────────────────────────────────────────────────┐   outbound        ┌───────────────────────┐
│ mender-orchestrator (unmodified)                        │◄─────────────────┤ mender-mqtt-agent      │
│   └─ calls interfaces/v1/mqtt-component per state        │                  │  (persistent session)  │
│                                                          │──publish cmd───► │  runs mender-update    │
│ mosquitto (standalone systemd service -- not part of    │◄─publish result─┤  (unmodified)          │
│  mender-orchestrator or mender-update)                  │                  └───────────────────────┘
│                                                          │                                           │
│ mqtt-component's Download state also starts a           │◄──HTTP GET (one-shot, per Download)────────┤
│ short-lived HTTP server, alive only for that one call   │                                           │
└───────────────────────────────────────────────────────┘
```

The broker is **plaintext, no authentication** -- appropriate for a trusted LAN, and it
avoids certificate management this example doesn't need.

Only `mqtt-component` ever talks to the broker on the System Device side -- there is no
separate control daemon. On the Component side, `mender-mqtt-agent` is the only thing that
talks to `mender-update`, using the same standalone CLI invocations
(`install`/`resume`/`commit`/`rollback --stop-before ...`) as the local `rootfs-image`
Interface; see that script for the state-by-state rationale.

## Layout

* `broker/mosquitto-orchestrator.conf` -- one plaintext, anonymous listener.
* `component-agent/` -- `mender-mqtt-agent`, its systemd unit, and a config example. Runs on
  each Component board.
* `../demo/mock-env/interfaces/v1/mqtt-component` -- the Interface itself. It lives
  alongside `esp32` and `rtos-interface` rather than the top-level `interfaces/v1/` (which
  is reserved for `rootfs-image`, the one officially-supported, dependency-free Interface):
  like `esp32`, this is real, runnable code, but example/unsupported and with an extra
  runtime dependency (`paho-mqtt`), so it's opt-in rather than installed on every
  orchestrator by default.

## Prerequisites

Both `mqtt-component` and `mender-mqtt-agent` need Python 3 and `paho-mqtt`
(`python3-paho-mqtt` on Debian-based images). The broker is `mosquitto`.

## Setup

### 1. System Device (RPi #1)

```
make install-mock-env-interfaces-v1-mqtt-component   # installs the Interface
make install-mqtt-broker                             # installs the plaintext mosquitto config
systemctl restart mosquitto
```

Add each Component to `/etc/mender-orchestrator/topology.yaml`:

```yaml
components:
  - component_type: gateway
    interface: mqtt-component
    interface_args: ["rpi2-component"]
```

`rpi2-component` here becomes the MQTT topic namespace for this Component, and must match
`MENDER_MQTT_COMPONENT_ID` in its agent config (step 2).

Set `MENDER_MQTT_INTERFACE_ARTIFACT_HOST` (e.g. in the orchestrator's own systemd unit
override, or wherever you manage its environment) to this System Device's own LAN IP or
hostname -- the address Components use to fetch Artifacts from the Interface's per-Download
HTTP server. There's no safe default the same way there is for the broker's own loopback
listener.

### 2. Each Component board (RPi #2, #3, ...)

```
make install-mqtt-component-agent
cp /etc/mender-mqtt-agent/mender-mqtt-agent.conf.example /etc/mender-mqtt-agent/mender-mqtt-agent.conf
# edit it: set MENDER_MQTT_COMPONENT_ID and MENDER_MQTT_BROKER_HOST
systemctl enable --now mender-mqtt-agent
```

Verify it connected, from RPi #1: `mosquitto_sub -h 127.0.0.1 -p 1883 -t
'mender-orchestrator/rpi2-component/status' -C 1` should print `online`.

### 3. Adding another Component later

Just repeat step 2 on the new board with its own `MENDER_MQTT_COMPONENT_ID`, and add it to
`topology.yaml`. There's no per-Component registration step in the plaintext setup -- any
Component that can reach the broker and knows its own ID can connect.
