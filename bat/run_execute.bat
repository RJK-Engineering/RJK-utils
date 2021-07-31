
IF NOT "%call%"=="" SET cmd=%call% %cmd%

%cmd% %args% %errorredirect% %quiet% %output%
