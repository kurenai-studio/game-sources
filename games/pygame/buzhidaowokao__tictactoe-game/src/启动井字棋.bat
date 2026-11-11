@echo off
chcp 65001 >nul
title 井字棋 Tic-Tac-Toe
cd /d "%~dp0"
echo 正在启动《井字棋》...
python main.py
if errorlevel 1 (
  echo.
  echo 启动失败。若提示缺少依赖，请先执行：pip install -r requirements.txt
)
echo.
echo 程序已退出，按任意键关闭窗口...
pause >nul
