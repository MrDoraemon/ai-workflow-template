# oh-my-claudecode Adapter

本 adapter 不复制本项目自带 Claude Agent。oh-my-claudecode 负责 agent 编排、mode 选择、并发执行和验证；`.ai-workflow` 负责 SDLC 协议、门禁、产物契约和运行状态账本。

## 使用原则

```text
RCG / REQ / TDR / ARCH：顺序确认，禁止并发发散
Developer / QA / Review：ARCH 确认后可并发
CTG：集中收敛，阻断项清零后交付
```

## 推荐模式

| 阶段 | 推荐模式 |
|------|----------|
| RCG | Autopilot |
| REQ | Autopilot |
| TDR | Autopilot 或 Team 小队 |
| ARCH | Autopilot |
| 小型实现 | Autopilot |
| 大型实现 | Ultrawork |
| 多模块协同 | Team |
| 难修 bug / 验证收敛 | Ralph |

## 强制边界

- 用户指定 Ultrawork / Team / Ralph 只是 runtime 偏好，不允许绕过 RCG、TDR、ARCH、CTG。
- Ultrawork / Team 只能在 ARCH confirmed 后进入实现。
- Ralph 适合作为 CTG 后的强验证收敛器。
- 关键阶段、门禁、返工和最终结果必须同步到 `.ai-workflow/runs/RUN-*/state.json` 与 `events.jsonl`。

## 推荐提示

```text
[Flow: feature-flow]
[Runtime: oh-my-claudecode]
[Execution preference: ultrawork after ARCH]

先按 .ai-workflow/protocol.md 完成 RCG、REQ、TDR、ARCH。
执行过程中维护 .ai-workflow/runs/ 运行状态账本。
ARCH confirmed 后，再使用 Ultrawork 并行实现。
```
