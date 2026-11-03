@echo off
chcp 65001 >nul
title Shadow Cubes 3D
cd /d "%~dp0"

echo Starting local server for Shadow Cubes 3D...
echo.

where py >nul 2>nul && goto :usepy
where python >nul 2>nul && goto :usepython
where npx >nul 2>nul && goto :usenpx
goto :nothing

:usepy
start "" http://localhost:8000/shadow-cubes-3d.html
py -m http.server 8000
goto :end

:usepython
start "" http://localhost:8000/shadow-cubes-3d.html
python -m http.server 8000
goto :end

:usenpx
start "" http://localhost:8000/shadow-cubes-3d.html
npx --yes serve -l 8000 .
goto :end

:nothing
echo Python or Node.js not found. Please install one:
echo   Python:  https://www.python.org/downloads/
echo   Node.js: https://nodejs.org/
echo.
pause

:end