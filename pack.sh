#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# pack.sh — 从 ~/.claude/ 收集配置，打包成 qq-go 插件
#
# 用法：./pack.sh
# 效果：把你在 ~/.claude/commands/ 和 ~/.claude/skills/ 的
#       最新内容同步到当前插件目录，然后交给 install.sh 分发。
# ============================================================

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_NAME="qq-go"
VERSION="${1:-1.0.0}"

SOURCE_COMMANDS="$HOME/.claude/commands"
SOURCE_SKILLS="$HOME/.claude/skills"

echo "=== 打包 ${PLUGIN_NAME} v${VERSION} ==="
echo ""

# ---- 1. 目录骨架 ----
mkdir -p "$PLUGIN_DIR/.claude-plugin"
mkdir -p "$PLUGIN_DIR/commands"
mkdir -p "$PLUGIN_DIR/skills"

# ---- 2. plugin.json ----
cat > "$PLUGIN_DIR/.claude-plugin/plugin.json" <<JSON
{
  "name": "${PLUGIN_NAME}",
  "description": "团队统一工具集：lint-fix Go 自动修复、ralph-gen 任务生成、Excalidraw 图表、前端测试、UI/UX 设计、Unison 配置",
  "version": "${VERSION}",
  "author": { "name": "Team" }
}
JSON
echo "[1/3] plugin.json 已生成"

# ---- 3. 复制 commands（排除 README） ----
if [ -d "$SOURCE_COMMANDS" ]; then
  rm -f "$PLUGIN_DIR/commands/"*
  for f in "$SOURCE_COMMANDS"/*.md; do
    name=$(basename "$f")
    case "$name" in
      *README*) continue ;;   # 跳过 *_README.md
    esac
    cp "$f" "$PLUGIN_DIR/commands/"
    echo "       + commands/$name"
  done
  echo "[2/3] commands 已同步（跳过 README）"
else
  echo "[2/3] 跳过：$SOURCE_COMMANDS 不存在"
fi

# ---- 4. 复制 skills（解除符号链接） ----
if [ -d "$SOURCE_SKILLS" ]; then
  rm -rf "$PLUGIN_DIR/skills/"*
  for d in "$SOURCE_SKILLS"/*/; do
    name=$(basename "$d")
    cp -R -L "$d" "$PLUGIN_DIR/skills/$name"
    echo "       + skills/$name"
  done
  echo "[3/3] skills 已同步（符号链接已解除）"
else
  echo "[3/3] 跳过：$SOURCE_SKILLS 不存在"
fi

# ---- 5. install.sh 自举 ----
chmod +x "$PLUGIN_DIR/install.sh" 2>/dev/null || true

echo ""
echo "=== 打包完成 ==="
echo ""
echo "目录：$PLUGIN_DIR"
echo ""
echo "下一步："
echo "  git commit + push → 团队成员 → ./install.sh 一键注册"
echo ""
echo "或者本机直接测试："
echo "  ./install.sh"
