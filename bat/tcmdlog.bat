@echo off

call %LOCALAPPDATA%\RJK-utils.bat

perl %rjk-utils-home%\totalcmd\log.pl ^
--archive-dir %tcmd-log-archive-dir% ^
--logfile %tcmd-log-file% %*

if %errorlevel% gtr 0 pause
