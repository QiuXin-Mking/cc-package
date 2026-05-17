#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# superskills 安装脚本
# 从 github.com/ariadoss/superskills 克隆并执行 setup
# ============================================================

SUPERSKILLS_DIR="$HOME/.claude/skills/superskills"

if [ -d "$SUPERSKILLS_DIR" ]; then
  echo "superskills 已安装，执行升级..."
  cd "$SUPERSKILLS_DIR"
  git pull
else
  echo "安装 superskills..."
  git clone https://github.com/ariadoss/superskills.git "$SUPERSKILLS_DIR"
  cd "$SUPERSKILLS_DIR"
fi

./setup
echo ""
echo "superskills 安装完成。242+ skills 已就绪。"
