<p align="center">
  <img src="assets/icon-256.png" width="120" alt="zigbee2mqtt" />
</p>

# zigbee2mqtt

Zigbee2MQTT bridges Zigbee devices to MQTT, freeing them from proprietary hubs.

A first-party [orca](https://github.com/argyle-labs/orca) plugin (service-backend).

This repo is **self-contained** — the steps below run zigbee2mqtt **by hand, without orca**. orca automates exactly this (same image, ports, and data) through one generic surface.

---

## Run it without orca

### Docker / Podman

```yaml
# compose.yml
services:
  zigbee2mqtt:
    image: koenkk/zigbee2mqtt:latest
    container_name: zigbee2mqtt
    restart: unless-stopped
    ports:
      - "8080:8080/tcp"   # web UI
    volumes:
      - ./data:/app/data
      - /run/udev:/run/udev:ro   # (also map your Zigbee USB coordinator via devices:)
```

```sh
docker compose up -d
```

Podman: the same file with `podman-compose up -d`.

### Ports & data

| | |
|---|---|
| Default port | `8080` |
| Upstream | <https://www.zigbee2mqtt.io/> |
| Operator notes | [zigbee2mqtt.md](docs/zigbee2mqtt.md) |


### Backup & restore

Back up the config/data volume(s) above — that's the whole service state (stop the container first for a clean copy). Restore by putting them back and starting it.

> With orca this is **`service.backup` / `service.restore`** — location-agnostic (docker / podman / lxc / vm), one command regardless of where zigbee2mqtt runs. No per-service backup script.

## With orca

orca drives this plugin through the single generic `service.*` surface — no per-plugin tools:

```sh
orca service.deploy zigbee2mqtt      # render + launch on any supported runtime
orca service.status zigbee2mqtt      # health + rich diagnostics (typed payload)
orca service.backup zigbee2mqtt      # location-agnostic backup (tar; PBS on Proxmox)
orca service.configure zigbee2mqtt   # apply config via the upstream API
```

## Layout

- `src/` — the plugin (pure Rust): the `ServiceBackend` descriptor + `configure` / `status`.
- `docs/` — standalone operator notes.
- [CAPABILITIES.md](CAPABILITIES.md) — the service-backend contract checklist.
- `assets/` — plugin icon.
