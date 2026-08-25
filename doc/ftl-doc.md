I've added FTLCONF_webserver_api_password to the pihole service environment in [`pi-hole/docker-compose.yml OR yaml()`](pi-hole/docker-compose.yml:11) and set FTLCONF_webserver_api_password="${WEBPASSWORD}" in [`pi-hole/.env OR env()`](pi-hole/.env:4). Then I recreated the pihole container with `docker compose up -d --no-deps --force-recreate pihole`.

Next steps to verify API access (run these on your Pi/host). IMPORTANT: do NOT paste or commit real passwords into repository files or documentation. Use an environment variable (for example `${WEBPASSWORD}` from [`pi-hole/.env`](pi-hole/.env:1)) or read the secret at runtime.

1) Obtain sid+CSRF with curl and store cookies (use a runtime secret placeholder):
   - Example using an explicit placeholder (replace <REDACTED_PASSWORD> with a value read from an env var/secure source):
     - curl -s -c cookies.txt -X POST "http://127.0.0.1/api/auth" -H "Content-Type: application/json" -d '{"password":"<REDACTED_PASSWORD>"}'
   - Inspect token: `jq -r .token <(tail -n +1 cookies.txt 2>/dev/null || echo '{}')` (or parse curl output directly)

2) Example using header-based SID (no cookie):
   - SID=$(curl -s -X POST "http://127.0.0.1/api/auth" -H "Content-Type: application/json" -d '{"password":"<REDACTED_PASSWORD>"}' | jq -r .sid)
   - curl -s -H "X-FTL-SID: $SID" "http://127.0.0.1/api/queries"

3) Example using cookie+CSRF:
   - curl -s -c cookies.txt -X POST "http://127.0.0.1/api/auth" -H "Content-Type: application/json" -d '{"password":"<REDACTED_PASSWORD>"}' | jq -r .token > token.txt
   - curl -s -b cookies.txt -H "X-CSRF-TOKEN: $(cat token.txt)" "http://127.0.0.1/api/queries"

If these return 200 and the expected JSON, the API password is correctly set. I will mark verification as pending in the todo list. Completed changes are in the repo; tell me if you want me to revert or instead patch the compose to use FTLCONF_webserver_api_password from a different env var (e.g., ADMIN_PASSWORD).
