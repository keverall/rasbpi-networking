# Docker Update Commands

Commands for updating and maintaining the Docker stack on pi-networking (192.168.1.5).

## SSH Access

```bash
# Connect to Pi
ssh pi-networking@192.168.1.5

# Or run commands directly
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes pi-networking@192.168.1.5 "hostname"
```

## Update All Images

```bash
ssh pi-networking@192.168.1.5 "cd ~/repos/rasbpi-networking/pi-hole && docker compose pull && docker compose up -d"
```

## Rebuild Custom Unbound Image (1.26.0)

The Unbound image is compiled from source since the Alpine package is outdated.

```bash
ssh pi-networking@192.168.1.5 "cd ~/repos/rasbpi-networking/pi-hole && docker build -f Dockerfile.unbound -t local/unbound-rpi:1.26.0 . && docker compose up -d --no-deps --force-recreate unbound"
```

## Verify Services

```bash
# Container status
ssh pi-networking@192.168.1.5 "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"

# Unbound version
ssh pi-networking@192.168.1.5 "docker exec unbound /opt/unbound/sbin/unbound -V 2>&1 | grep Version"

# cAdvisor version
ssh pi-networking@192.168.1.5 "docker exec cadvisor /usr/bin/cadvisor --version 2>&1 | head -1"

# Pi-hole version
ssh pi-networking@192.168.1.5 "docker exec pihole pihole -v 2>&1 | head -1"

# DNS resolution test
ssh pi-networking@192.168.1.5 "docker exec pihole nslookup google.com"

# Prometheus targets
ssh pi-networking@192.168.1.5 "curl -s http://127.0.0.1:9090/api/v1/targets | python3 -c 'import sys,json; d=json.load(sys.stdin); [print(f\"  {t[\"labels\"][\"job\"]}: {t[\"health\"]}\") for t in d[\"data\"][\"activeTargets\"]]'"
```

## Restart All Containers

```bash
ssh pi-networking@192.168.1.5 "cd ~/repos/rasbpi-networking/pi-hole && docker compose restart"
```

## View Logs

```bash
# Pi-hole logs
ssh pi-networking@192.168.1.5 "docker logs --tail 50 pihole"

# Unbound logs
ssh pi-networking@192.168.1.5 "docker logs --tail 50 unbound"

# All containers
ssh pi-networking@192.168.1.5 "cd ~/repos/rasbpi-networking/pi-hole && docker compose logs --tail 20"
```

## Clean Up

```bash
# Remove unused images
ssh pi-networking@192.168.1.5 "docker image prune -f"

# Remove stopped containers
ssh pi-networking@192.168.1.5 "docker container prune -f"
```

## Current Image Versions

| Service | Image | Version |
|---------|-------|---------|
| Unbound | local/unbound-rpi:1.26.0 | 1.26.0 (compiled from source) |
| cAdvisor | ghcr.io/google/cadvisor:latest | v0.60.5 |
| Pi-hole | local/pihole:arm64 | v6.4.3 |
| Prometheus | prom/prometheus:latest | 3.14.0 |
| Grafana | grafana/grafana:latest | 13.2.0 |
| Node Exporter | prom/node-exporter:latest | latest |
| Unbound Exporter | local/unbound_exporter:latest | local build |
| Raspi Exporter | local/raspi_exporter:latest | local build |
