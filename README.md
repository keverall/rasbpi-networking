# rasbpi-networking

A Docker-based Pi-hole stack for a Raspberry Pi 5 (arm64) plus a local
monitoring stack. It runs Pi-hole with a local recursive resolver (Unbound) and
Prometheus/Grafana/Loki monitoring on the Pi itself.

![alt text](doc/pi-hole.png)

## What this project provides

- A locally built **Pi-hole** image (Pi-hole server + pihole-FTL + web UI).
- An **Unbound** recursive resolver (compiled from source) for DNS privacy and
  performance, bound to `127.0.0.1:5335`.
- Exporters and monitoring:
  - `pihole_exporter` — Pi-hole metrics (port 9617)
  - `unbound_exporter` — Unbound metrics (port 9167)
  - `node_exporter` — host/system metrics (port 9100)
  - `raspi_exporter` — Raspberry Pi thermal/voltage metrics (port 9779)
  - `prometheus` — scrapes the exporters and stores metrics (port 9090)
  - `grafana` — dashboards (port 3000)
  - `alertmanager` — routes alerts from Prometheus (port 9093)
  - `loki` + `promtail` — log aggregation

> NOTE: `cAdvisor` and `Uptime Kuma` are **not** part of this stack. They were
> removed to reduce Pi CPU load; references to them in older notes are stale.

## Files of interest

- `pi-hole/Dockerfile` — Dockerfile for the Pi-hole image build.
- `pi-hole/Dockerfile.unbound` — Dockerfile that compiles Unbound from source.
- `pi-hole/docker-compose.yml` — the full compose stack (services, ports,
  volumes, env, resource limits).
- `pi-hole/.env.example` — example environment file; copy to `.env` and edit.
- `pi-hole/prometheus/prometheus.yml` — scrape targets.
- `pi-hole/prometheus/alert_rules.yml` — alert rules.

### Docs (`doc/`)

- `doc/endpoint-summary.md` — service endpoints, ports, and Prometheus mappings.
- `doc/monitoring-guide.md` — Prometheus/Alertmanager/Grafana and dashboards.
- `doc/docker-commands.md` — sanitized docker/compose commands and auth recipes.
- `doc/docker-update-commands.md` — update/rebuild/maintenance commands.
- `doc/pihole-auth-issues-fixes.md` — Pi-hole v6 API auth troubleshooting (curl).
- `doc/ftl-doc.md` — how the Pi-hole password is provided and API auth works.
- `doc/pihole-exporter.md` — the `pihole_exporter` service.
- `doc/node-exporter.md` — host metrics via `node_exporter`.
- `doc/adding-raspi-exporter.md` — history of adding `raspi_exporter`.
- `doc/unbound-permission-fixes.md` — Unbound logging/exporter fixes.
- `doc/sys time warning fix.md` — fixing the `CAP_SYS_TIME` warning.
- `doc/network-tools-guide.md` — LAN diagnostic tools (run from a desktop, not
  part of the Docker stack).

## Quick start (on the Pi)

1. Copy the example env file and edit values:

   ```bash
   cp pi-hole/.env.example pi-hole/.env
   # Edit pi-hole/.env: set TZ, WEBPASSWORD, SERVERIP
   ```

2. (Optional) Auto-detect `SERVERIP` for DHCP hosts:

   ```bash
   cd pi-hole && chmod +x generate-env.sh && ./generate-env.sh
   ```

3. Build and start the stack:

   ```bash
   cd pi-hole
   # Build local images (recommended on the Pi)
   docker compose build
   # Start everything
   docker compose up -d
   ```

4. Recreate only the `pihole` service after env changes:

   ```bash
   cd pi-hole && docker compose up -d --no-deps --force-recreate pihole
   ```

## Important environment variables

Set these in `pi-hole/.env` (copy from `pi-hole/.env.example`):

- `TZ` — container timezone (e.g. `Europe/London`).
- `WEBPASSWORD` — web/admin password. It is passed to the `pihole` service both
  as `WEBPASSWORD` and as `FTLCONF_webserver_api_password`, so the web UI and the
  FTL HTTP API share one password.
- `SERVERIP` — LAN IP of the Pi (e.g. `192.168.1.5`). Use `auto` and run
  `generate-env.sh` if the Pi gets a dynamic IP.

DNS upstreams (`DNS1`/`DNS2`) and the exporter password are configured directly
in `docker-compose.yml` (Unbound at `127.0.0.1#5335`), not via `.env`.

> The `PIHOLE_API` line that still appears in `.env.example` is **unused** by
> this stack — the `pihole_exporter` authenticates with `WEBPASSWORD` instead.

## Runtime overview — what runs and why

- `pihole` — Pi-hole web UI, pihole-FTL resolver and API (the DNS-blocking core).
- `unbound` — recursive resolver bound to `127.0.0.1:5335` (privacy; no external
  forwarders).
- `pihole_exporter` — scrapes the Pi-hole API, exposes metrics for Prometheus.
- `unbound_exporter` — exports Unbound metrics for Prometheus.
- `prometheus` — scrapes the exporters and stores metrics.
- `grafana` — dashboarding for Prometheus/Loki metrics and logs.
- `alertmanager` — receives alerts from Prometheus and routes notifications.
- `node_exporter`, `raspi_exporter` — host/board metrics for monitoring.
- `loki`, `promtail` — collect and store container and Unbound logs.

## Where data is persisted

- Pi-hole config/gravity: `pi-hole/etc-pihole`
- dnsmasq/Pi-hole DNS config: `pi-hole/etc-dnsmasq.d`
- Unbound config/logs: `pi-hole/unbound`, `pi-hole/unbound/var/log`
- Prometheus/Grafana/Alertmanager/Loki: `pi-hole/prometheus`, `pi-hole/grafana`,
  `pi-hole/alertmanager`, `pi-hole/loki`

## API authentication / common pitfalls

Pi-hole v6 API uses session IDs (`sid`) and CSRF tokens for cookie-based auth.
Common options:

- Use cookie + `X-CSRF-TOKEN`: authenticate via `/api/auth` to obtain a session
  cookie and CSRF token, then send the token in `X-CSRF-TOKEN` on subsequent
  requests. See `doc/pihole-auth-issues-fixes.md` for exact curl examples.
- Use header-based SID: include `X-FTL-SID: <sid>` (obtained from `/api/auth`)
  for scripted clients — avoids cookie/CSRF complexity.

If you see `401 Unauthorized` on actionable endpoints, ensure:

- You set `WEBPASSWORD` (and therefore `FTLCONF_webserver_api_password`) in
  `pi-hole/.env` — prefer the env variable over in-container changes.
- Host/cookie mismatch: Pi-hole sets the session cookie for a specific domain
  (e.g. `pi.hole`). When using curl or a reverse proxy, make the `Host` header
  and cookie domain match the configured `webserver.domain` (see
  `pi-hole/etc-pihole/pihole.toml`).

## Security notes

- This stack is for home/lab use. Do not expose the Pi-hole web UI or exporters
  to the public internet without a firewall / reverse-proxy auth.
- `pi-hole/.env` contains `WEBPASSWORD` and is git-ignored — never commit it.
- No secrets are stored in this repository. If you must handle tokens, read them
  from the env file at runtime and never paste them into docs or commands.

## Further reading & troubleshooting

- `doc/endpoint-summary.md`
- `doc/monitoring-guide.md`
- `doc/docker-commands.md`
- `doc/pihole-auth-issues-fixes.md`
- `doc/ftl-doc.md`
