@ECHO OFF
SETLOCAL

CALL run_start %0 "%~1"
IF DEFINED help GOTO HELP

CALL run_getopt %*
IF NOT DEFINED cmd SET usage=1& GOTO HELP

CALL run_execute
GOTO END

:HELP
CALL run_usage

:END
CALL run_end
