# oh-my-opencode Mode Map

| Runtime 能力 | 在本协议中的定位 | 适合阶段 | 不适合阶段 |
|--------------|------------------|----------|------------|
| Oracle / planning agent | 只读分析与决策 | RCG、REQ、TDR、ARCH、Review | 写代码 |
| Sisyphus / conductor | 并发任务编排 | ARCH 后实现 | 需求澄清、技术决策前 |
| Worker agents | 具体实现 | Phase 3 编码实现 | RCG、TDR、PLG |
| Reviewer / security agent | 独立审查 | PLG、CTG、Review、Security | 修改代码 |

## 规则

- `.ai-workflow/protocol.md` 是上游协议。
- runtime 可以优化执行效率，但不能降低门禁强度。
- 并行只允许发生在需求和架构契约锁定之后。
