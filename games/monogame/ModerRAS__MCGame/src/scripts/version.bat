@echo off
REM 版本管理脚本 (Windows版本)
REM 用于创建标签和发布版本

setlocal enabledelayedexpansion

REM 获取当前版本
for /f "tokens=3 delims=<>" %%a in ('findstr /r "<Version>.*<Version>" MCGame.csproj') do set CURRENT_VERSION=%%a
echo 当前版本: %CURRENT_VERSION%

REM 检查是否提供了新版本
if "%~1"=="" (
    echo 用法: %~nx0 ^<新版本^> [发布标题]
    echo 例如: %~nx0 1.0.1 "Bug Fix Release"
    exit /b 1
)

set NEW_VERSION=%~1
if "%~2"=="" (
    set RELEASE_TITLE=Release v%NEW_VERSION%
) else (
    set RELEASE_TITLE=%~2
)

REM 验证版本格式
echo %NEW_VERSION% | findstr /r "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo 错误: 版本格式必须为 X.Y.Z
    exit /b 1
)

echo 更新版本到: %NEW_VERSION%

REM 更新项目文件中的版本
powershell -Command "(Get-Content MCGame.csproj) -replace '<Version>%CURRENT_VERSION%</Version>', '<Version>%NEW_VERSION%</Version>' | Set-Content MCGame.csproj"
powershell -Command "(Get-Content MCGame.csproj) -replace '<FileVersion>%CURRENT_VERSION%.0</FileVersion>', '<FileVersion>%NEW_VERSION%.0</FileVersion>' | Set-Content MCGame.csproj"
powershell -Command "(Get-Content MCGame.csproj) -replace '<AssemblyVersion>%CURRENT_VERSION%.0</AssemblyVersion>', '<AssemblyVersion>%NEW_VERSION%.0</AssemblyVersion>' | Set-Content MCGame.csproj"

REM 提交版本更改
git add MCGame.csproj
git commit -m "版本更新: %NEW_VERSION%

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude ^<noreply@anthropic.com^>"

REM 创建标签
git tag -a "v%NEW_VERSION%" -m "%RELEASE_TITLE%"

echo 版本 %NEW_VERSION% 已准备就绪
echo 使用以下命令推送到远程仓库:
echo   git push origin master
echo   git push origin v%NEW_VERSION%

echo.
echo 或者使用GitHub Actions手动触发发布:
echo   1. 访问 https://github.com/ModerRAS/MCGame/actions
echo   2. 选择 'Create Release' workflow
echo   3. 点击 'Run workflow'
echo   4. 输入版本: %NEW_VERSION%
echo   5. 输入发布标题: %RELEASE_TITLE%

pause