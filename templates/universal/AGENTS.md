<!-- This file is a rendered reference. Actual install uses .ai-workflow/ directory for zero-intrusion. -->
# AGENTS.md - Multi-Agent 协作协议

# 项目概述

> 以下信息供 Agent 启动时读取项目上下文，请根据实际项目填写。

## 项目简介
<!-- 一段话描述项目目标和定位 -->

## 技术栈
<!-- 如：语言、框架、包管理、数据库等 -->

## 目录结构
<!-- 列出关键目录及其职责 -->

## 开发命令
<!-- 启动、构建、测试、lint 等命令 -->

本文件定义项目的多 Agent 协作工作流，被 Claude Code / Codex CLI / OpenCode 等工具识别。

## 可用角色

| 角色 | 职责 | 权限 |
|------|------|------|
| tangseng | 需求分析，输出 REQ 文档 | 只读 |
| wukong | 技术决策、架构契约、编码合规审查 | 只读 |
| bajie | 功能实现与 TDD 单元测试编写 | 读写任务范围内代码 |
| nezha | 单测执行验证、集成测试、回归验证、覆盖率分析 | 读写测试 |
| erlang | 代码评审 | 只读 |
| lijing | 安全审计 | 只读 |
| bailongma | CI/CD 和部署 | 读写配置 |

权限优先由具体工具配置落地：Claude Code / OpenCode 模板会限制 `erlang`、`lijing` 的写入和 Bash 权限；不支持工具级隔离的环境以本文件约束为准。

## 强制路由协议

**收到用户需求后，必须先分类意图并声明走哪条流水线，然后再开始执行。**

路由判定清单：

| 用户意图 | 命中流水线 | 判定依据 |
|----------|-----------|---------|
| 添加功能 / 新页面 / 新组件 / 新 API / 新模块 / 集成第三方工具或库 / 新增配置项 / 使用某个工具/库/plugin 实现某个能力 | **feature-flow** | 任何引入新能力或改变行为的请求 |
| 修复错误 / 测试失败 / 异常日志 / 回归问题 / 性能劣化 | **bugfix-flow** | 任何恢复正确行为的请求 |
| 发布 / 部署 / 上线 / 打 tag / 版本发布 | **release-flow** | 任何向环境交付的请求 |
| 代码评审 / 检查代码 | erlang | 纯分析，不改变代码 |

**必须触发 feature-flow 的典型场景**（容易漏判）：用 XX 库/plugin/SDK 实现 YY、加页面/组件/接口、接入外部服务、优化实现方式、重构架构模式、配置新功能。

**降级保护**：意图不明确时默认归类为 feature-flow；不能仅凭"快速修"等措辞降级；每次路由判定后声明 `[Flow: xxx]`。

## 流水线触发规则

- **新功能需求** → tangseng(+RCG 需求澄清) → wukong(+TDR 方案选择+设计自检 DG) → bajie(+上下文预检 CG + 单测编写，满足边界时可轻量并行) → wukong(+编码合规审查 PLG) → 交付预检(CTG) → nezha(+单测验证 + 测试补强) → erlang
- **Bug 修复** → 定位问题 → bajie → nezha → erlang
- **代码评审** → erlang（可选 + lijing）
- **部署** → nezha → lijing → bailongma

## 质量门控（四阶段）

| 阶段 | 名称 | 执行者 | 门禁强度 |
|------|------|--------|---------|
| 1 | 设计预检 (DG-01~09) | wukong 自检 | 强门禁：100% PASS 才能编码 |
| 2 | 编码前上下文预检 (CG-01~07) | bajie 自检 | 强门禁：100% PASS 才能编码 |
| 3 | 编码合规审查 (PLG-01~07) | wukong 独立审查 | 强门禁：发现即修复 |
| 4 | 交付预检 (CTG-01~05) | 主会话 / OpenCode native: rulai | 分级门控：阻断项必修 |

## 产出物存档规范

- `requirements/` — REQ 需求文档
- `architectures/` — ARCH 架构文档
- `reviews/` — REV 评审报告
- `tests/` — TEST 测试报告
- `security/` — SEC 安全审计报告

## 运行状态协议

流水线执行必须维护 `.ai-workflow/runs/` 运行态账本。每次任务创建一个 `RUN-{YYYYMMDD-HHMMSS}-{flow}/` 目录，至少包含：

- `state.json`：当前 flow、mode、runtime、phase、gate、status、next_action
- `events.jsonl`：路由、Agent 完成、用户确认、门禁阻断、返工、恢复等不可变事件
- `metrics.json`：阶段耗时、调度次数、返工轮次、阻断项、验证次数等复盘指标
- `summary.md`：本次任务最终交付摘要
- `evolution.md`：自我进化建议

每次调度 Agent 或执行门禁前，主会话或 runtime 编排者必须读取 `state.json`，不得只依赖上下文记忆。遇到 RCG、TDR、ARCH、CTG 等人工门控时，`status` 必须更新为 `WAITING_USER`；遇到测试失败、评审阻断或门禁失败时，必须进入 `REWORK` 或 `BLOCKED` 并记录归因。

`evolution.md` 只提出 local-tweak / template-candidate / runtime-adapter 建议，不自动修改模板、项目代码、权限或门禁。

## Runtime 编排者

- Claude Code / Codex CLI：由主会话承担流程编排、产物传递、门禁停顿和 CTG。
- OpenCode native：由 `rulai` primary agent 承担上述编排职责，业务角色仍作为 subagent 执行专业任务；仅在 ARCH 模块边界清晰且互不冲突时执行轻量并行。
- oh-my-claudecode / oh-my-opencode：由外部 runtime 的 Team / Autopilot / Ultrawork / Ralph / Sisyphus 等能力承担编排，本项目不重复生成 native 编排 agent。

## 协作原则

- 主会话或 runtime 编排者按需调度子 Agent
- Agent 之间不直接调用，数据通过主会话或 runtime 编排者传递
- 每个阶段完成后必须通知主会话或 runtime 编排者当前状态
- 每个阶段完成后必须更新 `.ai-workflow/runs/` 中的运行状态和事件日志
