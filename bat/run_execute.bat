
IF DEFINED call SET cmd=%call% %cmd%
IF DEFINED args SET "cmd=%cmd% "
IF DEFINED errorredirect SET "errorredirect= %errorredirect%"

IF DEFINED echo ECHO "%cmd%%args%%quiet%%output%%errorredirect%%clip%"
%cmd%%args%%quiet%%output%%errorredirect%%clip%
