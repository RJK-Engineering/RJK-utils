@echo off
setlocal

call getclip

if /i "%clip:~0,4%"=="http" goto download
set "var=%clip:http:=%"
if /i not "%var%"=="%clip%" goto download
set "var=%clip:https:=%"
if /i not "%var%"=="%clip%" goto download

call :totalcmd "%clip%"
if not defined clip exit/b
if "%clip:~1,1%"==":" call :check-path
if not defined clip exit/b
goto chdir.pl

:check-path
call env-hash-value CHDIR_DRIVE_MAP %clip:~0,1%
if not defined -hash-value exit/b
call :totalcmd "%-hash-value%%clip:~1%"
exit/b

:totalcmd
if not exist "%~f1" exit/b
%COMMANDER_EXE% /O /S /L="%~f1"
set clip=
exit/b

:download
dl %clip%
exit/b

:chdir.pl
rjk-util totalcmd\chdir\chdir.pl -c
exit/b
