## Launches the desktop-window spike as a standalone process. Run from anywhere:
##   pwsh -File game/tools/run_spike.ps1 [--mode=strip|corner|window] [--scale=N] [--fps=N]
##       [--screen=N] [--no-ontop] [--no-passthrough] [--no-lowproc] [--no-hud]
##
## Why not F5 in the editor: recent editors embed the running game in a "Game" tab, where
## borderless, transparent, always-on-top and mouse passthrough do nothing. Either use this
## script or turn off "Embed Game on Next Play" in the editor's Game tab.
##
## The engine comes from $env:GODOT, or godot / godot4 on PATH.

param(
	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$GameArgs
)

$ErrorActionPreference = "Stop"

function Resolve-Godot {
	if ($env:GODOT -and (Test-Path -LiteralPath $env:GODOT -PathType Leaf)) {
		return (Resolve-Path -LiteralPath $env:GODOT).Path
	}
	foreach ($name in @("godot", "godot4")) {
		$command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue |
			Select-Object -First 1
		if ($command) {
			return $command.Source
		}
	}
	$Host.UI.WriteErrorLine("No Godot binary found. Set `$env:GODOT or put godot on PATH.")
	exit 2
}

$godot = Resolve-Godot
$project = Join-Path (Split-Path $PSScriptRoot -Parent) "."
$arguments = @("--path", $project, "res://scenes/dev/window_spike.tscn")
if ($GameArgs) {
	$arguments += "--"
	$arguments += $GameArgs
}
Start-Process -FilePath $godot -ArgumentList $arguments
Write-Host "Started. Click the strip to focus it, then Esc or Q quits (keys are listed in the HUD)."
