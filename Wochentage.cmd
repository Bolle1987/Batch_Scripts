@echo off & color 2 & cls & title Bolle's Wochentage (%~dp0%~n0%~x0)

for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Date).ToString('dddd', [System.Globalization.CultureInfo]::GetCultureInfo('de-DE'))"`) do set "DOW=%%A"

if not defined DOW (
    echo Fehler: Wochentag konnte nicht ermittelt werden.
    exit /b 1
)

echo.
echo %DOW%
echo.
pause
exit /b 0
