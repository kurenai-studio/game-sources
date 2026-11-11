param([string]$SeedFile='test-results/algorithm-audit/training-seeds.txt',
      [string]$OutputFile='test-results/algorithm-audit/training.csv')
$ErrorActionPreference='Stop'
[System.Diagnostics.Process]::GetCurrentProcess().PriorityClass='BelowNormal'
Add-Type -Path (Join-Path $PSScriptRoot 'AuditRunner.cs')
[DerbyAudit]::Fit((Resolve-Path -LiteralPath $SeedFile).Path,[System.IO.Path]::GetFullPath($OutputFile))
