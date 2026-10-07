#!/usr/bin/env bash
set -euo pipefail

output="${1:-}"
if [ -z "$output" ]; then
    echo "Missing output name" >&2
    exit 1
fi

umask 077
snapshot_dir=$(mktemp -d "${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/clavis-snapshot.XXXXXX")
trap 'rm -rf -- "$snapshot_dir"' EXIT
trap 'exit 1' HUP INT TERM

snapshot_path="$snapshot_dir/frame.bmp"

# Parse output geometry using xrandr
geom=$(xrandr --current 2>/dev/null | sed -nE "s/^${output} connected [a-z ]*([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+).*/\1 \2 \3 \4/p")
if [ -z "$geom" ]; then
    # Fallback to primary or first connected output
    geom=$(xrandr --current 2>/dev/null | sed -nE "s/^[a-zA-Z0-9-]+ connected [a-z ]*([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+).*/\1 \2 \3 \4/p" | head -n1)
fi

if [ -n "$geom" ]; then
    read -r w h x y <<< "$geom"
    disp="${DISPLAY:-:0}"
    # Remove screen number from display if present to append offset cleanly
    disp_base="${disp%.*}"
    timeout 1s ffmpeg -v error -f x11grab -video_size "${w}x${h}" -i "${disp_base}.0+${x},${y}" -vframes 1 -y "$snapshot_path" >/dev/null 2>&1 || true
fi

if [ -s "$snapshot_path" ]; then
    printf '%s\n' "$snapshot_path"
    # Keep directory alive until parent writes to stdin or closes stdin
    IFS= read -r _release || true
else
    exit 1
fi
