#!/usr/bin/env python3
"""
app_scanner.py - High-performance XDG .desktop application scanner & JSON cache generator.
Complies withdocs/ENGINEERING_TENETS.md Tier 3 asynchronous cache model and anti-zombie bindings.
"""
import sys
import os
import glob
import shlex
import json
import signal
import ctypes

# Anti-zombie protection: bind lifecycle to parent process
try:
    PR_SET_PDEATHSIG = 1
    libc = ctypes.CDLL("libc.so.6")
    libc.prctl(PR_SET_PDEATHSIG, signal.SIGTERM)
except Exception:
    pass


def get_application_dirs():
    home = os.path.expanduser("~")
    xdg_data_home = os.environ.get("XDG_DATA_HOME") or os.path.join(home, ".local", "share")
    xdg_data_dirs = os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"

    dirs = [os.path.join(xdg_data_home, "applications")]
    for d in xdg_data_dirs.split(":"):
        d = d.strip()
        if d:
            dirs.append(os.path.join(d, "applications"))

    # Also add flatpak / snap dirs if present
    for extra in ["/var/lib/flatpak/exports/share/applications",
                  os.path.join(home, ".local/share/flatpak/exports/share/applications"),
                  "/var/lib/snapd/desktop/applications"]:
        if os.path.isdir(extra) and extra not in dirs:
            dirs.append(extra)

    # Return valid existing directories in priority order (user local first)
    return [d for d in dirs if os.path.isdir(d)]


def clean_exec_string(exec_str):
    if not exec_str:
        return ""
    # Strip desktop field codes (%f, %F, %u, %U, %d, %D, %n, %N, %i, %c, %k, %v, %m)
    tokens = exec_str.split()
    cleaned = []
    for tok in tokens:
        if tok.startswith("%") and len(tok) == 2:
            continue
        cleaned.append(tok)
    return " ".join(cleaned)


def parse_desktop_file(filepath):
    try:
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except Exception:
        return None

    current_section = None
    entry_data = {}
    actions = {}
    current_action_id = None

    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        if line.startswith("[") and line.endswith("]"):
            current_section = line[1:-1]
            if current_section.startswith("Desktop Action "):
                current_action_id = current_section[len("Desktop Action "):].strip()
                actions[current_action_id] = {}
            else:
                current_action_id = None
            continue

        if "=" not in line:
            continue

        key, val = line.split("=", 1)
        key = key.strip()
        val = val.strip()

        if current_section == "Desktop Entry":
            # Save top-level desktop entry fields
            if key not in entry_data:
                entry_data[key] = val
        elif current_action_id and current_action_id in actions:
            if key not in actions[current_action_id]:
                actions[current_action_id][key] = val

    # Must be Type=Application
    if entry_data.get("Type") != "Application":
        return None

    # Filter NoDisplay or Hidden
    if entry_data.get("NoDisplay", "").lower() == "true":
        return None
    if entry_data.get("Hidden", "").lower() == "true":
        return None

    raw_exec = entry_data.get("Exec", "")
    if not raw_exec:
        return None

    cleaned_exec = clean_exec_string(raw_exec)
    try:
        command = shlex.split(cleaned_exec)
    except Exception:
        command = cleaned_exec.split()

    if not command:
        return None

    desktop_id = os.path.basename(filepath)
    name = entry_data.get("Name", "")
    if not name:
        name = desktop_id.replace(".desktop", "")

    generic_name = entry_data.get("GenericName", "")
    comment = entry_data.get("Comment", "")
    icon = entry_data.get("Icon", "")

    categories_raw = entry_data.get("Categories", "")
    categories = [c.strip() for c in categories_raw.split(";") if c.strip()]

    keywords_raw = entry_data.get("Keywords", "")
    keywords = [k.strip() for k in keywords_raw.split(";") if k.strip()]

    # Parse action items
    parsed_actions = []
    for act_id, act_fields in actions.items():
        act_exec = clean_exec_string(act_fields.get("Exec", ""))
        act_name = act_fields.get("Name", act_id)
        try:
            act_cmd = shlex.split(act_exec)
        except Exception:
            act_cmd = act_exec.split()
        if act_cmd:
            parsed_actions.append({
                "id": act_id,
                "name": act_name,
                "command": act_cmd
            })

    return {
        "id": desktop_id,
        "name": name,
        "genericName": generic_name,
        "comment": comment,
        "icon": icon,
        "categories": categories,
        "keywords": keywords,
        "command": command,
        "exec": cleaned_exec,
        "execString": raw_exec,
        "workingDirectory": entry_data.get("Path", ""),
        "terminal": entry_data.get("Terminal", "").lower() == "true",
        "actions": parsed_actions,
        "desktopFile": filepath
    }


def scan_applications():
    app_dirs = get_application_dirs()
    seen_ids = set()
    applications = []

    for d in app_dirs:
        desktop_files = glob.glob(os.path.join(d, "*.desktop"))
        for filepath in desktop_files:
            desktop_id = os.path.basename(filepath)
            if desktop_id in seen_ids:
                continue
            app = parse_desktop_file(filepath)
            if app:
                seen_ids.add(desktop_id)
                applications.append(app)

    # Sort alphabetically by name
    applications.sort(key=lambda a: a.get("name", "").lower())
    return applications


def get_cache_path():
    home = os.path.expanduser("~")
    clavis_cache = os.environ.get("CLAVIS_CACHE_HOME")
    if clavis_cache and os.path.isabs(clavis_cache):
        cache_dir = clavis_cache
    else:
        xdg_cache = os.environ.get("XDG_CACHE_HOME") or os.path.join(home, ".cache")
        cache_dir = os.path.join(xdg_cache, "clavis")
    return os.path.join(cache_dir, "applications.json")


def needs_update(cache_path):
    if not os.path.exists(cache_path):
        return True
    try:
        cache_mtime = os.path.getmtime(cache_path)
        for d in get_application_dirs():
            if os.path.isdir(d) and os.path.getmtime(d) > cache_mtime:
                return True
        return False
    except Exception:
        return True


def main():
    cache_path = get_cache_path()

    if "--check-mtime" in sys.argv:
        if not needs_update(cache_path):
            if "--json" in sys.argv or "--stdout" in sys.argv:
                print("[]")
            else:
                print("UNCHANGED")
            return

    apps = scan_applications()
    import tempfile
    cache_dir = os.path.dirname(cache_path)
    os.makedirs(cache_dir, exist_ok=True)

    # Atomic write using unique temporary file on same filesystem
    with tempfile.NamedTemporaryFile("w", dir=cache_dir, delete=False, encoding="utf-8") as f:
        tmp_path = f.name
        json.dump(apps, f, ensure_ascii=False, indent=2)
    os.replace(tmp_path, cache_path)

    if "--stdout" in sys.argv or "--json" in sys.argv:
        print(json.dumps(apps, ensure_ascii=False))
    else:
        print(f"Scanned {len(apps)} applications; cached to {cache_path}")


if __name__ == "__main__":
    main()
