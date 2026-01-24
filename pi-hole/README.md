# Pi-hole Docker for Raspberry Pi 5 (arm64)

This folder contains a small Docker setup to build and run a Pi-hole image optimized
for Raspberry Pi 5 (aarch64). It uses the upstream pihole/pihole image as the base
and forces an aarch64 build platform so you get an image tailored to the Pi 5 CPU.

Files:

- [`pi-hole/Dockerfile`](pi-hole/Dockerfile:1) - Dockerfile that pins --platform to linux/arm64 and adds build metadata and a lightweight HEALTHCHECK.
- [`pi-hole/docker-compose.yml`](pi-hole/docker-compose.yml:1) - Compose file with recommended volumes, ports and environment variables.
- [`pi-hole/.env.example`](pi-hole/.env.example:1) - Example env file; copy to `.env` and edit.

Quick start (recommended on the Pi itself):

1. Copy the example env file:

   cp .env.example .env

2. Edit `.env` and set `SERVERIP` to your Pi's IP and choose a `WEBPASSWORD`.

3. Build the image (recommended using buildx to ensure correct platform):

   docker buildx build --platform linux/arm64 -t local/pihole:arm64 .

   Or use docker-compose to build and run:

   docker compose up -d --build

Notes and recommendations:

- Run this on your Raspberry Pi 5 running a 64-bit OS (e.g., Raspberry Pi OS 64-bit or Ubuntu Server for Raspberry Pi).
- For DNS performance and to avoid conflicts with the host resolver, consider running Pi-hole on its own network or ensure port 53 is available.
- Persisted data is stored in `./etc-pihole` and `./etc-dnsmasq.d` relative to this folder.
- If you prefer to use the official multi-arch image directly (no local build), you can skip the build and use `image: pihole/pihole:latest` in the compose file.

Dynamic SERVERIP (DHCP/mobile setups)

If your Raspberry Pi obtains a dynamic IP via DHCP, you can auto-detect and populate
the `SERVERIP` value used by Pi-hole before starting the container. From the
`pi-hole` directory run:

1. Make the helper executable if needed:

   chmod +x generate-env.sh

2. Run the script to produce `.env` with the detected IP:

   ./generate-env.sh

This will copy `[`pi-hole/.env.example`](pi-hole/.env.example:1)` to `[`pi-hole/.env`](pi-hole/.env:1)` and replace `SERVERIP` with the detected IP address.

After `.env` is created, proceed with the build and run steps in this README.

Security:

- Choose a strong `WEBPASSWORD` and keep the Pi OS up to date.
- Exposing web UI to the internet is not recommended without additional protections.
