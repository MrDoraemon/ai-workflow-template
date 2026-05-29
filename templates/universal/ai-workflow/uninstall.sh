#!/bin/bash
# uninstall.sh - AI Workflow 一键卸载脚本
# 用法: ./.ai-workflow/uninstall.sh
# 删除所有工作流相关文件，不触碰用户原有内容

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$SCRIPT_DIR/install-manifest.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }

echo ""
echo -e "${YELLOW}AI Workflow 卸载${NC}"
echo ""

if [[ ! -f "$MANIFEST" ]]; then
  warn "未找到安装清单 ($MANIFEST)"
  echo "将执行默认清理..."
  # Default cleanup - remove known directories
  rm -rf "$TARGET_DIR/.claude/agents" "$TARGET_DIR/.claude/workflows" "$TARGET_DIR/.claude/commands" "$TARGET_DIR/.claude/artifacts"
  rm -f "$TARGET_DIR/.claude/CLAUDE.md" "$TARGET_DIR/.claude/settings.local.json"
  rm -rf "$TARGET_DIR/.opencode/agents"
  rm -rf "$TARGET_DIR/.ai-workflow"
  info "默认清理完成"
  exit 0
fi

# Parse manifest and delete recorded files
deleted=0
skipped=0

while IFS= read -r line; do
  # Extract path from JSON array (simple parsing, no jq dependency)
  path="${line#\"}"
  path="${path%\",}"
  path="${path%\"}"
  [[ -z "$path" ]] && continue

  target="$TARGET_DIR/$path"

  if [[ -e "$target" ]]; then
    rm -rf "$target"
    info "已删除: $path"
    deleted=$((deleted + 1))
  else
    warn "已不存在: $path"
    skipped=$((skipped + 1))
  fi
done < <(grep -E '^\s*"' "$MANIFEST")

# Remove .ai-workflow itself (this script's directory)
rm -rf "$TARGET_DIR/.ai-workflow"

echo ""
info "卸载完成: 删除 $deleted 项，跳过 $skipped 项（已不存在）"
echo ""
