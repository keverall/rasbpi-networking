#!/usr/bin/env bash
set -Eeuo pipefail

diagnostic_log="/tmp/restore-connectivity-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee "$diagnostic_log") 2>&1

step() {
    printf '\n==> %s\n' "$1"
}

printf 'Connectivity recovery started: %s\n' "$(date --iso-8601=seconds)"
printf 'Diagnostic log: %s\n' "$diagnostic_log"

step "Stopping Proton WireGuard connections"
for connection in wg-CH-UK-2 wg-CH-US-3 wg-is-uk-1; do
    sudo nmcli connection modify "$connection" connection.autoconnect no 2>/dev/null || true
    if sudo nmcli connection down "$connection" 2>/dev/null; then
        printf 'Stopped %s\n' "$connection"
    else
        printf 'Already down or unavailable: %s\n' "$connection"
    fi
done

step "Disabling the Proton VPN service"
sudo systemctl disable --now proton.VPN.service || true
sudo systemctl mask proton.VPN.service
service_state=$(systemctl is-enabled proton.VPN.service 2>&1 || true)
printf 'proton.VPN.service: %s\n' "$service_state"

step "Disabling the Proton kill switch"
user_config="$HOME/.config/Proton/VPN/settings.json"
if [[ -f "$user_config" ]]; then
    sed -E -i.bak 's/"killswitch"[[:space:]]*:[[:space:]]*1/"killswitch": 0/' "$user_config"
    printf 'Updated %s\n' "$user_config"
fi

root_config=/root/.config/Proton/VPN/settings.json
if sudo test -f "$root_config"; then
    sudo sed -E -i.bak 's/"killswitch"[[:space:]]*:[[:space:]]*1/"killswitch": 0/' "$root_config"
    printf 'Updated %s\n' "$root_config"
else
    printf 'No root Proton configuration found\n'
fi

if command -v protonvpn >/dev/null 2>&1; then
    if protonvpn config set kill-switch off; then
        printf 'Proton kill switch disabled\n'
    else
        printf 'Warning: Proton CLI could not change the kill-switch setting\n' >&2
    fi
else
    printf 'Warning: protonvpn CLI is not installed\n' >&2
fi

step "Clearing stale firewall rules"
sudo nft flush ruleset
sudo iptables -F
sudo ip6tables -F

step "Restarting NetworkManager and systemd-resolved"
sudo systemctl restart NetworkManager systemd-resolved

step "Checking connectivity to the Pi"
ping -c 4 192.168.1.5

step "Checking internet connectivity"
ping -c 4 google.com

step "Verifying the kill switch stayed cleared"
if sudo nft list ruleset | grep -qi 'killswitch\|proton'; then
    printf 'Warning: VPN-related firewall rules remain; inspect %s\n' "$diagnostic_log" >&2
else
    printf 'No Proton kill-switch rules detected\n'
fi

printf '\nConnectivity restored. Diagnostic log: %s\n' "$diagnostic_log"
