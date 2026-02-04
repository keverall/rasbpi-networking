# Added cAdvisor and a minimal raspi_exporter (vcgencmd wrapper) 

and integrated them with Prometheus/Grafana. Changes applied, containers started, and endpoints verified.

- Modified the Compose file to add services: cAdvisor and raspi_exporter (plus node_exporter was already added earlier): [`pi-hole/docker-compose.yml OR yaml()`](pi-hole/docker-compose.yml:130).
- Added the raspi exporter image build and script:
  - [`pi-hole/raspi-exporter/Dockerfile OR dockerfile()`](pi-hole/raspi-exporter/Dockerfile:1)
  - [`pi-hole/raspi-exporter/raspi_exporter.py OR python()`](pi-hole/raspi-exporter/raspi_exporter.py:1)
- Updated Prometheus scrape config to collect metrics from node_exporter, cAdvisor and raspi_exporter: [`pi-hole/prometheus/prometheus.yml OR yaml()`](pi-hole/prometheus/prometheus.yml:17).

Commands 

- Brought node_exporter up: [`docker compose -f pi-hole/docker-compose.yml up -d node_exporter OR bash()`](pi-hole/docker-compose.yml:99)
- Built/started cAdvisor and raspi_exporter: [`docker compose -f pi-hole/docker-compose.yml up -d --no-deps --build raspi_exporter cadvisor OR bash()`](pi-hole/docker-compose.yml:141)
- Verified containers: [`docker ps OR bash()`](pi-hole/docker-compose.yml:141)
- Queried metrics endpoints: [`curl 127.0.0.1:9100/metrics OR bash()`](pi-hole/docker-compose.yml:99), [`curl 127.0.0.1:8080/metrics OR bash()`](pi-hole/docker-compose.yml:130), [`curl 127.0.0.1:9779/metrics OR bash()`](pi-hole/raspi-exporter/raspi_exporter.py:1)

Verification (selected evidence)

- `docker ps` shows the new containers are running (e.g. `cadvisor`, `raspi_exporter`, `node_exporter`).
- cAdvisor metrics are available at 127.0.0.1:8080/metrics and returned Prometheus metrics (container/cgroup stats).
- raspi_exporter is serving metrics at 127.0.0.1:9779/metrics; it exposes the gauge `raspi_vcgencmd_present 1` indicating the host `vcgencmd` binary is available in the container.

Notes & caveats
- raspi_exporter relies on the host's `vcgencmd` to produce CPU/GPU temperature, voltage, frequency and throttling flags. If you run on a genuine Raspberry Pi and `vcgencmd` returns values on the host, the exporter will expose them. If metrics are zero, check `vcgencmd` on the host first.
- Some setups require access to `/dev/vchiq` for video core info. I initially attempted to add `/dev/vchiq` and saw it absent on this host; if your Pi exposes it, uncomment the `devices` mapping in [`pi-hole/docker-compose.yml OR yaml()`](pi-hole/docker-compose.yml:141) to pass it into the container.
- cAdvisor requires read access to container runtime state. The compose entry mounts `/var/lib/docker` — adjust if you run containerd/podman or have a different Docker data root.
- All services are run with host networking for simplicity (Prometheus scrapes `127.0.0.1`). If you need tighter network isolation, expose the ports on loopback only and update Prometheus accordingly.
- cAdvisor is feature-rich and exposes a lot of metrics — keep it behind your LAN or firewall to avoid exposing container metadata.

How to revert
- Remove the `cadvisor` and `raspi_exporter` service blocks from [`pi-hole/docker-compose.yml OR yaml()`](pi-hole/docker-compose.yml:130) and recreate the services:
  - `docker compose -f pi-hole/docker-compose.yml down cadvisor raspi_exporter` and then `docker compose -f pi-hole/docker-compose.yml up -d --no-deps node_exporter` (or similar).

Outcome
- cAdvisor and a minimal raspi_exporter were added to your stack, Prometheus was configured to scrape them, containers were started, and metric endpoints are reachable on the host. The raspi exporter reports `vcgencmd` presence; temperature/voltage/frequency/throttle metrics will appear when `vcgencmd` can return values on the host.