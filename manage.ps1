<#
.SYNOPSIS
    AI Tools Unified Manager - MCP, Skills, Git version control
.EXAMPLE
    .\manage.ps1 status
    .\manage.ps1 list-mcp
    .\manage.ps1 list-skills
    .\manage.ps1 show-skill my-skill
    .\manage.ps1 show-mcp my-server
    .\manage.ps1 git log
    .\manage.ps1 git save "message"
    .\manage.ps1 git push
    .\manage.ps1 test-mcp
    .\manage.ps1 help
    .\manage.ps1 version
#>
param(
    [Parameter(Position=0)]
    [string]$Command = 'help',

    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$ExtraArgs
)

# ---- Auto-detect paths (portable, no hardcoded directories) ----
$RootDir   = $PSScriptRoot
$SharedDir = Join-Path $RootDir 'shared'
$BackupDir = Join-Path $RootDir 'backups'
$UserHome  = $env:USERPROFILE
$ScriptVersion = '2.1.0'

# ---- Helper Functions ----

function Print-Banner {
    Write-Host ''
    Write-Host '=========================================' -ForegroundColor Cyan
    Write-Host '    AI Tools Unified Manager v' -NoNewline -ForegroundColor Cyan; Write-Host $ScriptVersion -ForegroundColor Green
    Write-Host '=========================================' -ForegroundColor Cyan
}

function Init-Environment {
    $isNew = $false
    if (-not (Test-Path $SharedDir)) {
        New-Item -ItemType Directory -Path $SharedDir | Out-Null
        $isNew = $true
        Write-Host '[INIT] Created shared directory.' -ForegroundColor Green
    }

    $mcpDir = Join-Path $SharedDir 'mcp'
    if (-not (Test-Path $mcpDir)) {
        New-Item -ItemType Directory -Path $mcpDir | Out-Null
        $readme = "### MCP Servers`r`nPlace your custom MCP server folders here."
        Set-Content (Join-Path $mcpDir 'README.md') $readme -Encoding UTF8
        Write-Host '[INIT] Created shared\mcp directory.' -ForegroundColor Green
        $isNew = $true
    }

    $skillsDir = Join-Path $SharedDir 'skills'
    if (-not (Test-Path $skillsDir)) {
        New-Item -ItemType Directory -Path $skillsDir | Out-Null
        $readme = "### Skills`r`nPlace your downloaded or custom Skills (with SKILL.md) here."
        Set-Content (Join-Path $skillsDir 'README.md') $readme -Encoding UTF8
        Write-Host '[INIT] Created shared\skills directory.' -ForegroundColor Green
        $isNew = $true
    }

    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir | Out-Null
        Write-Host '[INIT] Created backups directory.' -ForegroundColor Green
        $isNew = $true
    }

    if ($isNew -and -not (Test-Path (Join-Path $SharedDir '.git'))) {
        Push-Location $SharedDir
        git init | Out-Null
        git add . 2>$null
        git commit -m 'init: auto-created folder structure by Unified Manager' 2>$null | Out-Null
        Pop-Location
        Write-Host '[INIT] Initialized local Git repository in shared.' -ForegroundColor Green
    }
}

function Check-Junction($path, $expectedTarget) {
    if (Test-Path $path) {
        $item = Get-Item -LiteralPath $path -Force
        if ($item.LinkType -eq 'Junction') {
            if ($item.Target -match [regex]::Escape($expectedTarget)) {
                Write-Host ('  [OK]   {0} -> {1}' -f $path, $expectedTarget) -ForegroundColor Green
                return $true
            } else {
                Write-Host ('  [WARN] {0} -> {1} (expected: {2})' -f $path, $item.Target, $expectedTarget) -ForegroundColor Yellow
                return $false
            }
        } else {
            Write-Host ('  [FAIL] {0} is a normal directory, not a Junction' -f $path) -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host ('  [MISS] {0} is MISSING' -f $path) -ForegroundColor Red
        return $false
    }
}

function Repair-Junction($path, $targetDir) {
    if (Test-Path $path) {
        $item = Get-Item -LiteralPath $path -Force
        if ($item.LinkType -eq 'Junction' -and ($item.Target -match [regex]::Escape($targetDir))) {
            return
        }
        Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
    }

    $parentDir = Split-Path $path
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    try {
        cmd /c mklink /J "$path" "$targetDir" > $null
        Write-Host ('  [FIXED] Created Junction: {0} -> {1}' -f $path, $targetDir) -ForegroundColor Green
    } catch {
        Write-Host ('  [FAIL] Failed to create Junction: {0}' -f $_) -ForegroundColor Red
    }
}

# ---- Auto-init on every run ----
Init-Environment

# ---- Main Command Switch ----
switch ($Command) {

    'help' {
        Print-Banner
        Write-Host '  Usage: ' -NoNewline -ForegroundColor White; Write-Host '.\manage.ps1 <command> [args...]' -ForegroundColor Yellow
        Write-Host ''

        Write-Host '  --- 查询 ---' -ForegroundColor Cyan
        Write-Host '    status              查看总体状态（链接、MCP、Skill、Git、备份）'
        Write-Host '    list-mcp            列出所有安装的 MCP 服务器'
        Write-Host '    list-skills         列出所有安装的 Skill 技能'
        Write-Host '    show-mcp <name>     查看特定 MCP 的配置详情'
        Write-Host '    show-skill <name>   查看特定 Skill 的 README/配置'
        Write-Host '    test-mcp            测试所有 MCP 是否能正常启动'
        Write-Host ''

        Write-Host '  --- 安装与卸载 ---' -ForegroundColor Cyan
        Write-Host '    add-mcp [name]      添加一个新的 MCP（向导式）'
        Write-Host '    remove-mcp <name>   从所有 AI 工具中卸载该 MCP'
        Write-Host '    add-skill <source>  安装新技能 (Git URL / Zip / 本地目录)'
        Write-Host '    remove-skill <name> 删除特定的 Skill 技能'
        Write-Host ''

        Write-Host '  --- Git 版本管理 ---' -ForegroundColor Cyan
        Write-Host '    git log             查看历史修改记录'
        Write-Host '    git diff            查看当前未保存的修改'
        Write-Host '    git status          查看当前文件状态'
        Write-Host '    git save "msg"      保存所有当前的修改'
        Write-Host '    git push            一键发版到云端仓库 (GitHub)'
        Write-Host '    git rollback <hash> 回退到某个历史版本'
        Write-Host '    git reset           放弃所有未保存的修改'
        Write-Host ''

        Write-Host '  --- 维护与系统 ---' -ForegroundColor Cyan
        Write-Host '    backup              手动触发完整目录备份'
        Write-Host '    repair              自动修复缺失的符号链接 (Junction)'
        Write-Host '    version             显示管理脚本版本'
        Write-Host ''
    }

    'version' {
        Write-Host ('Unified Management Script v{0}' -f $ScriptVersion) -ForegroundColor Cyan
    }

    'status' {
        Print-Banner
        Write-Host '[Junction Links]' -ForegroundColor Yellow
        Check-Junction (Join-Path $UserHome '.claude\MCP')    (Join-Path $SharedDir 'mcp') | Out-Null
        Check-Junction (Join-Path $UserHome '.claude\skills') (Join-Path $SharedDir 'skills') | Out-Null
        Check-Junction (Join-Path $UserHome '.gemini\skills') (Join-Path $SharedDir 'skills') | Out-Null
        Check-Junction (Join-Path $UserHome '.codex\skills')  (Join-Path $SharedDir 'skills') | Out-Null

        Write-Host ''
        Write-Host '[Component Stats]' -ForegroundColor Yellow
        $mcpCount   = @(Get-ChildItem (Join-Path $SharedDir 'mcp')    -Directory -ErrorAction SilentlyContinue).Count
        $skillCount = @(Get-ChildItem (Join-Path $SharedDir 'skills') -Directory -ErrorAction SilentlyContinue).Count
        Write-Host ('  MCP Servers: {0}' -f $mcpCount) -ForegroundColor Green
        Write-Host ('  Skills:      {0}' -f $skillCount) -ForegroundColor Green

        Write-Host ''
        Write-Host '[Git Status]' -ForegroundColor Yellow
        if (Test-Path (Join-Path $SharedDir '.git')) {
            Push-Location $SharedDir
            $branch = git rev-parse --abbrev-ref HEAD 2>$null
            $commit = git log -1 --format='%h %s' 2>$null
            $dirty  = @(git status --porcelain 2>$null)
            Write-Host ('  Branch: {0}' -f $branch)
            Write-Host ('  Latest: {0}' -f $commit)
            if ($dirty.Count -gt 0) {
                Write-Host ('  Uncommitted: {0} file(s)' -f $dirty.Count) -ForegroundColor Yellow
            } else {
                Write-Host '  Working tree: clean' -ForegroundColor Green
            }
            Pop-Location
        } else {
            Write-Host '  Not a git repository yet.' -ForegroundColor Yellow
        }

        Write-Host ''
        Write-Host '[Backups]' -ForegroundColor Yellow
        if (Test-Path $BackupDir) {
            $backups = Get-ChildItem $BackupDir -Directory | Sort-Object Name -Descending | Select-Object -First 3
            if ($backups.Count -gt 0) {
                foreach ($b in $backups) { Write-Host ('  {0}' -f $b.Name) }
            } else { Write-Host '  No backups yet' }
        } else {
            Write-Host '  No backups found' -ForegroundColor Yellow
        }
        Write-Host ''
    }

    'repair' {
        Write-Host ''
        Write-Host '=== Repairing Junction Links ===' -ForegroundColor Cyan
        Repair-Junction (Join-Path $UserHome '.claude\MCP')    (Join-Path $SharedDir 'mcp')
        Repair-Junction (Join-Path $UserHome '.claude\skills') (Join-Path $SharedDir 'skills')
        Repair-Junction (Join-Path $UserHome '.gemini\skills') (Join-Path $SharedDir 'skills')
        Repair-Junction (Join-Path $UserHome '.codex\skills')  (Join-Path $SharedDir 'skills')
        Write-Host 'Repair complete!' -ForegroundColor Green
        Write-Host ''
    }

    'list-mcp' {
        Write-Host ''
        Write-Host ('=== Shared MCP Servers ({0}\mcp) ===' -f $SharedDir) -ForegroundColor Cyan
        Get-ChildItem (Join-Path $SharedDir 'mcp') -Directory | ForEach-Object {
            Write-Host ('  * {0}' -f $_.Name) -ForegroundColor Green
        }
        Write-Host ''
    }

    'show-mcp' {
        if ($ExtraArgs.Count -lt 1) {
            Write-Host 'Usage: .\manage.ps1 show-mcp <mcp-name>' -ForegroundColor Yellow
            return
        }
        $mcpName = $ExtraArgs[0]
        $mcpDir = Join-Path $SharedDir "mcp\$mcpName"

        Write-Host ''
        Write-Host ("=== Details for MCP: $mcpName ===") -ForegroundColor Cyan
        if (-not (Test-Path $mcpDir)) {
            Write-Host "Directory not found: $mcpDir" -ForegroundColor Red
            return
        }

        Write-Host "Location: $mcpDir"
        $files = Get-ChildItem $mcpDir -File | Select-Object -ExpandProperty Name
        Write-Host "Files: " -NoNewline; Write-Host ($files -join ', ') -ForegroundColor Green

        Write-Host ''
        Write-Host '[Configuration Check]' -ForegroundColor Yellow
        $claudeFile = Join-Path $UserHome '.claude\.mcp.json'
        if (Test-Path $claudeFile) {
            try {
                $claude = Get-Content $claudeFile -Raw | ConvertFrom-Json
                if ($null -ne $claude.mcpServers.$mcpName) {
                    Write-Host ('  [Claude] Found: command = {0}' -f $claude.mcpServers.$mcpName.command) -ForegroundColor Green
                } else { Write-Host '  [Claude] Not configured' -ForegroundColor DarkGray }
            } catch {}
        }
        $geminiFile = Join-Path $UserHome '.gemini\settings.json'
        if (Test-Path $geminiFile) {
            try {
                $gem = Get-Content $geminiFile -Raw | ConvertFrom-Json
                if ($null -ne $gem.mcpServers.$mcpName) {
                    Write-Host ('  [Gemini] Found: command = {0}' -f $gem.mcpServers.$mcpName.command) -ForegroundColor Green
                } else { Write-Host '  [Gemini] Not configured' -ForegroundColor DarkGray }
            } catch {}
        }
        Write-Host ''
    }

    'remove-mcp' {
        if ($ExtraArgs.Count -lt 1) {
            Write-Host 'Usage: .\manage.ps1 remove-mcp <mcp-name>' -ForegroundColor Yellow
            return
        }
        $mcpName = $ExtraArgs[0]
        $mcpDir = Join-Path $SharedDir "mcp\$mcpName"

        if (-not (Test-Path $mcpDir)) {
            Write-Host ("MCP directory not found: $mcpDir") -ForegroundColor Red
        } else {
            $confirm = Read-Host ("Remove MCP '$mcpName' and its configs? (y/N)")
            if ($confirm -notmatch '^[yY]') { return }
            Remove-Item -LiteralPath $mcpDir -Recurse -Force
            Write-Host ("Removed directory $mcpDir") -ForegroundColor Green
        }

        Write-Host 'Removing from configs...' -ForegroundColor Yellow

        $f = Join-Path $UserHome '.claude\.mcp.json'
        if (Test-Path $f) {
            $obj = Get-Content $f -Raw | ConvertFrom-Json
            if ($null -ne $obj.mcpServers.$mcpName) {
                $obj.mcpServers.PSObject.Properties.Remove($mcpName)
                $obj | ConvertTo-Json -Depth 10 | Set-Content $f -Encoding UTF8
                Write-Host '  [OK] Removed from Claude' -ForegroundColor Green
            }
        }

        $f = Join-Path $UserHome '.gemini\settings.json'
        if (Test-Path $f) {
            $obj = Get-Content $f -Raw | ConvertFrom-Json
            if ($null -ne $obj.mcpServers.$mcpName) {
                $obj.mcpServers.PSObject.Properties.Remove($mcpName)
                $obj | ConvertTo-Json -Depth 10 | Set-Content $f -Encoding UTF8
                Write-Host '  [OK] Removed from Gemini' -ForegroundColor Green
            }
        }

        $f = Join-Path $UserHome '.config\opencode\opencode.json'
        if (Test-Path $f) {
            $obj = Get-Content $f -Raw | ConvertFrom-Json
            if ($null -ne $obj.mcp.$mcpName) {
                $obj.mcp.PSObject.Properties.Remove($mcpName)
                $obj | ConvertTo-Json -Depth 10 | Set-Content $f -Encoding UTF8
                Write-Host '  [OK] Removed from OpenCode' -ForegroundColor Green
            }
        }

        $f = Join-Path $UserHome '.codex\config.toml'
        if (Test-Path $f) {
            $content = Get-Content $f -Raw
            $pattern = '(?m)(?s)\[mcp_servers\.' + [regex]::Escape($mcpName) + '\].*?(?=\[mcp_servers|$)'
            if ($content -match $pattern) {
                $content = $content -replace $pattern, ''
                Set-Content $f -Value $content.TrimEnd() -Encoding UTF8
                Write-Host '  [OK] Removed from Codex' -ForegroundColor Green
            }
        }

        if (Test-Path (Join-Path $SharedDir '.git')) {
            Push-Location $SharedDir
            git add -A
            git commit -m ("remove-mcp: " + $mcpName) 2>&1 | Out-Null
            Pop-Location
        }
        Write-Host 'Removal complete!' -ForegroundColor Green
        Write-Host ''
    }

    'list-skills' {
        Write-Host ''
        Write-Host ('=== Shared Skills ({0}\skills) ===' -f $SharedDir) -ForegroundColor Cyan
        Get-ChildItem (Join-Path $SharedDir 'skills') -Directory | ForEach-Object {
            $skillMd = Join-Path $_.FullName 'SKILL.md'
            if (Test-Path $skillMd) {
                $head = Get-Content $skillMd -TotalCount 1
                $tag = if ($head -eq '---') { '[OK]' } else { '[!!]' }
                $color = if ($head -eq '---') { 'Green' } else { 'Red' }
            } else {
                $tag = '[--]'; $color = 'Yellow'
            }
            Write-Host ('  {0} {1}' -f $tag, $_.Name) -ForegroundColor $color
        }
        Write-Host ''
    }

    'show-skill' {
        if ($ExtraArgs.Count -lt 1) {
            Write-Host 'Usage: .\manage.ps1 show-skill <skill-name>' -ForegroundColor Yellow
            return
        }
        $skillName = $ExtraArgs[0]
        $skillDir = Join-Path $SharedDir "skills\$skillName"

        Write-Host ''
        Write-Host ("=== Details for Skill: $skillName ===") -ForegroundColor Cyan
        if (-not (Test-Path $skillDir)) {
            Write-Host "Directory not found: $skillDir" -ForegroundColor Red
            return
        }

        $skillMd = Join-Path $skillDir 'SKILL.md'
        if (Test-Path $skillMd) {
            Write-Host 'SKILL.md content (first 10 lines):' -ForegroundColor Yellow
            Get-Content $skillMd -TotalCount 10 | ForEach-Object { Write-Host "  $_" }
            Write-Host '  ...'
        } else {
            Write-Host '[WARN] SKILL.md not found!' -ForegroundColor Red
        }
        Write-Host ''
    }

    'remove-skill' {
        if ($ExtraArgs.Count -lt 1) {
            Write-Host 'Usage: .\manage.ps1 remove-skill <skill-name>' -ForegroundColor Yellow
            return
        }
        $skillName = $ExtraArgs[0]
        $skillDir = Join-Path $SharedDir "skills\$skillName"

        if (-not (Test-Path $skillDir)) {
            Write-Host ("Skill directory not found: $skillDir") -ForegroundColor Red
            return
        }

        $confirm = Read-Host ("Remove skill '$skillName'? (y/N)")
        if ($confirm -notmatch '^[yY]') { return }

        Remove-Item -LiteralPath $skillDir -Recurse -Force
        Write-Host ("Removed: $skillDir") -ForegroundColor Green

        if (Test-Path (Join-Path $SharedDir '.git')) {
            Push-Location $SharedDir
            git add -A
            git commit -m ("remove-skill: " + $skillName) 2>&1 | Out-Null
            Pop-Location
        }
        Write-Host 'Removal complete!' -ForegroundColor Green
        Write-Host ''
    }

    'backup' {
        Write-Host ''
        Write-Host '=== Creating Manual Backup ===' -ForegroundColor Cyan
        if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir | Out-Null }

        $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
        $destDir = Join-Path $BackupDir "manual_backup_$ts"
        New-Item -ItemType Directory -Path $destDir | Out-Null

        Write-Host 'Backing up configs...' -ForegroundColor Yellow
        Copy-Item (Join-Path $UserHome '.claude\.mcp.json') (Join-Path $destDir 'claude_mcp.json') -Force -ErrorAction SilentlyContinue
        Copy-Item (Join-Path $UserHome '.gemini\settings.json') (Join-Path $destDir 'gemini_settings.json') -Force -ErrorAction SilentlyContinue
        Copy-Item (Join-Path $UserHome '.codex\config.toml') (Join-Path $destDir 'codex_config.toml') -Force -ErrorAction SilentlyContinue
        Copy-Item (Join-Path $UserHome '.config\opencode\opencode.json') (Join-Path $destDir 'opencode_config.json') -Force -ErrorAction SilentlyContinue

        Write-Host 'Backing up shared folder...' -ForegroundColor Yellow
        $zipPath = Join-Path $destDir 'shared_folder.zip'
        Compress-Archive -Path $SharedDir -DestinationPath $zipPath -Force

        Write-Host ("Backup created at: $destDir") -ForegroundColor Green
        Write-Host ''
    }

    'git' {
        $sub = if ($ExtraArgs.Count -gt 0) { $ExtraArgs[0] } else { 'status' }

        if (-not (Test-Path (Join-Path $SharedDir '.git'))) {
            Write-Host "Error: Git is not initialized in $SharedDir" -ForegroundColor Red
            return
        }

        switch ($sub) {
            'log' {
                Write-Host ''
                Write-Host '=== Git Commit History ===' -ForegroundColor Cyan
                Push-Location $SharedDir
                git log --oneline --graph -20
                Pop-Location
                Write-Host ''
            }
            'diff' {
                Push-Location $SharedDir
                git diff
                git diff --cached
                Pop-Location
            }
            'status' {
                Push-Location $SharedDir
                git status
                Pop-Location
            }
            'save' {
                $msg = if ($ExtraArgs.Count -gt 1) {
                    ($ExtraArgs[1..($ExtraArgs.Count-1)]) -join ' '
                } else {
                    'update: manual save ' + (Get-Date -Format 'yyyy-MM-dd HH:mm')
                }
                Push-Location $SharedDir
                git add -A
                git commit -m $msg
                Pop-Location
                Write-Host ''
                Write-Host ('Saved: {0}' -f $msg) -ForegroundColor Green
            }
            'push' {
                Write-Host ''
                Write-Host '=== Pushing to Remote Repository ===' -ForegroundColor Cyan
                Push-Location $SharedDir
                $remotes = git remote -v 2>$null
                if ([string]::IsNullOrWhiteSpace($remotes)) {
                    Write-Host '  [FAIL] No remote configured.' -ForegroundColor Red
                    Write-Host '  Run this first: git remote add origin <your-github-url>' -ForegroundColor Yellow
                } else {
                    Write-Host 'Pushing...' -ForegroundColor Yellow
                    git push -u origin HEAD 2>&1 | Write-Host
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host '  [OK] Push successful!' -ForegroundColor Green
                    } else {
                        Write-Host '  [FAIL] Push failed. See error above.' -ForegroundColor Red
                    }
                }
                Pop-Location
                Write-Host ''
            }
            'rollback' {
                if ($ExtraArgs.Count -lt 2) {
                    Write-Host 'Usage: .\manage.ps1 git rollback <commitHash>' -ForegroundColor Yellow
                    return
                }
                $hash = $ExtraArgs[1]
                Write-Host ''
                Write-Host ('About to rollback to commit: {0}' -f $hash) -ForegroundColor Yellow
                Write-Host 'This will discard all uncommitted changes!' -ForegroundColor Red
                $confirm = Read-Host 'Confirm rollback? (y/N)'
                if ($confirm -notmatch '^[yY]') { return }

                Push-Location $SharedDir
                $tempBranch = 'backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
                git stash -u 2>$null
                git branch $tempBranch 2>$null
                Write-Host ('Current state saved to branch: {0}' -f $tempBranch) -ForegroundColor Cyan
                git checkout $hash -- .
                git add -A
                git commit -m ('rollback: revert to {0}' -f $hash)
                Pop-Location
                Write-Host ''
                Write-Host ('Rollback complete! To undo, switch to branch: {0}' -f $tempBranch) -ForegroundColor Green
            }
            'reset' {
                Write-Host ''
                Write-Host 'About to discard all uncommitted changes' -ForegroundColor Yellow
                $confirm = Read-Host 'Confirm? (y/N)'
                if ($confirm -notmatch '^[yY]') { return }

                Push-Location $SharedDir
                git checkout -- .
                git clean -fd
                Pop-Location
                Write-Host 'Restored to latest commit.' -ForegroundColor Green
            }
            default {
                Write-Host ('Unknown git subcommand: {0}' -f $sub) -ForegroundColor Red
            }
        }
    }

    'test-mcp' {
        Write-Host ''
        Write-Host '=== Testing MCP Server Startup ===' -ForegroundColor Cyan
        $mcpRoot = Join-Path $SharedDir 'mcp'
        $servers = @(
            @{ Name='alpha-midgrp';        Cmd='uv'; CmdArgs=('--directory "' + (Join-Path $mcpRoot 'alpha-midgrp') + '" run alpha-midgrp') },
            @{ Name='oracle-unified-query'; Cmd='python'; CmdArgs=(Join-Path $mcpRoot 'oracle_unified_query\server.py') }
        )
        foreach ($s in $servers) {
            Write-Host ''
            Write-Host ('  Testing {0}...' -f $s.Name) -ForegroundColor Yellow
            try {
                $errFile = Join-Path $env:TEMP 'mcp_test_err.txt'
                $outFile = Join-Path $env:TEMP 'mcp_test_out.txt'
                $proc = Start-Process -FilePath $s.Cmd -ArgumentList $s.CmdArgs -PassThru -NoNewWindow -RedirectStandardError $errFile -RedirectStandardOutput $outFile
                Start-Sleep -Seconds 3
                if (-not $proc.HasExited) {
                    Write-Host ('  [OK]   {0} started (PID: {1})' -f $s.Name, $proc.Id) -ForegroundColor Green
                    $proc.Kill()
                } else {
                    $err = Get-Content $errFile -ErrorAction SilentlyContinue | Select-Object -First 3
                    Write-Host ('  [FAIL] {0} exited immediately (Code: {1})' -f $s.Name, $proc.ExitCode) -ForegroundColor Red
                    if ($err) { $err | ForEach-Object { Write-Host ('         {0}' -f $_) -ForegroundColor DarkRed } }
                }
            } catch {
                Write-Host ('  [FAIL] {0} could not start: {1}' -f $s.Name, $_) -ForegroundColor Red
            }
        }
        Write-Host ''
    }

    'add-mcp' {
        Write-Host ''
        Write-Host '=== Add MCP Server to All Tools ===' -ForegroundColor Cyan
        Write-Host ''

        $mcpName = if ($ExtraArgs.Count -gt 0) { $ExtraArgs[0] } else { Read-Host 'MCP name (e.g. my-new-server)' }
        $mcpCmd  = if ($ExtraArgs.Count -gt 1) { $ExtraArgs[1] } else { Read-Host 'Command (e.g. python)' }
        $mcpArg  = if ($ExtraArgs.Count -gt 2) { $ExtraArgs[2] } else { Read-Host 'Arguments (e.g. path\to\server.py)' }

        $envVars = @{}
        if ($ExtraArgs.Count -gt 3) {
            for ($i = 3; $i -lt $ExtraArgs.Count; $i++) {
                $parts = $ExtraArgs[$i] -split '=', 2
                if ($parts.Count -eq 2) { $envVars[$parts[0].Trim()] = $parts[1].Trim() }
            }
        } else {
            $hasEnv = Read-Host 'Has environment variables? (y/N)'
            if ($hasEnv -match '^[yY]') {
                Write-Host 'Enter env vars (KEY=VALUE). Empty line to finish:'
                while ($true) {
                    $line = Read-Host '  '
                    if ([string]::IsNullOrWhiteSpace($line)) { break }
                    $parts = $line -split '=', 2
                    if ($parts.Count -eq 2) { $envVars[$parts[0].Trim()] = $parts[1].Trim() }
                }
            }
        }

        Write-Host ''
        Write-Host ('Adding "{0}" to all tools...' -f $mcpName) -ForegroundColor Yellow

        # Claude
        $claudeFile = Join-Path $UserHome '.claude\.mcp.json'
        try {
            if (-not (Test-Path $claudeFile)) {
                $dir = Split-Path $claudeFile
                if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                Set-Content $claudeFile '{"mcpServers":{}}' -Encoding UTF8
            }
            $claude = Get-Content $claudeFile -Raw | ConvertFrom-Json
            $newServer = @{ command = $mcpCmd; args = @($mcpArg -split ' ') }
            if ($envVars.Count -gt 0) { $newServer['env'] = $envVars }
            $claude.mcpServers | Add-Member -NotePropertyName $mcpName -NotePropertyValue ([PSCustomObject]$newServer) -Force
            $claude | ConvertTo-Json -Depth 10 | Set-Content $claudeFile -Encoding UTF8
            Write-Host ('  [OK] Claude:   {0}' -f $claudeFile) -ForegroundColor Green
        } catch { Write-Host ('  [FAIL] Claude: {0}' -f $_) -ForegroundColor Red }

        # Gemini
        $geminiFile = Join-Path $UserHome '.gemini\settings.json'
        try {
            if (-not (Test-Path $geminiFile)) {
                $dir = Split-Path $geminiFile
                if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                Set-Content $geminiFile '{"mcpServers":{}}' -Encoding UTF8
            }
            $gemini = Get-Content $geminiFile -Raw | ConvertFrom-Json
            $newServer = @{ command = $mcpCmd; args = @($mcpArg -split ' '); env = @{}; timeout = 60000 }
            if ($envVars.Count -gt 0) { $newServer['env'] = $envVars }
            $gemini.mcpServers | Add-Member -NotePropertyName $mcpName -NotePropertyValue ([PSCustomObject]$newServer) -Force
            $gemini | ConvertTo-Json -Depth 10 | Set-Content $geminiFile -Encoding UTF8
            Write-Host ('  [OK] Gemini:   {0}' -f $geminiFile) -ForegroundColor Green
        } catch { Write-Host ('  [FAIL] Gemini: {0}' -f $_) -ForegroundColor Red }

        # Codex
        $codexFile = Join-Path $UserHome '.codex\config.toml'
        try {
            if (-not (Test-Path $codexFile)) {
                $dir = Split-Path $codexFile
                if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                Set-Content $codexFile '' -Encoding UTF8
            }
            $tomlContent = Get-Content $codexFile -Raw -ErrorAction SilentlyContinue
            $argsEsc = ($mcpArg -split ' ' | ForEach-Object { '"{0}"' -f $_ }) -join ', '
            $newBlock = "`n[mcp_servers.{0}]`ntype = `"stdio`"`ncommand = `"{1}`"`nargs = [{2}]`n" -f $mcpName, $mcpCmd, $argsEsc
            if ($envVars.Count -gt 0) {
                $newBlock += "`n[mcp_servers.{0}.env]`n" -f $mcpName
                foreach ($k in $envVars.Keys) { $newBlock += '{0} = "{1}"`n' -f $k, $envVars[$k] }
            }
            $tomlContent += $newBlock
            Set-Content $codexFile -Value $tomlContent -Encoding UTF8
            Write-Host ('  [OK] Codex:    {0}' -f $codexFile) -ForegroundColor Green
        } catch { Write-Host ('  [FAIL] Codex:  {0}' -f $_) -ForegroundColor Red }

        # OpenCode
        $ocPath = Join-Path $UserHome '.config\opencode'
        $openCodeFile = Join-Path $ocPath 'opencode.json'
        try {
            if (-not (Test-Path $ocPath)) { New-Item -ItemType Directory -Path $ocPath -Force | Out-Null }
            if (-not (Test-Path $openCodeFile)) { Set-Content $openCodeFile '{"mcp":{}}' -Encoding UTF8 }
            $oc = Get-Content $openCodeFile -Raw | ConvertFrom-Json
            $cmdArr = @($mcpCmd) + @($mcpArg -split ' ')
            $newServer = @{ command = $cmdArr; enabled = $true; type = 'local' }
            if ($envVars.Count -gt 0) { $newServer['environment'] = $envVars }
            $oc.mcp | Add-Member -NotePropertyName $mcpName -NotePropertyValue ([PSCustomObject]$newServer) -Force
            $oc | ConvertTo-Json -Depth 10 | Set-Content $openCodeFile -Encoding UTF8
            Write-Host ('  [OK] OpenCode: {0}' -f $openCodeFile) -ForegroundColor Green
        } catch { Write-Host ('  [FAIL] OpenCode: {0}' -f $_) -ForegroundColor Red }

        Write-Host ''
        Write-Host ('Done! "{0}" added. Restart CLI to take effect.' -f $mcpName) -ForegroundColor Green
        Write-Host ''
    }

    'add-skill' {
        Write-Host ''
        Write-Host '=== Download and Install Skill ===' -ForegroundColor Cyan
        Write-Host ''

        if ($ExtraArgs.Count -lt 1) {
            Write-Host 'Usage:' -ForegroundColor Yellow
            Write-Host '  .\manage.ps1 add-skill <git-url> [name]        Clone from Git repo'
            Write-Host '  .\manage.ps1 add-skill <path.zip> [name]       Extract from local zip'
            Write-Host '  .\manage.ps1 add-skill <local-dir> [name]      Copy from local directory'
            return
        }

        $source    = $ExtraArgs[0]
        $skillsDir = Join-Path $SharedDir 'skills'

        if ($ExtraArgs.Count -gt 1) {
            $skillName = $ExtraArgs[1]
        } else {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($source)
            $baseName = $baseName -replace '\.git$', ''
            $skillName = $baseName
        }

        $targetDir = Join-Path $skillsDir $skillName

        if (Test-Path $targetDir) {
            Write-Host ('Skill "{0}" already exists at: {1}' -f $skillName, $targetDir) -ForegroundColor Yellow
            $overwrite = Read-Host 'Overwrite? (y/N)'
            if ($overwrite -notmatch '^[yY]') { Write-Host 'Cancelled.'; return }
            Remove-Item -LiteralPath $targetDir -Recurse -Force
        }

        $success = $false

        if ($source -match '^https?://' -or $source -match '\.git$' -or $source -match '^git@') {
            Write-Host ('Cloning from Git: {0}' -f $source) -ForegroundColor Yellow
            $tempClone = Join-Path $env:TEMP ('skill-clone-' + (Get-Date -Format 'yyyyMMddHHmmss'))
            try {
                git clone --depth 1 $source $tempClone 2>&1 | Write-Host
                if (Test-Path $tempClone) {
                    $gitDir = Join-Path $tempClone '.git'
                    if (Test-Path $gitDir) { Remove-Item -LiteralPath $gitDir -Recurse -Force }
                    $skillMd = Join-Path $tempClone 'SKILL.md'
                    if (Test-Path $skillMd) {
                        Copy-Item $tempClone $targetDir -Recurse -Force
                        $success = $true
                    } else {
                        $found = Get-ChildItem $tempClone -Recurse -Filter 'SKILL.md' | Select-Object -First 1
                        if ($found) {
                            Copy-Item -LiteralPath $found.Directory.FullName $targetDir -Recurse -Force
                            $success = $true
                        } else {
                            Copy-Item $tempClone $targetDir -Recurse -Force
                            $success = $true
                            Write-Host '  [WARN] No SKILL.md found.' -ForegroundColor Yellow
                        }
                    }
                    Remove-Item -LiteralPath $tempClone -Recurse -Force -ErrorAction SilentlyContinue
                }
            } catch { Write-Host ('  [FAIL] Git clone failed: {0}' -f $_) -ForegroundColor Red }
        }
        elseif ($source -match '\.zip$' -and (Test-Path $source)) {
            Write-Host ('Extracting from ZIP: {0}' -f $source) -ForegroundColor Yellow
            $tempExtract = Join-Path $env:TEMP ('skill-extract-' + (Get-Date -Format 'yyyyMMddHHmmss'))
            try {
                Expand-Archive -Path $source -DestinationPath $tempExtract -Force
                $found = Get-ChildItem $tempExtract -Recurse -Filter 'SKILL.md' | Select-Object -First 1
                if ($found) {
                    Copy-Item -LiteralPath $found.Directory.FullName $targetDir -Recurse -Force
                } else {
                    $subDirs = Get-ChildItem $tempExtract -Directory
                    if ($subDirs.Count -eq 1) { Copy-Item -LiteralPath $subDirs[0].FullName $targetDir -Recurse -Force }
                    else { Copy-Item -LiteralPath $tempExtract $targetDir -Recurse -Force }
                    Write-Host '  [WARN] No SKILL.md found in ZIP.' -ForegroundColor Yellow
                }
                Remove-Item -LiteralPath $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
                $success = $true
            } catch { Write-Host ('  [FAIL] ZIP extraction failed: {0}' -f $_) -ForegroundColor Red }
        }
        elseif (Test-Path $source -PathType Container) {
            Write-Host ('Copying from local: {0}' -f $source) -ForegroundColor Yellow
            try {
                Copy-Item -LiteralPath $source $targetDir -Recurse -Force
                $success = $true
            } catch { Write-Host ('  [FAIL] Copy failed: {0}' -f $_) -ForegroundColor Red }
        }
        else {
            Write-Host ('  [FAIL] Source not recognized: {0}' -f $source) -ForegroundColor Red
            return
        }

        if ($success) {
            Write-Host ''
            $skillMdPath = Join-Path $targetDir 'SKILL.md'
            if (Test-Path $skillMdPath) {
                $firstLine = Get-Content $skillMdPath -TotalCount 1
                if ($firstLine -eq '---') {
                    Write-Host '  [OK] SKILL.md frontmatter valid' -ForegroundColor Green
                } else {
                    Write-Host '  [WARN] SKILL.md missing --- frontmatter!' -ForegroundColor Red
                }
            } else {
                Write-Host '  [WARN] No SKILL.md found.' -ForegroundColor Yellow
            }

            if (Test-Path (Join-Path $SharedDir '.git')) {
                Push-Location $SharedDir
                git add -A
                git commit -m ('add-skill: {0} (from {1})' -f $skillName, $source) 2>&1 | Out-Null
                Pop-Location
            }

            Write-Host ''
            Write-Host ('Skill "{0}" installed to: {1}' -f $skillName, $targetDir) -ForegroundColor Green
            Write-Host ''
        }
    }

    default {
        Write-Host ('Unknown command: {0}. Run ".\manage.ps1 help" for usage.' -f $Command) -ForegroundColor Red
    }
}
