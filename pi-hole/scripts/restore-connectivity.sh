#!/usr/bin/env bash
set -Eeuo pipefail

step() {
    printf '\n==> %s\n' "$1"
}

step "Stopping Proton WireGuard connections"
for connection in wg-CH-UK-2 wg-CH-US-3 wg-is-uk-1; do
    if sudo nmcli connection down "$connection" 2>/dev/null; then
        printf 'Stopped %s\n' "$connection"
    else
        printf 'Already down or unavailable: %s\n' "$connection"
    fi
done

step "Disabling the Proton VPN service"
sudo systemctl disable --now proton.VPN.service || true
service_state=$(systemctl is-enabled proton.VPN.service 2>&1 || true)
printf 'proton.VPN.service: %s\n' "$service_state"

step "Disabling the Proton kill switch"
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

printf '\nConnectivity restored.\n'
