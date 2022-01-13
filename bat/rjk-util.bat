@ECHO OFF
SETLOCAL

IF NOT DEFINED RJK_UTILS_HOME (
    FOR /F "delims=" %%P IN ("%~dp0..") DO SET RJK_UTILS_HOME=%%~fP
)

CALL run_start %0 "%~1"
IF defined help GOTO HELP

CALL run_getopt %*
SET util=%arg1%
IF not defined util GOTO HELP
SET extension=%ext1%
SET args=%args1%

SET cmd=%RJK_UTILS_HOME%\utils\%util%
CALL run_execute
GOTO END

:HELP
ECHO USAGE: %script% [UTIL] [OPTIONS] [UTIL ARGS]
ECHO.
IF "%help%"=="usage" (
    ECHO DISPLAY EXTENDED HELP: %script% /?
    GOTO END
)
ECHO OPTIONS:
ECHO./?        Help
ECHO /p        Force pause before exit
ECHO /-p       Force no pause before exit
ECHO /t [n]    Timeout before exit
ECHO /q        Be quiet (redirect standard output to NUL)
ECHO /-e       No errors (redirect error output to NUL)
ECHO /r        Redirect error output to standard ouput
ECHO /c        Copy standard ouput to clipboard
ECHO /o [path] Write standard ouput to file

:END
CALL run_end
