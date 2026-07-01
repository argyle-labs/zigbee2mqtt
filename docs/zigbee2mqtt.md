# Zigbee2MQTT

Zigbee coordinator and MQTT bridge. Translates Zigbee device messages to MQTT topics consumed by Home Assistant.

---

## Instance

| Field | Value |
|---|---|
| LXC ID | 107 |
| Host | <host> (<ip>) |
| IP | <ip> |
| OS | Alpine Linux |
| CPU | 1 core |
| RAM | 256 MB |
| Disk | 1 GB (local-lvm) |
| Unprivileged | yes |
| onboot | yes |
| USB passthrough | Zigbee dongle → `/dev/ttyUSB0` |
| Web UI | http://<ip>:8080 |

---

## USB Passthrough

The Zigbee USB dongle is passed through from <host> to LXC 107. The device appears as `/dev/ttyUSB0` inside the LXC.

In `/etc/pve/lxc/107.conf` on <host>:
```ini
lxc.cgroup2.devices.allow: c 188:* rwm
lxc.mount.entry: /dev/ttyUSB0 dev/ttyUSB0 none bind,optional,create=file
```

If the dongle is unplugged and replugged, restart the LXC:
```bash
pct stop 107 && pct start 107
```

---

## Service Management

```bash
pct enter 107   # on <host>

# Alpine — service managed via OpenRC
rc-service zigbee2mqtt status
rc-service zigbee2mqtt restart

# Logs
logfile is typically /opt/zigbee2mqtt/data/log/
```

---

## Configuration

Config at `/etc/zigbee2mqtt/configuration.yaml` inside the LXC.
`ZIGBEE2MQTT_DATA=/etc/zigbee2mqtt` is set by the OpenRC init script (`/etc/init.d/zigbee2mqtt`).

Key settings:
- MQTT broker: `mqtt://<ip>` (LXC 100)
- Serial port: `/dev/ttyUSB0`

---

## Persistent Storage

Config and device database are in `/etc/zigbee2mqtt/` inside the LXC. This path is bind-mounted from <host>'s local filesystem via `mp1` in `/etc/pve/lxc/107.conf`:

```
mp1: /var/lib/zigbee2mqtt,mp=/etc/zigbee2mqtt
```

Data lives on <host> (not <host>) so Zigbee stays operational if the NAS goes down. Survives LXC rebuilds — add `mp1` back to `107.conf` before starting a new LXC.

---

## Backup

Config and device database backed up nightly via `backup-configs.sh` from `/etc/zigbee2mqtt/`.

---

## Related

- [mqtt.md](mqtt.md)
- [home-assistant.md](home-assistant.md)
