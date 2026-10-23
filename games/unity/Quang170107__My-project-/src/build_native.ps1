Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Building NativeRoguelikeCore.dll (C++ Native Plugin)" -ForegroundColor Cyan
Write-Host "========================================================"

if (-not (Test-Path "Assets\Plugins\x86_64")) {
    New-Item -ItemType Directory -Force -Path "Assets\Plugins\x86_64" | Out-Null
}

$gpp = "g++"
if (Get-Command "C:\msys64\ucrt64\bin\g++.exe" -ErrorAction SilentlyContinue) {
    $gpp = "C:\msys64\ucrt64\bin\g++.exe"
}

& $gpp -O3 -shared -fPIC -static-libgcc -static-libstdc++ `
    -I NativeCore/include `
    NativeCore/src/SpatialGrid.cpp `
    NativeCore/src/SteeringSwarm.cpp `
    NativeCore/src/ProceduralDungeon.cpp `
    -o Assets/Plugins/x86_64/NativeRoguelikeCore.dll

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] NativeRoguelikeCore.dll built successfully into Assets\Plugins\x86_64\" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red
}
