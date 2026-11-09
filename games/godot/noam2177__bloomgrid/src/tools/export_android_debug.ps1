$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root "build\bloomgrid-debug.apk"
New-Item -ItemType Directory -Force -Path (Split-Path $out) | Out-Null
$godot = Get-Command godot -ErrorAction SilentlyContinue
if (-not $godot) {
  Write-Error "Godot לא ב-PATH. התקן Godot 4.7, הוסף Android export template, והגדר SDK ב-Editor Settings → Export → Android."
}
& godot --headless --path $root --export-debug "Android Debug APK" $out
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "APK: $out"
