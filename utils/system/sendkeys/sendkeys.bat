@echo off
setlocal

set/a start=%TIME:~0,2%*3600 + %TIME:~3,2%*60 + %TIME:~6,2%

set timeout=%2
timeout %timeout%

:STOP
:: this expression sometimes FAILS with "Invalid number."
set/a stop=%TIME:~0,2%*3600 + %TIME:~3,2%*60 + %TIME:~6,2%
if not defined stop timeout 1 & goto STOP

set/a diff=stop-start
if %diff% lss 0 set/a diff+=86400

if %diff% lss %timeout% (
    echo timeout aborted
) else (
    cscript /nologo "%~dpn0.vbs" %1
)
