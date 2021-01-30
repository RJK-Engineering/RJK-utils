@echo off
setlocal
set prevdir=%CD%
cd\
call rjk-util system\drivestatus\drivestatus.pl /n --window-title "%~n0" %*
cd %prevdir%
