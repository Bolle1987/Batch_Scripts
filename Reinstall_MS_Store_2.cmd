@echo off & color 2 & cls & title Bolle's Reinstall MS Store (%0)
echo ================================
echo.
echo  Bolle's Reinstall_MS_Store.cmd
echo.
echo ================================
echo.
echo Reinstall can take a few minutes. There will be no info.
echo Just look into start menue till "Microsoft Store" appears.
echo.
echo Press any key to start reinstall MS Store
echo.

goto checkPrivileges
:gotPrivileges

pause >nul 2>nul
powershell.exe -ExecutionPolicy Bypass -Command "wsreset -i"
exit

:checkPrivileges 
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto gotPrivileges 
) else ( powershell "saps -filepath '%0' -verb runas" >nul 2>&1)
exit /b