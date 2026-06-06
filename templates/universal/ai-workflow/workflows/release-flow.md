# Release Workflow / 发布流水线

## 触发条件
用户要求发布或部署。

**判定标准**：任何向运行环境交付产物的请求。包括但不限于：
- "发布版本" / "上线" / "部署到 XX"
- 打 tag / 版本号更新 / changelog 生成
- Docker 镜像构建并推送
- 发布到 npm / PyPI / Maven 等仓库

**不属于本流程**：本地构建调试（直接操作）；仅修改 CI 配置（走 feature-flow）。

## 编排流程

### 运行状态初始化
1. 主会话或 OpenCode native 的 rulai 创建 `.ai-workflow/runs/RUN-{YYYYMMDD-HHMMSS}-release-flow/`
2. 初始化 `state.json`：`flow=release-flow`、`status=READY`、`phase=PRECHECK`、`next_action=执行发布前预检`
3. 追加 `events.jsonl`：记录用户发布目标、路由结果、mode 和 runtime
4. 后续每个阶段开始前必须读取 `state.json`，不得只凭上下文记忆推进

### Phase 1: 预检
1. 调用 nezha 运行全量测试
2. 调用 lijing 做只读安全审计
3. 如需运行依赖审计或安全扫描命令，由主会话、OpenCode native 的 rulai 或具备执行权限的 Agent 在用户确认后执行
4. 确认无致命/严重问题（如有则中止，回到修复流程）
5. 预检通过后追加 `gate_passed` 事件，并将 `phase` 更新为 `BUILD`、`status` 更新为 `READY`；发现致命/严重问题时进入 `BLOCKED`

### Phase 2: 构建
1. 调用 bailongma
   - 项目生产构建或打包
   - 容器镜像构建（如有 Dockerfile）
   - 配置验证
2. 输出构建产物和构建状态
3. 构建完成后追加 `agent_completed` 事件，并将 `phase` 更新为 `DEPLOY_CONFIRM`、`status` 更新为 `WAITING_USER`

### Phase 3: 部署（需用户确认）
1. **人工门控点**：展示构建结果和部署计划，等待用户确认
2. bailongma 执行部署流程
3. 输出部署状态和验证结果
4. 部署完成后生成 `.ai-workflow/runs/RUN-*/summary.md` 和 `evolution.md`，更新 `metrics.json`，并将 `state.json` 更新为 `status=DONE`

## 关键约束
- Phase 1 的致命/严重问题必须修复后才能继续
- Phase 3 部署前必须获得用户确认
- 生产环境 Dockerfile 必须使用非 root 用户
- 禁止在镜像中包含 `.env` 文件
- 每个阶段完成后必须更新 `.ai-workflow/runs/RUN-*/state.json` 并追加 `events.jsonl`
