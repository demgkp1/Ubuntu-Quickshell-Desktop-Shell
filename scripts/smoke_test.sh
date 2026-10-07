#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/home/dkp/projects/Ubuntu Quickshell Desktop Shell"
cd "$PROJECT_DIR"

if [ -f "/home/dkp/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "/home/dkp/.nix-profile/etc/profile.d/nix.sh"
fi

export XCURSOR_THEME="Yaru"
export XCURSOR_SIZE="24"
export XCURSOR_PATH="/usr/share/icons:/home/dkp/.icons"
export QT_QUICK_BACKEND="software"
export QT_QPA_PLATFORM="xcb"
export QML2_IMPORT_PATH="$PROJECT_DIR/imports:${QML2_IMPORT_PATH:-}"

cleanup() {
    killall quickshell 2>/dev/null || true
    gnome-extensions disable "hidetopbar@mathieu.bidon.ca" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "[Smoke Test] Starting 3-second ephemeral Quickshell validation..."
gnome-extensions enable "hidetopbar@mathieu.bidon.ca" 2>/dev/null || true

# Run quickshell for 3 seconds, then terminate cleanly
timeout 3s nix develop "$PROJECT_DIR" --command quickshell -p "$PROJECT_DIR/src/" || {
    EXIT_CODE=$?
    # 124 is normal exit code for timeout command
    if [ $EXIT_CODE -eq 124 ]; then
        echo "[Smoke Test] Ephemeral validation passed (3s completed without crash)."
        exit 0
    else
        echo "[Smoke Test] Quickshell exited with code $EXIT_CODE"
        exit $EXIT_CODE
    fi
}
