#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="team-toolkit"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== 安装 ${PLUGIN_NAME} 插件 ==="

# 方式一：注册到用户级 ~/.claude/settings.json（对所有项目生效）
SETTINGS_FILE="$HOME/.claude/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
  echo "{}" > "$SETTINGS_FILE"
fi

# 用 python 安全地编辑 JSON（macOS 自带 python3）
python3 -c "
import json, sys

with open('$SETTINGS_FILE') as f:
    config = json.load(f)

plugins = config.setdefault('enabledPlugins', {})
plugins['${PLUGIN_NAME}'] = True

dir_plugins = config.setdefault('extraKnownMarketplaces', {})
dir_plugins['${PLUGIN_NAME}_local'] = {
    'source': {
        'source': 'directory',
        'path': '$PLUGIN_DIR'
    }
}

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)

print('已注册到', '$SETTINGS_FILE')
"

echo ""
echo "=== 安装完成 ==="
echo ""
echo "插件命令（命名空间 ${PLUGIN_NAME}）："
echo "  /${PLUGIN_NAME}:lint-fix       Go lint 自动修复"
echo "  /${PLUGIN_NAME}:ralph-gen      任务生成"
echo ""
echo "可用 skills："
echo "  excalidraw-diagram-generator   生成 Excalidraw 图表"
echo "  frontend-testing               前端组件测试"
echo "  ui-ux-pro-max                  UI/UX 设计"
echo "  unison-config                  Unison 文件同步配置"
echo ""
echo "直接输入主题即可触发对应 skill。"
echo ""
echo "卸载：删除 $SETTINGS_FILE 中 enabledPlugins 和 extraKnownMarketplaces 的对应条目即可"
