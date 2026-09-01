# fix internet

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

```bash
protonvpn connect          # interactive profile picker
# or bring a specific NM profile up directly:
nmcli connection up wg-CH-UK-2
```

To disconnect:

```bash
protonvpn disconnect
# or:
nmcli connection down wg-CH-UK-2
```

### CachyOS NetManager GUI

Open the NetworkManager / NetManager applet, select the WireGuard profile
(e.g. `wg-CH-UK-2`) and click **Connect**. It will NOT auto-connect on boot
anymore, but you can still toggle it on/off whenever you like. (If you want a
single profile to reconnect automatically later, re-enable "Connect
automatically" for just that one connection — not all three.)

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
ssh pi
sudo systemctl disable --now proton.VPN.service
systemctl is-enabled proton.VPN.service
ping -c 4 google.com
```
