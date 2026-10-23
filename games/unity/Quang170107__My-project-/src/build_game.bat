@echo off
echo ========================================================
echo Building GeometricDungeon.exe (Standalone Raylib Game)
echo ========================================================

set GCC=g++
if exist "C:\msys64\ucrt64\bin\g++.exe" set GCC=C:\msys64\ucrt64\bin\g++.exe

%GCC% -O2 -static-libgcc -static-libstdc++ -mwindows ^
    -I "C:\msys64\ucrt64\include" ^
    StandaloneApp\main.cpp ^
    -L "C:\msys64\ucrt64\lib" ^
    -lraylib -lopengl32 -lgdi32 -lwinmm -lpthread ^
    -o GeometricDungeon.exe

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] GeometricDungeon.exe built successfully!
    echo.
    REM Copy required DLLs
    if exist "C:\msys64\ucrt64\bin\libraylib.dll" (
        copy /Y "C:\msys64\ucrt64\bin\libraylib.dll" . >nul
        echo [INFO] Copied libraylib.dll
    )
    if exist "C:\msys64\ucrt64\bin\libwinpthread-1.dll" (
        copy /Y "C:\msys64\ucrt64\bin\libwinpthread-1.dll" . >nul
        echo [INFO] Copied libwinpthread-1.dll
    )
    echo.
    echo [READY] Run GeometricDungeon.exe to play!
) else (
    echo [ERROR] Build failed! Make sure g++ and raylib are installed.
    echo   Install via MSYS2: pacman -S mingw-w64-ucrt-x86_64-raylib
)
pause
