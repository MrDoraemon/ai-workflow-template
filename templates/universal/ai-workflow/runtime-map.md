# Runtime Map / Runtime 映射

本项目的核心是 SDLC 协议层。runtime 只负责执行协议，不拥有跳过门禁的权限。

无论使用 native 还是 oh-my runtime，都必须维护 `.ai-workflow/runs/` 运行状态账本，用于阶段恢复、门禁追踪、返工归因和自我进化建议。

## native

生成本项目自带的轻量 Agent / workflow / command 模板。

OpenCode native 会额外生成 `rulai` primary agent，负责路由、阶段推进、产物传递、运行状态维护、CTG 交付预检和返工循环；其他业务角色仍作为 subagent 执行专业任务。

OpenCode native 支持轻量并行：当 ARCH 明确拆出多个独立 M-xxx 模块，且文件范围、接口契约和测试命令互不冲突时，rulai 可以并行分派多个 bajie 子任务，并在进入 PLG 前执行合并门禁。复杂多 worker、自动续跑或强并行场景，优先选择 oh-my-opencode。

适用场景：
- 不安装 oh-my-claudecode 或 oh-my-opencode
- 需要最少依赖、可审计的本地模板
- 新项目快速启用 AI workflow
- OpenCode 项目以轻量编排为主，复杂并行需求不强

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
| PLG / CTG / Review | Ralph 或 Autopilot + erlang |

原则：Ultrawork / Team 只能在 ARCH 确认后进入实现阶段。oh-my runtime 可以使用自身状态管理，但需要把关键状态同步到 `.ai-workflow/runs/`。

## oh-my-opencode

不生成本项目自带 OpenCode Agent，改由 oh-my-opencode / Sisyphus 等执行。

推荐映射：

| SDLC 阶段 | 推荐执行方式 |
|-----------|--------------|
| RCG / REQ | read-only tangseng / planning agent |
| TDR / ARCH | oracle / wukong 类只读 agent |
| 编码实现 | Sisyphus / worker |
| 多模块并行 | conductor 分派 worker |
| Review / Security | oracle / erlang / lijing 类只读 agent |

原则：Sisyphus 等强编排只能在 RCU、REQ、TDR、ARCH 完成后进入实现阶段。oh-my runtime 可以使用自身状态管理，但需要把关键状态同步到 `.ai-workflow/runs/`。
