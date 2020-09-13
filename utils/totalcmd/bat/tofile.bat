@echo off
setlocal

rem clear vars, they are inherited from master environment
SET debug=
SET pause=
SET redirect=
SET outfile=
SET command=

:getopt
IF "%~1"=="" GOTO endgetopt
IF DEFINED command SET "command=%command% %1" & GOTO nextopt
IF "%~1"=="/d" SET "debug=1" & GOTO nextopt
IF "%~1"=="/p" SET "pause=1" & GOTO nextopt
IF "%~1"=="/r" SET "redirect=1" & GOTO nextopt
IF NOT DEFINED outfile SET "outfile=%~1" & GOTO nextopt
SET command=%1
:nextopt
SHIFT & GOTO getopt
:endgetopt

IF DEFINED debug GOTO DEBUG

IF EXIST "%outfile%" ECHO File exists: %outfile% & PAUSE & GOTO END
IF DEFINED redirect (
    %command% > "%outfile%" 2>NUL
) ELSE (
    %command% > "%outfile%"
)
GOTO END

:DEBUG
ECHO Command: %command%
ECHO Write output to file: %outfile%
ECHO Suppress error output: %redirect%
SET pause=1

:END
IF DEFINED pause pause
