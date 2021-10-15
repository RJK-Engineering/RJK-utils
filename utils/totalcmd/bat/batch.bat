@ECHO OFF
SETLOCAL

CALL run_start %0 "%~1"
IF defined help GOTO HELP
SET help=usage

SET run_getopt_get_filelist=1
CALL run_getopt %*
IF not defined filelist GOTO HELP

SET background=
SET display=
IF defined option/d SET display=%%~fF
IF defined option/n SET display=%%~nxF
IF defined output SET append=%output%

FOR /F "tokens=*" %%F IN (%filelist%) DO (
    IF defined display ECHO %display%
    CALL run_execute %args%
)
GOTO END

:HELP
CALL batch_help

:END
CALL run_end
