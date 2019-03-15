@perl %~dp0..\system\chletter\chletter.pl ^
--temp-file c:\temp\chletter.tmp ^
--disconnect-network-drive %*

@if %errorlevel% gtr 0 pause
