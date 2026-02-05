# rasbpi-networking

Pi-hole Docker for Raspberry Pi 5 (arm64)

This repository contains a small Docker-based Pi-hole stack tailored for Raspberry Pi (arm64). It builds a local Pi-hole image and runs a small monitoring stack that makes it convenient to run Pi-hole alongside a local recursive resolver and Prometheus/Grafana monitoring.

What this project provides

- A locally built Pi-hole image (Pi-hole server + pihole-FTL + web UI).
- An Unbound recursive resolver for improved DNS privacy and performance.
- Exporters and monitoring: `pihole_exporter`, `unbound_exporter`, `node_exporter`, `cadvisor`, and an optional `raspi_exporter` for Raspberry Pi metrics.
- Prometheus to scrape exporter metrics and Grafana for dashboards.

Files of interest

- [pi-hole/Dockerfile](pi-hole/Dockerfile) — Dockerfile for the Pi-hole image build.
- [pi-hole/docker-compose.yml](pi-hole/docker-compose.yml) — compose stack (services, ports, volumes, env).
- [pi-hole/.env.example](pi-hole/.env.example) — example environment file; copy to `.env` and edit.
- [doc/endpoint-summary.md](doc/endpoint-summary.md) — summary of service endpoints and Prometheus mappings.
- [doc/docker-commands.md](doc/docker-commands.md) — handy docker/compose commands used for debugging and management.
- [doc/pihole-auth-issues-fixes.md](doc/pihole-auth-issues-fixes.md) — authentication troubleshooting and curl examples.
- [doc/ftl-doc.md](doc/ftl-doc.md) — FTL / API internals and implementation details.

Quick start (recommended on the Pi)

1. Copy the example env file and edit values:

   cp pi-hole/.env.example pi-hole/.env
   # Edit pi-hole/.env: set SERVERIP, WEBPASSWORD, PIHOLE_API (optional)

2. (Optional) Auto-detect SERVERIP for DHCP hosts:

   cd pi-hole && chmod +x generate-env.sh && ./generate-env.sh

3. Build and start the stack (or use the upstream image):

   # Build local pihole image (recommended on the Pi)
   cd pi-hole
   docker buildx build --platform linux/arm64 -t local/pihole:arm64 .

   # Start services
   docker compose up -d --build

4. Recreate only the pihole service after env changes:

   cd pi-hole && docker compose up -d --no-deps --force-recreate pihole

Important environment variables

- `FTLCONF_webserver_api_password` — set the web/API password via environment to avoid in-container interactive changes (preferred for Docker). See [pi-hole/.env.example](pi-hole/.env.example).
- `PIHOLE_API` — short-lived API token used by exporters (e.g., `pihole_exporter`). Generate with the Pi-hole web UI or `docker exec pihole pihole -a -t` and put it in `pi-hole/.env`.

Runtime overview — what runs and why

- pihole (container): Pi-hole web UI, pihole-FTL resolver and API. This is the DNS-blocking core.
- unbound (container): a recursive resolver bound to localhost (127.0.0.1:5335) to avoid external lookups, improving privacy.
- pihole_exporter: scrapes the Pi-hole API and exposes metrics for Prometheus.
- unbound_exporter: exports Unbound metrics for Prometheus.
- prometheus: scrapes the exporters and stores metrics.
- grafana: dashboarding for Prometheus metrics.
- node_exporter, cadvisor, raspi_exporter: host/container/system metrics for monitoring.

Where data is persisted

- Pi-hole configuration and gravity data: `pi-hole/etc-pihole`
- dnsmasq/pi-hole dns configuration: `pi-hole/etc-dnsmasq.d`
- Prometheus/Grafana data: `pi-hole/prometheus`, `pi-hole/grafana` (as configured in `docker-compose.yml`)

API authentication / common pitfalls

Pi-hole v6 API uses session IDs (sid) and CSRF tokens for cookie-based auth. Common options:

- Use cookie + X-CSRF-TOKEN: authenticate via `/api/auth` to obtain a session cookie and CSRF token, then send the token in `X-CSRF-TOKEN` on subsequent requests. See [doc/pihole-auth-issues-fixes.md](doc/pihole-auth-issues-fixes.md) for exact curl examples.
- Use header-based SID: include `X-FTL-SID: <sid>` header (obtained from `/api/auth`) for scripted clients — avoids cookie/CSRF complexity.

If you see 401 Unauthorized on actionable endpoints, ensure:

- You set `FTLCONF_webserver_api_password` or used `pihole setpassword` in a way compatible with Docker (prefer env variable).
- Host/cookie mismatch: Pi-hole may set the session cookie for a specific domain (e.g., `pi.hole`). When using curl or a reverse proxy, make sure the `Host` header and cookie domain match the configured `webserver.domain` (see `pi-hole/etc-pihole/pihole.toml`).

Further reading & troubleshooting

- [doc/endpoint-summary.md](doc/endpoint-summary.md)
- [doc/docker-commands.md](doc/docker-commands.md)
- [doc/pihole-auth-issues-fixes.md](doc/pihole-auth-issues-fixes.md)
- [doc/ftl-doc.md](doc/ftl-doc.md)

Support and notes

- This stack is intended for home/lab use. Exposing the Pi-hole web UI to the public internet is not recommended without additional protections (firewall, reverse proxy auth, etc.).
- If you need help reproducing the API authentication flows, see the curl examples in [doc/pihole-auth-issues-fixes.md](doc/pihole-auth-issues-fixes.md).

Completed.
