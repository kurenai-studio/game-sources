<#
.SYNOPSIS
  run.ps1 — Run the Breakout project with LÖVE (Windows).
.USAGE
  powershell -ExecutionPolicy Bypass -File scripts/run.ps1
#>
$ErrorActionPreference = "Stop"

$LoveExe = Join-Path $env:LOCALAPPDATA "love\love.exe"
if (-not (Test-Path $LoveExe)) {
    $LoveExe = "love"   # assume LÖVE is on PATH (winget install)
}

$ProjectRoot = Split-Path -Parent $PSScriptRoot
& $LoveExe $ProjectRoot
