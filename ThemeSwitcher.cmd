@echo off & color 2 & cls & title Bolle's Windows Dark / Light Theme Switcher (%0)

:MENU
cls
echo =============================================
echo.
echo  Bolle's Windows Dark / Light Theme Switcher
echo.
echo =============================================
echo.
echo  [1] Dark Mode aktivieren
echo  [2] Light Mode aktivieren
echo  [0] Beenden
echo.
set CHOICE=
set /p CHOICE=Bitte Auswahl treffen (leer = Wechsel): 

if "%CHOICE%"=="1" goto DARK
if "%CHOICE%"=="2" goto LIGHT
if "%CHOICE%"=="0" exit
if "%CHOICE%"=="" goto TOGGLE
echo.
echo Beende
timeout /t 1 >nul
exit

:DARK
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f >nul
goto APPLY

:LIGHT
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 1 /f >nul
goto APPLY

:TOGGLE

reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme 2>nul | findstr /i "0x0" >nul
if %ERRORLEVEL%==0 goto LIGHT

reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme 2>nul | findstr /i "0x1" >nul
if %ERRORLEVEL%==0 goto DARK

echo.
echo Wert kann nicht ausgelesen werden...
echo.
timeout /t 2 >nul
goto MENU

:APPLY
echo.
echo Design wird angewendet ...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
timeout /t 2 >nul
echo Fertig!
timeout /t 1 >nul
exit