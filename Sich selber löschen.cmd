@echo off & color 2 & cls & title Bolle's Sich selber l�schen (%0)

echo.
echo Der Befehl zum auslesen der eigenen Datei lautet: %%0
echo Zum l�schen der eigenen Batch also folgender Befehl: 
echo.
@echo ������������������������ͻ
@echo �                        �
@echo �       del /q %%0        �
@echo �                        �
@echo ������������������������ͼ
echo.
echo Sie rufen grade diese Datei auf:
echo %0
pause>nul

rem 14:53 17.12.2007 Bolle