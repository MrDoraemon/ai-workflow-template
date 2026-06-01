# oh-my-claudecode Mode Map

| 模式 | 在本协议中的定位 | 适合阶段 | 不适合阶段 |
|------|------------------|----------|------------|
| Autopilot | 顺序执行器 | RCG、REQ、TDR、ARCH、小型实现 | 大规模并行实现 |
| Team | 多 agent 协作器 | ARCH 后多模块实现、交叉评审 | RCG、未确认 TDR 前 |
| Ultrawork | 高并发执行器 | ARCH 后大功能/多文件实现 | 需求不清、架构未确认 |
| Ralph | 强验证收敛器 | bugfix、CTG、最终验证 | 需求探索和技术路线选择 |

## 规则

- Flow 决定任务类型。
- Mode 决定流程强度。
- Runtime mode 决定执行方式。
- runtime mode 不得覆盖 Flow / Mode / Gate。
