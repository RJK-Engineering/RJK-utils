@echo off
setlocal

if "%1"=="/?" goto HELP
if not "%1"=="" set TASKS_FILTER=/fi "imagename eq %1"

if not "%2"=="" set TASKS_FORMAT=/fo %2
if /i "%2" equ "t" set TASKS_FORMAT=/fo table
if /i "%2" equ "l" set TASKS_FORMAT=/fo list
if /i "%2" equ "c" set TASKS_FORMAT=/fo csv

echo on
tasklist /v %TASKS_FILTER% %TASKS_FORMAT%
@echo off
echo.
echo For help type: %0 /?
EXIT/B

:HELP
echo Run tasklist command.
echo USAGE: %0 [image name eg: EXAMPLE.EXE] [format: TABLE, LIST or CSV]
echo Format shortcuts: T=TABLE, L=LIST, C=CSV
