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

### Phase 1: 需求分析（顺序执行）
1. 主会话接收用户需求
2. 调用 analyst Agent，传入用户原始需求文本
3. 输出 REQ-{YYYYMMDD}-{NNN} 文档
4. **存档**：将 REQ 文档写入 `.claude/artifacts/requirements/REQ-{YYYYMMDD}-{NNN}.md`，更新 `index.md`
5. **人工门控点**：展示 REQ 文档，等待用户确认

### Phase 2: 架构设计（顺序执行，依赖 Phase 1）
1. 将用户确认的 REQ 文档传递给 architect Agent
2. 输出 ARCH-{YYYYMMDD}-{NNN} 文档（含模块任务划分）
3. **设计自检**：architect Agent 必须输出设计自检报告（DG-01~DG-09），100% PASS 才能继续
4. **存档**：将 ARCH 文档写入 `.claude/artifacts/architectures/ARCH-{YYYYMMDD}-{NNN}.md`，更新 `index.md`
5. **人工门控点**：展示 ARCH 文档，等待用户确认

### Phase 3: 编码实现（可按模块并行执行）
- 调用 developer Agent（通用实现 + 测试）
  - 输入：ARCH 文档中的模块任务，可按 M-xxx 模块拆分为多个独立 developer 任务
  - **上下文预检**（强门禁）：CG-01~06 预检报告，100% PASS 才能编码
  - 执行：编写代码 → 运行测试/构建/lint/类型检查 → 自检(CDG-01~06)
  - 输出：变更清单 + 代码 + 验证结果

### Phase 4: 编码合规预检（强门禁：发现即修复）

Phase 3 编码实现完成后，调用 architect Agent 执行编码合规审查（PLG-01~PLG-07）。

1. 将 ARCH 文档 + developer 输出的代码变更清单传递给 architect Agent
2. architect Agent 读取 ARCH 契约，对照实际代码，执行 7 项检查
3. 输出合规报告：差异清单 + 缺失约束 + 风险点 + 合规率
4. 如有任何偏差 → 调用 developer 修复 → 重做 Phase 4
5. 全部通过后进入交付预检

### Phase 5: 交付预检 + 质量保障（分级门控）

**交付预检**（主会话执行）：
1. CTG-01 项目可运行性：项目约定的启动、构建或关键脚本可执行，无 import/编译/加载错误
2. CTG-02 测试可执行性：项目声明的测试命令可运行，无环境、fixture 或依赖声明缺失
3. CTG-03 配置完整性：新增配置项有默认值、示例或文档说明
4. CTG-04 存档一致性：ARCH 文档、REQ 文档、实际代码三方一致
5. CTG-05 依赖声明验证：项目依赖文件中的新增依赖与 ARCH 声明一致
6. 输出交付合规报告：阻断项必须修复，非阻断项输出风险清单
7. **人工终审**：用户查看差异清单和风险清单后，决定是否进入测试环节

**质量保障**：
1. 调用 qa（补充测试 + 全面回归）
2. 调用 reviewer（代码评审）
3. **存档**：将测试报告写入 `.claude/artifacts/tests/TEST-{YYYYMMDD}-{NNN}.md`，将评审报告写入 `.claude/artifacts/reviews/REV-{YYYYMMDD}-{NNN}.md`，更新 `index.md`
4. 如有安全敏感变更，调用 security
5. 汇总所有 Agent 输出

### Phase 6: 修正与合并（条件执行）
- 如评审发现问题 → 调用 developer 修正
- 修正后必须重做 Phase 4（编码合规预检）+ Phase 5（交付预检+质量保障）
- 所有评审通过 → 通知用户可合并

## 关键约束
- 主会话不得修改 Agent 的输出内容，只做传递和展示
- 禁止 Agent 自行调用其他 Agent
- 每个阶段完成后必须通知用户当前状态
