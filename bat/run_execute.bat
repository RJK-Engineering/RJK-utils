
IF not "%~1"=="" SET args=%*

::SET_RUN
SET run=
IF /I "%extension%"==".bat" SET run= CALL
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
    IF defined error GOTO END
    SET "out=>%output%"
)
IF defined errorredirect SET "out=%out% %errorredirect%"
SET "out=%quiet%%out%%clip%"

::EXECUTE
IF defined echo ECHO run=%run%& ECHO arg=%args%& ECHO out="%out%"

SET exitcode=
IF defined args (
    %run% %args%%out%
) ELSE (
    %run%%out%
)
IF %errorlevel% gtr 0 SET exitcode=%errorlevel%

:END
