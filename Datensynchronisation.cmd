@echo off & setlocal enabledelayedexpansion
rem ========================== Beschreibung ==========================
rem =                                                                =
rem =                   Datensynchronisierungstool                   =
rem =                                                                =
rem = Letzter Bearbeiter  :  Bolle                                   =
rem = Zuletzt bearbeitet  :  08:51 16.01.2012 Uhr                    =
rem = Versionsinformation :  1.0                                     =
rem = Kontaktinformation  :  https://github.com/Bolle1987            =
rem =                                                                =
rem =                                                                =
rem = L E G E N D E                                                  =
rem =                                                                =
rem = Datenquelle= Quellpfad bitte aus der Adressleiste kopieren     =
rem = Datenziel=   Zielpfad  bitte aus der Adressleiste kopieren     =
rem =                                                                =
rem = Ordner= f r die spezielle Ordnersynchronisation                =
rem =         Bitte durch Kommata trennen (z.B. Datenbanken,Dienste) =
rem =                                                                =
rem = Dateiausnahmen= Ausnahmen f r bestimmte Dateien                =
rem =                 - absolute Pfade (z.B. "C:\test.zip")          =
rem =                 - Dateinamen (z.B. "test.zip")                 =
rem =                 - Dateiendungen (z.B. "*.zip")                 =
rem =                                                                =
rem = Ordnerausnahmen= Ausnahmen f r bestimmte Ordner                =
rem =                  - absolute Pfade (z.B. "C:\WINDOWS")          =
rem =                  - ganze Ordnernamen (z.B. "WINDOWS")          =
rem =                  - TIPP: Adressleite des Quellpfades kopieren  =
rem =                                                                =
rem =                 Bei Ausnahmen gelten folgende Regeln:          =
rem =                 + Immer aus Sicht der Quelle                   =
rem =                 + In Anf hrungszeichen "" zu setzen            =
rem =                 + Bei Mehrfachwahl durch Leerzeichen getrennt  =
rem =                 + wird kein absoluter Pfad angegeben, gilt die =
rem =                   Ausnahme f r alle Ordner und Unterordner     =
rem =                                                                =
rem = log=    Logdatei erzeugen und anzeigen lassen                  =
rem = syntax= Die robocopy Syntax des Jobs zus tzlich anzeigen       =
rem =                                                                =
rem =         Folgenden Werte werden akzeptiert:                     =
rem =         1 / on / an / aktiviert / aktiv                        =
rem =         0 / off / aus / deaktiviert / inaktiv                  =
rem =         keinen Wert einzutragen entspricht DEAKTIVIERT         =
rem =                                                                =
rem =                                                                =
rem =                                                                =
rem ==================================================================

set Datenquelle=\\tsclient\C\Test
set Datenziel=C:\Test

set Ordner=Datenbanken,Dienste,Log

set Dateiausnahmen="*.TMP" "*.ini"
set Ordnerausnahmen="\\tsclient\C\Test\update" "\\tsclient\C\Test\install"

set log=an
set syntax=aus







:MAINMENU
color F0
rem if not %computername%==SERVER exit
if not exist "%windir%\system32\robocopy.exe" (
echo.
echo.
echo Robocopy ist auf diesem Rechner ^(%computername%^) nicht installiert.
echo.
echo.
pause
start http://en.wikipedia.org/wiki/Robocopy
exit
) else (cls)
if "%1"=="editiert" (goto:Parameter) else (echo.)
title Datensynchronisation - zum Abbrechen einfach ENTERN ohne Eingabe
echo                                           ͻ
echo                                             
echo    D a t e n s y n c h r o n i s a t i o n  
echo                                             
echo                                           ͼ
echo.
echo  n = Normal (Alles synchronisieren)
echo  s = Speziell (Nur bestimmte unterordner)
echo.
echo.
echo.
echo.
echo.
echo.
SET Auswahl=X
SET /P Auswahl=Bitte w hlen: 
if (%Auswahl%)==(X) (exit) else (goto:Parameter)
:Parameter
if not "%Dateiausnahmen%"=="" (set Dateiausnahme=/XF %Dateiausnahmen%) else (set Dateiausnahme=)
if not "%Ordnerausnahmen%"=="" (set Ordnerausnahme=/XD %Ordnerausnahmen%) else (set Ordnerausnahme=)
for /f "delims=" %%i in ("%Datenquelle%") do set "Datenquelle=%%~fi"
if "%Datenquelle:~-1%"=="\" set "Datenquelle=%Datenquelle:~,-1%"
if "%Datenquelle:~-1%"==":" set "Datenquelle=%Datenquelle%\."
for /f "delims=" %%i in ("%Datenziel%") do set "Datenziel=%%~fi"
if "%Datenziel:~-1%"=="\" set "Datenziel=%Datenziel:~,-1%"
if "%Datenziel:~-1%"==":" set "Datenziel=%Datenziel%\."
FOR /F "tokens=1,2,3,4 delims=/. " %%f in ('date/T') do set DATUM=%%f.%%g.%%h
set h=%time:~0,2%
set m=%time:~3,2%
set logging=
set optionen=1,on,an,aktiviert,aktiv
for %%l in (%optionen%) do (
if "%log%"=="%%l" (
set logdatei=Synchronisation_%DATUM%_%h%-%m%.txt
set logging=/TEE /Log+:!logdatei!
echo Gestartet am %DATUM% um %h%:%m% Uhr von: > !logdatei!
whoami >> !logdatei!
echo ----------------------------------------- >> !logdatei!
) else (echo.)
)
Goto :%Auswahl%
Goto :MAINMENU


:: NORMAL - Von Datenquelle nach Datenziel
:n
title Datensynchronisation - Normal
cls
echo.
echo Es wird synchronisiert von:
echo %Datenquelle%
echo.
echo nach:
echo %Datenziel%
echo.
for %%o in (%optionen%) do (
if "%syntax%"=="%%o" (
echo Die Syntax dazu lautet:
echo "%windir%\system32\robocopy.exe" "%Datenquelle%" "%Datenziel%" /MIR %Dateiausnahme% %Ordnerausnahme% %logging%
echo.
) else (echo.)
)
SET /P Abfrage=Bitte mit "ok" best tigen: 
if not (%Abfrage%)==(ok) (exit)
"%windir%\system32\robocopy.exe" "%Datenquelle%" "%Datenziel%" /MIR %Dateiausnahme% %Ordnerausnahme% %logging%
for %%l in (%optionen%) do (
if %log%==%%l (notepad.exe %logdatei%) else (echo.)
)
exit


:: SPEZIELL - SpeziellDatenquellOrdner von SpeziellDatenquelle nach SpeziellDatenziel
:s
title Datensynchronisation - Speziell
cls
if "%Ordner%"=="" (
echo.
echo Es wurden keine speziellen Ordner angegeben. Bitte durchf hren.
echo.
echo.
echo.
pause
notepad %0
call %0 editiert
) else (echo.)
echo Es werden von:
echo %Datenquelle%
echo.
echo nach:
echo %Datenziel%
echo.
echo folgende Ordner synchronisiert:
for %%s in (%Ordner%) do (
echo %%s
)
echo.
for %%o in (%optionen%) do (
if "%syntax%"=="%%o" (
echo Die Syntax dazu lautet ^(wobei %%s durch die o.g. Ordner zu ersetzen ist^):
echo "%windir%\system32\robocopy.exe" "%Datenquelle%\%%s" "%Datenziel%\%%s" /MIR %Dateiausnahme% %Ordnerausnahme% %logging%
echo.
) else (echo.)
)
SET /P Abfrage=Bitte mit "ok" best tigen: 
if not (%Abfrage%)==(ok) (exit)
for %%s in (%Ordner%) do (
"%windir%\system32\robocopy.exe" "%Datenquelle%\%%s" "%Datenziel%\%%s" /MIR %Dateiausnahme% %Ordnerausnahme% %logging%
)
for %%l in (%optionen%) do (
if %log%==%%l (notepad.exe %logdatei%) else (echo.)
)
exit
