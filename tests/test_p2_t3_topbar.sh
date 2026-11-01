#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== [Test P2-T3] TopBar Pills & Dynamic Hardware Adaptation ==="

# 1. Battery Hardware Zero-Occupancy Inspection
echo "1. Checking Battery physical hardware adaptation and 0px occupancy..."
grep -q "detectPhysicalBattery" "$PROJECT_DIR/src/Services/PowerService.qml" || {
    echo "[FAIL] PowerService missing detectPhysicalBattery implementation"
    exit 1
}
grep -q "readonly property bool hasPhysicalBattery" "$PROJECT_DIR/src/Services/PowerService.qml" || {
    echo "[FAIL] PowerService missing hasPhysicalBattery property"
    exit 1
}
grep -q "Layout.preferredWidth: visible ? implicitWidth : 0" "$PROJECT_DIR/src/Modules/Bar/QuickSettings/Battery.qml" || {
    echo "[FAIL] Battery.qml missing 0-width collapse on invisible"
    exit 1
}
grep -q "Layout.preferredHeight: visible ? implicitHeight : 0" "$PROJECT_DIR/src/Modules/Bar/QuickSettings/Battery.qml" || {
    echo "[FAIL] Battery.qml missing 0-height collapse on invisible"
    exit 1
}
grep -q "hasPhysicalBattery" "$PROJECT_DIR/src/Modules/Bar/QuickSettings/QuickSettings.qml" || {
    echo "[FAIL] QuickSettings.qml Loader missing hasPhysicalBattery awareness"
    exit 1
}
grep -q "!root.hasPhysicalBattery ? \"\" :" "$PROJECT_DIR/src/Modules/Bar/QuickSettings/Battery.qml" || {
    echo "[FAIL] Battery.qml should not show question mark icon when no physical battery is present"
    exit 1
}
echo "[PASS] Battery hardware auto-hide and 0px occupancy verified."

# 2. Brightness Software Dimmer Fallback Inspection
echo "2. Checking Brightness software dimmer fallback..."
grep -q "hasHardwareBacklight" "$PROJECT_DIR/src/Services/Brightness.qml" || {
    echo "[FAIL] Brightness.qml missing hasHardwareBacklight property"
    exit 1
}
grep -q "DisplayColor.setDimming(targetValue)" "$PROJECT_DIR/src/Services/Brightness.qml" || {
    echo "[FAIL] Brightness.qml not routing to DisplayColor.setDimming when backlight absent"
    exit 1
}
grep -q "isSoftwareDimmer: \!Brightness.hasHardwareBacklight" "$PROJECT_DIR/src/Modules/Bar/QuickSettings/Brightness.qml" || {
    echo "[FAIL] Brightness.qml in Bar missing isSoftwareDimmer binding"
    exit 1
}
grep -q "icon: root.isSoftwareDimmer ? \"wb_twilight\" : \"brightness_medium\"" "$PROJECT_DIR/src/Modules/Bar/QuickSettings/Brightness.qml" || {
    echo "[FAIL] Brightness.qml in Bar missing adaptive icon for software dimmer"
    exit 1
}
echo "[PASS] Brightness software dimmer fallback pipeline verified."

# 3. TopBarPill GPU Hardware Acceleration & Anti-Aliasing Mask
echo "3. Checking TopBarPill MultiEffect hardware shaders..."
grep -q "MultiEffect" "$PROJECT_DIR/src/Widgets/common/TopBarPill.qml" || {
    echo "[FAIL] TopBarPill.qml missing MultiEffect"
    exit 1
}
grep -q "maskEnabled: true" "$PROJECT_DIR/src/Widgets/common/TopBarPill.qml" || {
    echo "[FAIL] TopBarPill.qml missing maskEnabled"
    exit 1
}
grep -q "maskSource: contentMask" "$PROJECT_DIR/src/Widgets/common/TopBarPill.qml" || {
    echo "[FAIL] TopBarPill.qml missing maskSource"
    exit 1
}
grep -q "MultiEffect" "$PROJECT_DIR/src/Widgets/common/TopBarPillBackground.qml" || {
    echo "[FAIL] TopBarPillBackground.qml missing MultiEffect shadow"
    exit 1
}
grep -q "Variants" "$PROJECT_DIR/src/shell.qml" || {
    echo "[FAIL] shell.qml missing Variants for multi-screen TopBar derivation"
    exit 1
}
echo "[PASS] TopBarPill MultiEffect hardware acceleration verified."

# 4. Strictly Prohibit Software Backend Degrade
echo "4. Checking absence of QT_QUICK_BACKEND=software..."
if grep -rn "QT_QUICK_BACKEND=\"software\"" "$PROJECT_DIR/src/" "$PROJECT_DIR/bin/" 2>/dev/null; then
    echo "[FAIL] Software rasterization backend found in codebase!"
    exit 1
fi
echo "[PASS] No software rasterization override detected."

echo "=== [PASS] P2-T3 TopBar Pills & Hardware Adaptation Succeeded! ==="
