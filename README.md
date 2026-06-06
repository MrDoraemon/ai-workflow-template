# AI-Native Workflow Template

一套可复用的 AI-Native SDLC 流程协议模板，支持一键部署到新项目，并可适配 native / oh-my-claudecode / oh-my-opencode 等执行 runtime。

## 特性

- **7 个抽象角色契约**：需求分析、架构设计、开发实现、质量验证、代码评审、安全审计、运维部署；OpenCode native 额外提供 `rulai` 编排入口
- **3 条工作流**：新功能开发（含 4 阶段质量门控）、Bug 修复、发布部署
- **4 阶段质量门控 + RCG 需求澄清 + TDR 方案选择**：需求澄清(RCG) → 技术决策评审(TDR) → 设计预检(DG) → 编码前预检(CG) → 编码合规审查(PLG) → 交付预检(CTG)
- **3 档流程强度**：lite / standard / strict，可按项目默认选择，也可在单次任务中临时覆盖
- **跨系统初始化**：支持 macOS / Linux / Windows Git Bash 的 Bash 脚本
- **跨工具兼容**：支持 Claude Code、Codex CLI、OpenCode
- **Runtime Adapter**：支持 native 原生轻量模板，也可接入 oh-my-claudecode / oh-my-opencode
- **运行状态账本**：通过 `.ai-workflow/runs/` 记录 state、events、metrics、summary 和 evolution 建议，支持恢复、审计和复盘
- **通用型设计**：不绑定技术栈，核心协议安装到 `.ai-workflow/`

## 快速开始

在**你的项目目录**中执行初始化脚本。

### macOS / Linux / Windows Git Bash

Windows 用户请在 Git Bash 中运行初始化脚本。

```bash
# 方式一：clone 后引用（推荐）
git clone https://gitlab.com/jiangqiao/ai-workflow-template.git /tmp/ai-workflow-template
cd /path/to/your-project
/tmp/ai-workflow-template/init-workflow.sh

# 方式二：直接下载脚本（脚本会自动下载 templates 模板包）
cd /path/to/your-project
curl -fsSL https://gitlab.com/jiangqiao/ai-workflow-template/-/raw/main/init-workflow.sh -o /tmp/init-workflow.sh
bash /tmp/init-workflow.sh
```

脚本采用**个人本地零侵入架构**：不修改项目中已有的 `AGENTS.md`、`CLAUDE.md` 等文件，所有工作流配置安装到 `.ai-workflow/` 目录，并默认写入 `.gitignore`。直接下载单脚本时，脚本会从 GitLab archive 自动下载 `templates/`。如使用 fork、私有仓库或指定分支，可设置：

```bash
export AI_WORKFLOW_TEMPLATE_REPO=https://gitlab.com/jiangqiao/ai-workflow-template
export AI_WORKFLOW_TEMPLATE_REF=main
```

`.ai-workflow/` 默认不提交到业务仓库，方便个人按自己的人机协作模式本地定制。若团队希望共享流程协议，可自行移除对应忽略规则并提交定制后的协议文件。

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

# 指定流程强度
./init-workflow.sh --tool all --mode standard --non-interactive

# 指定角色契约和工作流
./init-workflow.sh --tool opencode --mode lite --agents tangseng,wukong,bajie --workflows feature-flow

# 接入 oh-my-claudecode（不生成本项目自带 Claude Agent）
./init-workflow.sh --tool claude-code --runtime oh-my-claudecode --mode standard --non-interactive

# 接入 oh-my-opencode（不生成本项目自带 OpenCode Agent）
./init-workflow.sh --tool opencode --runtime oh-my-opencode --mode standard --non-interactive

# 查看帮助
./init-workflow.sh --help
```

## 流程强度

| 模式 | 适用场景 | 默认流程 |
|------|----------|----------|
| lite | 小改动、快速原型、低风险修复 | bajie 实现+单测编写 → 最小验证/可选 nezha → 可选 erlang（RCG/TDR 可快速通过） |
| standard | 常规功能开发（默认推荐） | tangseng(+RCG 需求澄清) → wukong(+TDR 方案选择) → bajie → PLG → CTG → nezha(增量重做) → erlang(增量重做) |
| strict | 生产级、安全敏感、多人协作 | standard + 强制 lijing + RCG/TDR 必须存档 + 更严格人工门控 + 发布检查 |

初始化时选择的模式会写入 `.ai-workflow/` 配置。单次任务可临时覆盖，例如”本次用 lite 模式修复”或”这个支付功能走 strict 模式”。

## 工具适配说明

| Tool / Runtime | 生成内容 | 说明 |
|----------------|---------|------|
| native + Claude Code | `.ai-workflow/` + `.claude/agents/` + `workflows/` + `commands/` + `.claude/hooks/` | 原生轻量适配，含本项目自带 Agent 和 TDR Hook |
| native + Codex CLI | `.ai-workflow/` + `AGENTS.md`（仅脚本创建时） | 零侵入：已有 AGENTS.md 不修改 |
| native + OpenCode | `.ai-workflow/` + `.opencode/agents/` + `opencode.json` | 原生 OpenCode agent 适配，含 `rulai` primary 编排 Agent |
| oh-my-claudecode | `.ai-workflow/` + `.ai-workflow/runtimes/oh-my-claudecode/` | 不生成重复 Claude Agent，由 oh-my-claudecode 接管编排 |
| oh-my-opencode | `.ai-workflow/` + `.ai-workflow/runtimes/oh-my-opencode/` | 不生成重复 OpenCode Agent，由 oh-my-opencode 接管编排 |

本项目核心只定义 SDLC 协议、门禁和产物契约。native runtime 会生成本项目自带 Agent；其中 OpenCode native 额外生成 `rulai` primary Agent 承担流程路由、阶段推进、产物传递、CTG 交付预检和返工循环。OpenCode native 支持轻量并行：当 ARCH 明确拆出多个独立 M-xxx 模块，且文件范围、接口契约和测试命令互不冲突时，`rulai` 可并行分派多个 bajie 子任务，并在进入 PLG 前执行合并门禁。oh-my-claudecode / oh-my-opencode runtime 只生成适配说明，由外部 runtime 的 Team / Autopilot / Ultrawork / Ralph / Sisyphus 等能力负责执行。

OpenCode native 适合个人本地、最少依赖、可审计的轻量编排。复杂多 worker、自动续跑、强并行实现或长任务恢复场景，优先选择 oh-my-opencode。

权限控制采用”工具层限制 + 提示词约束”双层设计。RCG（需求澄清）在所有工具中通过 tangseng/需求角色强制输出 RCU 实现；TDR（技术决策评审）在 native Claude Code 中通过 PreToolUse Hook 实现硬约束。所有工具通用协议统一安装在 `.ai-workflow/` 目录，产出物存档到 `.ai-workflow/artifacts/`。

## 自动化与自我进化

本项目的自动化是**协议级自动化**，不是后台 daemon，也不是替代 oh-my-* 的强 runtime。每次流水线运行会在 `.ai-workflow/runs/RUN-{timestamp}-{flow}/` 下维护运行态账本：

- `state.json`：当前 flow、mode、runtime、phase、gate、status、next_action
- `events.jsonl`：路由、Agent 完成、用户确认、门禁阻断、返工、恢复等不可变事件
- `metrics.json`：阶段耗时、调度次数、返工轮次、阻断项和验证次数
- `summary.md`：本次任务最终交付摘要
- `evolution.md`：流程改进建议

主会话、OpenCode native 的 `rulai` 或外部 runtime 编排者在调度 Agent 前必须读取 `state.json`，阶段完成后必须追加 `events.jsonl` 并更新状态。这样即使上下文中断、换工具或隔天继续，也可以按运行账本恢复，而不是依赖 AI 的上下文记忆。

自我进化只输出建议，不自动修改模板、项目代码、权限或门禁。`evolution.md` 中的建议分为：

- `local-tweak`：仅适合当前项目本地个性化调整
- `template-candidate`：可能适合沉淀回通用模板
- `runtime-adapter`：应交给 oh-my-* 或 native runtime 执行层优化

只有用户明确确认后，才把 `template-candidate` 作为新的模板改进任务执行。

## Superpowers 插件集成（可选增强）

本项目模板内置了与 [Superpowers](https://github.com/anthropics/superpowers) Claude Code 插件的可选集成。如果目标项目已安装 Superpowers 插件，Agent 会自动在对应阶段调用编码纪律技能。

### 集成的技能

| Agent | 融入的技能 | 增强效果 |
|-------|-----------|---------|
| bajie（开发） | TDD + writing-plans + subagent-driven + verification | 实现与单元测试有 RED→GREEN→REFACTOR 纪律 |
| nezha（测试） | systematic-debugging + verification | 单测执行验证、测试失败归因和补盲区更系统 |
| erlang（评审） | requesting/receiving-code-review | 评审有标准化流程 |
| wukong（架构） | brainstorming | TDR 方案探索更深入 |

### 优雅降级

未安装 Superpowers 插件时，Agent 定义中的技能引用为纯文本说明，不影响任何功能。安装后自动生效，无需额外配置。

### TDD 角色分工

wukong 在 ARCH 中定义测试契约；bajie 使用 TDD 编写实现和单元测试；nezha 负责执行验证单测质量，并补充测试盲区、集成测试、回归测试和覆盖率分析。

## 角色契约

| 角色 | 职责 | 权限 |
|------|------|------|
| tangseng | 需求分析，输出 REQ 文档 | 只读 |
| wukong | 技术决策、架构契约、编码合规审查 | 只读 |
| bajie | 功能实现与 TDD 单元测试编写 | 读写任务范围内代码 |
| nezha | 单测执行验证、集成测试、回归验证、覆盖率分析 | 读写测试 |
| erlang | 代码评审 | 只读 |
| lijing | 安全审计 | 只读 |
| bailongma | CI/CD 和部署 | 读写配置 |

OpenCode native 模式会额外生成 `rulai`，它不是第 8 个业务角色，而是流程编排者：只负责路由、门禁、产物传递、轻量并行分派、CTG 和返工判断，不替代上述角色的专业产出。

## 新功能开发流水线

```
用户需求
  ↓
tangseng → RCU（需求理解确认 + 用户确认）
  ↓
tangseng → REQ 文档（需求分析）
  ↓
wukong → TDR 文档（技术决策评审 + 用户选择方案）
  ↓
wukong → ARCH 文档（架构设计 + DG 自检）
  ↓
bajie（编码实现 + TDD 单元测试编写 + CG 预检；满足边界时轻量并行）
  ↓
wukong → PLG 编码合规审查
  ↓
交付预检(CTG)
  ↓
nezha(单测验证+集成测试+回归) ── 内部重做循环（增量模式）
  ↓
erlang(评审) ── 内部重做循环（增量模式）
  ↓          └── 行为变更修复 → 回退 nezha 重测
合并就绪
```

在 OpenCode native 模式下，上述流程由 `rulai` 作为 primary agent 推进；其他角色作为 subagent 执行对应阶段。RCG、TDR、ARCH、CTG 和用户确认门控保持串行；只有 ARCH 明确拆分且互不冲突的 M-xxx 编码任务允许轻量并行，所有并行输出必须先回到 `rulai` 合并后再进入 PLG。

## 初始化后要做的事

1. 阅读 `.ai-workflow/protocol.md`、`.ai-workflow/roles.md`、`.ai-workflow/gates.md`
2. 编辑 `.claude/CLAUDE.md`（native Claude Code）或 `AGENTS.md`（Codex），填写项目概述、技术栈、目录结构
3. 如果选择 native OpenCode，优先从 `rulai` 开始任务，由它按 flow 编排其他 Agent
4. 如果选择 oh-my runtime，阅读 `.ai-workflow/runtimes/<runtime>/README.md`
5. 使用快捷命令（native Claude Code 模式）开始工作：
   - `/tangseng` — 需求分析，输出 REQ 文档
   - `/wukong` — 架构设计（含 TDR 方案选择），输出 ARCH 文档
   - `/bajie` — 编码实现
   - `/nezha` — 单测验证、测试补强与回归
   - `/erlang` — 代码评审
   - `/lijing` — 安全审计

## 目录结构

```
ai-workflow-template/
├── init-workflow.sh              # 初始化脚本
├── templates/
│   ├── universal/                # 通用层
│   │   ├── AGENTS.md             # AGENTS.md 模板（仅新建时使用）
│   │   └── ai-workflow/          # 零侵入通用工作流
│   │       ├── protocol.md       # 通用协议
│   │       ├── roles.md          # 抽象角色契约
│   │       ├── gates.md          # 门禁协议
│   │       ├── runtime-map.md    # runtime 映射
│   │       ├── runs/             # 流水线运行状态账本协议
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
│   ├── opencode/                 # OpenCode 适配
│   │   └── agents/               # 7 个业务 Agent + rulai 编排 Agent
│   └── runtimes/                 # 外部 runtime adapter
│       ├── oh-my-claudecode/
│       └── oh-my-opencode/
└── README.md
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
- `.opencode/agents/` — OpenCode Agent 定义（native 模式包含 `rulai` 编排入口）
- `opencode.json` — OpenCode 配置
- `.ai-workflow/artifacts/` — 产出物存档（**重要数据，建议备份**）

### 备份产出物

如果项目中有重要的需求文档（REQ）、架构设计（ARCH）、测试计划等，建议在卸载前备份：

```bash
cp -r .ai-workflow/artifacts ~/ai-workflow-artifacts-backup
```

### 执行卸载

```bash
./.ai-workflow/uninstall.sh
```

## License

MIT
