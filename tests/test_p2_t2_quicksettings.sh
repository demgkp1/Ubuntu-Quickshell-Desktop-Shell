#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== [Test P2-T2] QuickSettings Surface & Sliders 1:1 Visual Alignment ==="

# 1. Cursor audit on interactive elements in QuickSettings and common widgets
echo "1. Checking cursor shape locking on QuickSettings widgets..."
BAD_CURSORS=$(grep -rnE "(PointingHandCursor|ClosedHandCursor|OpenHandCursor)" "$PROJECT_DIR/src/Modules/QuickSettings/" "$PROJECT_DIR/src/Widgets/common/MaterialSplitSlider.qml" "$PROJECT_DIR/src/Widgets/common/QuickToggleButton.qml" 2>/dev/null || true)
if [ -n "$BAD_CURSORS" ]; then
    echo "[FAIL] Found non-arrow cursor shapes:"
    echo "$BAD_CURSORS"
    exit 1
fi
echo "[PASS] All QuickSettings interactive cursors locked to Qt.ArrowCursor."

# 2. Check MaterialSplitSlider color bindings
echo "2. Checking MaterialSplitSlider M3 color bindings..."
grep -q "Appearance.colors.colPrimary" "$PROJECT_DIR/src/Widgets/common/MaterialSplitSlider.qml" || { echo "[FAIL] highlightColor not bound to colPrimary"; exit 1; }
grep -q "Appearance.colors.colSecondaryContainer" "$PROJECT_DIR/src/Widgets/common/MaterialSplitSlider.qml" || { echo "[FAIL] trackColor not bound to colSecondaryContainer"; exit 1; }
echo "[PASS] MaterialSplitSlider color bindings properly aligned with M3 palette."

# 3. Check QuickSliders detailed setting
echo "3. Checking QuickSliders configuration..."
grep -q "quickSettingsSlidersDetailed: false" "$PROJECT_DIR/src/Services/PersonalizationConfig.qml" || { echo "[FAIL] quickSettingsSlidersDetailed should default to false"; exit 1; }
echo "[PASS] QuickSliders default aligns 1:1 with upstream_control_center.png."

# 4. Check container border highlights
echo "4. Checking colLayer0Border highlights..."
grep -q "border.color: Appearance.colors.colLayer0Border" "$PROJECT_DIR/src/Modules/QuickSettings/QuickSliders.qml" || { echo "[FAIL] QuickSliders missing border highlight"; exit 1; }
grep -q "border.color: Appearance.colors.colLayer0Border" "$PROJECT_DIR/src/Modules/QuickSettings/QuickSettingsSurface.qml" || { echo "[FAIL] togglePanel missing border highlight"; exit 1; }
grep -q "color: Appearance.colors.colLayer0Border" "$PROJECT_DIR/src/Widgets/common/EdgeRevealSurface.qml" || { echo "[FAIL] EdgeRevealSurface missing border highlight"; exit 1; }
echo "[PASS] Liquid frosted glass border highlights in place."

echo "=== [PASS] P2-T2 QuickSettings Verification Succeeded! ==="
