
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
| 代码评审 / 检查代码 / 看看有什么问题 | analyst + reviewer | 纯分析，不改变代码 |

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
| analyst | `.claude/agents/analyst.md` | 只读 | 需求分析，输出 REQ 文档 |
| architect | `.claude/agents/architect.md` | 只读 | 架构设计 |
| developer | `.claude/agents/developer.md` | 读写任务范围内代码 | 通用功能实现 |
| qa | `.claude/agents/qa.md` | 读写测试 | 测试编写与执行 |
| reviewer | `.claude/agents/reviewer.md` | 只读 | 代码评审 |
| security | `.claude/agents/security.md` | 只读 | 安全审计 |
| devops | `.claude/agents/devops.md` | 读写配置 | CI/CD 和部署 |

`reviewer` 和 `security` 不具备 Bash / Edit / Write 工具。需要执行测试、安全扫描或依赖审计时，由主会话或具备执行权限的 Agent 在人工确认后执行。

### 流水线触发规则

- **新功能需求** → analyst → architect(+TDR 方案选择+设计自检 DG) → developer(+上下文预检 CG，可按模块并行调度) → architect(+编码合规预检 PLG) → 交付预检(CTG) → qa → reviewer
- **Bug 修复** → 定位问题 → developer → qa → reviewer
- **代码评审** → reviewer（可选 + security）
- **部署** → qa → security → devops

### 产出物存档规范

流水线执行过程中，主会话在收到 Agent 输出后，必须将结构化产出物存档到 `.claude/artifacts/` 对应子目录。

- **存档目录**：
  - `.claude/artifacts/requirements/` — REQ 需求文档
  - `.claude/artifacts/architectures/` — ARCH 架构文档
  - `.claude/artifacts/reviews/` — REV 评审报告
  - `.claude/artifacts/tests/` — TEST 测试报告
  - `.claude/artifacts/security/` — SEC 安全审计报告
- **索引更新**：每次存档后更新 `.claude/artifacts/index.md`

### 预检机制（四阶段质量门控）

| 阶段 | 名称 | 执行者 | 门禁强度 | 规则 |
|------|------|--------|---------|------|
| 1 | 设计预检 (DG-01~09) | architect 自检 | **强门禁** | 100% PASS → 才能编码 |
| 2 | 编码前上下文预检 (CG-01~06) | developer 自检 | **强门禁** | 100% PASS → 才能编码 |
| 3 | 编码合规预检 (PLG-01~07) | architect 独立审查 | **强门禁** | 发现即修复，不可带病推进 |
| 4 | 交付预检 (CTG-01~05) | 主会话 | **分级门控** | 阻断项必修 + 风险清单 + 人工终审 |
