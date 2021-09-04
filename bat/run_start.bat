
REM clear vars, they are inherited from master environment
SET end=

SET script=%1
IF "%~2"=="/?" SET help=1& GOTO USAGE
IF "%~2"=="" GOTO USAGE
GOTO END

:USAGE
CALL run_usage

:END
