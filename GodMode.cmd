@echo off & color 2 & cls & title Bolle's Windows GOD Mode (%0)

md "%temp%\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" >nul 2>nul
explorer %temp%\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C} >nul 2>nul
echo Taste druecken um Godmode zu beenden
pause >nul 2>nul
rd /q "%temp%\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" >nul 2>nul