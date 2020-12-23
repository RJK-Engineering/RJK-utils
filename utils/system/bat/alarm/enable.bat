@schtasks /change /enable /tn alarm
@if %errorlevel% gtr 0 pause
@schtasks /query /v /fo list /tn alarm |find "Start Time"
@if %errorlevel% gtr 0 pause
