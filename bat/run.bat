@ECHO OFF
SETLOCAL

CALL run_start %0 "%~1"
IF defined help GOTO HELP
SET help=usage

GOTO GETOPT
:ENDGETOPT
IF not defined cmd GOTO HELP

CALL run_execute
CALL run_exit
GOTO END

REM clear vars, they are inherited from master environment
FOR %%V IN (terminator cmd args pause ignoreerrors ignoreexitcode^
    timeout quiet errorredirect clip output force append background wait) DO SET %%V=

:GETOPT
IF "%~1"=="" GOTO ENDGETOPT
IF defined terminator GOTO GETARG
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
IF defined cmd (
    SET args=%args% %1
) ELSE (
    SET cmd=%1
    SET extension=%~x1
)

:NEXTOPT
SHIFT
GOTO GETOPT

:HELP
CALL run_help

:END
CALL run_end
