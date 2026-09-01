@echo off & color 2 & cls & title FIREBIRD Datenbank-Restore

set databasedir=C:\Datenbanken
set databases=database1,database2,database3
set dbextension=fdb
set backupextension=fbk
set databaseserver=localhost
set fbport=3050
set databasebackupdir=%databasedir%
set contact=support@mydomain.com
set showpause=0
set createlog=1
set showlog=1
set checkuac=1
set checksysdba=1
set pauseservices=servicename1,servicename2
set restoreparameter=-c -v -p 16384 -se service_mgr
set fixcharset=0
set maxbackups=9

:: 20260506 https://github.com/Bolle1987
if %checkuac%==1 goto checkPrivileges
:gotPrivileges
set h=%time:~0,2%
set h=%h: =0%
set m=%time:~3,2%
set ISC_USER=SYSDBA
set ISC_PASSWORD=
if not %createlog%==1 set showpause=1
if NOT %databasedir:~-1%=="\" set databasedir=%databasedir%\
if NOT %databasebackupdir:~-1%=="\" set databasebackupdir=%databasebackupdir%\
FOR /F "tokens=1,2,3,4 delims=/. " %%f in ('date/T') do set DATUM=%%f.%%g.%%h
path %path%;%ProgramFiles%\Firebird\Firebird_3_0;%ProgramFiles%\firebird\firebird_2_5\bin;%ProgramFiles%\firebird\firebird_2_1\bin;%ProgramFiles%\firebird\firebird_2_0\bin;%ProgramFiles%\firebird\firebird_1_5\bin
path %path%;%ProgramFiles(x86)%\Firebird\Firebird_3_0;%ProgramFiles(x86)%\Firebird\Firebird_2_5\bin;%ProgramFiles(x86)%\firebird\firebird_2_1\bin;%ProgramFiles(x86)%\firebird\firebird_2_0\bin;%ProgramFiles(x86)%\firebird\firebird_1_5\bin


cls
title FIREBIRD Datenbank-Restore in %databasedir%
echo  ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
echo  º                                 º
echo  º F I R E B I R D   R e s t o r e º
echo  º                                 º
echo  ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
echo.
if %fixcharset%==1 ( color 4
echo   WICHTIG: Die Variable fixcharset nach dem Restore wieder auf 0 setzen, da sonst die Datenbank immer weiter w„chst!
@echo  & ping 127.0.0.1 >nul 2>nul
color 2)
echo Folgende Datenbanken werden wiederhergestellt:
echo.
set fehler=0
for %%d in (%databases%) do (
	if not exist %databasebackupdir%%%d.%backupextension% (
		set fehler=1
		echo %%d -^> FEHLER: "%databasebackupdir%%%d.%backupextension%" nicht vorhanden
		@echo 
		) else (@echo %%d)
		)
		if %fehler%==1 (color CF
		echo.
		echo Bei Unklarheiten informieren Sie den Administrator! %contact%
		@echo  & pause
		start notepad.exe %0
		exit)
@echo.
@echo.
:pass
if [%ISC_PASSWORD%] EQU [] set /P ISC_PASSWORD=Bitte Firebird SYSDBA Passwort eingeben: 
gsec -user sysdba -password %ISC_PASSWORD% -display >nul 2>nul
if not %errorlevel%==0 if %checksysdba%==1 echo Passworteingabe inkorrekt, wiederhole... & echo. &set ISC_PASSWORD=& goto:pass
echo Restore 	von %Username% am %DATUM% um %h%:%m% Uhr >> %~dp0FIREBIRD_HISTORIE.txt
@echo.
@echo.
@echo.
@echo Dienste werden gestoppt...
for %%s in (%pauseservices%) do net stop %%s 2>nul
if %showpause%==1 cls
@echo.
@echo.
@echo.
for %%d in (%databases%) do (
	if %showpause%==1 cls
	title FIREBIRD - Wiederherstellung von %%d.%dbextension%
	if exist "%databasedir%%%d.%dbextension:~0,-1%%maxbackups%" del "%databasedir%%%d.%dbextension:~0,-1%%maxbackups%"
	set /A a=%maxbackups%
	set /A b=%maxbackups%+1
	Setlocal EnableDelayedExpansion 
	for %%i in (30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1) do (
		if exist  "%databasedir%%%d.%dbextension:~0,-1%!a!" ren  "%databasedir%%%d.%dbextension:~0,-1%!a!" "%%d.%dbextension:~0,-1%!b!"
	set /A a-=1
	set /A b-=1
	)
	if exist "%databasedir%%%d.%dbextension%" ren "%databasedir%%%d.%dbextension%" "%%d.%dbextension:~0,-1%1"
	if %fixcharset%==1 (set fixcharsetparam= -fix_fss_d WIN1252 -fix_fss_m WIN1252)
	if %createlog%==1 (
		set gbaklog="%databasedir%%DATUM%_%h%-%m%_Restore_%%d.log"
		set gbaklogold="%DATUM%_%h%-%m%_Restore_%%d.log_old"
		if exist !gbaklog!_old del !gbaklog!_old
		if exist !gbaklog! ren !gbaklog! !gbaklogold!
		set startzeit=Startzeit: !DATE! !TIME:~0,-3!
		@echo Das Restore der "%databasedir%%%d.%dbextension%" Datenbank 
		@echo wird durchgefhrt, bitte warten...
		@echo.
		gbak %restoreparameter%!fixcharsetparam! -service %databaseserver%/%fbport%:service_mgr "%databasebackupdir%%%d.%backupextension%" "%databasedir%%%d.%dbextension%" -y !gbaklog!
		gfix -write sync %databaseserver%/%fbport%:"%databasedir%%%d.%dbextension%" >> !gbaklog!
		set fehler=1
		find "finishing, closing, and going home" !gbaklog! >nul && set fehler=0
		if !fehler!==1 color CF && echo 		es traten Fehler auf >> %~dp0FIREBIRD_HISTORIE.txt
		find "Firebird login" !gbaklog! >nul && set fehler=2
		if !fehler!==2 (color CF && echo 		es traten Fehler auf: Firebirdlogin >> %~dp0FIREBIRD_HISTORIE.txt
			cls
			title FIREBIRD - F E H L E R bei Firebirdlogin
			echo.
			echo Firebirdlogin inkorrekt. Bitte SYSDBA Passwort "%ISC_PASSWORD%" prfen
			echo Bitte beliebige Taste drcken, um die Dienste wieder starten zu lassen
			@echo  & pause>nul
			rem ren "%databasedir%%%d.FD1" "%databasedir%%%d.%dbextension%"
			goto:Dienste)
		find "I/O error" !gbaklog! >nul && set fehler=3
		if !fehler!==3 (color CF && echo 		es traten Fehler auf: Verzeichnisfehler >> %~dp0FIREBIRD_HISTORIE.txt
			title FIREBIRD - F E H L E R bei Sicherung von %%d.%dbextension%
			echo.
			echo Datenbank nicht vorhanden. Bitte "%databasedir%%%d.%dbextension%" prfen
			echo Abbruch empfohlen
			@echo  & pause)
		@echo. >> !gbaklog!
		@echo. >> !gbaklog!
		@echo. >> !gbaklog!
		@echo Die letzte obere Zeile muss wie folgt lauten:  >> !gbaklog!
		@echo "gbak:finishing, closing, and going home"  >> !gbaklog!
		@echo. >> !gbaklog!
		@echo Falls der Text anders lautet, gab es Probleme beim Restore der Datenbank: >> !gbaklog!
		@echo "%databasedir%%%d.%dbextension%" ! >> !gbaklog!
		@echo Dann muss ggf. der Administrator informiert werden! %contact% >> !gbaklog!
		@echo. >> !gbaklog!
		@echo. >> !gbaklog!
		@echo. >> !gbaklog!
		@echo !startzeit! >> !gbaklog!
		@echo Endzeit: !DATE! !TIME:~0,-3! >> !gbaklog!
		@echo Das Restore der "%databasedir%%%d.%dbextension%" Datenbank 
		@echo wurde durchgefhrt. Das Protokoll wurde gespeichert unter:
		@echo !gbaklog! 
		if not exist !gbaklog! (color CF && echo 		es traten Fehler auf: Protokollfehler >> %~dp0FIREBIRD_HISTORIE.txt
			title FIREBIRD - F E H L E R bei Wiederherstellung von %%d.%dbextension%
			echo.
			echo Protokoll nicht verfgbar, bitte Pfadangabe "%databasedir%" prfen
			echo Abbruch empfohlen
			@echo  & pause)
		if %showlog%==1 (
			echo und wird nun ge”ffnet
			if %showpause%==1 (
				if exist !gbaklog! notepad.exe !gbaklog!
				) else (
				if exist !gbaklog! start notepad.exe !gbaklog!
				)
			)
		if !fehler!==1 color CF
		@echo.
		@echo.
	) else (
		if exist "%databasedir%%%d.%dbextension%" ren "%databasedir%%%d.%dbextension%" "%%d.%dbextension:~0,-1%1"
		@echo Das Restore der "%databasedir%%%d.%dbextension%" Datenbank 
		@echo wird durchgefhrt, bitte warten...
		@echo.
		@color 20
		gbak %restoreparameter%!fixcharsetparam! "%databasebackupdir%%%d.%backupextension%" -service %databaseserver%/%fbport%:service_mgr "%databasedir%%%d.%dbextension%"
		gfix -write sync %databaseserver%/%fbport%:"%databasedir%%%d.%dbextension%"
		@color 2
		@echo.
		@echo.
		@echo.
		@echo Die letzte obere Zeile muss wie folgt lauten: 
		@echo "gbak:finisching, closing und going home" 
		@echo.
		@echo Falls der Text anders lautet, gab es Probleme beim Restore der Datenbank:
		@echo "%databasedir%%%d.%dbextension%" !
		@echo Dann muss ggf. der Administrator informiert werden! %contact%
		@echo.
		@echo.
		@echo.
		)
	Endlocal
	if %showpause%==1 @echo  & pause
	)
:Dienste
if %showpause%==1 cls
if %showpause%==1 @echo.
if %showpause%==1 @echo.
@echo.
@echo Dienste werden gestartet...
for %%s in (%pauseservices%) do net start %%s 2>nul
if %showpause%==1 ping 127.0.0.1 >nul 2>nul
title FIREBIRD Datenbank-Restore in %databasedir% beendet!
if %fixcharset%==1 (start notepad.exe %0)
if %showpause%==0 (
	@echo.
	@echo.
	@echo.
	@echo Bitte kontrollieren Sie die Protokolle!
	@echo Ist dieses Fenster ROT, liegen definitiv Fehler vor!
	@echo Bei Unklarheiten informieren Sie den Administrator! %contact%
	@echo  & ping 127.0.0.1 -n 3 >nul 2>nul
	pause
	)
exit

:checkPrivileges
net session >nul 2>&1 && goto gotPrivileges
net file    >nul 2>&1 && goto gotPrivileges
set "SCRIPT=%~f0"
set "SCRIPT=%SCRIPT:'=''%"
powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%SCRIPT%' -Verb RunAs" >nul 2>&1
if errorlevel 1 (start "" cmd /c "color C & echo. & echo UAC-Abfrage wurde abgebrochen oder ist fehlgeschlagen. & echo. & pause" & exit /b 1)
exit /b 0