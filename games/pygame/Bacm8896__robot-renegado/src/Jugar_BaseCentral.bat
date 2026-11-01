@echo off
rem Atajo de pruebas: salta el Acto 1 y abre directamente la Base Central (terminal donde eliges que hacer).
rem Opciones: --nivel N (nivel de incursion)  --inicial-hecha (incursion inicial ya completada)
cd /d "%~dp0"
python tools\start_base_central.py %*
if errorlevel 1 (
    echo.
    echo El juego termino con un error. Copia el mensaje de arriba y avisame.
    pause
)
