REM Get options and other arguments from command-line arguments.
REM CALL run_getopt %*
REM
REM EXAMPLE
REM
REM run_getopt a.ext b c d
REM
REM arg1=a.ext   args1= b c d   ext1=ext
REM arg2=b       args2= c d
REM arg3=c       args3= d

REM clear vars, they are inherited from master environment
FOR %%V IN (optstop arg1 arg2 arg3 ext1 ext2 ext3 args1 args2 args3 pause nopause timeout quiet errorredirect clip output force append background wait) do set %%V=

:GETOPT
IF "%~1"==""       GOTO ENDGETOPT
IF defined optstop GOTO GETARG

IF "%~1"=="/p"  SET pause=1& SET nopause=& GOTO NEXTOPT
IF "%~1"=="/-p" SET nopause=1& SET pause=& GOTO NEXTOPT
IF "%~1"=="/t"  SET timeout=%2&    SHIFT & GOTO NEXTOPT
IF "%~1"=="/q"  SET "quiet=>NUL"         & GOTO NEXTOPT
IF "%~1"=="/-e" SET "errorredirect=2>NUL"& GOTO NEXTOPT
IF "%~1"=="/r"  SET "errorredirect=2>&1" & GOTO NEXTOPT
IF "%~1"=="/c"  SET "clip=|CLIP"         & GOTO NEXTOPT
IF "%~1"=="/g"  SET grep=%~2&      SHIFT & GOTO NEXTOPT
IF "%~1"=="/o"  SET output=%2&     SHIFT & GOTO NEXTOPT
IF "%~1"=="/f"  SET force=1&               GOTO NEXTOPT
IF "%~1"=="/a"  SET append=%2&     SHIFT & GOTO NEXTOPT
IF "%~1"=="/b"  SET background=1&          GOTO NEXTOPT
IF "%~1"=="/w"  SET wait=1&                GOTO NEXTOPT
IF "%~1"=="--"  SET optstop=1&             GOTO NEXTOPT

SET "arg=%~1"
IF "%arg:~0,1%"=="/" SET option%1=1&       GOTO NEXTOPT

:GETARG
IF defined arg3 (
    SET args3=%args3% %1
) ELSE IF defined arg2 (
    SET arg3=%1
    SET ext3=%~x1
)

IF defined arg2 (
    SET args2=%args2% %1
    SET args2= %1
) ELSE IF defined arg1 (
    SET arg2=%1
    SET ext2=%~x1
)

IF defined arg1 (
    SET args1=%args1% %1
) ELSE (
    SET arg1=%1
    SET ext1=%~x1
)

:NEXTOPT
SHIFT
GOTO GETOPT

:ENDGETOPT
