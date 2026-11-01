@echo off
rem Lanzador de Robot Renegado: doble clic para jugar.
cd /d "%~dp0"
python main.py
if errorlevel 1 (
    echo.
    echo El juego termino con un error. Copia el mensaje de arriba y avisame.
    pause
)
