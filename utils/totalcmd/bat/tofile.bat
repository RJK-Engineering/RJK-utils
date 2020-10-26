@echo off
setlocal

rem clear vars, they are inherited from master environment
SET pause=
SET nopause=
SET noerror=
SET redirect=
SET debug=
SET outfile=
SET command=

:getopt
IF "%~1"=="" GOTO endgetopt
IF DEFINED command SET "command=%command% %1" & GOTO nextopt
IF "%~1"=="/p" SET "pause=1" & GOTO nextopt
IF "%~1"=="/-p" SET "nopause=1" & GOTO nextopt
IF "%~1"=="/-e" SET "noerror=2>NUL" & GOTO nextopt
IF "%~1"=="/r" SET "redirect=2>&1" & GOTO nextopt
IF "%~1"=="/d" SET "debug=1" & GOTO nextopt
IF NOT DEFINED outfile SET "outfile=%~1" & GOTO nextopt
SET command=%1
:nextopt
SHIFT & GOTO getopt
:endgetopt

IF DEFINED debug GOTO DEBUG

IF EXIST "%outfile%" ECHO File exists: %outfile% & PAUSE & GOTO END
%command% %noerror% %redirect% > %outfile%
GOTO END

:DEBUG
ECHO Command: %command%
ECHO Write output to file: %outfile%
SET pause=1

:END
IF %errorlevel% GTR 0 (
    ECHO Error level %errorlevel%
    IF NOT DEFINED nopause SET pause=1
)
IF DEFINED pause pause
