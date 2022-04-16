@echo off
setlocal

if "%~1"=="" (
    exit/b 1
)

set bar=%COMMANDER_BARS%\%~1
if not exist "%bar%" (
    echo File not found: %bar%
    pause
    exit/b 2
)

REM UNSAFE: MUST NOT CONTAIN CHARS: & < > ^ |
set menu=%~2
set string=%~3

copy "%bar%" "%bar%~" >NUL
call :go > "%bar%"
del "%bar%~" >NUL
exit/b

:go
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
echo %* | FIND "%menu%" >NUL
if %errorlevel% equ 0 echo %_key%=%menu% %string%& set _print=
exit/b
