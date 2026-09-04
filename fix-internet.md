# fix internet


## Recovery (if internet dies again)

```bash
sudo nmcli connection down wg-CH-UK-2 wg-CH-US-3 wg-is-uk-1 2>/dev/null  

sudo systemctl restart firewalld  

sudo systemctl restart NetworkManager systemd-resolved  

sudo systemctl restart proton.VPN.service  

sleep 3  

busctl list | grep -E "proton\."

sudo nft flush ruleset  

sudo iptables -F  

sudo ip6tables -F  

protonvpn config set kill-switch off  

ping -c 4 192.168.1.5  

ping -c 4 google.com  

sudo systemctl disable --now proton.VPN.service  

systemctl is-enabled proton.VPN.service  

ping -c 4 google.com  


ssh pi  
```

## Crowdsec goes wonky again then:

Symptom after a `crowdsec` apt upgrade: `sudo cscli hub list` prints dozens of
`Ignoring file /etc/crowdsec/parsers|scenarios/...: lstat /var/lib/crowdsec/hub/...: no such file or directory`, and CrowdSec silently stops parsing anything.

Root cause: the 1.8.x package no longer bundles hub content — it is downloaded
separately by `cscli hub update`/`upgrade` (run by the postinst's `hubupdate.sh`
and the daily `crowdsec-hubupdate.timer`). The postinst **skips** that download
when it thinks `acquis.yaml` is user-modified, so the parsers/scenarios ship as
dangling symlinks and never get their backing files.

The fix that is already in place (survives reboots, lives on the Pi's filesystem,
not in this repo):
- collections are installed in cscli's `hub_dir` = `/etc/crowdsec/hub/`
  (kept current automatically by `crowdsec-hubupdate.timer`, already `enabled`).
- a manual bridge symlink `/usr/share/crowdsec/hub -> /etc/crowdsec/hub` so the
  package's enabled symlinks (`/etc/crowdsec/parsers|scenarios/*` ->
  `/var/lib/crowdsec/hub/*` -> `/usr/share/crowdsec/hub/*`) resolve to real files.

If a future upgrade breaks it again:

1. Re-establish the bridge (harmless if it already exists):
   ```bash
   sudo ln -sfn /etc/crowdsec/hub /usr/share/crowdsec/hub
   ```
2. Re-download + re-enable everything already installed:
   ```bash
   sudo cscli hub update
   sudo cscli hub upgrade
   sudo cscli parsers install crowdsecurity/whitelists   # s02-enrich/whitelists.yaml
   ```
3. Apply without a full restart, then confirm:
   ```bash
   sudo systemctl reload crowdsec.service
   sudo cscli hub list     # must show 0 "Ignoring file" warnings
   ```

Full re-install fallback (the exact set the package expects):
```bash
sudo cscli collections install crowdsecurity/linux crowdsecurity/sshd crowdsecurity/nginx crowdsecurity/apache2 crowdsecurity/base-http-scenarios crowdsecurity/http-cve crowdsecurity/whitelist-good-actors
```

Caveat: if a future `crowdsec` package starts shipping `/usr/share/crowdsec/hub`
as a *real* directory, it will collide with the bridge symlink. In that case
remove the symlink (`sudo rm /usr/share/crowdsec/hub`), let the package own that
dir, then run the `cscli hub update`/`upgrade` steps above — cscli's real store
remains `/etc/crowdsec/hub` regardless.

If you want to confirm it's ingesting, give it a moment then check acquisition:

```bash
sudo cscli metrics
```

## Root cause

`proton.VPN.service` may be disabled, but the Proton VPN app created 3
NetworkManager WireGuard connections that have `autoconnect = yes`:

```
wg-CH-UK-2
wg-CH-US-3
wg-is-uk-1
```

NetworkManager starts these on boot regardless of the systemd service. All
three try to grab the default route and knock out real internet. Disabling
`proton.VPN.service` alone does NOT stop this.

## PERMANENT FIX (run once, needs sudo)

Stop any active tunnels, disable auto-connect on the 3 WireGuard profiles
so they never start on boot, and turn OFF the kill switch (it injects
persistent iptables/nft rules that block all traffic when the VPN is down):

```bash
# disable auto-connect on the 3 WireGuard profiles so they never start on boot
sudo nmcli connection modify wg-CH-UK-2 connection.autoconnect no
sudo nmcli connection modify wg-CH-US-3 connection.autoconnect no
sudo nmcli connection modify wg-is-uk-1 connection.autoconnect no
# stop + keep the daemon disabled
sudo systemctl disable --now proton.VPN.service
# flush any leftover firewall rules the kill switch left behind
sudo nft flush ruleset
sudo iptables -F
sudo ip6tables -F
```

### THE REAL PERMANENT FIX — mask the Proton daemon

`connection.autoconnect no` on the 3 WireGuard profiles is NOT enough. The
`proton.VPN.service` daemon (once running) bypasses NetworkManager's
`autoconnect` flag and explicitly brings the profiles up itself via its own
"connect on launch / auto-connect" behaviour. That is why the connections keep
coming back and killing the default route. Mask the service so nothing — boot,
the GUI app, or a D-Bus activation — can ever start it automatically:

```bash
# kill it if it is somehow running, then mask so it cannot auto-start
sudo systemctl stop proton.VPN.service
sudo systemctl disable proton.VPN.service
sudo systemctl mask proton.VPN.service

# confirm
systemctl is-enabled proton.VPN.service   # -> masked
systemctl is-active  proton.VPN.service   # -> inactive
nmcli -g NAME,AUTOCONNECT connection show | grep -E "wg-"
# every wg-* line should show 'no'
```

Masking is the guarantee: even if the Proton GUI is opened, the daemon can't
start, so it can't steal the default route.

### Disable the kill switch

The kill switch injects persistent iptables/nft rules that block ALL traffic
when the VPN is down. `protonvpn config set kill-switch off` requires an active
Proton session and often errors ("An unexpected error occurred"), so set it by
editing the config files directly instead:

```bash
# user-level config (CLI/GUI read this)
sed -i 's/"killswitch": 1/"killswitch": 0/' ~/.config/Proton/VPN/settings.json
# root daemon config (authoritative when the VPN is actually connected)
sudo sed -i 's/"killswitch": 1/"killswitch": 0/' /root/.config/Proton/VPN/settings.json 2>/dev/null \
  || echo "root config absent — daemon will use its default (off)"
# confirm
grep killswitch ~/.config/Proton/VPN/settings.json
sudo grep killswitch /root/.config/Proton/VPN/settings.json 2>/dev/null
```

If you are signed in and the CLI works, the equivalent is:
```bash
sudo systemctl start proton.VPN.service
protonvpn config set kill-switch off
sudo systemctl disable --now proton.VPN.service
```

Verify nothing auto-connects:

```bash
nmcli -g NAME,AUTOCONNECT connection show | grep -E "wg-|proton"
# every wg-* line should now show 'no'
systemctl is-enabled proton.VPN.service   # -> disabled
```

Also turn OFF "Auto-connect on boot" inside the Proton VPN GUI/CLI if it was
enabled — that setting re-writes `autoconnect=yes` back onto the connection.

## Connect manually when you want the VPN

### CLI (choose one profile)

Because the daemon is masked, unmask + start it first, then connect:

```bash
sudo systemctl unmask proton.VPN.service
sudo systemctl start proton.VPN.service
protonvpn connect          # interactive profile picker
# or bring a specific NM profile up directly:
nmcli connection up wg-CH-UK-2
```

To disconnect:

```bash
protonvpn disconnect
# or:
nmcli connection down wg-CH-UK-2
# then re-mask so it can't auto-start again and break internet:
sudo systemctl stop proton.VPN.service
sudo systemctl mask proton.VPN.service
```

### CachyOS NetManager GUI

Open the NetworkManager / NetManager applet, select the WireGuard profile
(e.g. `wg-CH-UK-2`) and click **Connect**. It will NOT auto-connect on boot
anymore, but you can still toggle it on/off whenever you like. (If you want a
single profile to reconnect automatically later, re-enable "Connect
automatically" for just that one connection — not all three.)
