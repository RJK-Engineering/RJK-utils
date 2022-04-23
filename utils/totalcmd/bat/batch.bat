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

IF defined listfile (
    IF defined subdirs (
        CALL batch_read_subdirs
    ) ELSE IF not defined noderef (
        CALL batch_deref_listfile
    )
) ELSE (
    CALL batch_create_listfile
)
IF not defined listfile IF defined dirpath (
    SET fromdird=1
    CALL batch_create_listfile
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
FOR %%V IN (cmd extension args listfile listfileext subdirs dellistfile^
    fromclip dirpath fromdird fromdirn fromdirs^
    display terminator printexitcode pause ignoreerrors ignoreexitcode timeout quiet^
    errorredirect clip grep output force append background wait^
    noderef showlog clearlog noparams paramdir question defval cmessage choices) DO SET %%V=
:GETNEXTOPT
IF "%~1"=="" GOTO ENDGETOPT
IF defined terminator GOTO GETARG
IF "%~1"=="/L" SET listfile=%2&   SHIFT & GOTO NEXTOPT
IF "%~1"=="/E" SET listfileext=%2&SHIFT & GOTO NEXTOPT
IF "%~1"=="/s" SET subdirs=1&             GOTO NEXTOPT
IF "%~1"=="/C" SET fromclip=1&            GOTO NEXTOPT
IF "%~1"=="/dir" SET dirpath=%2&  SHIFT & GOTO NEXTOPT
IF "%~1"=="/D" SET fromdird=1&            GOTO NEXTOPT
IF "%~1"=="/N" SET fromdirn=1&            GOTO NEXTOPT
IF "%~1"=="/S" SET fromdirs=1&            GOTO NEXTOPT
IF "%~1"=="/d" SET display=%%~fF&         GOTO NEXTOPT
IF "%~1"=="/n" SET display=%%~nxF&        GOTO NEXTOPT
IF "%~1"=="/k" SET printexitcode=1&SET pause=1&SET ignoreerrors=1&SET ignoreexitcode=1&GOTO NEXTOPT
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

:HELP
CALL batch_help

:END
CALL run_end
