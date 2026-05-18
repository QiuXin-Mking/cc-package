#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="qq-go"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== 安装 ${PLUGIN_NAME} 插件 ==="

# 方式一：注册到用户级 ~/.claude/settings.json（对所有项目生效）
SETTINGS_FILE="$HOME/.claude/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
  echo "{}" > "$SETTINGS_FILE"
fi

# 用 python 安全地编辑 JSON（macOS 自带 python3）
# 只在 key 不存在时追加，不覆盖已有内容
python3 -c "
import json, sys

with open('$SETTINGS_FILE') as f:
    config = json.load(f)

changed = False

plugins = config.setdefault('enabledPlugins', {})
if '${PLUGIN_NAME}' not in plugins:
    plugins['${PLUGIN_NAME}'] = True
    changed = True

dir_plugins = config.setdefault('extraKnownMarketplaces', {})
if '${PLUGIN_NAME}_local' not in dir_plugins:
    dir_plugins['${PLUGIN_NAME}_local'] = {
        'source': {
            'source': 'directory',
            'path': '$PLUGIN_DIR'
        }
    }
    changed = True

if changed:
    with open('$SETTINGS_FILE', 'w') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    print('已注册到', '$SETTINGS_FILE')
else:
    print('已存在，跳过', '$SETTINGS_FILE')
"

echo ""

# 添加 bash 别名到 ~/.bashrc（只在不存在时追加）
BASHRC_FILE="$HOME/.bashrc"

add_alias() {
  local name="$1"
  local value="$2"
  if grep -q "^alias ${name}=" "$BASHRC_FILE" 2>/dev/null; then
    echo "别名已存在，跳过: ${name}"
  else
    echo "alias ${name}='${value}'" >> "$BASHRC_FILE"
    echo "已添加别名: ${name}"
  fi
}

add_alias "rebase" "git pull origin feature/6.12.0/888-bugfix --rebase && git push -f"
add_alias "supple-commit" "git add -u && git commit --amend --no-edit && git push -f"
add_alias "gs" "git status"
add_alias "gl" "git log -10 --oneline"
add_alias "gb" "git branch"

echo ""

# 安装 repomap（tree-sitter 代码结构映射）
echo "=== 安装 repomap ==="
REPOMAP_DIR="$PLUGIN_DIR/tools/repomap"
chmod +x "$REPOMAP_DIR/scripts/run.sh"

# 安装 Python 依赖（只在未安装时安装）
if python3 -c "import tree_sitter_languages" 2>/dev/null; then
  echo "tree-sitter-languages 已安装，跳过"
else
  echo "安装 tree-sitter-languages ..."
  pip3 install -r "$REPOMAP_DIR/requirements.txt" --quiet 2>/dev/null || \
    pip3 install tree-sitter==0.21.3 tree-sitter-languages==1.10.2 --quiet || \
    echo "警告: pip 安装失败，repomap 首次运行时会自动尝试安装"
fi

echo ""
echo "=== 安装完成 ==="
echo ""
echo "插件命令（命名空间 ${PLUGIN_NAME}）："
echo "  /${PLUGIN_NAME}:lint-fix          Go lint 自动修复"
echo "  /${PLUGIN_NAME}:ralph-gen         任务生成"
echo "  /${PLUGIN_NAME}:ralph-loop        Ralph 自循环迭代"
echo "  /${PLUGIN_NAME}:cancel-ralph      取消 Ralph 循环"
echo "  /${PLUGIN_NAME}:ralph-help        Ralph Loop 帮助"
echo "  /${PLUGIN_NAME}:repomap           生成代码结构映射"
echo "  /${PLUGIN_NAME}:repomap-auto-on   启用自动更新 REPOMAP"
echo "  /${PLUGIN_NAME}:repomap-auto-off  关闭自动更新 REPOMAP"
echo ""
echo "可用 skills："
echo "  excalidraw-diagram-generator   生成 Excalidraw 图表"
echo "  frontend-testing               前端组件测试"
echo "  graphify                       知识图谱生成（代码库可视化、社区检测）"
echo "  ui-ux-pro-max                  UI/UX 设计"
echo "  unison-config                  Unison 文件同步配置"
echo ""
echo "直接输入主题即可触发对应 skill。"
echo ""
echo "卸载：删除 $SETTINGS_FILE 中 enabledPlugins 和 extraKnownMarketplaces 的对应条目即可"
