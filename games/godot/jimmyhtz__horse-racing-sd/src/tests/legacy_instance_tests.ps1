param([string]$RunningEngine = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../scripts/Instance-Check.ps1')
$engine = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../fake-engine.exe'))
$same = [pscustomobject]@{Path=$engine; ProcessName='fake-engine'; MainWindowTitle=''}
$legacy = [pscustomobject]@{Path='C:\Elsewhere\Godot.exe'; ProcessName='Godot_v4'; MainWindowTitle='Horse racing | SD mode'}
$unrelated = [pscustomobject]@{Path='C:\Elsewhere\Godot.exe'; ProcessName='Godot_v4'; MainWindowTitle='Another project'}
if (-not (Test-HorseRacingRunning -Godot $engine -Candidates @($same))) { throw 'Same executable was missed' }
if (-not (Test-HorseRacingRunning -Godot $engine -Candidates @($legacy))) { throw 'Legacy game window was missed' }
if (Test-HorseRacingRunning -Godot $engine -Candidates @($unrelated)) { throw 'Unrelated engine blocked' }
if (Test-HorseRacingRunning -Godot $engine -Candidates @()) { throw 'Empty process list blocked' }
$shared = [pscustomobject]@{Path=$engine; ProcessName='Godot_v4'; MainWindowTitle='Another project'}
if (-not (Test-HorseRacingRunning -Godot $engine -Candidates @($shared))) { throw 'Dedicated executable policy was not enforced' }
if ($RunningEngine -and -not (Test-HorseRacingRunning -Godot $RunningEngine)) { throw 'Actual running engine was missed' }
Write-Output 'LEGACY INSTANCE CHECK: 5 cases passed'
