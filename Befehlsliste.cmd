@echo off & color 2 & cls & title Bolle's Befehlsliste erstellen (%0)

IF "%OS%"=="Windows_NT" SETLOCAL DISABLEDELAYEDEXPANSION

:: Versionsnummer der Batch
SET Versionsnummer=1.0

:: Zeige "Info"
ECHO.
ECHO Befehlsliste,  Version %Versionsnummer% fr Windows
ECHO generiet eine HTML Datei mit allen Batch-Befehlen des jeweiligen Betriebssystems
ECHO.

IF NOT "%OS%"=="Windows_NT" SET Versionsnummer=
IF NOT "%OS%"=="Windows_NT" GOTO End

:: Aktuelle Sprache feststellen und setzen
FOR /F "tokens=*" %%A IN ('CHCP') DO FOR %%B IN (%%A) DO SET CHCP=%%B
CHCP 1252 >NUL 2>&1

:: HTML
ECHO Schreibe HTML Kopf . . .
> Befehlsliste.htm ECHO ^<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"^>
>>Befehlsliste.htm ECHO ^<HTML^>
>>Befehlsliste.htm ECHO ^<HEAD^>

:: Windows Version auslesen
FOR /F "tokens=1 delims=[" %%A IN ('VER') DO SET Ver=%%A
FOR /F "tokens=1* delims= " %%A IN ('ECHO.%Ver%') DO SET Ver=%%B

:: Service Pack auslesen (Registry)
CALL :HoleSP
>>Befehlsliste.htm ECHO ^<TITLE^>Help for all %Ver%%SP% commands^</TITLE^>
>>Befehlsliste.htm ECHO ^<META NAME="generator" CONTENT="Befehlsliste.cmd, Version %Versionsnummer%, von Bolle"^>
>>Befehlsliste.htm ECHO ^</HEAD^>
>>Befehlsliste.htm ECHO.
>>Befehlsliste.htm ECHO ^<BODY^>
>>Befehlsliste.htm ECHO.
>>Befehlsliste.htm ECHO ^<A NAME="Top"^>^</A^>
>>Befehlsliste.htm ECHO.
>>Befehlsliste.htm ECHO ^<CENTER^>
>>Befehlsliste.htm ECHO ^<H1^>%Ver%%SP% Befehle^</H1^>
FOR /F "tokens=* delims=" %%A IN ('VER') DO SET Ver=%%A
>>Befehlsliste.htm ECHO ^<H3^>%Ver%^</H3^>
>>Befehlsliste.htm ECHO ^</CENTER^>
>>Befehlsliste.htm ECHO.
>>Befehlsliste.htm ECHO ^<P^>^&nbsp;^</P^>
>>Befehlsliste.htm ECHO.

ECHO Erstelle Kommando Index Tabelle . . .
SET FirstCell=1
>>Befehlsliste.htm ECHO ^<TABLE BORDER="0"^>
:: Überspringe 1 oder 2 Zeilen des HELP Kommando Kopf
FOR /F "tokens=1 delims=[]" %%A IN ('HELP ^| FIND /N "."') DO IF %%A LEQ 2 SET Skip=+%%A
FOR /F "tokens=* delims=" %%A IN ('HELP ^| MORE /E %Skip% /T8') DO CALL :DispLine "%%A"
>>Befehlsliste.htm ECHO ^</TD^>^</TR^>
>>Befehlsliste.htm ECHO ^</TABLE^>
>>Befehlsliste.htm ECHO.
>>Befehlsliste.htm ECHO ^<P^>^&nbsp;^</P^>
>>Befehlsliste.htm ECHO.

ECHO Schreibe Hilfe fr jeden Befehl:
FOR /F "tokens=* delims=" %%A IN ('HELP ^| MORE /E %Skip% /T8') DO CALL :DispFull "%%A"

ECHO Schliesse HTML Datei
>>Befehlsliste.htm ECHO.
>>Befehlsliste.htm ECHO ^<DIV ALIGN="Center"^>
>>Befehlsliste.htm ECHO ^<P^>Diese HTML Datei wurde erstellt von:^<BR^>
>>Befehlsliste.htm ECHO ^<B^>Befehlsliste.cmd^</B^>, Version %Versionsnummer%
>>Befehlsliste.htm ECHO von Bolle^<BR^>
>>Befehlsliste.htm ECHO ^<A HREF="https://github.com/Bolle1987"^>github^</A^>^</P^>
>>Befehlsliste.htm ECHO ^</DIV^>
>>Befehlsliste.htm ECHO.
>>Befehlsliste.htm ECHO ^</BODY^>
>>Befehlsliste.htm ECHO ^</HTML^>

ECHO.
ECHO Eine HTML Hilfe-Datei "Befehlsliste.htm" wurde im gleichen Ordner gespeichert
ECHO.
ECHO ™ffne "Befehlsliste.htm" . . .
START "Befehlsliste" Befehlsliste.htm

:: Ende
CHCP %CHCP% >NUL 2>&1
ENDLOCAL
GOTO:EOF


:: Subroutinen


:DispLine
SET Line=%1
SET Line=%Line:(=^(%
SET Line=%Line:)=^)%
SET Line=%Line:"=%
SET Command=%Line:~0,8%
SET Command=%Command: =%
IF DEFINED Command CALL :ZeigeCMDZeile %Command%
FOR /F "tokens=1* delims= " %%a IN ('ECHO.%*') DO SET Descr=%%b
SET Descr=%Descr:"=%
>>Befehlsliste.htm ECHO.%Descr%
GOTO:EOF


:ZeigeCMDZeile
IF "%FirstCell%"=="0" IF DEFINED Command (>>Befehlsliste.htm ECHO ^</TD^>^</TR^>)
SET Command=%1
IF DEFINED Command (>>Befehlsliste.htm ECHO ^<TR^>^<TH ALIGN="left" VALIGN="top"^>^<A HREF="#%Command%"^>%Command%^</A^>^</TH^>^<TD^>^&nbsp;^&nbsp;^&nbsp;^</TD^>^<TD^>)
SET FirstCell=0
SET Command=
GOTO:EOF


:DispFull
SET Line=%1
SET Command=%Line:~1,8%
SET Command=%Command: =%
IF DEFINED Command CALL :Schreibevoll %Command%
SET Command=
GOTO:EOF


:HoleSP
SET SP=
:: Exportiere Registry Zweig in temporäre Datei
START /WAIT REGEDIT.EXE /E "%Temp%.\%~n0.dat" "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
IF NOT EXIST "%Temp%.\%~n0.dat" GOTO:EOF
:: Lese Inhalt "CSDVersion" von der temporären Datei
FOR /F "tokens=2 delims==" %%A IN ('TYPE "%Temp%.\%~n0.dat" ^| FIND /I "CSDVersion"') DO SET SP=%%~A
:: Überprüfe ob Inhalt OK ist
ECHO.%SP% | FIND /I "Service Pack" >NUL
IF ERRORLEVEL 1 SET SP=
DEL "%Temp%.\%~n0.dat"
:: Benutze kleinere Beschreibung
IF DEFINED SP SET SP=%SP:Service Pack=SP%
GOTO:EOF


:Schreibevoll
ECHO.  %1 . . .
>>Befehlsliste.htm ECHO.
>>Befehlsliste.htm ECHO ^<A NAME="%~1"^>^</A^>
>>Befehlsliste.htm ECHO.
>>Befehlsliste.htm ECHO ^<H2^>%1^</H2^>
>>Befehlsliste.htm ECHO.
>>Befehlsliste.htm ECHO ^<PRE^>
>>Befehlsliste.htm HELP %1
>>Befehlsliste.htm ECHO ^</PRE^>
>>Befehlsliste.htm ECHO.
>>Befehlsliste.htm ECHO ^<A HREF="#Top"^>Nach oben . . .^</A^>
>>Befehlsliste.htm ECHO.
>>Befehlsliste.htm ECHO ^<P^>^&nbsp;^</P^>
>>Befehlsliste.htm ECHO.
GOTO:EOF

:End
