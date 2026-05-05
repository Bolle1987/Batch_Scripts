@echo off & color 2 & cls & title Bolle's Adminrechte anfordern (%~nx0)

goto checkPrivileges
:gotPrivileges

echo Adminrechte bekommen!
pause
exit /b 0

:checkPrivileges
net session >nul 2>&1 && goto gotPrivileges
net file    >nul 2>&1 && goto gotPrivileges

rem Script mit UAC-Elevation neu starten
rem Absoluten Skriptpfad holen und UAC-Elevation auch ermöglichen wenn Script im Ordner mit Apostrophen liegt
set "SCRIPT=%~f0"
rem PowerShell-Single-Quotes escapen: ' -> ''
set "SCRIPT=%SCRIPT:'=''%"
powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%SCRIPT%' -Verb RunAs" >nul 2>&1
if errorlevel 1 (start "" cmd /c "color C & echo. & echo UAC-Abfrage wurde abgebrochen oder ist fehlgeschlagen. & echo. & pause" & exit /b 1)
exit /b 0
