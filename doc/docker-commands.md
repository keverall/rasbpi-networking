# docker commands

docker compose -f pi-hole/docker-compose.yml ps --services --filter status=running

docker run --rm local/unbound_exporter:latest --help

Usage of /usr/local/bin/unbound_exporter:
  -unbound.ca string
        Unbound server certificate. (default "/etc/unbound/unbound_server.pem")
  -unbound.cert string
        Unbound client certificate. (default "/etc/unbound/unbound_control.pem")
  -unbound.host string
        Unix or TCP address of Unbound control socket. (default "tcp://localhost:8953")
  -unbound.key string
        Unbound client key. (default "/etc/unbound/unbound_control.key")
  -web.health-path string
        Path under which to expose healthcheck. (default "/_healthz")
  -web.listen-address string
        Address to listen on for web interface and telemetry. (default ":9167")
  -web.telemetry-path string
        Path under which to expose metrics. (default "/metrics")

docker compose -f pi-hole/docker-compose.yml ps (service status/ports)
docker compose -f pi-hole/docker-compose.yml logs unbound_exporter --tail 200 (exporter errors)
From inside the exporter container: connectivity tests (nc -4/-6 to unbound:8953 and ::1:8953) and process cmdline/env
From inside the unbound container: printed /etc/unbound/unbound.conf

docker compose -f pi-hole/docker-compose.yml logs unbound_exporter --tail 120

docker compose -f pi-hole/docker-compose.yml up -d --build && sleep 4 && docker compose -f pi-hole/docker-compose.yml ps && docker compose -f pi-hole/docker-compose.yml logs unbound --tail 200 && docker compose -f pi-hole/docker-compose.yml logs unbound_exporter --tail 200

docker compose -f pi-hole/docker-compose.yml run --rm unbound sh -c 'cat /opt/unbound/etc/unbound/unbound.conf || true; echo ---; ls -la /opt/unbound/etc/unbound || true'

docker compose -f pi-hole/docker-compose.yml up -d --build && sleep 4 && docker compose -f pi-hole/docker-compose.yml ps && docker compose -f pi-hole/docker-compose.yml logs unbound --tail 200 && docker compose -f pi-hole/docker-compose.yml logs unbound_exporter --tail 200

docker compose -f pi-hole/docker-compose.yml run --rm unbound sh -c 'cat /opt/unbound/etc/unbound/unbound.conf || true; echo ---; ls -la /opt/unbound/etc/unbound || true'

docker compose -f pi-hole/docker-compose.yml up -d --build && sleep 4 && docker compose -f pi-hole/docker-compose.yml ps && docker compose -f pi-hole/docker-compose.yml logs unbound --tail 200 && docker compose -f pi-hole/docker-compose.yml logs unbound_exporter --tail 200

docker run --rm mvance/unbound-rpi:latest cat /unbound.sh

docker compose -f pi-hole/docker-compose.yml run --rm unbound sh -c 'grep -R "/etc/unbound/unbound_server.pem" /opt/unbound/etc/unbound /etc/unbound || true; echo "--- /opt/unbound/etc/unbound/unbound.conf ---"; sed -n "1,200p" /opt/unbound/etc/unbound/unbound.conf || true; echo "--- /etc/unbound/unbound.conf ---"; sed -n "1,200p" /etc/unbound/unbound.conf || true; echo "--- ls -la /opt/unbound/etc/unbound ---"; ls -la /opt/unbound/etc/unbound || true; echo "--- ls -la /etc/unbound ---"; ls -la /etc/unbound || true'

docker compose -f pi-hole/docker-compose.yml logs unbound --tail 300



chmod +x pi-hole/unbound/entrypoint.sh || true

echo '=== re-create unbound container to pick up new entrypoint file mount ==='
# remove container then recreate with compose up -d to pick up changed compose file
docker compose -f pi-hole/docker-compose.yml rm -sf unbound || true
# Give Docker a moment
sleep 1
# Start just the unbound service
docker compose -f pi-hole/docker-compose.yml up -d unbound || true
sleep 1

echo; echo '=== docker ps (filter unbound) ==='
docker ps --filter name=unbound --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}' || true

echo; echo '=== docker logs unbound (last 200) ==='
docker logs --tail 200 unbound || true

echo; echo '=== check exporter logs (last 200) ==='
docker logs --tail 200 pi-hole-unbound_exporter-1 || true


=== unbound NetworkSettings ===
{"SandboxID":"abc15d6eea69a732af1b5bf9945cdca9da101caed2b7d9cfd4382244516e342b","SandboxKey":"/var/run/docker/netns/abc15d6eea69","Ports":{"53/tcp":null,"53/udp":null,"5335/tcp":[{"HostIp":"127.0.0.1","HostPort":"5335"}],"5335/udp":[{"HostIp":"127.0.0.1","HostPort":"5335"}],"8953/tcp":[{"HostIp":"127.0.0.1","HostPort":"8953"}],"8953/udp":[{"HostIp":"127.0.0.1","HostPort":"8953"}]},"Networks":{"pi-hole_default":{"IPAMConfig":null,"Links":null,"Aliases":["unbound","unbound"],"DriverOpts":null,"GwPriority":0,"NetworkID":"d87583c8b322274a9805512145bd3113a6174afe240adef851aedb7da4d9722c","EndpointID":"19323f6670d011b1e3559f9cce7b4b67103274c0ac46e4ee480d08f5db9971c5","Gateway":"172.18.0.1","IPAddress":"172.18.0.2","MacAddress":"ee:7e:6f:b6:9a:4e","IPPrefixLen":16,"IPv6Gateway":"","GlobalIPv6Address":"","GlobalIPv6PrefixLen":0,"DNSNames":["unbound","bb8c3b6f23d4"]}}}

=== exporter NetworkSettings ===
{"SandboxID":"3184f116c71b050c22be4088ef7d92fc9dc9478b5884022172c27816e4f5ee92","SandboxKey":"/var/run/docker/netns/3184f116c71b","Ports":{"9167/tcp":[{"HostIp":"127.0.0.1","HostPort":"9167"}]},"Networks":{"pi-hole_default":{"IPAMConfig":null,"Links":null,"Aliases":["pi-hole-unbound_exporter-1","unbound_exporter"],"DriverOpts":null,"GwPriority":0,"NetworkID":"d87583c8b322274a9805512145bd3113a6174afe240adef851aedb7da4d9722c","EndpointID":"89e9bce1726df90e2b47886d41e3735d96603bbe0bd024bb9546415d2179924f","Gateway":"172.18.0.1","IPAddress":"172.18.0.3","MacAddress":"ce:17:00:da:7b:52","IPPrefixLen":16,"IPv6Gateway":"","GlobalIPv6Address":"","GlobalIPv6PrefixLen":0,"DNSNames":["pi-hole-unbound_exporter-1","unbound_exporter","ea719104e74b"]}}}

=== exporter /etc/hosts ===
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::	ip6-localnet
ff00::	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.18.0.3	ea719104e74b

=== exporter /etc/resolv.conf ===
# Generated by Docker Engine.
# This file can be edited; Docker Engine will not make further changes once it
# has been modified.

nameserver 127.0.0.11
search communityfibre.co.uk
options ndots:0

# Based on host file: '/etc/resolv.conf' (internal resolver)
# ExtServers: [host(192.168.1.1) host(2a02:6b60:20:2a00:8269:1aff:fed7:14fc)]
# Overrides: []
# Option ndots from: internal

=== grep unbound hostname in exporter DNS resolution ===
172.18.0.2        unbound  unbound

=== unbound /proc/net/tcp* ports (grep 22F9 hex for 8953) ===
/proc/net/tcp:5:   3: 00000000:22F9 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 1171441 1 00000000d3d95f3e 100 0 0 10 5                   

=== unbound listening fds (/proc/1/fd) ===
ls: cannot read symbolic link '/proc/1/fd/0': Permission denied
ls: cannot read symbolic link '/proc/1/fd/1': Permission denied
ls: cannot read symbolic link '/proc/1/fd/2': Permission denied
ls: cannot read symbolic link '/proc/1/fd/3': Permission denied
ls: cannot read symbolic link '/proc/1/fd/4': Permission denied
ls: cannot read symbolic link '/proc/1/fd/5': Permission denied
ls: cannot read symbolic link '/proc/1/fd/6': Permission denied
ls: cannot read symbolic link '/proc/1/fd/7': Permission denied
ls: cannot read symbolic link '/proc/1/fd/8': Permission denied
ls: cannot read symbolic link '/proc/1/fd/9': Permission denied
ls: cannot read symbolic link '/proc/1/fd/10': Permission denied
ls: cannot read symbolic link '/proc/1/fd/11': Permission denied
ls: cannot read symbolic link '/proc/1/fd/12': Permission denied
ls: cannot read symbolic link '/proc/1/fd/13': Permission denied
ls: cannot read symbolic link '/proc/1/fd/14': Permission denied
ls: cannot read symbolic link '/proc/1/fd/15': Permission denied
ls: cannot read symbolic link '/proc/1/fd/16': Permission denied
ls: cannot read symbolic link '/proc/1/fd/17': Permission denied
ls: cannot read symbolic link '/proc/1/fd/18': Permission denied
ls: cannot read symbolic link '/proc/1/fd/19': Permission denied
ls: cannot read symbolic link '/proc/1/fd/20': Permission denied
ls: cannot read symbolic link '/proc/1/fd/21': Permission denied
ls: cannot read symbolic link '/proc/1/fd/22': Permission denied
ls: cannot read symbolic link '/proc/1/fd/23': Permission denied
ls: cannot read symbolic link '/proc/1/fd/24': Permission denied
ls: cannot read symbolic link '/proc/1/fd/25': Permission denied
ls: cannot read symbolic link '/proc/1/fd/26': Permission denied
ls: cannot read symbolic link '/proc/1/fd/27': Permission denied
ls: cannot read symbolic link '/proc/1/fd/28': Permission denied
ls: cannot read symbolic link '/proc/1/fd/29': Permission denied
total 0
dr-x------ 2 root     root     30 Feb  3 10:19 .
dr-xr-xr-x 9 _unbound _unbound  0 Feb  3 10:16 ..
lrwx------ 1 root     root     64 Feb  3 10:19 0
l-wx------ 1 root     root     64 Feb  3 10:19 1
lrwx------ 1 root     root     64 Feb  3 10:19 10
lrwx------ 1 root     root     64 Feb  3 10:19 11
lrwx------ 1 root     root     64 Feb  3 10:19 12
lrwx------ 1 root     root     64 Feb  3 10:19 13
lrwx------ 1 root     root     64 Feb  3 10:19 14
lrwx------ 1 root     root     64 Feb  3 10:19 15
lrwx------ 1 root     root     64 Feb  3 10:19 16
lrwx------ 1 root     root     64 Feb  3 10:19 17
lrwx------ 1 root     root     64 Feb  3 10:19 18
lrwx------ 1 root     root     64 Feb  3 10:19 19
l-wx------ 1 root     root     64 Feb  3 10:19 2
lrwx------ 1 root     root     64 Feb  3 10:19 20
lrwx------ 1 root     root     64 Feb  3 10:19 21
lrwx------ 1 root     root     64 Feb  3 10:19 22
lrwx------ 1 root     root     64 Feb  3 10:19 23
lrwx------ 1 root     root     64 Feb  3 10:19 24
lr-x------ 1 root     root     64 Feb  3 10:19 25
l-wx------ 1 root     root     64 Feb  3 10:19 26
lrwx------ 1 root     root     64 Feb  3 10:19 27
lr-x------ 1 root     root     64 Feb  3 10:19 28
l-wx------ 1 root     root     64 Feb  3 10:19 29
lrwx------ 1 root     root     64 Feb  3 10:19 3
lrwx------ 1 root     root     64 Feb  3 10:19 4
lrwx------ 1 root     root     64 Feb  3 10:19 5
lrwx------ 1 root     root     64 Feb  3 10:19 6
lrwx------ 1 root     root     64 Feb  3 10:19 7
lrwx------ 1 root     root     64 Feb  3 10:19 8
lrwx------ 1 root     root     64 Feb  3 10:19 9


