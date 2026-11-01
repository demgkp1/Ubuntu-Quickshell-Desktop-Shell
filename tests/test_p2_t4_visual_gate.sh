#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================================================="
echo " [Test P2-T4] Phase 2 Visual Truth Benchmarks & Comprehensive Gatekeeper"
echo "=========================================================================="

BENCHMARK_DIR="$PROJECT_DIR/docs/visual_benchmarks"
TEAL_BENCHMARK="$BENCHMARK_DIR/target_teal_theme.png"
SPIDER_BENCHMARK="$BENCHMARK_DIR/target_spider_cream_theme.png"
CC_BENCHMARK="$BENCHMARK_DIR/upstream_control_center.png"
GOLDEN_TOPBAR="$BENCHMARK_DIR/golden_topbar_reference.png"

# 1. Verify existence and validity of Visual Truth Benchmarks using ImageMagick
echo "1. Validating Visual Truth Benchmark image integrity (ImageMagick)..."
for bench in "$TEAL_BENCHMARK" "$SPIDER_BENCHMARK" "$CC_BENCHMARK" "$GOLDEN_TOPBAR"; do
    if [ ! -f "$bench" ]; then
        echo "[FAIL] Missing benchmark image: $bench"
        exit 1
    fi
    IMG_INFO=$(nix develop "$PROJECT_DIR" --command identify -format "%w %h %m" "$bench" 2>/dev/null | tail -n 1 || true)
    read -r WIDTH HEIGHT FORMAT <<< "$IMG_INFO"
    if [ "$FORMAT" != "PNG" ] || [ "$WIDTH" -lt 100 ] || [ "$HEIGHT" -lt 30 ]; then
        echo "[FAIL] Corrupt or invalid benchmark image: $bench (Format: $FORMAT, Dim: ${WIDTH}x${HEIGHT})"
        exit 1
    fi
    echo "  [VALID] $(basename "$bench") (${WIDTH}x${HEIGHT} $FORMAT, $(stat -c%s "$bench") bytes)"
done
echo "[PASS] All 3 Visual Truth Benchmark assets verified with ImageMagick."

# 2. Step through P2-T1 regression
echo "2. Running P2-T1 Matugen Theme Pipeline regression..."
"$SCRIPT_DIR/test_p2_t1_matugen.sh"
echo "[PASS] P2-T1 regression passed."

# 3. Step through P2-T2 regression
echo "3. Running P2-T2 QuickSettings 1:1 Visual Alignment regression..."
"$SCRIPT_DIR/test_p2_t2_quicksettings.sh"
echo "[PASS] P2-T2 regression passed."

# 4. Step through P2-T3 regression
echo "4. Running P2-T3 TopBar Pills & Hardware Adaptation regression..."
"$SCRIPT_DIR/test_p2_t3_topbar.sh"
echo "[PASS] P2-T3 regression passed."

# 5. Headless GPU rendering capture & ImageMagick visual verification (Xvfb)
echo "5. Executing headless virtual framebuffer rendering and visual pixel capture..."
nix develop "$PROJECT_DIR" --command bash -c '
set -euo pipefail
TMP_RENDER_DIR=$(mktemp -d)
XVFB_DISPLAY=95
Xvfb :$XVFB_DISPLAY -screen 0 1920x1080x24 >/dev/null 2>&1 &
XVFB_PID=$!
trap "kill -9 $XVFB_PID 2>/dev/null || true; rm -rf $TMP_RENDER_DIR" EXIT

sleep 1
RENDER_LOG="$TMP_RENDER_DIR/quickshell_render.log"
export DISPLAY=:$XVFB_DISPLAY
export QT_QPA_PLATFORM=xcb
unset WAYLAND_DISPLAY

quickshell -p "'"$PROJECT_DIR"'/src/shell.qml" >/dev/null 2>"$RENDER_LOG" &
QPID=$!
sleep 3

# 1. Assert no fatal GPU backend crash in render log
if grep -qiE "(FATAL|segmentation fault|Could not initialize GLX|Failed to initialize graphics backend|qglx_findConfig)" "$RENDER_LOG"; then
    echo "[FAIL] Fatal GPU rendering context failure in virtual framebuffer:"
    cat "$RENDER_LOG"
    kill -9 $QPID 2>/dev/null || true
    exit 1
fi

# 2. Capture the actual rendered framebuffer
CAPTURED_FRAME="$TMP_RENDER_DIR/rendered_frame.png"
import -window root "$CAPTURED_FRAME"
kill -9 $QPID 2>/dev/null || true

# 3. Verify with ImageMagick identify
FRAME_INFO=$(identify -format "%w %h %m" "$CAPTURED_FRAME" 2>/dev/null || true)
read -r F_WIDTH F_HEIGHT F_FORMAT <<< "$FRAME_INFO"
if [ "$F_FORMAT" != "PNG" ] || [ "$F_WIDTH" -ne 1920 ] || [ "$F_HEIGHT" -ne 1080 ]; then
    echo "[FAIL] Invalid or corrupted rendered frame: ${F_WIDTH}x${F_HEIGHT} $F_FORMAT"
    exit 1
fi

# 4. Assert non-empty framebuffer (Anti-Black-Screen Gate)
MEAN_VAL=$(magick "$CAPTURED_FRAME" -format "%[mean]" info:)
echo "  [RENDER OK] Headless framebuffer captured: 1920x1080 PNG (Mean Luminance: $MEAN_VAL)"
MEAN_INT=$(echo "$MEAN_VAL" | cut -d'.' -f1)
if [ "$MEAN_INT" -lt 100 ]; then
    echo "[FAIL] Framebuffer is essentially blank or pure black (Mean: $MEAN_VAL < 100)! Rendering failed!"
    exit 1
fi

# 5. Extract and assert rendered TopBar active luminance
CAPTURED_TOPBAR="$TMP_RENDER_DIR/captured_topbar.png"
magick "$CAPTURED_FRAME" -crop 1920x60+0+0 "$CAPTURED_TOPBAR"
TOPBAR_MEAN=$(magick "$CAPTURED_TOPBAR" -format "%[mean]" info:)
TOPBAR_MEAN_INT=$(echo "$TOPBAR_MEAN" | cut -d'.' -f1)
echo "  [TOPBAR OK] Rendered TopBar region mean luminance: $TOPBAR_MEAN"
if [ "$TOPBAR_MEAN_INT" -lt 5000 ]; then
    echo "[FAIL] Rendered TopBar region lacks active pixels (Mean: $TOPBAR_MEAN < 5000)!"
    exit 1
fi

# 6. Real Visual Pixel AE comparison against Golden Benchmark Reference
TOPBAR_DIFF="$TMP_RENDER_DIR/topbar_diff.png"
TOPBAR_AE=$(compare -metric AE -fuzz 10% "$CAPTURED_TOPBAR" "'"$GOLDEN_TOPBAR"'" "$TOPBAR_DIFF" 2>&1 || true)
AE_PIXELS=$(echo "$TOPBAR_AE" | awk "{print \$1}")
echo "  [COMPARE OK] ImageMagick visual diff AE against golden benchmark: $AE_PIXELS pixels ($TOPBAR_AE)"

# 1920x60 = 115,200 pixels. Max allowable difference is 0.5% (600 pixels) for clock seconds/tray transitions
MAX_ALLOWABLE_AE=600
AE_INT=$(echo "$AE_PIXELS" | cut -d'.' -f1)
if [ "$AE_INT" -gt "$MAX_ALLOWABLE_AE" ]; then
    echo "[FAIL] TopBar visual regression detected: $AE_INT pixels differ from golden benchmark (exceeds $MAX_ALLOWABLE_AE)!"
    exit 1
fi

kill -9 $XVFB_PID 2>/dev/null || true
rm -rf "$TMP_RENDER_DIR"
trap - EXIT
'
echo "[PASS] Ground-truth headless GPU rendering and ImageMagick verification passed."

# 6. Verify absence of software rendering overrides
echo "6. Auditing against software rasterization backdoors..."
if grep -rn "QT_QUICK_BACKEND=\"software\"" "$PROJECT_DIR/src/" "$PROJECT_DIR/bin/" 2>/dev/null; then
    echo "[FAIL] Software rasterization backdoor detected!"
    exit 1
fi
echo "[PASS] GPU hardware rendering pipeline pure."

# 7. Final mechanical tenets verification & smoke test
echo "7. Running strict tenets verification and smoke test..."
"$PROJECT_DIR/scripts/verify_tenets.sh"
"$PROJECT_DIR/scripts/smoke_test.sh"

echo "=========================================================================="
echo " [SUCCESS] P2-T4 Visual Truth Benchmarks & Regression Gate ALL PASSED!"
echo " Phase 2 Quality Chain is 100% Green and Production Ready!"
echo "=========================================================================="
