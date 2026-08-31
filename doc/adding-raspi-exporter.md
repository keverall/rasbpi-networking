# Added raspi_exporter

A minimal `raspi_exporter` (a `vcgencmd` wrapper) was added to the stack and
integrated with Prometheus/Grafana.

## What was added

- `raspi_exporter` service in `pi-hole/docker-compose.yml` (built from
  `pi-hole/raspi-exporter/Dockerfile`).
- Exporter code: `pi-hole/raspi-exporter/raspi_exporter.py`.
- A Prometheus scrape job `raspi_exporter` → `127.0.0.1:9779` in
  `pi-hole/prometheus/prometheus.yml`.

`node_exporter` was already present in the stack at the time (see
`doc/node-exporter.md`).

## How it works

`raspi_exporter` relies on the host's `vcgencmd` to expose CPU/GPU temperature,
voltage, frequency, and throttling flags (`raspi_cpu_temp_celsius`,
`raspi_core_volts`, `raspi_core_freq_hz`, `raspi_throttled_*`). If you run on a
Raspberry Pi and `vcgencmd` returns values on the host, the exporter exposes
them. If metrics are zero, check `vcgencmd` on the host first.

## Verify

```bash
curl -s http://127.0.0.1:9779/metrics | grep -E '^raspi_'
```

In Prometheus, the `raspi_exporter` target should be UP at
http://127.0.0.1:9090/targets.

## Note

`cAdvisor` **is** part of this stack (port 8080, scraped by the `cadvisor` job),
providing `container_*` metrics for the per-container CPU/memory panels. Host
metrics come from `node_exporter`; board metrics come from `raspi_exporter`.
