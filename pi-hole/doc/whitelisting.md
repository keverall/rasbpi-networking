# whitelisting sites

## commands

```shell
ssh -o ConnectTimeout=5 pi "docker exec pihole pihole allow track.webgains.com" 2>&1 | head -20
```

## TopCashback affiliate redirects

TopCashback/Rakuten affiliate links use `click.linksynergy.com` as their redirect
host. Allowlist the host rather than the full URL or its query parameters:

```shell
ssh -o ConnectTimeout=5 pi "docker exec pihole pihole allow click.linksynergy.com"
```

Unbound is only the recursive resolver in this stack; Pi-hole is the filtering
layer that needs the allowlist entry.
