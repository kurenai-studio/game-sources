# Astro Drift gameplay video capture.
# For each engine: launch the game, find its window, get its screen rect via
# Win32 GetWindowRect, then record the rect with ffmpeg gdigrab while driving
# the ship with keybd_event keystrokes. Output: docs/videos/<engine>.webm.

$ErrorActionPreference = "Continue"
$WarningPreference = "SilentlyContinue"

$ffmpeg = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
$godot  = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64.exe"
$love   = "C:\Program Files\LOVE\love.exe"
$python = (Get-Command python).Source
$repo   = "C:\Users\armah\projects\astro-drift"
$videosDir = "$repo\docs\videos"
$logDir = "$env:TEMP\astro-drift-capture"
New-Item -ItemType Directory -Path $videosDir -Force | Out-Null
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, IntPtr extra);
    public const int SW_RESTORE = 9;
    public const byte VK_LEFT = 0x25, VK_UP = 0x26, VK_RIGHT = 0x27, VK_DOWN = 0x28;
    public const byte VK_DELETE = 0x2E, VK_INSERT = 0x2D, VK_END = 0x23;
    public const uint KEYUP = 0x2;
}
"@ 2>&1 | Out-Null

function KeyDown([byte]$vk) { [W]::keybd_event($vk, 0, 0, [IntPtr]::Zero) }
function KeyUp([byte]$vk)   { [W]::keybd_event($vk, 0, [W]::KEYUP, [IntPtr]::Zero) }
function Tap([byte]$vk) {
    KeyDown $vk
    Start-Sleep -Milliseconds 60
    KeyUp $vk
}

function Find-Window([string]$pattern, [int]$timeoutSec = 12) {
    $deadline = (Get-Date).AddSeconds($timeoutSec)
    while ((Get-Date) -lt $deadline) {
        $p = Get-Process | Where-Object {
            $_.MainWindowTitle -ne "" -and $_.MainWindowTitle -match $pattern
        } | Select-Object -First 1
        if ($p) { return $p }
        Start-Sleep -Milliseconds 400
    }
    return $null
}

function Capture-Engine([string]$name, [scriptblock]$launch, [string]$titlePattern, [scriptblock]$drive) {
    Write-Host "`n=== $name ===" -ForegroundColor Yellow
    $proc = & $launch
    $win = Find-Window $titlePattern 12
    if (-not $win) {
        Write-Host "  window not found" -ForegroundColor Red
        if ($proc) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
        return
    }
    Write-Host "  window: '$($win.MainWindowTitle)'"
    [W]::ShowWindow($win.MainWindowHandle, [W]::SW_RESTORE) | Out-Null
    [W]::SetForegroundWindow($win.MainWindowHandle) | Out-Null
    Start-Sleep -Milliseconds 900

    $rect = New-Object 'W+RECT'
    [W]::GetWindowRect($win.MainWindowHandle, [ref]$rect) | Out-Null
    $x = $rect.L; $y = $rect.T
    $w = $rect.R - $rect.L; $h = $rect.B - $rect.T
    if ($w % 2 -ne 0) { $w-- }
    if ($h % 2 -ne 0) { $h-- }
    Write-Host "  rect: ${w}x${h} at ($x,$y)"

    $out = "$videosDir\$name.webm"
    $log = "$logDir\$name.log"
    $args = @(
        "-y", "-loglevel", "warning",
        "-f", "gdigrab", "-framerate", "30",
        "-offset_x", $x, "-offset_y", $y,
        "-video_size", "${w}x${h}",
        "-i", "desktop",
        "-t", "8",
        "-c:v", "libvpx-vp9", "-b:v", "1.4M", "-deadline", "good", "-cpu-used", "4",
        "-vf", "scale=720:-2,format=yuv420p",
        "-pix_fmt", "yuv420p",
        "-an", $out
    )
    $ff = Start-Process -FilePath $ffmpeg -ArgumentList $args -PassThru -WindowStyle Hidden `
        -RedirectStandardError $log
    Start-Sleep -Milliseconds 500

    # Refocus in case ffmpeg startup stole it
    [W]::SetForegroundWindow($win.MainWindowHandle) | Out-Null
    Start-Sleep -Milliseconds 200

    & $drive

    if (-not $ff.HasExited) { Wait-Process -Id $ff.Id -Timeout 30 -ErrorAction SilentlyContinue }
    Start-Sleep -Milliseconds 400
    Stop-Process -Id $win.Id -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 400

    if (Test-Path $out) {
        $sz = [math]::Round((Get-Item $out).Length / 1KB, 1)
        Write-Host "  OK: ${sz} KB" -ForegroundColor Green
    } else {
        Write-Host "  FAILED -- log: $log" -ForegroundColor Red
        if (Test-Path $log) { Get-Content $log -Tail 6 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray } }
    }
}

# Drive scripts: all-inline keybd_event calls so PowerShell parser stays happy

$driveAsteroidsGame = {
    # 1.0s thrust forward
    KeyDown ([W]::VK_UP); Start-Sleep -Milliseconds 1000; KeyUp ([W]::VK_UP)
    # 0.7s rotate-right + thrust
    KeyDown ([W]::VK_RIGHT); KeyDown ([W]::VK_UP); Start-Sleep -Milliseconds 700
    KeyUp ([W]::VK_RIGHT); KeyUp ([W]::VK_UP)
    # 4 quick shots
    1..4 | ForEach-Object {
        Tap ([W]::VK_DELETE); Start-Sleep -Milliseconds 130
    }
    # 0.6s rotate-left
    KeyDown ([W]::VK_LEFT); Start-Sleep -Milliseconds 600; KeyUp ([W]::VK_LEFT)
    # 0.8s thrust + 2 shots
    KeyDown ([W]::VK_UP); Start-Sleep -Milliseconds 400
    Tap ([W]::VK_DELETE); Start-Sleep -Milliseconds 200
    Tap ([W]::VK_DELETE); Start-Sleep -Milliseconds 200
    KeyUp ([W]::VK_UP)
    # Final rotation flourish
    KeyDown ([W]::VK_RIGHT); Start-Sleep -Milliseconds 800; KeyUp ([W]::VK_RIGHT)
    Tap ([W]::VK_DELETE); Start-Sleep -Milliseconds 200
    Tap ([W]::VK_DELETE)
}

$drivePyGame = {
    Tap ([W]::VK_INSERT)
    Start-Sleep -Seconds 7
}

$drivePanda3D = {
    KeyDown ([W]::VK_UP); Start-Sleep -Milliseconds 1500; KeyUp ([W]::VK_UP)
    KeyDown ([W]::VK_RIGHT); KeyDown ([W]::VK_UP); Start-Sleep -Milliseconds 1200
    KeyUp ([W]::VK_RIGHT); KeyUp ([W]::VK_UP)
    KeyDown ([W]::VK_LEFT); KeyDown ([W]::VK_UP); Start-Sleep -Milliseconds 1400
    KeyUp ([W]::VK_LEFT); KeyUp ([W]::VK_UP)
    KeyDown ([W]::VK_DOWN); Start-Sleep -Milliseconds 600; KeyUp ([W]::VK_DOWN)
    KeyDown ([W]::VK_UP); Start-Sleep -Milliseconds 1500; KeyUp ([W]::VK_UP)
}

# ----------- run -----------

Capture-Engine "godot" {
    Start-Process -FilePath $godot -ArgumentList @('--path', "$repo\godot") -PassThru
} "Astro Drift" $driveAsteroidsGame

Capture-Engine "love2d" {
    Start-Process -FilePath $love -ArgumentList @("$repo\love2d") -PassThru
} "Astro Drift" $driveAsteroidsGame

Capture-Engine "pygame" {
    $env:PYTHONUTF8 = "1"
    Start-Process -FilePath $python -ArgumentList @("$repo\pygame\main.py") -WorkingDirectory "$repo\pygame" -PassThru
} "Astro Drift" $drivePyGame

Capture-Engine "panda3d" {
    Start-Process -FilePath $python -ArgumentList @("$repo\panda3d\main.py") -WorkingDirectory "$repo\panda3d" -PassThru
} "Astro Drift" $drivePanda3D

Write-Host "`n=== DONE ===" -ForegroundColor Green
Get-ChildItem $videosDir | Select-Object Name, @{n='KB';e={[math]::Round($_.Length/1KB,1)}} | Format-Table -AutoSize
