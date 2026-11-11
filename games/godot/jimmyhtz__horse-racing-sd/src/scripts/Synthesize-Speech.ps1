param([Parameter(Mandatory=$true)][string]$Manifest)
$ErrorActionPreference = 'Stop'
# One hidden local worker per batch. No network, shell text, or race generator.
$request = $null
$errorsFound = @()
function Test-VoiceWave([string]$Path) {
    if (-not [IO.File]::Exists($Path)) { return $false }
    try {
        $data = [IO.File]::ReadAllBytes($Path)
        if ($data.Length -lt 44) { return $false }
        if ([Text.Encoding]::ASCII.GetString($data,0,4) -ne 'RIFF' -or [Text.Encoding]::ASCII.GetString($data,8,4) -ne 'WAVE') { return $false }
        if ([BitConverter]::ToUInt32($data,4)+8 -ne $data.Length) { return $false }
        $offset=12
        while ($offset+8 -le $data.Length) {
            $length=[BitConverter]::ToUInt32($data,$offset+4)
            if ($offset+8+$length -gt $data.Length) { return $false }
            if ([Text.Encoding]::ASCII.GetString($data,$offset,4) -eq 'data') { return $length -gt 0 }
            $offset+=8+$length+($length % 2)
        }
    } catch { return $false }
    return $false
}
try {
# Direct local file access avoids initializing unrelated Windows filesystem drives.
$request = [IO.File]::ReadAllText($Manifest) | ConvertFrom-Json
$voice = New-Object -ComObject SAPI.SpVoice
foreach ($clip in $request.clips) {
    if (Test-VoiceWave $clip.path) { continue }
    $temporary = [string]$clip.path + ".part.$PID"
    $stream = $null
    try {
        $chosen = $null
        # The selected installed token can work even when legacy enumeration fails.
        # Bind it first; enumeration is only a fallback for an unavailable token.
        try {
            $requested = New-Object -ComObject SAPI.SpObjectToken
            $requested.SetId([string]$clip.voice)
            $voice.Voice = $requested
            $chosen = $requested
        } catch {
            try {
                $tokens = $voice.GetVoices()
                $wanted = ([string]$clip.voice_name -replace '(?i)\bdesktop\b','' -replace '\s*[-(].*$','').Trim()
                for ($i=0; $i -lt $tokens.Count; $i++) {
                    $candidate = $tokens.Item($i)
                    $description = ($candidate.GetDescription() -replace '(?i)\bdesktop\b','' -replace '\s*[-(].*$','').Trim()
                    if ($candidate.Id -eq $clip.voice -or ($wanted -and $wanted -eq $description)) { $chosen = $candidate; break }
                }
            } catch { $chosen = $null }
        }
        if ($null -eq $chosen) { throw 'The selected Windows speech voice is unavailable.' }
        $voice.Voice = $chosen
        $boundedRate = [Math]::Max(1.0,[Math]::Min(1.6,[double]$clip.rate))
        $voice.Rate = [Math]::Max(0,[Math]::Min(6,[int][Math]::Round(10*[Math]::Log($boundedRate,2))))
        $voice.Volume = 100
        $stream = New-Object -ComObject SAPI.SpFileStream
        $stream.Open($temporary,3,$false)
        $voice.AudioOutputStream = $stream
		# SAPI XML provides a small lift on excited opening clauses, without imitating a person.
		$spoken = [System.Security.SecurityElement]::Escape([string]$clip.text)
		$bang = $spoken.IndexOf('!')
		if ($bang -ge 0 -and $bang -lt 160) {
			$spoken = '<pitch middle="3"><emph>' + $spoken.Substring(0,$bang+1) + '</emph></pitch>' + $spoken.Substring($bang+1)
		}
		$null = $voice.Speak('<pitch absmiddle="0">' + $spoken + '</pitch>',8)
        $stream.Close()
        $stream = $null
        if (-not (Test-VoiceWave $temporary)) { throw "Speech synthesis produced an incomplete wave file." }
        if ([IO.File]::Exists([string]$clip.path)) { [IO.File]::Replace($temporary,[string]$clip.path,([string]$clip.path+".old")); [IO.File]::Delete([string]$clip.path+".old") } else { [IO.File]::Move($temporary,[string]$clip.path) }
    } catch {
        $errorsFound += $_.Exception.Message
        if ($stream) { $stream.Close() }
        if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}
} catch { $errorsFound += $_.Exception.Message }
finally {
    $report = @{errors=$errorsFound; count=@($request.clips).Count} | ConvertTo-Json
    [IO.File]::WriteAllText($Manifest+'.done',$report,[Text.Encoding]::UTF8)
}
