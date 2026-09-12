@echo off
rem Startet Obsidian mit prozesslokalen API-Keys fuer Claudian.
rem Die DPAPI-verschluesselten Dateien bleiben im Benutzerprofil
rem und sind nur vom eigenen Windows-Konto auf diesem Rechner lesbar.
rem Details und Hinweise zum Datenschutz stehen im Kopf der PS1-Datei.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0load_obsidian_with_api.ps1"
if errorlevel 1 pause

rem 20260912 https://github.com/Bolle1987/Scripts