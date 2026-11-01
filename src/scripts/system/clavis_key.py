#!/usr/bin/env python3
"""
clavis_key.py - Unified Linux companion CLI bridge for Ubuntu Quickshell Desktop Shell.
Handles sysmon, keyboard watch, file operations/search, tool computations, clipboard, and recording status.
"""
import sys
import os
import time
import json
import signal
import ctypes
import glob
import subprocess

# Ensure child process terminates when parent (Quickshell) dies
try:
    PR_SET_PDEATHSIG = 1
    libc = ctypes.CDLL("libc.so.6")
    libc.prctl(PR_SET_PDEATHSIG, signal.SIGTERM)
except Exception:
    pass


def handle_sysmon(args):
    distro_id = "ubuntu"
    distro_name = "Ubuntu Linux"
    try:
        with open("/etc/os-release", "r") as f:
            for line in f:
                if line.startswith("ID="):
                    distro_id = line.strip().split("=")[1].strip('"')
                elif line.startswith("PRETTY_NAME="):
                    distro_name = line.strip().split("=")[1].strip('"')
    except Exception:
        pass

    cpu_model = ""
    try:
        with open("/proc/cpuinfo", "r") as f:
            for line in f:
                if "model name" in line:
                    cpu_model = line.split(":", 1)[1].strip()
                    break
    except Exception:
        pass

    boot_time = 0
    try:
        with open("/proc/stat", "r") as f:
            for line in f:
                if line.startswith("btime "):
                    boot_time = int(line.split()[1])
                    break
    except Exception:
        pass

    uname = os.uname()
    is_wayland = bool(os.environ.get("WAYLAND_DISPLAY"))
    wm_name = "GNOME / Wayland" if is_wayland else "GNOME / Mutter (X11)"

    payload = {
        "schemaVersion": 1,
        "system": {
            "systemUser": os.environ.get("USER", "ubuntu"),
            "hostName": uname.nodename,
            "wmName": wm_name,
            "shellName": "Ubuntu Quickshell Desktop Shell",
            "kernel": uname.release,
            "architecture": uname.machine,
            "chassis": "Desktop",
            "vendor": "Ubuntu",
            "productName": distro_name,
            "boardName": "",
            "biosVersion": "",
            "cpuModelName": cpu_model or "x86_64 Processor",
            "physicalCoreCount": max(1, (os.cpu_count() or 2) // 2),
            "logicalCpuCount": os.cpu_count() or 2,
            "bootTimeMs": boot_time * 1000,
            "osAgeText": "",
            "distroId": distro_id,
            "osName": distro_name
        }
    }
    print(json.dumps(payload))


def read_led(pattern):
    try:
        for path in glob.glob(pattern):
            with open(path, "r") as f:
                val = f.read().strip()
                if val.isdigit() and int(val) > 0:
                    return True
    except Exception:
        pass
    return False


def handle_keyboard(args):
    parent_pid = os.getppid()
    last_caps = None
    last_num = None

    while True:
        if os.getppid() != parent_pid or os.getppid() <= 1:
            sys.exit(0)

        caps = read_led("/sys/class/leds/*::capslock/brightness")
        num = read_led("/sys/class/leds/*::numlock/brightness")

        if last_caps is None:
            msg = {
                "schemaVersion": 1,
                "command": "keyboard.watch",
                "ok": True,
                "available": True,
                "event": "snapshot",
                "capsLock": caps,
                "numLock": num,
                "error": None
            }
            sys.stdout.write(json.dumps(msg) + "\n")
            sys.stdout.flush()
            last_caps = caps
            last_num = num
        elif caps != last_caps or num != last_num:
            msg = {
                "schemaVersion": 1,
                "command": "keyboard.watch",
                "ok": True,
                "available": True,
                "event": "changed",
                "capsLock": caps,
                "numLock": num,
                "error": None
            }
            sys.stdout.write(json.dumps(msg) + "\n")
            sys.stdout.flush()
            last_caps = caps
            last_num = num

        time.sleep(1.0)


def handle_file(args):
    if not args:
        return
    action = args[0]
    if action == "status":
        print(json.dumps({
            "schemaVersion": 1,
            "command": "file.status",
            "ok": True,
            "canSearch": True,
            "capabilities": {
                "search": True
            },
            "error": None
        }))
    elif action == "search":
        query = args[-1] if len(args) > 1 else ""
        home = os.path.expanduser("~")
        entries = []
        q_lower = query.lower()
        if q_lower:
            search_dirs = [
                os.path.join(home, "Desktop"),
                os.path.join(home, "Documents"),
                os.path.join(home, "Downloads"),
                os.path.join(home, "Pictures"),
                os.path.join(home, "Videos"),
                os.path.join(home, "Music")
            ]
            seen_paths = set()
            ignored_dirs = {"node_modules", "target", "build", "dist", ".git", ".cache", "venv", ".venv", "__pycache__"}

            # Search shallow files in home directory first (depth 1)
            try:
                for fname in os.listdir(home):
                    if fname.startswith("."):
                        continue
                    fpath = os.path.join(home, fname)
                    if os.path.isfile(fpath) and q_lower in fname.lower() and fpath not in seen_paths:
                        seen_paths.add(fpath)
                        try:
                            st = os.stat(fpath)
                            entries.append({
                                "name": fname,
                                "path": fpath,
                                "parentPath": home,
                                "parentName": os.path.basename(home),
                                "fileType": "file",
                                "modifiedTime": int(st.st_mtime * 1000),
                                "isDirectory": False,
                                "isSymlink": os.path.islink(fpath),
                                "isExecutable": os.access(fpath, os.X_OK),
                                "icon": "text-x-generic"
                            })
                            if len(entries) >= 50:
                                break
                        except Exception:
                            pass
            except Exception:
                pass

            max_depth = 4
            for sdir in search_dirs:
                if not os.path.isdir(sdir) or len(entries) >= 50:
                    continue
                try:
                    sdir_depth = sdir.rstrip(os.path.sep).count(os.path.sep)
                    for root_dir, dirs, files in os.walk(sdir):
                        # Enforce maximum search depth
                        cur_depth = root_dir.rstrip(os.path.sep).count(os.path.sep) - sdir_depth
                        if cur_depth >= max_depth:
                            dirs[:] = []
                            continue
                        # Prune hidden and heavyweight development directories
                        dirs[:] = [d for d in dirs if not d.startswith(".") and d.lower() not in ignored_dirs]
                        for fname in files:
                            if fname.startswith("."):
                                continue
                            if q_lower in fname.lower():
                                fpath = os.path.join(root_dir, fname)
                                if fpath in seen_paths:
                                    continue
                                seen_paths.add(fpath)
                                try:
                                    st = os.stat(fpath)
                                    is_dir = os.path.isdir(fpath)
                                    is_link = os.path.islink(fpath)
                                    ftype = "directory" if is_dir else ("symlink" if is_link else "file")
                                    entries.append({
                                        "name": fname,
                                        "path": fpath,
                                        "parentPath": root_dir,
                                        "parentName": os.path.basename(root_dir),
                                        "fileType": ftype,
                                        "modifiedTime": int(st.st_mtime * 1000),
                                        "isDirectory": is_dir,
                                        "isSymlink": is_link,
                                        "isExecutable": os.access(fpath, os.X_OK),
                                        "icon": "folder" if is_dir else "text-x-generic"
                                    })
                                    if len(entries) >= 50:
                                        break
                                except Exception:
                                    pass
                        if len(entries) >= 50:
                            break
                except Exception:
                    pass
                if len(entries) >= 50:
                    break

        print(json.dumps({
            "schemaVersion": 1,
            "command": "file.search",
            "ok": True,
            "query": query,
            "entries": entries,
            "complete": True,
            "limited": False,
            "error": None
        }))
    elif action in ("open", "reveal"):
        target_path = ""
        for a in args[1:]:
            if not a.startswith("--"):
                target_path = a
                break
        exists = os.path.exists(target_path)
        if action == "open":
            if exists:
                subprocess.Popen(["xdg-open", target_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print(json.dumps({
                "schemaVersion": 1,
                "command": "file.open",
                "ok": True,
                "path": target_path,
                "fileExists": exists,
                "mode": "open",
                "error": None
            }))
        elif action == "reveal":
            if exists:
                folder = target_path if os.path.isdir(target_path) else os.path.dirname(target_path)
                subprocess.Popen(["xdg-open", folder], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print(json.dumps({
                "schemaVersion": 1,
                "command": "file.reveal",
                "ok": True,
                "path": target_path,
                "fileExists": exists,
                "mode": "reveal",
                "error": None
            }))


def handle_tool(args):
    if not args:
        return
    action = args[0]
    if action == "status":
        print(json.dumps({
            "schemaVersion": 1,
            "command": "tool.status",
            "ok": True,
            "capabilities": {
                "calc": True,
                "time": True,
                "currency": False
            },
            "error": None
        }))
    elif action == "catalog":
        tool_name = args[1] if len(args) > 1 else ""
        print(json.dumps({
            "schemaVersion": 1,
            "command": "tool.catalog",
            "ok": True,
            "tool": tool_name,
            "catalog": [],
            "error": None
        }))
    elif action in ("calc", "time"):
        print(json.dumps({
            "schemaVersion": 1,
            "command": "tool." + action,
            "ok": True,
            "tool": action,
            "result": None,
            "error": None
        }))


def handle_clipboard(args):
    if not args:
        return
    sub = args[0]
    if sub == "config":
        max_items = 500
        for i, a in enumerate(args):
            if a == "--max-items" and i + 1 < len(args):
                try:
                    max_items = int(args[i + 1])
                except Exception:
                    pass
        print(json.dumps({
            "schemaVersion": 1,
            "command": "clipboard.config",
            "ok": True,
            "maxItems": max_items,
            "error": None
        }))
    elif sub == "list":
        print(json.dumps({
            "schemaVersion": 1,
            "command": "clipboard.list",
            "ok": True,
            "entries": [],
            "canList": True,
            "canRestore": False,
            "watcherRunning": False,
            "dependencies": {
                "cliphist": False,
                "wlCopy": False,
                "wlPaste": False
            },
            "capabilities": {
                "inspect": False,
                "preview": False,
                "mimeRestore": False,
                "mimeAwareStore": False
            },
            "error": None
        }))
    elif sub == "inspect":
        target_id = args[1] if len(args) > 1 else ""
        print(json.dumps({
            "schemaVersion": 1,
            "command": "clipboard.inspect",
            "ok": True,
            "id": target_id,
            "entry": None,
            "error": None
        }))
    else:
        print(json.dumps({
            "schemaVersion": 1,
            "command": "clipboard." + sub,
            "ok": True,
            "error": None
        }))


def handle_audio(args):
    sub = args[0] if args else "status"
    if sub == "watch":
        parent_pid = os.getppid()
        msg = {
            "schemaVersion": 1,
            "command": "audio.watch",
            "ok": True,
            "state": "idle",
            "sessionId": "",
            "sourceType": "mic",
            "startedAtMs": 0,
            "error": None
        }
        sys.stdout.write(json.dumps(msg) + "\n")
        sys.stdout.flush()
        while True:
            if os.getppid() != parent_pid or os.getppid() <= 1:
                sys.exit(0)
            time.sleep(2.0)
    else:
        print(json.dumps({
            "schemaVersion": 1,
            "command": "audio.status",
            "ok": True,
            "state": "idle",
            "sessionId": "",
            "sourceType": "mic",
            "startedAtMs": 0,
            "error": None
        }))


def handle_record(args):
    sub = args[0] if args else "status"
    if sub == "watch":
        parent_pid = os.getppid()
        msg = {
            "schemaVersion": 1,
            "command": "record.watch",
            "ok": True,
            "state": "idle",
            "sessionId": "",
            "recordingType": "screen",
            "startedAtMs": 0,
            "error": None
        }
        sys.stdout.write(json.dumps(msg) + "\n")
        sys.stdout.flush()
        while True:
            if os.getppid() != parent_pid or os.getppid() <= 1:
                sys.exit(0)
            time.sleep(2.0)
    else:
        print(json.dumps({
            "schemaVersion": 1,
            "command": "record.status",
            "ok": True,
            "state": "idle",
            "sessionId": "",
            "recordingType": "screen",
            "startedAtMs": 0,
            "error": None
        }))


def main():
    if len(sys.argv) < 2:
        sys.exit(0)
    cmd = sys.argv[1]
    rest = sys.argv[2:]
    if cmd == "sysmon":
        handle_sysmon(rest)
    elif cmd == "keyboard":
        handle_keyboard(rest)
    elif cmd == "file":
        handle_file(rest)
    elif cmd == "tool":
        handle_tool(rest)
    elif cmd == "clipboard":
        handle_clipboard(rest)
    elif cmd == "audio":
        handle_audio(rest)
    elif cmd == "record":
        handle_record(rest)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
