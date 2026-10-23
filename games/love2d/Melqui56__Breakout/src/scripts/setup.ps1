<#
.SYNOPSIS
  setup.ps1 — Install LÖVE 2D on Windows.
.DESCRIPTION
  Tries winget first; if unavailable or it fails, downloads the official
  portable zip from GitHub and extracts it to %LOCALAPPDATA%\love.
.USAGE
  powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
#>
$ErrorActionPreference = "Stop"

$LoveVersion = "11.5"
$InstallDir  = Join-Path $env:LOCALAPPDATA "love"
$LoveExe     = Join-Path $InstallDir "love.exe"

function Install-FromZip {
    Write-Host "==> Downloading LÖVE $LoveVersion (portable zip)..."
    $zip = Join-Path $env:TEMP "love-$LoveVersion.zip"
    Invoke-WebRequest -Uri "https://github.com/love2d/love/releases/download/$LoveVersion/love-$LoveVersion-win64.zip" -OutFile $zip
    if (Test-Path $InstallDir) { Remove-Item -Recurse -Force $InstallDir }
    Expand-Archive -Path $zip -DestinationPath $InstallDir
    $inner = Get-ChildItem $InstallDir | Select-Object -First 1
    if ($inner -and $inner.PSIsContainer) {
        Get-ChildItem $inner.FullName | Move-Item -Destination $InstallDir -Force
        Remove-Item -Recurse -Force $inner.FullName
    }
    Write-Host "==> LÖVE installed at: $LoveExe"
}

$winget = Get-Command winget -ErrorAction SilentlyContinue
if ($winget) {
    Write-Host "==> Trying winget..."
    try {
        winget install --id Love2d.Love2d --exact --silent --accept-source-agreements --accept-package-agreements
        Write-Host "==> LÖVE installed via winget."
        exit 0
    } catch {
        Write-Host "==> winget failed; falling back to direct download."
    }
} else {
    Write-Host "==> winget not available; using direct download."
}

Install-FromZip

if (Test-Path $LoveExe) {
    Write-Host "==> Ready. Run: scripts\run.ps1"
} else {
    Write-Host "==> LÖVE was not found at $LoveExe — check the output above."
}
