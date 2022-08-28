@echo off
setlocal

if "%~1" == "" goto USAGE
for %%A IN (%*) do call :disconnect %%A
exit/b

:disconnect
set driveletter=%1
echo net use /delete %driveletter%:
net use /delete %driveletter%:
exit/b

:USAGE
ECHO USAGE: %0 [driveletters]
pause
