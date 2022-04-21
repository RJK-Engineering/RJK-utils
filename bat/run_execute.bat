
IF not "%~1"=="" SET args= %*

::SET_RUN
SET run=
IF /I "%extension%"==".bat" SET run= CALL
IF /I "%extension%"==".pl" SET run= PERL
IF defined background SET run= START /B%run%
SET run=%run% %cmd%
SET run=%run:~1%

::SET_OUT
SET out=
IF defined append SET "out=>>%append%"
IF defined output CALL run_check_output %output%
IF defined error EXIT/B
IF defined output SET "out=>%output%"
IF defined errorredirect SET "out=%out% %errorredirect%"
SET "out=%quiet%%out%%toclip%"

::EXECUTE
IF defined wait ECHO run=%run%& ECHO args=%args%& ECHO "out=%out%"& PAUSE
CALL run_log "%run%%args%"

IF defined grep (
    %run%%args%|FIND /I "%grep%"%out%
) ELSE (
    %run%%args%%out%
)
