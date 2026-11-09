$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "build\web"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$godot = Get-Command godot -ErrorAction SilentlyContinue
if (-not $godot) {
  Write-Error "Godot לא נמצא ב-PATH. התקן Godot 4.7 והוסף export template ל-Web."
}
& godot --headless --path $root --export-release "Web" (Join-Path $outDir "index.html")
Write-Host "Web build: $outDir"
