
REM clear vars, they are inherited from master environment
FOR %%V IN (run out) do set %%V=

:SET_RUN
IF /I "%extension%"==".pl" SET run= PERL
IF DEFINED background SET run= START /B%run%
SET run=%run% %cmd%
SET run=%run:~1%

:SET_OUT
IF DEFINED append (
    SET "out=>>%append%"
) ELSE IF DEFINED output (
    CALL run_check_output %output%
    SET "out=>%output%"
)
IF DEFINED errorredirect SET "out=%out% %errorredirect%"
SET "out=%quiet%%out%%clip%"

:EXECUTE
IF DEFINED echo ECHO run=%run%& ECHO arg=%args%& ECHO out="%out%"

REM a bat files terminates when a bat file is executed unless CALL is used,
REM but since this is the last line in this bat file CALL is not needed

IF DEFINED args (
    %run% %args%%out%
) ELSE (
    %run%%out%
)
