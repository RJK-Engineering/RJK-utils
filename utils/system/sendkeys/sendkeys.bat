@echo off
setlocal

call :time2seconds
set start=%seconds%

set timeout=%2
timeout %timeout%

call :time2seconds
set/a diff=seconds-start
if %diff% lss 0 set/a diff+=86400

if %diff% lss %timeout% (
    echo timeout aborted
) else (
    cscript /nologo "%~dpn0.vbs" %1
)
exit/b

:time2seconds
set h=%TIME:~0,2%
set m=%TIME:~3,2%
set s=%TIME:~6,2%
if %h:~0,1% equ 0 set h=%h:~1,1%
if %m:~0,1% equ 0 set m=%m:~1,1%
if %s:~0,1% equ 0 set s=%s:~1,1%
set/a seconds=h*3600 + m*60 + s
exit/b
