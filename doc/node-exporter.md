# Node Exporter (host metrics)

`node_exporter` exposes host (Raspberry Pi) CPU, memory, disk, and network
metrics. It is part of the stack and is scraped by Prometheus.

## What runs

- Image: `prom/node-exporter:latest`
- Listens on `127.0.0.1:9100` (host networking, `pid: host`).
- Prometheus job `node_exporter` → `127.0.0.1:9100` in
  `pi-hole/prometheus/prometheus.yml`.
- Service definition in `pi-hole/docker-compose.yml`:

  ```yaml
  node_exporter:
    image: prom/node-exporter:latest
    network_mode: host
    pid: host
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

## Verify

```bash
curl -s http://127.0.0.1:9100/metrics | grep -E '^node_' | head
```

In Prometheus, the `node_exporter` target should be UP at
http://127.0.0.1:9090/targets.

## Grafana

Import "Node Exporter Full" (Grafana.com ID `1860`) and point it at the
Prometheus datasource.

## Security & resource notes

- Lightweight and safe for continuous run on a Pi.
- Bind to localhost (host networking) and firewall it — do not expose `:9100`
  publicly. Mounts are read-only.
- For Raspberry Pi board telemetry (temperature, throttling, voltage) use
  `raspi_exporter` (see `doc/adding-raspi-exporter.md`); `node_exporter` does not
  cover those.
