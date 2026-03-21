@echo off & color 2 & cls & title Bolle's Adminrechte anfordern (%~nx0)

goto checkPrivileges
:gotPrivileges

echo Adminrechte bekommen!
pause
exit /b 0

:checkPrivileges
rem Adminrechteprüfung ueber fltmc (schnell und lokal)
if exist "%SystemRoot%\System32\fltmc.exe" (
    fltmc >nul 2>&1
    if not errorlevel 1 goto gotPrivileges
)

rem Fallback falls fltmc nicht greift
net file >nul 2>&1
if not errorlevel 1 goto gotPrivileges

rem Script mit UAC-Elevation neu starten
rem Absoluten Skriptpfad holen und UAC-Elevation auch ermöglichen wenn Script im Ordner mit Apostrophen liegt
set "SCRIPT=%~f0"
rem PowerShell-Single-Quotes escapen: ' -> ''
set "SCRIPT=%SCRIPT:'=''%"
powershell -NoProfile -Command "Start-Process -FilePath '%SCRIPT%' -Verb RunAs" >nul 2>&1
if errorlevel 1 (
    echo UAC-Abfrage abgebrochen oder Start fehlgeschlagen.
    pause >nul 2>&1
    exit /b 1
)
exit /b 0
