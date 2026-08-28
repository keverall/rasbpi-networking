# Monitoring Stack Guide

Your Pi-hole stack includes two complementary monitoring tools: **Uptime Kuma** and **Alertmanager**.

## Quick Comparison

| Feature | Uptime Kuma | Alertmanager |
|---------|-------------|--------------|
| **Purpose** | Is my service reachable? | Is my CPU/disk too high? |
| **Monitors** | HTTP, TCP, ping | Metrics thresholds |
| **UI** | Pretty status pages | None (API only) |
| **Setup** | Simple, no config | YAML config files |
| **Integrates with** | Standalone | Prometheus |

---

## Uptime Kuma

**URL**: `http://192.168.1.5:3100`

### Setup
1. Navigate to `http://192.168.1.5:3100`
2. Create admin account on first visit
3. Click **+ Add New Monitor**

### Monitor Types

| Type | Use Case | Example |
|------|----------|---------|
| HTTP(s) | Website uptime | Pi-hole web UI |
| TCP Port | Service availability | DNS port 53 |
| Ping | ICMP reachability | Gateway 192.168.1.1 |
| DNS | DNS resolution | Query pi.hole |

### Recommended Monitors

| Name | Type | URL/Address | Port |
|------|------|-------------|------|
| Pi-hole Web | HTTP(s) | http://192.168.1.5 | 80 |
| Pi-hole DNS | TCP Port | 192.168.1.5 | 53 |
| Unbound DNS | TCP Port | 192.168.1.5 | 5335 |
| Grafana | HTTP(s) | http://192.168.1.5 | 3000 |
| Gateway | Ping | 192.168.1.1 | - |
| Internet | HTTP(s) | https://google.com | 443 |

### Notifications
Settings → Notifications → Add:
- Email (SMTP)
- Discord
- Slack
- Telegram
- Pushover

---

## Alertmanager

**URL**: `http://192.168.1.5:9093`

### How It Works
1. **Prometheus** evaluates alert rules every 15s
2. When threshold exceeded → sends alert to **Alertmanager**
3. **Alertmanager** deduplicates, groups, routes alerts
4. You receive notification (currently configured: none)

### Pre-configured Alerts

| Alert | Condition | Severity |
|-------|-----------|----------|
| PiHoleDown | Pi-hole unreachable for 5m | Critical |
| HighCPUUsage | CPU > 80% for 10m | Warning |
| HighMemoryUsage | Memory > 85% for 10m | Warning |
| DiskSpaceLow | Disk > 90% for 10m | Critical |
| ContainerDown | Monitoring container down 5m | Warning |

### Adding Notifications

Edit `pi-hole/alertmanager/config.yml`:

```yaml
receivers:
  - name: 'discord'
    discord_configs:
      - webhook_url: 'YOUR_DISCORD_WEBHOOK_URL'
        title: 'Pi-hole Alert'
        text: '{{ .CommonAnnotations.description }}'
```

Then update route:
```yaml
route:
  receiver: 'discord'
```

Restart:
```bash
cd pi-hole && docker compose restart alertmanager
```

### Viewing Alerts

- **Active alerts**: `http://192.168.1.5:9093/#/alerts`
- **Prometheus rules**: `http://192.168.1.5:9090/alerts`

---

## Grafana Dashboards

**URL**: `http://192.168.1.5:3000`

### Data Sources
- Prometheus: `http://192.168.1.5:9090`

### Useful Panels
- CPU usage: `100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
- Memory usage: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`
- DNS queries: `rate(pihole_dns_queries_total[5m])`

---

## Maintenance

### Restart Services
```bash
cd pi-hole
docker compose restart alertmanager uptime-kuma
```

### View Logs
```bash
docker logs -f alertmanager
docker logs -f uptime-kuma
```

### Backup
- Uptime Kuma data: `pi-hole/uptime-kuma/`
- Alertmanager config: `pi-hole/alertmanager/config.yml`
