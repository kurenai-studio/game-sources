param(
    [string]$Launcher = (Join-Path $PSScriptRoot '../scripts/Movement-Preview.ps1'),
    [string]$TestDirectory = (Join-Path $PSScriptRoot '../test-results/launcher-lifecycle')
)
New-Item -ItemType Directory -Path $TestDirectory -Force | Out-Null
$ErrorActionPreference = 'Stop'
$engine = Join-Path $TestDirectory 'DelayedGuiEngine.exe'
$marker = Join-Path $TestDirectory 'finished.txt'
if (-not (Test-Path -LiteralPath $engine)) {
    Add-Type -OutputAssembly $engine -OutputType WindowsApplication -TypeDefinition @"
using System;
using System.IO;
using System.Threading;
public static class DelayedGuiEngine {
    public static void Main(string[] args) {
        Thread.Sleep(2000);
        File.WriteAllText(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "finished.txt"), "finished");
        Environment.Exit(17);
    }
}
"@
}
if (Test-Path -LiteralPath $marker) { Remove-Item -LiteralPath $marker }
$timer = [Diagnostics.Stopwatch]::StartNew()
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Launcher -Godot $engine
$launcherCode = $LASTEXITCODE
$timer.Stop()
$waited = Test-Path -LiteralPath $marker
Write-Output ("Launcher waited for engine: {0}; reported failure: {1}; elapsed milliseconds: {2}" -f $waited, ($launcherCode -ne 0), $timer.ElapsedMilliseconds)
if (-not $waited -or $launcherCode -eq 0) { exit 1 }
exit 0

