@echo off & color 2 & cls & title Bolle's Zeit mit Sekunden (%0)

:Time
echo um %time:~0,2%:%time:~3,2%:%time:~6,2%
ping 127.0.0.1 -n 3 >nul 2>nul
goto :Time
pause >nul