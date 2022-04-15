@echo off
setlocal

set script=%0
set action=%1& shift
set diskpartscript="%TEMP%\letter.txt"

if not defined action goto USAGE
if /i "%action%"=="list" goto LIST
if /i "%action%"=="assign" goto ASSIGN
if /i "%action%"=="remove" goto REMOVE
if /i "%action%"=="reassign" goto REASSIGN
goto USAGE

:LIST
echo list volume| diskpart
EXIT/B

:ASSIGN
set label=%1
if not defined label goto USAGE
set letter=%2
if not defined letter goto USAGE

for /f "tokens=1-10" %%F in ('echo list volume^| diskpart') do (
    if "%%F"=="Volume" if "%%J"=="Partition" if "%%H"=="%label%" (
        echo Assign drive letter %letter% to %label%
        echo select volume=%%G> %diskpartscript%
        echo assign letter=%letter%>> %diskpartscript%
        goto EXECUTE
    )
)
echo Label not found: %label% (volume may not already have a drive letter assigned)
EXIT/B

:REMOVE
set letter=%1
if not defined letter goto USAGE
echo Remove drive letter %letter%
pause

echo select volume=%letter%> %diskpartscript%
echo remove letter=%letter%>> %diskpartscript%
goto EXECUTE

:REASSIGN
set letter=%1
if not defined letter goto USAGE
set newletter=%2
if not defined newletter goto USAGE
echo Reassign drive letter %letter% to %newletter%

echo select volume=%letter%> %diskpartscript%
echo assign letter=%newletter%>> %diskpartscript%
goto EXECUTE

:EXECUTE
diskpart /s %diskpartscript%
del %diskpartscript%
EXIT/B

:USAGE
echo USAGE:
echo %script% assign [label] [letter]
echo %script% remove [letter]
echo %script% reassign [letter] [letter]
