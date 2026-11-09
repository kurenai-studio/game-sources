# Gera dist/xadrez.love e dist/xadrez-windows.zip (executável que não precisa do LÖVE instalado).
# Uso (PowerShell, na pasta do projeto):  .\build.ps1
# Se o LÖVE estiver em outro lugar:       .\build.ps1 -Love "D:\LOVE"
param([string]$Love = "C:\Program Files\LOVE")

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

$raiz = $PSScriptRoot
$dist = Join-Path $raiz "dist"
$pastaWin = Join-Path $dist "xadrez-windows"
$arquivoLove = Join-Path $dist "xadrez.love"

if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory -Path $pastaWin | Out-Null

# 1) .love = zip com o código. Caminhos com "/" (o LÖVE não aceita "\" dentro do zip).
$arquivos = @("conf.lua", "main.lua") + (Get-ChildItem (Join-Path $raiz "src") -Filter *.lua | ForEach-Object { "src/" + $_.Name })
$zip = [System.IO.Compression.ZipFile]::Open($arquivoLove, "Create")
try {
    foreach ($a in $arquivos) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, (Join-Path $raiz $a), $a) | Out-Null
    }
} finally { $zip.Dispose() }

# 2) Executável "fundido": love.exe + xadrez.love, mais as DLLs do LÖVE.
$exe = Join-Path $pastaWin "xadrez.exe"
$bytes = [System.IO.File]::ReadAllBytes((Join-Path $Love "love.exe")) + [System.IO.File]::ReadAllBytes($arquivoLove)
[System.IO.File]::WriteAllBytes($exe, $bytes)
Get-ChildItem $Love -Filter *.dll | Copy-Item -Destination $pastaWin
Copy-Item (Join-Path $Love "license.txt") (Join-Path $pastaWin "LOVE-license.txt")
Copy-Item (Join-Path $raiz "LICENSE") (Join-Path $pastaWin "LICENSE.txt")

# 3) Zip para anexar na Release do GitHub.
[System.IO.Compression.ZipFile]::CreateFromDirectory($pastaWin, (Join-Path $dist "xadrez-windows.zip"))

Write-Host "Pronto:"
Write-Host "  $arquivoLove"
Write-Host "  $(Join-Path $dist 'xadrez-windows.zip')"
