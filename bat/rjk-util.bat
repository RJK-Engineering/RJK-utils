@ECHO OFF
SETLOCAL

IF NOT DEFINED RJK_UTILS_HOME (
    FOR /F "delims=" %%P IN ("%~dp0..") DO SET RJK_UTILS_HOME=%%~fP
)

CALL run_start %0 "%~1"
IF defined help GOTO HELP
SET help=usage

GOTO BEGINGETOPT
:ENDGETOPT
IF not defined util GOTO HELP
IF defined pause SET ignoreerrors=1& SET ignoreexitcode=1

SET cmd=%RJK_UTILS_HOME%\utils\%util%
CALL run_execute
CALL run_exit
GOTO END

:BEGINGETOPT
REM clear vars, they are inherited from master environment
FOR %%V IN (util args printexitcode pause ignoreerrors ignoreexitcode timeout quiet^
    errorredirect clip grep output force append background wait terminator) DO SET %%V=

:GETOPT
IF "%~1"=="" GOTO ENDGETOPT
IF defined terminator GOTO GETARG
IF "%~1"=="/k" SET printexitcode=1& SET pause=1& GOTO NEXTOPT
IF "%~1"=="/z" SET printexitcode=1&       GOTO NEXTOPT
IF "%~1"=="/p" SET pause=1&               GOTO NEXTOPT
IF "%~1"=="/i" SET ignoreerrors=1&        GOTO NEXTOPT
IF "%~1"=="/x" SET ignoreexitcode=1&      GOTO NEXTOPT
IF "%~1"=="/t" SET timeout=%2&    SHIFT & GOTO NEXTOPT
IF "%~1"=="/q" SET "quiet=>NUL"         & GOTO NEXTOPT
IF "%~1"=="/e" SET "errorredirect=2>NUL"& GOTO NEXTOPT
IF "%~1"=="/r" SET "errorredirect=2>&1" & GOTO NEXTOPT
IF "%~1"=="/c" SET "clip=|CLIP"         & GOTO NEXTOPT
IF "%~1"=="/g" SET grep=%~2&      SHIFT & GOTO NEXTOPT
IF "%~1"=="/o" SET output=%2&     SHIFT & GOTO NEXTOPT
IF "%~1"=="/f" SET force=1&               GOTO NEXTOPT
IF "%~1"=="/a" SET append=%2&     SHIFT & GOTO NEXTOPT
IF "%~1"=="/b" SET background=1&          GOTO NEXTOPT
IF "%~1"=="/w" SET wait=1&                GOTO NEXTOPT
IF "%~1"=="--" SET terminator=1&          GOTO NEXTOPT

:GETARG
IF defined util (
    SET args=%args% %1
) ELSE (
    SET util=%1
    SET extension=%~x1
)

:NEXTOPT
SHIFT
GOTO GETOPT

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
ECHO./k        Short for: /z /p (display exit code and pause before exit)
ECHO./z        Display exit code
ECHO./p        Force pause before exit
ECHO./i        Ignore errors (pauses on error by default)
ECHO./x        Ignore exit code (pauses when exit code ^> 0 by default)
ECHO./t [N]    Timeout for N seconds before exit
ECHO./q        Be quiet (suppress standard output)
ECHO./e        Hide errors (suppress error output)
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
