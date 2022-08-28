@echo off
setlocal

set dir=c:\temp\snapshots

if not "%~2"=="" goto subst-backup
if not "%~1"=="" goto subst-mirror
call :list
pause
exit/b

:subst-backup
subst /d %2:
net use /delete %2:
subst %2: "%1:\%2"
goto list

:subst-mirror
subst /d %1:
net use /delete %1:
subst %1: "%dir%\%1"
goto list

:list
FOR /F "tokens=1,4,5 delims=: " %%F IN ('subst') DO (
    echo %%F: = %%G:%%H
)
FOR /F "tokens=1,2,3" %%F IN ('net use') DO (
    if "%%F"=="Disconnected" echo %%G = %%H (%%F^)
    if "%%F"=="OK" echo %%G = %%H
)
exit/b
