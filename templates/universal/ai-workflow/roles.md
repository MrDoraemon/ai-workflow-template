# Role Contracts / 抽象角色契约

本文件定义 SDLC 协议层的抽象职责。具体由哪个 runtime agent、specialist、mode 或 worker 执行，由 runtime adapter 决定。

## 角色契约

| 角色 | 协议职责 | 必须产出 | 权限边界 |
|------|----------|----------|----------|
| tangseng | 需求澄清与需求契约 | RCU、REQ | 只读，不修改项目文件 |
| wukong | 技术决策、架构契约、编码合规审查 | TDR、ARCH、PLG 报告 | 只读，不修改项目文件 |
| bajie | 按 ARCH 实现代码与自测 | 变更清单、验证结果、CDG | 只修改任务范围内文件 |
| nezha | 测试设计、测试补充、回归验证 | TEST 报告 | 只修改测试相关文件 |
| erlang | 独立代码评审 | REV 报告 | 只读，不执行写入命令 |
| lijing | 安全审计 | SEC 报告 | 只读，扫描命令需人工确认 |
| bailongma | 构建、部署、CI/CD 与环境配置 | 部署方案、CI 配置、发布报告 | 只修改配置与部署相关文件 |

## 设计原则

- 本文件只定义“谁负责什么”，不绑定具体 Agent 实现。
- native runtime 可以生成本项目自带 Agent 文件。
- oh-my-claudecode / oh-my-opencode 等 runtime 由其自身 specialist、mode 或 conductor 承担这些角色。
- runtime 可以决定并发、模型、工具和执行策略，但不能跳过协议层门禁。

## Superpowers 技能映射（可选）

| 角色 | 推荐技能 | 触发时机 |
|------|---------|---------|
| bajie | test-driven-development, writing-plans, subagent-driven-development, verification-before-completion | 编码前计划 + 编码实现 + 完成验证 |
| nezha | systematic-debugging, verification-before-completion | 测试失败分析 + 测试报告输出 |
| erlang | requesting-code-review, receiving-code-review | 评审发起 + 评审反馈处理 |
| wukong | brainstorming | TDR 技术决策评审 |

此映射为建议性质，由各 Agent 模板中的文本指引落地。Runtime 可根据实际环境决定是否启用。
