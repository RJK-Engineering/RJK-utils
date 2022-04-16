@ECHO OFF
SETLOCAL

CALL run_start %0 "%~1"
IF defined help GOTO HELP
SET help=usage

GOTO BEGINGETOPT
:ENDGETOPT
IF not defined cmd GOTO HELP

CALL run_create_listfiles
SET dellistfile=
IF defined listfile GOTO EXECUTE

SET listfile=%TEMP%\CMD%RANDOM%.tmp
SET dellistfile=1

IF defined fromclip (
    CALL getclip /d > %listfile%
) ELSE IF defined fromdird (
    IF defined dirpath PUSHD. & cd/d %dirpath%
    IF exist %listfile% del/q %listfile%
    FOR /F "delims=" %%F IN ('dir/a-d/b') DO ECHO %%~fF>> %listfile%
    IF defined dirpath POPD
) ELSE IF defined fromdirn (
    dir/a-d/b %dirpath% > %listfile%
) ELSE IF defined fromdirs (
    dir/a-d/b/s %dirpath% > %listfile%
) ELSE (
    GOTO HELP
)

:EXECUTE
FOR /F "tokens=*" %%F IN (%listfile%) DO (
    IF defined display ECHO %display%
    REM replace %%F in vars
    SET append=%append%
    SET output=%output%
    CALL run_execute %args%
    CALL run_exit
)
CALL run_del_listfiles
IF defined dellistfile del/q %listfile%
GOTO END

:BEGINGETOPT
REM clear vars, they are inherited from master environment
FOR %%V IN (cmd extension args listfile fromclip fromdird fromdirn fromdirs dirpath paramdir^
    terminator printexitcode display pause ignoreerrors ignoreexitcode timeout quiet^
    errorredirect clip grep output force append background wait) DO SET %%V=

:GETOPT
IF "%~1"=="" GOTO ENDGETOPT
IF defined terminator GOTO GETARG
IF "%~1"=="/L" SET listfile=%2&   SHIFT & GOTO NEXTOPT
IF "%~1"=="/C" SET fromclip=1&            GOTO NEXTOPT
IF "%~1"=="/D" SET fromdird=1&            GOTO NEXTOPT
IF "%~1"=="/N" SET fromdirn=1&            GOTO NEXTOPT
IF "%~1"=="/S" SET fromdirs=1&            GOTO NEXTOPT
IF "%~1"=="/dir" SET dirpath=%2&  SHIFT & GOTO NEXTOPT
IF "%~1"=="/d" SET display=%%~fF&         GOTO NEXTOPT
IF "%~1"=="/n" SET display=%%~nxF&        GOTO NEXTOPT
IF "%~1"=="/k" SET printexitcode=1& SET pause=1& SET ^
    ignoreerrors=1& SET ignoreexitcode=1& GOTO NEXTOPT
IF "%~1"=="--" SET terminator=1&          GOTO NEXTOPT
IF "%~1"=="/z" SET printexitcode=1&       GOTO NEXTOPT
IF "%~1"=="/P" SET paramdir=%2&   SHIFT & GOTO NEXTOPT
IF "%~1"=="/p" SET pause=1&               GOTO NEXTOPT
IF "%~1"=="/i" SET ignoreerrors=1&        GOTO NEXTOPT
IF "%~1"=="/x" SET ignoreexitcode=1&      GOTO NEXTOPT
IF "%~1"=="/t" SET timeout=%2&    SHIFT & GOTO NEXTOPT
IF "%~1"=="/q" SET "quiet=>NUL"         & GOTO NEXTOPT
IF "%~1"=="/e" SET "errorredirect=2>NUL"& GOTO NEXTOPT
IF "%~1"=="/r" SET "errorredirect=2>&1" & GOTO NEXTOPT
IF "%~1"=="/c" SET "clip=|CLIP"         & GOTO NEXTOPT
IF "%~1"=="/g" SET "grep=%~2"   & SHIFT & GOTO NEXTOPT
IF "%~1"=="/o" SET output=%2&     SHIFT & GOTO NEXTOPT
IF "%~1"=="/f" SET force=1&               GOTO NEXTOPT
IF "%~1"=="/a" SET append=%2&     SHIFT & GOTO NEXTOPT
IF "%~1"=="/b" SET background=1&          GOTO NEXTOPT
IF "%~1"=="/w" SET wait=1&                GOTO NEXTOPT

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
CALL batch_help

:END
CALL run_end
