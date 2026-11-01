#!/usr/bin/env python3
"""
wifi_helper.py - Secure Wi-Fi credential connection helper for Quickshell.
Complies with CWE-214: Never exposes plaintext passwords in command-line arguments (/proc/*/cmdline).
"""
import os
import sys
import signal
import ctypes
import subprocess

# Anti-zombie protection: bind lifecycle to parent process
try:
    PR_SET_PDEATHSIG = 1
    libc = ctypes.CDLL("libc.so.6")
    libc.prctl(PR_SET_PDEATHSIG, signal.SIGTERM)
except Exception:
    pass


def connect_wifi(ssid, password=None):
    if not ssid:
        return 1

    if not password:
        cmd = ["nmcli", "device", "wifi", "connect", ssid]
        return subprocess.run(cmd).returncode

    # Pipe secret into nmcli --ask via stdin so it never appears in /proc/*/cmdline
    cmd = ["nmcli", "--ask", "device", "wifi", "connect", ssid]
    try:
        proc = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        stdout, stderr = proc.communicate(input=f"{password}\n")
        return proc.returncode
    except Exception as e:
        sys.stderr.write(f"wifi_helper error: {e}\n")
        return 1


def main():
    if len(sys.argv) < 2:
        sys.stderr.write("Usage: wifi_helper.py <SSID>\n")
        sys.exit(1)

    ssid = sys.argv[1]
    # Securely retrieve password from environment or stdin
    password = os.environ.get("CLAVIS_WIFI_SECRET")
    if not password and not sys.stdin.isatty():
        try:
            line = sys.stdin.readline().strip("\r\n")
            if line:
                password = line
        except Exception:
            pass

    code = connect_wifi(ssid, password)
    sys.exit(code)


if __name__ == "__main__":
    main()
