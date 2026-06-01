# AI Workflow Protocol / 多 Agent 协作协议

本文件定义项目的 AI-Native SDLC 协议，被 Claude Code / Codex CLI / OpenCode 及外部 runtime adapter 识别。

相关协议文件：
- `roles.md`：抽象角色契约，不绑定具体 agent 实现
- `gates.md`：RCG / TDR / ARCH / PLG / CTG 门禁
- `runtime-map.md`：native / oh-my-claudecode / oh-my-opencode 映射原则

## 可用角色

| 角色 | 职责 | 权限 |
|------|------|------|
| analyst | 需求分析，输出 REQ 文档 | 只读 |
| architect | 架构设计，输出 ARCH 文档 | 只读 |
| developer | 通用功能实现 | 读写任务范围内代码 |
| qa | 测试编写与执行 | 读写测试 |
| reviewer | 代码评审 | 只读 |
| security | 安全审计 | 只读 |
| devops | CI/CD 和部署 | 读写配置 |

权限优先由具体工具配置落地：Claude Code / OpenCode 模板会限制 `reviewer`、`security` 的写入和 Bash 权限；不支持工具级隔离的环境以本文件约束为准。

## 强制路由协议

**收到用户需求后，必须先分类意图并声明走哪条流水线，然后再开始执行。**

路由判定清单：

| 用户意图 | 命中流水线 | 判定依据 |
|----------|-----------|---------|
| 添加功能 / 新页面 / 新组件 / 新 API / 新模块 / 集成第三方工具或库 / 新增配置项 / 使用某个工具/库/plugin 实现某个能力 | **feature-flow** | 任何引入新能力或改变行为的请求 |
| 修复错误 / 测试失败 / 异常日志 / 回归问题 / 性能劣化 | **bugfix-flow** | 任何恢复正确行为的请求 |
| 发布 / 部署 / 上线 / 打 tag / 版本发布 | **release-flow** | 任何向环境交付的请求 |
| 代码评审 / 检查代码 | reviewer | 纯分析，不改变代码 |

**必须触发 feature-flow 的典型场景**（容易漏判）：用 XX 库/plugin/SDK 实现 YY、加页面/组件/接口、接入外部服务、优化实现方式、重构架构模式、配置新功能。

**降级保护**：意图不明确时默认归类为 feature-flow；不能仅凭"快速修"等措辞降级；每次路由判定后声明 `[Flow: xxx]`。

## 流水线触发规则

- **新功能需求** → analyst(+RCG 需求澄清) → architect(+TDR 方案选择+设计自检 DG) → developer(+上下文预检 CG，可按模块并行调度) → architect(+编码合规预检 PLG) → 交付预检(CTG) → qa → reviewer
- **Bug 修复** → 定位问题 → developer → qa → reviewer
- **代码评审** → reviewer（可选 + security）
- **部署** → qa → security → devops

## 预检机制（四阶段质量门控）

| 阶段 | 名称 | 执行者 | 门禁强度 |
|------|------|--------|---------|
| 1 | 设计预检 (DG-01~09) | architect 自检 | 强门禁：100% PASS 才能编码 |
| 2 | 编码前上下文预检 (CG-01~06) | developer 自检 | 强门禁：100% PASS 才能编码 |
| 3 | 编码合规预检 (PLG-01~07) | architect 独立审查 | 强门禁：发现即修复 |
| 4 | 交付预检 (CTG-01~05) | 主会话 | 分级门控：阻断项必修 |

## 产出物存档规范

- `requirements/` — REQ 需求文档
- `architectures/` — ARCH 架构文档
- `reviews/` — REV 评审报告
- `tests/` — TEST 测试报告
- `security/` — SEC 安全审计报告

## 协作原则

- 主会话充当编排者，按需调度子 Agent
- Agent 之间不直接调用，数据通过主会话传递
- 每个阶段完成后必须通知主会话当前状态
