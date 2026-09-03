# Docker Update Commands

Commands for updating and maintaining the Docker stack on pi-networking (192.168.1.5).

## SSH Access

```bash
# Connect to Pi
ssh pi-networking@192.168.1.5

# Or run commands directly
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes pi-networking@192.168.1.5 "hostname"
```

## Update Upstream Images

Pulls latest versions of externally hosted images (Prometheus, Grafana, Node Exporter, Pi-hole Exporter).

The four custom images (`local/pihole`, `local/unbound-rpi`, `local/unbound_exporter`,
`local/raspi_exporter`) are built locally and have `pull_policy: build`, so
`docker compose pull` automatically skips them instead of trying to fetch them
from a registry.

```bash
ssh pi-networking@192.168.1.5 "cd ~/repos/rasbpi-networking/pi-hole && docker compose pull && docker compose up -d"
```

If you only want to pull specific upstream services:
```bash
ssh pi-networking@192.168.1.5 "cd ~/repos/rasbpi-networking/pi-hole && docker compose pull prometheus grafana node_exporter pihole_exporter alertmanager loki promtail docker_exporter"
```

## Rebuild All Local Images

Rebuilds all custom images from Dockerfiles.

```bash
# Build all images at once
ssh pi-networking@192.168.1.5 "cd ~/repos/rasbpi-networking/pi-hole && docker compose build"
```

Or individually:

```bash
# Pi-hole (arm64)
ssh pi-networking@192.168.1.5 "cd ~/repos/rasbpi-networking/pi-hole && docker compose build pihole"

# Unbound 1.26.0 (compiled from source)
ssh pi-networking@192.168.1.5 "cd ~/repos/rasbpi-networking/pi-hole && docker compose build unbound"

# Raspberry Pi Exporter (vcgencmd wrapper)
ssh pi-networking@192.168.1.5 "cd ~/repos/rasbpi-networking/pi-hole && docker compose build raspi_exporter"

# Unbound Exporter
ssh pi-networking@192.168.1.5 "cd ~/repos/rasbpi-networking/pi-hole && docker compose build unbound_exporter"
```

## Rebuild and Restart Single Service

```bash
# Pi-hole
ssh pi-networking@192.168.1.5 "cd ~/repos/rasbpi-networking/pi-hole && docker compose up -d --no-deps --build pihole"

# Unbound
ssh pi-networking@192.168.1.5 "cd ~/repos/rasbpi-networking/pi-hole && docker compose up -d --no-deps --build unbound"

# Raspi Exporter
ssh pi-networking@192.168.1.5 "cd ~/repos/rasbpi-networking/pi-hole && docker compose up -d --no-deps --build raspi_exporter"

# Unbound Exporter
ssh pi-networking@192.168.1.5 "cd ~/repos/rasbpi-networking/pi-hole && docker compose up -d --no-deps --build unbound_exporter"
```

## Verify Services

```bash
# Container status
ssh pi-networking@192.168.1.5 "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"

# Unbound version
ssh pi-networking@192.168.1.5 "docker exec unbound /opt/unbound/sbin/unbound -V 2>&1 | grep Version"

# Pi-hole version
ssh pi-networking@192.168.1.5 "docker exec pihole pihole -v 2>&1 | head -1"

# DNS resolution test
ssh pi-networking@192.168.1.5 "docker exec pihole nslookup google.com 127.0.0.1"

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

## Dockerfiles Reference

| Dockerfile | Image | Description |
|------------|-------|-------------|
| `pi-hole/Dockerfile` | local/pihole:arm64 | Pi-hole for Raspberry Pi 5 (arm64) |
| `pi-hole/Dockerfile.unbound` | local/unbound-rpi:1.26.0 | Unbound DNS resolver 1.26.0 (compiled from source) |
| `pi-hole/raspi-exporter/Dockerfile` | local/raspi_exporter:latest | Raspberry Pi metrics exporter (vcgencmd wrapper) |
| `pi-hole/unbound-exporter/Dockerfile` | local/unbound_exporter:latest | Unbound metrics exporter |

## Current Image Versions

| Service | Image | Version |
|---------|-------|---------|
| Unbound | local/unbound-rpi:1.26.0 | 1.26.0 (compiled from source) |
| Pi-hole | local/pihole:arm64 | v6.4.3 |
| Prometheus | prom/prometheus:latest | 3.14.0 |
| Grafana | grafana/grafana:latest | 13.2.0 |
| Node Exporter | prom/node-exporter:latest | latest |
| Unbound Exporter | local/unbound_exporter:latest | latest (Go 1.25) |
| Raspi Exporter | local/raspi_exporter:latest | Python 3.11 |
| Pi-hole Exporter | ekofr/pihole-exporter:latest | latest |
