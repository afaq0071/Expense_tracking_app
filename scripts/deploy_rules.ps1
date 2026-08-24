#!/usr/bin/env pwsh
#
# deploy_rules.ps1 — Deploy Firestore security rules to Firebase.
#
# This script must be run from the project root (where firebase.json lives).
# It reads the project ID from .firebaserc and deploys only firestore.rules.
#
# Usage:
#   pwsh scripts/deploy_rules.ps1
#

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot | Split-Path -Parent
$rulesFile   = Join-Path $projectRoot "firestore.rules"

if (!(Test-Path $rulesFile)) {
    Write-Error "firestore.rules not found at $rulesFile"
    exit 1
}

# Find the Firebase CLI binary.
$firebaseBin = Join-Path $env:TEMP "opencode\firebase-cli\firebase.exe"
if (!(Test-Path $firebaseBin)) {
    # Fall back to a global install.
    $firebaseBin = "firebase"
}

Write-Host "Deploying Firestore rules from $rulesFile ..."
& $firebaseBin deploy --only firestore:rules --project myappbackend-4c522

if ($LASTEXITCODE -ne 0) {
    Write-Error "Firebase deploy failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "Firestore rules deployed successfully."
