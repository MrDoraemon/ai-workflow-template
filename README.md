# AI-Native Workflow Template

一套可复用的多 Agent 协作开发流水线模板，支持一键部署到新项目。

## 特性

- **7 个专业 Agent 角色**：需求分析师、架构师、开发工程师、测试工程师、代码评审员、安全审计员、运维工程师
- **3 条工作流**：新功能开发（含 4 阶段质量门控）、Bug 修复、发布部署
- **4 阶段质量门控 + RCG 需求澄清 + TDR 方案选择**：需求澄清(RCG) → 技术决策评审(TDR) → 设计预检(DG) → 编码前预检(CG) → 编码合规(PLG) → 交付预检(CTG)
- **3 档流程强度**：lite / standard / strict，可按项目默认选择，也可在单次任务中临时覆盖
- **跨系统初始化**：支持 macOS / Linux / Git Bash 的 Bash 脚本，也支持 Windows PowerShell
- **跨工具兼容**：支持 Claude Code、Codex CLI、OpenCode
- **通用型设计**：不绑定技术栈，Agent 自动从项目 CLAUDE.md 获取上下文

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
2. 需要的 Agent 角色
3. 需要的工作流
4. 流程强度（lite / standard / strict）

完成后，项目目录下会生成对应的配置文件。

## 命令行参数

```bash
# 非交互模式（全部默认）
./init-workflow.sh --tool claude-code --non-interactive
powershell -ExecutionPolicy Bypass -File .\init-workflow.ps1 -Tool claude-code -NonInteractive

# 指定流程强度
./init-workflow.sh --tool all --mode standard --non-interactive
powershell -ExecutionPolicy Bypass -File .\init-workflow.ps1 -Tool all -Mode standard -NonInteractive

# 指定 Agent 和工作流
./init-workflow.sh --tool opencode --mode lite --agents analyst,architect,developer --workflows feature-flow
powershell -ExecutionPolicy Bypass -File .\init-workflow.ps1 -Tool opencode -Mode lite -Agents analyst,architect,developer -Workflows feature-flow

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

| 工具 | 生成内容 | 说明 |
|------|---------|------|
| Claude Code | `.claude/agents/` + `workflows/` + `commands/` + `.claude/CLAUDE.md` + `.claude/hooks/` | 完整适配，含子 Agent 工具权限、危险命令 deny 和 TDR Hook 硬约束 |
| Codex CLI | 角色段落写入 `AGENTS.md`（仅脚本创建时） | 零侵入：已有 AGENTS.md 不修改 |
| OpenCode | `.opencode/agents/` + `opencode.json` | 使用 Markdown agent + `permission` 字段控制读写与 Bash |

权限控制采用”工具层限制 + 提示词约束”双层设计：`reviewer`、`security` 在 Claude Code 和 OpenCode 中禁用写入与 Bash；`developer`、`qa`、`devops` 才保留必要的编辑或执行权限。RCG（需求澄清）在所有工具中通过 analyst 强制输出 RCU 实现；TDR（技术决策评审）在 Claude Code 中通过 PreToolUse Hook 实现硬约束：未完成 TDR 确认时 Hook 自动阻断 architect 生成 ARCH 文档的调用。Codex CLI 当前以 `AGENTS.md` 约束为主，不能提供同等粒度的子 Agent 工具隔离和 Hook 硬约束。所有工具通用协议统一安装在 `.ai-workflow/` 目录，产出物存档到 `.ai-workflow/artifacts/`，卸载执行 `./.ai-workflow/uninstall.sh`。

## Agent 角色

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

## 初始化后要做的事

1. 编辑 `.claude/CLAUDE.md`（Claude Code 模式）或 `AGENTS.md`（Codex/OpenCode 模式），填写项目概述、技术栈、目录结构
2. Agent 启动时会自动读取项目配置获取上下文
3. 使用快捷命令（Claude Code 模式）开始工作：
   - `/requirement` — 需求分析，输出 REQ 文档
   - `/architecture` — 架构设计（含 TDR 方案选择），输出 ARCH 文档
   - `/developer` — 编码实现
   - `/qa` — 测试编写与执行
   - `/review` — 代码评审
   - `/security` — 安全审计
4. 卸载工作流：`./.ai-workflow/uninstall.sh`

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
│   │       ├── uninstall.sh      # 卸载脚本
│   │       ├── agents/           # 7 个 Agent 段落
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
└── README.md
```

## License

MIT
