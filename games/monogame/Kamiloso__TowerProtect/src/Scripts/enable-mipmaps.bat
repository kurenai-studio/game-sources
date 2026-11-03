@echo off
set "FILENAME=../TowerProtect/Content/Content.mgcb"

if not exist "%FILENAME%" (
    echo File %FILENAME% not found.
    pause
    exit /b 1
)

powershell -Command "(Get-Content '%FILENAME%') -replace '/processorParam:GenerateMipmaps=False', '/processorParam:GenerateMipmaps=True' | Out-File -FilePath '%FILENAME%' -Encoding utf8"

echo Mipmaps enabled successfully.
pause