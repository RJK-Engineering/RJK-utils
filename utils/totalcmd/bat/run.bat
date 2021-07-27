@ECHO OFF
SETLOCAL

REM Catch /? arg because CALL /? displays CALL's help
SET arg1=%1
IF "%~1"=="/?" SET arg1=& SET help=1

CALL run_start %0 %arg1%
IF DEFINED end GOTO END

CALL run_getopt %*
IF DEFINED end GOTO END

%cmd% %args% %errorredirect% %quiet% %output%

:END
CALL run_end
