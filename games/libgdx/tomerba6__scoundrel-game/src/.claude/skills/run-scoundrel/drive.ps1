<#
  Drives the running Scoundrel desktop window (libGDX / LWJGL3) from outside:
  screenshots the client area and sends real mouse clicks via Win32.

  Why this exists: `gradlew lwjgl3:run` opens a native OS window. There is no
  DOM, no accessibility tree, and no built-in remote control, so the only way an
  agent can verify UI work is to screenshot pixels and synthesise clicks.

  Usage (see SKILL.md for the full flow):
    drive.ps1 -WaitSeconds 240 -Actions "shot:C:\out\title.png"
    drive.ps1 -Actions "click:640:346,wait:1000,shot:C:\out\picker.png"
    drive.ps1 -Kill

  Coordinates are CLIENT pixels, origin TOP-LEFT. The game launches
  borderless-fullscreen, so press F11 first to get the 1280x720 window these
  coordinates assume. At that size the PixelViewport world is also 1280x720, so
  they map 1:1 -- but world Y points UP while client Y points DOWN:
      client_y = 720 - world_y
#>
param(
  [string]$Actions = "",
  [int]$WaitSeconds = 0,
  [switch]$Kill
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll", CharSet=CharSet.Auto)] public static extern IntPtr FindWindow(string c, string n);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, IntPtr pid);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool attach);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint f, IntPtr e);
  [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint mapType);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int hh, bool repaint);
  public struct RECT { public int Left, Top, Right, Bottom; }
  public struct POINT { public int X, Y; }
}
"@

# Must precede any coordinate work: without it Windows lies about sizes and
# positions on a scaled display, and every click lands in the wrong place.
[void][W]::SetProcessDPIAware()

function Get-GameWindow {
  # FindWindow races the window's creation during startup; the process list is
  # the reliable fallback once the JVM is up.
  $h = [W]::FindWindow($null, "Scoundrel")
  if ($h -ne [IntPtr]::Zero) { return $h }
  $p = Get-Process -ErrorAction SilentlyContinue |
       Where-Object { $_.MainWindowTitle -eq "Scoundrel" } | Select-Object -First 1
  if ($p) { return $p.MainWindowHandle }
  return [IntPtr]::Zero
}

if ($Kill) {
  $procs = Get-Process -ErrorAction SilentlyContinue |
           Where-Object { $_.MainWindowTitle -eq "Scoundrel" }
  if ($procs) { $procs | Stop-Process -Force; Write-Output "KILLED" }
  else { Write-Output "NOT_RUNNING" }
  exit 0
}

$h = Get-GameWindow
if ($h -eq [IntPtr]::Zero -and $WaitSeconds -gt 0) {
  $deadline = (Get-Date).AddSeconds($WaitSeconds)
  do {
    Start-Sleep -Milliseconds 2000
    $h = Get-GameWindow
  } while ($h -eq [IntPtr]::Zero -and (Get-Date) -lt $deadline)
}
if ($h -eq [IntPtr]::Zero) { Write-Output "WINDOW_NOT_FOUND"; exit 2 }

# Plain SetForegroundWindow is refused when the caller isn't the foreground
# process; without this the first synthesised click is swallowed activating the
# window instead of pressing the button under it.
function Activate([IntPtr]$hwnd) {
  # Windows can still refuse the raise (foreground lock, another app grabbing
  # focus). One attempt is not enough in practice, so try a few times.
  for ($i = 0; $i -lt 5; $i++) {
    if ([W]::GetForegroundWindow() -eq $hwnd) { return $true }
    $tidFg = [W]::GetWindowThreadProcessId([W]::GetForegroundWindow(), [IntPtr]::Zero)
    $tidMe = [W]::GetCurrentThreadId()
    [void][W]::AttachThreadInput($tidMe, $tidFg, $true)
    [void][W]::ShowWindow($hwnd, 9)   # SW_RESTORE
    [void][W]::BringWindowToTop($hwnd)
    [void][W]::SetForegroundWindow($hwnd)
    [void][W]::AttachThreadInput($tidMe, $tidFg, $false)
    Start-Sleep -Milliseconds 400
  }
  return ([W]::GetForegroundWindow() -eq $hwnd)
}

# Refuse to work blind. If the game is not actually in front, clicks land on
# whatever is (an IDE, a browser) and screenshots capture that instead -- which
# looks like a game that ignored the input rather than like a targeting failure,
# and has twice produced confident measurements of the wrong window.
if (-not (Activate $h)) {
  Write-Output "NOT_FOREGROUND - the Scoundrel window could not be raised; refusing to click or capture"
  exit 3
}

$rect = New-Object W+RECT
[void][W]::GetClientRect($h, [ref]$rect)
$origin = New-Object W+POINT
$origin.X = 0; $origin.Y = 0
[void][W]::ClientToScreen($h, [ref]$origin)
$cw = $rect.Right - $rect.Left
$ch = $rect.Bottom - $rect.Top
Write-Output ("CLIENT {0}x{1} at screen {2},{3}" -f $cw, $ch, $origin.X, $origin.Y)

function Shot([string]$path) {
  $dir = Split-Path -Parent $path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
  $bmp = New-Object System.Drawing.Bitmap $cw, $ch
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($origin.X, $origin.Y, 0, 0, (New-Object System.Drawing.Size $cw, $ch))
  $g.Dispose()
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Output ("SHOT {0}" -f $path)
}

function Click([int]$x, [int]$y) {
  [void][W]::SetCursorPos($origin.X + $x, $origin.Y + $y)
  Start-Sleep -Milliseconds 150
  [W]::mouse_event(0x0002, 0, 0, 0, [IntPtr]::Zero)   # LEFTDOWN
  Start-Sleep -Milliseconds 90
  [W]::mouse_event(0x0004, 0, 0, 0, [IntPtr]::Zero)   # LEFTUP
  Start-Sleep -Milliseconds 120
  Write-Output ("CLICK {0},{1}" -f $x, $y)
}

# The two halves of a click, separately, so a held button can be screenshotted.
# Menu buttons act on release and draw themselves sunk while held, and a whole
# Click is over long before a Shot could catch that. Pair them with move: to
# drive a press that slides off its button and is taken back.
function Down([int]$x, [int]$y) {
  [void][W]::SetCursorPos($origin.X + $x, $origin.Y + $y)
  Start-Sleep -Milliseconds 150
  [W]::mouse_event(0x0002, 0, 0, 0, [IntPtr]::Zero)   # LEFTDOWN
  Start-Sleep -Milliseconds 120
  Write-Output ("DOWN {0},{1}" -f $x, $y)
}

# A negative x means release where the pointer already is.
function Up([int]$x, [int]$y) {
  if ($x -ge 0) {
    [void][W]::SetCursorPos($origin.X + $x, $origin.Y + $y)
    Start-Sleep -Milliseconds 150
  }
  [W]::mouse_event(0x0004, 0, 0, 0, [IntPtr]::Zero)   # LEFTUP
  Start-Sleep -Milliseconds 120
  Write-Output ("UP {0},{1}" -f $x, $y)
}

# Debug and view-toggle bindings are polled per frame by the game (F11 fullscreen,
# F9 the sprite inspector, Esc to leave a screen), so they need real key events
# rather than clicks. Named rather than numeric so actions stay readable.
$VK = @{
  "ESC" = 0x1B; "ENTER" = 0x0D; "SPACE" = 0x20; "TAB" = 0x09; "R" = 0x52; "K" = 0x4B; "S" = 0x53; "B" = 0x42; "A" = 0x41; "E" = 0x45; "D" = 0x44; "H" = 0x48; "P" = 0x50; "X" = 0x58;
  "F1" = 0x70; "F2" = 0x71; "F3" = 0x72; "F4" = 0x73; "F5" = 0x74; "F6" = 0x75;
  "F7" = 0x76; "F8" = 0x77; "F9" = 0x78; "F10" = 0x79; "F11" = 0x7A; "F12" = 0x7B
}

# Resize to a target CLIENT size, for checking layout across window sizes.
# MoveWindow sizes the whole window including any border, so measure the
# difference and compensate -- asking for 1600x900 and silently getting a
# 1584x861 client would quietly invalidate whatever the shot is meant to prove.
function Resize([int]$targetW, [int]$targetH) {
  $wr = New-Object W+RECT; [void][W]::GetWindowRect($h, [ref]$wr)
  $cr = New-Object W+RECT; [void][W]::GetClientRect($h, [ref]$cr)
  $chromeW = ($wr.Right - $wr.Left) - ($cr.Right - $cr.Left)
  $chromeH = ($wr.Bottom - $wr.Top) - ($cr.Bottom - $cr.Top)
  [void][W]::MoveWindow($h, $wr.Left, $wr.Top, $targetW + $chromeW, $targetH + $chromeH, $true)
  Start-Sleep -Milliseconds 700
  $after = New-Object W+RECT; [void][W]::GetClientRect($h, [ref]$after)
  $aw = $after.Right - $after.Left; $ah = $after.Bottom - $after.Top
  # Later Shot calls must use the new size, not the one read at startup.
  $script:cw = $aw; $script:ch = $ah
  $o = New-Object W+POINT; $o.X = 0; $o.Y = 0
  [void][W]::ClientToScreen($h, [ref]$o)
  $script:origin = $o
  Write-Output ("RESIZE client {0}x{1} at screen {2},{3}" -f $aw, $ah, $o.X, $o.Y)
}

function Key([string]$name) {
  $n = $name.ToUpper()
  # Any single letter is its own virtual-key code, so the table only has to
  # carry the named keys. It used to list the letters too, and adding a lab
  # binding then meant editing this file before the key would do anything.
  if ((-not $VK.ContainsKey($n)) -and $n -match '^[A-Z0-9]$') {
    $VK[$n] = [int][char]$n
  }
  if (-not $VK.ContainsKey($n)) { Write-Output ("UNKNOWN KEY {0}" -f $name); return }
  $code = [byte]$VK[$n]
  # Send the real scan code rather than 0. GLFW does map a zero scancode back
  # via MapVirtualKey, but it calls that path a HACK for synthetic messages, so
  # supplying the true one keeps us on its normal route. Note this is NOT what
  # makes a press land -- see the swallowed-first-key note in SKILL.md.
  $scan = [byte]([W]::MapVirtualKey([uint32]$code, 0))   # MAPVK_VK_TO_VSC
  [W]::keybd_event($code, $scan, 0, [IntPtr]::Zero)      # down
  Start-Sleep -Milliseconds 90
  [W]::keybd_event($code, $scan, 2, [IntPtr]::Zero)      # KEYEVENTF_KEYUP
  Start-Sleep -Milliseconds 150
  Write-Output ("KEY {0} (vk 0x{1:X2} scan 0x{2:X2})" -f $n, $code, $scan)
}

foreach ($a in $Actions.Split(",")) {
  if ($a -eq "") { continue }
  # Split on the FIRST colon only -- screenshot paths contain "C:\".
  if ($a.StartsWith("shot:")) {
    Shot $a.Substring(5)
  } elseif ($a.StartsWith("click:")) {
    $c = $a.Substring(6).Split(":")
    Click ([int]$c[0]) ([int]$c[1])
  } elseif ($a.StartsWith("down:")) {
    $d = $a.Substring(5).Split(":")
    Down ([int]$d[0]) ([int]$d[1])
  } elseif ($a -eq "up") {
    Up -1 -1
  } elseif ($a.StartsWith("up:")) {
    $u = $a.Substring(3).Split(":")
    Up ([int]$u[0]) ([int]$u[1])
  } elseif ($a.StartsWith("move:")) {
    # Cursor move with no button, for hover states.
    $m = $a.Substring(5).Split(":")
    [void][W]::SetCursorPos($origin.X + [int]$m[0], $origin.Y + [int]$m[1])
    Start-Sleep -Milliseconds 200
    Write-Output ("MOVE {0},{1}" -f $m[0], $m[1])
  } elseif ($a.StartsWith("resize:")) {
    $r = $a.Substring(7).Split(":")
    Resize ([int]$r[0]) ([int]$r[1])
  } elseif ($a.StartsWith("key:")) {
    Key $a.Substring(4)
  } elseif ($a.StartsWith("wait:")) {
    Start-Sleep -Milliseconds ([int]$a.Substring(5))
    Write-Output ("WAIT {0}" -f $a.Substring(5))
  } else {
    Write-Output ("UNKNOWN ACTION {0}" -f $a)
  }
}
