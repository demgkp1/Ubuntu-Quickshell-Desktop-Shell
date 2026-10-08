#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
elif [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix.sh" ]; then
    . "/nix/var/nix/profiles/default/etc/profile.d/nix.sh"
fi

export DISPLAY="${DISPLAY:-:0}"
if [ -z "${XAUTHORITY:-}" ] && [ -f "$HOME/.Xauthority" ]; then
    export XAUTHORITY="$HOME/.Xauthority"
fi

export QT_QUICK_BACKEND="software"
export QT_QPA_PLATFORM="xcb"
export XCURSOR_THEME="${XCURSOR_THEME:-Yaru}"
export XCURSOR_SIZE="${XCURSOR_SIZE:-24}"
export XCURSOR_PATH="${XCURSOR_PATH:-/usr/share/icons:$HOME/.icons}"
export QML2_IMPORT_PATH="$PROJECT_DIR/src:$PROJECT_DIR/imports:${QML2_IMPORT_PATH:-}"

echo "=========================================================="
echo " Launching Clavis Upstream Wallpaper & Shader Demo"
echo " Window: 1120x700 Floating Window"
echo " Included: 6 Upstream Showcase Wallpapers + 7 GLSL Shaders"
echo " Press Ctrl+C or click the [✕] button in window to exit."
echo "=========================================================="

cd "$PROJECT_DIR"
exec nix develop "$PROJECT_DIR" --command quickshell -p "$PROJECT_DIR/tools/wallpaper-demo/shell.qml" "$@"
