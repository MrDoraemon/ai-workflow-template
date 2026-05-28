#!/bin/bash
# init-workflow.sh - AI-Native Workflow 初始化向导
# 支持 --tool claude-code|codex|opencode|all
# 支持 --mode lite|standard|strict
# 用法:
#   ./init-workflow.sh                              # 交互式向导
#   ./init-workflow.sh --tool claude-code --mode standard --non-interactive
#   ./init-workflow.sh --dry-run --tool all          # 预览不写入

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$(pwd)"
TEMPLATE_REPO_URL="${AI_WORKFLOW_TEMPLATE_REPO:-https://github.com/MrDoraemon/ai-workflow-template}"
TEMPLATE_REF="${AI_WORKFLOW_TEMPLATE_REF:-main}"
TEMPLATE_ARCHIVE_URL="${AI_WORKFLOW_TEMPLATE_ARCHIVE_URL:-${TEMPLATE_REPO_URL}/archive/refs/heads/${TEMPLATE_REF}.zip}"
TEMP_TEMPLATE_DIR=""

# ─── 默认值 ───
TOOL=""
MODE=""
NON_INTERACTIVE=false
DRY_RUN=false
SELECTED_AGENTS=()
SELECTED_WORKFLOWS=()

# ─── Agent 注册表（平行索引数组，兼容 bash 3.2）───
AGENT_NAMES=(analyst architect developer qa reviewer security devops)
AGENT_DESCS=("需求分析" "架构设计" "功能开发" "质量保证" "代码评审" "安全审计" "运维部署")
AGENT_CMD_FILES=("需求分析.md" "架构设计.md" "开发.md" "测试.md" "评审专家.md" "安全审计.md" "")

# ─── 工作流注册表 ───
WORKFLOW_NAMES=(feature-flow bugfix-flow release-flow)
WORKFLOW_DESCS=("新功能开发（含 4 阶段质量门控）" "Bug 修复" "发布部署")

# ─── 流程强度模式 ───
MODE_NAMES=(lite standard strict)
MODE_DESCS=("轻量模式：适合小改动、个人项目、快速原型" "标准模式：默认推荐，适合常规功能开发" "严格模式：适合生产级、多人协作、安全敏感项目")

# ─── 查找函数（替代关联数组）───
_agent_idx() {
  local i
  for i in "${!AGENT_NAMES[@]}"; do [[ "${AGENT_NAMES[$i]}" == "$1" ]] && echo "$i" && return; done
  echo ""
}
_wf_idx() {
  local i
  for i in "${!WORKFLOW_NAMES[@]}"; do [[ "${WORKFLOW_NAMES[$i]}" == "$1" ]] && echo "$i" && return; done
  echo ""
}

_mode_idx() {
  local i
  for i in "${!MODE_NAMES[@]}"; do [[ "${MODE_NAMES[$i]}" == "$1" ]] && echo "$i" && return; done
  echo ""
}

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

normalize_selected_agents() {
  local normalized=()
  local agent mapped idx exists

  for agent in "${SELECTED_AGENTS[@]}"; do
    mapped="$(trim_value "$agent")"
    [[ -n "$mapped" ]] || continue

    idx="$(_agent_idx "$mapped")"
    if [[ -z "$idx" ]]; then
      warn "未知 Agent: ${agent}，已跳过"
      continue
    fi

    exists=false
    for existing in "${normalized[@]+"${normalized[@]}"}"; do
      [[ "$existing" == "$mapped" ]] && exists=true
    done
    $exists || normalized+=("$mapped")
  done

  SELECTED_AGENTS=("${normalized[@]+"${normalized[@]}"}")
}

normalize_selected_workflows() {
  local normalized=()
  local workflow mapped idx exists

  for workflow in "${SELECTED_WORKFLOWS[@]}"; do
    mapped="$(trim_value "$workflow")"
    [[ -n "$mapped" ]] || continue

    idx="$(_wf_idx "$mapped")"
    if [[ -z "$idx" ]]; then
      warn "未知工作流: ${workflow}，已跳过"
      continue
    fi

    exists=false
    for existing in "${normalized[@]+"${normalized[@]}"}"; do
      [[ "$existing" == "$mapped" ]] && exists=true
    done
    $exists || normalized+=("$mapped")
  done

  SELECTED_WORKFLOWS=("${normalized[@]+"${normalized[@]}"}")
}

validate_mode() {
  [[ -n "$(_mode_idx "$MODE")" ]] || error "未知流程强度模式: ${MODE}（可选: lite|standard|strict）"
}

validate_tool() {
  case "$TOOL" in
    claude-code|codex|opencode|all) ;;
    *) error "未知 AI 编码工具: ${TOOL}（可选: claude-code|codex|opencode|all）" ;;
  esac
}

require_arg() {
  local opt="$1"
  local value="${2-}"
  if [[ -z "$value" || "$value" == --* ]]; then
    error "${opt} 需要一个有效值"
  fi
}

mode_desc() {
  case "$MODE" in
    lite) echo "轻量模式：适合小改动、个人项目、快速原型" ;;
    standard) echo "标准模式：默认推荐，适合常规功能开发" ;;
    strict) echo "严格模式：适合生产级、多人协作、安全敏感项目" ;;
  esac
}

# ─── 颜色 ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ─── 工具函数 ───
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
dry()   { $DRY_RUN && echo -e "${YELLOW}[DRY]${NC} $*" && return 0 || return 1; }

# 安全复制：dry-run 时只打印，否则执行
safe_cp() {
  if $DRY_RUN; then
    echo -e "${YELLOW}[DRY]${NC} cp $1 -> $2"
  else
    cp "$1" "$2"
  fi
}

safe_mkdir() {
  if $DRY_RUN; then
    echo -e "${YELLOW}[DRY]${NC} mkdir -p $*"
  else
    mkdir -p "$@"
  fi
}

safe_append() {
  if $DRY_RUN; then
    echo -e "${YELLOW}[DRY]${NC} append $1 -> $2"
  else
    cat "$1" >> "$2"
  fi
}

cleanup_temp_templates() {
  if [[ -n "$TEMP_TEMPLATE_DIR" && -d "$TEMP_TEMPLATE_DIR" ]]; then
    rm -rf "$TEMP_TEMPLATE_DIR"
  fi
}

ensure_templates() {
  if [[ -f "$SCRIPT_DIR/templates/universal/AGENTS.md" ]]; then
    return
  fi

  info "未在脚本目录发现 templates/，尝试下载模板包..."

  command -v curl >/dev/null 2>&1 || error "缺少 curl，无法自动下载模板。请 clone 完整仓库后再运行。"
  command -v unzip >/dev/null 2>&1 || error "缺少 unzip，无法解压模板包。请安装 unzip 或 clone 完整仓库后再运行。"

  TEMP_TEMPLATE_DIR="${TMPDIR:-/tmp}/ai-workflow-template.$$"
  local archive="$TEMP_TEMPLATE_DIR/template.zip"
  local extracted

  mkdir -p "$TEMP_TEMPLATE_DIR"
  trap cleanup_temp_templates EXIT

  info "下载: $TEMPLATE_ARCHIVE_URL"
  curl -fsSL "$TEMPLATE_ARCHIVE_URL" -o "$archive" || error "模板包下载失败。可设置 AI_WORKFLOW_TEMPLATE_REPO / AI_WORKFLOW_TEMPLATE_REF / AI_WORKFLOW_TEMPLATE_ARCHIVE_URL 后重试。"
  unzip -q "$archive" -d "$TEMP_TEMPLATE_DIR" || error "模板包解压失败"

  extracted="$(find "$TEMP_TEMPLATE_DIR" -maxdepth 2 -type d -name templates -print -quit | sed 's#/templates$##')"
  [[ -n "$extracted" && -f "$extracted/templates/universal/AGENTS.md" ]] || error "模板包中未找到 templates/universal/AGENTS.md"

  SCRIPT_DIR="$extracted"
  ok "模板包已就绪: $SCRIPT_DIR"
}

safe_append_mode_protocol() {
  local target="$1"
  local label="$2"
  local marker="AI-WORKFLOW-MODE"

  if $DRY_RUN; then
    echo -e "${YELLOW}[DRY]${NC} append workflow mode ${MODE} -> $target"
    return
  fi

  if [[ ! -f "$target" ]]; then
    warn "$label 不存在，跳过流程强度模式写入"
    return
  fi

  if grep -q "$marker" "$target" 2>/dev/null; then
    ok "$label 已包含流程强度模式，跳过"
    return
  fi

  {
    printf '\n'
    printf '<!-- AI-WORKFLOW-MODE:start -->\n'
    printf '## 流程强度模式\n\n'
    printf '当前项目默认模式：`%s`（%s）。\n\n' "$MODE" "$(mode_desc)"
    printf '用户在单次任务中可以临时覆盖默认模式，例如“本次用 lite 模式修复”或“这个功能走 strict 模式”。\n\n'
    printf '### 模式定义\n\n'
    printf '| 模式 | 适用场景 | 默认流程 |\n'
    printf '|------|----------|----------|\n'
    printf '| lite | 小改动、快速原型、低风险修复 | developer 实现 → 自测/构建 → 可选 reviewer |\n'
    printf '| standard | 常规功能开发 | analyst → architect → developer → PLG → CTG → qa → reviewer |\n'
    printf '| strict | 生产级、安全敏感、多人协作 | standard + 强制 security + 更严格人工门控 + 发布检查 |\n\n'
    printf '### 当前模式执行规则\n\n'
    case "$MODE" in
      lite)
        printf '%s\n' '- 默认跳过独立 REQ/ARCH 产物，除非需求不清、影响范围跨模块或用户明确要求。'
        printf '%s\n' '- developer 必须完成必要上下文确认、实现、自测和验证命令。'
        printf '%s\n' '- reviewer、qa、security 按风险触发，不强制每次调用。'
        printf '%s\n' '- CTG 只检查本次变更相关的运行、构建、测试、依赖和配置项。'
        ;;
      standard)
        printf '%s\n' '- 默认执行完整常规流水线：analyst → architect → developer → PLG → CTG → qa → reviewer。'
        printf '%s\n' '- DG、CG、PLG、CTG 按模板定义执行；阻断项必须修复。'
        printf '%s\n' '- security 在安全敏感、认证授权、依赖、配置、数据处理相关变更时触发。'
        ;;
      strict)
        printf '%s\n' '- analyst、architect、developer、qa、reviewer 必须参与；security 默认强制参与。'
        printf '%s\n' '- REQ、ARCH、测试报告、评审报告和安全报告必须存档并更新索引。'
        printf '%s\n' '- DG、CG、PLG、CTG 必须 100% 执行；任何阻断项不得带病推进。'
        printf '%s\n' '- 需求确认、架构确认、交付终审和发布/部署前确认均作为人工门控点。'
        ;;
    esac
    printf '<!-- AI-WORKFLOW-MODE:end -->\n'
  } >> "$target"

  ok "$label 已写入流程强度模式: $MODE"
}

# ─── 交互式向导 ───

step1_select_tool() {
  echo ""
  echo -e "${CYAN}Step 1/5: 选择 AI 编码工具${NC}"
  echo "  1) Claude Code（完整多 Agent 编排 + 子 Agent 权限控制）"
  echo "  2) Codex CLI（AGENTS.md 角色段落模式）"
  echo "  3) OpenCode（.opencode/agents/ 子 Agent 模式）"
  echo "  4) 全部生成（Claude Code + Codex + OpenCode + 通用 AGENTS.md）"
  echo -n "> "
  read -r choice
  case "$choice" in
    1) TOOL="claude-code" ;;
    2) TOOL="codex" ;;
    3) TOOL="opencode" ;;
    4) TOOL="all" ;;
    *) TOOL="claude-code" ; info "默认选择 Claude Code" ;;
  esac
}

step2_select_agents() {
  echo ""
  echo -e "${CYAN}Step 2/5: 选择需要的 Agent（输入编号，逗号分隔）${NC}"
  local i=1 idx
  for i in "${!AGENT_NAMES[@]}"; do
    echo "  $((i+1))) ${AGENT_NAMES[$i]}  ${AGENT_DESCS[$i]}"
  done
  echo -n "> "
  read -r choices

  SELECTED_AGENTS=()
  IFS=',' read -ra indices <<< "$choices"
  for idx in "${indices[@]}"; do
    idx="${idx// }"
    if [[ "$idx" -ge 1 && "$idx" -le "${#AGENT_NAMES[@]}" ]] 2>/dev/null; then
      SELECTED_AGENTS+=("${AGENT_NAMES[$((idx-1))]}")
    fi
  done

  if [[ ${#SELECTED_AGENTS[@]} -eq 0 ]]; then
    SELECTED_AGENTS=(analyst architect developer)
    info "默认选择核心 Agent: ${SELECTED_AGENTS[*]}"
  fi
}

step3_select_workflows() {
  echo ""
  echo -e "${CYAN}Step 3/5: 选择工作流（输入编号，逗号分隔）${NC}"
  local i n
  for n in "${!WORKFLOW_NAMES[@]}"; do
    echo "  $((n+1))) ${WORKFLOW_NAMES[$n]}  ${WORKFLOW_DESCS[$n]}"
  done
  echo -n "> "
  read -r choices

  SELECTED_WORKFLOWS=()
  IFS=',' read -ra indices <<< "$choices"
  for idx in "${indices[@]}"; do
    idx="${idx// }"
    if [[ "$idx" -ge 1 && "$idx" -le "${#WORKFLOW_NAMES[@]}" ]] 2>/dev/null; then
      SELECTED_WORKFLOWS+=("${WORKFLOW_NAMES[$((idx-1))]}")
    fi
  done

  if [[ ${#SELECTED_WORKFLOWS[@]} -eq 0 ]]; then
    SELECTED_WORKFLOWS=(feature-flow bugfix-flow)
    info "默认选择: ${SELECTED_WORKFLOWS[*]}"
  fi
}

step4_select_mode() {
  echo ""
  echo -e "${CYAN}Step 4/5: 选择流程强度${NC}"
  local i
  for i in "${!MODE_NAMES[@]}"; do
    echo "  $((i+1))) ${MODE_NAMES[$i]}  ${MODE_DESCS[$i]}"
  done
  echo -n "> "
  read -r choice
  case "$choice" in
    1) MODE="lite" ;;
    2|"") MODE="standard" ;;
    3) MODE="strict" ;;
    *) MODE="standard" ; info "默认选择 standard" ;;
  esac
}

step5_confirm() {
  echo ""
  echo -e "${CYAN}Step 5/5: 确认${NC}"
  echo "  工具: $TOOL"
  echo "  Agent: ${SELECTED_AGENTS[*]}"
  echo "  工作流: ${SELECTED_WORKFLOWS[*]}"
  echo "  流程强度: $MODE"
  $DRY_RUN && echo "  模式: DRY-RUN（仅预览）"
  echo ""
  echo -n "确认生成？(Y/n) "
  read -r confirm
  case "$confirm" in
    n|N) error "已取消" ;;
  esac
}

# ─── 生成逻辑 ───

generate_universal() {
  info "生成通用层 AGENTS.md..."
  if [[ -f "$TARGET_DIR/AGENTS.md" ]]; then
    warn "AGENTS.md 已存在，跳过（如需更新请手动处理）"
    return
  fi
  safe_cp "$SCRIPT_DIR/templates/universal/AGENTS.md" "$TARGET_DIR/AGENTS.md"
  ok "AGENTS.md 已生成"
}

generate_claude_code() {
  info "生成 Claude Code 适配层..."

  safe_mkdir "$TARGET_DIR/.claude/"{agents,workflows,commands}
  safe_mkdir "$TARGET_DIR/.claude/artifacts/"{requirements,architectures,reviews,tests,security}

  for agent in "${SELECTED_AGENTS[@]}"; do
    local src="$SCRIPT_DIR/templates/claude-code/agents/${agent}.md"
    if [[ -f "$src" ]]; then
      safe_cp "$src" "$TARGET_DIR/.claude/agents/${agent}.md"
      ok "Agent: ${agent}.md"
    fi
  done

  for workflow in "${SELECTED_WORKFLOWS[@]}"; do
    local src="$SCRIPT_DIR/templates/claude-code/workflows/${workflow}.md"
    if [[ -f "$src" ]]; then
      safe_cp "$src" "$TARGET_DIR/.claude/workflows/${workflow}.md"
      ok "工作流: ${workflow}.md"
    fi
  done

  # 按所选 Agent 过滤命令
  local copied_cmds=()
  for agent in "${SELECTED_AGENTS[@]}"; do
    local cmd_idx=$(_agent_idx "$agent")
    local cmd="${AGENT_CMD_FILES[$cmd_idx]:-}"
    if [[ -n "$cmd" && -f "$SCRIPT_DIR/templates/claude-code/commands/$cmd" ]]; then
      local already=false
      for c in "${copied_cmds[@]+"${copied_cmds[@]}"}"; do [[ "$c" == "$cmd" ]] && already=true; done
      if ! $already; then
        safe_cp "$SCRIPT_DIR/templates/claude-code/commands/$cmd" "$TARGET_DIR/.claude/commands/"
        copied_cmds+=("$cmd")
      fi
    fi
  done
  ok "快捷命令: ${copied_cmds[*]:-无}"

  safe_cp "$SCRIPT_DIR/templates/claude-code/artifacts/index.md" "$TARGET_DIR/.claude/artifacts/index.md"
  for subdir in requirements architectures reviews tests security; do
    $DRY_RUN || touch "$TARGET_DIR/.claude/artifacts/${subdir}/.gitkeep"
  done
  ok "产出物存档目录已创建"

  safe_cp "$SCRIPT_DIR/templates/claude-code/settings.local.json" "$TARGET_DIR/.claude/settings.local.json"
  ok "settings.local.json 已复制"

  # CLAUDE.md 追加（幂等）
  if [[ -f "$SCRIPT_DIR/templates/claude-code/claude-md-protocol.md" ]]; then
    local marker="Multi-Agent 协作协议"
    if [[ -f "$TARGET_DIR/CLAUDE.md" ]] && grep -q "$marker" "$TARGET_DIR/CLAUDE.md" 2>/dev/null; then
      ok "CLAUDE.md 已包含多 Agent 协作协议，跳过"
    elif [[ -f "$TARGET_DIR/CLAUDE.md" ]]; then
      $DRY_RUN || echo "" >> "$TARGET_DIR/CLAUDE.md"
      safe_append "$SCRIPT_DIR/templates/claude-code/claude-md-protocol.md" "$TARGET_DIR/CLAUDE.md"
      ok "CLAUDE.md 已追加多 Agent 协作协议"
    else
      safe_cp "$SCRIPT_DIR/templates/claude-code/claude-md-protocol.md" "$TARGET_DIR/CLAUDE.md"
      ok "CLAUDE.md 已创建（含多 Agent 协作协议）"
    fi
  fi

  safe_append_mode_protocol "$TARGET_DIR/CLAUDE.md" "CLAUDE.md"
}

generate_codex() {
  info "生成 Codex CLI 适配层..."

  for agent in "${SELECTED_AGENTS[@]}"; do
    local src="$SCRIPT_DIR/templates/codex/agents-md-sections/${agent}-section.md"
    local target="$TARGET_DIR/AGENTS.md"
    local marker="## ${agent}（"
    if [[ -f "$src" ]]; then
      if [[ -f "$target" ]] && grep -qF "$marker" "$target" 2>/dev/null; then
        ok "Codex 角色已存在: ${agent}，跳过"
        continue
      fi
      safe_append "$src" "$target"
      $DRY_RUN || echo "" >> "$target"
      ok "Codex 角色: ${agent}"
    fi
  done
}

generate_opencode() {
  info "生成 OpenCode 适配层..."

  safe_mkdir "$TARGET_DIR/.opencode/agents"

  for agent in "${SELECTED_AGENTS[@]}"; do
    local src="$SCRIPT_DIR/templates/opencode/agents/${agent}.md"
    if [[ -f "$src" ]]; then
      safe_cp "$src" "$TARGET_DIR/.opencode/agents/${agent}.md"
      ok "OpenCode Agent: ${agent}.md"
    fi
  done

  if [[ ! -f "$TARGET_DIR/opencode.json" ]]; then
    if $DRY_RUN; then
      echo -e "${YELLOW}[DRY]${NC} create opencode.json"
    else
      cat > "$TARGET_DIR/opencode.json" <<'JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "external_directory": "deny",
    "edit": "ask",
    "bash": {
      "*": "ask",
      "git status*": "allow",
      "git diff*": "allow",
      "git log*": "allow"
    }
  }
}
JSON
    fi
    ok "opencode.json 已生成"
  fi
}

generate_gitignore() {
  local gitignore="$TARGET_DIR/.gitignore"
  local entries=(".env" ".env.*" "!.env.example" ".claude/settings.local.json" ".claude/artifacts/*/")

  if [[ -f "$gitignore" ]]; then
    local modified=false
    for entry in "${entries[@]}"; do
      if ! grep -qF "$entry" "$gitignore" 2>/dev/null; then
        $DRY_RUN || echo "$entry" >> "$gitignore"
        modified=true
      fi
    done
    $modified && ok ".gitignore 已更新"
  else
    if $DRY_RUN; then
      echo -e "${YELLOW}[DRY]${NC} create .gitignore"
    else
      printf '%s\n' "${entries[@]}" > "$gitignore"
    fi
    ok ".gitignore 已创建"
  fi
}

# ─── 参数解析 ───

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tool)
        require_arg "$1" "${2-}"; TOOL="$2"; shift 2 ;;
      --mode)
        require_arg "$1" "${2-}"; MODE="$2"; shift 2 ;;
      --non-interactive)
        NON_INTERACTIVE=true; shift ;;
      --dry-run)
        DRY_RUN=true; shift ;;
      --agents)
        require_arg "$1" "${2-}"; IFS=',' read -ra SELECTED_AGENTS <<< "$2"; shift 2 ;;
      --workflows)
        require_arg "$1" "${2-}"; IFS=',' read -ra SELECTED_WORKFLOWS <<< "$2"; shift 2 ;;
      --help|-h)
        echo "用法: $0 [--tool claude-code|codex|opencode|all] [--mode lite|standard|strict] [--agents a,b,c] [--workflows a,b] [--non-interactive] [--dry-run]"
        exit 0 ;;
      *)
        error "未知参数: $1" ;;
    esac
  done
}

# ─── 主流程 ───

main() {
  echo ""
  echo -e "${CYAN}AI-Native Workflow 初始化向导${NC}"
  echo ""

  parse_args "$@"

  # 检查目标目录
  if [[ ! -d "$TARGET_DIR/.git" ]]; then
    warn "当前目录不是 git 仓库，建议先 git init"
  fi

  if [[ -z "$TOOL" ]]; then
    if $NON_INTERACTIVE; then
      TOOL="claude-code"
    else
      step1_select_tool
    fi
  fi
  validate_tool

  if ! $NON_INTERACTIVE; then
    if [[ ${#SELECTED_AGENTS[@]} -eq 0 ]]; then
      step2_select_agents
    else
      info "使用命令行指定的 Agent: ${SELECTED_AGENTS[*]}"
    fi
    if [[ ${#SELECTED_WORKFLOWS[@]} -eq 0 ]]; then
      step3_select_workflows
    else
      info "使用命令行指定的工作流: ${SELECTED_WORKFLOWS[*]}"
    fi
    if [[ -z "$MODE" ]]; then
      step4_select_mode
    fi
    validate_mode
  else
    if [[ ${#SELECTED_AGENTS[@]} -eq 0 ]]; then
      SELECTED_AGENTS=("${AGENT_NAMES[@]}")
    fi
    if [[ ${#SELECTED_WORKFLOWS[@]} -eq 0 ]]; then
      SELECTED_WORKFLOWS=("${WORKFLOW_NAMES[@]}")
    fi
    if [[ -z "$MODE" ]]; then
      MODE="standard"
    fi
    validate_mode
  fi

  normalize_selected_agents
  if [[ ${#SELECTED_AGENTS[@]} -eq 0 ]]; then
    error "未选择有效 Agent"
  fi

  normalize_selected_workflows
  if [[ ${#SELECTED_WORKFLOWS[@]} -eq 0 ]]; then
    error "未选择有效工作流"
  fi

  if ! $NON_INTERACTIVE; then
    step5_confirm
  fi

  $DRY_RUN && info "DRY-RUN 模式：仅预览，不写入文件"

  ensure_templates

  generate_universal

  case "$TOOL" in
    claude-code) generate_claude_code ;;
    codex)       generate_codex ;;
    opencode)    generate_opencode ;;
    all)         generate_claude_code; generate_codex; generate_opencode ;;
  esac

  safe_append_mode_protocol "$TARGET_DIR/AGENTS.md" "AGENTS.md"

  generate_gitignore

  echo ""
  echo -e "${GREEN}初始化完成！${NC}"
  echo "  工具: $TOOL"
  echo "  Agent: ${#SELECTED_AGENTS[@]} 个"
  echo "  工作流: ${#SELECTED_WORKFLOWS[@]} 条"
  echo "  流程强度: $MODE"
  $DRY_RUN && echo -e "  ${YELLOW}模式: DRY-RUN（未写入文件）${NC}"
  echo ""
  echo "  下一步：编辑 CLAUDE.md 顶部的项目概述，然后开始使用。"
}

main "$@"
