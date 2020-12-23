@echo off
schtasks /change /enable /tn alarm
if %errorlevel% gtr 0 pause
schtasks /query /v /fo list /tn alarm |find "Start Time"
pause
