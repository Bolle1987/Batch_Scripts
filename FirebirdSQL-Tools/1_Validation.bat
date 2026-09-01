@echo off & color 2 & cls & title FIREBIRD Datenbank-Validation

set databasedir=C:\Datenbanken
set databases=database1,database2,database3
set dbextension=fdb
set databaseserver=localhost
set fbport=3050
set contact=support@mydomain.com
set showpause=0
set createlog=1
set showlog=1
set checkuac=1
set checksysdba=1
set pauseservices=servicename1,servicename2
set validationparameter=-v -full -ignore -no_update





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
FOR /F "tokens=1,2,3,4 delims=/. " %%f in ('date/T') do set DATUM=%%f.%%g.%%h
path %path%;%ProgramFiles%\Firebird\Firebird_3_0;%ProgramFiles%\firebird\firebird_2_5\bin;%ProgramFiles%\firebird\firebird_2_1\bin;%ProgramFiles%\firebird\firebird_2_0\bin;%ProgramFiles%\firebird\firebird_1_5\bin
path %path%;%ProgramFiles(x86)%\Firebird\Firebird_3_0;%ProgramFiles(x86)%\Firebird\Firebird_2_5\bin;%ProgramFiles(x86)%\firebird\firebird_2_1\bin;%ProgramFiles(x86)%\firebird\firebird_2_0\bin;%ProgramFiles(x86)%\firebird\firebird_1_5\bin



cls
title FIREBIRD Datenbank-Validation in %databasedir%
echo  ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
echo  º                                       º
echo  º F I R E B I R D   V a l i d a t i o n º
echo  º                                       º
echo  ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
echo.
echo Folgende Datenbanken werden berprft:
echo.
set fehler=0
for %%d in (%databases%) do (
	if not exist %databasedir%%%d.%dbextension% (
		set fehler=1
		echo %%d -^> FEHLER: "%databasedir%%%d.%dbextension%" nicht vorhanden
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
if %ISC_PASSWORD%==firebird goto:sysdbachange
if %ISC_PASSWORD%==sysdba goto:sysdbachange
if %ISC_PASSWORD%==change goto:sysdbachange
gsec -user sysdba -password %ISC_PASSWORD% -display >nul 2>nul
if not %errorlevel%==0 if %checksysdba%==1 echo Passworteingabe inkorrekt, wiederhole... & echo. &set ISC_PASSWORD=& goto:pass
echo Validation	von %Username% am %DATUM% um %h%:%m% Uhr >> %~dp0FIREBIRD_HISTORIE.txt
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
	title FIREBIRD - šberprfung von %%d.%dbextension%
	if %createlog%==1 (
		Setlocal EnableDelayedExpansion 
		set gfixlog="%databasedir%%DATUM%_%h%-%m%_Validation_%%d.log"
		set gfixlogold="%DATUM%_%h%-%m%_Validation_%%d.log_old"
		if exist !gfixlog!_old del !gfixlog!_old
		if exist !gfixlog! ren !gfixlog! !gfixlogold!
		set startzeit=Startzeit: !DATE! !TIME:~0,-3!
		@echo.
		@echo Datenbank "%databasedir%%%d.%dbextension%" wird heruntergefahren...
        	gfix -shut -force 0 %databaseserver%/%fbport%:"%databasedir%%%d.%dbextension%" >> !gfixlog!
		@echo Datenbank "%databasedir%%%d.%dbextension%" wird berprft...
		gfix %validationparameter% %databaseserver%/%fbport%:"%databasedir%%%d.%dbextension%" 1>> !gfixlog!
		gfix %validationparameter% %databaseserver%/%fbport%:"%databasedir%%%d.%dbextension%" 2>> !gfixlog!
		find "Firebird login" !gfixlog! >nul && set fehler=1
		if !fehler!==1 (color CF && echo 		es traten Fehler auf: Firebirdlogin >> %~dp0FIREBIRD_HISTORIE.txt
			cls
			title FIREBIRD - F E H L E R bei Firebirdlogin
			echo.
			echo Firebirdlogin inkorrekt. Bitte SYSDBA Passwort "%ISC_PASSWORD%" prfen
			echo Bitte beliebige Taste drcken, um die Dienste wieder starten zu lassen
			@echo  & pause>nul
			goto:Dienste)
		find "I/O error" !gfixlog! >nul && set fehler=2
		if !fehler!==2 (color CF && echo 		es traten Fehler auf: Verzeichnisfehler >> %~dp0FIREBIRD_HISTORIE.txt
			title FIREBIRD - F E H L E R bei šberprfung von %%d.%dbextension%
			echo.
			echo Datenbank nicht vorhanden. Bitte "%databasedir%%%d.%dbextension%" prfen
			echo Abbruch empfohlen
			@echo  & pause>nul)
		@echo. >> !gfixlog!
        	@echo Datenbank "%databasedir%%%d.%dbextension%" wird wieder hochgefahren...
        	gfix -online %databaseserver%/%fbport%:"%databasedir%%%d.%dbextension%" >> !gfixlog!
        	@echo.
		@echo. >> !gfixlog!
		@echo. >> !gfixlog!
		@echo Die Überprüfung der "%databasedir%%%d.%dbextension%" Datenbank  >> !gfixlog!
		@echo wurde erfolgreich durchgeführt, falls keine Fehler aufgeführt wurden. >> !gfixlog!
		@echo. >> !gfixlog!
		@echo Informieren Sie ggf. Ihren Administrator! %contact% >> !gfixlog!
		@echo. >> !gfixlog!
		@echo. >> !gfixlog!
		@echo. >> !gfixlog!
		@echo !startzeit! >> !gfixlog!
		@echo Endzeit: !DATE! !TIME:~0,-3! >> !gfixlog!
		@echo Die šberprfung der "%databasedir%%%d.%dbextension%" Datenbank 
		@echo wurde durchgefhrt. Das Protokoll wurde gespeichert unter:
		@echo !gfixlog! 
		if not exist !gfixlog! (color CF && echo 		es traten Fehler auf: Protokollfehler >> %~dp0FIREBIRD_HISTORIE.txt
			title FIREBIRD - F E H L E R bei šberprfung von %%d.%dbextension%
			echo.
			echo Protokoll nicht verfgbar, bitte Pfadangabe "%databasedir%" prfen
			echo Abbruch empfohlen
			@echo  & pause>nul)
		if %showlog%==1 (
			echo und wird nun ge”ffnet
			if %showpause%==1 (
				if exist !gfixlog! notepad.exe !gfixlog!
				) else (
				if exist !gfixlog! start notepad.exe !gfixlog!
				)
			)
		@echo.
		@echo.
		Endlocal
	) else (
		@echo Die šberprfung der "%databasedir%%%d.%dbextension%" Datenbank 
		@echo wird durchgefhrt, bitte warten...
		@echo.
        @echo Datenbank "%databasedir%%%d.%dbextension%" wird heruntergefahren...
        gfix -shut -force 0 %databaseserver%/%fbport%:"%databasedir%%%d.%dbextension%"
		@color 20
		@echo Datenbank "%databasedir%%%d.%dbextension%" wird berprft...
		gfix %validationparameter% %databaseserver%/%fbport%:"%databasedir%%%d.%dbextension%"
		@color 2
        @echo Datenbank "%databasedir%%%d.%dbextension%" wird wieder hochgefahren...
        gfix -online %databaseserver%/%fbport%:"%databasedir%%%d.%dbextension%"
		@echo.
		@echo.
		@echo Die šberprfung der "%databasedir%%%d.%dbextension%" Datenbank 
		@echo wurde erfolgreich durchgefhrt, falls keine Fehler aufgefhrt wurden.
		@echo.
		@echo Informieren Sie ggf. Ihren Administrator! %contact%
		@echo.
		@echo.
		@echo.
		)
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
title FIREBIRD Datenbank-Validation in %databasedir% beendet!
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

:sysdbachange
@echo off & color 2 & cls & title SYSDBA Kennwortmanager
echo.
echo  ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
echo  º                                     º
echo  º   Firebird SYSDBA Kennwortmanager   º
echo  º                                     º
echo  ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
:passchange
@echo 
SET /P aktuell=Aktuelles SYSDBA Kennwort:        
gsec -user sysdba -password %aktuell% -display >nul 2>nul
if not %errorlevel%==0 echo Passworteingabe inkorrekt, wiederhole... & echo. & goto:passchange
SET /P neu=Neu zu setzendes SYSDBA Kennwort: 
cls & color 4
echo.
echo  ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
echo  º                                     º
echo  º   Firebird SYSDBA Kennwortmanager   º
echo  º                                     º
echo  ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
echo.
gsec -user sysdba -password %aktuell% -modify SYSDBA -pw %neu%
echo SYSDBA-Änderung	von %Username% am %DATUM% um %h%:%m% Uhr >> %~dp0FIREBIRD_HISTORIE.txt
ping 127.0.0.1 -n 2 >nul 2>nul
gsec -user sysdba -password %neu% -display >nul 2>nul
if not %errorlevel%==0 echo Passwortsetzung fehlgeschlagen, wiederhole... & echo. & goto:passchange
echo.
@echo 
pause
exit

:checkPrivileges
net session >nul 2>&1 && goto gotPrivileges
net file    >nul 2>&1 && goto gotPrivileges
set "SCRIPT=%~f0"
set "SCRIPT=%SCRIPT:'=''%"
powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%SCRIPT%' -Verb RunAs" >nul 2>&1
if errorlevel 1 (start "" cmd /c "color C & echo. & echo UAC-Abfrage wurde abgebrochen oder ist fehlgeschlagen. & echo. & pause" & exit /b 1)
exit /b 0