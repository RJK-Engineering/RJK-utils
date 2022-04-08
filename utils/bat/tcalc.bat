@echo off
call rjk-util /c timecalc.pl %*
call getclip
if defined clip echo %clip%
