@echo off & color 2 & cls & title Bolle's Ereignisanzeige leeren (%0)

goto admincheck
:adminok

powershell "wevtutil el | Foreach-Object {wevtutil cl "$_"}"
:: Für Admin-CMD
:: for /F "tokens=*" %1 in ('wevtutil.exe el') DO wevtutil.exe cl "%1"
exit

:admincheck
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto adminok 
) else ( powershell "saps -filepath '%0' -verb runas" >nul 2>&1)
exit /b

:: 02.12.2018 Bolle
