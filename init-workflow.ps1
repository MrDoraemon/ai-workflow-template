param(
  [string]$Tool = "",
  [string]$Mode = "",
  [string[]]$Agents = @(),
  [string[]]$Workflows = @(),
  [switch]$NonInteractive,
  [switch]$DryRun,
  [switch]$Help
)

$ErrorActionPreference = "Stop"

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetDir = (Get-Location).Path
$TemplateRepoUrl = if ($env:AI_WORKFLOW_TEMPLATE_REPO) { $env:AI_WORKFLOW_TEMPLATE_REPO } else { "https://github.com/MrDoraemon/ai-workflow-template" }
$TemplateRef = if ($env:AI_WORKFLOW_TEMPLATE_REF) { $env:AI_WORKFLOW_TEMPLATE_REF } else { "main" }
$TemplateArchiveUrl = if ($env:AI_WORKFLOW_TEMPLATE_ARCHIVE_URL) { $env:AI_WORKFLOW_TEMPLATE_ARCHIVE_URL } else { "$TemplateRepoUrl/archive/refs/heads/$TemplateRef.zip" }
$TempTemplateDir = ""

$AgentNames = @("analyst", "architect", "developer", "qa", "reviewer", "security", "devops")
$AgentDescs = @("需求分析", "架构设计", "功能开发", "质量保证", "代码评审", "安全审计", "运维部署")
$AgentCmdFiles = @("需求分析.md", "架构设计.md", "开发.md", "测试.md", "评审专家.md", "安全审计.md", "")

$WorkflowNames = @("feature-flow", "bugfix-flow", "release-flow")
$WorkflowDescs = @("新功能开发（含 4 阶段质量门控）", "Bug 修复", "发布部署")

$ModeNames = @("lite", "standard", "strict")
$ModeDescs = @("轻量模式：适合小改动、个人项目、快速原型", "标准模式：默认推荐，适合常规功能开发", "严格模式：适合生产级、多人协作、安全敏感项目")

$SelectedAgents = @()
$SelectedWorkflows = @()
$AgentsMdCreated = $false

function Write-Info($Message) { Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Ok($Message) { Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn($Message) { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Stop-Init($Message) {
  Write-Host "[ERROR] $Message" -ForegroundColor Red
  exit 1
}

function Show-Help {
  Write-Host "用法: .\init-workflow.ps1 [-Tool claude-code|codex|opencode|all] [-Mode lite|standard|strict] [-Agents a,b,c] [-Workflows a,b] [-NonInteractive] [-DryRun]"
}

function Test-InList($Value, $Items) {
  return $Items -contains $Value
}

function Get-ModeDesc {
  switch ($script:Mode) {
    "lite" { return "轻量模式：适合小改动、个人项目、快速原型" }
    "standard" { return "标准模式：默认推荐，适合常规功能开发" }
    "strict" { return "严格模式：适合生产级、安全敏感项目" }
  }
}

function Invoke-SafeCopy($Source, $Destination) {
  if ($DryRun) {
    Write-Host "[DRY] copy $Source -> $Destination" -ForegroundColor Yellow
  } else {
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
  }
}

function Invoke-SafeMkdir($Path) {
  if ($DryRun) {
    Write-Host "[DRY] mkdir -p $Path" -ForegroundColor Yellow
  } else {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Invoke-SafeAppend($Source, $Destination) {
  if ($DryRun) {
    Write-Host "[DRY] append $Source -> $Destination" -ForegroundColor Yellow
  } else {
    Get-Content -LiteralPath $Source | Add-Content -LiteralPath $Destination -Encoding UTF8
  }
}

function Ensure-Templates {
  if ((Test-Path (Join-Path $ScriptRoot "templates/universal/AGENTS.md")) -and
      (Test-Path (Join-Path $ScriptRoot "templates/universal/ai-workflow"))) {
    return
  }

  Write-Info "未在脚本目录发现 templates/，尝试下载模板包..."

  $script:TempTemplateDir = Join-Path ([IO.Path]::GetTempPath()) "ai-workflow-template-$PID"
  $archive = Join-Path $script:TempTemplateDir "template.zip"

  New-Item -ItemType Directory -Force -Path $script:TempTemplateDir | Out-Null

  Write-Info "下载: $TemplateArchiveUrl"
  try {
    Invoke-WebRequest -Uri $TemplateArchiveUrl -OutFile $archive -UseBasicParsing
    Expand-Archive -LiteralPath $archive -DestinationPath $script:TempTemplateDir -Force
  } catch {
    Stop-Init "模板包下载或解压失败。可设置 AI_WORKFLOW_TEMPLATE_REPO / AI_WORKFLOW_TEMPLATE_REF / AI_WORKFLOW_TEMPLATE_ARCHIVE_URL 后重试。$($_.Exception.Message)"
  }

  $templatesDir = Get-ChildItem -LiteralPath $script:TempTemplateDir -Directory -Recurse |
    Where-Object { $_.Name -eq "templates" -and (Test-Path (Join-Path $_.FullName "universal/AGENTS.md")) -and (Test-Path (Join-Path $_.FullName "universal/ai-workflow")) } |
    Select-Object -First 1

  if (-not $templatesDir) {
    Stop-Init "模板包中未找到 templates/universal/ai-workflow"
  }

  $script:ScriptRoot = Split-Path -Parent $templatesDir.FullName
  Write-Ok "模板包已就绪: $script:ScriptRoot"
}

function Append-ModeProtocol($Target, $Label) {
  $marker = "AI-WORKFLOW-MODE"

  if ($DryRun) {
    Write-Host "[DRY] append workflow mode $Mode -> $Target" -ForegroundColor Yellow
    return
  }

  if (-not (Test-Path $Target)) {
    Write-Warn "$Label 不存在，跳过流程强度模式写入"
    return
  }

  if (Select-String -LiteralPath $Target -Pattern $marker -Quiet) {
    Write-Ok "$Label 已包含流程强度模式，跳过"
    return
  }

  $lines = @(
    "",
    "<!-- AI-WORKFLOW-MODE:start -->",
    "## 流程强度模式",
    "",
    "当前项目默认模式：``$Mode``（$(Get-ModeDesc)）。",
    "",
    "用户在单次任务中可以临时覆盖默认模式，例如“本次用 lite 模式修复”或“这个功能走 strict 模式”。",
    "",
    "### 模式定义",
    "",
    "| 模式 | 适用场景 | 默认流程 |",
    "|------|----------|----------|",
    "| lite | 小改动、快速原型、低风险修复 | developer 实现 → 自测/构建 → 可选 reviewer |",
    "| standard | 常规功能开发 | analyst → architect → developer → PLG → CTG → qa → reviewer |",
    "| strict | 生产级、安全敏感、多人协作 | standard + 强制 security + 更严格人工门控 + 发布检查 |",
    "",
    "### 当前模式执行规则",
    ""
  )

  switch ($Mode) {
    "lite" {
      $lines += "- 默认跳过独立 REQ/ARCH 产物，除非需求不清、影响范围跨模块或用户明确要求。"
      $lines += "- developer 必须完成必要上下文确认、实现、自测和验证命令。"
      $lines += "- reviewer、qa、security 按风险触发，不强制每次调用。"
      $lines += "- CTG 只检查本次变更相关的运行、构建、测试、依赖和配置项。"
      $lines += "- TDR（技术决策评审）仍需执行，但用户确认时可快速通过。"
    }
    "standard" {
      $lines += "- 默认执行完整常规流水线：analyst → architect → developer → PLG → CTG → qa → reviewer。"
      $lines += "- DG、CG、PLG、CTG 按模板定义执行；阻断项必须修复。"
      $lines += "- security 在安全敏感、认证授权、依赖、配置、数据处理相关变更时触发。"
      $lines += "- architect 必须在 ARCH 文档前输出 TDR（技术决策评审），用户确认选择后再进入详细设计。"
    }
    "strict" {
      $lines += "- analyst、architect、developer、qa、reviewer 必须参与；security 默认强制参与。"
      $lines += "- REQ、ARCH、测试报告、评审报告和安全报告必须存档并更新索引。"
      $lines += "- DG、CG、PLG、CTG 必须 100% 执行；任何阻断项不得带病推进。"
      $lines += "- 需求确认、架构确认、交付终审和发布/部署前确认均作为人工门控点。"
      $lines += "- TDR（技术决策评审）为强制步骤且必须存档；用户必须明确确认每个决策项。"
    }
  }

  $lines += "<!-- AI-WORKFLOW-MODE:end -->"
  $lines | Add-Content -LiteralPath $Target -Encoding UTF8
  Write-Ok "$Label 已写入流程强度模式: $Mode"
}

function Normalize-SelectedAgents {
  $normalized = @()
  foreach ($agent in $script:SelectedAgents) {
    $mapped = $agent.Trim()
    if (-not $mapped) { continue }
    if (-not (Test-InList $mapped $AgentNames)) {
      Write-Warn "未知 Agent: $agent，已跳过"
      continue
    }
    if ($normalized -notcontains $mapped) {
      $normalized += $mapped
    }
  }
  $script:SelectedAgents = $normalized
}

function Normalize-SelectedWorkflows {
  $normalized = @()
  foreach ($workflow in $script:SelectedWorkflows) {
    $mapped = $workflow.Trim()
    if (-not $mapped) { continue }
    if (-not (Test-InList $mapped $WorkflowNames)) {
      Write-Warn "未知工作流: $workflow，已跳过"
      continue
    }
    if ($normalized -notcontains $mapped) {
      $normalized += $mapped
    }
  }
  $script:SelectedWorkflows = $normalized
}

function Select-ToolInteractive {
  Write-Host ""
  Write-Host "Step 1/5: 选择 AI 编码工具" -ForegroundColor Cyan
  Write-Host "  1) Claude Code（完整多 Agent 编排 + 子 Agent 权限控制）"
  Write-Host "  2) Codex CLI（AGENTS.md 角色段落模式）"
  Write-Host "  3) OpenCode（.opencode/agents/ 子 Agent 模式）"
  Write-Host "  4) 全部生成（Claude Code + Codex + OpenCode + 通用 AGENTS.md）"
  $choice = Read-Host ">"
  switch ($choice) {
    "1" { $script:Tool = "claude-code" }
    "2" { $script:Tool = "codex" }
    "3" { $script:Tool = "opencode" }
    "4" { $script:Tool = "all" }
    default { $script:Tool = "claude-code"; Write-Info "默认选择 Claude Code" }
  }
}

function Select-AgentsInteractive {
  Write-Host ""
  Write-Host "Step 2/5: 选择需要的 Agent（输入编号，逗号分隔）" -ForegroundColor Cyan
  for ($i = 0; $i -lt $AgentNames.Count; $i++) {
    Write-Host "  $($i + 1)) $($AgentNames[$i])  $($AgentDescs[$i])"
  }
  $choices = Read-Host ">"
  $script:SelectedAgents = @()
  foreach ($idx in ($choices -split ",")) {
    $n = 0
    if ([int]::TryParse($idx.Trim(), [ref]$n) -and $n -ge 1 -and $n -le $AgentNames.Count) {
      $script:SelectedAgents += $AgentNames[$n - 1]
    }
  }
  if ($script:SelectedAgents.Count -eq 0) {
    $script:SelectedAgents = @("analyst", "architect", "developer")
    Write-Info "默认选择核心 Agent: $($script:SelectedAgents -join ' ')"
  }
}

function Select-WorkflowsInteractive {
  Write-Host ""
  Write-Host "Step 3/5: 选择工作流（输入编号，逗号分隔）" -ForegroundColor Cyan
  for ($i = 0; $i -lt $WorkflowNames.Count; $i++) {
    Write-Host "  $($i + 1)) $($WorkflowNames[$i])  $($WorkflowDescs[$i])"
  }
  $choices = Read-Host ">"
  $script:SelectedWorkflows = @()
  foreach ($idx in ($choices -split ",")) {
    $n = 0
    if ([int]::TryParse($idx.Trim(), [ref]$n) -and $n -ge 1 -and $n -le $WorkflowNames.Count) {
      $script:SelectedWorkflows += $WorkflowNames[$n - 1]
    }
  }
  if ($script:SelectedWorkflows.Count -eq 0) {
    $script:SelectedWorkflows = @("feature-flow", "bugfix-flow")
    Write-Info "默认选择: $($script:SelectedWorkflows -join ' ')"
  }
}

function Select-ModeInteractive {
  Write-Host ""
  Write-Host "Step 4/5: 选择流程强度" -ForegroundColor Cyan
  for ($i = 0; $i -lt $ModeNames.Count; $i++) {
    Write-Host "  $($i + 1)) $($ModeNames[$i])  $($ModeDescs[$i])"
  }
  $choice = Read-Host ">"
  switch ($choice) {
    "1" { $script:Mode = "lite" }
    "2" { $script:Mode = "standard" }
    "" { $script:Mode = "standard" }
    "3" { $script:Mode = "strict" }
    default { $script:Mode = "standard"; Write-Info "默认选择 standard" }
  }
}

function Confirm-Interactive {
  Write-Host ""
  Write-Host "Step 5/5: 确认" -ForegroundColor Cyan
  Write-Host "  工具: $Tool"
  Write-Host "  Agent: $($SelectedAgents -join ' ')"
  Write-Host "  工作流: $($SelectedWorkflows -join ' ')"
  Write-Host "  流程强度: $Mode"
  if ($DryRun) { Write-Host "  模式: DRY-RUN（仅预览）" }
  $confirm = Read-Host "确认生成？(Y/n)"
  if ($confirm.ToLower() -eq "n") {
    Stop-Init "已取消"
  }
}

function Generate-Universal {
  Write-Info "生成通用层 .ai-workflow/..."

  $aiWf = Join-Path $TargetDir ".ai-workflow"
  $srcDir = Join-Path $ScriptRoot "templates/universal/ai-workflow"

  Invoke-SafeMkdir $aiWf
  Invoke-SafeMkdir (Join-Path $aiWf "agents")
  Invoke-SafeMkdir (Join-Path $aiWf "workflows")

  # protocol.md
  $protocolSrc = Join-Path $srcDir "protocol.md"
  $protocolDst = Join-Path $aiWf "protocol.md"
  if (Test-Path $protocolSrc) {
    if (Test-Path $protocolDst) {
      Write-Ok ".ai-workflow/protocol.md 已存在，跳过"
    } else {
      Invoke-SafeCopy $protocolSrc $protocolDst
      Write-Ok ".ai-workflow/protocol.md"
    }
  }

  # agents
  foreach ($agent in $SelectedAgents) {
    $src = Join-Path $srcDir "agents/$agent-section.md"
    $dst = Join-Path $aiWf "agents/$agent-section.md"
    if ((Test-Path $src) -and -not (Test-Path $dst)) {
      Invoke-SafeCopy $src $dst
      Write-Ok ".ai-workflow/agents/$agent-section.md"
    }
  }

  # workflows
  foreach ($workflow in $SelectedWorkflows) {
    $src = Join-Path $srcDir "workflows/$workflow.md"
    $dst = Join-Path $aiWf "workflows/$workflow.md"
    if ((Test-Path $src) -and -not (Test-Path $dst)) {
      Invoke-SafeCopy $src $dst
      Write-Ok ".ai-workflow/workflows/$workflow.md"
    }
  }

  # uninstall.sh
  $uninstallSrc = Join-Path $srcDir "uninstall.sh"
  $uninstallDst = Join-Path $aiWf "uninstall.sh"
  if (Test-Path $uninstallSrc) {
    Invoke-SafeCopy $uninstallSrc $uninstallDst
    Write-Ok ".ai-workflow/uninstall.sh"
  }

  # AGENTS.md (Codex): only create if not already exists
  $agentsMd = Join-Path $TargetDir "AGENTS.md"
  if (-not (Test-Path $agentsMd)) {
    Invoke-SafeCopy (Join-Path $ScriptRoot "templates/universal/AGENTS.md") $agentsMd
    $script:AgentsMdCreated = $true
    Write-Ok "AGENTS.md 已生成（从通用模板）"
  } else {
    Write-Warn "AGENTS.md 已存在，不修改。通用协议见 .ai-workflow/protocol.md"
  }

  Write-Ok ".ai-workflow/ 通用层已生成"
}

function Generate-ClaudeCode {
  Write-Info "生成 Claude Code 适配层..."

  foreach ($path in @(
    ".claude/agents",
    ".claude/workflows",
    ".claude/commands",
    ".claude/artifacts/requirements",
    ".claude/artifacts/architectures",
    ".claude/artifacts/reviews",
    ".claude/artifacts/tests",
    ".claude/artifacts/security"
  )) {
    Invoke-SafeMkdir (Join-Path $TargetDir $path)
  }

  foreach ($agent in $SelectedAgents) {
    $src = Join-Path $ScriptRoot "templates/claude-code/agents/$agent.md"
    if (Test-Path $src) {
      Invoke-SafeCopy $src (Join-Path $TargetDir ".claude/agents/$agent.md")
      Write-Ok "Agent: $agent.md"
    }
  }

  foreach ($workflow in $SelectedWorkflows) {
    $src = Join-Path $ScriptRoot "templates/claude-code/workflows/$workflow.md"
    if (Test-Path $src) {
      Invoke-SafeCopy $src (Join-Path $TargetDir ".claude/workflows/$workflow.md")
      Write-Ok "工作流: $workflow.md"
    }
  }

  $copiedCmds = @()
  foreach ($agent in $SelectedAgents) {
    $idx = [Array]::IndexOf($AgentNames, $agent)
    if ($idx -ge 0) {
      $cmd = $AgentCmdFiles[$idx]
      $src = Join-Path $ScriptRoot "templates/claude-code/commands/$cmd"
      if ($cmd -and (Test-Path $src) -and ($copiedCmds -notcontains $cmd)) {
        Invoke-SafeCopy $src (Join-Path $TargetDir ".claude/commands/")
        $copiedCmds += $cmd
      }
    }
  }
  if ($copiedCmds.Count -eq 0) { Write-Ok "快捷命令: 无" } else { Write-Ok "快捷命令: $($copiedCmds -join ' ')" }

  Invoke-SafeCopy (Join-Path $ScriptRoot "templates/claude-code/artifacts/index.md") (Join-Path $TargetDir ".claude/artifacts/index.md")
  if (-not $DryRun) {
    foreach ($subdir in @("requirements", "architectures", "reviews", "tests", "security")) {
      New-Item -ItemType File -Force -Path (Join-Path $TargetDir ".claude/artifacts/$subdir/.gitkeep") | Out-Null
    }
  }
  Write-Ok "产出物存档目录已创建"

  Invoke-SafeCopy (Join-Path $ScriptRoot "templates/claude-code/settings.local.json") (Join-Path $TargetDir ".claude/settings.local.json")
  Write-Ok "settings.local.json 已复制"

  # TDR gate hook
  $hooksDir = Join-Path $TargetDir ".claude/hooks"
  if (-not (Test-Path $hooksDir)) { New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null }
  Invoke-SafeCopy (Join-Path $ScriptRoot "templates/claude-code/hooks/tdr-gate.sh") (Join-Path $hooksDir "tdr-gate.sh")
  Write-Ok "TDR gate hook 已安装"

  $claudePath = Join-Path $TargetDir ".claude/CLAUDE.md"
  $protocolPath = Join-Path $ScriptRoot "templates/claude-code/claude-md-protocol.md"
  if (Test-Path $protocolPath) {
    if (Test-Path $claudePath) {
      Write-Ok ".claude/CLAUDE.md 已存在，跳过"
    } else {
      Invoke-SafeCopy $protocolPath $claudePath
      Write-Ok ".claude/CLAUDE.md 已创建（含多 Agent 协作协议）"
    }
  }

  Append-ModeProtocol $claudePath ".claude/CLAUDE.md"
}

function Generate-Codex {
  Write-Info "生成 Codex CLI 适配层..."
  $target = Join-Path $TargetDir "AGENTS.md"

  # Zero-intrusion: only modify AGENTS.md if we created it in this run
  if (-not $AgentsMdCreated) {
    Write-Warn "AGENTS.md 为已有文件，跳过 Codex 角色追加（通用协议见 .ai-workflow/protocol.md）"
    return
  }

  foreach ($agent in $SelectedAgents) {
    $src = Join-Path $ScriptRoot "templates/codex/agents-md-sections/$($agent)-section.md"
    if (Test-Path $src) {
      Invoke-SafeAppend $src $target
      if (-not $DryRun) { Add-Content -LiteralPath $target -Value "" -Encoding UTF8 }
      Write-Ok "Codex 角色: $agent"
    }
  }
}

function Generate-OpenCode {
  Write-Info "生成 OpenCode 适配层..."
  Invoke-SafeMkdir (Join-Path $TargetDir ".opencode/agents")

  foreach ($agent in $SelectedAgents) {
    $src = Join-Path $ScriptRoot "templates/opencode/agents/$agent.md"
    if (Test-Path $src) {
      Invoke-SafeCopy $src (Join-Path $TargetDir ".opencode/agents/$agent.md")
      Write-Ok "OpenCode Agent: $agent.md"
    }
  }

  $opencodeJson = Join-Path $TargetDir "opencode.json"
  if (-not (Test-Path $opencodeJson)) {
    if ($DryRun) {
      Write-Host "[DRY] create opencode.json" -ForegroundColor Yellow
    } else {
      @"
{
  "`$schema": "https://opencode.ai/config.json",
  "permission": {
    "external_directory": "deny",
    "edit": "ask",
    "bash": {
      "*": "ask",
      "git status*": "allow",
      "git diff*": "allow",
      "git log*": "allow"
    }
  }
}
"@ | Set-Content -LiteralPath $opencodeJson -Encoding UTF8
    }
    Write-Ok "opencode.json 已生成"
  }
}

function Generate-Gitignore {
  $gitignore = Join-Path $TargetDir ".gitignore"
  $entries = @(
    ".env"
    ".env.*"
    "!.env.example"
    ".ai-workflow/"
    ".claude/CLAUDE.md"
    ".claude/agents/"
    ".claude/workflows/"
    ".claude/commands/"
    ".claude/artifacts/"
    ".claude/settings.local.json"
    ".opencode/agents/"
    "opencode.json"
  )

  if (Test-Path $gitignore) {
    $content = Get-Content -LiteralPath $gitignore -Raw
    $modified = $false
    foreach ($entry in $entries) {
      if ($content -notmatch [regex]::Escape($entry)) {
        if (-not $DryRun) { Add-Content -LiteralPath $gitignore -Value $entry -Encoding UTF8 }
        $modified = $true
      }
    }
    if ($modified) { Write-Ok ".gitignore 已更新" }
  } else {
    if ($DryRun) {
      Write-Host "[DRY] create .gitignore" -ForegroundColor Yellow
    } else {
      $entries | Set-Content -LiteralPath $gitignore -Encoding UTF8
    }
    Write-Ok ".gitignore 已创建"
  }
}

if ($Help) {
  Show-Help
  exit 0
}

Write-Host ""
Write-Host "AI-Native Workflow 初始化向导" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path (Join-Path $TargetDir ".git"))) {
  Write-Warn "当前目录不是 git 仓库，建议先 git init"
}

if (-not $Tool) {
  if ($NonInteractive) {
    $Tool = "claude-code"
  } else {
    Select-ToolInteractive
  }
}
if (-not (Test-InList $Tool @("claude-code", "codex", "opencode", "all"))) {
  Stop-Init "未知 AI 编码工具: $Tool（可选: claude-code|codex|opencode|all）"
}

if ($NonInteractive) {
  if ($Agents.Count -gt 0) {
    $SelectedAgents = @($Agents | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  } else {
    $SelectedAgents = $AgentNames
  }
  if ($Workflows.Count -gt 0) {
    $SelectedWorkflows = @($Workflows | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  } else {
    $SelectedWorkflows = $WorkflowNames
  }
  if (-not $Mode) { $Mode = "standard" }
  if (-not (Test-InList $Mode $ModeNames)) { Stop-Init "未知流程强度模式: $Mode（可选: lite|standard|strict）" }
} else {
  if ($SelectedAgents.Count -eq 0 -and $Agents.Count -gt 0) {
    $SelectedAgents = @($Agents | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  }
  if ($SelectedWorkflows.Count -eq 0 -and $Workflows.Count -gt 0) {
    $SelectedWorkflows = @($Workflows | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  }
  if ($SelectedAgents.Count -eq 0) {
    Select-AgentsInteractive
  } else {
    Write-Info "使用命令行指定的 Agent: $($SelectedAgents -join ' ')"
  }
  if ($SelectedWorkflows.Count -eq 0) {
    Select-WorkflowsInteractive
  } else {
    Write-Info "使用命令行指定的工作流: $($SelectedWorkflows -join ' ')"
  }
  if (-not $Mode) { Select-ModeInteractive }
  if (-not (Test-InList $Mode $ModeNames)) { Stop-Init "未知流程强度模式: $Mode（可选: lite|standard|strict）" }
}

Normalize-SelectedAgents
if ($SelectedAgents.Count -eq 0) {
  Stop-Init "未选择有效 Agent"
}

Normalize-SelectedWorkflows
if ($SelectedWorkflows.Count -eq 0) {
  Stop-Init "未选择有效工作流"
}

if (-not $NonInteractive) {
  Confirm-Interactive
}

if ($DryRun) { Write-Info "DRY-RUN 模式：仅预览，不写入文件" }

try {
  Ensure-Templates

  switch ($Tool) {
    "claude-code" { Generate-ClaudeCode }
    "codex" {
      Generate-Universal
      Generate-Codex
    }
    "opencode" {
      Generate-Universal
      Generate-OpenCode
    }
    "all" {
      Generate-Universal
      Generate-ClaudeCode
      Generate-Codex
      Generate-OpenCode
    }
  }
  Generate-Gitignore

  Write-Host ""
  Write-Host "初始化完成！" -ForegroundColor Green
  Write-Host "  工具: $Tool"
  Write-Host "  Agent: $($SelectedAgents.Count) 个"
  Write-Host "  工作流: $($SelectedWorkflows.Count) 条"
  Write-Host "  流程强度: $Mode"
  if ($DryRun) { Write-Host "  模式: DRY-RUN（未写入文件）" -ForegroundColor Yellow }
  Write-Host ""
  Write-Host "  下一步：编辑 CLAUDE.md 顶部的项目概述，然后开始使用。"
  Write-Host "  卸载：./.ai-workflow/uninstall.sh"
} finally {
  if ($TempTemplateDir -and (Test-Path $TempTemplateDir)) {
    Remove-Item -LiteralPath $TempTemplateDir -Recurse -Force -ErrorAction SilentlyContinue
  }
}
