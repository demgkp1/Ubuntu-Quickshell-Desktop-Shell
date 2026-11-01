#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Ensure Nix profile is loaded
if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
elif [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix.sh" ]; then
    . "/nix/var/nix/profiles/default/etc/profile.d/nix.sh"
fi

# Cursor environment variables to enforce system Yaru arrow cursor
export XCURSOR_THEME="Yaru"
export XCURSOR_SIZE="24"
export XCURSOR_PATH="/usr/share/icons:$HOME/.icons"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-xcb}"
export QML2_IMPORT_PATH="$PROJECT_DIR/imports:${QML2_IMPORT_PATH:-}"
export GIO_EXTRA_MODULES="/usr/lib/x86_64-linux-gnu/gio/modules:${GIO_EXTRA_MODULES:-}"

# Automatically hide native GNOME topbar & dock, mute native notification banners on start, and restore on exit/Ctrl+C
cleanup() {
    killall quickshell 2>/dev/null || true
    gnome-extensions disable "hidetopbar@mathieu.bidon.ca" 2>/dev/null || true
    gnome-extensions enable "ubuntu-dock@ubuntu.com" 2>/dev/null || true
    gsettings set org.gnome.desktop.notifications show-banners true 2>/dev/null || true
}
trap cleanup EXIT INT TERM

gnome-extensions enable "hidetopbar@mathieu.bidon.ca" 2>/dev/null || true
gnome-extensions disable "ubuntu-dock@ubuntu.com" 2>/dev/null || true
gnome-extensions disable "dash-to-dock@micxgx.gmail.com" 2>/dev/null || true
gsettings set org.gnome.desktop.notifications show-banners false 2>/dev/null || true

cd "$PROJECT_DIR"
nix develop "$PROJECT_DIR" --command quickshell -p "$PROJECT_DIR/src/" "$@"
