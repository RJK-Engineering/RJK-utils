@echo off
setlocal

call getclip
call :tcc %clip%
exit/b

:tcc
if not exist %~f1 rjk-util totalcmd\chdir\chdir.pl -c
%COMMANDER_EXE% /O /S /L=%~f1
