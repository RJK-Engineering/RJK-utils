@echo off

if not defined -available-options (
    echo No available options set, set -available-options before calling %0:
    echo set -available-options=[option] ^([option] ...^)
    echo set -required-options=[option] ^([option] ...^)
    echo call set-options ...
    goto END
)

if "%~1"=="set" (
    if not "%~2"=="" shift & goto SET
) else if "%~1"=="delete" (
    shift & goto DELETE
) else (
    call :check-required %-required-options%
    if not defined -required-options-missing exit/b
)
call :set-interactive %-available-options%
goto END

:SET
set _opt=%1
if not defined _opt goto END
call :check-if-available %-available-options%
if not defined -is-available goto NEXT
echo set %_opt%=%~2
set %_opt%=%~2
setx %_opt% %2
echo.
:NEXT
shift & shift
goto SET

:DELETE
reg delete HKCU\Environment /v %1
set %1=
goto END

:check-required
set -required-options-missing=
:LOOP1
if "%1"=="" exit/b
call set value=%%%1%%
if not defined value (
    echo Option %1 is required.
    set -required-options-missing=1
)
shift
goto LOOP1

:check-if-available
set -is-available=
:LOOP2
if "%1"=="" (
    echo Option not available: %_opt%
    echo Available options: %-available-options%
    exit/b
) else if "%1"=="%_opt%" (
    set -is-available=1
    exit/b
)
shift
goto LOOP2

:set-interactive
set _opt=%1
if not defined _opt exit/b
shift

call set _val=%%%_opt%%%
echo %_opt%=%_val%
set _val=
set/p "_val=New value? (press enter to skip) "
if defined _val (
    echo set %_opt%=%_val%
    set %_opt%=%_val%
    setx %_opt% %_val%
)
echo.
goto set-interactive

:END
set -required-options-missing=
set -is-available=
set _opt=
set _val=
pause
