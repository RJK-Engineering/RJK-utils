@echo off
set left=%1
if "%1"=="" set left=%cd%
totalcmd /O /S /L=%left% /R=%2
