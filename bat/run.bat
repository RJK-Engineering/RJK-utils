@ECHO OFF
SETLOCAL

CALL run_start %0 "%~1"
IF DEFINED end GOTO END

CALL run_getopt %*
IF DEFINED end GOTO END

CALL run_execute

:END
CALL run_end
