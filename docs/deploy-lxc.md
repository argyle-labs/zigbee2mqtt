# Zigbee2MQTT on a Proxmox LXC (native, USB coordinator passthrough)

A standalone deployment: Zigbee2MQTT running **natively** inside a small
**Alpine LXC** on Proxmox, bridging a USB Zigbee coordinator to MQTT. Nothing
here needs orca.

> Placeholders: `<proxmox-host>` = your Proxmox node, `<ip>` = a LAN address,
> `<pool>` = your ZFS/backup pool, `<mqtt-host>` = your Mosquitto broker. Pick
> the CT ID with `pvesh get /cluster/nextid` (shown as `<CTID>`).

- **Port**: 8080 (web UI / frontend)
- **Type**: Proxmox LXC — Alpine minimal
- **Footprint**: 1 core / 256 MB RAM / 1 GB disk
- **Hardware**: a USB Zigbee coordinator (Sonoff ZBDongle-E/P, ConBee II, etc.)
  physically attached to `<proxmox-host>` and passed through

---

## Step 1 — Identify the coordinator on the host

```bash
ls -l /dev/serial/by-id/          # find the dongle's stable path
```

Create a stable udev symlink on `<proxmox-host>` so the device survives reboots
and re-plugging (recommended over a bare `/dev/ttyUSB0`, which can renumber):

```bash
cat > /etc/udev/rules.d/99-zigbee.rules << 'EOF'
SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{serial}=="<serial>", SYMLINK+="zigbee"
EOF
udevadm control --reload && udevadm trigger
ls -l /dev/zigbee                 # should point at the dongle's tty
```

## Step 2 — Create the LXC + pass the device through

```bash
pveam available | grep alpine
pct create "$(pvesh get /cluster/nextid)" \
  local:vztmpl/alpine-3.20-default_20240606_amd64.tar.xz \
  --hostname zigbee2mqtt \
  --storage local-lvm \
  --rootfs local-lvm:1 \
  --cores 1 --memory 256 --swap 512 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --features nesting=1 \
  --ostype alpine \
  --onboot 1
```

Stop the CT and add the passthrough lines to `/etc/pve/lxc/<CTID>.conf` on
`<proxmox-host>` (full sample in
[`lxc/zigbee2mqtt.conf.example`](../lxc/zigbee2mqtt.conf.example)):

```ini
lxc.cgroup2.devices.allow: c 188:* rwm
lxc.cgroup2.devices.allow: c 189:* rwm
lxc.mount.entry: /dev/zigbee dev/ttyUSB0 none bind,optional,create=file
```

This binds the host's `/dev/zigbee` symlink to `/dev/ttyUSB0` inside the CT.

## Step 3 — Install Zigbee2MQTT

```bash
pct start <CTID>
pct enter <CTID>

ls -l /dev/ttyUSB0                # the coordinator must appear
apk add zigbee2mqtt               # or the community-scripts installer
```

## Step 4 — Configure

Edit `/etc/zigbee2mqtt/configuration.yaml` (kept on a bind mount, see below):

```yaml
mqtt:
  server: mqtt://<mqtt-host>:1883
  user: zigbee2mqtt
  password: <pass>
serial:
  port: /dev/ttyUSB0
frontend:
  port: 8080
```

Enable and start the service, then open **http://<ip>:8080** and permit joins to
pair devices.

## Step 5 — Persistence + backups

The config and device database live on bind mounts (`mp1: /etc/zigbee2mqtt`,
`mp0: /mnt/backups`). Back up `configuration.yaml`, `coordinator_backup.json`,
and the `database.db`:

```bash
tar czf /mnt/backups/z2m_$(date +%Y%m%d).tar.gz -C /etc/zigbee2mqtt .
```

## Troubleshooting

**`/dev/ttyUSB0` missing in the CT** — on the host: `grep -i mount
/etc/pve/lxc/<CTID>.conf` and confirm `/dev/zigbee` exists (`ls -l /dev/zigbee`).
The `optional` flag means a missing device silently skips the mount.

**Coordinator not responding** — only one process may hold the serial port;
make sure no other container/service (e.g. an old Z2M or HA add-on) has it open.

**Wrong adapter type** — set `serial.adapter` (`ember`, `zstack`, `deconz`) to
match your dongle.
