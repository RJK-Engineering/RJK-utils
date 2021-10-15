@ECHO OFF
SETLOCAL

SET usage=
CALL run_start %0 "%~1"
IF defined help GOTO HELP

CALL run_getopt %*
IF not defined cmd SET usage=1& GOTO HELP

CALL run_execute
GOTO END

:HELP
CALL run_help

:END
CALL run_end
