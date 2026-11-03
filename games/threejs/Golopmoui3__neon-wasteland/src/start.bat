@echo off
cd /d "%~dp0"
echo === NEON WASTELAND ===
echo Запуск локального сервера на http://localhost:8137/ ...
start "" cmd /c "timeout /t 1 >nul & start http://localhost:8137/"
python -m http.server 8137 2>nul || py -m http.server 8137 2>nul || npx -y serve -l 8137 .
