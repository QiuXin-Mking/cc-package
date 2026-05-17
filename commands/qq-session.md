---
description: "链式多轮对话——同一 session 内依次执行多个 prompt"
argument-hint: "<session-name> <prompt1> | <prompt2> | ...
"
---

执行多轮链式对话，每一轮都能看到之前的结果:

```
${CLAUDE_PLUGIN_ROOT}/scripts/qq-session <session-name> <prompt1> "<prompt2>" ...
```

示例 — 代码库探索三部曲:
```
/qq-go:qq-session lustre-qa "读 REPOMAP.md 列出所有子系统和模块" "分析模块间的耦合关系" "给出减少耦合的重构建议"
```
