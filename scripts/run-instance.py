#!/usr/bin/env python3
"""Own exactly one child; no GNOME changes, shared PID files or process-name kills."""
import ctypes
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET


PR_SET_PDEATHSIG = 1

def parent_death():
    parent = os.getppid()
    if ctypes.CDLL(None).prctl(PR_SET_PDEATHSIG, signal.SIGTERM, 0, 0, 0):
        raise RuntimeError("PR_SET_PDEATHSIG failed")
    if parent == 1 or parent != os.getppid():
        os._exit(1)


def run(command):
    with tempfile.TemporaryDirectory(prefix="clavis-fonts-", dir=os.environ.get("XDG_RUNTIME_DIR")) as directory:
        root = ET.Element("fontconfig")
        ET.SubElement(root, "include", ignore_missing="yes").text = "/etc/fonts/fonts.conf"
        for item in os.environ.get("CLAVIS_FONT_DIRS", "").split(":"):
            if item:
                ET.SubElement(root, "dir").text = item
        path = Path(directory) / "fonts.conf"
        ET.ElementTree(root).write(path, encoding="utf-8", xml_declaration=True)
        # Quickshell's built-in handler forks a detached crash GUI and may
        # restart the app outside our lifetime contract. That GUI previously
        # inherited an already-deleted fonts.conf. Keep fatal stderr/native
        # coredumps and a nonzero status, but let this supervisor own shutdown.
        env = dict(os.environ, FONTCONFIG_FILE=str(path), QS_DISABLE_CRASH_HANDLER="1")
        child = subprocess.Popen(command, env=env, preexec_fn=parent_death)
        def stop(signum, _frame):
            if child.poll() is None:
                child.send_signal(signum)
        signal.signal(signal.SIGINT, stop)
        signal.signal(signal.SIGTERM, stop)
        try:
            result = child.wait()
            if result < 0:
                name = signal.Signals(-result).name
                print(f"Clavis: child terminated by {name} (exit {128 - result}); no detached crash GUI or automatic restart.", file=sys.stderr)
                return 128 - result
            return result
        finally:
            if child.poll() is None:
                child.terminate()
                try:
                    child.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit("A child command is required")
    raise SystemExit(run(sys.argv[1:]))
