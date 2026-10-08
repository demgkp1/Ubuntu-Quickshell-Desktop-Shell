#!/usr/bin/env bash
set -euo pipefail

x="${1:-0}"
y="${2:-0}"

# Detect primary / total virtual screen size
screen_w="1920"
screen_h="1080"
screen_geom=$(xrandr --current 2>/dev/null | sed -nE "s/^Screen 0:.*current ([0-9]+) x ([0-9]+).*/\1 \2/p" | head -n1)
if [ -n "$screen_geom" ]; then
    read -r screen_w screen_h <<< "$screen_geom"
fi

if [ "$x" -ge "$screen_w" ]; then x=$((screen_w - 1)); fi
if [ "$y" -ge "$screen_h" ]; then y=$((screen_h - 1)); fi
if [ "$x" -lt 0 ]; then x=0; fi
if [ "$y" -lt 0 ]; then y=0; fi

disp="${DISPLAY:-:0}"
disp_base="${disp%.*}"

tmp_pixel=$(mktemp "${TMPDIR:-/tmp}/clavis-color-XXXXXX.bmp")
trap 'rm -f "$tmp_pixel"' EXIT

timeout 2s ffmpeg -nostdin -v error -f x11grab -video_size "${screen_w}x${screen_h}" -i "${disp_base}.0+0,0" -vf "crop=1:1:${x}:${y}" -vframes 1 -y "$tmp_pixel" < /dev/null >/dev/null 2>&1 || true

if [ -s "$tmp_pixel" ]; then
    python3 -c "
import sys, gi
gi.require_version('GdkPixbuf', '2.0')
from gi.repository import GdkPixbuf
try:
    p = GdkPixbuf.Pixbuf.new_from_file(sys.argv[1])
    b = p.get_pixels()
    print('#{:02X}{:02X}{:02X}'.format(b[0], b[1], b[2]))
except Exception:
    sys.exit(1)
" "$tmp_pixel"
else
    echo "#000000"
fi
