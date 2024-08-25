@echo off & color 2 & cls & title Bolle's VerwaltungsmenÅ (%0)

:MAINMENU
cls
title Kommando-MenÅ
echo.
echo [1] - SteuerungsmenÅ
echo [2] - KonfigurationsmenÅ
echo.
echo.
echo [9] - Task-Manager
echo [0] - Beenden
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
SET /P Auswahl1=Bitte wÑhlen  :  
if (%Auswahl1%)==(00) Goto :ENDE
if (%Auswahl1%)==(01) Goto :STRGMENU
if (%Auswahl1%)==(02) Goto :KONFMENU
if (%Auswahl1%)==(09) taskmgr.exe
if (%Auswahl1%)==(0) Goto :ENDE
if (%Auswahl1%)==(1) Goto :STRGMENU
if (%Auswahl1%)==(2) Goto :KONFMENU
if (%Auswahl1%)==(9) taskmgr.exe
Goto :MAINMENU


:STRGMENU
cls
title SteuerungsmenÅ
echo.
echo [01] - Eingabeaufforderung
echo [02] - Sicherheitseinstellungen
echo [03] - Diensteverwaltung
echo [04] - Computerverwaltung
echo [05] - DatentrÑgerverwaltung
echo [06] - Wechselmedienverwaltung
echo [07] - GerÑte-Manager
echo [08] - Gruppenrichtlinien-Editor
echo [09] - Lokale Benutzer und Gruppen
echo [10] - Registrierungs-Editor
echo [11] - Leistungsmonitor
echo [12] - Freigegebene Ordner
echo [13] - Zertifikat-Manager
echo [14] - Indexdienst
echo [15] - Ereignisanzeige
echo [16] - DatentrÑgerbereinigung
echo [17] - Defragmentierung
echo [18] - DirectX-Diagnoseprogramm
echo [19] - SystemdateiÅberprÅfung
echo.
echo [00] - ZurÅck zu Kommando-MenÅ
echo.
echo.
SET /P Auswahl2=Bitte wÑhlen  :  
if (%Auswahl2%)==(00) Goto :MAINMENU
if (%Auswahl2%)==(01) cmd.exe
if (%Auswahl2%)==(02) secpol.msc
if (%Auswahl2%)==(03) services.msc
if (%Auswahl2%)==(04) compmgmt.msc
if (%Auswahl2%)==(05) diskmgmt.msc
if (%Auswahl2%)==(06) ntmsmgr.msc
if (%Auswahl2%)==(07) devmgmt.msc
if (%Auswahl2%)==(08) gpedit.msc
if (%Auswahl2%)==(09) lusrmgr.msc
if (%Auswahl2%)==(10) regedit.exe 
if (%Auswahl2%)==(11) perfmon.msc
if (%Auswahl2%)==(12) fsmgmt.msc
if (%Auswahl2%)==(13) certmgr.msc
if (%Auswahl2%)==(14) ciadv.msc
if (%Auswahl2%)==(15) eventvwr.msc
if (%Auswahl2%)==(16) cleanmgr.exe
if (%Auswahl2%)==(17) dfrg.msc
if (%Auswahl2%)==(18) dxdiag.exe
if (%Auswahl2%)==(19) sfc /scannow
if (%Auswahl2%)==(0) Goto :MAINMENU
if (%Auswahl2%)==(1) cmd.exe
if (%Auswahl2%)==(2) secpol.msc
if (%Auswahl2%)==(3) services.msc
if (%Auswahl2%)==(4) compmgmt.msc
if (%Auswahl2%)==(5) diskmgmt.msc
if (%Auswahl2%)==(6) ntmsmgr.msc
if (%Auswahl2%)==(7) devmgmt.msc
if (%Auswahl2%)==(8) gpedit.msc
if (%Auswahl2%)==(9) lusrmgr.msc
Goto :STRGMENU


:KONFMENU
cls
title KonfigurationsmenÅ
echo.
echo [01] - IP-Adresse anzeigen
echo [02] - Netzerkkonfiguration anzeigen
echo [03] - Netzerkkonfiguration abÑndern
echo [04] - Datum und Uhrzeit anzeigen
echo [05] - Datum und Uhrzeit eingeben
echo [06] - Rechner
echo [07] - Editor
echo [08] - Paint
echo [09] - Remotedesktop
echo [10] - Windows Aktivierung ÅberprÅfen
echo.
echo        Windows 2003
echo [11] - DomÑnen-Einrichtung
echo [12] - Active Directory
echo.
echo [00] - ZurÅck zu Kommando-MenÅ
echo.
echo.
echo.
echo.
echo.
echo.
echo.
SET /P Auswahl3=Bitte wÑhlen  :  
if (%Auswahl3%)==(00) Goto :MAINMENU
if (%Auswahl3%)==(01) Goto :ip
if (%Auswahl3%)==(02) Goto :ipall
if (%Auswahl3%)==(03) Goto :ipchange
if (%Auswahl3%)==(04) Goto :dt
if (%Auswahl3%)==(05) Goto :dti
if (%Auswahl3%)==(06) calc.exe
if (%Auswahl3%)==(07) notepad.exe
if (%Auswahl3%)==(08) mspaint.exe
if (%Auswahl3%)==(09) mstsc.exe
if (%Auswahl3%)==(10) %windir%\system32\oobe\msoobe.exe /a
if (%Auswahl3%)==(11) dcpromo.exe
if (%Auswahl3%)==(12) dsa.msc
if (%Auswahl3%)==(0) Goto :MAINMENU
if (%Auswahl3%)==(1) Goto :ip
if (%Auswahl3%)==(2) Goto :ipall
if (%Auswahl3%)==(3) Goto :ipchange
if (%Auswahl3%)==(4) Goto :dt
if (%Auswahl3%)==(5) Goto :dti
if (%Auswahl3%)==(6) calc.exe
if (%Auswahl3%)==(7) notepad.exe
if (%Auswahl3%)==(8) mspaint.exe
if (%Auswahl3%)==(9) mstsc.exe
Goto :KONFMENU


:ipchange
cls
title KonfigurationsmenÅ - Netzwerkkonfigurationen
echo.
echo [01] - Statische IP setzen
echo [02] - Dynamische IP setzen
echo.
echo [00] - ZurÅck zu KonfigurationsmenÅ
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
SET /P Auswahl4=Bitte wÑhlen  :  
if (%Auswahl4%)==(00) Goto :KONFMENU
if (%Auswahl4%)==(01) Goto :ipstat
if (%Auswahl4%)==(02) Goto :ipdyn
if (%Auswahl4%)==(0) Goto :KONFMENU
if (%Auswahl4%)==(1) Goto :ipstat
if (%Auswahl4%)==(2) Goto :ipdyn
Goto :KONFMENU


:ip
cls
echo.
ipconfig
echo.
echo.
echo.
pause
Goto :KONFMENU


:ipall
cls
echo.
ipconfig -all
echo.
echo.
echo.
pause
Goto :KONFMENU


:ipstat
cls
title Kommando-MenÅ - IP-Adresse Ñndern
echo.
echo.
echo IP-Adresse Ñndern
echo.
echo.
echo  *
echo  * Beispiel:
echo  *
echo  * DESC = LAN-Verbindung
echo  * IP   = 192.168.0.10
echo  * SM   = 255.255.255.0
echo  * GW   = 192.168.0.100
echo  * DNS0 = 192.168.0.1
echo  * DNS1 = 192.168.0.2
echo  *
echo.
echo.
SET /P DESC=Bitte LAN-Verbindung angeben      :  
SET /P IP=Bitte IP-Adresse eintragen        :  
SET /P NM=Bitte Subnetzmaske eintragen      :  
SET /P GW=Bitte Gateway eintragen           :  
SET /P DNS0=Bitte DNS eintragen               :  
SET /P DNS1=Bitte alterneativer DNS eintragen :  
rem IP und Subnetz
echo setze statische IP %IP% ...
netsh interface ip set address name=%DESC% source=static addr=%IP% mask=%NM%
rem Gateway
echo setze Gateway %GW% ...
netsh interface ip set address name=%DESC% gateway=%GW% gwmetric=0
rem Prim‰r DNS
echo setze primÑren DNS-Server %DNS0% ...
netsh interface ip set dns name=%DESC% source=static addr=%DNS0% register=PRIMARY
rem Sekund‰r DNS
echo setze sekundÑren DNS-Server %DNS1% ...
netsh interface ip add dns name=%DESC% addr=%DNS1% index=2
echo Netzwerkkonfiguration beendet!
pause
cls
echo Aktuelle Netzwerkeinstellungen:
ipconfig /all
pause
Goto:KONFMENU


:ipdyn
cls
title Kommando-MenÅ - IP-Adresse via DHCP
echo.
echo.
echo aktiviere DHCP ...
echo.
echo.
netsh interface ip set address "LAN-Verbindung" dhcp
pause
cls
echo Aktuelle Netzwerkeinstellungen:
ipconfig /all
pause
Goto:KONFMENU


:dt
cls
echo.
echo Datum : 
date /t
echo.
echo Uhrzeit :
time /t
echo.
echo.
echo.
pause
Goto :KONFMENU


:dti
cls
echo.
date
echo.
time
echo.
echo.
echo.
pause
Goto :KONFMENU

:ENDE
echo by Bolle 10:17 16.11.2009
exit
