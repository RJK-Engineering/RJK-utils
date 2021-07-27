
REM clear vars, they are inherited from master environment
FOR %%V in (cmd args pause nopause timeout quiet errorredirect clip output) do set %%V=

:getopt
IF "%~1"=="" GOTO endgetopt
IF DEFINED args SET args=%args% %1& GOTO nextopt
IF "%~1"=="/p" SET pause=1& SET nopause=& GOTO nextopt
IF "%~1"=="/-p" SET nopause=1& SET pause=& GOTO nextopt
IF "%~1"=="/t" SET timeout=%2& SHIFT& GOTO nextopt
IF "%~1"=="/q" SET "quiet=>NUL"& GOTO nextopt
IF "%~1"=="/-e" SET "errorredirect=2>NUL"& GOTO nextopt
IF "%~1"=="/r" SET "errorredirect=2>&1"& GOTO nextopt
IF "%~1"=="/c" SET "clip=|CLIP"& GOTO nextopt
IF "%~1"=="/o" SET output=%2& SHIFT& GOTO nextopt
IF "%~1"=="/-" SHIFT& GOTO endgetopt
SET "arg=%~1"
IF "%arg:~0,1%"=="/" SET option%1=1& GOTO nextopt
IF NOT DEFINED cmd SET cmd=%1& SET extension=%~x1& GOTO nextopt
SET args=%1
GOTO endgetopt

:nextopt
SHIFT
GOTO getopt

:endgetopt
IF NOT DEFINED cmd GOTO USAGE

:setcommand
IF "%extension%"==".pl" SET cmd=perl %cmd%
IF "%extension%"==".bat" SET cmd=call %cmd%

:setoutput
IF DEFINED output (
    SET "output=> %output%"
) ELSE (
    SET "output=%clip%"
)
GOTO END

:USAGE
CALL run_usage

:END
