#!/usr/bin/env bash
set -euo pipefail

geom="${1:-}"
output_path="${2:-}"
copy_clipboard="${3:-true}"

if [ -z "$output_path" ]; then
    pictures_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
    mkdir -p "$pictures_dir"
    output_path="${pictures_dir}/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
else
    mkdir -p "$(dirname "$output_path")"
fi

# Detect primary / total virtual screen size
screen_w="1920"
screen_h="1080"
screen_geom=$(xrandr --current 2>/dev/null | sed -nE "s/^Screen 0:.*current ([0-9]+) x ([0-9]+).*/\1 \2/p" | head -n1)
if [ -n "$screen_geom" ]; then
    read -r screen_w screen_h <<< "$screen_geom"
else
    output_geom=$(xrandr --current 2>/dev/null | sed -nE "s/^[a-zA-Z0-9-]+ connected [a-z ]*([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+).*/\1 \2/p" | head -n1)
    if [ -n "$output_geom" ]; then
        read -r screen_w screen_h <<< "$output_geom"
    fi
fi

w="$screen_w"
h="$screen_h"
x="0"
y="0"

# Parse geometry format: WxH+X+Y
if [[ "$geom" =~ ^([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+)$ ]]; then
    w="${BASH_REMATCH[1]}"
    h="${BASH_REMATCH[2]}"
    x="${BASH_REMATCH[3]}"
    y="${BASH_REMATCH[4]}"

    # Boundary safety checks
    if [ $((x + w)) -gt "$screen_w" ]; then
        w=$((screen_w - x))
    fi
    if [ $((y + h)) -gt "$screen_h" ]; then
        h=$((screen_h - y))
    fi
    if [ "$w" -le 0 ]; then w="10"; fi
    if [ "$h" -le 0 ]; then h="10"; fi
fi

disp="${DISPLAY:-:0}"
disp_base="${disp%.*}"

# Capture frame via ffmpeg x11grab with crop filter, ensuring non-interactive stdin
if [ "$w" -eq "$screen_w" ] && [ "$h" -eq "$screen_h" ] && [ "$x" -eq 0 ] && [ "$y" -eq 0 ]; then
    timeout 3s ffmpeg -nostdin -v error -f x11grab -video_size "${screen_w}x${screen_h}" -i "${disp_base}.0+0,0" -vframes 1 -y "$output_path" < /dev/null >/dev/null 2>&1 || true
else
    timeout 3s ffmpeg -nostdin -v error -f x11grab -video_size "${screen_w}x${screen_h}" -i "${disp_base}.0+0,0" -vf "crop=${w}:${h}:${x}:${y}" -vframes 1 -y "$output_path" < /dev/null >/dev/null 2>&1 || true
fi

if [ -s "$output_path" ]; then
    # Copy to system clipboard via Python Gtk3
    if [ "$copy_clipboard" = "true" ]; then
        python3 -c "
import sys, gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GdkPixbuf
try:
    clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)
    pixbuf = GdkPixbuf.Pixbuf.new_from_file(sys.argv[1])
    clipboard.set_image(pixbuf)
    clipboard.store()
except Exception:
    pass
" "$output_path" 2>/dev/null || true
    fi

    printf '%s\n' "$output_path"
    exit 0
else
    echo "Screenshot capture failed" >&2
    exit 1
fi
