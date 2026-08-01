@echo off & color 0A & cls & title Bolle's AdGuardHome Config Download (%0)
setlocal enabledelayedexpansion

set "PI_HOST=192.168.178.2"
set "PI_USER=pi"
set "SSH_KEY="
::  "SSH_KEY=C:\Tools\SSH-Key.ppk"
set "REMOTE_FILE=/opt/AdGuardHome/AdGuardHome.yaml"
set "LOCAL_FILE=%~dp0AdGuardHome.yaml"
set "LOG=%temp%\pscp_output_%random%.log"
set "PAGEANT_STARTED_BY_US=0"
set "ANY_TOOL_MISSING=0"

for /F %%a in ('echo prompt $E^|cmd') do set "ESC=%%a"
set "cRed=%ESC%[91m"
set "cGreen=%ESC%[92m"

echo ===== Preflight-Check =====

set "PSCP_FOUND=0"
for /f "delims=" %%p in ('where pscp 2^>nul') do (
    if "!PSCP_FOUND!"=="0" (
        set "PSCP_PATH=%%p"
        set "PSCP_FOUND=1"
    )
)
if "!PSCP_FOUND!"=="1" (
    echo pscp gefunden unter: !PSCP_PATH!
) else (
    echo pscp %cRed%nicht%cGreen% gefunden - ohne pscp ist kein Download moeglich.
)

set "PLINK_FOUND=0"
for /f "delims=" %%p in ('where plink 2^>nul') do (
    if "!PLINK_FOUND!"=="0" (
        set "PLINK_PATH=%%p"
        set "PLINK_FOUND=1"
    )
)
if "!PLINK_FOUND!"=="1" (
    echo plink gefunden unter: !PLINK_PATH!
) else (
    echo plink %cRed%nicht%cGreen% gefunden.
    set "ANY_TOOL_MISSING=1"
)

set "PAGEANT_FOUND=0"
if not "%SSH_KEY%"=="" (
    if exist "%SSH_KEY%" (
        echo SSH-Key gefunden unter: %SSH_KEY%
        for /f "delims=" %%p in ('where pageant 2^>nul') do (
            if "!PAGEANT_FOUND!"=="0" (
                set "PAGEANT_PATH=%%p"
                set "PAGEANT_FOUND=1"
            )
        )
        if "!PAGEANT_FOUND!"=="1" (
            echo Pageant gefunden unter: !PAGEANT_PATH!
        ) else (
            echo Pageant %cRed%nicht%cGreen% gefunden - Authentifizierung faellt auf Passwort zurueck.
            set "ANY_TOOL_MISSING=1"
        )
    ) else (
        echo SSH-Key %cRed%nicht%cGreen% gefunden unter "%SSH_KEY%"
    )
) else (
    tasklist /FI "IMAGENAME eq pageant.exe" 2>nul | find /I "pageant.exe" >nul
    if not errorlevel 1 (
        echo Pageant laeuft bereits
    )
)

if "!ANY_TOOL_MISSING!"=="1" (
    echo.
    echo https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
)

echo ===========================
echo.

if "!PSCP_FOUND!"=="0" (
    echo pscp wurde %cRed%nicht%cGreen% gefunden - Download %cRed%nicht%cGreen% moeglich. Bitte PuTTY-Installation pruefen.
	echo Downloads sind zu finden unter %cRed%https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html%cGreen%
    echo.
    pause
    goto :ende
)

if exist "%SSH_KEY%" if "!PAGEANT_FOUND!"=="1" (
    tasklist /FI "IMAGENAME eq pageant.exe" 2>nul | find /I "pageant.exe" >nul
    if errorlevel 1 (
        echo Pageant laeuft nicht - wird jetzt gestartet ...
        set "PAGEANT_STARTED_BY_US=1"
    ) else (
        echo Pageant laeuft bereits.
    )
    echo Lade Schluessel in Pageant ...
    start "" pageant "%SSH_KEY%"
    echo Falls ein Pageant-Fenster nach einer %cRed%Passphrase%cGreen% fragt, dort eingeben.
    echo Danach hier eine Taste druecken, um fortzufahren.
    pause
    echo.
)

echo Lade Config vom Pi herunter ...
echo.
pscp -P 22 %PI_USER%@%PI_HOST%:%REMOTE_FILE% "%LOCAL_FILE%" > "%LOG%" 2>&1

if %errorlevel%==0 (
    type "%LOG%"
    del "%LOG%" >nul 2>&1
    echo.
    echo Download erfolgreich.
    echo Datei gespeichert unter: %LOCAL_FILE%
    echo.
    pause
    goto :ende
)

type "%LOG%"
findstr /i "permission denied" "%LOG%" >nul
set "WAS_PERMISSION_ERROR=%errorlevel%"
del "%LOG%" >nul 2>&1

if %WAS_PERMISSION_ERROR%==0 (
    if "!PLINK_FOUND!"=="0" (
        echo.
        echo Permission-Fehler erkannt, aber plink ^(fuer automatische Reparatur^) wurde %cRed%nicht%cGreen% gefunden.
        echo Bitte manuell auf dem Pi beheben ^(oder plink downloaden^):
        echo   %cRed%sudo chmod o+x /opt/AdGuardHome%cGreen%
        echo   %cRed%sudo chmod o+r /opt/AdGuardHome/AdGuardHome.yaml%cGreen%
        echo.
        pause
        goto :ende
    )
    echo.
    echo Permission-Fehler erkannt. Verbinde per plink und setze Rechte ...
    echo.
    plink -ssh %PI_USER%@%PI_HOST% "sudo chmod o+x /opt/AdGuardHome && sudo chmod o+r /opt/AdGuardHome/AdGuardHome.yaml"
    echo.
    echo Versuche Download erneut ...
    echo.
    pscp -P 22 %PI_USER%@%PI_HOST%:%REMOTE_FILE% "%LOCAL_FILE%"
    if !errorlevel!==0 (
        echo.
        echo Download erfolgreich.
        echo Datei gespeichert unter: %LOCAL_FILE%
        echo.
        pause
    ) else (
        echo.
        echo Download nach Rechte-Reparatur weiterhin fehlgeschlagen. Bitte pruefen.
        echo.
        pause
    )
) else (
    echo.
    echo Fehler beim Download - kein Rechteproblem erkannt. Bitte pruefen.
    echo.
    pause
)

:ende
if "%PAGEANT_STARTED_BY_US%"=="1" (
    echo.
    echo Beende Pageant wieder, da es von diesem Skript gestartet wurde ...
    taskkill /IM pageant.exe /F >nul 2>&1
	ping 127.0.0.1 -n 3 >nul 2>&1
)
exit