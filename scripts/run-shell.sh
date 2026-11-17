#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for arg in "$@"; do
    if [[ "$arg" == "-d" || "$arg" == "--daemonize" ]]; then
        echo "Do not detach from the Clavis supervisor. Use the systemd user service for background operation." >&2
        exit 2
    fi
done
if [[ ! -r "$ROOT/build/qt-version" ]] || [[ "$(cat "$ROOT/build/qt-version")" != "$(pkg-config --modversion Qt6Core)" ]]; then
    echo "Native modules missing or Qt ABI changed. Run: $ROOT/scripts/build.sh" >&2
    exit 1
fi
trim_ws() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

forced_backend="$(trim_ws "${CLAVIS_SESSION_BACKEND:-}" | tr '[:upper:]' '[:lower:]')"
desktop_env="$(printf '%s' "${XDG_CURRENT_DESKTOP:-}" | tr '[:upper:]' '[:lower:]')"
session_env="$(printf '%s' "${DESKTOP_SESSION:-}" | tr '[:upper:]' '[:lower:]')"
niri_socket="$(trim_ws "${NIRI_SOCKET:-}")"
is_niri_session=0
if [[ "$forced_backend" == "niri" ]]; then
    is_niri_session=1
elif [[ "$forced_backend" != "gnome" && "$forced_backend" != "disabled" ]]; then
    if [[ -n "$niri_socket" || "$desktop_env" == *niri* || "$session_env" == *niri* ]]; then
        is_niri_session=1
    fi
fi

unset QML2_IMPORT_PATH QT_PLUGIN_PATH GIO_EXTRA_MODULES
export QML_IMPORT_PATH="$ROOT/build/qml:${CLAVIS_QML_DEPS:?Use scripts/launch.sh to enter the pinned Qt environment}"

if [[ "$is_niri_session" -eq 1 ]]; then
    export QT_QPA_PLATFORM=wayland
    # shellcheck source=scripts/graphics-env.sh
    source "$ROOT/scripts/graphics-env.sh"
    echo "Clavis: backend=niri; Qt=wayland; WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-unset}; NIRI_SOCKET=${niri_socket:-unset} (session/desktop settings unchanged)." >&2
    if [[ "${1:-}" == "--check-graphics" ]]; then
        exit 0
    fi
else
    # GNOME Wayland lacks layer-shell. Rendering uses XWayland, not a switched Xorg
    # session. Window management remains GNOME-native through the extension.
    if [[ -z "${DISPLAY:-}" ]]; then
        echo "DISPLAY is missing. Launch from a terminal in the GNOME session; no :0 is guessed." >&2
        exit 1
    fi
    export QT_QPA_PLATFORM=xcb
    # shellcheck source=scripts/graphics-env.sh
    source "$ROOT/scripts/graphics-env.sh"
    if [[ ! -x "$ROOT/build/bin/clavis-graphics-probe" ]]; then
        echo "Graphics probe missing. Run: $ROOT/scripts/build.sh" >&2
        exit 1
    fi
    echo "Clavis: Qt=xcb; OpenGL=$QT_XCB_GL_INTEGRATION; DISPLAY=$DISPLAY (session/desktop settings unchanged)." >&2
    if timeout --kill-after=2s 10s "$ROOT/build/bin/clavis-graphics-probe"; then
        if [[ "${1:-}" == "--check-graphics" ]]; then exit 0; fi
    else
        status=$?
        echo "Graphics preflight failed (exit $status); Quickshell was not started. No software-rendering fallback was forced." >&2
        exit "$status"
    fi
fi
# The supervisor ties the native child to its lifetime, including SIGKILL.
exec python3 "$ROOT/scripts/run-instance.py" quickshell --no-duplicate -p "$ROOT/src/shell.qml" "$@"
