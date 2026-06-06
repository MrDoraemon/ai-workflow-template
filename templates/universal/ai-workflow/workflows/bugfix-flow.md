# Bug Fix Workflow / Bug 修复流水线

## 触发条件
用户报告 bug、测试发现失败、或运行时错误。

**判定标准**：任何恢复正确行为的请求。包括但不限于：
- 运行时报错、异常日志
- 测试失败（CI 或本地）
- 功能回归（之前正常现在不正常）
- 性能劣化（之前快现在慢）
- 安全漏洞修复

**不属于本流程**：添加新功能来弥补缺失（走 feature-flow）；纯代码风格调整（直接操作）。

## 编排流程

### 运行状态初始化
1. 主会话或 OpenCode native 的 rulai 创建 `.ai-workflow/runs/RUN-{YYYYMMDD-HHMMSS}-bugfix-flow/`
2. 初始化 `state.json`：`flow=bugfix-flow`、`status=READY`、`phase=DIAGNOSIS`、`next_action=定位问题根因`
3. 追加 `events.jsonl`：记录用户原始错误描述、路由结果、mode 和 runtime
4. 后续每个阶段开始前必须读取 `state.json`，不得只凭上下文记忆推进

### Phase 1: 问题定位
1. 主会话或 OpenCode native 的 rulai 读取错误描述/日志
2. 使用项目搜索工具（如 Grep / Glob / rg）定位相关代码
3. 可选：调用 erlang 做初步诊断
4. 输出：问题定位报告（文件、行号、根因分析）
5. **存档**（遵循存档协议）：如生成诊断报告，将完整原文写入 `.ai-workflow/artifacts/reviews/REV-{YYYYMMDD}-{NNN}.md`，验证结构完整性，更新 `index.md`
6. 定位完成后追加 `agent_completed` 或 `diagnosis_completed` 事件，并将 `phase` 更新为 `FIX`、`status` 更新为 `READY`

### Phase 2: 修复实现
根据问题所在模块，调用对应 Agent：
- 代码问题 → bajie Agent
- 配置、部署或流水线问题 → bailongma Agent

Agent 输出：修复代码 + 对应测试

修复完成后追加 `agent_completed` 事件，并将 `phase` 更新为 `VERIFY`、`status` 更新为 `READY`。如果根因不清、权限不足或修复范围超出 bugfix 边界，必须进入 `BLOCKED` 并说明是否需要转入 feature-flow。

### Phase 3: 验证
1. 调用 nezha 运行相关测试
2. 调用 erlang 评审修复代码
3. **存档**（遵循存档协议）：将测试报告完整原文写入 `.ai-workflow/artifacts/tests/TEST-{YYYYMMDD}-{NNN}.md`，验证结构完整性，更新 `index.md`
4. 确认问题已解决且无副作用

验证失败时进入 `REWORK`，记录失败用例、目标 Agent 和返工轮次；验证通过后生成 `.ai-workflow/runs/RUN-*/summary.md` 和 `evolution.md`，更新 `metrics.json`，并将 `state.json` 更新为 `status=DONE`。

## Superpowers 插件增强（可选）

如果目标项目已安装 Superpowers 插件，bajie 在 Phase 2 修复实现时可使用 TDD 和 systematic-debugging 技能，nezha 在 Phase 3 验证时可使用 verification-before-completion 技能。这不需要主会话或 rulai 额外编排。

## 关键约束
- Bug 修复无人工门控点（修复范围通常较小）
- 修复必须包含对应的回归测试
- 遵循 CLAUDE.md 的最小化改动原则
- 每个阶段完成后必须更新 `.ai-workflow/runs/RUN-*/state.json` 并追加 `events.jsonl`
