# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# Builds the debug APK: build\forkline-debug.apk
# Works from a fresh clone or worktree in one command. It imports the project
# itself (retrying a crashed import), exports with a private temp folder, and
# only reports success when a new, readable APK exists. Any failure exits 1.
#
# Run from any folder:
#   powershell -ExecutionPolicy Bypass -File scripts\build.ps1
#
# Godot 4.7.2 must be on PATH as "godot", or set the GODOT environment variable
# to the full path of the Godot exe. The Android SDK, the JDK and the debug
# keystore come from Godot's Editor Settings, never from this repo.

param([switch]$AllowDirty)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$Godot = if ($env:GODOT) { $env:GODOT } else { 'godot' }
$Apk = Join-Path $Root 'build\forkline-debug.apk'
$ClassCache = Join-Path $Root '.godot\global_script_class_cache.cfg'
$WantVersion = '4.7.2.stable'
$Attempts = 3
$Started = (Get-Date).ToUniversalTime().AddSeconds(-2)

function Stop-Build([string]$Message) {
    Write-Host "BUILD FAILED: $Message"
    exit 1
}

# Runs Godot in this console, waits up to $Seconds, and returns its exit code.
# A run that goes over the time is ended by its own process id, and returns -1.
function Invoke-Godot([int]$Seconds, [string[]]$GodotArgs) {
    $Quoted = $GodotArgs | ForEach-Object { '"' + $_ + '"' }
    $Proc = Start-Process -FilePath $Godot -ArgumentList $Quoted -NoNewWindow -PassThru
    $null = $Proc.Handle   # keeps the handle open so ExitCode is readable
    if (-not $Proc.WaitForExit($Seconds * 1000)) {
        Stop-Process -Id $Proc.Id -Force
        return -1
    }
    $Proc.WaitForExit()
    return $Proc.ExitCode
}

if (-not (Get-Command $Godot -ErrorAction SilentlyContinue)) {
    Stop-Build "Godot was not found as '$Godot'. Install Godot $WantVersion or set GODOT to the full path of its exe."
}

$Version = (& $Godot --version | Out-String).Trim()
if (-not $Version.StartsWith($WantVersion)) {
    Stop-Build "This project needs Godot $WantVersion, but '$Godot' is version '$Version'."
}
Write-Host "Godot $Version"

# Build only from a commit. A folder without .git (a copy made with git archive)
# cannot be checked and is clean by construction.
if (Test-Path (Join-Path $Root '.git')) {
    $Changes = @(& git -C $Root status --porcelain 2>$null)
    if ($LASTEXITCODE -ne 0) {
        Stop-Build 'git status failed, so the tree cannot be checked.'
    }
    if ($Changes.Count -gt 0) {
        Write-Host "The working tree has $($Changes.Count) uncommitted change(s):"
        $Changes | Select-Object -First 15 | ForEach-Object { Write-Host $_ }
        if ($Changes.Count -gt 15) { Write-Host "... and $($Changes.Count - 15) more." }
        if ($AllowDirty) {
            Write-Host 'WARNING: building from a dirty tree (-AllowDirty). Do not publish this build.'
        } else {
            Stop-Build 'the working tree is not clean. Commit first, build from a clean clone, or add -AllowDirty for a local test build.'
        }
    } else {
        Write-Host "Working tree is clean. Commit: $((& git -C $Root rev-parse HEAD) | Out-String)".Trim()
    }
} else {
    Write-Host 'Not a git checkout: taken to be a clean copy of a commit.'
}

# Import until Godot has written its class cache. The first import of a fresh
# project can crash or stop early, and a rerun finishes the job.
Write-Host 'Importing the project...'
$Imported = $false
for ($n = 1; $n -le $Attempts; $n++) {
    if (Test-Path $ClassCache) { Remove-Item -Force $ClassCache }
    $Code = Invoke-Godot 300 @('--headless', '--path', $Root, '--import')
    if ($Code -eq 0 -and (Test-Path $ClassCache) -and (Get-Item $ClassCache).Length -gt 0) {
        $Imported = $true
        break
    }
    Write-Host "Import attempt $n of $Attempts did not finish (exit code $Code)."
}
if (-not $Imported) {
    Stop-Build "the import did not finish after $Attempts attempts. Read the Godot output above."
}

# Godot names its temporary export files with the clock in whole seconds, in the
# shared temp folder. Two exports that start in the same second (another Godot
# project, or a second copy of this script) overwrite each other's files. A
# private temp folder for this build stops that.
$BuildDir = Split-Path -Parent $Apk
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
$ExportTmp = Join-Path $BuildDir ('tmp.' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $ExportTmp | Out-Null
$OldTemp = $env:TEMP
$OldTmp = $env:TMP

Write-Host 'Exporting the debug APK...'
$Built = $false
try {
    $env:TEMP = $ExportTmp
    $env:TMP = $ExportTmp
    for ($n = 1; $n -le $Attempts; $n++) {
        Remove-Item -Force -ErrorAction SilentlyContinue $Apk, "$Apk.idsig"
        $Code = Invoke-Godot 600 @('--headless', '--path', $Root, '--export-debug', 'Android', $Apk)
        # A good APK: Godot exited 0, the file is new, over 1 MB, and a valid zip.
        if ($Code -eq 0 -and (Test-Path $Apk)) {
            $Item = Get-Item $Apk
            $Entries = 0
            try {
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                $Zip = [System.IO.Compression.ZipFile]::OpenRead($Apk)
                $Entries = $Zip.Entries.Count
                $Zip.Dispose()
            } catch {
                $Entries = 0
            }
            if ($Item.LastWriteTimeUtc -ge $Started -and $Item.Length -gt 1MB -and $Entries -gt 0) {
                $Built = $true
                break
            }
        }
        Write-Host "Export attempt $n of $Attempts failed (exit code $Code)."
        Remove-Item -Force -ErrorAction SilentlyContinue $Apk
    }
} finally {
    $env:TEMP = $OldTemp
    $env:TMP = $OldTmp
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $ExportTmp
}
if (-not $Built) {
    Stop-Build "the export did not produce a good APK after $Attempts attempts. Read the Godot output above."
}

$SizeMb = [math]::Round((Get-Item $Apk).Length / 1MB, 1)
Write-Host "Built $Apk ($SizeMb MB)"
Write-Host 'Check it with: scripts/check_apk.sh (in Git Bash)'
Write-Host 'Install it with: powershell -ExecutionPolicy Bypass -File scripts\install.ps1'
exit 0
