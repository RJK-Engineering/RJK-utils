@echo off

call "%~dp0..\config.bat"

perl "%rjk-utils-home%\system\chletter\chletter.pl" %*

if %errorlevel% gtr 0 pause
