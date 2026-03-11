$ErrorActionPreference = "Stop"

$BackupDir = "D:\AI\backups\20260310"
if (-not (Test-Path $BackupDir)) {
    Write-Error "Backup directory $BackupDir not found!"
    exit 1
}

Write-Host "WARNING: This will restore configs and directories to their state before the shared directory migration." -ForegroundColor Yellow
$confirm = Read-Host "Proceed with rollback? (y/N)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "Rollback cancelled."
    exit 0
}

Write-Host "1. Removing Junctions..." -ForegroundColor Cyan
$junctions = @("C:\Users\56308\.claude\MCP", "C:\Users\56308\.agents\skills", "C:\Users\56308\.gemini\skills", "C:\Users\56308\.codex\skills")
foreach ($j in $junctions) {
    if (Test-Path $j) {
        Remove-Item $j -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "2. Restoring Config Files..." -ForegroundColor Cyan
Copy-Item "$BackupDir\claude_mcp.json" "C:\Users\56308\.claude\.mcp.json" -Force
Copy-Item "$BackupDir\gemini_settings.json" "C:\Users\56308\.gemini\settings.json" -Force
Copy-Item "$BackupDir\codex_config.toml" "C:\Users\56308\.codex\config.toml" -Force
Copy-Item "$BackupDir\opencode_config.json" "C:\Users\56308\.config\opencode\opencode.json" -Force

Write-Host "3. Restoring Original Directories..." -ForegroundColor Cyan
Copy-Item "$BackupDir\claude_MCP\*" "C:\Users\56308\.claude\MCP\" -Recurse -Force
Copy-Item "$BackupDir\agents_skills\*" "C:\Users\56308\.agents\skills\" -Recurse -Force
Copy-Item "$BackupDir\gemini_skills\*" "C:\Users\56308\.gemini\skills\" -Recurse -Force
Copy-Item "$BackupDir\codex_skills\*" "C:\Users\56308\.codex\skills\" -Recurse -Force

Write-Host "`nRollback complete. System restored to pre-migration state." -ForegroundColor Green
