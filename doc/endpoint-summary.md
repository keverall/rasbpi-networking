# Endpoints & Prometheus mappings

Host LAN IP in this setup: `192.168.1.5`. Services use `network_mode: host`, so
all metrics endpoints are reachable on `127.0.0.1` from the Pi and on
`192.168.1.5` from the LAN. Prometheus (`pi-hole/prometheus/prometheus.yml`) is
the single datasource for Grafana.

## Prometheus (primary datasource)

- UI / API: http://127.0.0.1:9090/ (LAN: http://192.168.1.5:9090/)
- Targets: http://127.0.0.1:9090/targets
- Grafana datasource: type `Prometheus`, URL `http://127.0.0.1:9090`
  (Access = Server).

## Grafana

- UI: http://127.0.0.1:3000/ (LAN: http://192.168.1.5:3000/)
- Scrape job `grafana` at `127.0.0.1:3000` (Prometheus-side; Grafana itself is
  the datasource above, this job only tracks Grafana's health).

## Pi-hole (UI + exporter)

- Web UI: http://127.0.0.1/admin (LAN: http://192.168.1.5/admin)
- Exporter metrics: http://127.0.0.1:9617/metrics
- Prometheus job: `pihole` → `127.0.0.1:9617`
- Auth: the `pihole_exporter` logs in with `WEBPASSWORD` (see
  `doc/pihole-exporter.md`). It does **not** use the `PIHOLE_API` token.

## Unbound exporter

- Metrics: http://127.0.0.1:9167/metrics
- Prometheus job: `unbound` → `192.168.1.5:9167`
- Exports Unbound metrics (control port `8953`).

## Node Exporter (host/system)

- Metrics: http://127.0.0.1:9100/metrics (LAN: http://192.168.1.5:9100/metrics)
- Prometheus job: `node_exporter` → `127.0.0.1:9100`

## Raspberry Pi exporter (raspi_exporter)

- Metrics: http://127.0.0.1:9779/metrics
- Prometheus job: `raspi_exporter` → `127.0.0.1:9779`
- Exposes `raspi_cpu_temp_celsius`, `raspi_core_volts`, `raspi_core_freq_hz`,
  `raspi_throttled_*`.

## Scrape endpoints (quick reference)

| Job | Port | URL |
| --- | --- | --- |
| prometheus | 9090 | http://127.0.0.1:9090/ |
| pihole | 9617 | http://127.0.0.1:9617/metrics |
| unbound | 9167 | http://127.0.0.1:9167/metrics |
| node_exporter | 9100 | http://127.0.0.1:9100/metrics |
| raspi_exporter | 9779 | http://127.0.0.1:9779/metrics |
| grafana | 3000 | http://127.0.0.1:3000/ |
| cadvisor | 8080 | http://127.0.0.1:8080/metrics |

## Grafana setup

- Add one Prometheus datasource pointed at `http://127.0.0.1:9090` (or
  `http://192.168.1.5:9090` if Grafana is remote). All dashboards use it.
- Recommended dashboards (import via Grafana.com IDs):
  - Node Exporter Full — `1860`
  - Pi-hole — `9658`
  - Raspberry Pi metrics — search Grafana.com for a `raspi_exporter` dashboard, or
    build a small custom one (temp / throttling / volts / freq).

> `cAdvisor` **is** deployed in this stack (port 8080) and scraped by the
> `cadvisor` job, providing `container_*` metrics for the per-container panels.
