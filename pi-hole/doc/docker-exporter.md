# Docker Exporter

Replaces cAdvisor for Docker container metrics. Uses [`dlepaux/docker-exporter`](https://github.com/dlepaux/docker-exporter) on port 9713.

## Why docker-exporter instead of cAdvisor

- cAdvisor reports zero for `container_memory_working_set_bytes` on Raspberry Pi 5 (ARM64 + cgroup v2) — a known, upstream-unfixed bug.
- `docker-exporter` reads the Docker stats API directly and computes the working set correctly on both cgroup v1 and v2.
- ~9 MB image, ~7 MiB RAM, < 1% CPU.
- Read-only Docker socket, non-root, no privileged mode needed.
- Metric names are cAdvisor-compatible, so existing Grafana dashboards work unchanged.

## Service definition

Defined in `pi-hole/docker-compose.yml` as `docker_exporter`. It mounts `/var/run/docker.sock` read-only and listens on port 9713.

## Prometheus scrape config

Defined in `pi-hole/prometheus/prometheus.yml`:

```yaml
- job_name: 'docker_exporter'
  static_configs:
    - targets: ['127.0.0.1:9713']
```

## Compatible Grafana dashboards

Because metric names are cAdvisor-compatible, the standard cAdvisor dashboards work without modification:

- **Docker & system monitoring** — Grafana dashboard ID `10619` or `893`
- **Raspberry Pi & Docker Monitoring** — already included in this repo

## Useful metrics

| Metric | Description |
|--------|-------------|
| `container_cpu_usage_seconds_total` | Cumulative CPU time per container |
| `container_memory_usage_bytes` | Memory usage per container |
| `container_memory_working_set_bytes` | Working set memory (the number cAdvisor breaks on Pi 5) |
| `container_network_receive_bytes_total` | Network received per container |
| `container_network_transmit_bytes_total` | Network transmitted per container |
| `container_fs_reads_bytes_total` | Disk reads per container |
| `container_fs_writes_bytes_total` | Disk writes per container |

## Troubleshooting

If Docker panels show "No data":

1. Check the target is up in Prometheus: `http://192.168.1.5:9090/targets`
2. Check metrics are present: `http://192.168.1.5:9713/metrics`
3. Verify the dashboard queries use `container_*` metric names, not `docker_container_*`
