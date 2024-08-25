@echo off & color 2 & cls & title Bolle's Name und Laufwerksbuchstabe ermitteln (%0)

set LW=%~d0
echo.
echo.
echo.
echo Name: [%0]
echo.
echo Laufwerk: [%~d0]
echo.
echo Variable LW (%%LW%%) = %LW%
echo.
echo.
echo.

pause>nul

rem 16:27 17.12.2007 Bolle