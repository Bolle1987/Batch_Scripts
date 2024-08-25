@echo off & color 2 & cls & title Bolle's Zeit mit Sekunden in einzelen Variablen (%0)

for /f "tokens=1,2 delims=: " %%d in ('time /T') do set Zeit=%%d:%%e:%time:~6,2%
for /f "tokens=1 delims=: " %%e in ('time /T') do set Zeith=%%e
for /f "tokens=2 delims=: " %%f in ('time /T') do set Zeitm=%%f
set Zeits=%time:~6,2%

echo %Zeit% 
echo Stunde:  %Zeith% 
echo Minute:  %Zeitm% 
echo Sekunde: %Zeits% 
pause >nul