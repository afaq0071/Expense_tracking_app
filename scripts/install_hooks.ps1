#!/usr/bin/env pwsh
#
# install_hooks.ps1 — Install the git pre-commit hook for this project.
#
# Usage:
#   cd D:\expense_tracker_app
#   powershell -ExecutionPolicy Bypass -File scripts\install_hooks.ps1
#

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot    = (Get-Location).Path
$hooksDir    = Join-Path $repoRoot ".git\hooks"
$hookSource  = Join-Path $repoRoot "scripts\pre-commit.ps1"
$hookTarget  = Join-Path $hooksDir "pre-commit"

if (!(Test-Path $hooksDir)) {
    Write-Error ".git/hooks directory not found. Are you in a git repo?"
    exit 1
}

if (!(Test-Path $hookSource)) {
    Write-Error "scripts/pre-commit.ps1 not found."
    exit 1
}

Copy-Item -Path $hookSource -Destination $hookTarget -Force
Write-Host "Pre-commit hook installed at $hookTarget" -ForegroundColor Green
