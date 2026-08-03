@echo off & setlocal & color 2 & cls & title Bolle's Toolbox-Loader (%0)

echo ========================
echo.
echo  Bolle's Toolbox-Loader
echo.
echo ========================
echo.
echo.
echo  [1] WinUtil (Chris Titus Tech)
echo  [2] Winhance (Mems Tech Tips)
echo  [0] Beenden
echo.

choice /C 120 /N /T 10 /D 0 /M "Auswahl: "

if errorlevel 3 goto :ende

if errorlevel 2 (
    set "ToolName=Winhance"
    set "ToolUrl=https://get.winhance.net"
    goto :laden
)

if errorlevel 1 (
    set "ToolName=Chris Titus Tech WinUtil"
    set "ToolUrl=https://christitus.com/win"
    goto :laden
)

goto :ende

:laden
echo.
echo %ToolName% wird geladen ...
echo.

rem powershell.exe -NoProfile -Command "Invoke-RestMethod -Uri '%ToolUrl%' -ErrorAction Stop | Invoke-Expression"
powershell.exe -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12; try { Invoke-RestMethod -Uri '%ToolUrl%' -ErrorAction Stop | Invoke-Expression } catch { Write-Error $_.Exception.Message; exit 1 }"

if errorlevel 1 (
    echo.
    echo Fehler: %ToolName% konnte nicht gestartet werden.
    echo.
    pause
	goto :ende
)

:ende
endlocal
