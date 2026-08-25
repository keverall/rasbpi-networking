# docker commands

This file has been sanitized to remove any embedded secrets. Do NOT paste real passwords into commands or commit them. Use environment variables or a secret manager and pass secrets at runtime.

docker compose -f pi-hole/docker-compose.yml ps --services --filter status=running

Get new Pi-hole API key (secure usage)

# Examples (placeholders used; replace with secure retrieval at runtime)
#  - Replace <REDACTED_PASSWORD> with a value read from an environment variable or secret manager

# 1) Login and store cookie + JSON (placeholder)
docker exec pihole /bin/sh -lc 'rm -f /tmp/pihole.cookies /tmp/login.json /tmp/app.json ; curl -k -s -c /tmp/pihole.cookies -H "Host: pi.hole" -H "Content-Type: application/json" -X POST "https://127.0.0.1/api/auth" -d '\''{"password":"<REDACTED_PASSWORD>"}'\'' -o /tmp/login.json ; echo "---LOGIN JSON---" ; cat /tmp/login.json ; csrf=$(sed -n '\''s/.*"csrf":"\([^"]*\)".*/\1/p'\'' /tmp/login.json) ; echo "---CSRF---:$csrf" ; curl -k -s -b /tmp/pihole.cookies -H "Host: pi.hole" -H "X-CSRF-TOKEN: $csrf" "https://127.0.0.1/api/auth/app" -o /tmp/app.json ; echo "---APP JSON---" ; cat /tmp/app.json || true'

# 2) Extract SID/CSRF locally (example)
# sid=$(jq -r '.session.sid' /tmp/pihole_login.json)
# csrf=$(jq -r '.session.csrf' /tmp/pihole_login.json)

# 3) Call an endpoint using cookie + CSRF or X-FTL-SID
# curl -s -b /tmp/pihole_cookies --resolve pi.hole:80:127.0.0.1 -H "X-CSRF-TOKEN: $csrf" "http://pi.hole/api/queries" -w "\nHTTP_STATUS:%{http_code}\n"
# curl -s --resolve pi.hole:80:127.0.0.1 -H "X-FTL-SID: $sid" "http://pi.hole/api/queries" -w "\nHTTP_STATUS:%{http_code}\n"

# Container maintenance examples
cd pi-hole && (docker compose restart pihole || docker-compose restart pihole || docker restart pihole) && docker ps --filter "name=pihole" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" && docker logs --tail 200 pihole

docker run --rm local/unbound_exporter:latest --help

# Notes & security guidance
- Secrets must never be committed to version control. If a secret was committed, rotate it immediately (see below) and consider rewriting history.
- Use environment variables or a secrets manager. Put runtime env files (e.g., `pi-hole/.env`) in `.gitignore` and never commit them.
- If a secret leaked to logs or was committed, rotate the credential(s) immediately, then purge logs and/or rewrite git history if needed.

# Quick mitigation checklist (high priority)
- Rotate the Pi-hole web/admin password and any API tokens (PIHOLE_API).
- Truncate/clean container logs that contain the secret (see remediation steps shared with the maintainer).
- Remove secrets from repo files (this file has been sanitized). Search the repo for accidental secrets.
- If the secret was committed to git, consider rewriting history (git filter-repo or BFG) and force-pushing — this is destructive and will require collaborators to re-clone.

Completed.
