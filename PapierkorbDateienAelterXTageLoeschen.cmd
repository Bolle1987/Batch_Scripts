@echo off & color 2 & cls & title Bolle's Papierkorbdateien entfernen (%0)

SET tage=30

echo "Leere Papierkorb"
for /f "delims= " %%a in ('"wmic path win32_useraccount where name='%UserName%' get sid"') do (
   if not "%%a"=="SID" (          
      set sid=%%a
      goto :loop_end
   )   
)

:loop_end
cd /D "%SYSTEMDRIVE%\$Recycle.Bin\%sid%\"
forfiles /P %SYSTEMDRIVE%\$Recycle.Bin\%sid%\ /S /M * /D -%tage% /C "cmd /c if @isdir==FALSE del /F /S /Q @path"
forfiles /P %SYSTEMDRIVE%\$Recycle.Bin\%sid%\ /S /M * /D -%tage% /C "cmd /c if @isdir==TRUE rd /S /Q @path"
