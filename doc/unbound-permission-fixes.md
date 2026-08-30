# Unbound logging & exporter fixes

Fixes so Unbound writes logs Docker can capture and the `unbound_exporter`
can scrape it.

## What changed

- **Config**: `pi-hole/unbound/unbound.conf` runs Unbound in the foreground
  (`do-daemonize: no`) and no longer writes to a logfile path that is invalid
  inside the chroot (the earlier `Could not open logfile /proc/self/fd/1`
  error).
- **Entrypoint**: `pi-hole/unbound/entrypoint.sh` prepares `/dev` and `/var`
  and execs Unbound in the foreground so `docker logs unbound` shows startup
  output.
- **Compose**: the `unbound` service mounts the wrapper and uses it as its
  `entrypoint` (`pi-hole/docker-compose.yml`).
- **Permissions**: host-mounted Unbound config ownership was adjusted so Unbound
  can read its TLS/control keys (runtime UID `1000`).

## Verify

- `docker logs unbound` shows the wrapper and Unbound start notice, e.g.
  `Start of unbound 1.22.0.`
- `unbound_exporter` serves metrics at http://127.0.0.1:9167/metrics.
- Prometheus `unbound` target is UP at http://127.0.0.1:9090/targets.

## Notes

- Prometheus scrape config and Grafana dashboards were not changed; they now
  show Unbound metrics because the exporter serves them.
- The exporter reaches Unbound's control port `8953` (exporter → `127.0.0.1`,
  host networking).
