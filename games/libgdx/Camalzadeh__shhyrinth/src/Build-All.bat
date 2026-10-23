@echo off
echo Shhyrinth Qurasdirilir (Build)...
echo.
echo [1/2] Desktop versiyasi hazirlanir (JAR)...
call gradlew.bat desktop:dist
echo [2/2] Web (HTML) versiyasi hazirlanir...
call gradlew.bat html:dist
echo.
echo TEBRIKLER! Build ugurla basa catdi.
echo ---------------------------------------
echo.
echo Desktop: "PC-de-Oyna.bat" istifade edin.
echo Web: "html\build\dist" qovluguna baxin.
echo.
pause
