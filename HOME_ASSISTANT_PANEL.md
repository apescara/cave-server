# Home Assistant server panel

The **Cave server** dashboard is installed in Home Assistant VM 201 at
`https://haos.dacave.org/server-control/overview`. It appears in the sidebar
for administrators. The checked-in source is
[`home-assistant/server-control.json`](home-assistant/server-control.json).

The dashboard uses Home Assistant's official Proxmox VE integration. It shows
the Proxmox host, running status for LXCs 100–107 and VM 201, CPU, memory,
root-disk usage, uptime, storage usage, and the most recent Proxmox guest
backup result. The integration polls every 60 seconds. Some disk and backup
entities were enabled manually because Home Assistant disables them by default.
The backup-health entity has the `problem` device class: `off` means healthy.

The integration connects to `192.168.100.17:8006` with the dedicated
`homeassistant@pve!monitor` API token. Its account has the propagated
`PVEAuditor` role, so the dashboard provides monitoring without guest power
actions. The Proxmox certificate uses the local Proxmox CA; SSL verification
is disabled in the integration until that CA is trusted by Home Assistant.
The token secret is stored by Home Assistant and is not in this repository.

The Links view opens Proxmox and Homarr on their local network addresses.
Homarr in LXC 104 remains a service launcher. Its Docker socket can only see
containers in LXC 104; it does not report Docker status in the other guests.
Image update notifications are still pending task 4. Manual update operations
are documented in [`UPDATE_IMAGES.md`](UPDATE_IMAGES.md).

## Restore or update the dashboard

Restore VM 201 from its Proxmox guest backup to recover the integration and
dashboard together. To update the panel, edit the JSON source, validate all
entity IDs against Home Assistant, then paste the JSON into the dashboard's
Raw configuration editor or save it through the Home Assistant Lovelace API.
Avoid overwriting the default Overview dashboard.

If the Proxmox token needs replacing, create a new token for
`homeassistant@pve`, update the integration credentials in Home Assistant, and
delete the old token in Proxmox. Keep the account's role at `PVEAuditor` unless
you intentionally want power controls in Home Assistant.
