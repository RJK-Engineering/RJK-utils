@ECHO OFF
SETLOCAL

CALL run_start %0 "%~1"
IF defined help GOTO HELP
SET help=usage

GOTO BEGINGETOPT
:ENDGETOPT
IF not defined cmd GOTO HELP
IF defined pause SET ignoreerrors=1& SET ignoreexitcode=1

ECHO %args% | FIND "%%" >NUL
IF %errorlevel% equ 0 CALL run_replace_params
CALL run_append_listfile

CALL run_execute

CALL run_del_listfiles
IF defined dellistfile del/q %listfile%

CALL run_exit
GOTO END

:BEGINGETOPT
REM clear vars, they are inherited from master environment
FOR %%V IN (cmd args appendc appendd appendn appends appende appendo appendt paramdir^
    terminator printexitcode pause ignoreerrors ignoreexitcode timeout quiet^
    errorredirect toclip grep output force append background wait) DO SET %%V=

:GETOPT
IF "%~1"=="" GOTO ENDGETOPT
IF defined terminator GOTO GETARG
IF "%~1"=="/C?" (IF "%~2"=="" SET appendc=1)        & GOTO NEXTOPT
IF "%~1"=="/D?" (IF "%~2"=="" SET appendd=1)        & GOTO NEXTOPT
IF "%~1"=="/N?" (IF "%~2"=="" SET appendn=1)        & GOTO NEXTOPT
IF "%~1"=="/S?" (IF "%~2"=="" SET appends=1)        & GOTO NEXTOPT
IF "%~1"=="/d?" (IF "%~3"=="" SET dirpath=%2& SHIFT)& GOTO NEXTOPT
IF "%~1"=="/n?" (IF "%~3"=="" SET dirpath=%2& SHIFT)& GOTO NEXTOPT
IF "%~1"=="/s?" (IF "%~3"=="" SET dirpath=%2& SHIFT)& GOTO NEXTOPT
IF "%~1"=="/k" SET printexitcode=1& SET pause=1&      GOTO NEXTOPT
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
IF "%~1"=="/c" SET "toclip=|CLIP"       & GOTO NEXTOPT
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
CALL run_help

:END
CALL run_end
