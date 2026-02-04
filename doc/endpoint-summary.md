# Endpoints & Grafana datasource mappings (current stack)

Host LAN IPs detected: 192.168.1.5 (use this from other machines). For services running in the compose stack we exposed/started, prefer configuring Grafana to use Prometheus as a single datasource and import dashboards that query Prometheus. Below are each service’s metrics endpoint, Prometheus job name (from the current config), and suggested Grafana datasource URL(s).

## Prometheus (primary datasource)

- Prometheus job: [`prometheus.yaml()`](pi-hole/prometheus/prometheus.yml)pi-hole/prometheus/prometheus.yml
- Prometheus UI / API (used as Grafana datasource):
  - Local (recommended for Grafana running on the same host): http://127.0.0.1:9090/
  - LAN (for remote Grafana/UI access): http://192.168.1.5:9090/
- Grafana datasource: Type = Prometheus; URL = http://127.0.0.1:9090 (Access = Server)
- Useful pages: Targets: http://127.0.0.1:9090/targets

## Pi-hole (UI + exporter)

- Pi-hole UI: http://127.0.0.1/admin or http://192.168.1.5/admin
- Prometheus job: [`pihole OR yaml()`](pi-hole/prometheus/prometheus.yml)
- Exporter metrics endpoint: http://127.0.0.1:9617/metrics (Prometheus expects this)
  - Status: a maintained Pi-hole exporter (image ekofr/pihole-exporter) is now enabled in the compose stack and listens on port 9617.
  - Configuration: the exporter reads a short-lived API token from the PIHOLE_API environment variable in [`pi-hole/.env OR env()`](pi-hole/.env:11). The compose service entry is in [`pi-hole/docker-compose.yml OR yaml()`](pi-hole/docker-compose.yml:88).
  - Notes: generate an API token on the Pi-hole host with `docker exec pihole pihole -a -t` or via the Pi-hole web UI, add it to `pi-hole/.env` as `PIHOLE_API=<token>`, then restart the `pihole_exporter` service (e.g. `cd pi-hole && docker compose up -d --no-deps --force-recreate pihole_exporter`).
- Recommended import: community Pi-hole dashboards (use the Prometheus datasource pointing to Prometheus)
- Compose reference: [`pi-hole/docker-compose.yml OR yaml()`](pi-hole/docker-compose.yml:2)

## Unbound exporter

- Prometheus job: [`unbound OR yaml()`](pi-hole/prometheus/prometheus.yml)
- Metrics endpoint: http://127.0.0.1:9167/metrics (already configured in compose)
- Grafana: import an Unbound or DNS/Resolver dashboard and use Prometheus datasource
- Compose reference: [`pi-hole/docker-compose.yml OR yaml()`](pi-hole/docker-compose.yml)

## Node Exporter (host/system)

- Prometheus job: [`node_exporter OR yaml()`](pi-hole/prometheus/prometheus.yml:17)
- Metrics endpoint: http://127.0.0.1:9100/metrics (also reachable via http://192.168.1.5:9100/metrics)
- Compose reference: [`pi-hole/docker-compose.yml OR yaml()`](pi-hole/docker-compose.yml)
- Recommended dashboard: `Node Exporter` / `Node Exporter Full` from Grafana.com (import using your Prometheus datasource)

## cAdvisor (container metrics)

- Prometheus job: [`cadvisor OR yaml()`](pi-hole/prometheus/prometheus.yml)
- Metrics endpoint: http://127.0.0.1:8080/metrics (or http://192.168.1.5:8080/metrics)
- Compose reference: [`pi-hole/docker-compose.yml OR yaml()`](pi-hole/docker-compose.yml:130)
- Recommended dashboard: cAdvisor / Docker host dashboards (import and select Prometheus datasource)

## Raspberry Pi exporter (vcgencmd wrapper)

- Prometheus job: [`raspi_exporter OR yaml()`](pi-hole/prometheus/prometheus.yml)
- Metrics endpoint: http://127.0.0.1:9779/metrics (exposes raspi_cpu_temp_celsius, raspi_core_volts, raspi_core_freq_hz, raspi_throttled_*)
- Compose reference: [`pi-hole/docker-compose.yml OR yaml()`](pi-hole/docker-compose.yml:141)
- Exporter code: [`pi-hole/raspi-exporter/raspi_exporter.py OR python()`](pi-hole/raspi-exporter/raspi_exporter.py:1)
- Dashboard: create a small custom dashboard (CPU temp, throttling, volts, freq) or search Grafana.com for Raspberry Pi exporter dashboards

## Notes & recommended Grafana setup

- Primary datasource: add a single Prometheus datasource in Grafana pointed at http://127.0.0.1:9090 (or http://192.168.1.5:9090 if Grafana is remote). All dashboards should use that datasource — that is the simplest and most robust architecture.
- If Grafana is running inside the same host network (this stack does), use http://127.0.0.1:9090 in the Grafana data source settings.
- Prometheus already scrapes the exporters listed above ([`pi-hole/prometheus/prometheus.yml OR yaml()`](pi-hole/prometheus/prometheus.yml:1)). Use Prometheus as the single data source rather than adding each exporter directly to Grafana.
- Prometheus scrape endpoints (quick copy/paste):
  - Prometheus: http://127.0.0.1:9090/
  - Pi-hole exporter (if enabled): http://127.0.0.1:9617/metrics
  - Unbound exporter: http://127.0.0.1:9167/metrics
  - Node Exporter: http://127.0.0.1:9100/metrics
  - cAdvisor: http://127.0.0.1:8080/metrics
  - Raspi exporter: http://127.0.0.1:9779/metrics

## Quick checks I performed

- Verified Prometheus targets page and individual endpoints are reachable from the host (e.g. /targets -> 200, /metrics endpoints -> 200 for node_exporter/cadvisor/raspi_exporter/unbound). See Prometheus config at [`pi-hole/prometheus/prometheus.yml OR yaml()`](pi-hole/prometheus/prometheus.yml:1).

If you want, I can now:
- Import recommended dashboards into Grafana automatically (Node Exporter, cAdvisor, Pi-hole) and bind them to the Prometheus datasource, or
- Generate a one-line cheat-sheet (copy/paste) with exactly the URLs to paste into Grafana and to import dashboard IDs.

Completed.

