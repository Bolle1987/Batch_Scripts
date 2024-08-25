@echo off & color 2 & cls & title Bolle's Adminrechte anfordern (%0)

goto checkPrivileges
:gotPrivileges

echo Adminrechte bekommen!
pause
exit

:checkPrivileges 
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto gotPrivileges 
) else ( powershell "Start-Process -filepath '%0' -verb runas" >nul 2>&1)
exit /b