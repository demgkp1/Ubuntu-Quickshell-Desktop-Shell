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

# Automatically hide native GNOME topbar and register global shortcuts, restoring on exit/Ctrl+C
ORIG_WINDOW_MENU=$(gsettings get org.gnome.desktop.wm.keybindings activate-window-menu 2>/dev/null || echo "['<Alt>space']")

cleanup() {
    gnome-extensions disable "hidetopbar@mathieu.bidon.ca" 2>/dev/null || true
    gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "$ORIG_WINDOW_MENU" 2>/dev/null || true
    gsettings reset org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || true
}
trap cleanup EXIT INT TERM

gnome-extensions enable "hidetopbar@mathieu.bidon.ca" 2>/dev/null || true

# Register global shortcuts in GNOME for Spotlight Launcher (<Alt>space and <Control>space)
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "[]" 2>/dev/null || true
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name "Quickshell Spotlight" 2>/dev/null || true
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "$PROJECT_DIR/scripts/toggle_spotlight.sh" 2>/dev/null || true
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding "<Alt>space" 2>/dev/null || true

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name "Quickshell Spotlight Secondary" 2>/dev/null || true
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command "$PROJECT_DIR/scripts/toggle_spotlight.sh" 2>/dev/null || true
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding "<Control>space" 2>/dev/null || true

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']" 2>/dev/null || true

cd "$PROJECT_DIR"
nix develop "$PROJECT_DIR" --command quickshell -p "$PROJECT_DIR/src/" "$@"
