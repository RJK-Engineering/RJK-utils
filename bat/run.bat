@ECHO OFF
SETLOCAL

CALL run_start %0 "%~1"
IF defined help GOTO HELP
SET help=usage

CALL run_getopt %*
SET cmd=%arg1%
IF not defined cmd GOTO HELP
SET extension=%ext1%
SET args=%args1%

CALL run_execute
GOTO END

:HELP
CALL run_help

:END
CALL run_end
