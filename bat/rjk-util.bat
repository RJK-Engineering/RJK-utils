@echo off

setlocal
if not defined RJK_UTILS_HOME FOR /F "delims=" %%P IN ("%~dp0..") DO set RJK_UTILS_HOME=%%~dpfP

rem arguments: [UTIL] [OPTIONS] [ARGS]

rem [UTIL] required
IF "%~1" == "" GOTO USAGE
SET util=%~1
SHIFT

rem [OPTIONS]
:getopt
IF "%~1" == "/d" SET DEBUG=1 & GOTO nextopt
IF "%~1" == "/w" SET WORKSPACEENVIRONMENT=1 & GOTO nextopt
IF "%~1" == "/n" SET NOPAUSE=1 & GOTO nextopt
IF "%~1" == "/p" SET PAUSEONEXIT=1 & GOTO nextopt
GOTO endgetopt
:nextopt
SHIFT & GOTO getopt
:endgetopt

rem [ARGS]
:getarg
IF "%~1" == "" GOTO endgetarg
IF "%~1" == "--" GOTO endgetarg
IF DEFINED args (SET args=%args% %1) ELSE (SET args=%1)
SHIFT & GOTO getarg
:endgetarg

perl %RJK_UTILS_HOME%\utils\%util% %args%

if defined NOPAUSE GOTO END
if %errorlevel% gtr 0. pause & GOTO END
if defined PAUSEONEXIT pause & GOTO END

GOTO END

:USAGE
ECHO USAGE: %0 [UTIL] [OPTIONS] [ARGS]

:END
