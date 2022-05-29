
IF not "%~1"=="" SET args= %*
IF defined errorredirect SET "errorredirect= %errorredirect%"

IF /I "%extension%"==".bat" SET "cmd=CALL %cmd% "
IF /I "%extension%"==".pl" SET "cmd=PERL %cmd% "
IF defined background SET cmd=START /B %cmd%

SET out=
IF defined append SET "out=>>%append%"
IF defined output CALL run_check_output %output%
IF defined error EXIT/B
IF defined output SET "out=>%output%"
IF defined grep SET "out=|FIND /I "%grep%"%out%"

IF defined message ECHO %message%
IF defined wait ECHO cmd=%cmd%& ECHO args=%args%& ECHO redir="%quiet%%out%%toclip%"& PAUSE
CALL run_log %cmd%%args%
%cmd%%args%%errorredirect%%quiet%%out%%toclip%
