#!/usr/bin/env python3
"""Simple Raspberry Pi exporter that wraps vcgencmd and exposes Prometheus metrics.

Requirements:
- The host's vcgencmd binary should be mounted into the container (e.g. /opt/vc/bin/vcgencmd).
- The container should have access to /dev/vchiq (device) and /opt/vc mounted read-only.

This exporter is intentionally minimal: it calls vcgencmd periodically and exports a
small set of useful gauges (CPU temp, core freq, core volts, throttled flags).
"""
import os
import re
import subprocess
import sys
import time

from prometheus_client import Gauge, start_http_server

VCG_PATHS = [
    "/opt/vc/bin/vcgencmd",
    "/usr/bin/vcgencmd",
    "/usr/local/bin/vcgencmd",
    "/bin/vcgencmd",
]


def find_vcgencmd():
    """Locate the vcgencmd binary on the system.

    Returns:
        str or None: Path to the executable if found, None otherwise.
    """
    for p in VCG_PATHS:
        if os.path.exists(p) and os.access(p, os.X_OK):
            return p
    return None


def run_vcgencmd(path, args):
    """Execute a vcgencmd command.

    Args:
        path (str): Path to the vcgencmd binary.
        args (list): Arguments to pass to vcgencmd.

    Returns:
        str or None: Decoded command output, or None on failure.
    """
    try:
        out = subprocess.check_output([path] + args, stderr=subprocess.DEVNULL)
        return out.decode().strip()
    except Exception:
        return None


def parse_temp(s):
    """Extract temperature value from vcgencmd measure_temp output.

    Args:
        s (str): Raw output string (e.g., "temp=42.1'C").

    Returns:
        float or None: Temperature in Celsius, or None if parsing failed.
    """
    if not s:
        return None
    m = re.search(r"([-+]?[0-9]*\.?[0-9]+)", s)
    return float(m.group(1)) if m else None


def parse_volts(s):
    """Extract voltage value from vcgencmd measure_volts output.

    Args:
        s (str): Raw output string (e.g., "volt=1.2000V").

    Returns:
        float or None: Voltage in volts, or None if parsing failed.
    """
    if not s:
        return None
    m = re.search(r"([-+]?[0-9]*\.?[0-9]+)", s)
    return float(m.group(1)) if m else None


def parse_freq(s):
    """Extract frequency value from vcgencmd measure_clock output.

    Args:
        s (str): Raw output string (e.g., "frequency(arm)=1800000000").

    Returns:
        int or None: Frequency in Hz, or None if parsing failed.
    """
    if not s:
        return None
    m = re.search(r"([0-9]+)", s)
    return int(m.group(1)) if m else None


def parse_throttled(s):
    """Extract throttled flags from vcgencmd get_throttled output.

    Args:
        s (str): Raw output string (e.g., "throttled=0x50005").

    Returns:
        int: Raw throttled flags as integer, or 0 if parsing failed.
    """
    if not s:
        return 0
    m = re.search(r"0x[0-9a-fA-F]+", s)
    if m:
        return int(m.group(0), 16)
    if s.startswith("throttled="):
        try:
            return int(s.split("=")[1], 16)
        except Exception:
            return 0
    return 0


def main(port):
    """Main loop: poll vcgencmd and expose metrics via Prometheus.

    Args:
        port (int): HTTP port to serve metrics on.
    """
    vcgencmd_path = find_vcgencmd()

    g_vcgencmd = Gauge("raspi_vcgencmd_present", "1 if vcgencmd is available")
    g_cpu_temp = Gauge("raspi_cpu_temp_celsius", "CPU temperature in Celsius")
    g_core_volts = Gauge("raspi_core_volts", "Core voltage in volts")
    g_core_freq = Gauge("raspi_core_freq_hz", "Core frequency in Hz")
    g_throttled_raw = Gauge("raspi_throttled_raw", "Raw throttled flags (integer)")
    g_throttled_now = Gauge("raspi_throttled_now", "1 if throttled now (derived from get_throttled)")
    g_undervoltage_now = Gauge("raspi_undervoltage_now", "1 if undervoltage now (derived from get_throttled)")

    start_http_server(port)
    interval = 5

    while True:
        vcgencmd_path = find_vcgencmd()
        g_vcgencmd.set(1 if vcgencmd_path else 0)

        if vcgencmd_path:
            temp_out = run_vcgencmd(vcgencmd_path, ["measure_temp"])
            temp_val = parse_temp(temp_out)
            if temp_val is not None:
                g_cpu_temp.set(temp_val)

            volts_out = run_vcgencmd(vcgencmd_path, ["measure_volts"])
            volts_val = parse_volts(volts_out)
            if volts_val is not None:
                g_core_volts.set(volts_val)

            freq_out = run_vcgencmd(vcgencmd_path, ["measure_clock", "arm"])
            freq_val = parse_freq(freq_out)
            if freq_val is not None:
                g_core_freq.set(freq_val)

            thr_out = run_vcgencmd(vcgencmd_path, ["get_throttled"])
            thr_val = parse_throttled(thr_out)
            g_throttled_raw.set(thr_val)
            g_undervoltage_now.set(1 if (thr_val & 0x1) else 0)
            g_throttled_now.set(1 if (thr_val & 0x4) else 0)

        time.sleep(interval)


if __name__ == "__main__":
    try:
        port = int(sys.argv[1]) if len(sys.argv) > 1 else int(os.environ.get("PORT", "9779"))
    except Exception:
        port = 9779
    main(port)
