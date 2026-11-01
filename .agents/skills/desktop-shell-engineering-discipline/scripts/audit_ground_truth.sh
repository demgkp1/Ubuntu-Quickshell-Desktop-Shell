#!/usr/bin/env bash
# ==============================================================================
# Desktop Shell Ground-Truth Automated Auditor (Single Source of Truth)
# Enforces Anti-Cheating Tenets, Deep Security Audits, and Real Systems Validation
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$WORKSPACE_ROOT" ]; then
    WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}================================================================${NC}"
echo -e "${BOLD}${BLUE} Linux Desktop Shell Ground-Truth Auditor (Anti-Cheating Gate)  ${NC}"
echo -e "${BOLD}${BLUE}================================================================${NC}"

VIOLATIONS=0

# 1. Audit against Fake Assertions (grep -q used as test verification)
echo -e "\n${BOLD}=== [Check 1] 假断言与形式主义扫描 ===${NC}"
SWALLOWED_TIMEOUT=$(grep -rnE "timeout[[:space:]]+[0-9]+[smh]?[[:space:]]+.*\|\|[[:space:]]*\[[[:space:]]*\\\$(\?|EXIT_CODE)[[:space:]]*-eq[[:space:]]*124[[:space:]]*\]" "$WORKSPACE_ROOT/scripts/" "$WORKSPACE_ROOT/tests/" 2>/dev/null || true)
if [ -n "$SWALLOWED_TIMEOUT" ]; then
    echo -e "${RED}[FAIL] 发现测试脚本吞噬 124 超时强杀，假冒通过！${NC}"
    echo "$SWALLOWED_TIMEOUT"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}[PASS] 未发现吞噬 124 超时作弊模式。${NC}"
fi

# 2. Audit against Plaintext Password / Secret Exposure in cmdline (CWE-214)
echo -e "\n${BOLD}=== [Check 2] 命令行参数明文密码/凭证泄露审计 (CWE-214) ===${NC}"
CRED_LEAKS=$(grep -rnE "(password|secret|token)[[:space:]]*:[[:space:]]*password" "$WORKSPACE_ROOT/src/Services/" 2>/dev/null | grep -E "execDetached|Popen" || true)
if [ -n "$CRED_LEAKS" ]; then
    echo -e "${RED}[FAIL] 发现通过命令行参数直接传递明文密码/Secret！(/proc/*/cmdline 泄露风险)：${NC}"
    echo "$CRED_LEAKS"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}[PASS] 敏感凭证未直接暴露于 CLI 进程参数表。${NC}"
fi

# 3. Audit against Unauthenticated IPC Lock Unlock (CWE-306)
echo -e "\n${BOLD}=== [Check 3] 锁屏 IPC 未鉴权免密后门审计 (CWE-306) ===${NC}"
IPC_LOCK_UNLOCK=$(grep -rnE "IpcHandler[[:space:]]*\{[^\}]*target:[[:space:]]*[\"']lock[\"'][^\}]*function[[:space:]]+unlock" "$WORKSPACE_ROOT/src/" 2>/dev/null || true)
if [ -n "$IPC_LOCK_UNLOCK" ]; then
    echo -e "${RED}[FAIL] 发现锁屏 IPC 存在公开的 unlock() 免密接口！${NC}"
    echo "$IPC_LOCK_UNLOCK"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}[PASS] 锁屏 IPC 未暴露免密 unlock() 后门。${NC}"
fi

# 4. Brace-Depth AST Empty Function & Constant Stub Audit (动态单向递减律)
echo -e "\n${BOLD}=== [Check 4] 字符流括号深度解析状态机全量债务审计 (动态单向递减律) ===${NC}"
python3 - "$WORKSPACE_ROOT" << 'EOF' || VIOLATIONS=$((VIOLATIONS + 1))
import os, sys, re, json, tempfile
from datetime import datetime, timezone

workspace = sys.argv[1]
ratchet_file = os.path.join(workspace, ".debt_ratchet.json")
if not os.path.isfile(ratchet_file):
    print(f"[FAIL] 动态债务追踪文件 {ratchet_file} 不存在！", file=sys.stderr)
    sys.exit(1)

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

print(f"  [DEBT] 真实纯空函数 (Pure Empty Stubs): {curr_pure} (动态基线: {rec_pure})")
print(f"  [DEBT] 常量假实现桩 (Constant Return Stubs): {curr_const} (动态基线: {rec_const})")
print(f"  [DEBT] 伪日志桩 (Logging Stubs): {curr_log} (动态基线: {rec_log})")
print(f"  [DEBT] 死变量假实现桩 (Dead Var Stubs): {curr_dead} (动态基线: {rec_dead})")
print(f"  [DEBT TOTAL] 全仓真实技术债务总计: {curr_total} (动态基线: {rec_total})")

failed = False
if curr_pure > rec_pure:
    print(f"[FAIL] 纯空函数数量 {curr_pure} 超出动态基线 ({rec_pure})！", file=sys.stderr)
    failed = True
if curr_const > rec_const:
    print(f"[FAIL] 常量假实现桩数量 {curr_const} 超出动态基线 ({rec_const})！", file=sys.stderr)
    failed = True
if curr_log > rec_log:
    print(f"[FAIL] 伪日志桩数量 {curr_log} 超出动态基线 ({rec_log})！", file=sys.stderr)
    failed = True
if curr_dead > rec_dead:
    print(f"[FAIL] 死变量假实现桩数量 {curr_dead} 超出动态基线 ({rec_dead})！", file=sys.stderr)
    failed = True
if curr_total > rec_total:
    print(f"[FAIL] 全仓总技术债务 {curr_total} 超出动态基线 ({rec_total})！", file=sys.stderr)
    failed = True

if failed:
    print("FATAL: 违反单向递减律 (The Law of Ratchet)！债务严禁任何形式的反弹与增加！", file=sys.stderr)
    sys.exit(1)

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
    print(f"  [RATCHET] 技术债务消减成功！.debt_ratchet.json 自动锁死新基线 (原: {rec_total} -> 新: {curr_total})！")
EOF

# 5. Pure GPU Rendering Pipeline & Compositor Sanity Check
echo -e "\n${BOLD}=== [Check 5] GPU 硬件渲染管线与 GLX 真实性审计 ===${NC}"
SOFT_BACKEND=$(grep -rnE "QT_QUICK_BACKEND[[:space:]]*=[[:space:]]*[\"']?software[\"']?" "$WORKSPACE_ROOT/scripts/" "$WORKSPACE_ROOT/bin/" 2>/dev/null || true)
if [ -n "$SOFT_BACKEND" ]; then
    echo -e "${RED}[FAIL] 发现强制开启 CPU 软渲染配置！${NC}"
    echo "$SOFT_BACKEND"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}[PASS] 保持纯粹 GPU 硬件渲染加速管线。${NC}"
fi

echo -e "\n================================================================"
if [ "$VIOLATIONS" -gt 0 ]; then
    echo -e "${RED}[FAILURE] 发现 ${VIOLATIONS} 项工程真值或安全违规！立即阻断！${NC}"
    exit 1
else
    echo -e "${GREEN}[SUCCESS] 真值工程审计全部通过！未发现作弊或严重安全后门！${NC}"
    exit 0
fi
