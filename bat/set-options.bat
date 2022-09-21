@echo off
setlocal

rem When this script is called from another script, it should not run in
rem a local environment (no setlocal before calling this script), to allow
rem updating of current user environment in which the main script runs.

if not defined -available-options (
    echo No available options set, set -available-options before calling %0:
    echo set -available-options=[option] ^([option] ...^)
    echo set -required-options=[option] ^([option] ...^)
    echo call set-options ...
    echo.
    goto PAUSE_AND_EXIT
)

set _cmd=%1
shift
if not defined _cmd (
    call :check-required %-required-options%
    if not defined -required-options-missing exit/b
) else if "%_cmd%"=="set" (
    if not "%~1"=="" (
        endlocal
        goto SET
    )
) else if "%_cmd%"=="delete" (
    endlocal
    goto DELETE
) else (
    echo Not a command: %_cmd%
    goto PAUSE_AND_EXIT
)
endlocal
call :set-interactive %-available-options%
goto PAUSE_AND_EXIT

:SET
if "%~1"=="" goto PAUSE_AND_EXIT
set -is-available=%1
call :check-if-available %-available-options%
if not defined -is-available goto NEXT
echo set %1=%~2
set %1=%~2
setx %1 %2
echo.
:NEXT
shift & shift
goto SET

:DELETE
if "%~1"=="" goto PAUSE_AND_EXIT
reg delete HKCU\Environment /v %1
set %1=
shift
goto DELETE

:check-required
set -required-options-missing=
:LOOP
if "%~1"=="" exit/b
call set value=%%%1%%
if not defined value (
    echo Option %1 is required.
    set -required-options-missing=1
)
shift
goto LOOP

:check-if-available
if "%~1"=="%-is-available%" exit/b
if "%~1"=="" (
    echo Option not available: %-is-available%
    echo Available options: %-available-options%
    set -is-available=
    exit/b
)
shift
goto check-if-available

:set-interactive
if "%~1"=="" exit/b
call :set-value %1 "%%%1%%"
shift
goto set-interactive

:set-value
echo %1=%~2
set %1=
set/p "%1=New value? (press enter to skip) "
call :_set-value %1 "%%%1%%" %2
echo.
exit/b

:_set-value
if "%~2"=="" (
    set "%1=%~3"
) else (
    echo set %1=%~2
    set "%1=%~2"
    setx %1 %2
)
exit/b

:PAUSE_AND_EXIT
pause
