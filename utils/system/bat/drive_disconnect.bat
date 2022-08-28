@echo off
setlocal

if "%~1" == "" goto USAGE
for %%A IN (%*) do call :disconnect %%A
exit/b

:disconnect
set driveletter=%1
call %~dp0netdrive_disconnect %driveletter%
subst /d %driveletter%:
exit/b

:USAGE
ECHO USAGE: %0 [driveletters]
pause
