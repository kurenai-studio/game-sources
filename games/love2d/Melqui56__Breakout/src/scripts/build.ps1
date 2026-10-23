<#
.SYNOPSIS
  build.ps1 — Package the portable versions of Breakout (Windows).
.DESCRIPTION
  Produces in .\dist:
    Breakout.love            portable game package (any OS with LÖVE)
    Breakout-win64\Breakout.exe  self-contained Windows executable (love.exe + .love)
    Breakout-win64.zip       zipped portable Windows build
.USAGE
  powershell -ExecutionPolicy Bypass -File scripts\build.ps1
#>
$ErrorActionPreference = "Stop"

$LoveVersion = "11.5"
$Root  = Split-Path -Parent $PSScriptRoot
$Dist  = Join-Path $Root "dist"
$Name  = "Breakout"
New-Item -ItemType Directory -Force -Path $Dist | Out-Null

# 1) Portable .love package (zip renamed to .love).
$loveZip = Join-Path $Dist "$Name.zip"
$loveFile = Join-Path $Dist "$Name.love"
if (Test-Path $loveFile) { Remove-Item $loveFile }
Compress-Archive -Path (Join-Path $Root "main.lua"), (Join-Path $Root "conf.lua"), (Join-Path $Root "src") -DestinationPath $loveZip -Force
Rename-Item $loveZip $loveFile

# 2) love.exe (download portable LÖVE if needed).
$loveBase = Join-Path $env:LOCALAPPDATA "love"
$loveExe  = Join-Path $loveBase "love.exe"
if (-not (Test-Path $loveExe)) {
    Write-Host "==> Downloading LÖVE $LoveVersion (portable)..."
    $zip = Join-Path $env:TEMP "love-$LoveVersion-win64.zip"
    Invoke-WebRequest -Uri "https://github.com/love2d/love/releases/download/$LoveVersion/love-$LoveVersion-win64.zip" -OutFile $zip
    if (Test-Path $loveBase) { Remove-Item -Recurse -Force $loveBase }
    Expand-Archive -Path $zip -DestinationPath $loveBase
    $inner = Get-ChildItem $loveBase | Select-Object -First 1
    if ($inner -and $inner.PSIsContainer) {
        Get-ChildItem $inner.FullName | Move-Item -Destination $loveBase -Force
        Remove-Item -Recurse -Force $inner.FullName
    }
}

# 3) Self-contained Breakout.exe (love.exe + game.love) and zip.
$winDir = Join-Path $Dist "${Name}-win64"
New-Item -ItemType Directory -Force -Path $winDir | Out-Null
Copy-Item $loveExe $winDir
Copy-Item $loveFile $winDir
$gameExe = Join-Path $winDir "$Name.exe"
Copy-Item $loveExe $gameExe
$bytes = [System.IO.File]::ReadAllBytes($loveFile)
$stream = [System.IO.File]::Open($gameExe, "Append")
$stream.Write($bytes, 0, $bytes.Length)
$stream.Close()
Compress-Archive -Path $winDir -DestinationPath (Join-Path $Dist "${Name}-win64.zip") -Force

Write-Host ""
Write-Host "==> Built artifacts in $Dist :"
Get-ChildItem $Dist -Filter "$Name*" | Select-Object Name, Length
Write-Host ""
Write-Host "    Windows portable : run $gameExe (or unzip ${Name}-win64.zip)"
Write-Host "    Any OS with love  : love $loveFile"
