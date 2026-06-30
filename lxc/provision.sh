#!/usr/bin/env bash
# Creates and configures a zigbee2mqtt LXC on Proxmox VE. Run on the host as root.
set -euo pipefail
VMID="${1:?Usage: $0 <vmid> [options]}"
# TODO: pct create / config / install zigbee2mqtt. Mirror jellyfin/lxc/provision.sh.
echo "[provision] zigbee2mqtt LXC $VMID — not yet implemented"
