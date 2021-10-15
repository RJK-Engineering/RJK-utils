
IF not "%~1"=="" SET args=%*

::SET_RUN
SET run=
IF /I "%extension%"==".pl" SET run= PERL
IF defined background SET run= START /B%run%
SET run=%run% %cmd%
SET run=%run:~1%

::SET_OUT
SET out=
IF defined append (
    SET "out=>>%append%"
) ELSE IF defined output (
    CALL run_check_output %output%
    SET "out=>%output%"
)
IF defined errorredirect SET "out=%out% %errorredirect%"
SET "out=%quiet%%out%%clip%"

::EXECUTE
IF defined echo ECHO run=%run%& ECHO arg=%args%& ECHO out="%out%"

REM a bat files terminates when a bat file is executed unless CALL is used,
REM but since this is the last line in this bat file CALL is not needed

IF defined args (
    %run% %args%%out%
) ELSE (
    %run%%out%
)
