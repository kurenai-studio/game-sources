param([Parameter(Mandatory=$true)][string]$InputFile,
      [Parameter(Mandatory=$true)][string]$OutputFile,
      [Parameter(Mandatory=$true)][string]$SamplesFile)
$ErrorActionPreference = 'Stop'
[System.Diagnostics.Process]::GetCurrentProcess().PriorityClass = 'BelowNormal'
Add-Type -Path (Join-Path $PSScriptRoot 'AuditRunner.cs')
[DerbyAudit]::Run((Resolve-Path -LiteralPath $InputFile).Path,
    [System.IO.Path]::GetFullPath($OutputFile), [System.IO.Path]::GetFullPath($SamplesFile))
