param([string]$Project)
$ErrorActionPreference='Stop'
$folder=Join-Path $Project '..\..\work\speech17-worker-test'
New-Item -ItemType Directory -Path $folder -Force | Out-Null
$token=Get-ChildItem -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Speech_OneCore\Voices\Tokens' | Select-Object -First 1
$id=$token.Name
$unique=[Guid]::NewGuid().ToString('N')
$wave=Join-Path $folder ($unique+'.wav')
$manifest=Join-Path $folder ($unique+'.json')
@{clips=@(@{text='Horse two just passed Horse four for second!';voice=$id;rate=1.0;path=$wave},@{text='Unavailable voice.';voice='HKEY_LOCAL_MACHINE\SOFTWARE\MissingVoice17';rate=1.0;path=($wave+'.invalid')})} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifest -Encoding UTF8
& (Join-Path $Project 'scripts\Synthesize-Speech.ps1') -Manifest $manifest
if (-not (Test-Path -LiteralPath ($manifest+'.done'))) { throw 'Missing worker result report' }
$report=Get-Content -LiteralPath ($manifest+'.done') -Raw | ConvertFrom-Json
if (-not (Test-Path -LiteralPath $wave)) { throw 'No speech wave created for an installed direct voice token' }
$data=[IO.File]::ReadAllBytes($wave)
if ($data.Length -lt 1000 -or [Text.Encoding]::ASCII.GetString($data,0,4) -ne 'RIFF') { throw 'Invalid speech wave' }
if ($report.errors.Count -ne 1) { throw 'Unavailable voice did not produce exactly one explicit error' }
Write-Output ('WORKER17 PASS: '+$data.Length+' bytes; installed token synthesized; missing voice reported')
