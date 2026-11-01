@echo off
cd /d "%~dp0"

where python >nul 2>&1
if errorlevel 1 (
  echo Error: python not found. Install Python 3.8+ first.
  exit /b 1
)

echo Checking Python version (need 3.8-3.13, not 3.14+) ...
python -c "import sys; raise SystemExit(0 if (3,8)<=sys.version_info<(3,14) else 1)"
if errorlevel 1 (
  echo Error: Python 3.14+ is not supported yet ^(pygame.font missing^).
  echo Install Python 3.11 or 3.12 from https://www.python.org/downloads/
  pause
  exit /b 1
)

echo Creating virtual environment in .venv ...
python -m venv .venv
if errorlevel 1 exit /b 1

echo Installing dependencies ...
.venv\Scripts\python.exe -m pip install --upgrade pip
.venv\Scripts\python.exe -m pip install -r requirements.txt
if errorlevel 1 exit /b 1

echo Verifying pygame fonts ...
.venv\Scripts\python.exe -B -c "import pygame; pygame.init(); import pygame.font; pygame.font.SysFont('Arial', 16)"
if errorlevel 1 (
  echo Error: pygame.font is not available.
  pause
  exit /b 1
)

echo.
echo Setup complete. Start the collection with GameCollection.bat
pause
