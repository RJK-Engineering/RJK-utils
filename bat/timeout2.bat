@echo off
REM sets TIMEOUT_ABORT=aborted when key pressed before timeout ends

IF "%~1"=="" GOTO HELP
SET TIMEOUT_ABORT=
SETLOCAL
SET timeout=%1
IF %timeout% gtr 1 IF %timeout% lss 60 GOTO START

:HELP
ECHO USAGE: %0 [timeout in seconds]
ECHO timeout must be greater than 1 and less than 60
GOTO END

:START
SET start=%TIME:~6,2%%TIME:~9,2%
IF "%start:~0,1%"=="0" SET start=%start:~1%

TIMEOUT %timeout%

SET stop=%TIME:~6,2%%TIME:~9,2%
IF "%stop:~0,1%"=="0" SET stop=%stop:~1%

SET /a diff=stop-start
IF %diff% lss 0 SET /a diff+=6000

SET slack=100
SET /a diff+=slack
IF %diff% lss %timeout%00 ENDLOCAL & SET TIMEOUT_ABORT=aborted

:END
