#!/bin/bash
set -euo pipefail

sudo nmcli connection down wg-CH-UK-2 wg-CH-US-3 wg-is-uk-1 2>/dev/null  

sudo nft flush ruleset

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
