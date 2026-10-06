#!/usr/bin/env python3
"""
sysmon_stream.py - Lightweight Linux /proc/stat, /proc/meminfo, thermal, and statvfs provider
for Clavis SystemMonitorService (schemaVersion 1).
"""
import sys
import time
import json
import os
import glob

def read_cpu():
    try:
        with open("/proc/stat", "r") as f:
            line = f.readline()
        fields = [float(x) for x in line.split()[1:8]]
        idle = fields[3] + fields[4]
        total = sum(fields)
        return idle, total
    except Exception:
        return 0, 1

def read_mem():
    try:
        mem_total = 1
        mem_avail = 1
        with open("/proc/meminfo", "r") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    mem_total = int(line.split()[1]) * 1024
                elif line.startswith("MemAvailable:"):
                    mem_avail = int(line.split()[1]) * 1024
        used = max(0, mem_total - mem_avail)
        usage_pct = (used / mem_total) * 100 if mem_total > 0 else 0
        return usage_pct, used, mem_total
    except Exception:
        return 0, 0, 1

def read_temp():
    try:
        # Check thermal zones
        zones = glob.glob("/sys/class/thermal/thermal_zone*/temp")
        if zones:
            with open(zones[0], "r") as f:
                return float(f.read().strip()) / 1000.0
    except Exception:
        pass
    return 40.0

def read_disk():
    try:
        st = os.statvfs("/")
        total = st.f_blocks * st.f_frsize
        avail = st.f_bavail * st.f_frsize
        used = max(0, total - avail)
        pct = (used / total) * 100.0 if total > 0 else 0.0
        return [{
            "mountPoint": "/",
            "filesystem": "root",
            "totalBytes": total,
            "usedBytes": used,
            "availableBytes": avail,
            "usagePercent": round(pct, 1)
        }]
    except Exception:
        return []

prev_idle, prev_total = read_cpu()
seq = 0

# Emit initial values immediately
now_idle, now_total = read_cpu()
prev_idle, prev_total = now_idle, now_total

parent_pid = os.getppid()

while True:
    if os.getppid() != parent_pid or os.getppid() <= 1:
        sys.exit(0)
    time.sleep(2.0)
    now_idle, now_total = read_cpu()
    d_idle = now_idle - prev_idle
    d_total = now_total - prev_total
    prev_idle, prev_total = now_idle, now_total

    cpu_pct = 0.0
    if d_total > 0:
        cpu_pct = max(0.0, min(100.0, (1.0 - (d_idle / d_total)) * 100.0))

    mem_pct, mem_used, mem_total = read_mem()
    temp_c = read_temp()
    disks = read_disk()

    payload = {
        "schemaVersion": 1,
        "timestampMs": int(time.time() * 1000),
        "sequence": seq,
        "intervalMs": 2000,
        "cpu": {
            "usagePercent": round(cpu_pct, 1),
            "temperatureCelsius": round(temp_c, 1),
            "packageTemperatureCelsius": round(temp_c, 1)
        },
        "memory": {
            "usagePercent": round(mem_pct, 1),
            "usedBytes": mem_used,
            "totalBytes": mem_total
        },
        "network": {
            "downloadBytesPerSecond": 0,
            "uploadBytesPerSecond": 0
        },
        "disks": disks,
        "gpus": [],
        "errors": []
    }
    seq += 1
    sys.stdout.write(json.dumps(payload) + "\n")
    sys.stdout.flush()
