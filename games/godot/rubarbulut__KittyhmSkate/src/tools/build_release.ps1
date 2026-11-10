param(
    [string]$Godot = $env:GODOT,
    [switch]$SkipTests
)
$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $ProjectRoot
if (-not $Godot) {
    $EngineCommand = Get-Command godot -ErrorAction SilentlyContinue
    if ($EngineCommand) { $Godot = $EngineCommand.Source }
    else { $Godot = Join-Path $env:USERPROFILE 'Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' }
}
if (-not (Test-Path -LiteralPath $Godot)) { throw 'Set GODOT or pass -Godot with the Godot 4.7.2 console executable.' }
New-Item -ItemType Directory -Force -Path 'exports/windows','exports/web','exports/packages','.qa' | Out-Null
if (-not $SkipTests) {
    foreach ($TestScript in @('smoke','tour','settings_calibration')) {
        $TestOutput = @(& $Godot --headless --path $ProjectRoot --script "res://tests/$TestScript.gd" 2>&1)
        $TestExit = $LASTEXITCODE
        $TestOutput | Out-File -FilePath ".qa/test-$TestScript.log" -Encoding utf8
        $TestOutput | Write-Output
        if ($TestExit -ne 0 -or ($TestOutput -match 'SCRIPT ERROR:|ERROR:|FAILED')) { throw "Test failed: $TestScript" }
    }
}
foreach ($Preset in @('Windows','Web')) {
    & $Godot --headless --quiet --path $ProjectRoot --export-release $Preset
    if ($LASTEXITCODE -ne 0) { throw "Export failed: $Preset" }
}
$PackAudit = @(& $Godot --headless --path "$ProjectRoot/exports/windows" --main-pack "$ProjectRoot/exports/windows/KittyhmSkate.pck" --script "$ProjectRoot/tests/audit_pack.gd" 2>&1)
$PackExit = $LASTEXITCODE
$PackAudit | Out-File -FilePath '.qa/test-packed-resources.log' -Encoding utf8
$PackAudit | Write-Output
if ($PackExit -ne 0 -or ($PackAudit -match 'SCRIPT ERROR:|ERROR:|FAILED')) { throw 'Packed game resource audit failed' }
$NativeLog = Join-Path $ProjectRoot '.qa/native-release.log'
$NativeArgs = '--headless --quit-after 120 --log-file "' + $NativeLog + '"'
$NativeRun = Start-Process -FilePath "$ProjectRoot/exports/windows/KittyhmSkate.exe" -ArgumentList $NativeArgs -WindowStyle Hidden -PassThru -Wait
if ($NativeRun.ExitCode -ne 0) { throw 'Native release boot failed' }
$NativeOutput = Get-Content -LiteralPath $NativeLog -Raw
if ($NativeOutput -match 'SCRIPT ERROR:|ERROR:') { throw 'Native release reported a runtime error' }
Write-Output 'PASS: native release process booted and exited cleanly'
foreach ($Directory in @('exports/windows','exports/web')) {
    Copy-Item -LiteralPath 'LICENSE','CREDITS.md','PLAYME.txt' -Destination $Directory
    Copy-Item -LiteralPath 'assets/fonts/OFL.txt' -Destination "$Directory/FONT-LICENSE.txt"
}
$WindowsFiles = @('KittyhmSkate.exe','KittyhmSkate.pck','LICENSE','CREDITS.md','FONT-LICENSE.txt','PLAYME.txt') | ForEach-Object { "exports/windows/$_" }
Compress-Archive -LiteralPath $WindowsFiles -DestinationPath 'exports/packages/KittyhmSkate-Windows.zip' -Force
$WebFiles = @(Get-ChildItem -LiteralPath 'exports/web' -File | Where-Object { $_.Name -match '^index\.[a-z.]+$' -or $_.Name -in @('LICENSE','CREDITS.md','FONT-LICENSE.txt','PLAYME.txt') } | Select-Object -ExpandProperty FullName)
Compress-Archive -LiteralPath $WebFiles -DestinationPath 'exports/packages/KittyhmSkate-Web.zip' -Force
python tools/audit_release.py
if ($LASTEXITCODE -ne 0) { throw 'Release archive audit failed' }
Get-FileHash -LiteralPath 'exports/packages/KittyhmSkate-Windows.zip','exports/packages/KittyhmSkate-Web.zip' -Algorithm SHA256 | Format-Table -AutoSize
