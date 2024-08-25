@echo off & color 2 & cls & title Bolle's HTML erzeugen und ausgeben (%0)

set htmldatei=%temp%\test_html_logfile.html
if exist %htmldatei% del %htmldatei%

echo ^<HTML^>^<HEAD^>				>>%htmldatei%
echo ^<TITLE^>Bolle^</TITLE^>		>>%htmldatei%
echo ^</HEAD^>^<BODY^>				>>%htmldatei%
echo ^<H1^>test^</H1^>			>>%htmldatei%
date /t						>>%htmldatei%
time /t						>>%htmldatei%
echo ^<HR /^>					>>%htmldatei%
echo Test^<HR /^> 				>>%htmldatei%
echo ^</BODY^>^</HTML^> 			>>%htmldatei%

cls
echo.
echo Bitte warten, die Seite wird aufgerufen...
start %htmldatei%
ping 127.0.0.1 -n 3 >nul


rem 10:11 14.06.2007 Bolle