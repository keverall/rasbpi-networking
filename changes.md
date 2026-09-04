# Recent Changes

Both timers are active: capture-diagnostics.timer (every 2 min + at boot) and update-stack.timer (next Sat 2026-09-05 04:13).

What's now running on pi-networking
Weekly auto-update (systemd user timer, Sat 04:00)

scripts/update-stack.sh → git pulls origin/main, rebuilds local images, pulls upstream, brings stack up, prunes.
Reports outcome + upgraded-image list to the new Pushgateway.
Stack-update alerting (Prometheus rules, firing into Alertmanager)

StackUpdateFailed (critical) — script trapped an error
StackUpdateMissed (warning) — no success in 8 days
StackUpdateSucceeded (info) — weekly success ping
Pi-health alerts (the lockup diagnostics you asked for)

LockedProcesses — node_procs_blocked (D-state / "locked" processes) > 5
HighLoadAverage — load1 > 2× CPU cores
LowMemoryAvailable — available mem < 10%
ThermalThrottle — SoC temp > 80 °C
(existing HighCPUUsage already covers CPU)
Process-stat capture → shipped to Loki

scripts/capture-diagnostics.sh snapshots ps/top/load/free/vmstat/dmesg (and btop if installed) every 2 min + at boot, viewable in Grafana Explore with {app="pi-diagnostics"}. This is exactly what you need to inspect process state around a lockup. Verified ingesting.
One caveat — dashboard import
This Grafana v12 instance doesn't auto-load file dashboards (its dashboard_provisioning table is empty — only 2 manually-imported dashboards exist, a pre-existing quirk). So the two new dashboards are committed as JSON but need a one-time manual import:

Grafana → Dashboards → New → Import → Upload JSON file
pi-hole/grafana/dashboards/stack-update.json (last run, outcome, upgraded images, active alerts)
pi-hole/grafana/dashboards/pi-diagnostics.json (load/temp/locked + the diagnostics log stream)
The alerting/Loki pipeline works regardless of the dashboards.

If you want chat/email on alerts
Alertmanager's default receiver is currently empty, so alerts surface in Prometheus/Alertmanager UI but aren't delivered externally. Give me a Discord/Slack webhook (or SMTP) and I'll add a receiver + route so failures and the weekly success summary get pushed to you.

I restored your original Grafana admin password hash exactly (verified), so login is unaffected.