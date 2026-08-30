# Pi-hole v6 API auth — 401 troubleshooting

Pi-hole v6 authenticates API requests with a session (`sid`) and CSRF token.
Symptoms of misconfiguration: `401 Unauthorized` on endpoints such as
`/api/queries`.

## Root cause of most 401s

The web server domain is set in `pi-hole/etc-pihole/pihole.toml`
(`webserver.domain`, e.g. `pi.hole`). Cookie-based sessions are bound to that
host, so a request sent to `127.0.0.1` (or any other `Host`) will not carry the
cookie and is rejected unless you either:

- send the `X-FTL-SID: <sid>` header, or
- send the request with `Host` matching the configured domain (e.g. `pi.hole`)
  and include the `X-CSRF-TOKEN` header from login.

The web/admin password is supplied to the container via `WEBPASSWORD` and
`FTLCONF_webserver_api_password` in `pi-hole/docker-compose.yml` (both read from
`WEBPASSWORD` in `pi-hole/.env`).

## Verification (from the Pi host)

Replace the password at runtime — never paste a real password into docs or
commands. Read it from the env file:

```bash
PW="$(grep '^WEBPASSWORD=' pi-hole/.env | cut -d= -f2-)"
```

### 1) Login and store cookie + CSRF (browser-like)

```bash
curl -s -c /tmp/pihole_cookies --resolve pi.hole:80:127.0.0.1 \
  -H "Content-Type: application/json" \
  -X POST "http://pi.hole/api/auth" \
  --data-raw "{\"password\":\"$PW\"}" -o /tmp/pihole_login.json

sid=$(jq -r '.session.sid' /tmp/pihole_login.json)
csrf=$(jq -r '.session.csrf' /tmp/pihole_login.json)
echo "SID=$sid CSRF=$csrf"
```

### 2) Call an endpoint with cookie + CSRF

```bash
curl -s -b /tmp/pihole_cookies --resolve pi.hole:80:127.0.0.1 \
  -H "X-CSRF-TOKEN: $csrf" \
  "http://pi.hole/api/queries" -w "\nHTTP_STATUS:%{http_code}\n"
```

### 3) Call an endpoint with X-FTL-SID (scripted clients)

```bash
curl -s --resolve pi.hole:80:127.0.0.1 -H "X-FTL-SID: $sid" \
  "http://pi.hole/api/queries" -w "\nHTTP_STATUS:%{http_code}\n"
```

Expected: `HTTP_STATUS:200` and a JSON array of queries.

## Notes

- For scripted clients, prefer `X-FTL-SID` (no cookie/CSRF needed). Ensure the
  `sid` was obtained from the same server/session.
- For cookie auth (browser-like), the `Host` header and cookie domain must match
  `webserver.domain`. A reverse proxy must forward the `X-CSRF-TOKEN` header.
- A fuller, sanitized command recipe lives in `doc/docker-commands.md`.
