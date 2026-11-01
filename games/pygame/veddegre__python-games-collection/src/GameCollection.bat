@echo off
cd /d "%~dp0"

if exist ".venv\Scripts\python.exe" (
  .venv\Scripts\python.exe -B run.py
  goto :done
)

python -B -c "import pygame" 2>nul
if errorlevel 1 (
  echo pygame is not installed for this Python.
  echo.
  echo Run setup.bat once, then GameCollection.bat again.
  pause
  exit /b 1
)

python -B run.py

:done
pause
