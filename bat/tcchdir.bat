@echo off

call "%~dp0..\config.bat"

perl "%rjk-utils-home%\totalcmd\chdir.pl" %*
