@echo off & color 2 & cls & title Bolle's Reinstall MS Store (%0)
if "%~1"=="1" goto OPTION1

:MENU
cls
echo ================================
echo.
echo  Bolle's Reinstall_MS_Store.cmd
echo.
echo ================================
echo.
echo  [1] Microsoft Store neu installieren (wsreset)
echo  [2] Xbox App Downloadseite oeffnen
echo.
set /p AUSWAHL=Bitte Auswahl treffen: 

if "%AUSWAHL%"=="1" goto OPTION1
if "%AUSWAHL%"=="2" goto OPTION2
echo.
echo Beende
timeout /t 1 >nul
echo.
exit

:OPTION1
goto checkPrivileges

:gotPrivileges
cls
echo ======================================
echo.
echo  Microsoft Store wird neu installiert
echo.
echo ======================================
echo.
echo Dies kann einige Minuten dauern.
echo Es gibt keine Statusanzeige.
echo.
echo Warte, bis der Microsoft Store im Startmenue erscheint.
echo.
powershell.exe -ExecutionPolicy Bypass -Command "wsreset -i"
echo.
pause
exit

:checkPrivileges
net session >nul 2>&1 && goto gotPrivileges
net file    >nul 2>&1 && goto gotPrivileges
set "SCRIPT=%~f0"
set "SCRIPT=%SCRIPT:'=''%"
powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%SCRIPT%' -Verb RunAs -ArgumentList '1'" >nul 2>&1
if errorlevel 1 (start "" cmd /c "color C & echo. & echo UAC-Abfrage wurde abgebrochen oder ist fehlgeschlagen. & echo. & pause" & exit /b 1)
exit /b 0

:OPTION2
cls
echo ===================
echo.
echo  Xbox App Download
echo.
echo ===================
echo.
echo Die Xbox App installiert fehlende Abhaengigkeiten
echo wie Microsoft Store oder App Installer (winget).
echo.
echo Druecke eine beliebige Taste um die Downloadseite
echo zu oeffen: https://www.xbox.com/apps/xbox-app-for-pc
echo.
pause >nul 2>nul
start https://www.xbox.com/apps/xbox-app-for-pc
exit
