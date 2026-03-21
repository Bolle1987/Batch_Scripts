@echo off & color 2 & cls & title Bolle's Umlaute in Batches (%~dp0%~n0%~x0)
mode con lines=33 >nul 2>&1

rem Fuer klassische CMD meist stabiler mit 1252 statt 850 (Standard)
chcp 1252 >nul
if errorlevel 1 goto:850

echo(
echo ========================
echo    Umlaute in Batches
echo ========================
echo(
echo         ae = ไ
echo         ae = ไ
echo         oe = ๖
echo         ue = ü
echo(
echo         AE = ฤ
echo         OE = ึ
echo         UE = Ü
echo(
echo         sz = ฿
echo(
rem pause >nul

:850
chcp 850 >nul
echo.
@echo ษออออออออออออออออออออออออป
@echo บ                        บ
@echo บ   Umlaute in Batches   บ
@echo บ                        บ
@echo ศออออออออออออออออออออออออผ
echo.
echo         ae = 
echo         oe = ”
echo         ue = 
echo.
echo         AE = 
echo         OE = 
echo         UE = 
echo.
echo         sz = แ
pause>nul

rem 11:38 24.09.2007 Bolle
