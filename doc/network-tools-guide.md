# Network Tools Guide

Utilities for monitoring, security auditing, and diagnostics from CachyOS.

---

## fail2ban

**Purpose**: Bans IPs that show malicious signs (failed SSH, brute force).

### Verify Config

```bash
# Check fail2ban is running
sudo systemctl status fail2ban

# List active jails
sudo fail2ban-client status

# Check specific jail (e.g., sshd)
sudo fail2ban-client status sshd

# List banned IPs
sudo fail2ban-client status sshd | grep "Banned IP list"

# Unban an IP
sudo fail2ban-client set sshd unbanip 192.168.1.100
```

### Config Location

- `/etc/fail2ban/jail.local` - custom rules
- `/etc/fail2ban/jail.d/` - additional jails

---

## lynis

**Purpose**: Security auditing and compliance testing.

### Run Audit

```bash
# Install
sudo pacman -S lynis

# Run system audit
sudo lynis audit system

# Run specific tests
sudo lynis audit system --tests-from-group firewall
sudo lynis audit system --tests-from-group networking

# View report
sudo cat /var/log/lynis-report.dat

# Show warnings
sudo grep "warning" /var/log/lynis-report.dat

# Show suggestions
sudo grep "suggestion" /var/log/lynis-report.dat
```

### Schedule Regular Audits

```bash
# Add to crontab (weekly)
sudo crontab -e
# Add: 0 3 * * 0 /usr/bin/lynis audit system --cronjob
```

---

## nmap

**Purpose**: Network scanning and discovery.

### Scan from CachyOS

```bash
# Install
sudo pacman -S nmap

# Scan Pi network
sudo nmap -sn 192.168.1.0/24

# Scan Pi for open ports
sudo nmap -sV 192.168.1.5

# Scan specific ports
sudo nmap -p 22,53,80,443,9090,3000 192.168.1.5

# OS detection
sudo nmap -O 192.168.1.5

# Full scan (slow, thorough)
sudo nmap -A -T4 192.168.1.5
```

### Common Scans

| Scan Type | Command | Use Case |
| --- | --- | --- |
| Ping sweep | `nmap -sn 192.168.1.0/24` | Find live hosts |
| Quick | `nmap -F 192.168.1.5` | Fast port scan |
| Service | `nmap -sV 192.168.1.5` | Detect service versions |
| Stealth | `nmap -sS 192.168.1.5` | SYN scan (less logging) |

---

## iperf3

**Purpose**: Bandwidth testing between machines.

### Setup

```bash
# Install on CachyOS
sudo pacman -S iperf3

# Install on Pi
sudo apt install -y iperf3
```

### Run Test

```bash
# On Pi (server mode)
iperf3 -s

# On CachyOS (client mode)
iperf3 -c 192.168.1.5

# Reverse test (Pi uploads to CachyOS)
iperf3 -c 192.168.1.5 -r

# Test with parallel streams
iperf3 -c 192.168.1.5 -P 4

# Test specific duration
iperf3 -c 192.168.1.5 -t 30
```

---

## mtr

**Purpose**: Combined traceroute + ping for network diagnostics.

### Usage

```bash
# Install
sudo pacman -S mtr

# Trace route to Pi
mtr 192.168.1.5

# Trace to external host
mtr google.com

# Report mode (output after 10 packets)
mtr -r -c 10 192.168.1.5

# Show numeric IPs (no DNS lookup)
mtr -n 192.168.1.5
```

### Interpreting Output

- **Loss%** = packet loss at that hop
- **Avg** = average latency
- **Wrst** = worst latency

---

## netdata

**Purpose**: Real-time system monitoring with web UI.

### Install on Pi

```bash
# Install
curl https://my-netdata.io/kickstart.sh > /tmp/netdata-kickstart.sh
sh /tmp/netdata-kickstart.sh

# Or Docker
docker run -d --name=netdata \
  -p 19999:19999 \
  -v netdataconfig:/etc/netdata \
  -v netdatalib:/var/lib/netdata \
  -v netdatacache:/var/cache/netdata \
  -v /etc/passwd:/etc/passwd:ro \
  -v /etc/group:/etc/group:ro \
  -v /proc:/proc:ro \
  -v /sys:/sys:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --cap-add SYS_PTRACE \
  --security-opt apparmor=unconfined \
  netdata/netdata
```

### Access

- URL: `http://192.168.1.5:19999`

### Integrate with Prometheus/Grafana

```bash
# netdata exports Prometheus metrics at
http://192.168.1.5:19999/api/v1/allmetrics?format=prometheus
```

Add to `prometheus.yml`:

```yaml
  - job_name: 'netdata'
    static_configs:
      - targets: ['192.168.1.5:19999']
```

---

## Grafana Dashboards

### Import Dashboards

1. Navigate to `http://192.168.1.5:3000`
2. Dashboards → Import
3. Enter dashboard ID or paste JSON

### Useful Dashboard IDs

| ID | Name | Monitors |
| --- | --- | --- |
| 1860 | Node Exporter Full | CPU, Memory, Disk, Network |
| 9658 | Pi-hole | DNS queries, blocked domains |
| 12345 | WireGuard | VPN traffic (if applicable) |

### Create Alerts

1. Edit panel → Alert tab
2. Set condition (e.g., `WHEN last() OF query(A, 5m, now) IS ABOVE 80`)
3. Configure notification channel

### Notification Channels

Settings → Notification channels → Add:

- **Discord**: Webhook URL
- **Email**: SMTP settings
- **Telegram**: Bot token + chat ID

---

## Quick Reference

| Tool | Install (CachyOS) | Command |
| --- | --- | --- |
| fail2ban | `sudo pacman -S fail2ban` | `sudo fail2ban-client status` |
| lynis | `sudo pacman -S lynis` | `sudo lynis audit system` |
| nmap | `sudo pacman -S nmap` | `sudo nmap -sV 192.168.1.5` |
| iperf3 | `sudo pacman -S iperf3` | `iperf3 -c 192.168.1.5` |
| mtr | `sudo pacman -S mtr` | `mtr 192.168.1.5` |
| netdata | Docker on Pi | `http://192.168.1.5:19999` |
