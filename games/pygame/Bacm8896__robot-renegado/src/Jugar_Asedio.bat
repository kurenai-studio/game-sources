@echo off
rem Atajo de pruebas: salta todo y abre directamente la Guerra de Asedio (modo Comandante, mapa de 3000 x 2000).
cd /d "%~dp0"
python tools\start_base_central.py --asedio %*
if errorlevel 1 (
    echo.
    echo El juego termino con un error. Copia el mensaje de arriba y avisame.
    pause
)
