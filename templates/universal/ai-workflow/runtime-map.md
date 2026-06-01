# Runtime Map / Runtime 映射

本项目的核心是 SDLC 协议层。runtime 只负责执行协议，不拥有跳过门禁的权限。

## native

生成本项目自带的轻量 Agent / workflow / command 模板。

适用场景：
- 不安装 oh-my-claudecode 或 oh-my-opencode
- 需要最少依赖、可审计的本地模板
- 新项目快速启用 AI workflow

## oh-my-claudecode

不生成本项目自带 Claude Agent，改由 oh-my-claudecode 的 mode / specialist 执行。

推荐映射：

| SDLC 阶段 | 推荐执行方式 |
|-----------|--------------|
| RCG / REQ | Autopilot，顺序执行 |
| TDR / ARCH | Autopilot 或小规模 Team |
| 编码实现 | 小任务 Autopilot，大任务 Ultrawork |
| 多模块并行 | Team 或 Ultrawork |
| 难修 bug / 最终验证 | Ralph |
| PLG / CTG / Review | Ralph 或 Autopilot + reviewer |

原则：Ultrawork / Team 只能在 ARCH 确认后进入实现阶段。

## oh-my-opencode

不生成本项目自带 OpenCode Agent，改由 oh-my-opencode / Sisyphus 等执行。

推荐映射：

| SDLC 阶段 | 推荐执行方式 |
|-----------|--------------|
| RCG / REQ | read-only analyst / planning agent |
| TDR / ARCH | oracle / architect 类只读 agent |
| 编码实现 | Sisyphus / worker |
| 多模块并行 | conductor 分派 worker |
| Review / Security | oracle / reviewer / security 类只读 agent |

原则：Sisyphus 等强编排只能在 RCU、REQ、TDR、ARCH 完成后进入实现阶段。
