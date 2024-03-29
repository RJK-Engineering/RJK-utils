@echo off

set -available-options=NETDRIVE_HOST NETDRIVE_MAP
set -required-options=NETDRIVE_HOST

if "%~1"=="" (
    goto USAGE
) else if "%~1"=="set" (
    call set-options %*
) else if "%~1 %~2"=="delete option" (
    call set-options delete %3
) else (
    call set-options
    setlocal
    for %%A IN (%*) do call :connect %%A
)
exit/b

:connect
set driveletter=%1
call %~dp0drive_disconnect %driveletter%
set volume=%driveletter%:

call env-hash-value NETDRIVE_MAP %driveletter%
if defined -hash-value (
    set dir=%-hash-value%
) else (
    set dir=\\%NETDRIVE_HOST%\%driveletter%$
)
echo net use %volume% %dir%
net use %volume% %dir%
exit/b

:USAGE
echo USAGE
echo.
echo %0 [driveletters]
echo.
echo LIST/SET OPTIONS INTERACTIVELY
echo.
echo %0 set
echo.
echo SET OPTIONS (available options: %-available-options%)
echo.
echo %0 set [option]=[value] ([option]=[value] ...)
echo.
echo DELETE OPTION
echo.
echo %0 set delete option [option]
echo.
pause
