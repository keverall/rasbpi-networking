#!/usr/bin/env python3
"""Raspberry Pi exporter reading CPU temperature from sysfs."""
import os
import sys
import time

from prometheus_client import Gauge, start_http_server

THERMAL_ZONE = "/sys/class/thermal/thermal_zone0/temp"


def read_thermal_zone(path=THERMAL_ZONE):
    try:
        with open(path, "r") as f:
            raw = f.read().strip()
            return float(raw) / 1000.0
    except Exception:
        return None


def main(port):
    g_cpu_temp = Gauge("raspi_cpu_temp_celsius", "CPU temperature in Celsius")

    start_http_server(port)
    interval = 5

    while True:
        temp_val = read_thermal_zone()
        if temp_val is not None:
            g_cpu_temp.set(temp_val)

        time.sleep(interval)


if __name__ == "__main__":
    try:
        port = int(sys.argv[1]) if len(sys.argv) > 1 else int(os.environ.get("PORT", "9779"))
    except Exception:
        port = 9779
    main(port)
