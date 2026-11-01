# Builds the onefile exe and stages the distributable folder:
#
#   dist\Rhythm Fest.exe        windowed (no console), upx disabled
#   dist\music_levels\...       levels + audio copied BESIDE the exe
#
# stats.dat / settings.json are deliberately never copied - the exe
# creates fresh ones next to itself on the receiving machine.
#
# Usage (from anywhere):  powershell -File tools\package.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot   # repo root

Push-Location $root
try {
    python -m PyInstaller "Rhythm Fest.spec" --noconfirm
    if ($LASTEXITCODE -ne 0) { throw "PyInstaller failed (exit $LASTEXITCODE)" }

    $src = Join-Path $root "music_levels"
    $dst = Join-Path $root "dist\music_levels"
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    $files = Get-ChildItem $src -File |
        Where-Object { $_.Extension -in ".json", ".mp3", ".wav" }
    $files | Copy-Item -Destination $dst -Force

    $mb = [math]::Round((Get-Item (Join-Path $root "dist\Rhythm Fest.exe")).Length / 1MB, 1)
    Write-Host "OK  dist\Rhythm Fest.exe ($mb MB)"
    Write-Host "OK  dist\music_levels ($($files.Count) files) - no stats.dat / settings.json"
}
finally {
    Pop-Location
}
