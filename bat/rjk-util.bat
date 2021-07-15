@echo off
setlocal

IF NOT DEFINED RJK_UTILS_HOME (
    FOR /F "delims=" %%P IN ("%~dp0..") DO SET RJK_UTILS_HOME=%%~fP
)
SET script=%0

rem clear vars, they are inherited from master environment
SET workspaceenvironment=
SET pause=
SET nopause=
SET quiet=
SET errorredirect=
SET timeout=
SET clip=
SET output=
SET util=
SET extension=
SET args=

:getopt
IF "%~1"=="" GOTO endgetopt
IF DEFINED args SET args=%args% %1& GOTO nextopt
IF "%~1"=="/?" GOTO USAGE
IF "%~1"=="/w" SET workspaceenvironment=1& GOTO nextopt
IF "%~1"=="/p" SET pause=1& GOTO nextopt
IF "%~1"=="/-p" SET nopause=1& GOTO nextopt
IF "%~1"=="/n" SET nopause=1& GOTO nextopt
IF "%~1"=="/q" SET "quiet=>NUL"& GOTO nextopt
IF "%~1"=="/-e" SET "errorredirect=2>NUL"& GOTO nextopt
IF "%~1"=="/r" SET "errorredirect=2>&1"& GOTO nextopt
IF "%~1"=="/t" SET timeout=%2& SHIFT& GOTO nextopt
IF "%~1"=="/c" SET "clip=|CLIP"& GOTO nextopt
IF "%~1"=="/o" SET output=%2& SHIFT& GOTO nextopt
IF NOT DEFINED util (
    SET util=%1
    SET extension=%~x1
    GOTO nextopt
)
SET args=%1
IF "%args:~0,1%"=="/" (
    ECHO Invalid option: %1
    GOTO ERROR
)
:nextopt
SHIFT & GOTO getopt
:endgetopt

IF NOT DEFINED util GOTO USAGE

IF DEFINED workspaceenvironment (
    SET "RJK_UTILS_HOME=c:\workspace\RJK-utils%"
    SET "PATH=%PATH:c:\scripts\RJK-utils\bat=c:\workspace\RJK-utils\bat%"
    SET "PERL5LIB=%PERL5LIB:c:\scripts\RJK-perl5lib\lib=c:\workspace\RJK-perl5lib\lib%"
)

SET cmd=
IF "%extension%"==".pl" SET cmd=perl
IF "%extension%"==".bat" SET cmd=call

IF DEFINED output (
    SET "output=> %output%"
) ELSE (
    SET "output=%quiet% %clip%"
)

%cmd% %RJK_UTILS_HOME%\utils\%util% %args% %errorredirect% %output%
GOTO END

:ERROR
SET pause=1
ECHO.

:USAGE
ECHO USAGE: %script% [UTIL] [OPTIONS] [ARGS]

:END
IF %errorlevel% GTR 0 (
    ECHO Exit code %errorlevel%
    IF NOT DEFINED nopause SET pause=1
)
IF DEFINED timeout timeout %timeout%
IF DEFINED pause pause
