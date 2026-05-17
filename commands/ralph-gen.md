---
description: Generate a structured ralph-loop prompt from a brief task description
argument-hint: "<task description>"
allowed-tools: Bash, Read, Write, Glob, Grep
---

# Ralph Prompt Generator

Analyze the user's task description ($ARGUMENTS) and the current project context, then generate a structured ralph-loop prompt document.

## Step 1: Understand the Project

Quickly assess the project:
- Read CLAUDE.md if it exists
- Check package.json / go.mod / Cargo.toml / requirements.txt to identify tech stack
- Check existing test commands (npm test, go test, pytest, etc.)

## Step 2: Generate the Prompt

Write `ralph-prompt.md` in the project root. Follow this template structure exactly:

```
# [Concise Task Title]

## 任务描述

[Expand the task into a detailed description. Include:
- What to build or fix
- Tech stack context (language, framework, key dependencies)
- Any constraints or conventions to follow
- Where relevant files are located]

## 完成标准

- [ ] [Verifiable criterion 1 — be specific]
- [ ] [Verifiable criterion 2]
- [ ] `make bin` 编译通过
- [ ] `make lint` 静态检查零告警

## 分步执行

### Phase 1: [First milestone]

- [Concrete step]
- [Concrete step]

### Phase 2: [Second milestone]

- [Concrete step]
- [Concrete step]

### Phase 3: [Final milestone]

- [Concrete step]
- [Concrete step]

## 自纠错指令

1. 每次代码修改后，运行编译验证: `make bin`
2. 编译通过后，运行静态检查: `make lint`
3. 如果编译或 lint 失败，分析错误信息，修复后重新验证
4. 同一错误连续失败 3 次 → 记录原因到 progress.md，尝试替代方案
5. 每完成一个 Phase，确认 `make bin && make lint` 均通过再进入下一 Phase

## 输出

当所有完成标准满足时（含 `make bin` 和 `make lint` 通过），输出: <promise>COMPLETE</promise>
```

## Step 3: Output

After writing the file, print:
- The file path
- A summary of what was generated (title, number of phases, number of criteria)
- Reminder: "请审阅 ralph-prompt.md，微调后运行: /ralph-loop \"\$(cat ralph-prompt.md)\" --completion-promise \"COMPLETE\" --max-iterations 50"

## Rules

- The prompt MUST be in Chinese if the user's task description is in Chinese
- Each completion criterion must be verifiable (tests pass, build succeeds, etc.) — avoid vague criteria like "code is clean"
- Each phase should be independently completable and verifiable
- 闭环验证固定为 `make bin`（编译）和 `make lint`（静态检查），不可替换为其他命令
- Keep the `--max-iterations` suggestion proportional to the task complexity (20 for simple, 50 for medium, 100 for complex)
