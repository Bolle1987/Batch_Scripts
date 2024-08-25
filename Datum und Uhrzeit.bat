@echo off & color 2 & cls & title Bolle's Datum und Uhrzeit (%0)

set h=%time:~0,2%
set m=%time:~3,2%
FOR /F "tokens=1,2,3,4 delims=/. " %%a in ('date/T') do set DATUM=%%a.%%b.%%c

echo.
echo.
echo.
echo Datum und Uhrzeit : %DATUM% %h%:%m% Uhr
echo.
echo.
echo.
pause>nul

rem 22:18 13.12.2007 Bolle