# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# Installs build\forkline-debug.apk on the Android phone connected by USB.
# An installed copy is replaced and its saved game is kept.
#
# Run from any folder:
#   powershell -ExecutionPolicy Bypass -File scripts\install.ps1
#
# adb comes from C:\Android\Sdk\platform-tools. Set the ADB environment
# variable to use another adb.exe. With more than one device connected, set
# ANDROID_SERIAL to the serial number "adb devices" shows for the phone.

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$Adb = if ($env:ADB) { $env:ADB } else { 'C:\Android\Sdk\platform-tools\adb.exe' }
$Apk = Join-Path $Root 'build\forkline-debug.apk'

if (-not (Test-Path $Adb)) {
    Write-Host "adb was not found at $Adb. Install Android SDK Platform-Tools there, or set ADB to the full path of adb.exe."
    exit 1
}
if (-not (Test-Path $Apk)) {
    Write-Host "There is no APK at $Apk. Build it first: powershell -ExecutionPolicy Bypass -File scripts\build.ps1"
    exit 1
}

# "adb devices" prints a header, then one "serial<TAB>state" line per device.
$Lines = & $Adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }
if ($LASTEXITCODE -ne 0) {
    Write-Host 'adb could not list devices.'
    exit 1
}
$Devices = @($Lines | ForEach-Object { $Parts = $_ -split '\s+'; [pscustomobject]@{ Serial = $Parts[0]; State = $Parts[1] } })
if ($env:ANDROID_SERIAL) {
    $Devices = @($Devices | Where-Object { $_.Serial -eq $env:ANDROID_SERIAL })
}
$Ready = @($Devices | Where-Object { $_.State -eq 'device' })

if ($Devices.Count -eq 0) {
    Write-Host 'No Android device is connected.'
    Write-Host 'Plug the phone in with a USB data cable, unlock it, and check that USB debugging is on in its developer options. Then run this again.'
    exit 1
}
if ($Ready.Count -eq 0) {
    $States = ($Devices | ForEach-Object { "$($_.Serial) is $($_.State)" }) -join ', '
    Write-Host "A device is connected but not ready: $States."
    Write-Host 'If it says unauthorized: unlock the phone and tap Allow on the "Allow USB debugging?" prompt. If it says offline: unplug the cable and plug it in again. Then run this again.'
    exit 1
}
if ($Ready.Count -gt 1) {
    Write-Host 'More than one device is ready. Unplug the others, or set ANDROID_SERIAL to the phone''s serial number:'
    $Ready | ForEach-Object { Write-Host "  $($_.Serial)" }
    exit 1
}

Write-Host "Installing on $($Ready[0].Serial)..."
& $Adb -s $Ready[0].Serial install -r $Apk
if ($LASTEXITCODE -ne 0) {
    Write-Host 'The install failed. If adb says INSTALL_FAILED_UPDATE_INCOMPATIBLE, the copy on the phone was signed by another computer: uninstall Forkline on the phone (this deletes its saved game) and run this again.'
    exit 1
}
Write-Host 'Installed. Open Forkline from the phone''s app list.'
exit 0
