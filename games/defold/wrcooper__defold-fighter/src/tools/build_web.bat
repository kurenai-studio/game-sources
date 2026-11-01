@echo off
rem Bundles the HTML5 (WebAssembly) release build into dist\web\Defold Fighter
rem using the Bob builder inside the Defold editor install.
rem Set DEFOLD_DIR if Defold isn't in %USERPROFILE%\Tools\Defold.
setlocal
if "%DEFOLD_DIR%"=="" set "DEFOLD_DIR=%USERPROFILE%\Tools\Defold"
set "PKG=%DEFOLD_DIR%\packages"
for %%f in ("%PKG%\defold-*.jar") do set "JAR=%%f"
for /d %%d in ("%PKG%\jdk-*") do set "JDK=%%d"
if not exist "%JAR%" (
  echo Defold editor jar not found in %PKG%
  exit /b 1
)

cd /d "%~dp0.."
if exist "dist\web" rmdir /s /q "dist\web"
"%JDK%\bin\java.exe" -cp "%JAR%" com.dynamo.bob.Bob --root . --output build/web ^
  --platform wasm-web --architectures wasm-web --variant release --archive ^
  --bundle-output dist/web build bundle || exit /b 1

echo.
echo Built: dist\web\Defold Fighter\index.html
echo Test locally:  python -m http.server 8080 --directory "dist/web/Defold Fighter"
echo then open http://localhost:8080
