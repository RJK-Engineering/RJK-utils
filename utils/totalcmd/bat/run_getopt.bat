
REM clear vars, they are inherited from master environment
FOR %%V in (cmd args pause nopause timeout quiet errorredirect clip output call) do set %%V=

:GETOPT
IF "%~1"=="" GOTO ENDGETOPT
IF DEFINED args SET args=%args% %1&        GOTO NEXTOPT
IF "%~1"=="/p"  SET pause=1& SET nopause=& GOTO NEXTOPT
IF "%~1"=="/-p" SET nopause=1& SET pause=& GOTO NEXTOPT
IF "%~1"=="/t"  SET timeout=%2&    SHIFT & GOTO NEXTOPT
IF "%~1"=="/q"  SET "quiet=>NUL"&          GOTO NEXTOPT
IF "%~1"=="/-e" SET "errorredirect=2>NUL"& GOTO NEXTOPT
IF "%~1"=="/r"  SET "errorredirect=2>&1"&  GOTO NEXTOPT
IF "%~1"=="/c"  SET "clip=|CLIP"&          GOTO NEXTOPT
IF "%~1"=="/o"  SET output=%2&     SHIFT & GOTO NEXTOPT
IF "%~1"=="/f"  SET force=1&               GOTO NEXTOPT
IF "%~1"=="/a"  SET append=%2&     SHIFT & GOTO NEXTOPT
IF "%~1"=="/-"  SET args=%2&       SHIFT & GOTO NEXTOPT
SET "arg=%~1"
IF "%arg:~0,1%"=="/" SET option%1=1&       GOTO NEXTOPT
IF DEFINED cmd (
    SET args=%1
) ELSE (
    SET cmd=%1
    SET extension=%~x1
)
GOTO NEXTOPT

:NEXTOPT
SHIFT
GOTO GETOPT

:ENDGETOPT
IF NOT DEFINED cmd GOTO USAGE

:SETCALL
IF "%extension%"==".pl"  SET call=perl
IF "%extension%"==".bat" SET call=call

:SETOUTPUT
IF DEFINED append (
    SET "output=>> %append%"
) ELSE IF DEFINED output (
    CALL run_check_output %output%
    SET "output=> %output%"
) ELSE (
    SET "output=%clip%"
)
GOTO END

:USAGE
CALL run_usage

:END
