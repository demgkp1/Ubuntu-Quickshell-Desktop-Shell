#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
elif [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix.sh" ]; then
    . "/nix/var/nix/profiles/default/etc/profile.d/nix.sh"
fi

export XCURSOR_THEME="Yaru"
export XCURSOR_SIZE="24"
export XCURSOR_PATH="/usr/share/icons:$HOME/.icons"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-xcb}"
export QML2_IMPORT_PATH="$PROJECT_DIR/imports:${QML2_IMPORT_PATH:-}"

cleanup() {
    killall quickshell 2>/dev/null || true
    gnome-extensions disable "hidetopbar@mathieu.bidon.ca" 2>/dev/null || true
    gnome-extensions enable "ubuntu-dock@ubuntu.com" 2>/dev/null || true
    rm -f "$SMOKE_LOG" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "[Smoke Test] Starting 3-second ephemeral Quickshell validation..."
gnome-extensions enable "hidetopbar@mathieu.bidon.ca" 2>/dev/null || true
gnome-extensions disable "ubuntu-dock@ubuntu.com" 2>/dev/null || true
gnome-extensions disable "dash-to-dock@micxgx.gmail.com" 2>/dev/null || true

SMOKE_LOG=$(mktemp)
# Run quickshell for 3 seconds under nix develop, redirecting output for strict error verification
timeout 3s nix develop "$PROJECT_DIR" --command quickshell -p "$PROJECT_DIR/src/" > "$SMOKE_LOG" 2>&1 || {
    EXIT_CODE=$?
    # Check for fatal graphics crashes or QML load failures in log
    if grep -qE "(FATAL:|Could not initialize GLX|Failed to create graphics context|Failed to load configuration|Type .* unavailable|is not a type)" "$SMOKE_LOG"; then
        echo "[FAIL] 冒烟测试捕获到致命错误或组件加载失败！"
        cat "$SMOKE_LOG"
        exit 1
    fi

    # 124 is normal exit code for timeout command
    if [ $EXIT_CODE -eq 124 ]; then
        echo "[Smoke Test] Ephemeral validation passed (3s completed without crash or fatal error)."
        exit 0
    else
        echo "[Smoke Test] Quickshell exited unexpectedly with code $EXIT_CODE"
        cat "$SMOKE_LOG"
        exit $EXIT_CODE
    fi
}
