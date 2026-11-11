param([string]$Project)
$ErrorActionPreference='Stop'
$cache=Join-Path $Project '..\..\work\speech-recovery-test'
New-Item -ItemType Directory -Path $cache -Force | Out-Null
$target=Join-Path $cache 'recovered.wav'
[IO.File]::WriteAllText($target,'partial')
$manifest=Join-Path $cache 'request.json'
$voice=New-Object -ComObject SAPI.SpVoice
@{clips=@(@{text='A recovered voice clip.';voice=$voice.GetVoices().Item(0).Id;rate=1.0;path=[IO.Path]::GetFullPath($target)})} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifest
& (Join-Path $Project 'scripts\Synthesize-Speech.ps1') -Manifest $manifest
$bytes=[IO.File]::ReadAllBytes($target)
if ($bytes.Length -lt 1000 -or [Text.Encoding]::ASCII.GetString($bytes,0,4) -ne 'RIFF') { Write-Output 'FAIL: interrupted WAV is not regenerated'; exit 1 }
Write-Output ('SPEECH RECOVERY PASS: '+$bytes.Length+' bytes')
