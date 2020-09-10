@echo off
setlocal

IF NOT DEFINED RJK_UTILS_HOME FOR /F "delims=" %%P IN ("%~dp0..") DO SET RJK_UTILS_HOME=%%~dpfP

rem clear vars, they are inherited from master environment
SET debug=
SET workspaceenvironment=
SET nopause=
SET pauseonexit=
SET args=

:getopt
IF "%~1"=="" GOTO endgetopt
IF DEFINED args SET args=%args% %1& GOTO nextopt
IF "%~1"=="/?" GOTO USAGE
IF "%~1"=="/d" SET debug=1& GOTO nextopt
IF "%~1"=="/w" SET workspaceenvironment=1& GOTO nextopt
IF "%~1"=="/n" SET nopause=1& GOTO nextopt
IF "%~1"=="/p" SET pauseonexit=1& GOTO nextopt
IF NOT DEFINED util SET util=%1& GOTO nextopt
SET args=%1
:nextopt
SHIFT & GOTO getopt
:endgetopt

IF NOT DEFINED util GOTO USAGE

IF DEFINED workspaceenvironment (
    SET RJK_UTILS_HOME=c:\workspace\RJK-utils%
    SET PATH=%PATH:c:\scripts\RJK-utils\bat=c:\workspace\RJK-utils\bat%
    SET PERL5LIB=%PERL5LIB:c:\scripts\RJK-perl5lib\lib=c:\workspace\RJK-perl5lib\lib%
)

IF DEFINED debug (
    echo perl %RJK_UTILS_HOME%\utils\%util% %args%
) else (
    perl %RJK_UTILS_HOME%\utils\%util% %args%
)

IF DEFINED nopause GOTO END
IF %errorlevel% gtr 0. pause & GOTO END
IF DEFINED pauseonexit pause & GOTO END

GOTO END

:USAGE
ECHO USAGE: %0 [UTIL] [OPTIONS] [ARGS]

:END
