@echo off
setlocal

if "%~1"=="" (
    echo USAGE: %0 [totalcmd button bar] [label] [icon]
    echo Search for button description starting with [label] and replace icon with [icon].
    exit/b 1
)

set bar=%COMMANDER_BARS%\%~1
if not exist "%bar%" (
    echo File not found: %bar%
    pause
    exit/b 2
)

set "label=%~2"
set icon=%~3

set _num=
call :find-num 2>NUL
if not defined _num (
    echo Label not found: "%label%"
    echo NOTE: Labels containing any of the following characters are not recognized: ^& ^< ^> ^^ ^|
    pause
    exit/b 3
)

copy "%bar%" "%bar%~" >NUL
call :update-bar 2>NUL >"%bar%"

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

:find-num
for /f "usebackq tokens=1,* delims==" %%G in ("%bar%") do (
    call :find %%G %%H
    if defined _num exit/b
)
exit/b

:find
set _key=%1
if not "%_key:~0,4%"=="menu" exit/b
echo %* | FINDSTR /B /C:"%_key% %label%" >NUL
if %errorlevel% equ 0 set _num=%_key:~4%
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
if not "%_key%"=="button%_num%" exit/b
echo %_key%=%icon%
set _print=
exit/b
