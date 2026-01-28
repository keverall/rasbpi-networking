#!/usr/bin/env bash
set -euo pipefail

# generate-env.sh
# Detect the primary IP address of the Raspberry Pi and write it to pi-hole/.env
# Usage: run this script from the pi-hole directory: ./generate-env.sh

OUT=.env
EXAMPLE=.env.example

if [ ! -f "$EXAMPLE" ]; then
  echo "Missing $EXAMPLE; cannot generate $OUT" >&2
  exit 1
fi

# Detect primary IPv4 address used for outbound traffic
# Uses `ip route get` for reliable selection of the primary interface.
detect_ip() {
  ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++){if($i=="src"){print $(i+1); exit}}}' || true
  # Fallback to hostname -I
  if [ -z "${REPLY:-}" ]; then
    hostname -I | awk '{print $1}'
  fi
}

detected_ip=$(detect_ip)

if [ -z "$detected_ip" ]; then
  echo "Could not detect an IP address. Please set SERVERIP in $OUT manually." >&2
  exit 2
fi

echo "Detected IP: $detected_ip"

# Create .env from example then replace SERVERIP line
cp "$EXAMPLE" "$OUT"

if grep -qE '^SERVERIP=' "$OUT"; then
  sed -i.bak -E "s/^SERVERIP=.*/SERVERIP=$detected_ip/" "$OUT"
else
  echo "SERVERIP=$detected_ip" >> "$OUT"
fi

echo "Wrote $OUT with SERVERIP=$detected_ip"

