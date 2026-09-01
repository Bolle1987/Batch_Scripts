@echo off & color 07 & cls & title OneDrive Ordner ausschliessen (%~nx0)

rem GPO/Intune feature: MC1430530 / Roadmap 567470
rem Folder matching is case-insensitive; wildcards aren't supported.
rem Restart the OneDrive client after applying or changing the policy
rem Existing folders already synced aren't handled retroactively, so affected users need to move them out of OneDrive and then back into the synced location after the policy is active
rem 20260901 https://github.com/Bolle1987

set folders="PowerShell","WindowsPowerShell","Benutzerdefinierte Office-Vorlagen"

set "REGKEY=HKLM\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreFolderListFromGPO"

for /F %%a in ('echo prompt $E^|cmd') do set "ESC=%%a"
set "cReset=%ESC%[0m"
set "cRed=%ESC%[91m"
set "cGreen=%ESC%[92m"
set "cOrange=%ESC%[38;5;208m"

goto checkPrivileges
:gotPrivileges

setlocal EnableDelayedExpansion
set /a index=0
set /a success=0
set /a failed=0

echo.
for %%f in (%folders%) do (
    set /a index+=1
    echo [!index!] %%~f
    reg add "%REGKEY%" /v "!index!" /t REG_SZ /d "%%~f" /f >nul 2>&1

    if !errorlevel! equ 0 (
        echo     %cGreen%[OK]%cReset% Registry-Eintrag wurde gesetzt.
        set /a success+=1
    ) else (
        echo     %cRed%[FEHLER]%cReset% Registry-Eintrag konnte nicht gesetzt werden. Fehlercode: !errorlevel!
        set /a failed+=1
    )
    echo.
)

echo %cOrange%----------------%cReset%
echo Zusammenfassung:
if !success! gtr 0 (
    echo     Erfolgreich: %cGreen%!success!%cReset%
) else (
    echo     Erfolgreich: !success!
)
if !failed! gtr 0 (
    echo          Fehler: %cRed%!failed!%cReset%
) else (
    echo          Fehler: !failed!
)
echo %cOrange%----------------%cReset%
echo.

if !failed! gtr 0 (
    echo %cRed%[FEHLER]%cReset% Es konnten nicht alle OneDrive-Ausschlussordner gesetzt werden.
    echo.
    pause
    endlocal
    exit /b 1
)

echo %cGreen%[OK]%cReset% Alle %cGreen%!success!%cReset% OneDrive-Ausschlussordner wurden erfolgreich gesetzt.
echo.
pause
endlocal
exit /b 0

:checkPrivileges
net session >nul 2>&1 && goto gotPrivileges
net file    >nul 2>&1 && goto gotPrivileges

rem Script mit UAC-Elevation neu starten
rem Absoluten Skriptpfad holen und UAC-Elevation auch ermöglichen wenn Script im Ordner mit Apostrophen liegt
set "SCRIPT=%~f0"
rem PowerShell-Single-Quotes escapen: ' -^> ''
set "SCRIPT=%SCRIPT:'=''%"
powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%SCRIPT%' -Verb RunAs" >nul 2>&1
if errorlevel 1 (
    echo %cRed%[FEHLER]%cReset% UAC-Abfrage wurde abgebrochen oder ist fehlgeschlagen.
    echo.
    pause
    exit /b 1
)
exit /b 0
