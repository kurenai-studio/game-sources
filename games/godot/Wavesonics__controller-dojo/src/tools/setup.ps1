<#
.SYNOPSIS
Prepares a fresh clone for building and exporting.

.DESCRIPTION
Creates the per-platform export directories and restores the ControllerRumble
Android plugin into the generated build template. Safe to re-run; run it again
after any reinstall of the Android build template.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File tools\setup.ps1

.EXAMPLE
powershell -ExecutionPolicy Bypass -File tools\setup.ps1 -InstallAndroidTemplate
#>
[CmdletBinding()]
param(
	[switch]$InstallAndroidTemplate,
	[string]$Godot = "$env:APPDATA\itch\apps\godot\Godot_v4.7.1-stable_win64_console.exe"
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$androidNs   = 'http://schemas.android.com/apk/res/android'
$metaName    = 'org.godotengine.plugin.v2.ControllerRumble'
$metaValue   = 'com.godot.game.rumble.ControllerRumblePlugin'
$pluginSrc   = Join-Path $PSScriptRoot 'android\ControllerRumblePlugin.kt'
$buildDir    = Join-Path $root 'android\build'
$pluginDst   = Join-Path $buildDir 'src\main\java\com\godot\game\rumble\ControllerRumblePlugin.kt'
$manifest    = Join-Path $buildDir 'src\main\AndroidManifest.xml'

foreach ($platform in 'web', 'windows', 'linux', 'macos', 'android') {
	New-Item -ItemType Directory -Force (Join-Path $root ".export\$platform") | Out-Null
}
Write-Host "Export directories ready under .export\"

if ($InstallAndroidTemplate -or -not (Test-Path $buildDir)) {
	if (-not (Test-Path $Godot)) {
		throw "Godot not found at '$Godot'. Pass -Godot with the correct path."
	}
	Write-Host "Installing the Android build template..."
	$throwaway = Join-Path $root '.export\android\template_install.apk'
	& $Godot --headless --path $root --install-android-build-template --export-debug 'Android' $throwaway
	if ($LASTEXITCODE -ne 0) {
		throw "Godot exited $LASTEXITCODE while installing the Android build template."
	}
	Remove-Item $throwaway -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path $buildDir)) {
	Write-Host "No Android build template present; skipping the rumble plugin."
	Write-Host "Setup complete."
	return
}

New-Item -ItemType Directory -Force (Split-Path -Parent $pluginDst) | Out-Null
Copy-Item $pluginSrc $pluginDst -Force
Write-Host "Copied ControllerRumblePlugin.kt into the build template"

[xml]$doc = Get-Content -Raw $manifest
$application = $doc.SelectSingleNode('/manifest/application')
if (-not $application) {
	throw "No <application> element in '$manifest'."
}

$present = @($application.SelectNodes('meta-data')) |
	Where-Object { $_.GetAttribute('name', $androidNs) -eq $metaName }

if ($present) {
	Write-Host "Manifest already registers the plugin"
} else {
	$element = $doc.CreateElement('meta-data')
	$element.SetAttribute('name', $androidNs, $metaName)
	$element.SetAttribute('value', $androidNs, $metaValue)
	$application.AppendChild($element) | Out-Null
	$doc.Save($manifest)
	Write-Host "Registered the plugin in AndroidManifest.xml"
}

Write-Host "Setup complete."
