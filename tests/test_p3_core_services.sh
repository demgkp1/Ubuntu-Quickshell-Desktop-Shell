#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== [Test P3] Phase 3 Core Services & LockScreen/Keystone Linkage ==="

# 1. Real Headless QML Runtime Evaluation Harness for NetworkService, BluetoothService & WidgetState
echo "1. Executing real Headless QML Runtime validation harness for Core Services & State Linkage..."
TMP_HARNESS="$PROJECT_DIR/src/test_harness_services_runner.qml"
cat << 'EOF' > "$TMP_HARNESS"
import QtQuick
import Quickshell
import qs.Services
import qs.Common

Scope {
    id: root

    Component.onCompleted: {
        console.log("[HARNESS] Validating services and types in QML runtime...");
        if (typeof NetworkService === "undefined")
            throw new Error("NetworkService undefined in runtime!");
        if (typeof BluetoothService === "undefined")
            throw new Error("BluetoothService undefined in runtime!");
        if (typeof WidgetState === "undefined")
            throw new Error("WidgetState undefined in runtime!");

        console.log("[HARNESS] NetworkService state property:", NetworkService.state);
        console.log("[HARNESS] BluetoothService state property:", BluetoothService.state);
        console.log("[HARNESS] WidgetState.sessionLocked:", WidgetState.sessionLocked);

        // Verify method invocability for NetworkService
        const netMethods = [
            "disconnectNetwork", "connectNetwork", "disconnectWifiNetwork",
            "connectToWifiNetwork", "cancelPasswordRequest", "forgetProfile",
            "forgetNetwork", "connectProfile", "changePassword", "openPublicWifiPortal",
            "acquireScan", "releaseScan", "requestScan", "requestRuntimeDetails", "releaseRuntimeDetails"
        ];
        for (const m of netMethods) {
            if (typeof NetworkService[m] !== "function")
                throw new Error("NetworkService." + m + " is not a callable function!");
        }
        console.log("[HARNESS] All 15 NetworkService methods verified callable in QML runtime.");

        // Verify method invocability for BluetoothService
        const btMethods = [
            "connectDevice", "disconnectDevice", "pairDevice", "forgetDevice",
            "setDeviceTrusted", "setDeviceWakeAllowed", "setDeviceBlocked",
            "_resolveDevice", "_resolveAddress"
        ];
        for (const m of btMethods) {
            if (typeof BluetoothService[m] !== "function")
                throw new Error("BluetoothService." + m + " is not a callable function!");
        }
        console.log("[HARNESS] All 9 BluetoothService methods verified callable in QML runtime.");

        // Test WidgetState state mutation & LockScreen linkage
        if (typeof WidgetState.sessionLocked !== "boolean")
            throw new Error("WidgetState.sessionLocked is not boolean!");
        WidgetState.sessionLocked = true;
        if (!WidgetState.sessionLocked)
            throw new Error("WidgetState.sessionLocked failed to mutate to true!");
        WidgetState.sessionLocked = false;
        if (WidgetState.sessionLocked)
            throw new Error("WidgetState.sessionLocked failed to mutate to false!");
        console.log("[HARNESS] WidgetState.sessionLocked state mutation and linkage verified.");

        console.log("[HARNESS_SUCCESS] Real QML Runtime evaluation passed!");
    }
}
EOF

HARNESS_OUTPUT=$(nix develop "$PROJECT_DIR" --command bash -c '
    export QT_QPA_PLATFORM=offscreen
    unset WAYLAND_DISPLAY
    timeout 3s quickshell -p "'"$TMP_HARNESS"'" 2>&1 || true
')
rm -f "$TMP_HARNESS"

if echo "$HARNESS_OUTPUT" | grep -qiE "(ERROR:|Failed to load configuration|Exception|FATAL)"; then
    echo "[FAIL] QML runtime harness threw errors during execution:"
    echo "$HARNESS_OUTPUT"
    exit 1
fi

if ! echo "$HARNESS_OUTPUT" | grep -q "\[HARNESS_SUCCESS\]"; then
    echo "[FAIL] QML runtime harness did not output [HARNESS_SUCCESS]!"
    echo "$HARNESS_OUTPUT"
    exit 1
fi
echo "[PASS] QML runtime validation passed: NetworkService, BluetoothService & WidgetState dynamically evaluated and verified."

# 2. NetworkService & BluetoothService CLI Subprocess Integration Verification
echo "2. Verifying CLI subprocess execution and captive portal backend..."
NET_SVC="$PROJECT_DIR/src/Services/NetworkService.qml"
BT_SVC="$PROJECT_DIR/src/Services/BluetoothService.qml"

if ! grep -q "nmcli" "$NET_SVC"; then
    echo "[FAIL] NetworkService missing nmcli fallback execution logic"
    exit 1
fi
if ! grep -q "nmcheck.gnome.org" "$NET_SVC"; then
    echo "[FAIL] NetworkService missing captive portal verification target"
    exit 1
fi
if ! grep -q "wifiConnectProc" "$NET_SVC" || ! grep -q "stdinEnabled: true" "$NET_SVC"; then
    echo "[FAIL] NetworkService missing secure stdinEnabled Process (CWE-214 violation)"
    exit 1
fi
WIFI_HELPER="$PROJECT_DIR/src/scripts/system/wifi_helper.py"
if [ ! -f "$WIFI_HELPER" ]; then
    echo "[FAIL] wifi_helper.py missing at $WIFI_HELPER"
    exit 1
fi
if ! grep -q "sys.stdin.readline" "$WIFI_HELPER"; then
    echo "[FAIL] wifi_helper.py must use sys.stdin.readline() to prevent pipe deadlock"
    exit 1
fi
if ! grep -q "bluetoothctl" "$BT_SVC"; then
    echo "[FAIL] BluetoothService missing bluetoothctl fallback execution logic"
    exit 1
fi
echo "[PASS] NetworkService & BluetoothService CLI integration and secure stdin pipeline (CWE-214) verified."

# 3. LockScreen & Keystone Protocol Integration & Mutual Exclusion Verification
echo "3. Verifying LockScreen & Keystone state linkage and focus containment..."
LOCK_ROOT="$PROJECT_DIR/src/Modules/Lock/Lock.qml"
LOCK_WIN="$PROJECT_DIR/src/Modules/Lock/LockWindow.qml"
KEYSTONE_ROOT="$PROJECT_DIR/src/Modules/Keystone/Keystone.qml"
KEYSTONE_SURFACE="$PROJECT_DIR/src/Modules/Keystone/Styles/Shared/KeystoneSurface.qml"

if ! grep -q "target: WidgetState" "$LOCK_ROOT" || ! grep -q 'property: "sessionLocked"' "$LOCK_ROOT"; then
    echo "[FAIL] Lock.qml missing Binding to WidgetState.sessionLocked"
    exit 1
fi
if ! grep -q "WidgetState.closeAllPopups()" "$LOCK_ROOT"; then
    echo "[FAIL] Lock.qml missing closeAllPopups on active change"
    exit 1
fi
if ! grep -q "forceActiveFocus(Qt.OtherFocusReason)" "$LOCK_WIN"; then
    echo "[FAIL] LockWindow.qml missing focus grab for interactionHost"
    exit 1
fi
if ! grep -q "WidgetState.sessionLocked" "$KEYSTONE_ROOT"; then
    echo "[FAIL] Keystone.qml missing WidgetState.sessionLocked check in invoke()"
    exit 1
fi
if ! grep -q "SESSION_LOCKED" "$KEYSTONE_ROOT"; then
    echo "[FAIL] Keystone.qml invoke() missing SESSION_LOCKED suppression return"
    exit 1
fi
if ! grep -q "!WidgetState.sessionLocked" "$KEYSTONE_SURFACE"; then
    echo "[FAIL] KeystoneSurface.qml missing !WidgetState.sessionLocked visibility binding"
    exit 1
fi
echo "[PASS] LockScreen & Keystone state linkage and mutual exclusion verified."

# 4. Law of Ratchet (Single-direction debt decrement) Verification
echo "4. Verifying Law of Ratchet against .debt_ratchet.json (0 stubs in network/bluetooth)..."
STUBS_INFO=$(python3 - "$PROJECT_DIR" << 'EOF'
import os, sys, re, json

workspace = sys.argv[1]
ratchet_file = os.path.join(workspace, ".debt_ratchet.json")
if not os.path.isfile(ratchet_file):
    print("FATAL: .debt_ratchet.json missing!", file=sys.stderr)
    sys.exit(1)

with open(ratchet_file, "r", encoding="utf-8") as f:
    recorded = json.load(f)

rec_pure = recorded.get("pure_stubs", 16)
rec_const = recorded.get("constant_stubs", 31)
rec_log = recorded.get("logging_stubs", 0)
rec_dead = recorded.get("dead_var_stubs", 0)
rec_total = recorded.get("total_debt", 47)

def scan_file_stubs(filepath):
    with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()
    n = len(content)
    i = 0
    stubs = []
    while i < n:
        if content[i:i+2] == "//":
            i += 2
            while i < n and content[i] != "\n":
                i += 1
            continue
        if content[i:i+2] == "/*":
            i += 2
            while i < n and content[i:i+2] != "*/":
                i += 1
            i += 2
            continue
        if content[i] in ("\"", "\'", "`"):
            quote = content[i]
            i += 1
            while i < n:
                if content[i] == "\\":
                    i += 2
                    continue
                if content[i] == quote:
                    i += 1
                    break
                i += 1
            continue
        is_func = False
        func_sig = ""
        if content[i:i+8] == "function" and (i == 0 or not (content[i-1].isalnum() or content[i-1] == "_")) and (i+8 >= n or not (content[i+8].isalnum() or content[i+8] == "_")):
            brace_pos = content.find("{", i+8)
            if brace_pos != -1:
                sig_part = content[i:brace_pos].strip()
                if "(" in sig_part and ")" in sig_part:
                    is_func = True
                    func_sig = sig_part
                    i = brace_pos
        elif content[i:i+2] == "=>":
            k = i + 2
            while k < n and content[k].isspace():
                k += 1
            if k < n and content[k] == "{":
                is_func = True
                func_sig = "arrow_func =>"
                i = k
        if is_func and i < n and content[i] == "{":
            depth = 1
            i += 1
            body_chars = []
            while i < n and depth > 0:
                c = content[i]
                if content[i:i+2] == "//":
                    while i < n and content[i] != "\n":
                        i += 1
                    continue
                elif content[i:i+2] == "/*":
                    i += 2
                    while i < n and content[i:i+2] != "*/":
                        i += 1
                    i += 2
                    continue
                elif c in ("\"", "\'", "`"):
                    quote = c
                    body_chars.append(c)
                    i += 1
                    while i < n:
                        if content[i] == "\\":
                            body_chars.append(content[i:i+2])
                            i += 2
                            continue
                        body_chars.append(content[i])
                        if content[i] == quote:
                            i += 1
                            break
                        i += 1
                    continue
                elif c == "{":
                    depth += 1
                    body_chars.append(c)
                    i += 1
                elif c == "}":
                    depth -= 1
                    if depth > 0:
                        body_chars.append(c)
                    i += 1
                else:
                    body_chars.append(c)
                    i += 1
            clean_body = "".join(body_chars).strip()
            normalized = re.sub(r"\s+", " ", clean_body)
            stub_type = None
            if not clean_body:
                stub_type = "pure"
            elif normalized in ["return null;", "return [];", "return false;", "return \"\";", "return '';", "return true;", "return 0;"]:
                stub_type = "constant"
            else:
                stripped_log = re.sub(r"console\.[a-zA-Z0-9_]+\([^)]*\)", "", clean_body)
                stripped_log = re.sub(r"\breturn\b|[;\s]", "", stripped_log)
                if len(stripped_log) == 0:
                    stub_type = "logging"
                else:
                    stripped_var = re.sub(r"\b(?:const|let|var)\s+[a-zA-Z0-9_$]+(?:\s*=\s*[^;]+)?;", "", clean_body)
                    stripped_var = re.sub(r"\breturn\b|[;\s]", "", stripped_var)
                    if len(stripped_var) == 0:
                        stub_type = "dead_var"
            
            if stub_type:
                stubs.append((stub_type, func_sig, filepath, clean_body))
            continue
        i += 1
    return stubs

EXCLUDE_DIRS = {
    ".git", ".direnv", "result", "tests", "reference", "docs", "tools",
    "build", "node_modules", ".agents"
}

curr_counts = {"pure": 0, "constant": 0, "logging": 0, "dead_var": 0}
svc_stubs = 0
for root, dirs, files in os.walk(workspace):
    dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS and not d.startswith(".")]
    for f in files:
        if f.endswith((".qml", ".js")):
            p = os.path.join(root, f)
            for item in scan_file_stubs(p):
                curr_counts[item[0]] += 1
                if "NetworkService" in p or "BluetoothService" in p:
                    svc_stubs += 1

curr_pure = curr_counts["pure"]
curr_const = curr_counts["constant"]
curr_log = curr_counts["logging"]
curr_dead = curr_counts["dead_var"]
curr_total = curr_pure + curr_const + curr_log + curr_dead

print(f"{curr_pure}|{curr_const}|{curr_log}|{curr_dead}|{curr_total}|{rec_pure}|{rec_const}|{rec_log}|{rec_dead}|{rec_total}|{svc_stubs}")
EOF
)

CURR_PURE=$(echo "$STUBS_INFO" | cut -d'|' -f1)
CURR_CONST=$(echo "$STUBS_INFO" | cut -d'|' -f2)
CURR_LOG=$(echo "$STUBS_INFO" | cut -d'|' -f3)
CURR_DEAD=$(echo "$STUBS_INFO" | cut -d'|' -f4)
CURR_TOTAL=$(echo "$STUBS_INFO" | cut -d'|' -f5)
REC_PURE=$(echo "$STUBS_INFO" | cut -d'|' -f6)
REC_CONST=$(echo "$STUBS_INFO" | cut -d'|' -f7)
REC_LOG=$(echo "$STUBS_INFO" | cut -d'|' -f8)
REC_DEAD=$(echo "$STUBS_INFO" | cut -d'|' -f9)
REC_TOTAL=$(echo "$STUBS_INFO" | cut -d'|' -f10)
SVC_STUBS=$(echo "$STUBS_INFO" | cut -d'|' -f11)

if [ "$SVC_STUBS" -ne 0 ]; then
    echo "[FAIL] Found $SVC_STUBS empty/constant stubs in NetworkService / BluetoothService!"
    exit 1
fi

if [ "$CURR_PURE" -gt "$REC_PURE" ]; then
    echo "[FAIL] Pure stubs $CURR_PURE exceeds ratchet baseline of $REC_PURE!"
    exit 1
fi

if [ "$CURR_CONST" -gt "$REC_CONST" ]; then
    echo "[FAIL] Constant stubs $CURR_CONST exceeds ratchet baseline of $REC_CONST!"
    exit 1
fi

if [ "$CURR_LOG" -gt "$REC_LOG" ]; then
    echo "[FAIL] Logging stubs $CURR_LOG exceeds ratchet baseline of $REC_LOG!"
    exit 1
fi

if [ "$CURR_DEAD" -gt "$REC_DEAD" ]; then
    echo "[FAIL] Dead var stubs $CURR_DEAD exceeds ratchet baseline of $REC_DEAD!"
    exit 1
fi

if [ "$CURR_TOTAL" -gt "$REC_TOTAL" ]; then
    echo "[FAIL] Total debt $CURR_TOTAL exceeds ratchet baseline of $REC_TOTAL!"
    exit 1
fi
echo "[PASS] Law of Ratchet verified: Pure: $CURR_PURE (<=$REC_PURE), Constant: $CURR_CONST (<=$REC_CONST), Logging: $CURR_LOG (<=$REC_LOG), Total: $CURR_TOTAL (<=$REC_TOTAL), 0 stubs in Network/Bluetooth."

echo "=== [SUCCESS] Phase 3 Core Services & LockScreen/Keystone Linkage Verified! ==="
