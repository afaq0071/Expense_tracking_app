#!/usr/bin/env pwsh
#
# pre-commit — Git pre-commit hook for this project.
#
# If firestore.rules is staged, deploys the rules to Firebase before
# the commit completes, so local and live rules can never drift apart.
#
# Install: copy or symlink to .git/hooks/pre-commit (no .exe extension).
#

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot | Split-Path -Parent
if (!$repoRoot) { $repoRoot = (Get-Location).Path }

# Check if firestore.rules is in the staged files.
$staged = git diff --cached --name-only 2>$null
if ($null -eq $staged) { exit 0 }

$rulesStaged = $staged | Where-Object { $_ -eq "firestore.rules" }
if (!$rulesStaged) { exit 0 }

$rulesFile = Join-Path $repoRoot "firestore.rules"
if (!(Test-Path $rulesFile)) { exit 0 }

# Find the Firebase CLI binary.
$firebaseBin = Join-Path $env:TEMP "opencode\firebase-cli\firebase.exe"
if (!(Test-Path $firebaseBin)) {
    $firebaseBin = "firebase"
}

Write-Host ""
Write-Host "[pre-commit] firestore.rules changed — deploying to Firebase ..." -ForegroundColor Cyan

& $firebaseBin deploy --only firestore:rules --project myappbackend-4c522

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[pre-commit] Firestore rules deploy FAILED — commit aborted." -ForegroundColor Red
    Write-Host "[pre-commit] Fix the issue and try again." -ForegroundColor Red
    exit 1
}

Write-Host "[pre-commit] Firestore rules deployed successfully." -ForegroundColor Green
exit 0
