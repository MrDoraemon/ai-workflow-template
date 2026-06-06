# 项目概述

> 以下信息供 Agent 启动时读取项目上下文，请根据实际项目填写。

## 项目简介
<!-- 一段话描述项目目标和定位 -->

## 技术栈
<!-- 如：语言、框架、包管理、数据库等 -->

## 目录结构
<!-- 列出关键目录及其职责 -->

## 开发命令
<!-- 启动、构建、测试、lint 等命令 -->

## Multi-Agent 协作协议

本项目的 Claude Code 会话遵循多 Agent 协作模式（Orchestrator-Worker）。主会话充当编排者，按需调用子 Agent，每个 Agent 只做自己的事，输出回流给主会话。

### 强制路由协议（最高优先级）

**规则：收到用户需求后，必须先分类意图并声明走哪条流水线，然后再开始执行。**

路由判定清单：

| 用户意图 | 命中流水线 | 判定依据 |
|----------|-----------|---------|
| 添加功能 / 新页面 / 新组件 / 新 API / 新模块 / 集成第三方工具或库 / 新增配置项 / 使用某个工具/库/plugin 实现某个能力 | **feature-flow** | 任何引入新能力或改变行为的请求 |
| 修复错误 / 测试失败 / 异常日志 / 回归问题 / 性能劣化 | **bugfix-flow** | 任何恢复正确行为的请求 |
| 发布 / 部署 / 上线 / 打 tag / 版本发布 | **release-flow** | 任何向环境交付的请求 |
| 代码评审 / 检查代码 / 看看有什么问题 | tangseng + erlang | 纯分析，不改变代码 |

**必须触发 feature-flow 的典型场景**（容易漏判）：

- "用 XX 库/plugin/SDK 实现 YY" — 引入新依赖实现新能力 = 新功能
- "加一个页面/组件/接口" — 新增产物 = 新功能
- "接入 XX 服务" — 集成外部系统 = 新功能
- "优化 YY 的实现方式" — 改变行为或架构 = 新功能
- "重构为 XX 模式" — 改变架构 = 新功能（除非是纯重命名等无行为变化）
- "配置 XX 功能" — 新增功能配置 = 新功能

**不需要触发流水线的场景**：

- 纯问答（"XX 是什么""怎么用 YY"）→ 直接回答
- 查看代码（"帮我看看这个文件"）→ 直接读
- 微小修改（改 typo、改注释、调整格式）→ 直接改，走 lite 模式

**降级保护**：

- 如果用户请求模棱两可，默认归类为 feature-flow（宁可多走流程，不可跳过）
- 如果用户明确说"简单改一下""快速修"等表达，仍需判断本质：是新功能还是小改动？不能仅凭措辞降级
- 每次路由判定后，主会话必须向用户声明：`[Flow: feature-flow]` / `[Flow: bugfix-flow]` / `[Flow: release-flow]` / `[Flow: direct]`

### 可用 Agent 清单

| Agent | 文件 | 权限 | 职责 |
|---|---|---|---|
| tangseng | `.claude/agents/tangseng.md` | 只读 | 需求分析，输出 REQ 文档 |
| wukong | `.claude/agents/wukong.md` | 只读 | 技术决策评审(TDR)、架构设计(ARCH)、编码合规审查(PLG) |
| bajie | `.claude/agents/bajie.md` | 读写任务范围内代码 | 功能实现与 TDD 单元测试编写 |
| nezha | `.claude/agents/nezha.md` | 读写测试 | 单测执行验证、集成测试、回归验证、覆盖率分析 |
| erlang | `.claude/agents/erlang.md` | 只读 | 代码评审 |
| lijing | `.claude/agents/lijing.md` | 只读 | 安全审计 |
| bailongma | `.claude/agents/bailongma.md` | 读写配置 | CI/CD 和部署 |

`erlang` 和 `lijing` 不具备 Bash / Edit / Write 工具。需要执行测试、安全扫描或依赖审计时，由主会话或具备执行权限的 Agent 在人工确认后执行。

### 流水线触发规则

- **新功能需求** → tangseng(+RCG 需求澄清) → wukong(+TDR 方案选择+设计自检 DG) → bajie(+上下文预检 CG + 单测编写，可按模块并行调度) → wukong(+编码合规审查 PLG) → 交付预检(CTG) → nezha(+单测验证 + 测试补强) → erlang
- **Bug 修复** → 定位问题 → bajie → nezha → erlang
- **代码评审** → erlang（可选 + lijing）
- **部署** → nezha → lijing → bailongma

### 产出物存档规范

流水线执行过程中，主会话在收到 Agent 输出后，必须将结构化产出物存档到 `.ai-workflow/artifacts/` 对应子目录。

- **存档目录**：
  - `.ai-workflow/artifacts/requirements/` — REQ 需求文档
  - `.ai-workflow/artifacts/architectures/` — ARCH 架构文档
  - `.ai-workflow/artifacts/reviews/` — REV 评审报告
  - `.ai-workflow/artifacts/tests/` — TEST 测试报告
  - `.ai-workflow/artifacts/security/` — SEC 安全审计报告
- **索引更新**：每次存档后更新 `.ai-workflow/artifacts/index.md`

#### 存档协议

所有 Agent 产出物存档必须遵循以下步骤：

1. **完整写入**：将 Agent 输出的完整原文逐字写入文件，不得摘要、截断或省略
2. **结构验证**：读取已写入文件，检查所有必需章节存在
3. **索引更新**：更新 index.md，记录文档编号和一行摘要
4. **验证失败处理**：如结构验证失败，重新保存 Agent 输出；如上下文已丢失则重新调度 Agent

各文档类型的结构要求：

| 文档类型 | 必需章节 | 识别标记 |
|---------|---------|---------|
| RCU | §1-§7（RCU-1 ~ RCU-7） | `RCU-` 前缀标题 |
| REQ | §1-§9 | `### 1.` ~ `### 9.` 编号标题 |
| TDR | §1-§4（TDR-1 ~ TDR-4） | `TDR-` 前缀标题 |
| ARCH | §1-§10 + DG 自检 | `### 1.` ~ `### 10.` + `DG-0` 编号 |
| TEST | 测试报告结构 | 根据模板定义 |
| REV | 评审报告结构 | 根据模板定义 |

验证方法：扫描文件中的章节标题标记，与上表比对。缺失任一必需章节即判定为验证失败。

### 运行状态协议

流水线执行过程中，主会话必须维护 `.ai-workflow/runs/` 运行态账本。每次任务创建一个 `RUN-{YYYYMMDD-HHMMSS}-{flow}/` 目录，至少包含：

- `state.json`：当前 flow、mode、runtime、phase、gate、status、next_action
- `events.jsonl`：路由、Agent 完成、用户确认、门禁阻断、返工、恢复等不可变事件
- `metrics.json`：阶段耗时、调度次数、返工轮次、阻断项、验证次数等复盘指标
- `summary.md`：本次任务最终交付摘要
- `evolution.md`：自我进化建议

调度 Agent 或执行门禁前，主会话必须读取 `state.json`，不得只依赖上下文记忆。遇到 RCG、TDR、ARCH、CTG 等人工门控时，`status` 必须更新为 `WAITING_USER`；遇到测试失败、评审阻断或门禁失败时，必须进入 `REWORK` 或 `BLOCKED` 并记录归因。

`evolution.md` 只提出 local-tweak / template-candidate / runtime-adapter 建议，不自动修改模板、项目代码、权限或门禁。

### 质量门控（四阶段）

| 阶段 | 名称 | 执行者 | 门禁强度 | 规则 |
|------|------|--------|---------|------|
| 1 | 设计预检 (DG-01~09) | wukong 自检 | **强门禁** | 100% PASS → 才能编码 |
| 2 | 编码前上下文预检 (CG-01~07) | bajie 自检 | **强门禁** | 100% PASS → 才能编码 |
| 3 | 编码合规审查 (PLG-01~07) | wukong 独立审查 | **强门禁** | 发现即修复，不可带病推进 |
| 4 | 交付预检 (CTG-01~05) | 主会话 | **分级门控** | 阻断项必修 + 风险清单 + 人工终审 |

CTG-04 必须额外检查 `state.json`、confirmed 标记和 artifacts 的一致性；不一致时进入 `BLOCKED`。
