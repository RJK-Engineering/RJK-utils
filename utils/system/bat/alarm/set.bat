@echo off
if "%~1" == "" goto SHOW
schtasks /change /st %1 /tn alarm
if %errorlevel% gtr 0 pause
schtasks /change /enable /tn alarm
if %errorlevel% gtr 0 pause
:SHOW
schtasks /query /tn alarm
:END
pause