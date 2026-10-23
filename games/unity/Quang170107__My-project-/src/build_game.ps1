Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Building GeometricDungeon.exe (Standalone Raylib Game)" -ForegroundColor Cyan
Write-Host "========================================================"

$gpp = "g++"
if (Get-Command "C:\msys64\ucrt64\bin\g++.exe" -ErrorAction SilentlyContinue) {
    $gpp = "C:\msys64\ucrt64\bin\g++.exe"
}

& $gpp -O2 -static-libgcc -static-libstdc++ -mwindows `
    -I "C:\msys64\ucrt64\include" `
    StandaloneApp/main.cpp `
    -L "C:\msys64\ucrt64\lib" `
    -lraylib -lopengl32 -lgdi32 -lwinmm -lpthread `
    -o GeometricDungeon.exe

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] GeometricDungeon.exe built successfully!" -ForegroundColor Green

    # Copy required runtime DLLs
    if (Test-Path "C:\msys64\ucrt64\bin\libraylib.dll") {
        Copy-Item "C:\msys64\ucrt64\bin\libraylib.dll" "." -Force
        Write-Host "[INFO] Copied libraylib.dll" -ForegroundColor Yellow
    }
    if (Test-Path "C:\msys64\ucrt64\bin\libwinpthread-1.dll") {
        Copy-Item "C:\msys64\ucrt64\bin\libwinpthread-1.dll" "." -Force
        Write-Host "[INFO] Copied libwinpthread-1.dll" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "[READY] Run GeometricDungeon.exe to play!" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Build failed! Make sure g++ and raylib are installed." -ForegroundColor Red
    Write-Host "  Install via MSYS2: pacman -S mingw-w64-ucrt-x86_64-raylib" -ForegroundColor Yellow
}
