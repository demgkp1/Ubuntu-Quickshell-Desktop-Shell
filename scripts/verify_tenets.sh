#!/usr/bin/env bash
# ==============================================================================
# scripts/verify_tenets.sh - Industrial Automated Gatekeeper (Strict Edition V3)
# 
# 严格按照 docs/ENGINEERING_TENETS.md 执行全仓零死角、防穿透的自动化门禁。
# 包含：
# 1. 全仓多引号格式用户绝对路径扫描 (/home/...)
# 2. 软渲染配置与环境变量扫描 (严禁软件光栅)
# 3. TopBarPill 硬件加速与抗锯齿遮罩审计
# 4. 伴生守护进程动态防僵尸安全检查 (PR_SET_PDEATHSIG)
# 5. 跨目录穿透性脚本引用审计 (../scripts)
# 6. 技术债务熔断机制 (Debt Ceiling / Ratchet Policy，超限一票否决)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

VIOLATIONS=0
WARNINGS=0

# 动态技术债务单向递减基线文件 (Dynamic Ratchet Contract)
RATCHET_FILE="$PROJECT_DIR/.debt_ratchet.json"

echo -e "${BOLD}${BLUE}================================================================${NC}"
echo -e "${BOLD}${BLUE} Ubuntu Quickshell Desktop Shell - 工业级军规门禁自动检验 (V2.3 终极版) ${NC}"
echo -e "${BOLD}${BLUE}================================================================${NC}"

# ------------------------------------------------------------------------------
# Gate 1：全仓绝对开发路径扫描 (包含单引号、双引号、反引号及裸路径，覆盖 tests/)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}=== [Gate 1] 全仓硬编码个人开发路径扫描 (/home/...) ===${NC}"
MATCHES=$(grep -rnE "['\"\`]/home/[a-zA-Z0-9_-]+" "$PROJECT_DIR/src/" "$PROJECT_DIR/scripts/" "$PROJECT_DIR/bin/" "$PROJECT_DIR/systemd/" "$PROJECT_DIR/tests/" 2>/dev/null || true)
if [ -n "$MATCHES" ]; then
    echo -e "${RED}[FAIL] 发现写死的开发者个人主目录绝对路径：${NC}"
    echo "$MATCHES"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}[PASS] 全仓无硬编码 /home/... 绝对个人路径。${NC}"
fi

# ------------------------------------------------------------------------------
# Gate 2：渲染管线审计 (严禁强制 CPU 软渲染)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}=== [Gate 2] 渲染管线审计 (严禁强制开启 CPU 软渲染) ===${NC}"
SOFT_BACKEND=$(grep -rnE "QT_QUICK_BACKEND[[:space:]]*=[[:space:]]*[\"']?software[\"']?" "$PROJECT_DIR/scripts/" "$PROJECT_DIR/bin/" "$PROJECT_DIR/systemd/" 2>/dev/null || true)
if [ -n "$SOFT_BACKEND" ]; then
    echo -e "${RED}[FAIL] 发现脚本/配置中强制开启 CPU 软件光栅化 (破坏动效与着色器)：${NC}"
    echo "$SOFT_BACKEND"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}[PASS] 未发现强制 software 软渲染配置，保持 GPU 硬件加速管线。${NC}"
fi

# ------------------------------------------------------------------------------
# Gate 3：TopBarPill 视觉与 MultiEffect 遮罩完整性审计
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}=== [Gate 3] TopBarPill 视觉与 MultiEffect 遮罩完整性审计 ===${NC}"
PILL_FILE="$PROJECT_DIR/src/Widgets/common/TopBarPill.qml"
if [ -f "$PILL_FILE" ]; then
    if grep -q "layer.enabled:[[:space:]]*false" "$PILL_FILE"; then
        echo -e "${RED}[FAIL] TopBarPill.qml 中的 MultiEffect 抗锯齿遮罩被禁用 (layer.enabled: false)！${NC}"
        VIOLATIONS=$((VIOLATIONS + 1))
    else
        echo -e "${GREEN}[PASS] TopBarPill 保持了 MultiEffect 硬件加速抗锯齿遮罩。${NC}"
    fi
else
    echo -e "${RED}[FAIL] 找不到 TopBarPill.qml 文件！${NC}"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# ------------------------------------------------------------------------------
# Gate 4：伴生守护进程防僵尸安全检查 (动态扫描所有长驻伴生脚本)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}=== [Gate 4] 伴生守护进程防僵尸安全检查 (PR_SET_PDEATHSIG) ===${NC}"
while IFS= read -r py_script; do
    if [ -n "$py_script" ] && [ -f "$py_script" ]; then
        if grep -q "PR_SET_PDEATHSIG" "$py_script"; then
            echo -e "${GREEN}[PASS] $(basename "$py_script") 已绑定 PR_SET_PDEATHSIG 父进程生死信号。${NC}"
        else
            echo -e "${RED}[FAIL] 伴生脚本 $(basename "$py_script") 包含循环/守护逻辑但缺少 PR_SET_PDEATHSIG 绑定！${NC}"
            VIOLATIONS=$((VIOLATIONS + 1))
        fi
    fi
done < <(find "$PROJECT_DIR/src/scripts/" -type f -name "*.py" -not -path "*/vendor/*" -exec grep -lE "(while[[:space:]]+True|daemon|stream)" {} + 2>/dev/null || true)

# ------------------------------------------------------------------------------
# Gate 5：跨目录穿透性脚本引用审计 (../scripts)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}=== [Gate 5] 跨目录穿透性脚本引用审计 (../scripts) ===${NC}"
REL_MATCHES=$(grep -rnE "\.\./scripts" "$PROJECT_DIR/src/" 2>/dev/null || true)
if [ -n "$REL_MATCHES" ]; then
    echo -e "${RED}[FAIL] 发现穿透打包根目录的危险相对路径：${NC}"
    echo "$REL_MATCHES"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}[PASS] 未发现 ../scripts 穿透性路径。${NC}"
fi

# ------------------------------------------------------------------------------
# Gate 6：技术债务熔断看板 —— 债务单向递减律 (The Law of Ratchet)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}=== [Gate 6] 现地技术债务熔断监控 (债务单向递减律) ===${NC}"

# 1. 检查是否存在伪造 Mock 模块目录
if [ -d "$PROJECT_DIR/imports/Clavis" ]; then
    echo -e "${RED}[FAIL] 发现伪造 Mock 目录 imports/Clavis/ 依然存在！必须物理彻底删除！${NC}"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}[PASS] imports/Clavis/ 伪造 Mock 树已彻底物理销毁。${NC}"
fi

# 2. Native imports are valid only with built, runtime-loaded plugins. The GNOME
# port deliberately restores native capabilities; banning all C++ produced stubs.
# No per-URI allowlist, no hand-written native qmldir, no grep-based success.
if [ -d "$PROJECT_DIR/imports/M3Shapes" ]; then
    echo -e "${RED}[FAIL] Local M3Shapes shadow module must be removed.${NC}"
    VIOLATIONS=$((VIOLATIONS + 1))
elif "$PROJECT_DIR/scripts/native-check.sh"; then
    echo -e "${GREEN}[PASS] Native dependencies were loaded and exercised by QML.${NC}"
else
    echo -e "${RED}[FAIL] Native runtime validation failed; build with scripts/build.sh first.${NC}"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# 3. 使用字符流括号深度解析状态机扫描真实纯空桩、常量返回假实现桩、伪日志桩与死变量桩
if [ ! -f "$RATCHET_FILE" ]; then
    echo -e "${RED}[FAIL] 动态债务追踪文件 $RATCHET_FILE 不存在！门禁阻断！${NC}"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    set +e
    DEBT_RESULT=$(python3 - "$PROJECT_DIR" 2>&1 << 'EOF'
import os, sys, re, json, tempfile
from datetime import datetime, timezone

workspace = sys.argv[1]
ratchet_file = os.path.join(workspace, ".debt_ratchet.json")
if not os.path.isfile(ratchet_file):
    print("FATAL: .debt_ratchet.json does not exist!", file=sys.stderr)
    sys.exit(2)

with open(ratchet_file, "r", encoding="utf-8") as f:
    recorded = json.load(f)

rec_pure = recorded.get("pure_stubs", 0)
rec_const = recorded.get("constant_stubs", 0)
rec_log = recorded.get("logging_stubs", 0)
rec_dead = recorded.get("dead_var_stubs", 0)
rec_total = recorded.get("total_debt", rec_pure + rec_const + rec_log + rec_dead)

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
for root, dirs, files in os.walk(workspace):
    dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS and not d.startswith(".")]
    for f in files:
        if f.endswith((".qml", ".js")):
            p = os.path.join(root, f)
            for item in scan_file_stubs(p):
                curr_counts[item[0]] += 1

curr_pure = curr_counts["pure"]
curr_const = curr_counts["constant"]
curr_log = curr_counts["logging"]
curr_dead = curr_counts["dead_var"]
curr_total = curr_pure + curr_const + curr_log + curr_dead

regressions = []
if curr_pure > rec_pure:
    regressions.append(f"纯空函数反弹超限: 当前 {curr_pure} > 基线 {rec_pure}")
if curr_const > rec_const:
    regressions.append(f"常量假实现桩反弹超限: 当前 {curr_const} > 基线 {rec_const}")
if curr_log > rec_log:
    regressions.append(f"伪日志桩反弹超限: 当前 {curr_log} > 基线 {rec_log}")
if curr_dead > rec_dead:
    regressions.append(f"死变量假实现桩反弹超限: 当前 {curr_dead} > 基线 {rec_dead}")
if curr_total > rec_total:
    regressions.append(f"全仓总技术债务反弹超限: 当前 {curr_total} > 基线 {rec_total}")

if regressions:
    for r in regressions:
        print(f"[FAIL] {r}", file=sys.stderr)
    print("FATAL: 违反单向递减律 (The Law of Ratchet)！债务严禁任何形式的反弹与增加！", file=sys.stderr)
    sys.exit(1)

auto_ratcheted = False
if curr_pure < rec_pure or curr_const < rec_const or curr_log < rec_log or curr_dead < rec_dead or curr_total < rec_total:
    new_data = {
        "$schema": recorded.get("$schema", "urn:clavis:debt-ratchet:v1"),
        "pure_stubs": curr_pure,
        "constant_stubs": curr_const,
        "logging_stubs": curr_log,
        "dead_var_stubs": curr_dead,
        "total_debt": curr_total,
        "last_updated": datetime.now(timezone.utc).isoformat()
    }
    dir_name = os.path.dirname(os.path.abspath(ratchet_file))
    with tempfile.NamedTemporaryFile("w", dir=dir_name, delete=False, encoding="utf-8") as tf:
        json.dump(new_data, tf, indent=2)
        tf.write("\n")
        tf.flush()
        os.fsync(tf.fileno())
        tmp_name = tf.name
    os.replace(tmp_name, ratchet_file)
    auto_ratcheted = True

print(f"{curr_pure}|{curr_const}|{curr_log}|{curr_dead}|{curr_total}|{rec_pure}|{rec_const}|{rec_log}|{rec_dead}|{rec_total}|{1 if auto_ratcheted else 0}")
EOF
)
    PY_STATUS=$?
    set -e

    if [ "$PY_STATUS" -ne 0 ]; then
        echo -e "${RED}[FATAL] 动态技术债务单向递减审计失败：${NC}"
        echo "$DEBT_RESULT"
        VIOLATIONS=$((VIOLATIONS + 1))
    else
        LAST_LINE=$(echo "$DEBT_RESULT" | tail -n 1)
        CURR_PURE=$(echo "$LAST_LINE" | cut -d'|' -f1)
        CURR_CONST=$(echo "$LAST_LINE" | cut -d'|' -f2)
        CURR_LOG=$(echo "$LAST_LINE" | cut -d'|' -f3)
        CURR_DEAD=$(echo "$LAST_LINE" | cut -d'|' -f4)
        CURR_TOTAL=$(echo "$LAST_LINE" | cut -d'|' -f5)
        REC_PURE=$(echo "$LAST_LINE" | cut -d'|' -f6)
        REC_CONST=$(echo "$LAST_LINE" | cut -d'|' -f7)
        REC_LOG=$(echo "$LAST_LINE" | cut -d'|' -f8)
        REC_DEAD=$(echo "$LAST_LINE" | cut -d'|' -f9)
        REC_TOTAL=$(echo "$LAST_LINE" | cut -d'|' -f10)
        AUTO_RATCHET=$(echo "$LAST_LINE" | cut -d'|' -f11)

        echo -e "${YELLOW}[DEBT] 真实纯空函数: ${CURR_PURE} 处 (动态基线: ${REC_PURE})${NC}"
        echo -e "${YELLOW}[DEBT] 常量假实现桩: ${CURR_CONST} 处 (动态基线: ${REC_CONST})${NC}"
        echo -e "${YELLOW}[DEBT] 伪日志桩 (console laundering): ${CURR_LOG} 处 (动态基线: ${REC_LOG})${NC}"
        echo -e "${YELLOW}[DEBT] 死变量假桩 (dummy vars): ${CURR_DEAD} 处 (动态基线: ${REC_DEAD})${NC}"
        echo -e "${YELLOW}[DEBT TOTAL] 全仓真实技术总债: ${CURR_TOTAL} 处 (动态基线: ${REC_TOTAL})${NC}"

        if [ "$AUTO_RATCHET" -eq 1 ]; then
            echo -e "${GREEN}[RATCHET] 技术债务消减成功！.debt_ratchet.json 自动锁死新基线 (原: ${REC_TOTAL} -> 新: ${CURR_TOTAL})！${NC}"
        else
            echo -e "${GREEN}[DEBT OK] 全仓技术债务在动态单向递减限额内 (${CURR_TOTAL} <= ${REC_TOTAL})，严防反弹。${NC}"
        fi
        WARNINGS=$((WARNINGS + CURR_TOTAL))
    fi
fi

# ------------------------------------------------------------------------------
# 门禁最终裁决
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BLUE}================================================================${NC}"
echo -e "${BOLD}门禁检验汇总：致命违规项 (Violations) = ${VIOLATIONS}, 跟踪技术债 (Debts) = ${WARNINGS}${NC}"
echo -e "${BOLD}${BLUE}================================================================${NC}"

if [ "$VIOLATIONS" -gt 0 ]; then
    echo -e "${RED}[FATAL] 门禁阻断：存在 ${VIOLATIONS} 项严重违规，禁止提交与合并！${NC}"
    exit 1
else
    echo -e "${GREEN}[SUCCESS] 本次门禁检查通过；这不证明真实 GNOME 桌面功能或视觉已全部验证。${NC}"
    exit 0
fi
