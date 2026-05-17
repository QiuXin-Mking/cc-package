# cc-package

团队统一的 Claude Code 插件包，一键复制给全团队使用。

## 快速开始

```bash
git clone git@github.com:QiuXin-Mking/cc-package.git
cd cc-package
./install.sh
```

## 包含内容

### 命令

| 命令 | 用途 |
|------|------|
| `/team-toolkit:lint-fix` | Go 项目 lint 自动修复，每轮修 3 个问题 |
| `/team-toolkit:ralph-gen` | 从简短描述生成结构化任务提示 |
| `/team-toolkit:ralph-loop` | Ralph Wiggum 自循环迭代开发 |
| `/team-toolkit:cancel-ralph` | 取消活跃的 Ralph 循环 |
| `/team-toolkit:ralph-help` | Ralph Loop 插件帮助 |

### Ralph Loop 详解

Ralph Loop 实现 [Ralph Wiggum 技术](https://ghuntley.com/ralph/) —— 基于持续 AI 循环的迭代开发方法论。通过 Stop hook 拦截退出，将同一个 prompt 反复喂给 Claude，每次迭代都能看到上一轮的文件变更，逐步逼近目标。

**启动循环：**

```bash
# 基本用法（无限循环，慎用）
/team-toolkit:ralph-loop "Refactor the cache layer"

# 设置最大迭代次数（推荐）
/team-toolkit:ralph-loop "Fix the auth bug" --max-iterations 20

# 设置完成承诺（循环直到输出 <promise>DONE</promise>）
/team-toolkit:ralph-loop "Build a REST API for todos" --completion-promise "DONE" --max-iterations 50
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--max-iterations <n>` | 最大迭代次数，0 = 无限（默认） |
| `--completion-promise <text>` | 完成承诺短语，Claude 输出 `<promise>短语</promise>` 时停止 |

**取消循环：**

```bash
/team-toolkit:cancel-ralph
```

**适用场景：** 需求清晰的迭代任务（TDD、lint 修复、测试补齐）、有自动验证手段的任务。
不适合需要人工判断、一次操作即可完成、或需求模糊的任务。

### Skills（自动触发）

| Skill | 触发场景 |
|-------|----------|
| **excalidraw-diagram-generator** | 画流程图、架构图、思维导图、时序图等 |
| **frontend-testing** | 写前端组件/ Hook /工具函数测试 |
| **ui-ux-pro-max** | UI/UX 设计：50+ 风格、161 色板、57 字体配对 |
| **unison-config** | 配置 Unison 文件同步 |

## 脚本说明

| 脚本 | 谁用 | 作用 |
|------|------|------|
| `pack.sh` | 维护者 | 从 `~/.claude/` 收集最新 commands/skills，重新打包插件 |
| `install.sh` | 团队成员 | 在 `~/.claude/settings.json` 中注册插件，Claude Code 启动即加载 |

## 维护流程

```bash
# 1. 本机更新 commands 或 skills 后，重新打包
./pack.sh

# 2. 推送到团队仓库
git add -A && git commit -m "更新插件" && git push
```

## 卸载

删除 `~/.claude/settings.json` 中 `enabledPlugins` 和 `extraKnownMarketplaces` 里的对应条目。
