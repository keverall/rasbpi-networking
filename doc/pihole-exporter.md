# Pi-hole exporter

The `pihole_exporter` service exposes Pi-hole metrics for Prometheus.

## What runs

- Image: `ekofr/pihole-exporter:latest` (maintained community exporter).
- Listens on `127.0.0.1:9617` (host networking), scrape job `pihole` in
  `pi-hole/prometheus/prometheus.yml`.
- Configured in `pi-hole/docker-compose.yml`:

  ```yaml
  pihole_exporter:
    image: ekofr/pihole-exporter:latest
    network_mode: host
    environment:
      PIHOLE_HOSTNAME: 127.0.0.1
      PIHOLE_PASSWORD: ${WEBPASSWORD}
      PORT: '9617'
  ```

## Authentication

The exporter logs into the Pi-hole API with the web/admin password
(`WEBPASSWORD` from `pi-hole/.env`), passed via the `PIHOLE_PASSWORD`
environment variable. It does **not** use the separate `PIHOLE_API` token that
`pi-hole/.env.example` still lists — that token is unused by this stack.

If the password in `.env` changes, recreate the exporter:

```bash
cd pi-hole && docker compose up -d --no-deps --force-recreate pihole_exporter
```

## Verify

```bash
curl -s http://127.0.0.1:9617/metrics | grep -E '^pihole_' | head
```

In Prometheus, the `pihole` target should show as UP at
http://127.0.0.1:9090/targets.
