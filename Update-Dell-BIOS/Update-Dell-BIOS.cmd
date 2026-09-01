@echo off & color 2 & cls & title Bolle's Dell BIOS Updater (%0)
echo ==============================
echo.
echo  Bolle's Update-Dell-BIOS.cmd
echo.
echo ==============================
echo.

goto checkPrivileges
:gotPrivileges
echo.
echo WARNING:
echo This script performs a BIOS update.
echo BIOS updates can render a device unusable.
echo Use at your own risk.
echo.
echo Ensure:
echo  - You are running this on a Dell system
echo  - The device is connected to reliable power
echo  - Important data is backed up
echo.
pause
echo.
powershell.exe -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/Bolle1987/Scripts/main/Update-Dell-BIOS/Update-Dell-BIOS.ps1)"
exit

:checkPrivileges
net session >nul 2>&1 && goto gotPrivileges
net file    >nul 2>&1 && goto gotPrivileges
set "SCRIPT=%~f0"
set "SCRIPT=%SCRIPT:'=''%"
powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%SCRIPT%' -Verb RunAs" >nul 2>&1
if errorlevel 1 (start "" cmd /c "color C & echo. & echo UAC-Abfrage wurde abgebrochen oder ist fehlgeschlagen. & echo. & pause" & exit /b 1)
exit /b 0