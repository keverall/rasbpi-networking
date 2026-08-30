# Pi-hole: "Insufficient permissions to set system time" (CAP_SYS_TIME)

## Symptom

From `docker logs pihole`:

```
WARNING: Insufficient permissions to set system time (CAP_SYS_TIME required), NTP client not available
```

## Fix

The `pihole` service in `pi-hole/docker-compose.yml` was given the capabilities
it needs:

```yaml
cap_add:
  - NET_ADMIN
  - SYS_TIME
  - SYS_NICE
```

Apply by recreating the container:

```bash
cd pi-hole && docker compose up -d --no-deps --force-recreate pihole
```

After this, logs show the NTP client starting and receiving replies, e.g.
`Received 8/8 valid NTP replies from pool.ntp.org`.

## Caveats

- `CAP_SYS_TIME` lets the container change the host clock — a powerful
  privilege; only grant it to trusted images.
- Under rootless Docker, `CAP_SYS_TIME` may be ineffective. In that case run NTP
  on the host instead.
