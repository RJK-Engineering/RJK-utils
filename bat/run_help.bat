ECHO USAGE: %script% [OPTIONS] [COMMAND] [OPTIONS] [ARGS]
ECHO.
IF "%help%"=="usage" (
    ECHO DISPLAY EXTENDED HELP: %script% /?
    GOTO END
)

ECHO OPTIONS
ECHO./p        Force pause before exit
ECHO./-p       Force no pause before exit (pauses on error by default)
ECHO./t [n]    Timeout before exit
ECHO./q        Be quiet (supress standard output)
ECHO./-e       Hide errors (supress error output)
ECHO./r        Redirect error output to standard output
ECHO./c        Redirect standard output to clipboard
ECHO /o [path] Write standard output to file
ECHO./f        Force overwrite (no overwrite by default)
ECHO /a [path] Append standard output to file
ECHO /b        Run in background (START /B)
ECHO /-        OPTIONS terminator, rest of command line are ARGS

ECHO.
ECHO BUG: ARGS can't contain /?
ECHO.
ECHO Example usage in Total Commander:
ECHO     Command:   run.bat command.exe /p /r
ECHO     Params:    ?/q %%N
ECHO Extra OPTIONS can be added or removed quickly (by pressing HOME) at
ECHO the start of the parameter list in the dialog box opened on execution.

:END
