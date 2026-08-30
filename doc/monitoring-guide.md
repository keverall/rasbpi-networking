# Monitoring Stack Guide

The Pi-hole stack ships with monitoring built on Prometheus, Alertmanager,
Grafana, Loki, and Promtail. All services run with `network_mode: host` on the
Pi (`192.168.1.5` on the LAN).

> `Uptime Kuma` is **not** part of this stack (the service was removed to reduce
> Pi CPU load). References to it in older notes are stale.

## Components

| Component | Purpose | LAN URL |
| --- | --- | --- |
| Prometheus | Scrape & store metrics | http://192.168.1.5:9090 |
| Alertmanager | Route alerts from Prometheus | http://192.168.1.5:9093 |
| Grafana | Dashboards (Prometheus + Loki) | http://192.168.1.5:3000 |
| Loki / Promtail | Log aggregation & shipping | (queried via Grafana) |

---

## Alertmanager

**URL**: http://192.168.1.5:9093

### How it works

1. Prometheus evaluates alert rules every 15s (`scrape_interval` in
   `pi-hole/prometheus/prometheus.yml`).
2. When a threshold is exceeded, Prometheus sends the alert to Alertmanager.
3. Alertmanager deduplicates, groups, and routes alerts.
4. Notifications are sent per `pi-hole/alertmanager/config.yml` (currently none
   configured by default).

### Pre-configured alerts (`pi-hole/prometheus/alert_rules.yml`)

| Alert | Condition | Severity |
| --- | --- | --- |
| PiHoleDown | Pi-hole unreachable for 5m | Critical |
| HighCPUUsage | CPU > 80% for 10m | Warning |
| HighMemoryUsage | Memory > 85% for 10m | Warning |
| DiskSpaceLow | Disk > 90% for 10m | Critical |
| ContainerDown | `node_exporter` down 5m | Warning |

### Adding notifications

Edit `pi-hole/alertmanager/config.yml`. Example (Discord):

```yaml
route:
  receiver: 'discord'
receivers:
  - name: 'discord'
    discord_configs:
      - webhook_url: 'YOUR_DISCORD_WEBHOOK_URL'
        title: 'Pi-hole Alert'
        text: '{{ .CommonAnnotations.summary }}'
```

Restart:

```bash
cd pi-hole && docker compose restart alertmanager
```

### Viewing alerts

- Active alerts: http://192.168.1.5:9093/#/alerts
- Prometheus rules: http://192.168.1.5:9090/alerts

---

## Grafana dashboards

**URL**: http://192.168.1.5:3000

### Data sources

- Prometheus: http://192.168.1.5:9090
- Loki: http://192.168.1.5:3100

### Useful panels (PromQL)

- CPU usage: `100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
- Memory usage: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`
- DNS queries: `rate(pihole_dns_queries_total[5m])`

### Recommended dashboard IDs

- Node Exporter Full — `1860`
- Pi-hole — `9658`

---

## Maintenance

### Restart services

```bash
cd pi-hole && docker compose restart alertmanager prometheus grafana loki promtail
```

### View logs

```bash
docker logs -f alertmanager
docker logs -f prometheus
```

### Backup

- Alertmanager config: `pi-hole/alertmanager/config.yml`
- Grafana data: `pi-hole/grafana/` (runtime DB is git-ignored)
- Prometheus data: `pi-hole/prometheus/` (TSDB volume)
