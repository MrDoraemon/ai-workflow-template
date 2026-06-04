# ai-workflow-template vs Superpowers Plugin：深度对比分析

> 分析日期：2026-06-04
> 分析对象：
> - ai-workflow-template（本项目）— AI-Native SDLC 协议框架
> - superpowers plugin（Claude Code 官方插件）— 编码纪律方法论技能包

---

## 一、本质定位差异

| 维度 | ai-workflow-template | Superpowers |
|------|----------------------|-------------|
| **本质** | SDLC 全生命周期**协议框架** | 编码纪律**方法论技能包** |
| **隐喻** | 西游记角色分工（唐僧管需求、悟空管架构…） | 铁律驱动的工程纪律（TDD、根因调试…） |
| **抽象层级** | **项目级** — 管理从需求到部署的完整流水线 | **任务级** — 管理具体怎么写好一段代码 |
| **核心问题** | "谁在什么时候做什么事，过什么门控" | "怎么把这件事做对、做干净" |
| **粒度** | 粗 — 7个角色、8个阶段、6类门控 | 细 — 14个技能，每个技能有微观步骤 |

简单说：**ai-workflow 管流程骨架，Superpowers 管执行纪律**。一个回答 "what & when"，一个回答 "how"。

---

## 二、能力关系判断

**结论：高度互补，少量重叠，零冲突。**

```
ai-workflow 的覆盖范围（SDLC 层）:
  需求澄清 → 需求文档 → 技术决策 → 架构设计 → 实现 → 合规审查 → 测试 → 代码审查 → 部署
                                                          ↑                    ↑
Superpowers 的覆盖范围（编码层）:                          │                    │
  头脑风暴 → 写计划 → TDD编码 → 系统化调试 → 代码审查 → 完成验证              │
                                                          ↑                    ↑
                                              覆盖了"怎么做实现"      覆盖了"怎么做审查"
```

### 互补区域（最大价值区）

- ai-workflow 的 bajie（实现阶段）是空的框架 → Superpowers 的 TDD + subagent-driven 填充了"怎么写代码"
- ai-workflow 的 nezha（测试阶段）定义了"谁测" → Superpowers 的 systematic-debugging 定义了"怎么修"
- ai-workflow 的 CTG 门控说"通过才能发布" → Superpowers 的 verification-before-completion 定义了"什么叫通过"

### 重叠区域（可整合）

- 两者都有代码审查机制，但粒度不同：erlang 是 11 维度独立审查 vs Superpowers 的两阶段（规格合规 + 代码质量）
- 两者都有头脑风暴：tangseng 的 RCU vs Superpowers 的 brainstorming skill
- 两者都有计划编写：wukong 的 ARCH vs Superpowers 的 writing-plans

---

## 三、关键差异深度解析

### 1. 强制机制不同

| 机制 | ai-workflow | Superpowers |
|------|------------|-------------|
| **门控执行** | Hook 硬强制（`.confirmed` 标记文件检查） | "铁律"文本约束（NO X WITHOUT Y） |
| **绕过难度** | 技术层面无法绕过（bash hook 拦截） | 可被 AI 忽略（纯提示词约束） |
| **适用场景** | 流程级门控（没确认不能进下一阶段） | 行为级约束（不写测试不能写代码） |

**评价**：ai-workflow 的 Hook 机制更强硬可靠，Superpowers 的铁律更灵活但依赖 AI 自律。

### 2. TDD 态度差异显著

- **Superpowers**：TDD 是核心铁律，强制 RED→GREEN→REFACTOR，"先写了代码？删掉重来"
- **ai-workflow**：没有强制 TDD，bajie 只要求"自检 CDG"，测试由 nezha 独立负责

这是一个重要的哲学分歧。ai-workflow 将测试责任分给了 nezha（独立测试角色），而 Superpowers 要求写代码的人自己先写测试。

### 3. 角色分工 vs 技能触发

```
ai-workflow: 你是 bajie → 你只能做实现 → 悟空会来审查你
Superpowers: 你遇到 bug → 触发 systematic-debugging → 你自己调试到底
```

ai-workflow 通过**角色隔离**实现制衡（实现者 ≠ 审查者 ≠ 测试者），Superpowers 通过**技能切换**实现纪律（同一个 agent 在不同阶段调用不同技能）。

### 4. 产物管理

- **ai-workflow**：完整的产物体系（RCU、REQ、TDR、ARCH、REV、SEC…），带编号、索引、追溯
- **Superpowers**：产物较轻（spec 文档 + plan 文档），重点在过程而非文档

---

## 四、实际使用建议

**推荐方案：融合使用，ai-workflow 管流程，Superpowers 管执行。**

### 融合架构

```
┌──────────────── ai-workflow 流程骨架 ────────────────┐
│                                                        │
│  Phase 1A: RCG (tangseng)                             │
│  Phase 1B: REQ (tangseng)                             │
│  Phase 2:  TDR + ARCH (wukong)                        │
│  ┌────────── Phase 3: 实现 (bajie) ──────────┐       │
│  │  ← Superpowers brainstorming              │       │
│  │  ← Superpowers writing-plans              │       │
│  │  ← Superpowers TDD (RED→GREEN→REFACTOR)   │       │
│  │  ← Superpowers subagent-driven-dev        │       │
│  └───────────────────────────────────────────┘       │
│  Phase 4:  PLG 合规审查 (wukong)                      │
│  ┌────────── Phase 5: 测试 (nezha) ──────────┐       │
│  │  ← Superpowers systematic-debugging       │       │
│  │  ← Superpowers verification-before-comp   │       │
│  └───────────────────────────────────────────┘       │
│  ┌────────── Phase 6: 审查 (erlang) ─────────┐       │
│  │  ← Superpowers requesting-code-review     │       │
│  │  ← Superpowers receiving-code-review      │       │
│  └───────────────────────────────────────────┘       │
│  Phase 7:  部署 (bailongma)                           │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### 融合映射表

| ai-workflow 阶段 | 融入的 Superpowers 技能 | 效果 |
|------------------|------------------------|------|
| bajie 实现阶段 | TDD + subagent-driven | 实现不再是空的"写代码"，有纪律的 RED→GREEN |
| nezha 测试阶段 | systematic-debugging | 失败的测试有系统化的根因追踪 |
| erlang 审查阶段 | requesting/receiving-code-review | 审查有标准化的两阶段流程 |
| 所有阶段 | verification-before-completion | 每次宣称"完成"前必须跑验证 |
| 流程开始前 | brainstorming | 增强需求澄清的深度 |

### 需要解决的冲突

Superpowers 的 TDD 铁律与 ai-workflow 的角色分工有一个张力：
- Superpowers 说：写代码的人必须先写测试
- ai-workflow 说：bajie 写代码，nezha 写测试

**建议处理**：让 bajie 在实现时遵循 TDD（写代码前写单元测试），nezha 负责独立的集成测试和覆盖率分析。这样既满足 TDD 纪律，又保持了角色制衡。

---

## 五、选型决策矩阵

| 如果你需要… | 选择 |
|-------------|------|
| 完整的 SDLC 流程治理 | ai-workflow |
| 编码纪律和 TDD | Superpowers |
| 多角色协作和制衡 | ai-workflow |
| 子代理并行开发 | Superpowers |
| 跨工具兼容（Codex/OpenCode） | ai-workflow |
| 快速迭代、轻量约束 | Superpowers |
| 团队级规范化开发 | 两者融合 |

---

## 六、总结

两者**不是竞争关系**，而是**正交互补**。用一个比喻：

- **ai-workflow 是建筑图纸和施工规范** — 规定了从地基到封顶的完整流程、谁负责什么、每道工序必须通过什么检验
- **Superpowers 是工匠的技艺手册** — 规定了砌砖的手法、焊接的温度、打磨的顺序

最好的建筑，既需要图纸，也需要工匠技艺。**融合使用是最佳方案。**
