# Pi-hole FTL API password configuration

How the Pi-hole web admin / FTL HTTP API password is set in this repo, and how
to authenticate to the API. **No secrets live in this repository** — see
`pi-hole/.gitignore`; the real `pi-hole/.env` is ignored and never committed.

## How the password is provided

The Pi-hole password comes from `WEBPASSWORD` in `pi-hole/.env` (copy and edit
from `pi-hole/.env.example`). It is passed to the `pihole` service in
[`pi-hole/docker-compose.yml`](pi-hole/docker-compose.yml) like this:

```yaml
services:
  pihole:
    environment:
      TZ: ${TZ}
      WEBPASSWORD: ${WEBPASSWORD}
      FTLCONF_webserver_api_password: ${WEBPASSWORD}
```

- `WEBPASSWORD` — the legacy variable Pi-hole maps to the web admin password.
- `FTLCONF_webserver_api_password` — an **FTL configuration key** exposed as an
  environment variable via Pi-hole FTL's `FTLCONF_*` convention (each
  `FTLCONF_<key>` maps to an FTL config setting, with underscores converted to
  config separators). Both lines set the **same** credential, so the web UI and
  the FTL HTTP API share one password.

> `PIHOLE_API` still appears in `pi-hole/.env.example` but is **unused** by this
> stack. The `pihole_exporter` service authenticates with the web/admin password
> via the `PIHOLE_PASSWORD` environment variable (set from `WEBPASSWORD`), not a
> separate token. The `PIHOLE_API` line can be ignored or removed.

## Authenticating to the FTL API

1. Obtain a session by posting the password to `/api/auth` (`https://127.0.0.1`
   with a self-signed cert, so `-k` is used; matching the recipe in
   [`doc/docker-commands.md`](doc/docker-commands.md)):

   ```bash
   # Read the secret at runtime; never hard-code it.
   PW="$(grep '^WEBPASSWORD=' pi-hole/.env | cut -d= -f2-)"
   curl -sk -X POST "https://127.0.0.1/api/auth" \
     -H "Content-Type: application/json" \
     -d "{\"password\":\"${PW}\"}"
   ```

   A success response looks like:

   ```json
   {"session":{"valid":true,"sid":"<SID>","csrf":"<CSRF>","totp":false}}
   ```

   A wrong password returns `401` with:

   ```json
   {"session":{"valid":false,"message":"password incorrect"}}
   ```

2. Reuse the session for API calls via the `SID` and `CSRF` returned in
   `session.sid` / `session.csrf`:

   ```bash
   SID=...    # from session.sid
   CSRF=...   # from session.csrf
   curl -sk -H "X-FTL-SID: ${SID}" -H "X-CSRF-TOKEN: ${CSRF}" \
     "https://127.0.0.1/api/queries"
   ```

   The full, sanitized step-by-step recipe (cookie jar, CSRF flow, `pi.hole`
   Host header) lives in [`doc/docker-commands.md`](doc/docker-commands.md).

## Notes

- `pi-hole/.env` is listed in `.gitignore` and must **never** be committed. It
  contains `WEBPASSWORD` (and, for backwards-compatibility, an unused
  `PIHOLE_API` line).
- Never paste real passwords into repository files or documentation — always read
  them at runtime as shown above.
- After changing `WEBPASSWORD` in `.env`, recreate the container:

  ```bash
  cd pi-hole && docker compose up -d --no-deps --force-recreate pihole
  ```
