@ECHO OFF
SETLOCAL

IF NOT DEFINED RJK_UTILS_HOME (
    FOR /F "delims=" %%P IN ("%~dp0..") DO SET RJK_UTILS_HOME=%%~fP
)
SET script=%0

IF "%~1"=="" GOTO USAGE
IF "%~1"=="/?" SET help=1& GOTO USAGE
SET option/w=
CALL run_getopt %*

IF DEFINED end GOTO END
IF NOT DEFINED cmd GOTO USAGE
IF DEFINED option/w (
    SET "RJK_UTILS_HOME=c:\workspace\RJK-utils%"
    SET "PATH=%PATH:c:\scripts\RJK-utils\bat=c:\workspace\RJK-utils\bat%"
    SET "PERL5LIB=%PERL5LIB:c:\scripts\RJK-perl5lib\lib=c:\workspace\RJK-perl5lib\lib%"
)

SET cmd=%RJK_UTILS_HOME%\utils\%cmd%
CALL run_execute
GOTO END

:USAGE
ECHO USAGE: %script% [UTIL] [OPTIONS] [UTIL ARGS] [OPTIONS]
ECHO.
IF NOT DEFINED help (
    ECHO DISPLAY EXTENDED HELP: %script% /?
    GOTO END
)
ECHO OPTIONS:
ECHO./?        Help
ECHO /w        Workspace environment
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
