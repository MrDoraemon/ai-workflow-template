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
PLG 编码合规预检
  ↓
CTG 交付预检
  ↓
QA / Review / Security
```

## RCG

- feature-flow 中 analyst 必须首先输出 RCU。
- 用户确认 RCU 前，不得生成 REQ。
- lite 模式可以输出精简 RCU，但不可由 AI 自行跳过。

确认标记：

```text
.ai-workflow/artifacts/requirements/RCU-{YYYYMMDD}-{NNN}.confirmed
```

## TDR

- 架构设计 Phase 2 中 architect 必须首先输出 TDR。
- 用户确认 TDR 前，不得生成 ARCH。
- lite 模式可快速接受推荐，但不可由 AI 自行跳过。

确认标记：

```text
.ai-workflow/artifacts/architectures/TDR-{YYYYMMDD}-{NNN}.confirmed
```

## ARCH

- ARCH 必须基于已确认的 REQ 和 TDR 决策生成。
- ARCH 必须包含 DG 自检，且 100% PASS 后才能进入编码。

## CG / PLG / CTG

- CG：developer 编码前必须完成上下文预检。
- PLG：architect 对照 ARCH 契约检查实现，发现偏差必须修复。
- CTG：主会话执行交付预检，阻断项未清零不得交付。

## Runtime 边界

runtime 可以选择并发、模型、agent、worker、hook 和工具链，但不能决定跳过上述门禁。
