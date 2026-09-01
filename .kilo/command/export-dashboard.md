# Export Grafana Dashboard

Exports a dashboard from Grafana (by UID) and saves it to the repo's provisioning folder.

## Usage

```bash
export-dashboard <uid> [--output <filename>]
```

- `uid`: The Grafana dashboard UID (e.g., `unbound-ar51an-18077`)
- `--output`: Optional filename to save as (defaults to `<title>-<uid>.json`)

## Description

With `allowUiUpdates: true`, Grafana saves UI edits to the database only — the provisioning
JSON file in the repo is NOT updated automatically. This script fetches the current version
from the Grafana API and writes it to `pi-hole/grafana/dashboards/`, so you can commit the
updated dashboard to the repo.

Run from the Pi at `pi-hole/` directory:
```bash
cd pi-hole && scripts/export-dashboard.sh <uid>
```

## Examples

```bash
# Export dashboard by UID
export-dashboard unbound-ar51an-18077

# Export with custom filename
export-dashboard unbound-ar51an-18077 --output my-dashboard.json
```
