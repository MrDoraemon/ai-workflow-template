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

### Phase 1: 问题定位
1. 主会话读取错误描述/日志
2. 使用项目搜索工具（如 Grep / Glob / rg）定位相关代码
3. 可选：调用 reviewer 做初步诊断
4. 输出：问题定位报告（文件、行号、根因分析）
5. **存档**：如生成诊断报告，写入 `.claude/artifacts/reviews/REV-{YYYYMMDD}-{NNN}.md`，更新 `index.md`

### Phase 2: 修复实现
根据问题所在模块，调用对应 Agent：
- 代码问题 → developer Agent
- 配置、部署或流水线问题 → devops Agent

Agent 输出：修复代码 + 对应测试

### Phase 3: 验证
1. 调用 qa 运行相关测试
2. 调用 reviewer 评审修复代码
3. **存档**：将测试报告写入 `.claude/artifacts/tests/TEST-{YYYYMMDD}-{NNN}.md`，更新 `index.md`
4. 确认问题已解决且无副作用

## 关键约束
- Bug 修复无人工门控点（修复范围通常较小）
- 修复必须包含对应的回归测试
- 遵循 CLAUDE.md 的最小化改动原则
