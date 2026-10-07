#!/usr/bin/env bash
set -e

# Project root directory
PROJECT_DIR="/home/dkp/projects/Ubuntu Quickshell Desktop Shell"

# Ensure Nix profile is loaded
if [ -f "/home/dkp/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "/home/dkp/.nix-profile/etc/profile.d/nix.sh"
fi

# Cursor environment variables to enforce system Yaru arrow cursor
export XCURSOR_THEME="Yaru"
export XCURSOR_SIZE="24"
export XCURSOR_PATH="/usr/share/icons:/home/dkp/.icons"
export QT_QUICK_BACKEND="software"
export QT_QPA_PLATFORM="xcb"
export QML2_IMPORT_PATH="$PROJECT_DIR/imports:${QML2_IMPORT_PATH:-}"

# Automatically hide native GNOME topbar on start, and restore it on exit/Ctrl+C
cleanup() {
    gnome-extensions disable "hidetopbar@mathieu.bidon.ca" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

gnome-extensions enable "hidetopbar@mathieu.bidon.ca" 2>/dev/null || true

cd "$PROJECT_DIR"
nix develop "$PROJECT_DIR" --command quickshell -p "$PROJECT_DIR/src/" "$@"
