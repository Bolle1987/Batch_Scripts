@echo off & color 0A & cls & title Bolle's Farben in Batches (%0)

set u=[0m
set bold=[1m
set under=[4m
set inverse=[7m
set blink=[5m
set cyanl=[96m
set cyand=[36m
set magental=[95m
set magentad=[35m
set white=[97m

set lime=[38;5;154m
set brown=[38;5;94m
set greenl=[38;5;46m
set green=[38;5;40m
set greenm=[38;5;42m
set greend=[38;5;35m
set yellowl=[38;5;226m
set yellow=[38;5;220m
set bluel=[38;5;45m
set blue=[38;5;39m
set blued=[38;5;33m
set blueb=[38;5;75m
set purplel=[38;5;105m
set purple=[38;5;99m
set fuchsia1=[38;5;1m
set fuchsia2=[38;5;162m
set peach=[38;5;174m
set debug=[38;5;91m
set pinkl=[38;5;13m
set pink=[38;5;206m
set pinkd=[38;5;200m
set yellowl=[38;5;228m
set yellowm=[38;5;226m
set yellowd=[38;5;190m
set orangel=[38;5;215m
set orange=[38;5;208m
set oranged=[38;5;202m
set goldl=[38;5;220m
set goldm=[38;5;178m
set goldd=[38;5;214m
set grayb=[38;5;250m
set greyl=[38;5;247m
set graym=[38;5;244m
set grayd=[38;5;238m
set grayz=[38;5;237m
set redl=[91m
set red=[38;5;160m
set redd=[38;5;124m
set redz=[38;5;88m

@echo ษอออออออออออออออออออออออป
@echo บ                       บ
@echo บ   %red%Farben in Batches%green%   บ
@echo บ                       บ
@echo ศอออออออออออออออออออออออผ
echo.
echo %goldm%0%green% = Schwarz        %goldm%8%green% = Dunkelgrau
echo %goldm%1%green% = Dunkelblau     %goldm%9%green% = Blau
echo %goldm%2%green% = Dunkelgrn     %goldm%A%green% = Grn
echo %goldm%3%green% = Blaugrn       %goldm%B%green% = Zyan
echo %goldm%4%green% = Dunkelrot      %goldm%C%green% = Rot
echo %goldm%5%green% = Lila           %goldm%D%green% = Magenta
echo %goldm%6%green% = Ocker          %goldm%E%green% = Gelb
echo %goldm%7%green% = Hellgrau       %goldm%F%green% = Weiแ
echo.
echo Beispiel : %goldm%color 0A%green%
echo %goldm%0%green% = Hintergrund (Schwarz)
echo %goldm%A%green% = Schrift (Grn)
echo.
cd %windir%\system32
C:
cmd
exit

rem 14:27 22.02.2012 Bolle