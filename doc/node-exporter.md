# Prometheus "node exporter

- [Prometheus "node exporter](#prometheus-node-exporter)
  - [Fix](#fix)
  - [Commands run](#commands-run)
  - [Next steps](#next-steps)
  - [Summary](#summary)
  - [Where to add it](#where-to-add-it)
    - [Notes on the snippet](#notes-on-the-snippet)
    - [Prometheus config to scrape node\_exporter](#prometheus-config-to-scrape-node_exporter)
  - [Useful alternatives / complements](#useful-alternatives--complements)
  - [Grafana dashboards](#grafana-dashboards)
  - [Security \& resource notes](#security--resource-notes)


The standard, lightweight option for host (Pi) CPU / memory / disk / network metrics and it integrates cleanly  existing Prometheus + Grafana + Pi‑hole stack.

## Fix

Prometheus Node Exporter added to compose.yml, updated Prometheus to scrape it, started the container, and verified metrics are 

- **available at 127.0.0.1:9100/metrics.**

Changes made (files & lines):

Added node_exporter service to pi-hole/docker-compose.yml OR yaml().
Added scrape job to pi-hole/prometheus/prometheus.yml OR yaml().

## Commands run

```bash
docker compose -f pi-hole/docker-compose.yml up -d node_exporter OR bash()
```

Verified with docker ps OR bash() and curl 127.0.0.1:9100/metrics OR bash()

Verification:

```docker ps``` shows the node_exporter container is up.

```bash
curl 127.0.0.1:9100/metrics returned Prometheus metrics (CPU, memory, filesystem, network, etc.).
```

## Next steps

Import a Node Exporter dashboard in Grafana (search "Node Exporter Full" on Grafana.com).
Add raspi-specific exporter if you want GPU/temp/throttling metrics beyond what node_exporter exposes by default.
Outcome: Node exporter is running and integrated with Prometheus for Grafana visualization.

## Summary

- Use Prometheus Node Exporter (official) for host/system metrics (CPU, mem, disk, per‑interface network bytes). It’s low overhead and scrapes easily from Prometheus.
- For Raspberry Pi‑specific telemetry (temperature, throttling, voltage) add a small Pi exporter or use node_exporter’s textfile collector / custom script.
- If you want richer, realtime UI and additional out‑of‑the‑box dashboards consider Netdata (more features, slightly higher resource usage).
- For container metrics add cAdvisor (containers) in addition to node_exporter (host).

## Where to add it

- Add a Node Exporter service to your Docker Compose file: [`pi-hole/docker-compose.yml`](pi-hole/docker-compose.yml:20).
- Tell Prometheus to scrape it by updating [`pi-hole/prometheus/prometheus.yml`](pi-hole/prometheus/prometheus.yml:1).

Recommended docker-compose service (works well on Raspberry Pi)
[`docker-compose OR yaml()`](pi-hole/docker-compose.yml:20)
- Add this service to your existing compose file (keeps metrics on host loopback; node_exporter needs host /proc and /sys access):

```bash
  node_exporter:
    image: prom/node-exporter:latest
    container_name: node_exporter
    network_mode: host
    pid: "host"
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - --path.procfs=/host/proc
      - --path.sysfs=/host/sys
      - --collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($|/)
```

### Notes on the snippet

- Using network_mode: host + pid: "host" + mounting /proc, /sys and rootfs is the usual way to let the exporter see host metrics from a container on Linux (and it’s what works reliably on RPi).
- If you prefer to avoid host networking you can expose port 9100 on loopback only (127.0.0.1:9100) but still mount the host fs/proc/sys — the host network approach is simpler and common.

### Prometheus config to scrape node_exporter

[`prometheus.yml OR yaml()`](pi-hole/prometheus/prometheus.yml:1)

```bash
- Add this job to the existing scrape_configs in your Prometheus config:

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['127.0.0.1:9100']
```

current file already scrapes Pi‑hole and Unbound — add node_exporter alongside them.

## Useful alternatives / complements

- Netdata (netdata/netdata): excellent realtime UI and many collectors; can be scraped by Prometheus or used standalone. Easier dashboards but higher resource cost than node_exporter.
- cAdvisor (gcr.io/cadvisor/cadvisor): container-level metrics for Grafana (container CPU/memory/IO).
- vnStat + vnstat-exporter: if you want long‑term per‑interface bandwidth accounting (node_exporter gives current bytes/sec counters but vnStat keeps persistent histories).
- Telegraf => InfluxDB => Grafana: alternative stack (more plugins, different datastore).
- Raspberry‑Pi specific exporters (e.g., raspi_exporter / vcgencmd wrappers): for CPU/GPU temp / throttling metrics if you need those exact metrics out of the box.

## Grafana dashboards

- Import community dashboards for "Node Exporter" (search Grafana.com for “Node Exporter Full” or “Node Exporter for Prometheus”). Also import Pi‑hole dashboards for the pihole exporter you already have.
- Netdata also supplies dashboards you can embed or scrape from.

## Security & resource notes

- Node exporter is lightweight (small CPU/memory), safe for continuous run on RPi.
- Don’t expose the exporter to the public internet — bind it to localhost or use host networking and firewall it; Prometheus already runs on host so scraping localhost:9100 is ideal.
- Mounts are read‑only in the snippet; keep it that way.

Quick commands (to run after you add the service)

[`docker compose -f pi-hole/docker-compose.yml up -d node_exporter OR bash()`](pi-hole/docker-compose.yml:20)

or (rebuild if you changed compose)

[`docker compose -f pi-hole/docker-compose.yml up -d --no-deps --build node_exporter OR bash()`](pi-hole/docker-compose.yml:20)

Integration with repo

- Prometheus is at [`pi-hole/prometheus/prometheus.yml`](pi-hole/prometheus/prometheus.yml:1) — add the scrape job above and reload Prometheus (or restart container).
