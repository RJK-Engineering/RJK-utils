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
ECHO USAGE: %script% [OPTIONS] [UTIL] [ARGUMENTS]
ECHO.
IF not "%help%"=="usage" GOTO EXTENDED
ECHO Execute UTIL with ARGUMENTS.
ECHO Arguments starting with a '/' are OPTIONS, except after terminator '--'.
ECHO.
ECHO DISPLAY EXTENDED HELP: %script% /?
GOTO END

:EXTENDED
ECHO OPTIONS
ECHO./p        Force pause before exit
ECHO./-p       Force no pause before exit (pauses on error by default)
ECHO./t [N]    Timeout for N seconds before exit
ECHO./q        Be quiet (supress standard output)
ECHO./-e       Hide errors (supress error output)
ECHO./r        Redirect error output to standard output
ECHO./c        Redirect standard output to clipboard
ECHO./g [TEXT] Grep standard output
ECHO./o [PATH] Write standard output to file, quits if PATH exists and /f option not present
ECHO./f        Force overwrite
ECHO./a [PATH] Append standard output to file
ECHO./b        Run in background (START /B)
ECHO./w        Wait for any key before execution
ECHO --        OPTIONS terminator

:END
CALL run_end
