@echo off & color 2 & cls & title Bolle's VirtualBox-NumPad-Fix (%0)

set path="C:\Program Files\Oracle\VirtualBox";%path%
set folder=%CD% & if exist %1 (set folder=%~1)
cd %folder%
cls
@echo.
echo Alle VM's in "%folder%" werden angepasst... &&echo.&&pause
@echo.
@echo on
for /f "tokens=*" %%M in ('dir /b /a:d ".\*"') do (VBoxManage setextradata "%%M" GUI/HidLedsSync "0")
@echo off
@echo.
pause