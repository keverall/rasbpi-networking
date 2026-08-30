# HARDENING.md — `pi-networking` (Raspberry Pi 5, Debian 13/trixie)

Operational hardening for the Pi-hole + monitoring box. This is the record of
what was changed on the Pi's OS image and what is still recommended. The
changes below marked **APPLIED** live in the Pi's OS (`/etc`, `/boot`) — they are
**not** part of this git repo and are not auto-applied; this file is the
source of truth for reproducing them after a re-image.

Target host: `pi-networking` @ `192.168.1.5`. Repo lives at
`/home/pi-networking/repos/rasbpi-networking` on the Pi; canonical copy is this
desktop checkout.

---

## Failure modes we were defending against

1. **Became unreachable after a router reset** — the Pi had *no static IP* and
   two network daemons (`NetworkManager` + `systemd-networkd`) fighting over
   the interfaces, so a DHCP change dropped it off the network.
   → Fixed earlier: static `192.168.1.5/24` on `eth0`, `systemd-networkd`
   disabled (see git history / the deployed clone).
2. **SD-card corruption / silent hang** — classic Raspberry Pi killer from
   power loss and write wear.
   → Mitigated below (watchdog, failsafe remount, reduced writes).
3. **Lockout / brute force** — SSH password auth left enabled.
   → Fixed below (key-only SSH).

---

## APPLIED (safe, offline — no packages required)

### 0. Boot robustness (fixes emergency mode / no-network)
- `/etc/fstab` `/mnt/ssd` line: added `nofail,x-systemd.device-timeout=30s`. An external
  SSD with no `nofail` dropped the Pi to **emergency mode** when unplugged or slow to
  spin up; now it is optional and time-bounded.
- `NetworkManager` was **enabled** in `multi-user.target.wants` (it was not enabled;
  after `systemd-networkd` was disabled earlier, the Pi would otherwise boot with *no*
  network manager). NM owns `eth0` (static `192.168.1.5`). `wlan0`
  (`CommunityFibre10Gb_714FC`) autoconnect was disabled
  (`nmcli connection modify "CommunityFibre10Gb_714FC" connection.autoconnect no`) so the
  Pi keeps a single default route via `eth0` and avoids the dual-gateway conflict.

### 1. Hardware watchdog (auto-reboot on hang)
- `/boot/config.txt` (Pi boot partition):
  ```ini
  dtparam=watchdog=on
  ```
- `/etc/systemd/system.conf`:
  ```ini
  RuntimeWatchdogSec=30
  ```
  systemd pets the hardware watchdog; if it stops for 30s the Pi reboots.
  No `watchdog` package needed — systemd's built-in support is used.
  **Caveat:** if the Pi appears to reboot in a loop (truly hung, e.g. a stalled mount),
  the watchdog is firing — revert `RuntimeWatchdogSec=30` in `/etc/systemd/system.conf`
  and `dtparam=watchdog=on` in `config.txt` to recover.

### 2. Kernel panic → reboot
- `/etc/sysctl.d/99-hardening.conf`:
  ```sysctl
  kernel.panic = 10
  kernel.panic_on_oops = 1
  vm.swappiness = 1
  ```
  (`vm.swappiness=1`: the Pi uses `zram` swap in RAM, so keep paging to a minimum.)

### 3. SSH key-only
- `/etc/ssh/sshd_config`:
  ```ssh
  PermitRootLogin prohibit-password
  PubkeyAuthentication yes
  PasswordAuthentication no
  KbdInteractiveAuthentication no
  ```
  The `keverall` user already has keys in `~/.ssh/authorized_keys`, so this
  does not lock anyone out. `root` has no key → stays disabled.

### 4. SD failsafe
- `/etc/fstab` root line:
  ```fstab
  PARTUUID=0ca05afd-02  /  ext4  defaults,noatime,errors=remount-ro  0  1
  ```
  A detected corruption remounts read-only instead of wedging the box.

All of the above take effect on the next **reboot**.

---

## VERIFY AFTER REBOOT

```bash
ls /dev/watchdog                 # should exist (watchdog dtparam active)
systemctl show -p RuntimeWatchdogUSec   # should report 30s
cat /proc/sys/kernel/panic       # should be 10
cat /etc/ssh/sshd_config | grep -iE 'PasswordAuthentication|PermitRootLogin'
mount | grep ' / '                # should show errors=remount-ro
```
Test an **SSH key** login before trusting password-off.

---

## RECOMMENDED (not yet done)

### High value
- **Migrate the OS to the SSD.** The Pi has an unused SSD mounted at `/mnt/ssd`;
  booting from USB SSD instead of the SD card is the single biggest protection
  against SD death. Clone rootfs → SSD, point bootloader/cmdline `root=` at the
  SSD PARTUUID.
- **Router DHCP reservation** for `192.168.1.5` (belt-and-suspenders with the
  static IP) so the address is stable even if DHCP reassigned.
- **Bind Pi-hole explicitly** to `192.168.1.5` (it currently listens on all
  interfaces — see `listeningMode = "ALL"` in `pihole.toml`; revisit whether
  `LOCAL` is safer now that the IP is static).

### Nice to have
- `unattended-upgrades` for crowdsec / Pi-hole security patches.
- `fail2ban` (a guide already lives in the repo) for SSH/HTTP brute-force.
- Bound journald SD writes: in `/etc/systemd/journald.conf` set
  `Storage=volatile` (loses logs on reboot) or `SystemMaxUse=32M`.
- Keep UFW as-is (already enables with a sane ruleset); review rules if the
  listening interface changes.

---

## Notes
- These OS changes are intentionally **outside git**; this document is the
  reproduction record. If the Pi is re-imaged, re-apply the APPLIED section.
- The Pi-hole config files (`pihole.toml`, `dnsmasq.conf`) and runtime data
  (`kuma.db*`, `unbound/*.pid`) are git-ignored (see `.gitignore`) so the
  working tree stays clean — FTL rewrites them at runtime.
