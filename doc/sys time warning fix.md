# Sys time not working

error -

2026-02-03 19:02:06.854 GMT [68M] INFO:  -> Known forward destinations: 0
2026-02-03 19:02:07.503 GMT [68M] WARNING: Insufficient permissions to set system time (CAP_SYS_TIME required), NTP client not available
2026-02-03 19:02:07.503 GMT [68/T69] INFO: NTP server listening on 0.0.0.0:123 (IPv4)
2026-02-03 19:02:07.503 GMT [68/T70] INFO: NTP server listening on :::123 (IPv6)
from docker logs pihole -

- Edited [`pi-hole/docker-compose.yml OR yaml()`](pi-hole/docker-compose.yml:20) to add capabilities to the pihole service's [`cap_add OR yaml()`](pi-hole/docker-compose.yml:20):
  - [`NET_ADMIN OR yaml()`](pi-hole/docker-compose.yml:21)
  - [`SYS_TIME OR yaml()`](pi-hole/docker-compose.yml:22)
  - [`SYS_NICE OR yaml()`](pi-hole/docker-compose.yml:23)

## Commands I ran

- [`docker compose -f pi-hole/docker-compose.yml up -d --no-deps --build pihole OR bash()`](pi-hole/docker-compose.yml:20)
- [`docker inspect pihole OR bash()`](pi-hole/docker-compose.yml:20)
- [`docker logs --tail 200 pihole OR bash()`](pi-hole/docker-compose.yml:20)

## Verification (selected evidence)
- `docker inspect` reported the added caps: CapAdd: ["[`CAP_NET_ADMIN OR bash()`](pi-hole/docker-compose.yml:21)", "[`CAP_SYS_NICE OR bash()`](pi-hole/docker-compose.yml:23)", "[`CAP_SYS_TIME OR bash()`](pi-hole/docker-compose.yml:22)"]
- Container logs show the runtime applying the capabilities (caps list includes [`CAP_SYS_NICE OR bash()`](pi-hole/docker-compose.yml:23) and [`CAP_SYS_TIME OR bash()`](pi-hole/docker-compose.yml:22)) and NTP successfully receiving replies:
  - "INFO: Applying the following caps to pihole-FTL: ... [`CAP_SYS_NICE OR bash()`](pi-hole/docker-compose.yml:23), [`CAP_SYS_TIME OR bash()`](pi-hole/docker-compose.yml:22)"
  - "INFO: Received 8/8 valid NTP replies from pool.ntp.org" (NTP client active)

## Notes & caveats
- Granting [`CAP_SYS_TIME OR bash()`](pi-hole/docker-compose.yml:22) allows the container to change the host clock — this is a powerful privilege; only grant it to trusted images.
- If Docker is running in rootless mode, assigning [`CAP_SYS_TIME OR bash()`](pi-hole/docker-compose.yml:22) may be ineffective; in that case run NTP on the host or run Pi-hole under a different runtime.

## How to revert
- Remove [`SYS_TIME OR yaml()`](pi-hole/docker-compose.yml:22) and [`SYS_NICE OR yaml()`](pi-hole/docker-compose.yml:23) from [`pi-hole/docker-compose.yml OR yaml()`](pi-hole/docker-compose.yml:20) and recreate the service with:
  - [`docker compose -f pi-hole/docker-compose.yml up -d --no-deps --build pihole OR bash()`](pi-hole/docker-compose.yml:20)

## Outcome
- The capability error (Insufficient permissions to set system time) has been resolved: the pihole container now has the capabilities required and Pi-hole's FTL started its NTP client successfully. Completed.

