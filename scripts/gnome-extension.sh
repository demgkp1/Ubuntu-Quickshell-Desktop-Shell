#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UUID=clavis-bridge@local
SOURCE="$ROOT/gnome-extension/$UUID"
OUTPUT="$ROOT/build/gnome-extension"
case "${1:-pack}" in
    pack)
        mkdir -p "$OUTPUT"
        /usr/bin/gnome-extensions pack "$SOURCE" --force --out-dir "$OUTPUT"
        echo "Packed only; no installed or enabled extension was changed."
        ;;
    install)
        echo "Installs the user-session window/workspace bridge. Does not hide GNOME UI, enable itself, change wallpaper or replace locking."
        "$0" pack
        /usr/bin/gnome-extensions install "$OUTPUT/$UUID.shell-extension.zip"
        echo "Installed, not enabled. GNOME may require a later user-controlled login to discover a newly installed extension."
        ;;
    enable)
        echo "Enables access to real GNOME window/workspace metadata and window actions for local session clients. Does not change GNOME chrome or window layout."
        /usr/bin/gnome-extensions enable "$UUID"
        /usr/bin/gnome-extensions info "$UUID"
        ;;
    disable)
        /usr/bin/gnome-extensions disable "$UUID"
        echo "Disabled. Clavis will discard the window model when the bridge disconnects."
        ;;
    *) echo "Usage: $0 [pack|install|enable|disable]" >&2; exit 2 ;;
esac
