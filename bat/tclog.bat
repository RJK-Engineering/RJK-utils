@echo off

call "%~dp0..\config.bat"

perl "%rjk-utils-home%\totalcmd\log.pl" ^
--archive-dir "%tc-log-archive-dir%" ^
--logfile "%tc-log-file%" %*

if %errorlevel% gtr 0 pause
