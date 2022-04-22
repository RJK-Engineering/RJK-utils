@echo off
setlocal
setlocal enabledelayedexpansion

set bar=%1
if not defined bar echo USAGE: %0 [bar file]& goto END
if not exist %bar% echo File does not exist: %bar%& goto END

set newbar=%~n183.bar
if exist %newbar% echo File already exists: %newbar%& goto END

echo Reading %bar%
echo Writing %newbar%

for /f "delims=" %%A in (%bar%) do (
    set "l=%%A"
    set l=!l:%%L=%%l!
    set l=!l:%%F=%%f!
    set l=!l:%%P=%%p!
    set l=!l:%%T=%%t!
    echo !l!>> %newbar%
)

:END
