#!/usr/bin/env bash
#
# Capture a point-in-time Pi diagnostics snapshot to a log file so that, when
# the Pi locks up, the process/CPU/memory state just before the lockup is
# retained in Loki (and viewable in Grafana) for post-mortem analysis.
#
# Run every 2 minutes by the systemd user timer (see capture-diagnostics.{service,timer}).
#
set -u

OUT_DIR="$HOME/logs/pi-diagnostics"
mkdir -p "$OUT_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
OUT="$OUT_DIR/diag-$TS.log"

{
  echo "=== Pi diagnostics snapshot: $(date -Is) ==="
  echo "--- uptime ---"; uptime 2>/dev/null
  echo "--- loadavg (/proc/loadavg) ---"; cat /proc/loadavg 2>/dev/null
  echo "--- free ---"; free -h 2>/dev/null
  echo "--- vmstat 1 3 ---"; vmstat 1 3 2>/dev/null
  echo "--- top CPU processes (pid ppid stat %cpu %mem cmd) ---"
  ps -eo pid,ppid,stat,pcpu,pmem,comm --sort=-pcpu 2>/dev/null | head -21
  echo "--- top MEM processes ---"
  ps -eo pid,ppid,stat,pcpu,pmem,comm --sort=-pmem 2>/dev/null | head -21
  echo "--- D-state (uninterruptible / locked) processes ---"
  ps -eo pid,stat,comm 2>/dev/null | awk 'NR==1 || $2 ~ /D/'
  echo "--- btop ---"; command -v btop >/dev/null 2>&1 && btop --utf-force -b -n 1 2>/dev/null || echo "btop not installed"
  echo "--- dmesg tail ---"; dmesg -T 2>/dev/null | tail -25
  echo "--- disk usage ---"; df -h / /boot 2>/dev/null
  echo "=== end snapshot ==="
} >"$OUT" 2>&1

# Rotate: keep the most recent 40 snapshots (~80 min of history at 2-min interval).
ls -1t "$OUT_DIR"/diag-*.log 2>/dev/null | tail -n +41 | xargs -r rm -f

echo "$OUT"
