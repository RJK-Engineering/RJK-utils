@schtasks /create /xml alarm.xml /tn alarm
@if %errorlevel% gtr 0 pause
