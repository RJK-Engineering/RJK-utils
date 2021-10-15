REM Get options from command-line arguments.
REM CALL run_getopt %*
REM
REM %* = <cmd> [options] <args>
REM or
REM %* = <cmd> [options] <filelist> <args>
REM
REM - [options] start with a "/" and can be followed by a value
REM - <cmd> and <filelist> can be mixed with [options]
REM - to get <filelist>, set get_filelist=1 before calling run_getopt

REM clear vars, they are inherited from master environment
FOR %%V IN (cmd extension filelist args pause nopause timeout quiet errorredirect clip output force append background) do set %%V=

:GETOPT
IF "%~1"=="" GOTO ENDGETOPT
IF defined args SET args=%args% %1&        GOTO NEXTOPT
IF "%~1"=="/p"  SET pause=1& SET nopause=& GOTO NEXTOPT
IF "%~1"=="/-p" SET nopause=1& SET pause=& GOTO NEXTOPT
IF "%~1"=="/t"  SET timeout=%2&    SHIFT & GOTO NEXTOPT
IF "%~1"=="/q"  SET "quiet=>NUL"         & GOTO NEXTOPT
IF "%~1"=="/-e" SET "errorredirect=2>NUL"& GOTO NEXTOPT
IF "%~1"=="/r"  SET "errorredirect=2>&1" & GOTO NEXTOPT
IF "%~1"=="/c"  SET "clip=|CLIP"         & GOTO NEXTOPT
IF "%~1"=="/o"  SET output=%2&     SHIFT & GOTO NEXTOPT
IF "%~1"=="/f"  SET force=1&               GOTO NEXTOPT
IF "%~1"=="/a"  SET append=%2&     SHIFT & GOTO NEXTOPT
IF "%~1"=="/b"  SET background=1&          GOTO NEXTOPT
IF "%~1"=="/-"  SET args=%2&       SHIFT & GOTO NEXTOPT
SET "arg=%~1"
IF "%arg:~0,1%"=="/" SET option%1=1&       GOTO NEXTOPT
IF not defined cmd (
    SET cmd=%1
    SET extension=%~x1
    GOTO NEXTOPT
) ELSE IF defined get_filelist IF not defined filelist (
    SET filelist=%1
    GOTO NEXTOPT
)
SET args=%1
:NEXTOPT
SHIFT
GOTO GETOPT

:ENDGETOPT
