@echo off & color 2 & cls & title Bolle's Datum und Uhrzeit (%~nx0)

set h=%time:~0,2%
set m=%time:~3,2%
FOR /F "tokens=1,2,3,4 delims=/. " %%a in ('date/T') do set DATUM=%%a.%%b.%%c
rem Robuste lokale Datums-/Zeitermittlung via PowerShell
FOR /f "usebackq delims=" %%E in (`powershell -NoProfile -Command "Get-Date -Format 'dd.MM.yyyy HH:mm'"`) do set "DT=%%E"


echo.
echo.
echo.
echo Datum und Uhrzeit : %DATUM% %h%:%m% Uhr
echo Datum und Uhrzeit : %DT% Uhr
echo.
echo.
echo.
pause>nul
exit /b 0

rem 22:18 13.12.2007 Bolle
