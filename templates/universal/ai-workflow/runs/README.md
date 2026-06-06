# Runs / 流水线运行状态协议

本目录记录每一次 AI Workflow 流水线运行的状态、事件、度量和复盘结果。它是运行态账本，不替代 `.ai-workflow/artifacts/` 中的正式产出物。

## 目录结构

每次任务创建一个独立目录：

```text
.ai-workflow/runs/
  RUN-{YYYYMMDD-HHMMSS}-{flow}/
    state.json
    events.jsonl
    metrics.json
    summary.md
    evolution.md
```

`RUN-*` 目录由主会话、OpenCode native 的 `rulai` 或外部 runtime 编排者创建和维护。

## state.json

`state.json` 只记录当前运行状态，用于恢复、推进和门禁判断。建议字段：

```json
{
  "run_id": "RUN-20260606-153000-feature-flow",
  "flow": "feature-flow",
  "mode": "standard",
  "runtime": "native-opencode",
  "phase": "TDR",
  "gate": "TDR",
  "status": "WAITING_USER",
  "current_artifact": "TDR-20260606-001",
  "next_action": "等待用户选择技术方案",
  "rework_count": 0,
  "updated_at": "2026-06-06T15:30:00+08:00"
}
```

### status 枚举

| 状态 | 含义 |
|------|------|
| `READY` | 阶段输入齐全，可调度 Agent 或执行门禁 |
| `RUNNING` | 当前阶段正在执行 |
| `WAITING_USER` | 等待用户确认、选择或授权 |
| `BLOCKED` | 缺少输入、命令失败、权限不足或门禁阻断 |
| `REWORK` | 进入返工循环，等待目标 Agent 修复或补强 |
| `DONE` | 当前 flow 已完成，合并或交付就绪 |

## events.jsonl

`events.jsonl` 追加记录不可变事件，每行一个 JSON 对象。常见事件：

```jsonl
{"ts":"2026-06-06T15:30:00+08:00","event":"flow_routed","flow":"feature-flow","mode":"standard"}
{"ts":"2026-06-06T15:31:00+08:00","event":"agent_completed","agent":"tangseng","artifact":"RCU-20260606-001"}
{"ts":"2026-06-06T15:32:00+08:00","event":"user_confirmed","gate":"RCG","artifact":"RCU-20260606-001"}
{"ts":"2026-06-06T15:40:00+08:00","event":"gate_blocked","gate":"CTG","reason":"测试命令不可执行"}
```

事件必须追加写入，不得改写历史。需要纠正时追加新的 `state_corrected` 或 `artifact_replaced` 事件。

## metrics.json

`metrics.json` 记录可复盘指标：

- 每个阶段耗时
- Agent 调度次数
- 用户确认次数
- 返工轮次
- 测试失败类型
- PLG / CTG / Review 阻断项数量
- 增量验证与全量验证次数

指标允许近似，但不得伪造未执行的命令、测试或审查结果。

## summary.md

`summary.md` 是本次运行的交付摘要，应包含：

- 用户原始目标
- 最终 flow / mode / runtime
- 关键产出物链接
- 变更清单
- 已执行验证
- 剩余风险
- 是否合并就绪

## evolution.md

`evolution.md` 是自我进化建议，不自动修改模板或项目代码。

建议必须分级：

| 分级 | 含义 |
|------|------|
| `local-tweak` | 仅适合当前项目本地个性化调整 |
| `template-candidate` | 可能适合沉淀回通用模板 |
| `runtime-adapter` | 应交给 oh-my-* 或 native runtime 执行层优化 |

每条建议必须包含证据、影响范围、推荐改动和回滚方式。禁止自动降低门禁、放宽权限、新增依赖或把单次项目经验直接提升为通用模板规则。

## 恢复规则

当上下文中断或换工具继续时，编排者必须：

1. 读取最近一个未完成的 `RUN-*` 目录
2. 读取 `state.json` 判断当前状态
3. 对照 `events.jsonl`、confirmed 标记和 artifacts 文件验证一致性
4. 只从 `next_action` 指向的阶段继续，不凭上下文记忆跳步

如果状态与产出物不一致，必须进入 `BLOCKED`，说明冲突并等待用户确认修复方式。
