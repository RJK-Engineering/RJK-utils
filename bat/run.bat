@ECHO OFF
SETLOCAL

CALL run_start %0 "%~1"
IF defined help GOTO HELP
SET help=usage

CALL run_getopt %*
IF not defined cmd GOTO HELP

CALL run_execute
GOTO END

:HELP
CALL run_help

:END
CALL run_end
