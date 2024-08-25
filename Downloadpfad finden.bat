@echo off & color 2 & cls & title Bolle's Downloadpfad auslesen (%0)

setlocal EnableExtensions DisableDelayedExpansion

set "Reg32=%SystemRoot%\System32\reg.exe"
if not "%ProgramFiles(x86)%" == "" set "Reg32=%SystemRoot%\SysWOW64\reg.exe"

set "DownloadShellFolder="
for /F "skip=1 tokens=1,2*" %%T in ('%Reg32% query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "{374DE290-123F-4565-9164-39C4925E467B}" 2^>nul') do (
    if /I "%%T" == "{374DE290-123F-4565-9164-39C4925E467B}" (
        set "DownloadShellFolder=%%V"
        goto GetDownloadDirectory
    )
)

:GetDownloadDirectory
set "DownloadDirectory="
for /F "skip=1 tokens=1,2,3*" %%S in ('%Reg32% query "HKCU\Software\Microsoft\Internet Explorer" /v "Download Directory" 2^>nul') do (
    if /I "%%S" == "Download" (
        if /I "%%T" == "Directory" (
            set "DownloadDirectory=%%V"
            goto GetSaveDirectory
        )
    )
)

:GetSaveDirectory
set "SaveDirectory="
for /F "skip=1 tokens=1,2,3*" %%S in ('%Reg32% query "HKCU\Software\Microsoft\Internet Explorer\Main" /v "Save Directory" 2^>nul') do (
    if /I "%%S" == "Save" (
        if /I "%%T" == "Directory" (
            set "SaveDirectory=%%V"
            goto OutputResults
        )
    )
)

:OutputResults
cls
echo/

if not exist "%USERPROFILE%\Downloads" goto OutputShellFolder
echo Download Ordner des Benutzeraccounts ist:
echo/
echo   %USERPROFILE%\Downloads
echo/
echo/

:OutputShellFolder
if not defined DownloadShellFolder goto OutputDownloadDir
if "%DownloadShellFolder:~-1%" == "\" set "DownloadShellFolder=%DownloadShellFolder:~0,-1%"
echo Download Shell-Ordner des Benutzeraccounts ist:
echo/
echo   %DownloadShellFolder%
echo/
echo/

:OutputDownloadDir
if not defined DownloadDirectory goto OutputSaveDir
if "%DownloadDirectory:~-1%" == "\" set "DownloadDirectory=%DownloadDirectory:~0,-1%"
echo Download Ordner des Internet Explorers ist:
echo/
echo   %DownloadDirectory%
echo/
echo/

:OutputSaveDir
if not defined SaveDirectory goto EndBatch
if "%SaveDirectory:~-1%" == "\" set "SaveDirectory=%SaveDirectory:~0,-1%"
echo Speicherpfad des Internet Explorers ist:
echo/
echo   %SaveDirectory%

:EndBatch
endlocal
pause