@echo off & color 2 & cls & title Bolle's WinGet Installer (%0)

echo ==========================
echo.
echo  Bolle's WinGet Installer
echo.
echo ==========================
echo.
echo Adminrechte anfordern...
goto checkPrivileges

:gotPrivileges
cls
echo ==========================
echo.
echo  Bolle's WinGet Installer
echo.
echo ==========================
echo.
echo Dies kann ein paar Minuten dauern.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
"$ProgressPreference='SilentlyContinue'; ^
$ErrorActionPreference='Stop'; ^
Write-Host 'Installing WinGet...'; ^
Install-PackageProvider -Name NuGet -Force -Confirm:$false ^| Out-Null; ^
Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -Confirm:$false ^| Out-Null; ^
Write-Host 'Initialising WinGet...'; ^
Repair-WinGetPackageManager -AllUsers; ^
Write-Host 'Updating Microsoft Store source...'; ^
winget source update --name msstore --disable-interactivity; ^
if ($LASTEXITCODE -ne 0) { throw 'Die WinGet-Quelle konnte nicht aktualisiert werden.' }; ^
winget search Bolle --source msstore --accept-source-agreements --disable-interactivity; ^
winget --info"

set "RESULT=%ERRORLEVEL%"

echo.
if not "%RESULT%"=="0" (
    color C
    echo Installation fehlgeschlagen. Fehlercode: %RESULT%
) else (
    echo Fertig!
)

echo.
pause
exit /b %RESULT%

:checkPrivileges
net session >nul 2>&1 && goto gotPrivileges
net file    >nul 2>&1 && goto gotPrivileges
set "SCRIPT=%~f0"
set "SCRIPT=%SCRIPT:'=''%"
powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%SCRIPT%' -Verb RunAs -ArgumentList '1'" >nul 2>&1
if errorlevel 1 (start "" cmd /c "color C & echo. & echo UAC-Abfrage wurde abgebrochen oder ist fehlgeschlagen. & echo. & pause" & exit /b 1)
exit /b 0
