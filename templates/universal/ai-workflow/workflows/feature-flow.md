# Feature Development Workflow / 新功能开发流水线

## 触发条件
用户提出新功能需求（自然语言描述）。

**判定标准**：任何引入新能力、改变行为、新增产物或集成外部依赖的请求，均视为新功能需求。包括但不限于：
- 添加新页面、组件、API 接口、模块
- 集成第三方库、SDK、plugin、外部服务
- 新增配置项或功能开关
- 优化或重构现有实现方式（改变行为）
- "用 XX 实现 YY" 类请求 — 即使只涉及一个工具，本质仍是新功能

**不属于本流程**：纯问答、查看代码、改 typo/注释/格式（走直接操作）。

## 编排流程

### 运行状态初始化
1. 主会话或 OpenCode native 的 rulai 创建 `.ai-workflow/runs/RUN-{YYYYMMDD-HHMMSS}-feature-flow/`
2. 初始化 `state.json`：`flow=feature-flow`、`status=READY`、`phase=RCG`、`next_action=调度 tangseng 输出 RCU`
3. 追加 `events.jsonl`：记录用户原始需求、路由结果、mode 和 runtime
4. 后续每个阶段开始前必须读取 `state.json`，不得只凭上下文记忆推进

### Phase 1A: 需求理解确认 RCG（顺序执行）
1. 主会话或 OpenCode native 的 rulai 接收用户需求
2. 调用 tangseng Agent，传入用户原始需求文本
3. tangseng 只输出 RCU-{YYYYMMDD}-{NNN}（需求理解确认单），不得输出 REQ
   - **tangseng 输出 RCU 后必须立即停止，不得继续输出 REQ 文档**
   - 编排者追加 `agent_completed` 事件，并将 `status` 更新为 `WAITING_USER`
4. **需求澄清门控点**：展示 RCU，等待用户确认
   - 用户可选：A. 理解正确 / B. 基本正确需调整 / C. 理解有误重新澄清
5. 用户确认后，创建 `.ai-workflow/artifacts/requirements/RCU-{YYYYMMDD}-{NNN}.confirmed` 标记文件，追加 `user_confirmed` 事件，并将 `phase` 更新为 `REQ`、`status` 更新为 `READY`

### Phase 1B: 需求文档 REQ（顺序执行，依赖 Phase 1A）
1. 将用户原始需求 + 已确认 RCU 传递给 tangseng Agent
2. tangseng 输出 REQ-{YYYYMMDD}-{NNN} 文档
3. **存档**（遵循存档协议）：
   - 将 RCU 和 REQ 的完整原文写入 `.ai-workflow/artifacts/requirements/`
   - 验证文件包含所有必需章节（RCU: §1-§7, REQ: §1-§9）
   - 更新 `index.md`
4. **人工门控点**：展示 REQ 文档，等待用户确认；等待期间 `status=WAITING_USER`
5. 用户确认后追加 `user_confirmed` 事件，并将 `phase` 更新为 `TDR`、`status` 更新为 `READY`

### Phase 2: 架构设计（顺序执行，依赖 Phase 1）
1. 将用户确认的 REQ 文档传递给 wukong Agent
2. wukong 输出 TDR-{YYYYMMDD}-{NNN} 文档（技术决策评审）
   - 识别关键技术决策点，每个提供多选项（含优势/劣势）和推荐
   - 如无需要用户参与的决策点，在"无需用户决策的技术选型"章节说明
3. **方案选择门控点**：展示 TDR 文档，等待用户逐项选择
   - **wukong 输出 TDR 后必须立即停止，不得继续输出 ARCH 文档**
   - 用户可接受推荐或选择其他选项，可补充额外约束
   - 等待期间 `status=WAITING_USER`
   - 用户确认后，主会话或 rulai 创建 `.ai-workflow/artifacts/architectures/TDR-{YYYYMMDD}-{NNN}.confirmed` 标记文件，追加 `user_confirmed` 事件
4. 将用户选择结果 + REQ 文档传递给 wukong Agent
   - wukong 根据用户选择生成 ARCH-{YYYYMMDD}-{NNN} 文档（含模块任务划分）
5. **设计自检**：wukong Agent 必须输出设计自检报告（DG-01~DG-09），100% PASS 才能继续
6. **存档**（遵循存档协议）：
   - 将 TDR 和 ARCH 的完整原文写入 `.ai-workflow/artifacts/architectures/`
   - 验证文件包含所有必需章节（TDR: §1-§4, ARCH: §1-§10 + DG 自检）
   - 更新 `index.md`
7. **人工门控点**：展示 ARCH 文档，等待用户确认；等待期间 `status=WAITING_USER`
8. 用户确认后追加 `user_confirmed` 事件，并将 `phase` 更新为 `IMPLEMENTATION`、`status` 更新为 `READY`

### Phase 3: 编码实现（可按模块轻量并行）
- 调用 bajie Agent（通用实现 + TDD 单元测试编写）
  - 输入：ARCH 文档中的模块任务，可按 M-xxx 模块拆分为多个独立 bajie 任务
  - **上下文预检**（强门禁）：CG-01~07 预检报告，100% PASS 才能编码
  - 执行：编写代码 → 编写/更新单元测试 → 自检(CDG-01~06)
  - 输出：变更清单 + 代码 + 单元测试 + 交由 nezha 执行的单测验证命令

#### OpenCode native 轻量并行规则
OpenCode native 由 rulai 作为 primary agent 编排。rulai 只有在同时满足以下条件时，才允许并行分派多个 bajie 子任务：
1. ARCH 中存在明确的 M-xxx 模块任务拆分
2. 每个模块的输入、输出、文件范围和验收标准清晰
3. 不同模块的修改文件不重叠
4. 公共接口、共享类型、数据模型和配置契约已经冻结；如未冻结，必须先串行完成公共契约
5. 不涉及数据库迁移、认证授权、安全策略、生产配置或全局依赖升级
6. 每个子任务都有可独立编写的单元测试和建议验证命令

不满足任一条件时，rulai 必须降级为串行调度。

#### OpenCode native 并行合并门禁
所有 bajie 子任务完成后，rulai 必须在进入 PLG 前执行合并门禁：
1. 收齐每个子任务的变更清单、单元测试、CDG 和建议验证命令
2. 检查文件修改是否冲突、重复或遗漏
3. 检查子任务之间的接口调用、导出注册、配置项和测试命令是否一致
4. 合并为一份全局变更清单，并标注每个变更来自哪个 M-xxx 模块
5. 如发现冲突或跨模块契约不一致，调度相关 bajie 子任务修复；修复后重新执行合并门禁
6. 合并门禁通过后，才允许进入 wukong 全局 PLG

Phase 3 完成后，编排者必须追加 `agent_completed` / `merge_gate_passed` 事件，并将 `phase` 更新为 `PLG`、`status` 更新为 `READY`。如 CG、CDG 或合并门禁失败，进入 `BLOCKED` 或 `REWORK`，并记录目标 bajie 子任务。

### Phase 4: 编码合规审查（强门禁：发现即修复）

Phase 3 编码实现完成后，调用 wukong Agent 执行编码合规审查（PLG-01~PLG-07）。

1. 将 ARCH 文档 + bajie 输出的代码变更清单传递给 wukong Agent；OpenCode native 如使用并行，必须传递 rulai 合并后的全局变更清单
2. wukong Agent 读取 ARCH 契约，对照实际代码，执行 7 项检查
3. 输出合规报告：差异清单 + 缺失约束 + 风险点 + 合规率
4. 如有任何偏差 → 调用 bajie 修复 → 重做 Phase 4
5. 全部通过后进入交付预检

PLG 通过后，编排者追加 `gate_passed` 事件，并将 `phase` 更新为 `CTG`、`status` 更新为 `READY`。PLG 发现偏差时进入 `REWORK`，记录偏差、目标模块和返工轮次。

### Phase 5: 交付预检 + 测试验证（分级门控）

#### 5a. 交付预检（主会话 / OpenCode native rulai 执行）
1. CTG-01 项目可运行性：项目约定的启动、构建或关键脚本可执行，无 import/编译/加载错误
2. CTG-02 测试可执行性：项目声明的测试命令可运行，无环境、fixture 或依赖声明缺失
3. CTG-03 配置完整性：新增配置项有默认值、示例或文档说明
4. CTG-04 存档一致性与完整性：
   - 文档完整性：验证 ARCH 文档包含全部 10 个必需章节 + DG 自检，REQ 文档包含全部 9 个必需章节
   - 三方一致性：ARCH 文档、REQ 文档、实际代码之间无矛盾或遗漏
5. CTG-05 依赖声明验证：项目依赖文件中的新增依赖与 ARCH 声明一致
6. 输出交付合规报告：阻断项必须修复，非阻断项输出风险清单
7. CTG-04 同时检查 `state.json`、confirmed 标记和 artifacts 的一致性
8. **人工终审**：用户查看差异清单和风险清单后，决定是否进入测试环节；等待期间 `status=WAITING_USER`
9. 用户确认进入测试后，追加 `user_confirmed` 事件，并将 `phase` 更新为 `TEST`、`status` 更新为 `READY`

#### 5b. 测试验证（首次全量）
1. 调用 nezha（执行单元测试 + 补充集成/回归测试 + 覆盖率/盲区分析）
2. **存档**（遵循存档协议）：将测试报告完整原文写入 `.ai-workflow/artifacts/tests/TEST-{YYYYMMDD}-{NNN}.md`，验证结构完整性，更新 `index.md`

#### 5c. nezha 重做循环（条件执行）
如 nezha 发现测试失败或单测缺口：
1. nezha 先归因：代码实现问题、单测实现问题、测试策略/覆盖盲区
2. **代码实现问题或 bajie 单测实现问题** → 主会话或 rulai 记录失败用例 → 调用 bajie 修复
3. **测试策略/覆盖盲区问题** → nezha 自行补充测试后重跑
4. bajie 如有修复，返回新变更清单和修复说明
5. 主会话或 rulai 对比修复前后变更清单，计算增量范围
6. 判定是否满足升级条件（见下方升级触发器）
7. **未触发升级** → nezha 增量测试（单元测试 + 受影响测试 + 修复验证用例）
8. **触发升级** → nezha 全量测试
9. nezha 输出测试报告
10. 如仍有失败或阻断缺口 → 回到步骤 1
11. nezha 全部通过 → 存档测试报告 → 进入 Phase 6

**升级触发器**（满足任一即全量重测）：
- 返工轮次超过 3 次
- 修复涉及公共接口或数据模型变更
- 增量测试发现原始失败列表外的新失败

测试失败或单测缺口必须进入 `REWORK`，记录失败类型、目标 Agent、返工轮次和是否升级全量测试。nezha 全部通过后，编排者将 `phase` 更新为 `REVIEW`、`status` 更新为 `READY`。

### Phase 6: 代码评审 + 修正循环（条件执行）

#### 6a. 首次评审（全量）
1. 调用 erlang（全量评审：所有变更文件 × 11 维度）
2. 如有安全敏感变更，调用 lijing
3. **存档**（遵循存档协议）：将评审报告完整原文写入 `.ai-workflow/artifacts/reviews/REV-{YYYYMMDD}-{NNN}.md`，验证结构完整性，更新 `index.md`

#### 6b. erlang 重做循环（条件执行）
如 erlang 发现致命/严重问题：
1. 主会话或 rulai 记录问题清单 → 调用 bajie 修复
2. bajie 返回新变更清单和修复说明
3. 主会话或 rulai 判定修复性质：
   - **非行为变更**（命名、注释、格式、输入校验、权限检查）→ Phase 6 内部循环
   - **行为变更**（逻辑、接口签名、数据结构、状态转换、错误传播）→ **回退 Phase 5b**
4. Phase 6 内部循环：
   - 主会话或 rulai 对比修复前后变更清单，计算增量范围
   - 判定是否满足升级条件（见下方升级触发器）
   - **未触发升级** → erlang 增量评审（增量文件 × 全维度 + 原始问题验证）
   - **触发升级** → erlang 全量评审
5. erlang 输出评审报告
6. 如仍有致命/严重问题 → 回到步骤 1
7. erlang 评审通过 → 存档评审报告 → 进入 Phase 7

**升级触发器**（满足任一即全量重审）：
- 返工轮次超过 3 次
- 修复涉及公共接口或数据模型变更
- 增量评审发现新的致命/严重问题

评审发现致命/严重问题必须进入 `REWORK`，记录问题等级、目标 Agent、是否行为变更和回退阶段。评审通过后，编排者将 `phase` 更新为 `DONE`、`status` 更新为 `READY`。

#### 6c. Phase 6 → Phase 5 回退
当 bajie 的修复涉及行为变更时：
1. 主会话或 rulai 将行为变更清单传给 nezha
2. nezha 执行增量测试（验证变更不影响现有测试）
3. nezha 通过 → 继续 Phase 6 的 erlang 评审
4. nezha 失败 → 进入 Phase 5c 的 nezha 重做循环

### Phase 7: 合并就绪
1. 汇总所有 Agent 输出
2. 生成 `.ai-workflow/runs/RUN-*/summary.md`
3. 生成 `.ai-workflow/runs/RUN-*/evolution.md`，仅提出 local-tweak / template-candidate / runtime-adapter 建议，不自动修改模板
4. 更新 `metrics.json`
5. 将 `state.json` 更新为 `status=DONE`
6. 通知用户可合并

## Superpowers 插件增强（可选）

如果目标项目已安装 Superpowers 插件，各 Agent 在执行时可自动调用对应编码纪律技能。这不需要主会话或 rulai 额外编排，Agent 定义中已包含触发指引。编排者无需修改调度逻辑。

| Agent | 可能触发的技能 | 触发时机 |
|-------|---------------|---------|
| bajie | TDD / writing-plans / subagent-driven / verification | Phase 3 编码实现 |
| nezha | systematic-debugging / verification | Phase 5 测试执行与单测审查 |
| erlang | requesting/receiving-code-review | Phase 6 代码评审 |
| wukong | brainstorming | Phase 2 TDR |

## 关键约束
- 主会话或 rulai 不得修改 Agent 的输出内容，只做传递、展示、存档和门禁判断
- 禁止 Agent 自行调用其他 Agent
- 每个阶段完成后必须通知用户当前状态
- 每个阶段完成后必须更新 `.ai-workflow/runs/RUN-*/state.json` 并追加 `events.jsonl`
