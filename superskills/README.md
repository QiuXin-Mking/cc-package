# Superskills

242 个精选 AI skills，覆盖开发方法论、安全、spec 工作流、知识库、性能优化等。捆绑 [gstack](https://github.com/garrytan/gstack)（Garry Tan 的虚拟工程团队）。

**来源：** [github.com/ariadoss/superskills](https://github.com/ariadoss/superskills)

## 安装

```bash
cd cc-package
./superskills/install.sh
```

setup 会自动：安装 gstack + bun、链接所有 skills 到 Claude Code、可选配置知识库。

## 核心价值

### 1. 代码库认知 —— 让 Claude 真正"看懂"项目

这是 superskills 最独特的价值。

| 命令 | 效果 |
|------|------|
| `/repomap` | 生成 `REPOMAP.md`，把整个仓库的文件→函数→类→结构体做成结构化索引 |
| `/dbmap` | 生成 `DBMAP.md`，数据库 schema 全貌 |
| `/graphify` | 把任意文件夹转成可交互的知识图谱（HTML + JSON） |

**为什么有用：** Claude 的上下文窗口有限，不可能每次都读完整个项目。REPOMAP.md 像一个浓缩版的代码地图，Claude 读它就能快速定位 "XX 功能在哪个模块"，然后精准跳进去改代码。

**怎么用：**
- 在项目里跑一次 `/repomap`，生成 REPOMAP.md
- 在项目 `CLAUDE.md` 里加一条规则，让 Claude 自动引用它
- 之后问 "lustre 的 quota 在哪"、"这个重构要改哪些文件"，Claude 会自动查地图

示例 `CLAUDE.md` 规则：

```markdown
<!-- repomap-rule -->
## REPOMAP.md

REPOMAP.md at the project root is a structural outline of the codebase
(files, classes, functions, types). Read it when the task benefits from a
map: broad exploration, "where does X live", cross-module refactors,
onboarding to an unfamiliar area, or planning changes that touch multiple
files. Skip it for narrow lookups where Grep or a known file path is
faster.
```

### 2. 开发方法论

| 命令 | 用途 |
|------|------|
| `/tdd` | TDD 红-绿-重构强制流程 |
| `/debug` | 四阶段根因分析，不猜原因 |
| `/write-plan` | 从 spec 生成详细实施计划 |
| `/verify` | 合并前验证——必须跑验证命令确认输出 |

### 3. Spec 工作流（需求→任务）

| 命令 | 用途 |
|------|------|
| `/specify` | 从自然语言描述创建 feature spec |
| `/clarify` | 找出 spec 中描述不清的地方，提 5 个澄清问题 |
| `/analyze` | 检查 spec / plan / tasks 三者之间的一致性 |
| `/checklist` | 为当前 feature 生成质量检查清单 |

### 4. 安全

| 命令 | 用途 |
|------|------|
| `/defense` | 纵深防御——OWASP Top 10、密钥检测、认证、加密 |
| `/pentest` | 安全扫描（需要 clearwing） |
| `/fuzz` | Web 模糊测试（需要 ffuf） |

### 5. 知识库 —— 让 Claude 读你的文档

配置 `~/.superskills/knowledge.conf`：

```
# name|path|description|git-url
docs|~/.superskills/knowledge/docs|团队内部文档|https://github.com/org/docs.git
```

然后：

| 命令 | 用途 |
|------|------|
| `/kb-advisor` | 搜索知识库，综合回答 |
| `/content-writer` | 基于知识库的内容创作 |

### 6. 其他

| 命令 | 用途 |
|------|------|
| `/perf-profile` | 应用性能分析 |
| `/db-optimize` | 数据库性能审计（N+1、EXPLAIN、慢查询） |
| `/cache-strategy` | 缓存优先策略 |
| `/playwright` | Playwright E2E 测试 |
| `/worktrees` | 创建隔离的 git worktree 并行开发 |
| `/finish-branch` | 分支清理和合并决策 |

## gstack（内嵌）

43 个额外 skills，由 Garry Tan 维护。覆盖规划评审、部署、文档生成、事件响应等。setup 自动安装。

## 升级

```bash
/superskills-upgrade
```

或手动：

```bash
cd ~/.claude/skills/superskills && git pull && ./setup
```

## 卸载

```bash
rm -rf ~/.claude/skills/superskills ~/.claude/skills/gstack
```

然后删除 `~/.claude/CLAUDE.md` 中 superskills 相关的规则。
