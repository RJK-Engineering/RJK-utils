@ECHO OFF
SETLOCAL

CALL run_start %0 "%~1"
IF defined help GOTO HELP
SET help=usage

CALL run_getopt %*
SET cmd=%arg1%
SET filelist=%arg2%
IF not defined filelist GOTO HELP
SET extension=%ext1%
SET args=%args2%

SET background=
SET display=
IF defined option/d SET display=%%~fF
IF defined option/n SET display=%%~nxF

FOR /F "tokens=*" %%F IN (%filelist%) DO (
    IF defined display ECHO %display%
    SET append=%append%
    SET output=%output%
    CALL run_execute %args%
    IF defined error GOTO END
    IF defined exitcode PAUSE
)
GOTO END

:HELP
CALL batch_help

:END
CALL run_end
