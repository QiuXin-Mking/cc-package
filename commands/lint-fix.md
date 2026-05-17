---
description: Autonomous golangci-lint batch-fixer — 3 fixes per iteration with compile + lint verification gates
argument-hint: [N]  iterations (default 50)
allowed-tools: Bash, Read, Write
---

# Lint Auto-Fix

Self-contained golangci-lint batch-fixer. On first run, bootstraps `AAA_fix_lint/`.
Runs `claude -p` in a loop using your default model, each iteration fixing exactly 3
issues with `make bin` + `make lint` verification. Resumable on interrupt.

Your role: **launch, monitor, troubleshoot**.

## Phase 0: Bootstrap (first run only)

If `AAA_fix_lint/loop.sh` doesn't exist, create it:

```bash
mkdir -p AAA_fix_lint/logs
```

Then write each file:

```bash
# 1. loop.sh
cat <<'LOOP_EOF' > AAA_fix_lint/loop.sh
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(pwd)"

MAX_ITER=${MAX_ITER:-50}
SINGLE_TIMEOUT=${SINGLE_TIMEOUT:-600}
MAX_RETRY_SAME_ERROR=${MAX_RETRY_SAME_ERROR:-3}
PROGRESS_FILE="${PROGRESS_FILE:-${SCRIPT_DIR}/PROGRESS.md}"
CONSTITUTION_FILE="${CONSTITUTION_FILE:-${SCRIPT_DIR}/LINT_CONSTITUTION.md}"
LOG_DIR="${LOG_DIR:-${SCRIPT_DIR}/logs}"
GO_PROJECT_DIR=${GO_PROJECT_DIR:-${PROJECT_ROOT}}

mkdir -p "$LOG_DIR"

cleanup() {
    echo ""
    echo "Interrupted, cleaning up..."
    jobs -p | xargs -r kill -TERM 2>/dev/null
    sleep 3
    jobs -p | xargs -r kill -9 2>/dev/null
    echo "Stopped"
    exit 130
}
trap cleanup SIGINT SIGTERM

if [ ! -f "$PROGRESS_FILE" ]; then
    echo "ERROR: $PROGRESS_FILE missing"
    exit 1
fi
if [ ! -f "$CONSTITUTION_FILE" ]; then
    echo "ERROR: $CONSTITUTION_FILE missing"
    exit 1
fi

get_status() {
    grep "^## Status:" "$PROGRESS_FILE" 2>/dev/null | sed 's/## Status: //' | tr -d ' '
}

get_iteration() {
    grep "^\- Iteration:" "$PROGRESS_FILE" 2>/dev/null | sed 's/- Iteration: //' | tr -d ' '
}

get_error_log() {
    sed -n '/## Error Log/,$ p' "$PROGRESS_FILE" | tail -n +2 | head -5
}

update_iteration() {
    local iter=$1
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^- Iteration:.*/- Iteration: $iter/" "$PROGRESS_FILE"
    else
        sed -i "s/^- Iteration:.*/- Iteration: $iter/" "$PROGRESS_FILE"
    fi
}

build_prompt() {
    cat <<'PROMPT_EOF'
你是 Go 项目 golangci-lint 自主修复助手。请严格按照以下协议执行：

## 第一步：读取项目宪法（必须！）
读取 AAA_fix_lint/LINT_CONSTITUTION.md，这是你这次任务的"法律"。每次启动都必须重新读一遍，不要凭记忆。

## 第二步：读取进度文件
读取 AAA_fix_lint/PROGRESS.md，重点关注 Status、Next Step、Error Log、Stats。

## 第三步：执行 Next Step
按照 LINT_CONSTITUTION.md 中的修复策略执行：

1. 运行 golangci-lint 获取当前问题
2. 聚焦 Next Step 指定的 package 和 linter 类别
3. **每次 session 只修复 3 个 lint 问题**（不多不少，除非剩余不足 3 个）
4. 修复完成后执行 **make bin 2>&1 >bin.log** 编译
5. **检查 bin.log 确认编译通过**，编译失败则分析错误 → 修复 → 重新编译，直到通过
6. 编译通过后执行 **make lint 2>&1 >lint.log**
7. **阅读 lint.log，对比修复前后的 lint 问题数量**，确认减少了

编译闭环 + lint 收敛，两条都是硬性要求，缺一不可。

## 第四步：更新 PROGRESS.md（必须执行！）
- 成功 → 任务从 Next Step 移到 Completed，更新 Stats
- 全部完成 → Status 改为 done
- 遇到错误 → 在 Error Log 中记录具体错误信息
- 记录关键决策到 Key Decisions（如：为何对某处用了 nolint）

## 重要约束
- 只做 Next Step 中列出的任务
- 每步结束时必须更新 PROGRESS.md
- 同一问题连续 3 次失败 → Status 改为 blocked
- 禁止用 //nolint 批量关闭问题

开始执行。
PROMPT_EOF
}

main() {
    local iter
    local last_error=""
    local same_error_count=0

    iter=$(get_iteration)
    if [ -z "$iter" ]; then
        iter=0
    fi

    echo "============================================"
    echo "Golangci-lint Auto-Fix"
    echo "   Project: $GO_PROJECT_DIR"
    echo "   Max iterations: $MAX_ITER"
    echo "   Per-iteration timeout: ${SINGLE_TIMEOUT}s"
    echo "============================================"

    while [ "$iter" -lt "$MAX_ITER" ]; do
        iter=$((iter + 1))
        echo ""
        echo "=== Iteration $iter / $MAX_ITER ==="

        local status
        status=$(get_status)
        echo "Status: $status"

        if [ "$status" = "done" ]; then
            echo "All done!"
            exit 0
        fi

        if [ "$status" = "blocked" ]; then
            echo "Blocked — manual intervention needed"
            cat "$PROGRESS_FILE"
            exit 1
        fi

        update_iteration "$iter"

        echo "Launching Claude Code..."
        local log_file="$LOG_DIR/iter_$(printf '%04d' $iter).log"
        local prompt
        prompt=$(build_prompt)

        local session_id
        session_id=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())")

        (
            claude -p "$prompt" \
                --session-id "$session_id" \
                --no-session-persistence \
                --add-dir "$SCRIPT_DIR" \
                --add-dir "$GO_PROJECT_DIR" \
                --output-format text \
                2>&1
        ) > "$log_file" &
        local claude_pid=$!

        (
            sleep "$SINGLE_TIMEOUT"
            if kill -0 $claude_pid 2>/dev/null; then
                echo "Timeout (${SINGLE_TIMEOUT}s), sending SIGTERM..."
                kill -TERM $claude_pid 2>/dev/null
                sleep 10
                if kill -0 $claude_pid 2>/dev/null; then
                    echo "No response, sending SIGKILL..."
                    kill -9 $claude_pid 2>/dev/null
                fi
            fi
        ) &
        local watchdog_pid=$!

        local exit_code=0
        wait $claude_pid 2>/dev/null || exit_code=$?
        kill $watchdog_pid 2>/dev/null || true

        if [ "$exit_code" -ne 0 ]; then
            echo "Abnormal exit: $exit_code"

            local current_error
            current_error=$(get_error_log)
            if [ "$current_error" = "$last_error" ] && [ -n "$current_error" ]; then
                same_error_count=$((same_error_count + 1))
                echo "Same error #$same_error_count"
                if [ "$same_error_count" -ge "$MAX_RETRY_SAME_ERROR" ]; then
                    echo "Circuit breaker: same error $MAX_RETRY_SAME_ERROR times, blocked"
                    exit 1
                fi
            else
                same_error_count=1
                last_error="$current_error"
            fi
        else
            same_error_count=0
            last_error=""
        fi

        status=$(get_status)
        if [ "$status" = "done" ]; then
            echo "All done! Total iterations: $iter"
            exit 0
        fi

        sleep 2
    done

    echo "Max iterations ($MAX_ITER) reached."
    exit 1
}

main "$@"
LOOP_EOF

chmod +x AAA_fix_lint/loop.sh

# 2. LINT_CONSTITUTION.md
cat <<'CONST_EOF' > AAA_fix_lint/LINT_CONSTITUTION.md
# Lint 修复宪法

## Linter 优先级
**必须修复（阻塞 CI）**: errcheck, govet, staticcheck, ineffassign, unused
**逐步修复（不阻塞 CI）**: revive, gocritic, gosec, gocyclo, dupl

## 修复策略
1. 按优先级 + 按 package 分批，每次聚焦一个 package
2. 每次 session 修复 3 个 lint 问题（剩余不足 3 个时修完即可）
3. 修复后必须执行 `make bin 2>&1 >bin.log`，检查 bin.log 确认编译通过
4. 编译通过后执行 `make lint 2>&1 >lint.log`，确认问题数减少
5. 编译失败或 lint 未收敛 → 分析原因修复，直到通过

## 绝对禁止
- 禁止用 `//nolint` 批量关闭问题（有充分理由时记录到 Key Decisions）
- 禁止修改 `.golangci.yml` 绕过问题
- 禁止在不够理解代码意图时盲目修改逻辑
- 禁止做 PROGRESS.md 中 Next Step 之外的事情

## Commit 格式
`fix: resolve <linter-name> issues in <package-path>`
CONST_EOF

# 3. PROGRESS.md template
PROJECT_ROOT=$(pwd)
cat <<PROG_EOF > AAA_fix_lint/PROGRESS.md
# Progress — golangci-lint 修复进度

## Meta
- Task: 修复 Go 项目的 golangci-lint 问题
- Project Root: ${PROJECT_ROOT}
- Started: $(date -u +%Y-%m-%dT%H:%M:%S)
- Iteration: 0

## Stats
- 初始问题总数: PLACEHOLDER_COUNT
- 已修复: 0
- 剩余: PLACEHOLDER_COUNT

## Status: pending

## Completed

## Next Step

## Error Log

## Key Decisions

## Fixed Packages
PROG_EOF

# 4. Initialize count
COUNT=$(golangci-lint run ./... 2>&1 | wc -l | tr -d ' ')
sed -i '' "s/PLACEHOLDER_COUNT/${COUNT}/g" AAA_fix_lint/PROGRESS.md
```

## Phase 1: Validate

```bash
[ -x AAA_fix_lint/loop.sh ] && echo "✓ loop.sh" || echo "✗ loop.sh missing"
[ -f AAA_fix_lint/LINT_CONSTITUTION.md ] && echo "✓ LINT_CONSTITUTION.md" || echo "✗ missing"
[ -f AAA_fix_lint/PROGRESS.md ] && echo "✓ PROGRESS.md" || echo "✗ missing"
go version && golangci-lint --version && make --version && which uuidgen
```

If PROGRESS.md still has `PLACEHOLDER_COUNT`, re-run the initialization at the end of Phase 0.

## Phase 2: Launch

Parse `$ARGUMENTS`. If it's a number, use it as `MAX_ITER` (default 50).

```bash
MAX_ITER=<N> ./AAA_fix_lint/loop.sh
```

## Phase 3: Monitor & Recover

- **Progress**: read `AAA_fix_lint/PROGRESS.md` → Status, Stats
- **Interrupted?** Re-run `/lint-fix` — resumes from PROGRESS.md
- **Blocked?** Read Error Log, fix manually, set Status→in_progress, re-run
- **Lint cache?** `golangci-lint cache clean`
- **Long session?** Use tmux

## After Completion

```bash
git diff --stat
# Commit: fix: resolve <linter> issues in <package>
```
