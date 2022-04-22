@ECHO OFF
SETLOCAL

CALL run_start %0 "%~1"
IF defined help GOTO HELP
SET help=usage

GOTO GETOPT
:ENDGETOPT
IF not defined cmd GOTO HELP

IF not defined noparams (
    ECHO %args% | FINDSTR "%%~*[dpnx]*[IOLCDNS]" >NUL
    IF %errorlevel% equ 0 CALL run_subst_params
)

SET dellistfile=
IF not defined listfile (
    CALL :CREATELISTFILE
) ELSE IF not defined noderef (
    CALL :DEREFLISTFILE %listfile%
)
IF not defined listfile IF defined dirpath (
    SET fromdird=1
    CALL :CREATELISTFILE
)

FOR /F "delims=" %%F IN (%listfile%) DO (
    IF defined display ECHO %display%
    REM replace %%F in vars
    SET append=%append%
    SET output=%output%
    CALL run_execute %args%
    CALL run_exit
)
GOTO END

:GETOPT
REM clear vars, they are inherited from master environment
FOR %%V IN (cmd extension args listfile fromclip fromdird fromdirn fromdirs^
    dirpath display noderef terminator^
    printexitcode pause ignoreerrors ignoreexitcode timeout quiet^
    errorredirect clip grep output force append background wait^
    showlog clearlog noparams paramdir question defval cmessage choices) DO SET %%V=
:GETNEXTOPT
IF "%~1"=="" GOTO ENDGETOPT
IF defined terminator GOTO GETARG
IF "%~1"=="/L" SET listfile=%2&   SHIFT & GOTO NEXTOPT
IF "%~1"=="/C" SET fromclip=1&            GOTO NEXTOPT
IF "%~1"=="/dir" SET dirpath=%2&  SHIFT & GOTO NEXTOPT
IF "%~1"=="/D" SET fromdird=1&            GOTO NEXTOPT
IF "%~1"=="/N" SET fromdirn=1&            GOTO NEXTOPT
IF "%~1"=="/S" SET fromdirs=1&            GOTO NEXTOPT
IF "%~1"=="/d" SET display=%%~fF&         GOTO NEXTOPT
IF "%~1"=="/n" SET display=%%~nxF&        GOTO NEXTOPT
IF "%~1"=="/k" SET printexitcode=1&SET pause=1&SET ignoreerrors=1&SET ignoreexitcode=1&GOTO NEXTOPT
IF "%~1"=="/E" SET listfileext=%2&SHIFT & GOTO NEXTOPT
IF "%~1"=="--" SET terminator=1&          GOTO NEXTOPT
IF "%~1"=="/z" SET printexitcode=1&       GOTO NEXTOPT
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
IF "%~1"=="/noderef"      SET noderef=1&               GOTO NEXTOPT
IF "%~1"=="/nolog"        SET COMMANDER_RUN_LOG=&      GOTO NEXTOPT
IF "%~1"=="/showlog"      SET showlog=1&               GOTO NEXTOPT
IF "%~1"=="/clearlog"     SET clearlog=1&              GOTO NEXTOPT
IF "%~1"=="/noparams"     SET noparams=1&              GOTO NEXTOPT
IF "%~1"=="/list"         SET paramdir=%2&     SHIFT & GOTO NEXTOPT
IF "%~1"=="/prompt"       SET "question=%~2" & SHIFT & GOTO NEXTOPT
IF "%~1"=="/defaultvalue" SET "defval=%~2"   & SHIFT & GOTO NEXTOPT
IF "%~1"=="/OM"           SET cmessage=%2&     SHIFT & GOTO NEXTOPT
IF "%~1"=="/O" (
    ECHO %2. %~3
    SET choice_%2=%~3
    SET choices=%choices%%2
    SHIFT & SHIFT & GOTO NEXTOPT
)

:GETARG
IF defined cmd (
    SET args=%args% %1
) ELSE (
    SET cmd=%1
    SET extension=%~x1
)

:NEXTOPT
SHIFT
GOTO GETNEXTOPT

:CREATELISTFILE
SET listfile=%TEMP%\CMD%RANDOM%.tmp
SET dellistfile=1

IF defined fromclip (
    >%listfile% CALL getclip /d
) ELSE IF defined fromdird (
    IF defined dirpath PUSHD. & cd/d %dirpath%
    IF exist %listfile% del/q %listfile%
    FOR /F "delims=" %%F IN ('dir/a-d/b') DO >>%listfile% ECHO %%~fF
    IF defined dirpath POPD
) ELSE IF defined fromdirn (
    >%listfile% dir/a-d/b %dirpath%
) ELSE IF defined fromdirs (
    >%listfile% dir/a-d/b/s %dirpath%
) ELSE (
    SET listfile=
    SET dellistfile=
)
EXIT/B

:DEREFLISTFILE
IF not defined listfileext SET listfileext=txt
IF /I not "%~x1"==".%listfileext%" EXIT/B
SET line=
FOR /F "delims=" %%F IN (%listfile%) DO (
    IF defined line EXIT/B
    CALL SET line=%%F
)
SET listfile=%line%
EXIT/B

:HELP
CALL batch_help

:END
IF not defined noparams CALL run_del_listfiles
IF defined dellistfile del/q %listfile%
CALL run_end
