@echo off
rem Startet VS Code mit den API-Keys für Claude und Codex als prozesslokale
rem Umgebungsvariablen. Die Keys liegen DPAPI-verschlüsselt im Benutzerprofil
rem und sind nur vom eigenen Windows-Konto auf diesem Rechner lesbar.
rem Details und Hinweise zum Datenschutz stehen im Kopf der PS1-Datei.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0load_vscode_with_api.ps1"

rem 20260901 https://github.com/Bolle1987/Scripts