@echo off
set "TARGET_DIR=../TowerProtect/Content"
python python/remove_transparency.py "%TARGET_DIR%"
pause