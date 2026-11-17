#!/usr/bin/env python3
"""Negative-path test: abort only our invisible Quickshell, not a user instance.

Run in the pinned dev shell after sourcing scripts/graphics-env.sh, with the
real graphical environment inherited. No GNOME actions or visible windows.
"""
import json
import os
from pathlib import Path
import resource
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build/graphics-validation"


class LauncherCrashTest(unittest.TestCase):
    def test_native_abort_returns_failure_and_cleans_fonts_without_reporter(self):
        self.assertTrue(os.environ.get("DISPLAY"), "Inherit the actual GNOME DISPLAY; no :0 is guessed")
        self.assertTrue(shutil.which("quickshell"), "Run inside the pinned Nix environment")
        OUT.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="clavis-crash-check-") as directory:
            temp = Path(directory)
            runtime = temp / "runtime"
            runtime.mkdir(mode=0o700)
            config = temp / "shell.qml"
            config.write_text('''//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
ShellRoot {
    IpcHandler {
        target: "probe"
        function environment(): string {
            return JSON.stringify({
                fontconfig: Quickshell.env("FONTCONFIG_FILE"),
                crashHandlerDisabled: Quickshell.env("QS_DISABLE_CRASH_HANDLER")
            });
        }
    }
    Timer { running: true; interval: 15000; onTriggered: Quickshell.quit(3) }
}
''')
            env = dict(os.environ, XDG_RUNTIME_DIR=str(runtime), QT_QPA_PLATFORM="xcb")

            def no_core():
                resource.setrlimit(resource.RLIMIT_CORE, (0, 0))

            with (OUT / "crash-lifecycle.log").open("w+") as log:
                supervisor = subprocess.Popen(
                    [sys.executable, str(ROOT / "scripts/run-instance.py"),
                     "quickshell", "--no-duplicate", "-p", str(config)],
                    env=env, stdin=subprocess.DEVNULL, stdout=log, stderr=log,
                    preexec_fn=no_core,
                )
                try:
                    state = None
                    deadline = time.monotonic() + 8
                    while time.monotonic() < deadline:
                        self.assertIsNone(supervisor.poll(), "Our Quickshell exited before IPC readiness")
                        reply = subprocess.run(
                            ["quickshell", "ipc", "-p", str(config), "call", "probe", "environment"],
                            env=env, capture_output=True, text=True, timeout=2,
                        )
                        if reply.returncode == 0:
                            state = json.loads(reply.stdout)
                            break
                        time.sleep(0.05)
                    self.assertIsNotNone(state, "Our actual QML runtime did not reach IPC readiness")
                    self.assertEqual(state["crashHandlerDisabled"], "1")
                    fonts = Path(state["fontconfig"])
                    self.assertTrue(fonts.is_file(), "Fonts must remain present while Qt is running")
                    children = Path(f"/proc/{supervisor.pid}/task/{supervisor.pid}/children").read_text().split()
                    self.assertEqual(len(children), 1, "Signal exactly the supervisor's owned native child")
                    native_pid = int(children[0])
                    os.kill(native_pid, signal.SIGABRT)
                    self.assertEqual(supervisor.wait(timeout=5), 134, "Do not swallow a native crash exit")
                    self.assertFalse(fonts.exists(), "The stopped native child no longer needs its font file")
                    # Check for new detached reporters by this launch's unique
                    # font path, not a global process-name heuristic. Do not
                    # signal other processes or print unrelated environments.
                    survivors = []
                    marker = f"FONTCONFIG_FILE={fonts}".encode()
                    for process in Path("/proc").iterdir():
                        if not process.name.isdigit():
                            continue
                        try:
                            if process.stat().st_uid == os.getuid() and marker in (process / "environ").read_bytes().split(b"\0"):
                                survivors.append(int(process.name))
                        except (FileNotFoundError, ProcessLookupError, PermissionError):
                            continue
                    self.assertEqual(survivors, [], "A process retained our deleted font config")
                    log.flush()
                    log.seek(0)
                    text = log.read()
                    self.assertIn("child terminated by SIGABRT (exit 134)", text)
                    for failure in ("Starting crash reporter", "Fontconfig error", "Could not initialize GLX", "qglx_findConfig"):
                        self.assertNotIn(failure, text)
                    (OUT / "crash-lifecycle.json").write_text(json.dumps({
                        "nativePid": native_pid, "exit": 134,
                        "fontsRemoved": True, "survivors": survivors,
                    }, indent=2) + "\n")
                finally:
                    if supervisor.poll() is None:
                        supervisor.terminate()
                        try:
                            supervisor.wait(timeout=3)
                        except subprocess.TimeoutExpired:
                            supervisor.kill()
                            supervisor.wait()


if __name__ == "__main__":
    unittest.main()
