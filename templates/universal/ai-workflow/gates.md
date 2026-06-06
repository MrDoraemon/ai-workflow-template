# Gates / 门禁协议

本文件定义跨 runtime 的硬性流程门禁。

## Gate 顺序

```text
RCG 需求澄清
  ↓
REQ 需求文档
  ↓
TDR 技术决策
  ↓
ARCH 架构契约
  ↓
CG 编码前上下文预检
  ↓
PLG 编码合规审查
  ↓
CTG 交付预检
  ↓
QA / Review / Security
```

## RCG

- feature-flow 中 tangseng 必须首先输出 RCU。
- 用户确认 RCU 前，不得生成 REQ。
- lite 模式可以输出精简 RCU，但不可由 AI 自行跳过。

确认标记：

```text
.ai-workflow/artifacts/requirements/RCU-{YYYYMMDD}-{NNN}.confirmed
```

## TDR

- 架构设计 Phase 2 中 wukong 必须首先输出 TDR。
- 用户确认 TDR 前，不得生成 ARCH。
- lite 模式可快速接受推荐，但不可由 AI 自行跳过。

确认标记：

```text
.ai-workflow/artifacts/architectures/TDR-{YYYYMMDD}-{NNN}.confirmed
```

## ARCH

- ARCH 必须基于已确认的 REQ 和 TDR 决策生成。
- ARCH 必须包含 DG 自检，且 100% PASS 后才能进入编码。

## 存档验证

每次存档操作后必须执行结构完整性验证（详见 protocol.md 存档协议）。CTG-04 交付预检中增加文档完整性复核。

## 运行状态门禁

流水线执行必须维护 `.ai-workflow/runs/RUN-*/state.json` 和 `events.jsonl`：

- 进入任一阶段前，主会话或 runtime 编排者必须读取 `state.json` 判断当前 `phase`、`gate`、`status` 和 `next_action`
- 任何 Agent 完成、用户确认、门禁失败或返工，都必须追加写入 `events.jsonl`
- RCG、TDR、ARCH、CTG 等人工门控必须将 `status` 更新为 `WAITING_USER`
- 门禁失败、缺少产出物、权限不足或命令不可执行时，必须将 `status` 更新为 `BLOCKED`
- 测试、评审或安全审计要求返工时，必须将 `status` 更新为 `REWORK`，并记录目标 Agent 和归因

CTG-04 必须额外检查三方一致性：

1. `state.json` 指向的当前阶段和产出物存在
2. confirmed 标记与人工门控事件一致
3. artifacts 文件包含必需章节，且与当前 flow 阶段匹配

三方不一致时不得交付，必须进入 `BLOCKED` 并等待用户确认修复方式。

## CG / PLG / CTG

- CG：bajie 编码前必须完成上下文预检。
- PLG：wukong 对照 ARCH 契约审查实现，发现偏差必须修复。
- CTG：主会话或 OpenCode native 的 rulai 执行交付预检，阻断项未清零不得交付。

## Runtime 边界

runtime 可以选择并发、模型、agent、worker、hook 和工具链，但不能决定跳过上述门禁。
runtime 可以优化状态读写方式，但必须保留 `.ai-workflow/runs/` 的可读账本。
