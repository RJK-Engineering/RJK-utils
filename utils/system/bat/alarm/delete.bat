@schtasks /delete /tn alarm
@if %errorlevel% gtr 0 pause
