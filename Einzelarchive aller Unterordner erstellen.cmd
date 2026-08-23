@echo off & color 0A & cls & title Bolle's Einzelarchive aller Unterordner erstellen (%~nx0)
setlocal DisableDelayedExpansion

rem =================================================================================================================
rem Erstellt für jeden direkten Unterordner des angegebenen Ordners ein eigenes ZIP- oder RAR-Archiv.
rem Der Quellordner kann per Drag & Drop, als Parameter oder durch manuelle Eingabe des Pfads angegeben werden.
rem Wahlweise wird nur der Inhalt eines Unterordners oder der Unterordner selbst in das jeweilige Archiv aufgenommen.
rem Bereits vorhandene Archive werden aktualisiert. WinRAR muss auf dem System installiert sein.
rem =================================================================================================================

rem =============
rem Einstellungen
rem =============

set ARCHIV=ZIP
rem Mögliche Werte: ZIP oder RAR

set STANDARDKONFIG=0
rem 0 = IGNORIEREN (-cfg-)
rem 1 = VERWENDEN

set HAUPTORDNER=0
rem 0 = NEIN - Nur der Inhalt liegt direkt im Archiv.
rem 1 = JA   - Der jeweilige Hauptordner liegt selbst im Archiv.

for /F %%a in ('echo prompt $E^|cmd') do set "ESC=%%a"
set "cRed=%ESC%[91m"
set "cGreen=%ESC%[92m"

set "WINRAR="
set "TARGET="
set "FOUND="
set "ERRORS="
set "ARCHIV_SWITCH="
set "ARCHIV_EXT="
set "CFG_SWITCH="
set "STANDARDKONFIG_TEXT="
set "HAUPTORDNER_TEXT="

rem ===================
rem Archivformat prüfen
rem ===================

if /I "%ARCHIV%"=="ZIP" (
    set "ARCHIV_SWITCH=-afzip"
    set "ARCHIV_EXT=zip"
) else if /I "%ARCHIV%"=="RAR" (
    set "ARCHIV_SWITCH=-afrar"
    set "ARCHIV_EXT=rar"
) else (
    echo.
    echo Ungueltiges Archivformat: %cRed%%ARCHIV%%cGreen%
    echo Erlaubte Werte sind: ZIP oder RAR
    echo.
    pause
    goto ende
)

rem ============================
rem Standardkonfiguration prüfen
rem ============================

if "%STANDARDKONFIG%"=="0" (
    set "CFG_SWITCH=-cfg-"
    set "STANDARDKONFIG_TEXT=IGNORIEREN"
) else if "%STANDARDKONFIG%"=="1" (
    set "CFG_SWITCH="
    set "STANDARDKONFIG_TEXT=VERWENDEN"
) else (
    echo.
    echo Ungueltiger Wert fuer STANDARDKONFIG: %cRed%%STANDARDKONFIG%%cGreen%
    echo Erlaubte Werte sind: 0 oder 1
    echo.
    pause
    goto ende
)

rem ==============================
rem Hauptordner-Einstellung prüfen
rem ==============================

if "%HAUPTORDNER%"=="0" (
    set "HAUPTORDNER_TEXT=NEIN"
) else if "%HAUPTORDNER%"=="1" (
    set "HAUPTORDNER_TEXT=JA"
) else (
    echo.
    echo Ungueltiger Wert fuer HAUPTORDNER: %cRed%%HAUPTORDNER%%cGreen%
    echo Erlaubte Werte sind: 0 oder 1
    echo.
    pause
    goto ende
)

rem ====================
rem Zielordner ermitteln
rem ====================

if not "%~1"=="" goto targetFromArgument

echo.
set /p "TARGET=Ordnerpfad eingeben: "
goto targetReady

:targetFromArgument
set "TARGET=%~1"

:targetReady
set "TARGET=%TARGET:"=%"

if not defined TARGET (
    echo.
    echo Es wurde %cRed%kein%cGreen% Ordner angegeben.
    echo.
    pause
    goto ende
)

for %%I in ("%TARGET%") do set "TARGET=%%~fI"

if not exist "%TARGET%\." (
    echo.
    echo Ordner %cRed%nicht%cGreen% gefunden:
    echo "%TARGET%"
    echo.
    pause
    goto ende
)

echo.
echo ===== Preflight-Check =====

rem =============
rem WinRAR suchen
rem =============

if exist "%ProgramFiles%\WinRAR\WinRAR.exe" (
    set "WINRAR=%ProgramFiles%\WinRAR\WinRAR.exe"
)

if not defined WINRAR if exist "%ProgramFiles(x86)%\WinRAR\WinRAR.exe" (
    set "WINRAR=%ProgramFiles(x86)%\WinRAR\WinRAR.exe"
)

if not defined WINRAR (
    for /f "delims=" %%W in ('where WinRAR.exe 2^>nul') do if not defined WINRAR set "WINRAR=%%W"
)

if defined WINRAR (
    echo WinRAR gefunden unter: %WINRAR%
) else (
    echo WinRAR %cRed%nicht%cGreen% gefunden - ohne WinRAR ist kein Packen moeglich.
    echo.
    echo ===========================
    echo.
    pause
    goto ende
)

echo Archivformat: %ARCHIV%
echo Standardkonfiguration: %STANDARDKONFIG_TEXT% (%STANDARDKONFIG%)
echo Hauptordner im Archiv: %HAUPTORDNER_TEXT% (%HAUPTORDNER%)
echo Zielordner: %TARGET%

rem ==================================
rem Schreibrechte im Zielordner prüfen
rem ==================================

set "WRITE_TEST=%TARGET%\.__archive_write_test_%RANDOM%_%RANDOM%.tmp"
echo Schreibtest>"%WRITE_TEST%" 2>nul

if exist "%WRITE_TEST%" (
    del /q "%WRITE_TEST%" >nul 2>&1
    echo Schreibrechte: vorhanden
    goto preflightDone
)

echo Schreibrechte: %cRed%nicht%cGreen% vorhanden.

if /I "%~2"=="__ELEVATED__" (
    echo.
    echo Auch mit Adminrechten konnte im Zielordner %cRed%nicht%cGreen% geschrieben werden.
    echo Bitte Berechtigungen des Ordners pruefen.
    echo.
    echo ===========================
    echo.
    pause
    goto ende
)

echo Adminrechte erforderlich - UAC-Abfrage wird gestartet ...
echo.
goto requestElevation

:preflightDone
echo ===========================
echo.

rem ===========================================================
rem In Zielordner wechseln und jeden Unterordner einzeln packen
rem ===========================================================

pushd "%TARGET%" >nul 2>&1

if errorlevel 1 (
    echo Zielordner konnte %cRed%nicht%cGreen% geoeffnet werden:
    echo "%TARGET%"
    echo.
    pause
    goto ende
)

echo Jeder direkte Unterordner wird als eigenes %ARCHIV%-Archiv gepackt.
echo Vorhandene Archive werden von WinRAR aktualisiert.
echo.

for /d %%D in (*) do (
    set "FOUND=1"
    echo Packe "%%D" ...

    if "%HAUPTORDNER%"=="1" (
        "%WINRAR%" a %CFG_SWITCH% %ARCHIV_SWITCH% -r "%%D.%ARCHIV_EXT%" "%%D" >nul
    ) else (
        "%WINRAR%" a %CFG_SWITCH% %ARCHIV_SWITCH% -r -ep1 "%%D.%ARCHIV_EXT%" "%%D\*" >nul
    )

    if errorlevel 1 (
        set "ERRORS=1"
        echo   %cRed%Fehler%cGreen% beim Packen von "%%D"
    ) else (
        echo   Fertig: "%%D.%ARCHIV_EXT%"
    )
)

popd

if not defined FOUND (
    echo.
    echo Keine Unterordner gefunden.
    echo.
    pause
    goto ende
)

echo.
if defined ERRORS (
    echo Vorgang beendet - mindestens ein Archiv konnte %cRed%nicht%cGreen% erfolgreich erstellt werden.
) else (
    echo Alle Unterordner erfolgreich als %ARCHIV% gepackt.
)
echo.
pause
goto ende

rem =============
rem UAC-Elevation
rem =============

:requestElevation
rem Script mit UAC-Elevation neu starten
rem Absoluten Skriptpfad holen und UAC-Elevation auch ermöglichen wenn Script oder Zielordner Apostrophe enthalten
set "SCRIPT=%~f0"
set "SCRIPT_PS=%SCRIPT:'=''%"
set "TARGET_PS=%TARGET:'=''%"

powershell -NoProfile -WindowStyle Hidden -Command "$arg=[char]34+'%TARGET_PS%'+[char]34+' __ELEVATED__'; Start-Process -FilePath '%SCRIPT_PS%' -ArgumentList $arg -Verb RunAs" >nul 2>&1

if errorlevel 1 (
    start "" cmd /c "color C & echo. & echo UAC-Abfrage wurde abgebrochen oder ist fehlgeschlagen. & echo. & pause"
    exit /b 1
)

exit /b 0

:ende
endlocal
exit /b 0
