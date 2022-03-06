@echo off
setlocal

if "%~2"=="" (
    echo Join files in list file using Avidemux.
    echo USAGE: %0 [list file] [output file] [optional output format]
    exit/b 1
)

set load=
for /f "delims=" %%F in (%1) do (
    if defined load (
        call set load=%%load%% --append "%%F"
    ) else (
        call set load=--load "%%F"
    )
)

set format=%3
if defined format set format= --output-format %format%

echo avidemux.exe --force-alt-h264 %load%%format% --save %2 --quit
set abort=
echo Press enter to continue, enter any text to abort.
set /p abort=
if defined abort exit/b

avidemux.exe --force-alt-h264 %load%%format% --save %2 --quit
