@ECHO OFF
REM SETLOCAL restores %CD% when bat script ends (or on ENDLOCAL)
SETLOCAL

cd\
call rjk-util system\drivestatus\drivestatus.pl /n --window-title "%~n0" %*
