# whitelisting sites

## commands

```shell
ssh -o ConnectTimeout=5 pi "docker exec pihole pihole allow track.webgains.com" 2>&1 | head -20
```
