## Says whether it is time to cut a new release, from what changed since the last one.
##   pwsh -File game/tools/release_check.ps1 [-Since <tag or commit>] [-Ref HEAD]
## It is a suggestion from simple rules, not a decision; the rules and thresholds are at the top and in
## .github/skills/release/SKILL.md. Run it when opening or merging a PR (the pull-request skill does).
## Needs the tags: `git fetch --tags`.

param(
	[string]$Ref = "HEAD",
	[string]$Since = ""
)

$ErrorActionPreference = "Stop"

# Suggest a minor release at this many player-facing changes, or after this many days with any.
$MinorChanges = 3
$MinorDays = 14

# What a player gets in the zip, and what is the saved world (see docs: saves have no migration).
$PlayerFacing = @(
	"game/scripts", "game/scenes", "game/assets", "game/resources", "game/project.godot",
	"game/icon.png", "game/icon.ico"
)
$SaveFormat = @("game/scripts/sim/state")

Set-Location (git rev-parse --show-toplevel)

$base = $Since
if (-not $base) {
	$base = git describe --tags --abbrev=0 --match "v[0-9]*" $Ref 2>$null
}
if (-not $base) {
	Write-Host "No release has been made yet. The first one is the v0.1.0 flow in .github/skills/release."
	exit 0
}
$range = "$base..$Ref"
$baseName = if ($base -match '^v[0-9]') { $base } else { (git rev-parse --short $base) }

$changes = [int](git rev-list --first-parent --count $range -- @PlayerFacing)
$subjects = @(git log --first-parent --format=%s $range -- @PlayerFacing)
$fixes = @($subjects | Where-Object { $_ -match '(?i)\b(fix|fixes|fixed|bug|crash|hotfix|regression)\b' })
$saveFiles = @(git diff --name-only $base $Ref -- @SaveFormat | Where-Object { $_ -notmatch '\.uid$' })
$allCommits = [int](git rev-list --first-parent --count $range)

$stamp = [int64](git log -1 --format=%ct $base)
$days = [math]::Floor(([DateTimeOffset]::UtcNow - [DateTimeOffset]::FromUnixTimeSeconds($stamp)).TotalDays)

$lastVersion = $base.TrimStart("v")
$parts = $lastVersion -split "\."
$patch = if ($parts.Count -eq 3) { "$($parts[0]).$($parts[1]).$([int]$parts[2] + 1)" } else { "" }
$minor = if ($parts.Count -eq 3) { "$($parts[0]).$([int]$parts[1] + 1).0" } else { "" }
$projectVersion = (Select-String -Path "game/project.godot" -Pattern '^config/version="(.+)"').Matches[0].Groups[1].Value

if ($changes -eq 0) {
	$verdict = "No release needed"
	$why = "Nothing a player would notice has changed since $baseName."
	$next = ""
}
elseif ($fixes.Count -gt 0 -and $changes -lt $MinorChanges) {
	$verdict = "Release a patch soon"
	$why = "A fix reaches players ($($fixes[0]))."
	$next = $patch
}
elseif ($changes -ge $MinorChanges) {
	$verdict = "Good time for a release"
	$why = "$changes player-facing changes have built up (the suggestion starts at $MinorChanges)."
	if ($fixes.Count -gt 0) { $why += " One is a fix: $($fixes[0])." }
	$next = $minor
}
elseif ($days -ge $MinorDays) {
	$verdict = "Good time for a release"
	$why = "$changes player-facing change(s), and it has been $days days since $baseName (the suggestion starts at $MinorDays)."
	$next = $minor
}
else {
	$verdict = "Not yet"
	$why = "$changes player-facing change(s) and $days day(s) since $baseName. A release is suggested at $MinorChanges changes or $MinorDays days, or for a fix."
	$next = ""
}

$notes = @()
if ($next -and $projectVersion -eq $lastVersion) {
	$notes += "`config/version` is still $projectVersion; bump it to $next in the release PR."
}
if ($saveFiles.Count -gt 0) {
	$names = ($saveFiles | Select-Object -First 3 | ForEach-Object { Split-Path $_ -Leaf }) -join ", "
	if ($saveFiles.Count -gt 3) { $names += " and $($saveFiles.Count - 3) more" }
	$notes += "The saved world changed ($names). Saves have no migration yet: make sure an old save still loads before releasing."
}
if ($next) {
	$notes += "Play it on a real desktop for a few minutes first (window behaviour can't be tested automatically). Steps: the `release` skill."
}

Write-Host "$verdict. $why"
Write-Host "Last release $baseName ($days day(s) ago); $changes player-facing change(s) of $allCommits since."
if ($next) { Write-Host "Suggested next version: v$next" }
foreach ($note in $notes) { Write-Host "- $($note -replace '`', '')" }
