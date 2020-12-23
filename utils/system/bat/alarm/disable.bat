@schtasks /change /disable /tn alarm
@if %errorlevel% gtr 0 pause
