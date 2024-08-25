@echo off & color 2 & cls & title Bolle's Toolbox (%0)
echo =====================
echo.
echo  Bolle's Toolbox.cmd
echo  to open Script from
echo   Chris Titus Tech
echo.
echo =====================
echo.

goto checkPrivileges
:gotPrivileges

powershell.exe -ExecutionPolicy Bypass -Command "iwr -useb https://christitus.com/win | iex"
exit

:checkPrivileges 
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto gotPrivileges 
) else ( powershell "saps -filepath '%0' -verb runas" >nul 2>&1)
exit /b