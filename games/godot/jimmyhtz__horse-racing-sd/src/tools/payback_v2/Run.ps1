# Requires PowerShell 7 with modern .NET SHA256.HashData support.
param([ValidateSet('oracle','holdout')][string]$Run='oracle')
$ErrorActionPreference='Stop'
[Diagnostics.Process]::GetCurrentProcess().PriorityClass='BelowNormal'
$root=Join-Path $PSScriptRoot '../..'
$results=Join-Path $root 'test-results/payback-v2'
Add-Type -Path (Join-Path $PSScriptRoot 'Runner.cs')
[PaybackCandidateRunner]::Run((Join-Path $results "$Run-input.csv"),
    (Join-Path $results 'config.csv'),(Join-Path $results "$Run-fast.csv"),
    (Join-Path $results "$Run-fast-samples.csv"))
