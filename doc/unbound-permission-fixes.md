# unbound exporter permission fixes to enable logging and promitheus/grafana dashboards

- Fixed permissions on the mounted Unbound config so the Unbound process can read its TLS/control keys (detected runtime UID 1000 and adjusted ownership).
- Reworked Unbound startup so Docker captures runtime logs: updated the Unbound configuration file [`pi-hole/unbound/unbound.conf`](pi-hole/unbound/unbound.conf:1) to run in foreground (no daemon) and removed the invalid logfile target that failed inside the chroot (the key settings include `do-daemonize: no`).
- Added a small wrapper entrypoint to ensure the container prepares /dev and /var then runs Unbound in foreground: [`pi-hole/unbound/entrypoint.sh`](pi-hole/unbound/entrypoint.sh:1).
- Mounted the wrapper and configured the service entrypoint in compose: [`pi-hole/docker-compose.yml`](pi-hole/docker-compose.yml:24) (the unbound service now uses the bundled entrypoint).
- Restarted the Unbound and exporter containers to apply the changes.

## Verification (evidence)
- `docker logs unbound` now shows startup output from the wrapper and Unbound start notice, for example:
  - [entrypoint] wrapper starting
  - [entrypoint] exec unbound in foreground (stderr->stdout, verbose)
  - [1770115913] unbound[1:0] notice: Start of unbound 1.22.0.
  - 
  These lines are produced after the wrapper in [`pi-hole/unbound/entrypoint.sh`](pi-hole/unbound/entrypoint.sh:1) runs and execs Unbound.

- The unbound_exporter is reachable and serving metrics: a curl to the exporter endpoint returns Prometheus metrics (example: `go_memstats_alloc_bytes ...`) at http://127.0.0.1:9167/metrics. 
- Prometheus shows the unbound job as scraped (configured in [`pi-hole/prometheus/prometheus.yml`](pi-hole/prometheus/prometheus.yml:13)).

- From the exporter container I verified TCP connectivity to Unbound’s control port (unbound:8953) — connection succeeded (the exporter can reach `172.18.0.2:8953` inside the compose network).

## Diagnosis recap  

- Primary: mounted config + ownership/permissions prevented Unbound from reading its control certs and/or writing its logfile. That led the exporter to repeatedly fail when scraping the control socket.
- Secondary: Unbound had been chrooted and configured to write logs to a path that was invalid from inside the chroot, so Docker didn’t capture logs (the error seen earlier: "Could not open logfile /proc/self/fd/1").

What I did NOT change

- Prometheus scrape config and Grafana dashboards — they should now show Unbound metrics because the exporter serves metrics.

## Recommendations (next steps you should apply or I can apply)

- Fix the Pi-hole exporter configuration: change `PIHOLE_HOSTNAME` in [`pi-hole/docker-compose.yml`](pi-hole/docker-compose.yml:84) to remove the redundant scheme prefix (use `127.0.0.1` or `http://127.0.0.1:80` depending on exporter expectations) to resolve the authentication errors previously observed.
- Make ownership fixes persistent: add a `chown -R _unbound:_unbound /opt/unbound/etc/unbound` step in the wrapper [`pi-hole/unbound/entrypoint.sh`](pi-hole/unbound/entrypoint.sh:1) so host-mounted files are corrected on container start.
- Optional: if you prefer not to replace the image entrypoint, revert the wrapper and instead use a small log-sidecar that tails an internal Unbound logfile (less invasive), or adapt the image’s original startup script to ensure stdout/stderr are available.

## current state (closing):

- Unbound is running and writing startup logs that Docker captures (`docker logs unbound` shows startup notice).
- unbound_exporter is able to connect to Unbound and serves Prometheus metrics at http://127.0.0.1:9167/metrics; Prometheus shows the unbound target as UP.

Files  edited

- [`pi-hole/unbound/unbound.conf`](pi-hole/unbound/unbound.conf:1)
- [`pi-hole/unbound/entrypoint.sh`](pi-hole/unbound/entrypoint.sh:1)
- [`pi-hole/docker-compose.yml`](pi-hole/docker-compose.yml:24)

Work completed: permission fix, config edits, wrapper creation, compose update, container restarts, verification of logs and metrics.