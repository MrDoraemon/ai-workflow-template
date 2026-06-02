# AI-Native Workflow Template

一套可复用的 AI-Native SDLC 流程协议模板，支持一键部署到新项目，并可适配 native / oh-my-claudecode / oh-my-opencode 等执行 runtime。

## 特性

- **7 个抽象角色契约**：需求分析、架构设计、开发实现、质量验证、代码评审、安全审计、运维部署
- **3 条工作流**：新功能开发（含 4 阶段质量门控）、Bug 修复、发布部署
- **4 阶段质量门控 + RCG 需求澄清 + TDR 方案选择**：需求澄清(RCG) → 技术决策评审(TDR) → 设计预检(DG) → 编码前预检(CG) → 编码合规(PLG) → 交付预检(CTG)
- **3 档流程强度**：lite / standard / strict，可按项目默认选择，也可在单次任务中临时覆盖
- **跨系统初始化**：支持 macOS / Linux / Git Bash 的 Bash 脚本，也支持 Windows PowerShell
- **跨工具兼容**：支持 Claude Code、Codex CLI、OpenCode
- **Runtime Adapter**：支持 native 原生轻量模板，也可接入 oh-my-claudecode / oh-my-opencode
- **通用型设计**：不绑定技术栈，核心协议安装到 `.ai-workflow/`

## 快速开始

在**你的项目目录**中执行初始化脚本。

### macOS / Linux / Git Bash

```bash
# 方式一：clone 后引用（推荐）
git clone https://github.com/MrDoraemon/ai-workflow-template.git /tmp/ai-workflow-template
cd /path/to/your-project
/tmp/ai-workflow-template/init-workflow.sh

# 方式二：直接下载脚本（脚本会自动下载 templates 模板包）
cd /path/to/your-project
curl -fsSL https://raw.githubusercontent.com/MrDoraemon/ai-workflow-template/main/init-workflow.sh -o /tmp/init-workflow.sh
bash /tmp/init-workflow.sh
```

### Windows PowerShell

```powershell
# 方式一：clone 后引用（推荐）
git clone https://github.com/MrDoraemon/ai-workflow-template.git $env:TEMP\ai-workflow-template
cd C:\path\to\your-project
powershell -ExecutionPolicy Bypass -File $env:TEMP\ai-workflow-template\init-workflow.ps1

# 方式二：直接下载脚本（脚本会自动下载 templates 模板包）
cd C:\path\to\your-project
iwr https://raw.githubusercontent.com/MrDoraemon/ai-workflow-template/main/init-workflow.ps1 -OutFile $env:TEMP\init-workflow.ps1
powershell -ExecutionPolicy Bypass -File $env:TEMP\init-workflow.ps1
```

脚本采用**零侵入架构**：不修改项目中已有的 `AGENTS.md`、`CLAUDE.md` 等文件，所有工作流配置安装到 `.ai-workflow/` 目录。直接下载单脚本时，脚本会从 GitHub archive 自动下载 `templates/`。如使用 fork、私有仓库或指定分支，可设置：

```bash
export AI_WORKFLOW_TEMPLATE_REPO=https://github.com/MrDoraemon/ai-workflow-template
export AI_WORKFLOW_TEMPLATE_REF=main
```

```powershell
$env:AI_WORKFLOW_TEMPLATE_REPO = "https://github.com/MrDoraemon/ai-workflow-template"
$env:AI_WORKFLOW_TEMPLATE_REF = "main"
```

交互式向导会引导你选择：
1. AI 编码工具（Claude Code / Codex CLI / OpenCode / 全部）
2. Runtime 适配层（native / oh-my-claudecode / oh-my-opencode）
3. 需要的角色契约
4. 需要的工作流
5. 流程强度（lite / standard / strict）

完成后，项目目录下会生成对应的配置文件。

## 命令行参数

```bash
# 非交互模式（全部默认）
./init-workflow.sh --tool claude-code --non-interactive
powershell -ExecutionPolicy Bypass -File .\init-workflow.ps1 -Tool claude-code -NonInteractive

# 指定流程强度
./init-workflow.sh --tool all --mode standard --non-interactive
powershell -ExecutionPolicy Bypass -File .\init-workflow.ps1 -Tool all -Mode standard -NonInteractive

# 指定角色契约和工作流
./init-workflow.sh --tool opencode --mode lite --agents analyst,architect,developer --workflows feature-flow
powershell -ExecutionPolicy Bypass -File .\init-workflow.ps1 -Tool opencode -Mode lite -Agents analyst,architect,developer -Workflows feature-flow

# 接入 oh-my-claudecode（不生成本项目自带 Claude Agent）
./init-workflow.sh --tool claude-code --runtime oh-my-claudecode --mode standard --non-interactive
powershell -ExecutionPolicy Bypass -File .\init-workflow.ps1 -Tool claude-code -Runtime oh-my-claudecode -Mode standard -NonInteractive

# 接入 oh-my-opencode（不生成本项目自带 OpenCode Agent）
./init-workflow.sh --tool opencode --runtime oh-my-opencode --mode standard --non-interactive
powershell -ExecutionPolicy Bypass -File .\init-workflow.ps1 -Tool opencode -Runtime oh-my-opencode -Mode standard -NonInteractive

# 查看帮助
./init-workflow.sh --help
powershell -ExecutionPolicy Bypass -File .\init-workflow.ps1 -Help
```

## 流程强度

| 模式 | 适用场景 | 默认流程 |
|------|----------|----------|
| lite | 小改动、快速原型、低风险修复 | developer 实现 → 自测/构建 → 可选 reviewer（RCG/TDR 可快速通过） |
| standard | 常规功能开发（默认推荐） | analyst(+RCG 需求澄清) → architect(+TDR 方案选择) → developer → PLG → CTG → qa → reviewer |
| strict | 生产级、安全敏感、多人协作 | standard + 强制 security + RCG/TDR 必须存档 + 更严格人工门控 + 发布检查 |

初始化时选择的模式会写入 `.ai-workflow/` 配置。单次任务可临时覆盖，例如”本次用 lite 模式修复”或”这个支付功能走 strict 模式”。

## 工具适配说明

| Tool / Runtime | 生成内容 | 说明 |
|----------------|---------|------|
| native + Claude Code | `.ai-workflow/` + `.claude/agents/` + `workflows/` + `commands/` + `.claude/hooks/` | 原生轻量适配，含本项目自带 Agent 和 TDR Hook |
| native + Codex CLI | `.ai-workflow/` + `AGENTS.md`（仅脚本创建时） | 零侵入：已有 AGENTS.md 不修改 |
| native + OpenCode | `.ai-workflow/` + `.opencode/agents/` + `opencode.json` | 原生 OpenCode agent 适配 |
| oh-my-claudecode | `.ai-workflow/` + `.ai-workflow/runtimes/oh-my-claudecode/` | 不生成重复 Claude Agent，由 oh-my-claudecode 接管编排 |
| oh-my-opencode | `.ai-workflow/` + `.ai-workflow/runtimes/oh-my-opencode/` | 不生成重复 OpenCode Agent，由 oh-my-opencode 接管编排 |

本项目核心只定义 SDLC 协议、门禁和产物契约。native runtime 会生成本项目自带 Agent；oh-my-claudecode / oh-my-opencode runtime 则只生成适配说明，由外部 runtime 的 Team / Autopilot / Ultrawork / Ralph / Sisyphus 等能力负责执行。

权限控制采用”工具层限制 + 提示词约束”双层设计。RCG（需求澄清）在所有工具中通过 analyst/需求角色强制输出 RCU 实现；TDR（技术决策评审）在 native Claude Code 中通过 PreToolUse Hook 实现硬约束。所有工具通用协议统一安装在 `.ai-workflow/` 目录，产出物存档到 `.ai-workflow/artifacts/`，卸载执行 `./.ai-workflow/uninstall.sh`。

## 角色契约

| 角色 | 职责 | 权限 |
|------|------|------|
| analyst | 需求分析，输出 REQ 文档 | 只读 |
| architect | 架构设计 | 只读 |
| developer | 通用功能实现 | 读写任务范围内代码 |
| qa | 测试编写与执行 | 读写测试 |
| reviewer | 代码评审 | 只读 |
| security | 安全审计 | 只读 |
| devops | CI/CD 和部署 | 读写配置 |

## 新功能开发流水线

```
用户需求
  ↓
analyst → RCU（需求理解确认 + 用户确认）
  ↓
analyst → REQ 文档（需求分析）
  ↓
architect → TDR 文档（技术决策评审 + 用户选择方案）
  ↓
architect → ARCH 文档（架构设计 + DG 自检）
  ↓
developer（编码实现 + CG 预检；可按模块并行调度）
  ↓
architect → PLG 编码合规审查
  ↓
交付预检(CTG) → qa(测试) → reviewer(评审)
```

## 卸载

### 卸载前须知

卸载脚本会删除所有 AI Workflow 相关的配置文件，包括：
- `.ai-workflow/` — 通用协议、角色契约、门禁协议、工作流定义
- `.claude/agents/` — Claude Code Agent 定义
- `.claude/workflows/` — Claude Code 工作流
- `.claude/commands/` — 快捷命令
- `.claude/hooks/` — TDR 门禁 Hook
- `.claude/CLAUDE.md` — 协作协议（仅 AI Workflow 添加的内容）
- `.claude/settings.local.json` — 权限配置
- `.opencode/agents/` — OpenCode Agent 定义
- `.opencode.json` — OpenCode 配置
- `.ai-workflow/artifacts/` — 产出物存档（**重要数据，建议备份**）

### 备份产出物

如果项目中有重要的需求文档（REQ）、架构设计（ARCH）、测试计划等，建议在卸载前备份：

```bash
# macOS / Linux / Git Bash
cp -r .ai-workflow/artifacts ~/ai-workflow-artifacts-backup

# Windows PowerShell
Copy-Item -Recurse .ai-workflow\artifacts $HOME\ai-workflow-artifacts-backup
```

### 执行卸载

```bash
# macOS / Linux / Git Bash
./.ai-workflow/uninstall.sh

# Windows PowerShell
bash .\.ai-workflow\uninstall.sh
# 或者在 Git Bash 中执行
./.ai-workflow/uninstall.sh
```

## 初始化后要做的事

1. 阅读 `.ai-workflow/protocol.md`、`.ai-workflow/roles.md`、`.ai-workflow/gates.md`
2. 编辑 `.claude/CLAUDE.md`（native Claude Code）或 `AGENTS.md`（Codex/OpenCode），填写项目概述、技术栈、目录结构
3. 如果选择 oh-my runtime，阅读 `.ai-workflow/runtimes/<runtime>/README.md`
4. 使用快捷命令（native Claude Code 模式）开始工作：
   - `/requirement` — 需求分析，输出 REQ 文档
   - `/architecture` — 架构设计（含 TDR 方案选择），输出 ARCH 文档
   - `/developer` — 编码实现
   - `/qa` — 测试编写与执行
   - `/review` — 代码评审
   - `/security` — 安全审计
5. 卸载工作流：`./.ai-workflow/uninstall.sh`

## 目录结构

```
ai-workflow-template/
├── init-workflow.sh              # 初始化脚本
├── init-workflow.ps1             # Windows PowerShell 初始化脚本
├── templates/
│   ├── universal/                # 通用层
│   │   ├── AGENTS.md             # AGENTS.md 模板（仅新建时使用）
│   │   └── ai-workflow/          # 零侵入通用工作流
│   │       ├── protocol.md       # 通用协议
│   │       ├── roles.md          # 抽象角色契约
│   │       ├── gates.md          # 门禁协议
│   │       ├── runtime-map.md    # runtime 映射
│   │       ├── uninstall.sh      # 卸载脚本
│   │       └── workflows/        # 3 条工作流
│   ├── claude-code/              # Claude Code 适配
│   │   ├── agents/               # 7 个 Agent 定义
│   │   ├── workflows/            # 3 条工作流
│   │   ├── commands/             # 6 个快捷命令
│   │   ├── hooks/                # PreToolUse Hook（TDR 硬约束）
│   │   ├── artifacts/            # 产出物骨架（index.md）
│   │   ├── claude-md-protocol.md # .claude/CLAUDE.md 协议片段
│   │   └── settings.local.json   # 权限配置 + Hook 注册
│   ├── codex/                    # Codex CLI 适配
│   │   └── agents-md-sections/   # 7 个角色段落
│   └── opencode/                 # OpenCode 适配
│       └── agents/               # 7 个 Agent 文件
│   └── runtimes/                 # 外部 runtime adapter
│       ├── oh-my-claudecode/
│       └── oh-my-opencode/
└── README.md
```

## License

MIT
