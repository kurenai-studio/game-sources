@echo off
echo ========================================================
echo Building NativeRoguelikeCore.dll (C++ Native Plugin)
echo ========================================================

if not exist "Assets\Plugins\x86_64" mkdir "Assets\Plugins\x86_64"

g++ -O3 -shared -fPIC -static-libgcc -static-libstdc++ ^
    -I NativeCore\include ^
    NativeCore\src\SpatialGrid.cpp ^
    NativeCore\src\SteeringSwarm.cpp ^
    NativeCore\src\ProceduralDungeon.cpp ^
    -o Assets\Plugins\x86_64\NativeRoguelikeCore.dll

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] NativeRoguelikeCore.dll built successfully into Assets\Plugins\x86_64\
) else (
    echo [ERROR] Build failed! Check g++ compiler path.
)
