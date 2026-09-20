# whitelisting sites

## commands

```shell
ssh -o ConnectTimeout=5 pi "docker exec pihole pihole allow track.webgains.com" 2>&1 | head -20
```

## TopCashback and Google affiliate redirects

TopCashback/Rakuten links use `click.linksynergy.com` as their redirect host.
Google Ads links use `googleadservices.com` and `www.googleadservices.com`.
Allowlist the hosts rather than the full URLs or their query parameters:

```shell
ssh -o ConnectTimeout=5 pi "docker exec pihole pihole allow \
  click.linksynergy.com googleadservices.com www.googleadservices.com"
```

Unbound is only the recursive resolver in this stack; Pi-hole is the filtering
layer that needs the allowlist entries.
