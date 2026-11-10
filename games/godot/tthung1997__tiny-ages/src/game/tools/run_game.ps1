## Launches the game (scenes/main.tscn) as a standalone process. Run from anywhere:
##   pwsh -File game/tools/run_game.ps1 [--new] [--nosave] [--days=N] [--bot] [--speed=N]
##       [--mode=strip|corner|window] [--scale=N] [--fps=N] [--screen=N] [--no-hud] ...
## Flags are documented at the top of game/scripts/game/game.gd.
##
## Standalone rather than F5, because the editor embeds the running game where the window
## flags (borderless, transparent, always-on-top, click-through) do nothing.
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
$arguments = @("--path", $project)
if ($GameArgs) {
	$arguments += "--"
	$arguments += $GameArgs
}
Start-Process -FilePath $godot -ArgumentList $arguments
Write-Host "Started. Click the strip to focus it, then Esc or Q saves and quits (keys are in the HUD)."
