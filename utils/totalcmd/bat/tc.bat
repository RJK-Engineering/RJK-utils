@echo off
set left=%1
if "%1"=="" set left=%cd%
%COMMANDER_EXE% /O /S /L=%left% /R=%2
