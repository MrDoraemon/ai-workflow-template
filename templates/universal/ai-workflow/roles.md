# Role Contracts / 抽象角色契约

本文件定义 SDLC 协议层的抽象职责。具体由哪个 runtime agent、specialist、mode 或 worker 执行，由 runtime adapter 决定。

## 角色契约

| 角色 | 协议职责 | 必须产出 | 权限边界 |
|------|----------|----------|----------|
| analyst | 需求澄清与需求契约 | RCU、REQ | 只读，不修改项目文件 |
| architect | 技术决策、架构契约、编码合规 | TDR、ARCH、PLG | 只读，不修改项目文件 |
| developer | 按 ARCH 实现代码与自测 | 变更清单、验证结果、CDG | 只修改任务范围内文件 |
| qa | 测试设计、测试补充、回归验证 | TEST 报告 | 只修改测试相关文件 |
| reviewer | 独立代码评审 | REV 报告 | 只读，不执行写入命令 |
| security | 安全审计 | SEC 报告 | 只读，扫描命令需人工确认 |
| devops | 构建、部署、CI/CD 与环境配置 | 部署方案、CI 配置、发布报告 | 只修改配置与部署相关文件 |

## 设计原则

- 本文件只定义“谁负责什么”，不绑定具体 Agent 实现。
- native runtime 可以生成本项目自带 Agent 文件。
- oh-my-claudecode / oh-my-opencode 等 runtime 由其自身 specialist、mode 或 conductor 承担这些角色。
- runtime 可以决定并发、模型、工具和执行策略，但不能跳过协议层门禁。
