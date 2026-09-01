# Delete Provisioned Dashboard

Deletes a dashboard that was provisioned from a file. Provisioned dashboards cannot be deleted
directly from the Grafana UI — you must remove the source file first.

## Usage

```bash
delete-dashboard <dashboard-file>
```

- `dashboard-file`: The relative path to the dashboard JSON file in `grafana/dashboards/`
  (e.g., `pihole/pihole-ui.json`)

## Description

1. Removes the dashboard JSON file from the provisioning folder
2. Commits the file removal
3. On the Pi, the provisioning system will unprovision the dashboard after restart,
   allowing deletion from the Grafana UI

## Example

```bash
# Remove a dashboard from provisioning (run from repo root)
delete-dashboard pi-hole/grafana/dashboards/pihole/pihole-ui.json
```

After running, sync to Pi and restart Grafana:
```bash
git push origin main
ssh pi 'cd /home/pi-networking/repos/rasbpi-networking/pi-hole && git pull && docker compose restart grafana'
```
