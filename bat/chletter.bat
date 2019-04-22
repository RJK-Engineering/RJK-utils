@echo off

call %LOCALAPPDATA%\RJK-utils.bat

perl %rjk-utils-home%\system\chletter\chletter.pl ^
--temp-file "%chletter-temp-file%" ^
--disconnect-network-drive %*

@if %errorlevel% gtr 0 pause
