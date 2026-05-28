
## Multi-Agent 协作协议

本项目的 Claude Code 会话遵循多 Agent 协作模式（Orchestrator-Worker）。主会话充当编排者，按需调用子 Agent，每个 Agent 只做自己的事，输出回流给主会话。

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

- **新功能需求** → analyst → architect(+设计自检 DG) → developer(+上下文预检 CG，可按模块并行调度) → architect(+编码合规预检 PLG) → 交付预检(CTG) → qa → reviewer
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
