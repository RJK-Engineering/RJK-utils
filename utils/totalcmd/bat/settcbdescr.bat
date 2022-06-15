@echo off
setlocal

if "%~1"=="" (
    echo USAGE: %0 [totalcmd button bar] [label] [value]
    echo Search for button description starting with [label] and replace text after [label] with [value].
    exit/b 1
)

set bar=%COMMANDER_BARS%\%~1
if not exist "%bar%" (
    echo File not found: %bar%
    pause
    exit/b 2
)

set "label=%~2"
set value=%~3
set _found=

copy "%bar%" "%bar%~" >NUL
call :update-bar 2>NUL >"%bar%"

if not defined _found (
    echo Label not found: "%label%"
    echo NOTE: Labels containing any of the following characters are not recognized: ^& ^< ^> ^^ ^|
    pause
    exit/b 3
)

:: diff check
set i=0
for /f "delims=" %%G in ('fc "%bar%~" "%bar%"') do set/a i=i+1
if %i% equ 10 set i=2
if %i% equ 2 (
    del "%bar%~" >NUL
) else (
    copy "%bar%~" "%bar%" >NUL
    echo EXCEPTION: diff check failed
    fc "%bar%~" "%bar%"
    pause
)
exit/b

:update-bar
for /f "usebackq tokens=1,* delims==" %%G in ("%bar%~") do (
    if /i "%%G"=="[buttonbar]" (
        echo %%G
    ) else (
        call :check %%G %%H
        if defined _print echo %%G=%%H
    )
)
exit/b

:check
set _key=%1
set _print=1
if not "%_key:~0,4%"=="menu" exit/b
echo %* | FINDSTR /B /C:"%_key% %label%" >NUL
if %errorlevel% neq 0 exit/b
echo %_key%=%label% %value%
set _print=
set _found=1
exit/b
