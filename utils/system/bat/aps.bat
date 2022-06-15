@echo off
if "%~1" == "" goto USAGE

rem ~ powercfg /SETACVALUEINDEX 381b4222-f694-41f0-9685-ff5bb260df2e 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 55
powercfg /setacvalueindex SCHEME_BALANCED SUB_PROCESSOR PROCTHROTTLEMAX %1
powercfg /setactive SCHEME_BALANCED
for /f %%F in ("settcbdescr.bat") do if exist %%~$PATH:F call %%F System.bar "Current setting:" "%1%%%%"
exit/b

:USAGE
echo USAGE: %0 ^<value^>
echo.
powercfg /query SCHEME_BALANCED SUB_PROCESSOR PROCTHROTTLEMAX
pause
