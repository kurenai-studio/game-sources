@echo off
set JAR_FILE=desktop\build\lib\desktop-1.0.jar

if exist "%JAR_FILE%" (
    echo Shhyrinth basladilir...
    java -jar "%JAR_FILE%"
) else (
    echo [XETA] Build tapilmadi! Zehmet olmasa evvelce "Build-All.bat" isletin.
    pause
)
