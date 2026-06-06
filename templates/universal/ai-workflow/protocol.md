# AI Workflow Protocol / 多 Agent 协作协议

本文件定义项目的 AI-Native SDLC 协议，被 Claude Code / Codex CLI / OpenCode 及外部 runtime adapter 识别。

相关协议文件：
- `roles.md`：抽象角色契约，不绑定具体 agent 实现
- `gates.md`：RCG / TDR / ARCH / PLG / CTG 门禁
- `runtime-map.md`：native / oh-my-claudecode / oh-my-opencode 映射原则
- `runs/README.md`：流水线运行状态、事件日志、度量和自我进化建议协议

## 可用角色

| 角色 | 职责 | 权限 |
|------|------|------|
| tangseng | 需求分析，输出 REQ 文档 | 只读 |
| wukong | 技术决策、架构契约、编码合规审查 | 只读 |
| bajie | 功能实现与 TDD 单元测试编写 | 读写任务范围内代码 |
| nezha | 单测执行验证、集成测试、回归验证、覆盖率分析 | 读写测试 |
| erlang | 代码评审 | 只读 |
| lijing | 安全审计 | 只读 |
| bailongma | CI/CD 和部署 | 读写配置 |

权限优先由具体工具配置落地：Claude Code / OpenCode 模板会限制 `erlang`、`lijing` 的写入和 Bash 权限；不支持工具级隔离的环境以本文件约束为准。

## 强制路由协议

**收到用户需求后，必须先分类意图并声明走哪条流水线，然后再开始执行。**

路由判定清单：

| 用户意图 | 命中流水线 | 判定依据 |
|----------|-----------|---------|
| 添加功能 / 新页面 / 新组件 / 新 API / 新模块 / 集成第三方工具或库 / 新增配置项 / 使用某个工具/库/plugin 实现某个能力 | **feature-flow** | 任何引入新能力或改变行为的请求 |
| 修复错误 / 测试失败 / 异常日志 / 回归问题 / 性能劣化 | **bugfix-flow** | 任何恢复正确行为的请求 |
| 发布 / 部署 / 上线 / 打 tag / 版本发布 | **release-flow** | 任何向环境交付的请求 |
| 代码评审 / 检查代码 | erlang | 纯分析，不改变代码 |

**必须触发 feature-flow 的典型场景**（容易漏判）：用 XX 库/plugin/SDK 实现 YY、加页面/组件/接口、接入外部服务、优化实现方式、重构架构模式、配置新功能。

**降级保护**：意图不明确时默认归类为 feature-flow；不能仅凭"快速修"等措辞降级；每次路由判定后声明 `[Flow: xxx]`。

## 流水线触发规则

- **新功能需求** → tangseng(+RCG 需求澄清) → wukong(+TDR 方案选择+设计自检 DG) → bajie(+上下文预检 CG + 单测编写，满足边界时可轻量并行) → wukong(+编码合规审查 PLG) → 交付预检(CTG) → nezha(+单测验证 + 测试补强) → erlang
- **Bug 修复** → 定位问题 → bajie → nezha → erlang
- **代码评审** → erlang（可选 + lijing）
- **部署** → nezha → lijing → bailongma

## 质量门控（四阶段）

| 阶段 | 名称 | 执行者 | 门禁强度 |
|------|------|--------|---------|
| 1 | 设计预检 (DG-01~09) | wukong 自检 | 强门禁：100% PASS 才能编码 |
| 2 | 编码前上下文预检 (CG-01~07) | bajie 自检 | 强门禁：100% PASS 才能编码 |
| 3 | 编码合规审查 (PLG-01~07) | wukong 独立审查 | 强门禁：发现即修复 |
| 4 | 交付预检 (CTG-01~05) | 主会话 / OpenCode native: rulai | 分级门控：阻断项必修 |

## 产出物存档规范

- `requirements/` — REQ 需求文档
- `architectures/` — ARCH 架构文档
- `reviews/` — REV 评审报告
- `tests/` — TEST 测试报告
- `security/` — SEC 安全审计报告

### 存档协议

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

## 运行状态协议

流水线执行必须维护 `.ai-workflow/runs/` 运行态账本。每次任务创建一个 `RUN-{YYYYMMDD-HHMMSS}-{flow}/` 目录，至少包含：

- `state.json`：当前 flow、mode、runtime、phase、gate、status、next_action
- `events.jsonl`：路由、Agent 完成、用户确认、门禁阻断、返工、恢复等不可变事件
- `metrics.json`：阶段耗时、调度次数、返工轮次、阻断项、验证次数等复盘指标
- `summary.md`：本次任务最终交付摘要
- `evolution.md`：自我进化建议

`state.json` 的 `status` 只能使用以下值：

| 状态 | 含义 |
|------|------|
| `READY` | 阶段输入齐全，可调度 Agent 或执行门禁 |
| `RUNNING` | 当前阶段正在执行 |
| `WAITING_USER` | 等待用户确认、选择或授权 |
| `BLOCKED` | 缺少输入、命令失败、权限不足或门禁阻断 |
| `REWORK` | 进入返工循环，等待目标 Agent 修复或补强 |
| `DONE` | 当前 flow 已完成，合并或交付就绪 |

### 状态推进规则

1. 主会话或 runtime 编排者收到任务后，必须先创建或选择当前 `RUN-*` 目录
2. 每次调度 Agent 或执行门禁前，必须读取 `state.json`，不得只依赖上下文记忆
3. 每次 Agent 完成、用户确认、门禁失败、返工或恢复时，必须追加写入 `events.jsonl`
4. 每个阶段结束后，必须更新 `state.json` 的 `phase`、`gate`、`status` 和 `next_action`
5. 遇到 RCG、TDR、ARCH、CTG 等人工门控时，必须进入 `WAITING_USER`
6. 遇到测试失败、评审阻断或门禁失败时，必须进入 `REWORK` 或 `BLOCKED`，并记录归因和目标阶段

### 恢复规则

上下文中断、换工具或继续历史任务时，编排者必须读取最近一个未完成的 `RUN-*` 目录，并对照 `state.json`、`events.jsonl`、confirmed 标记和 artifacts 文件验证一致性。状态与产出物不一致时，必须进入 `BLOCKED` 并等待用户确认修复方式。

## 自我进化协议

每次 flow 进入 `DONE` 或 `BLOCKED` 后，编排者必须生成 `evolution.md`。自我进化只提出建议，不自动修改模板、项目代码、权限或门禁。

建议分级：

| 分级 | 含义 |
|------|------|
| `local-tweak` | 仅适合当前项目本地个性化调整 |
| `template-candidate` | 可能适合沉淀回通用模板 |
| `runtime-adapter` | 应交给 oh-my-* 或 native runtime 执行层优化 |

每条建议必须包含证据、影响范围、推荐改动和回滚方式。禁止自动降低门禁、放宽权限、新增依赖或把单次项目经验直接提升为通用模板规则。

## Runtime 编排者

- Claude Code / Codex CLI：由主会话承担流程编排、产物传递、门禁停顿和 CTG。
- OpenCode native：由 `rulai` primary agent 承担上述编排职责，业务角色仍作为 subagent 执行专业任务；仅在 ARCH 模块边界清晰且互不冲突时执行轻量并行。
- oh-my-claudecode / oh-my-opencode：由外部 runtime 的 Team / Autopilot / Ultrawork / Ralph / Sisyphus 等能力承担编排，本项目不重复生成 native 编排 agent。

## 协作原则

- 主会话或 runtime 编排者按需调度子 Agent
- Agent 之间不直接调用，数据通过主会话或 runtime 编排者传递
- 每个阶段完成后必须通知主会话或 runtime 编排者当前状态
- 每个阶段完成后必须更新 `.ai-workflow/runs/` 中的运行状态和事件日志

### Superpowers 插件增强（可选）

各 Agent 模板中可选嵌入 Superpowers 插件技能引用。这是纯提示词级别的增强，不改变协议门控逻辑，不引入硬依赖。安装了 Superpowers 的环境自动获得编码纪律增强；未安装的环境不受影响。
