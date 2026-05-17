# cc-package

团队统一的 Claude Code 插件包，一键复制给全团队使用。

## 快速开始

```bash
git clone git@github.com:QiuXin-Mking/cc-package.git
cd cc-package
./install.sh
```

### 离线安装

repo 仅 3.2M，任意方式传过去即可：

```bash
# 方式 1：tar 打包传输
tar czf cc-package.tar.gz cc-package/
scp cc-package.tar.gz user@target:~/
# 在目标机器上
tar xzf cc-package.tar.gz && cd cc-package && ./install.sh

# 方式 2：U 盘 / 内网共享直接拷贝目录
cp -r cc-package /target/path/
cd /target/path/cc-package && ./install.sh
```

`install.sh` 只写 `~/.claude/settings.json`，不联网、不装依赖。

## 包含内容

### 命令

| 命令 | 用途 |
|------|------|
| `/qq-go:lint-fix` | Go 项目 lint 自动修复，每轮修 3 个问题 |
| `/qq-go:ralph-gen` | 从简短描述生成结构化任务提示 |
| `/qq-go:ralph-loop` | Ralph Wiggum 自循环迭代开发 |
| `/qq-go:cancel-ralph` | 取消活跃的 Ralph 循环 |
| `/qq-go:ralph-help` | Ralph Loop 插件帮助 |

### Ralph Loop 详解

Ralph Loop 实现 [Ralph Wiggum 技术](https://ghuntley.com/ralph/) —— 基于持续 AI 循环的迭代开发方法论。通过 Stop hook 拦截退出，将同一个 prompt 反复喂给 Claude，每次迭代都能看到上一轮的文件变更，逐步逼近目标。

**启动循环：**

```bash
# 基本用法（无限循环，慎用）
/qq-go:ralph-loop "Refactor the cache layer"

# 设置最大迭代次数（推荐）
/qq-go:ralph-loop "Fix the auth bug" --max-iterations 20

# 设置完成承诺（循环直到输出 <promise>DONE</promise>）
/qq-go:ralph-loop "Build a REST API for todos" --completion-promise "DONE" --max-iterations 50
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--max-iterations <n>` | 最大迭代次数，0 = 无限（默认） |
| `--completion-promise <text>` | 完成承诺短语，Claude 输出 `<promise>短语</promise>` 时停止 |

**取消循环：**

```bash
/qq-go:cancel-ralph
```

**适用场景：** 需求清晰的迭代任务（TDD、lint 修复、测试补齐）、有自动验证手段的任务。
不适合需要人工判断、一次操作即可完成、或需求模糊的任务。

### Skills（自动触发）

#### excalidraw-diagram-generator — 图表生成

支持流程图、架构图、思维导图、时序图、ER 图、类图、泳道图等 9 种类型。说出想画什么即可自动生成 `.excalidraw` 文件。

```
"画一个用户登录的流程图"
"画出 lustre ptlrpc nrs 的架构图"
"生成 xxx 模块的类图"
```

输出 `.excalidraw` 文件，可直接在 [Excalidraw](https://excalidraw.com) 打开编辑。

#### frontend-testing — 前端测试

基于 Vitest + React Testing Library 为前端组件/Hook/工具函数生成测试。

```
"给这个组件写测试"
"补充 xxx hook 的测试覆盖率"
"review 一下这个 spec 文件"
```

技术栈：Vitest 4.x + RTL + jsdom + nock（HTTP mock）。

#### graphify — 知识图谱

将任意代码库/文档目录转化为可查询的知识图谱，支持社区检测、关系审计。

```
/graphify .                          # 当前目录全量构建
/graphify lustre/ptlrpc --mode deep  # 深度模式
/graphify . --update                 # 增量更新
/graphify query "nrs 调度流程"       # 图谱查询
/graphify path "A" "B"               # 两概念最短路径
```

输出 `graph.html`（交互可视化）、`graph.json`（持久化图谱）、`GRAPH_REPORT.md`（审计报告）。

#### ui-ux-pro-max — UI/UX 设计

50+ 风格、161 色板、57 字体配对、99 UX 准则，覆盖 React/Next.js/Vue/Svelte/SwiftUI/Flutter 等 10 个技术栈。

```
"设计一个 SaaS 管理后台的 UI"
"这个按钮组件的配色优化一下"
"这个页面不够专业，帮我改进"
```

触发场景：设计新页面、创建/重构组件、选色板字体、UX 审查、无障碍优化。

#### unison-config — Unison 文件同步

配置 Unison 双向文件同步的 `.prf` 文件。

```
"帮我配置一个 unison sync profile"
"设置 ~/code 和服务器之间的同步"
```

自动识别 macOS（`~/Library/Application Support/Unison/`）和 Linux（`~/.unison/`）的配置文件路径。

### Superskills（推荐扩展）

242 个精选 skills：repomap 代码地图、tdd/debug 开发方法论、spec 工作流、安全测试、知识库等。

```bash
./superskills/install.sh
```

详见 [superskills/README.md](superskills/README.md)

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
