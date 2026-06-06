# oh-my-opencode Adapter

本 adapter 不复制本项目自带 OpenCode Agent。oh-my-opencode / Sisyphus 等 runtime 负责 agent 编排、并发执行和工具调用；`.ai-workflow` 负责 SDLC 协议、门禁、产物契约和运行状态账本。

## 使用原则

```text
RCG / REQ / TDR / ARCH：使用只读 planning / oracle 类 agent
实现阶段：ARCH confirmed 后再交给 Sisyphus / worker
Review / Security：使用只读审查 agent
```

## 强制边界

- Sisyphus 不能从用户一句话直接开始写代码。
- 实现前必须存在已确认的 RCU、REQ、TDR、ARCH。
- conductor 可以分派 worker，但不能决定跳过门禁。
- 关键阶段、门禁、返工和最终结果必须同步到 `.ai-workflow/runs/RUN-*/state.json` 与 `events.jsonl`。

## 推荐提示

```text
[Flow: feature-flow]
[Runtime: oh-my-opencode]
[Execution preference: Sisyphus after ARCH]

先读取 .ai-workflow/protocol.md。
执行过程中维护 .ai-workflow/runs/ 运行状态账本。
完成 RCG、REQ、TDR、ARCH 并取得 confirmed 标记后，再使用 Sisyphus 分派实现任务。
```
