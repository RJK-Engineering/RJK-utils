@ECHO OFF
SETLOCAL

IF "%~1"=="" GOTO USAGE

rem clear vars, they are inherited from master environment
SET pause=
SET nopause=
SET quiet=
SET redirect=
SET debug=
SET cmd=
SET args=

:getopt
IF "%~1"=="" GOTO endgetopt
IF DEFINED args SET "args=%args% %1" & GOTO nextopt
IF "%~1"=="/?" GOTO HELP
IF "%~1"=="/p" SET "pause=1" & GOTO nextopt
IF "%~1"=="/-p" SET "nopause=1" & GOTO nextopt
IF "%~1"=="/q" SET "quiet=1" & GOTO nextopt
IF "%~1"=="/r" SET "redirect=1" & GOTO nextopt
IF "%~1"=="/d" SET "debug=1" & GOTO nextopt
IF NOT DEFINED cmd SET "cmd=%1" & (IF "%~x1"==".bat" SET "cmd=call %1") & GOTO nextopt
SET args=%1
:nextopt
SHIFT & GOTO getopt
:endgetopt

IF DEFINED debug (
    ECHO *: %*
    ECHO pause: %pause%
    ECHO nopause: %nopause%
    ECHO quiet: %quiet%
    ECHO redirect: %redirect%
    ECHO debug: %debug%
    ECHO cmd: %cmd%
    ECHO args: %args%
    SET pause=1
)

IF NOT DEFINED cmd GOTO USAGE

IF DEFINED debug (
    ECHO %cmd% %args%
) ELSE IF DEFINED quiet (
    IF DEFINED redirect (
        %cmd% %args% >NUL 2>&1
    ) ELSE (
        %cmd% %args% >NUL
    )
) ELSE IF DEFINED redirect (
    %cmd% %args% 2>&1
) ELSE (
    %cmd% %args%
)
GOTO END

:HELP
SET help=1
:USAGE
ECHO USAGE: %0 [OPTIONS] [COMMAND] [OPTIONS] [ARGS]
ECHO.
ECHO OPTIONS
ECHO./?   Display extended help.
ECHO./p   Pause before exit (only pauses on error by default, overrides /-p).
ECHO./-p  No pause before exit (pauses on error by default).
ECHO./q   Be quiet (suppress standard output).
ECHO./r   Redirect standard error output to standard output.
ECHO./d   Debug mode.
IF NOT DEFINED help GOTO END

ECHO.
ECHO Example usage in Total Commander:
ECHO     Command:   run.bat command.exe /p /r
ECHO     Params:    ?/q %%N
ECHO Extra OPTIONS can be added or removed quickly (by pressing HOME) at
ECHO the start of the parameter list in the dialog box opened on execution.

:END
IF %errorlevel% GTR 0 (
    ECHO Error level %errorlevel%
    IF NOT DEFINED nopause SET pause=1
)
IF DEFINED pause pause
