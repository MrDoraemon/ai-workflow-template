#!/bin/bash
# tdr-gate.sh — PreToolUse Hook
# Enforces TDR (Technical Decision Review) completion before wukong ARCH-phase calls.
# Installed to .claude/hooks/ by init-workflow when Claude Code mode is selected.

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "tdr-gate.sh: jq not found; TDR gate is disabled for this call." >&2
  exit 0
fi

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only intercept Agent tool calls
if [ "$TOOL_NAME" != "Agent" ]; then
  exit 0
fi

PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // ""')
DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // ""')
FULL_TEXT="$PROMPT $DESCRIPTION"

# Check if this is a wukong-related call
if ! echo "$FULL_TEXT" | grep -qi "\bwukong\b\|悟空\|\bWK\b"; then
  exit 0
fi

# Identify the phase from keywords in the prompt
IS_TDR_PHASE=false
IS_COMPLIANCE=false

if echo "$FULL_TEXT" | grep -qi "TDR 阶段\|TDR阶段\|技术决策评审\|Technical Decision"; then
  IS_TDR_PHASE=true
fi

if echo "$FULL_TEXT" | grep -qi "合规审查\|编码合规\|PLG\|Phase 4"; then
  IS_COMPLIANCE=true
fi

# TDR phase and compliance review calls always pass through
if [ "$IS_TDR_PHASE" = true ] || [ "$IS_COMPLIANCE" = true ]; then
  exit 0
fi

# Remaining wukong calls are treated as ARCH-phase — check TDR gate

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -z "$CWD" ]; then
  exit 0
fi

# Check for confirmed TDR marker file
ARTIFACTS_DIR="$CWD/.ai-workflow/artifacts/architectures"
if [ -d "$ARTIFACTS_DIR" ]; then
  CONFIRMED=$(find "$ARTIFACTS_DIR" -name "TDR-*.confirmed" -type f 2>/dev/null | head -1)
  if [ -n "$CONFIRMED" ]; then
    exit 0
  fi
fi

# Block: TDR not confirmed
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    "permissionDecisionReason": "TDR（技术决策评审）尚未完成或未获用户确认。必须先完成 TDR 阶段，由用户确认技术方案选择后，才能进入 ARCH 设计阶段。"
  }
}'
